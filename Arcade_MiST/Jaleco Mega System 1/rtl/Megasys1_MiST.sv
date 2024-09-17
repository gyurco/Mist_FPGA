//============================================================================
//  Jaleco Mega Systam 1 HW top-level for MiST
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

module Megasys1_MiST
(
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

`define CORE_NAME "P47J"

localparam CONF_STR = {
	`CORE_NAME, ";;",
	"O2,Rotate Controls,Off,On;",
//`ifdef DUAL_SDRAM
//	"O78,Orientation,Vertical,Clockwise,Anticlockwise;",
//	"O9,Rotation filter,Off,On;",
//`endif
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"OA,Service,Off,On;",
	"OB,Refresh Rate,Native,NTSC;",
	"OC,Audio Mix,Mono,Stereo;",
	`SEP
	"DIP;",
	`SEP
	"T0,Reset;",
	"V,v1.20.",`BUILD_DATE
};

wire        rotate    = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend     = status[5];
wire        joyswap   = status[6];
wire  [1:0] rotate_screen = 0;
//wire  [1:0] rotate_screen = status[8:7];
//wire        rotate_filter = status[9];
wire        service = status[10];
wire        refresh_mod = status[11];
wire        stereo_en = status[12];

wire  [7:0] dsw1 = status[23:16];
wire  [7:0] dsw2 = status[31:24];
wire  [3:0] pcb = core_mod[3:0];

wire        flipped = 0;
wire        tate = 0;

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_72;
//assign SDRAM_CKE = 1;

wire clk_72;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(clk_72),
	.locked(pll_locked)
	);
/*
`ifdef DUAL_SDRAM
wire pll2_locked, clk2_72;
pll_mist pll2(
	.inclk0(CLOCK_27),
	.c0(clk2_72),
	.locked(pll2_locked)
	);
assign SDRAM2_CKE = 1;
assign SDRAM2_CLK = clk2_72;
`endif
*/
// reset generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_72) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded | ioctl_downl;
end

// ARM connection
wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;
wire  [6:0] core_mod;

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
	.ROM_DIRECT_UPLOAD(DIRECT_UPLOAD),
	.FEATURES(32'h0 | (BIG_OSD << 13) | (HDMI << 14)))
user_io(
	.clk_sys        (clk_72         ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD ),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       ),
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
	.core_mod       (core_mod       ),
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

data_io #(.ROM_DIRECT_UPLOAD(DIRECT_UPLOAD)) data_io(
	.clk_sys       ( clk_72       ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_SS4       ( SPI_SS4      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire [15:0] laudio, raudio;
wire        hs, vs;
wire        hb, vb;
wire  [7:0] r,b,g;

wire [15:0] p1 =  ~{ 8'h00, m_fire1[3:0], m_up1, m_down1, m_left1, m_right1 };
wire [15:0] p2 =  ~{ 8'h00, m_fire2[3:0], m_up2, m_down2, m_left2, m_right2 };
wire [15:0] system = ~{ 8'h00, m_coin2, m_coin1, service, 3'd0, m_two_players, m_one_player };
wire        pause_cpu;
input_toggle pause_toggle(clk_72, reset, m_fire1[8] | m_fire2[8], pause_cpu);

Megasys1_top top
(
	.pll_locked   ( pll_locked ),
	.clk_sys      ( clk_72     ),
	.reset        ( reset      ),
	.pcb          ( pcb        ),
	.pause_cpu    ( pause_cpu  ),
	.refresh_mod  ( refresh_mod),

	.p1           ( p1         ),
	.p2           ( p2         ),
	.dsw          ( {dsw2, dsw1} ),
	.system       ( system     ),

	.hbl          ( hb         ),
	.vbl          ( vb         ),
	.hsync        ( hs         ),
	.vsync        ( vs         ),
	.rgb          ( {r, g, b}  ),

	.stereo_en    ( stereo_en  ),
	.AUDIO_L      ( laudio     ),
	.AUDIO_R      ( raudio     ),

	.ioctl_download ( ioctl_downl),
	.ioctl_addr   ( ioctl_addr ),
	.ioctl_wr     ( ioctl_wr   ),
	.ioctl_dout   ( ioctl_dout ),
	.ioctl_index  ( ioctl_index),

	.SDRAM_A      ( SDRAM_A    ),
	.SDRAM_BA     ( SDRAM_BA   ),
	.SDRAM_DQ     ( SDRAM_DQ   ),
	.SDRAM_DQML   ( SDRAM_DQML ),
	.SDRAM_DQMH   ( SDRAM_DQMH ),
	.SDRAM_nCS    ( SDRAM_nCS  ),
	.SDRAM_nCAS   ( SDRAM_nCAS ),
	.SDRAM_nRAS   ( SDRAM_nRAS ),
	.SDRAM_nWE    ( SDRAM_nWE  ),
	.SDRAM_CKE    ( SDRAM_CKE  )
);

mist_dual_video #(.COLOR_DEPTH(8),.OUT_COLOR_DEPTH(VGA_BITS),.SD_HCNT_WIDTH(10),.USE_BLANKS(1'b1),.BIG_OSD(BIG_OSD)) mist_video(
//`ifdef DUAL_SDRAM
//	.clk_sys(clk2_72),
//`else
	.clk_sys(clk_72),
//`endif
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(r),
	.G(g),
	.B(b),
	.HSync(~hs),
	.VSync(~vs),
	.HBlank(hb),
	.VBlank(vb),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
`ifdef USE_HDMI
	.HDMI_R         ( HDMI_R           ),
	.HDMI_G         ( HDMI_G           ),
	.HDMI_B         ( HDMI_B           ),
	.HDMI_VS        ( HDMI_VS          ),
	.HDMI_HS        ( HDMI_HS          ),
	.HDMI_DE        ( HDMI_DE          ),
`endif
/*
`ifdef DUAL_SDRAM
	.clk_sdram      ( clk2_72          ),
	.sdram_init     ( ~pll2_locked     ),
	.SDRAM_A        ( SDRAM2_A         ),
	.SDRAM_DQ       ( SDRAM2_DQ        ),
	.SDRAM_DQML     ( SDRAM2_DQML      ),
	.SDRAM_DQMH     ( SDRAM2_DQMH      ),
	.SDRAM_nWE      ( SDRAM2_nWE       ),
	.SDRAM_nCAS     ( SDRAM2_nCAS      ),
	.SDRAM_nRAS     ( SDRAM2_nRAS      ),
	.SDRAM_nCS      ( SDRAM2_nCS       ),
	.SDRAM_BA       ( SDRAM2_BA        ),
	.rotate_screen  ( rotate_screen    ),
	.rotate_hfilter ( rotate_filter    ),
	.rotate_vfilter ( rotate_filter    ),
`endif
*/
	.no_csync(no_csync),
	.rotate({~flipped,rotate}),
	.ce_divider(4'd11), // pix clock = 72/12
	.blend(blend),
	.scandoubler_disable(scandoublerD),
	.scanlines(scanlines),
	.ypbpr(ypbpr)
	);

`ifdef USE_HDMI

i2c_master #(72_000_000) i2c_master (
	.CLK         (clk_72),

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

assign HDMI_PCLK = clk_72;

`endif

dac #(16) dacl(
	.clk_i(clk_72),
	.res_n_i(1),
	.dac_i({~laudio[15], laudio[14:0]}),
	.dac_o(AUDIO_L)
	);

