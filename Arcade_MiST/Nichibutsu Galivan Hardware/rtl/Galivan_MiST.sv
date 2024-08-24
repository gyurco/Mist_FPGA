module Galivan_MiST (
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
/*
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
*/
`include "build_id.v"

localparam CONF_STR = {
	"GALIVAN;;",
	"O2,Rotate Controls,Off,On;",
`ifdef DUAL_SDRAM
	"OWX,Orientation,Vertical,Clockwise,Anticlockwise;",
	"OY,Rotation filter,Off,On;",
`endif
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"O8,Test mode,Off,On;",
	"O1,Pause,Off,On;",
	`SEP
	"DIP;",
	`SEP
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire        pause = status[1];
wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];
wire        joyswap = status[6];
wire        service = status[8];
wire  [1:0] rotate_screen = status[33:32];
wire        rotate_filter = status[34];

wire        flip;
wire  [1:0] orientation = {flip, 1'b1};

wire  [7:0] j1 = ~{ m_fire1[2], 1'b0, m_fire1[1], m_fire1[0], m_right1, m_left1, m_down1, m_up1 };
wire  [7:0] j2 = ~{ m_fire2[2], 1'b0, m_fire2[1], m_fire2[0], m_right2, m_left2, m_down2, m_up2 };
wire  [7:0] p1 = ~status[23:16]; // dsw1
wire  [7:0] p2 = ~status[31:24]; // dsw2

wire  [7:0] system = ~{ 3'b000, service, m_coin2, m_coin1, m_two_players, m_one_player };

assign 		LED = ~ioctl_downl;
assign 		SDRAM_CLK = clk_ram;
assign 		SDRAM_CKE = 1;

wire clk_sys, clk_ram, pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(clk_ram),
	.c1(clk_sys),
	.locked(pll_locked)
	);

`ifdef DUAL_SDRAM
wire pll2_locked;
pll_mist pll2(
	.inclk0(CLOCK_27),
	.c0(SDRAM2_CLK),
	.locked(pll2_locked)
	);
assign SDRAM2_CKE = 1;
`endif

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire  [6:0] core_mod;
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
	.STRLEN(($size(CONF_STR)>>3)),
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

wire [15:0] cpu1_rom_addr;
wire [15:0] cpu1_rom_do;
wire        cpu1_rom_cs;
wire        cpu1_rom_valid;
wire [15:0] cpu2_rom_addr;
wire [15:0] cpu2_rom_do;
wire        cpu2_rom_cs;
wire        cpu2_rom_valid;

wire [13:0] gfx1_rom_addr;
wire [15:0] gfx1_rom_do;
wire [16:0] gfx2_rom_addr;
wire [15:0] gfx2_rom_do;
wire [15:0] gfx3_rom_addr;
wire [15:0] gfx3_rom_do;
wire        gfx3_rom_ready;

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_din;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clk_sys      ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_upload  ( ioctl_upl    ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_din     ( ioctl_din    ),
	.ioctl_dout    ( ioctl_dout   )
);

reg port1_req, port2_req;
sdram #(96) sdram(
	.*,
	.init_n        ( pll_locked     ),
	.clk           ( clk_ram        ),

	// port1 for main and sound CPU
	.port1_req     ( port1_req      ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( rom_init       ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_cs       ( cpu1_rom_cs    ),
	.cpu1_addr     ( {1'b0, cpu1_rom_addr[15:1]} ),
	.cpu1_q        ( cpu1_rom_do    ),
	.cpu1_valid    ( cpu1_rom_valid ),
	.cpu2_cs       ( cpu2_rom_cs    ),
	.cpu2_addr     ( {1'b1, cpu2_rom_addr[15:1]} ),
	.cpu2_q        ( cpu2_rom_do    ),
	.cpu2_valid    ( cpu2_rom_valid ),

	// port2 for graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( ioctl_addr[23:1] ),
	.port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port2_we      ( rom_init ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.gfx1_addr      ( 27'he000 + gfx1_rom_addr[13:1] ),
	.gfx1_q         ( gfx1_rom_do ),
	.gfx2_addr      ( 27'h10000 + gfx2_rom_addr[16:1] ),
	.gfx2_q         ( gfx2_rom_do ),
	.gfx3_addr      ( 27'h20000 + gfx3_rom_addr[15:1] ),
	.gfx3_q         ( gfx3_rom_do ),
	.gfx3_ready     ( gfx3_rom_ready )
);

// ROM download controller
always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (rom_init) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sys) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end


wire [15:0] sound;
wire HBlank;
wire HSync;
wire VBlank;
wire VSync;
wire [8:0] hcount, vcount;
reg  [2:0] vred, vgreen;
reg  [1:0] vblue;

wire ce_pix;

video video(
  .clk    ( clk_sys ),
  .ce_pix ( ce_pix  ),
  .hs     ( HSync   ),
  .vs     ( VSync   ),
  .hb     ( HBlank  ),
  .vb     ( VBlank  ),
  .hcount ( hcount  ),
  .vcount ( vcount  ),
  .hoffs  (),
  .voffs  ()
);

wire rom_init = ioctl_downl && (ioctl_index==0);
//wire nvram_init = ioctl_downl && (ioctl_index==8'hFF);

core u_core(
	.reset          ( reset            ),
	.clk_sys        ( clk_sys          ),
	.ce_pix         ( ce_pix           ),
	.pause          ( pause            ),
	.j1             ( j1               ),
	.j2             ( j2               ),
	.p1             ( p1               ),
	.p2             ( p2               ),
	.system         ( system           ),
	.ioctl_index    ( ioctl_index      ),
	.ioctl_download ( rom_init         ),
	.ioctl_addr     ( ioctl_addr       ),
	.ioctl_dout     ( ioctl_dout       ),
	.ioctl_wr       ( ioctl_wr         ),
	.hh             ( hcount           ),
	.vv             ( vcount           ),
	.red            ( vred             ),
	.green          ( vgreen           ),
	.blue           ( vblue            ),
	.vs             ( VSync            ),
	.hb             ( HBlank           ),
	.sound          ( sound            ),
	.hflip          ( flip             ),
	.bg_on          ( 1'b1             ),
	.tx_on          ( 1'b1             ),
	.sp_on          ( 1'b1             ),
	.fdiv           ( 2'b0             ),

	.cpu1_rom_cs    ( cpu1_rom_cs      ),
	.cpu1_rom_addr  ( cpu1_rom_addr    ),
	.cpu1_rom_q     ( cpu1_rom_addr[0] ? cpu1_rom_do[15:8] : cpu1_rom_do[7:0] ),
	.cpu1_rom_valid ( cpu1_rom_valid   ),
	.cpu2_rom_cs    ( cpu2_rom_cs      ),
	.cpu2_rom_addr  ( cpu2_rom_addr    ),
	.cpu2_rom_q     ( cpu2_rom_addr[0] ? cpu2_rom_do[15:8] : cpu2_rom_do[7:0] ),
	.cpu2_rom_valid ( cpu2_rom_valid   ),

	.gfx1_rom_addr  ( gfx1_rom_addr    ),
	.gfx1_rom_q     ( gfx1_rom_addr[0] ? gfx1_rom_do[15:8] : gfx1_rom_do[7:0] ),
	.gfx2_rom_addr  ( gfx2_rom_addr    ),
	.gfx2_rom_q     ( gfx2_rom_addr[0] ? gfx2_rom_do[15:8] : gfx2_rom_do[7:0] ),
	.gfx3_rom_addr  ( gfx3_rom_addr    ),
	.gfx3_rom_q     ( gfx3_rom_addr[0] ? gfx3_rom_do[15:8] : gfx3_rom_do[7:0] ),
	.gfx3_rom_ready ( gfx3_rom_ready   )
);

mist_dual_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(VGA_BITS), .BIG_OSD(BIG_OSD), .USE_BLANKS(1'b1)) mist_video(
	.clk_sys        ( clk_ram          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( vred             ),
	.G              ( vgreen           ),
	.B              ( {vblue, vblue[1]}),
	.HBlank         ( HBlank           ),
	.VBlank         ( VBlank           ),
	.HSync          ( HSync            ),
	.VSync          ( VSync            ),
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
`ifdef DUAL_SDRAM
	.clk_sdram      ( clk_ram          ),
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
`endif
	.ce_divider     ( 4'd15            ),
	.rotate         ( { orientation[1], rotate } ),
	.rotate_screen  ( rotate_screen    ),
	.rotate_hfilter ( rotate_filter    ),
	.rotate_vfilter ( rotate_filter    ),
	.blend          ( blend            ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

`ifdef USE_HDMI
i2c_master #(48_000_000) i2c_master (
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

assign HDMI_PCLK = clk_sys;
`endif

wire audio_out;
assign AUDIO_L = audio_out;
assign AUDIO_R = audio_out;

dac #(.C_bits(16))dac(
	.clk_i(clk_sys),
	.res_n_i(1'b1),
	.dac_i({~sound[15], sound[14:0]}),
	.dac_o(audio_out)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_sys),
	.clk_rate(32'd48_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan({1'b0, ~sound[15], sound[14:1]}),
	.right_chan({1'b0, ~sound[15], sound[14:1]})
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clk_sys) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clk_sys),
	.clk_rate_i(32'd48_000_000),
	.spdif_o(SPDIF),
	.sample_i({2{1'b0, ~sound[15], sound[14:1]}})
);
`endif

wire m_up1, m_down1, m_left1, m_right1, m_up1B, m_down1B, m_left1B, m_right1B;
wire m_up2, m_down2, m_left2, m_right2, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
wire [11:0] m_fire1, m_fire2;

arcade_inputs #(.START1(10), .START2(12), .COIN1(11)) inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( orientation ^ {1'b0, |rotate_screen} ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_up1B, m_down1B, m_left1B, m_right1B, m_fire1, m_up1, m_down1, m_left1, m_right1} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, m_fire2, m_up2, m_down2, m_left2, m_right2} )
);

endmodule
