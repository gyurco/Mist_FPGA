//============================================================================
//  Data East Express Raider top-level for MiST
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

module ExpressRaider_MiST
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
assign SDRAM2_DQML = 0;
assign SDRAM2_DQMH = 0;
assign SDRAM2_CKE = 0;
assign SDRAM2_CLK = 0;
assign SDRAM2_nCS = 1;
assign SDRAM2_DQ = 16'hZZZZ;
assign SDRAM2_nCAS = 1;
assign SDRAM2_nRAS = 1;
assign SDRAM2_nWE = 1;
`endif

`include "build_id.v"

`define CORE_NAME "EXPRRAID"
wire [6:0] core_mod;

localparam CONF_STR = {
	`CORE_NAME, ";;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blending,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"O7,Pause,Off,On;",
	"DIP;",
	"T0,Reset;",
	"V,v1.20.",`BUILD_DATE
};

wire        rotate    = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend     = status[5];
wire        joyswap   = status[6];
wire        pause     = status[7];
wire  [7:0] sw0       = status[15:8];
wire  [7:0] sw1       = status[23:16];

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_96;
assign SDRAM_CKE = 1;

wire clk_96, clk_48;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(clk_96),
	.c1(clk_48),
	.locked(pll_locked)
	);

// reset generation
reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_48) begin
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
	.clk_sys        (clk_48         ),
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
	.clk_sys       ( clk_48       ),
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

wire        rom_cs;
wire [15:0] rom_addr;
wire [15:0] rom_do;
wire        snd_cs;
wire [14:0] snd_addr;
wire [15:0] snd_do;
wire [14:0] gfx1_addr;
wire [15:0] gfx1_do;
wire [14:0] gfx2_addr;
wire [15:0] gfx2_do;
wire [15:0] gfx3_addr;
wire [31:0] gfx3_do;
wire [15:0] sp_addr;
wire [31:0] sp_do;
reg         port1_req, port2_req;
reg  [23:0] port1_a;
reg  [23:0] port2_a;

// ROM download controller
always @(posedge clk_48) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr && ioctl_index == 0) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
end

sdram #(96) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_96       ),

	// port1 used for main + sound CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_cs       ( rom_cs ),
	.cpu1_addr     ( rom_addr[15:1] ),
	.cpu1_q        ( rom_do ),
	.cpu2_cs       ( snd_cs ),
	.cpu2_addr     ( 15'h6000 + snd_addr[14:1] ),
	.cpu2_q        ( snd_do ),
	.gfx1_addr     ( 20'h38000 + gfx1_addr[14:1] ),
	.gfx1_q        ( gfx1_do ),
	.gfx2_addr     ( 20'h2C000 + gfx2_addr[14:1] ),
	.gfx2_q        ( gfx2_do ),

	// port2 for sprite graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] ), 
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.gfx3_addr     ( 20'h18000 + gfx3_addr[14:1] ),
	.gfx3_q        ( gfx3_do ),
	.sp_addr       ( 20'h6000 + sp_addr ),
	.sp_q          ( sp_do )
);

reg   [7:0] gfx3_data;
always @(*)
	case({gfx3_addr[0], gfx3_addr[15]})
	2'b00: gfx3_data = gfx3_do[7:0];
	2'b01: gfx3_data = gfx3_do[15:8];
	2'b10: gfx3_data = gfx3_do[23:16];
	2'b11: gfx3_data = gfx3_do[31:24];
	default: ;
	endcase

wire        rom_dl = ioctl_downl && ioctl_index == 0;
wire [16:0] sound;
wire        HSync, VSync;
wire        HBlank, VBlank;
wire  [3:0] vred, vgreen, vblue;

wire [7:0] p1 = ~{ m_two_players, m_one_player, m_fire1[1], m_fire1[0], m_down1, m_up1, m_left1, m_right1 };
wire [7:0] p2 = ~{ m_coin2, m_coin1, m_fire2[1], m_fire2[0], m_down2, m_up2, m_left2, m_right2 };

core u_core(
  .reset          ( reset            ),
  .clk_sys        ( clk_48           ),
  .pause          ( pause            ),
  .p1             ( p1               ),
  .p2             ( p2               ),
  .p3             ( sw1              ),
  .dsw            ( sw0              ),
  .ioctl_index    ( ioctl_index      ),
  .ioctl_download ( rom_dl           ),
  .ioctl_addr     ( ioctl_addr       ),
  .ioctl_dout     ( ioctl_dout       ),
  .ioctl_wr       ( ioctl_wr         ),
  .red            ( vred             ),
  .green          ( vgreen           ),
  .blue           ( vblue            ),
  .vs             ( VSync            ),
  .vb             ( VBlank           ),
  .hs             ( HSync            ),
  .hb             ( HBlank           ),
  .ce_pix         ( ),
  .sound          ( sound            ),
  .cpu_rom_cs     ( rom_cs           ),
  .cpu_rom_addr   ( rom_addr         ),
  .cpu_rom_data   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
  .audio_rom_cs   ( snd_cs           ),
  .audio_rom_addr ( snd_addr         ),
  .audio_rom_data ( snd_addr[0] ? snd_do[15:8] : snd_do[7:0] ),
  .gfx1_addr      ( gfx1_addr        ),
  .gfx1_data      ( gfx1_addr[0] ? gfx1_do[15:8] : gfx1_do[7:0] ),
  .gfx2_addr      ( gfx2_addr        ),
  .gfx2_data      ( gfx2_addr[0] ? gfx2_do[15:8] : gfx2_do[7:0] ),
  .gfx3_addr      ( gfx3_addr        ),
  .gfx3_data      ( gfx3_data        ),
  .sp_addr        ( sp_addr          ),
  .sp_data        ( sp_do            )
);

mist_video #(.COLOR_DEPTH(4),.SD_HCNT_WIDTH(10),.OUT_COLOR_DEPTH(VGA_BITS),.USE_BLANKS(1'b1),.BIG_OSD(BIG_OSD)) mist_video(
	.clk_sys(clk_48),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(vred  ),
	.G(vgreen),
	.B(vblue ),
	.HBlank(HBlank),
	.VBlank(VBlank),
	.HSync(~HSync),
	.VSync(~VSync),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.no_csync(no_csync),
	.rotate({1'b0,rotate}),
	.ce_divider(3'd0), // pix clock = 48/4
	.blend(blend),
	.scandoubler_disable(scandoublerD),
	.scanlines(scanlines),
	.ypbpr(ypbpr)
	);

`ifdef USE_HDMI

