module MissileCommand_MiST(
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

assign SDRAM_A = 13'hZZZZ;
assign SDRAM_BA = 0;
assign SDRAM_DQML = 1;
assign SDRAM_DQMH = 1;
assign SDRAM_CKE = 0;
assign SDRAM_CLK = 0;
assign SDRAM_nCS = 1;
assign SDRAM_DQ = 16'hZZZZ;
assign SDRAM_nCAS = 1;
assign SDRAM_nRAS = 1;
assign SDRAM_nWE = 1;

`include "build_id.v"

localparam CONF_STR = {
	"MISSILE;;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O1,Pause,Off,On;",
	"O2,Blend,Off,On;",
	`SEP
	"P1,Switches;",
	"P1O89,Coinage,1C_1C,2C_1C,Free_Play,1C_2C;",
	"P1OA,Service,Off,On;",
	"P1OBC,Language,English,French,German,Spanish;",
	"P1ODE,Cities,6,4,5,7;",
	"P1OF,Bonus Credit for 4 Coins,Off,On;",
	
	"P1OG,Trackball Size,Large,Mini;",
	"P1OHJ,Bonus City,None,8000,20000,18000,15000,14000,12000,10000;",
	"P1OK,Cabinet,Upright,Cocktail;",
	`SEP
	"OOP,Mouse/trackball speed,25%,50%,100%,200%;",
	"OQR,Button order,LMR,LRM,MRL,MLR;",
	"OS,Joystick mode,Digital,Analog;",
	"OT,Joystick speed,Low,High;",
	`SEP
	"T0,Reset;",
	"V,v1.0.",`BUILD_DATE
};

wire        pause  = status[1];
wire [1:0]  scanlines = status[4:3];
wire        blend  = status[2];
wire        service = status[10];

wire		dip_cocktail = ~status[20];		// 1= Upright, 0=Cocktail (enable flip)
wire [1:0]	dip_language = status[12:11];
wire		dip_centrecoin = 1'b0;		// Coin multipliers are unnecessary
wire [1:0]	dip_rightcoin = 2'b00;		// Coin multipliers are unnecessary
wire [1:0]	dip_coinage = status[9:8];
wire [1:0]	dip_cities = status[14:13];
wire		dip_bonuscredit = status[15];		// Not useful
wire [2:0]	dip_bonuscity = ~status[19:17];
wire		dip_trackballspeed = status[16];

wire [7:0]	in2 = { 1'b0, dip_language, dip_centrecoin, dip_rightcoin, dip_coinage };
wire [7:0]	dip_switches = { dip_cocktail, dip_bonuscity, dip_trackballspeed, dip_bonuscredit, dip_cities };

assign LED = ~ioctl_downl;
assign AUDIO_R = AUDIO_L;
assign SDRAM_CKE = 0;

wire clk_sys, clk_core;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys),//40
	.c1(clk_core),//10
	.locked(pll_locked)
	);

reg ce_vid = 1'b0;
always @(posedge clk_core) ce_vid <= !ce_vid;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clk_core     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire [31:0] joystick_analog_0;
wire [31:0] joystick_analog_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire  [8:0] mouse_x;
wire  [8:0] mouse_y;
wire  [7:0] mouse_flags;  // YOvfl, XOvfl, dy8, dx8, 1, mbtn, rbtn, lbtn
wire        mouse_strobe;
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
	.clk_sys        (clk_core       ),
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
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.mouse_strobe   (mouse_strobe   ),
	.mouse_x        (mouse_x        ),
	.mouse_y        (mouse_y        ),
	.mouse_flags    (mouse_flags    ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.joystick_analog_0(joystick_analog_0),
	.joystick_analog_1(joystick_analog_1),
	.status         (status         )
	);

reg mouse_left, mouse_right, mouse_center;
wire [24:0] ps2_mouse = { mouse_strobe_level, mouse_y[7:0], mouse_x[7:0], mouse_flags };
reg         mouse_strobe_level;
always @(posedge clk_core) if (mouse_strobe) mouse_strobe_level <= ~mouse_strobe_level;

always @(posedge clk_core)
begin
	case(status[27:26])
	2'd0: // LMR
	begin
		mouse_left <= ps2_mouse[0];
		mouse_center <= ps2_mouse[2];
		mouse_right <= ps2_mouse[1];
	end
	2'd1: // LRM
	begin
		mouse_left <= ps2_mouse[0];
		mouse_center <= ps2_mouse[1];
		mouse_right <= ps2_mouse[2];
	end
	2'd2: // MRL
	begin
		mouse_left <= ps2_mouse[2];
		mouse_center <= ps2_mouse[1];
		mouse_right <= ps2_mouse[0];
	end
	2'd3: // MLR
	begin
		mouse_left <= ps2_mouse[2];
		mouse_center <= ps2_mouse[0];
		mouse_right <= ps2_mouse[1];
	end
	endcase
end

wire [5:0] audio;
wire        hs, vs, hb, vb;
wire			g, r, b;

missile missile_inst(
	.clk_10M				(clk_core),
	.ce_5M					(ce_vid),
	.reset					(status[0] | buttons[1]),
	.pause					(pause),
	.vtb_dir1				(vtb_dir1),
	.vtb_clk1				(vtb_clk1),
	.htb_dir1				(htb_dir1),
	.htb_clk1				(htb_clk1),


	.coin						(m_coin1),
	.p1_start				(m_one_player),
	.p2_start				(m_two_players),
	
	.p1_fire_l				(m_fireA | mouse_left),
	.p1_fire_c				(m_fireB | mouse_center),
	.p1_fire_r				(m_fireC | mouse_right),
	
	.p2_fire_l				(m_fire2A | mouse_left),
	.p2_fire_c				(m_fire2B | mouse_center),
	.p2_fire_r				(m_fire2C | mouse_right),

	.in2						(in2),
	.switches				(dip_switches),
	.self_test				(service),
	.slam						(m_tilt),
	.flip						(flip),
	
	.r							(r),
	.g							(g),
	.b							(b),
	.h_sync					(hs),
	.v_sync					(vs),
	.h_blank					(hb),
	.v_blank					(vb),
	.audio_o					(audio),
	.dn_addr					(ioctl_addr[15:0]),
	.dn_data					(ioctl_dout),
	.dn_wr					(ioctl_wr && ioctl_index == 0)
);

//Trackball
wire 		TB_horiz, TB_vert;
wire		flip;
wire		vtb_dir1;
wire		vtb_clk1;
wire		htb_dir1;
wire		htb_clk1;

trackball trackball
(
	.clk(clk_core),
	.flip(flip),
	.joystick({m_up, m_down, m_left, m_right}),
	.joystick_mode(status[28]),
	.joystick_analog(joystick_analog_0 !=0 ? joystick_analog_0 : joystick_analog_1),
	.joystick_sensitivity(status[29]),
	.mouse_speed(status[25:24]),
	.ps2_mouse(ps2_mouse),
	.v_dir(vtb_dir1),
	.v_clk(vtb_clk1),
	.h_dir(htb_dir1),
	.h_clk(htb_clk1)
);

mist_video #(.COLOR_DEPTH(1), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(VGA_BITS), .USE_BLANKS(1'b1), .BIG_OSD(BIG_OSD)) mist_video(
	.clk_sys        ( clk_sys          ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
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
	.scandoubler_disable(scandoublerD  ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

`ifdef USE_HDMI

i2c_master #(10_000_000) i2c_master (
	.CLK         (clk_core),

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

mist_video #(.COLOR_DEPTH(1), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(8), .USE_BLANKS(1'b1), .BIG_OSD(BIG_OSD)) hdmi_video(
	.clk_sys        ( clk_sys          ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
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
	.VGA_R          ( HDMI_R           ),
	.VGA_G          ( HDMI_G           ),
	.VGA_B          ( HDMI_B           ),
	.VGA_VS         ( HDMI_VS          ),
	.VGA_HS         ( HDMI_HS          ),
	.VGA_DE         ( HDMI_DE          ),
	.scandoubler_disable(1'b0          ),
	.ypbpr          ( 1'b0             ),
	.no_csync       ( 1'b1             )
	);

assign HDMI_PCLK = clk_sys;
`endif

dac #(
	.C_bits(6))
dac_l(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_sys),
	.clk_rate(32'd40_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan({{3{~audio[5]}}, audio[4:0], audio[4:0], audio[4:2]}),
	.right_chan({{3{~audio[5]}}, audio[4:0], audio[4:0], audio[4:2]})
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
	.clk_rate_i(32'd40_000_000),
	.spdif_o(SPDIF),
	.sample_i({2{{3{~audio[5]}}, audio[4:0], audio[4:0], audio[4:2]}})
);
`endif

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs #(.START1(10), .START2(12), .COIN1(11)) inputs (
	.clk         ( clk_core    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 