dac #(16) dacr(
	.clk_i(clk_72),
	.res_n_i(1),
	.dac_i({~raudio[15], raudio[14:0]}),
	.dac_o(AUDIO_R)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_72),
	.clk_rate(32'd72_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan({{2{laudio[15]}}, laudio[14:1]}),
	.right_chan({{2{raudio[15]}}, raudio[14:1]})
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clk_72) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clk_72),
	.clk_rate_i(32'd72_000_000),
	.spdif_o(SPDIF),
	.sample_i({{2{raudio[15]}}, raudio[14:1], {2{laudio[15]}}, laudio[14:1]})
);
`endif

// Common inputs
wire m_up1, m_down1, m_left1, m_right1, m_up1B, m_down1B, m_left1B, m_right1B;
wire m_up2, m_down2, m_left2, m_right2, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_up3, m_down3, m_left3, m_right3, m_up3B, m_down3B, m_left3B, m_right3B;
wire m_up4, m_down4, m_left4, m_right4, m_up4B, m_down4B, m_left4B, m_right4B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
wire [11:0] m_fire1, m_fire2, m_fire3, m_fire4;

arcade_inputs #(.START1(8), .START2(9), .COIN1(10), .COIN2(11)) inputs (
	.clk         ( clk_72      ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( {~flipped, tate ^ |rotate_screen} ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_up1B, m_down1B, m_left1B, m_right1B, m_fire1, m_up1, m_down1, m_left1, m_right1} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, m_fire2, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_up3B, m_down3B, m_left3B, m_right3B, m_fire3, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_up4B, m_down4B, m_left4B, m_right4B, m_fire4, m_up4, m_down4, m_left4, m_right4} )
);

endmodule