i2c_master #(48_000_000) i2c_master (
	.CLK         (clk_48),

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

mist_video #(.COLOR_DEPTH(4),.SD_HCNT_WIDTH(10),.OUT_COLOR_DEPTH(8),.USE_BLANKS(1'b1),.BIG_OSD(BIG_OSD)) hdmi_video(
	.clk_sys(clk_48),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(vred  ),
	.G(vgreen),
	.B(vblue ),
	.HBlank(HBlank),
	.VBlank(VBlank),
	.HSync(~HSync),
	.VSync(~VSync),
	.VGA_R(HDMI_R),
	.VGA_G(HDMI_G),
	.VGA_B(HDMI_B),
	.VGA_VS(HDMI_VS),
	.VGA_HS(HDMI_HS),
	.VGA_DE(HDMI_DE),
	.no_csync(1'b1),
	.rotate({1'b0,rotate}),
	.ce_divider(3'd0), // pix clock = 48/4
	.blend(blend),
	.scandoubler_disable(1'b0),
	.scanlines(scanlines),
	.ypbpr(1'b0)
	);
assign HDMI_PCLK = clk_48;
`endif

dac #(16) dacl(
	.clk_i(clk_48),
	.res_n_i(1),
	.dac_i({~sound[16], sound[15:1]}),
	.dac_o(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_48),
	.clk_rate(32'd48_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan(sound),
	.right_chan(sound)
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clk_48) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clk_48),
	.clk_rate_i(32'd48_000_000),
	.spdif_o(SPDIF),
	.sample_i({sound, sound})
);
`endif

// Common inputs
wire m_up1, m_down1, m_left1, m_right1, m_up1B, m_down1B, m_left1B, m_right1B;
wire m_up2, m_down2, m_left2, m_right2, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
wire [11:0] m_fire1, m_fire2;

arcade_inputs #(.START1(10), .START2(12), .COIN1(11)) inputs (
	.clk         ( clk_48      ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( 2'b00       ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_up1B, m_down1B, m_left1B, m_right1B, m_fire1, m_up1, m_down1, m_left1, m_right1} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, m_fire2, m_up2, m_down2, m_left2, m_right2} )
);

endmodule
