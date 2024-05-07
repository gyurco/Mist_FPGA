//============================================================================
//  Lady Bug MiST/SiDi top-level
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================
module LadyBug_MiST (
	input         CLOCK_27,
`ifdef USE_CLOCK_50
	input         CLOCK_50,
`endif

	output        LED,
	output [VGA_BITS-1:0] VGA_R,
	output [VGA_BITS-1:0] VGA_G,
	output [VGA_BITS-1:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

`ifdef USE_HDMI
	output        HDMI_RST,
	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_PCLK,
	output        HDMI_DE,
	input         HDMI_INT,
	inout         HDMI_SDA,
	inout         HDMI_SCL,
`endif

	input         SPI_SCK,
	inout         SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,    // data_io
	input         SPI_SS3,    // OSD
	input         CONF_DATA0, // SPI_SS for user_io

`ifdef USE_QSPI
	input         QSCK,
	input         QCSn,
	inout   [3:0] QDAT,
`endif
`ifndef NO_DIRECT_UPLOAD
	input         SPI_SS4,
`endif

	output [12:0] SDRAM_A,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nWE,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nCS,
	output  [1:0] SDRAM_BA,
	output        SDRAM_CLK,
	output        SDRAM_CKE,

`ifdef DUAL_SDRAM
	output [12:0] SDRAM2_A,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_DQML,
	output        SDRAM2_DQMH,
	output        SDRAM2_nWE,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nCS,
	output  [1:0] SDRAM2_BA,
	output        SDRAM2_CLK,
	output        SDRAM2_CKE,
`endif

	output        AUDIO_L,
	output        AUDIO_R,
`ifdef I2S_AUDIO
	output        I2S_BCK,
	output        I2S_LRCK,
	output        I2S_DATA,
`endif
`ifdef I2S_AUDIO_HDMI
	output        HDMI_MCLK,
	output        HDMI_BCK,
	output        HDMI_LRCK,
	output        HDMI_SDATA,
`endif
`ifdef SPDIF_AUDIO
	output        SPDIF,
`endif
`ifdef USE_AUDIO_IN
	input         AUDIO_IN,
`endif
	input         UART_RX,
	output        UART_TX

);

`ifdef NO_DIRECT_UPLOAD
localparam bit DIRECT_UPLOAD = 0;
wire SPI_SS4 = 1;
`else
localparam bit DIRECT_UPLOAD = 1;
`endif

`ifdef USE_QSPI
localparam bit QSPI = 1;
assign QDAT = 4'hZ;
`else
localparam bit QSPI = 0;
`endif

`ifdef VGA_8BIT
localparam VGA_BITS = 8;
`else
localparam VGA_BITS = 6;
`endif

`ifdef USE_HDMI
localparam bit HDMI = 1;
assign HDMI_RST = 1'b1;
`else
localparam bit HDMI = 0;
`endif

`ifdef BIG_OSD
localparam bit BIG_OSD = 1;
`define SEP "-;",
`else
localparam bit BIG_OSD = 0;
`define SEP
`endif

// remove this if the 2nd chip is actually used
`ifdef DUAL_SDRAM
assign SDRAM2_A = 13'hZZZZ;
assign SDRAM2_BA = 0;
assign SDRAM2_DQML = 1;
assign SDRAM2_DQMH = 1;
assign SDRAM2_CKE = 0;
assign SDRAM2_CLK = 0;
assign SDRAM2_nCS = 1;
assign SDRAM2_DQ = 16'hZZZZ;
assign SDRAM2_nCAS = 1;
assign SDRAM2_nRAS = 1;
assign SDRAM2_nWE = 1;
`endif

`include "build_id.v"

localparam CONF_STR = {
	"Ladybug;;",
	"O2,Rotate Controls,Off,On;",
	"OWX,Orientation,Vertical,Clockwise,Anticlockwise;",
	"OY,Rotation filter,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	`SEP
	"DIP;",
	`SEP
	"T0,Reset;",
	"V,v1.10.",`BUILD_DATE
};

wire        rotate = status[2];
wire        blend = status[5];
wire  [1:0] scanlines = status[4:3];
wire  [1:0] rotate_screen = status[33:32];
wire        rotate_filter = status[34];

wire  [1:0] orientation = {1'b0, core_mod[0]};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clk_sys, clk_mem;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_mem),
	.c1(clk_sys),
	.locked(pll_locked)
	);
assign SDRAM_CLK = clk_mem;
assign SDRAM_CKE = 1;

wire [63:0] status;
wire  [6:0] core_mod;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [15:0] joystick_0;
wire [15:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
`ifdef USE_HDMI
wire        i2c_start;
wire        i2c_read;
wire  [6:0] i2c_addr;
wire  [7:0] i2c_subaddr;
wire  [7:0] i2c_dout;
wire  [7:0] i2c_din;
wire        i2c_ack;
wire        i2c_end;
`endif

user_io #(
	.STRLEN($size(CONF_STR)>>3),
	.FEATURES(32'h0 | (BIG_OSD << 13) | (HDMI << 14)))
user_io(
	.clk_sys        (clk_sys        ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
	.core_mod       (core_mod       ),
`ifdef USE_HDMI
	.i2c_start      (i2c_start      ),
	.i2c_read       (i2c_read       ),
	.i2c_addr       (i2c_addr       ),
	.i2c_subaddr    (i2c_subaddr    ),
	.i2c_dout       (i2c_dout       ),
	.i2c_din        (i2c_din        ),
	.i2c_ack        (i2c_ack        ),
	.i2c_end        (i2c_end        ),
`endif
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
);

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire [14:0] rom_cpu_a;
reg   [7:0] rom_cpu_d;
wire  [7:0] rom_cpu_d1;
wire  [7:0] rom_cpu_d2;
wire  [7:0] rom_cpu_d3;

always @(*) begin
	case (rom_cpu_a[14:13])
	2'b00: rom_cpu_d = rom_cpu_d1;
	2'b01: rom_cpu_d = rom_cpu_d2;
	2'b10: rom_cpu_d = rom_cpu_d3;
	default: rom_cpu_d = 8'hff;
	endcase
end

dpram #(13) rom12 (
	.clk_a_i  ( clk_sys ),
	.en_a_i   ( 1'b1 ),
	.we_i     ( ioctl_addr[24:13] == 0 && ioctl_wr ),
	.addr_a_i ( ioctl_addr[12:0] ),
	.data_a_i ( ioctl_dout ),
	.data_a_o ( ),
	.clk_b_i  ( clk_sys ),
	.addr_b_i ( rom_cpu_a[12:0] ),
	.data_b_o ( rom_cpu_d1 )
);

dpram #(13) rom34 (
	.clk_a_i  ( clk_sys ),
	.en_a_i   ( 1'b1 ),
	.we_i     ( ioctl_addr[24:13] == 1 && ioctl_wr ),
	.addr_a_i ( ioctl_addr[12:0] ),
	.data_a_i ( ioctl_dout ),
	.data_a_o ( ),
	.clk_b_i  ( clk_sys ),
	.addr_b_i ( rom_cpu_a[12:0] ),
	.data_b_o ( rom_cpu_d2 )
);

dpram #(13) rom56 (
	.clk_a_i  ( clk_sys ),
	.en_a_i   ( 1'b1 ),
	.we_i     ( ioctl_addr[24:13] == 2 && ioctl_wr ),
	.addr_a_i ( ioctl_addr[12:0] ),
	.data_a_i ( ioctl_dout ),
	.data_a_o ( ),
	.clk_b_i  ( clk_sys ),
	.addr_b_i ( rom_cpu_a[12:0] ),
	.data_b_o ( rom_cpu_d3 )
);

wire [11:0] rom_char_a;
wire [15:0] rom_char_d;

dpram #(12) rom_char_l (
	.clk_a_i  ( clk_sys ),
	.en_a_i   ( 1'b1 ),
	.we_i     ( ioctl_addr[24:13] == 4 && !ioctl_addr[12] && ioctl_wr ),
	.addr_a_i ( ioctl_addr[11:0] ),
	.data_a_i ( ioctl_dout ),
	.data_a_o ( ),
	.clk_b_i  ( clk_sys ),
	.addr_b_i ( rom_char_a[11:0] ),
	.data_b_o ( rom_char_d[7:0] )
);

dpram #(12) rom_char_h (
	.clk_a_i  ( clk_sys ),
	.en_a_i   ( 1'b1 ),
	.we_i     ( ioctl_addr[24:13] == 4 && ioctl_addr[12] && ioctl_wr ),
	.addr_a_i ( ioctl_addr[11:0] ),
	.data_a_i ( ioctl_dout ),
	.data_a_o ( ),
	.clk_b_i  ( clk_sys ),
	.addr_b_i ( rom_char_a[11:0] ),
	.data_b_o ( rom_char_d[15:8] )
);

wire [11:0] rom_sprite_a;
wire [15:0] rom_sprite_d;

dpram #(12) rom_sprite_l (
	.clk_a_i  ( clk_sys ),
	.en_a_i   ( 1'b1 ),
	.we_i     ( ioctl_addr[24:13] == 3 && !ioctl_addr[12] && ioctl_wr ),
	.addr_a_i ( ioctl_addr[11:0] ),
	.data_a_i ( ioctl_dout ),
	.data_a_o ( ),
	.clk_b_i  ( clk_sys ),
	.addr_b_i ( rom_sprite_a[11:0] ),
	.data_b_o ( rom_sprite_d[7:0] )
);

dpram #(12) rom_sprite_h (
	.clk_a_i  ( clk_sys ),
	.en_a_i   ( 1'b1 ),
	.we_i     ( ioctl_addr[24:13] == 3 && ioctl_addr[12] && ioctl_wr ),
	.addr_a_i ( ioctl_addr[11:0] ),
	.data_a_i ( ioctl_dout ),
	.data_a_o ( ),
	.clk_b_i  ( clk_sys ),
	.addr_b_i ( rom_sprite_a[11:0] ),
	.data_b_o ( rom_sprite_d[15:8] )
);

wire  [7:0] decrypted_d;
dpram #(8) rom_decrypt (
	.clk_a_i  ( clk_sys ),
	.en_a_i   ( 1'b1 ),
	.we_i     ( ioctl_addr[24:13] == 5 && ioctl_addr[12:8] == 1 && ioctl_wr ),
	.addr_a_i ( ioctl_addr[7:0] ),
	.data_a_i ( ioctl_dout ),
	.data_a_o ( ),
	.clk_b_i  ( clk_sys ),
	.addr_b_i ( rom_cpu_d ),
	.data_b_o ( decrypted_d )
);

wire  [5:1] rgb_a;
wire  [8:1] rgb_s;
dpram #(5) prom_10_2(
	.clk_a_i  ( clk_sys ),
	.en_a_i   ( 1'b1 ),
	.we_i     ( ioctl_addr[24:13] == 5 && ioctl_addr[12:5] == 1 && ioctl_wr ),
	.addr_a_i ( ioctl_addr[4:0] ),
	.data_a_i ( ioctl_dout ),
	.data_a_o ( ),
	.clk_b_i  ( clk_sys ),
	.addr_b_i ( rgb_a ),
	.data_b_o ( rgb_s )
);

wire  [4:0] lu_a;
wire  [7:0] lu_d;

dpram #(5) prom_10_1 (
	.clk_a_i  ( clk_sys ),
	.en_a_i   ( 1'b1 ),
	.we_i     ( ioctl_addr[24:13] == 5 && ioctl_addr[12:5] == 0 && ioctl_wr ),
	.addr_a_i ( ioctl_addr[4:0] ),
	.data_a_i ( ioctl_dout ),
	.data_a_o ( ),
	.clk_b_i  ( clk_sys ),
	.addr_b_i ( lu_a ),
	.data_b_o ( lu_d )
);

wire  [4:0] ctrl_lu_a;
wire  [7:0] ctrl_lu_d;

dpram #(5) prom_10_3 (
	.clk_a_i  ( clk_sys ),
	.en_a_i   ( 1'b1 ),
	.we_i     ( ioctl_addr[24:13] == 5 && ioctl_addr[12:5] == 2 && ioctl_wr ),
	.addr_a_i ( ioctl_addr[4:0] ),
	.data_a_i ( ioctl_dout ),
	.data_a_o ( ),
	.clk_b_i  ( clk_sys ),
	.addr_b_i ( ctrl_lu_a ),
	.data_b_o ( ctrl_lu_d )
);

reg         reset = 1;
always @(posedge clk_sys) begin
	reset <= status[0] | buttons[1] | ioctl_downl;
end

reg         ce_5m;
reg   [1:0] ce_cnt;
always @(posedge clk_sys) begin
	ce_cnt <= ce_cnt + 1'd1;
	ce_5m <= ce_cnt == 0;
end

wire  [8:0] audio;
wire        hb, vb;
wire        hs, vs;
wire  [1:0] r,g,b;

ladybug_machine ladybug(
	.ext_res_n_i       ( ~reset ),
	.clk_20mhz_i       ( clk_sys ),
	.clk_en_5mhz_o     ( ce_5m ),
	.tilt_n_i          (~{m_tilt,m_tilt}),
	.player_select_n_i (~{m_two_players, m_one_player}),
	.player_fire_n_i   (~{m_fire2A,m_fireA}),
	.player_up_n_i     (~{m_up2,m_up}),
	.player_right_n_i  (~{m_right2,m_right}),
	.player_down_n_i   (~{m_down2,m_down}),
	.player_left_n_i   (~{m_left2,m_left}),
	.player_bomb_n_i   (~{m_fire2B,m_fireB}),
	.right_chute_i     ( m_coin1 ),
	.left_chute_i      ( m_coin2 ),
	.dip_block_1_i     ( ~status[15:8] ),
	.dip_block_2_i     ( 8'hFF ),
	.rgb_r_o           ( r ),
	.rgb_g_o           ( g ),
	.rgb_b_o           ( b ),
	.hsync_n_o         ( hs ),
	.vsync_n_o         ( vs ),
	.vblank_o          ( vb ),
	.hblank_o          ( hb ),
	.audio_o           ( audio ),
	.rom_cpu_a_o       ( rom_cpu_a ),
	.rom_cpu_d_i       ( rom_cpu_d ),
	.d_decrypted_i     ( decrypted_d ),
	.rom_char_a_o      ( rom_char_a ),
	.rom_char_d_i      ( rom_char_d ),
	.rom_sprite_a_o    ( rom_sprite_a ),
	.rom_sprite_d_i    ( rom_sprite_d ),
	.rgb_a_o           ( rgb_a ),
	.rgb_s_i           ( rgb_s ),
	.lu_a_o            ( lu_a ),
	.lu_d_i            ( lu_d ),
	.ctrl_lu_a_o       ( ctrl_lu_a ),
	.ctrl_lu_d_i       ( ctrl_lu_d )
	);

mist_dual_video #(.COLOR_DEPTH(2), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(VGA_BITS), .USE_BLANKS(1'b1), .BIG_OSD(BIG_OSD)) mist_video(
	.clk_sys        ( clk_mem          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( b                ),
	.HBlank         ( hb               ),
	.VBlank         ( vb               ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
`ifdef USE_HDMI
	.HDMI_R         ( HDMI_R           ),
	.HDMI_G         ( HDMI_G           ),
	.HDMI_B         ( HDMI_B           ),
	.HDMI_VS        ( HDMI_VS          ),
	.HDMI_HS        ( HDMI_HS          ),
	.HDMI_DE        ( HDMI_DE          ),
`endif
	.clk_sdram      ( clk_mem          ),
	.sdram_init     ( ~pll_locked      ),
	.SDRAM_A        ( SDRAM_A          ),
	.SDRAM_DQ       ( SDRAM_DQ         ),
	.SDRAM_DQML     ( SDRAM_DQML       ),
	.SDRAM_DQMH     ( SDRAM_DQMH       ),
	.SDRAM_nWE      ( SDRAM_nWE        ),
	.SDRAM_nCAS     ( SDRAM_nCAS       ),
	.SDRAM_nRAS     ( SDRAM_nRAS       ),
	.SDRAM_nCS      ( SDRAM_nCS        ),
	.SDRAM_BA       ( SDRAM_BA         ),

	.ce_divider     ( 4'd7             ),
	.rotate         ( { 1'b0, rotate } ),
	.rotate_screen  ( rotate_screen    ),
	.rotate_hfilter ( rotate_filter    ),
	.rotate_vfilter ( rotate_filter    ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.blend          ( blend            ),
	.no_csync       ( no_csync         )
	);

`ifdef USE_HDMI

i2c_master #(20_000_000) i2c_master (
	.CLK         (clk_sys),

	.I2C_START   (i2c_start),
	.I2C_READ    (i2c_read),
	.I2C_ADDR    (i2c_addr),
	.I2C_SUBADDR (i2c_subaddr),
	.I2C_WDATA   (i2c_dout),
	.I2C_RDATA   (i2c_din),
	.I2C_END     (i2c_end),
	.I2C_ACK     (i2c_ack),

	//I2C bus
	.I2C_SCL     (HDMI_SCL),
 	.I2C_SDA     (HDMI_SDA)
);

assign HDMI_PCLK = clk_mem;
`endif

dac #(9) dac(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_mem),
	.clk_rate(32'd40_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan({2'd0, audio, 5'd0}),
	.right_chan({2'd0, audio, 5'd0})
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clk_mem) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clk_mem),
	.clk_rate_i(32'd40_000_000),
	.spdif_o(SPDIF),
	.sample_i({2'd0, audio, 5'd0, 2'd0, audio, 5'd0})
);
`endif

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
        
arcade_inputs inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( orientation ^ {1'b0, |rotate_screen} ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
