module VicDual_MiST(
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
	"CARNIVAL;;",
	"O2,Rotate Controls,Off,On;",
	"OWX,Orientation,Vertical,Clockwise,Anticlockwise;",
	"OY,Rotation filter,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	`SEP
	"DIP;",
	`SEP
	"T0,Reset;",
	"V,v0.00.",`BUILD_DATE
};

wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];
wire        joyswap = status[6];
wire  [1:0] rotate_screen = status[33:32];
wire        rotate_filter = status[34];

assign LED = ~ioctl_downl;
assign AUDIO_R = AUDIO_L;

wire clk_mem, clk_vid, clk_sys, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_mem),//61.87392
	.c1(clk_vid),//30.936960
	.c2(clk_sys),//15.468480
	.locked(pll_locked)
	);

assign SDRAM_CLK = clk_mem;
assign SDRAM_CKE = 1;

wire  [7:0] core_mod;
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
	.STRLEN(($size(CONF_STR)>>3)),
	.FEATURES(32'h0 | (BIG_OSD << 13) | (HDMI << 14)))
user_io (
	.clk_sys        (clk_sys        ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
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

reg         port1_req, port1_progress;
wire        port1_ack;
wire        sdram_download = ioctl_downl && ioctl_wr && ioctl_index == 8'd0;
wire [7:0]  sdram_dout = !sdram_addr[0] ? wav_data_o[7:0] : wav_data_o[15:8];
wire [24:0] sdram_addr, sdram_addr_old;
reg         sdram_ack;
wire        sdram_rd;
wire        sdram_ready;
wire [15:0] wav_data_o;

always @(posedge clk_mem) begin
	reg sdram_rd_old = 0, ioctl_wr_old = 0;
	ioctl_wr_old <= ioctl_wr;
	sdram_addr_old <= sdram_addr;

	if (sdram_download) begin
		sdram_rd_old <= 0;
		port1_progress <= 0;
		if (~ioctl_wr_old & ioctl_wr) begin
			port1_req <= ~port1_req;
		end
	end else begin
		sdram_rd_old <= sdram_rd;
		if (!sdram_rd_old && sdram_rd) begin
			if (sdram_addr[24:1] != sdram_addr_old[24:1]) begin
				port1_req <= ~port1_req;
				port1_progress <= 1;
			end
			else sdram_ack <= ~sdram_ack;
		end
		if (port1_req == port1_ack && port1_progress) begin
			sdram_ack <= ~sdram_ack;
			port1_progress <= 0;
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

reg	 [15:0] audio;
wire        hs, vs, hb, vb;
wire  [7:0] r,g,b;

system system_inst(
	.clk					(clk_sys),
	.reset				(reset),
	.game_mode			(game_mode),
	.pause				(btn_pause),
	.coin					(btn_coin),
	.dual_game_toggle	(btn_dual_game_toggle),
	.in_p1				(IN_P1),
	.in_p2				(IN_P2),
	.in_p3				(IN_P3),
	.in_p4				(IN_P4),
	.rgb					({b,g,r}),
	.vsync				(vs),
	.hsync				(hs),
	.vblank				(vb),
	.hblank				(hb),
	.audio				(audio),
	.dn_addr				(ioctl_addr),
	.dn_index			(ioctl_addr < 16'h8480 ? 8'd0 : ioctl_addr < 16'h8500 ? 8'd3 : 8'd2),
	.dn_download		(ioctl_downl),
	.dn_wr				(ioctl_wr),
	.dn_data				(ioctl_dout),
	.sdram_addr			(sdram_addr),
	.sdram_rd			(sdram_rd),
	.sdram_ack			(sdram_ack),
	.sdram_dout			(sdram_dout)
);

mist_dual_video #(.COLOR_DEPTH(8), .SD_HCNT_WIDTH(11), .OUT_COLOR_DEPTH(VGA_BITS), .USE_BLANKS(1'b1), .BIG_OSD(BIG_OSD)) mist_video(
	.clk_sys        ( clk_mem          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( b                ),
	.HBlank         ( hb               ),
	.VBlank         ( vb               ),
	.HSync          ( ~hs              ),
	.VSync          ( ~vs              ),
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

	.ram_din        ( {ioctl_dout, ioctl_dout} ),
	.ram_dout       ( wav_data_o ),
	.ram_addr       ( ioctl_downl ? ioctl_addr[22:1] - 16'h4280 : sdram_addr[22:1] ),
	.ram_ds         ( ioctl_downl ? { ioctl_addr[0], ~ioctl_addr[0] } : 2'b11 ),
	.ram_req        ( port1_req        ),
	.ram_we         ( ioctl_downl      ),
	.ram_ack        ( port1_ack        ),

	.rotate         ( { 1'b0, rotate } ),
	.ce_divider     ( 4'd11            ),
	.blend          ( blend            ),
	.scandoubler_disable (scandoublerD ),
	.rotate_screen  ( rotate_screen    ),
	.rotate_hfilter ( rotate_filter    ),
	.rotate_vfilter ( rotate_filter    ),
	.no_csync       ( no_csync         ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            )
	);

`ifdef USE_HDMI

i2c_master #(15_000_000) i2c_master (
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

	assign HDMI_PCLK = clk_vid;
`endif

dac #(.C_bits(16))dac(
	.clk_i(clk_vid),
	.res_n_i(1),
	.dac_i({~audio[15],audio[14:0]}),
	.dac_o(AUDIO_L)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_vid),
	.clk_rate(32'd30_936_960),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan(audio),
	.right_chan(audio)
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clk_vid) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clk_vid),
	.clk_rate_i(32'd30_936_960),
	.spdif_o(SPDIF),
	.sample_i({2{audio}})
);
`endif
// Arcade inputs
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
        
arcade_inputs #(.START1(10), .START2(12), .COIN1(11)) inputs (
	.clk         ( clk_sys    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( {landscape, ~|rotate_screen} ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( ~simultaneous2player ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

///////////////////   CONTROLS   ////////////////////
wire [9:0] Controls1 = {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right}; 
wire [9:0] Controls2 = {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2};
reg simultaneous2player;
wire p1_right = Controls1[0];
wire p2_right = Controls2[0];
wire p1_left = Controls1[1];
wire p2_left = Controls2[1];
wire p1_down = Controls1[2];
wire p2_down = Controls2[2];
wire p1_up = Controls1[3];
wire p2_up = Controls2[3];
wire p1_fire1 = Controls1[4];
wire p2_fire1 = Controls2[4];
wire p1_fire2 = Controls1[5];
wire p2_fire2 = Controls2[5];
wire p1_fire3 = Controls1[6];
//wire p2_fire3 = simultaneous2player ? Controls2[6] : joy[6];	//unused

wire start_p1 = m_one_player;
wire start_p2 = m_two_players;
wire btn_coin = m_coin1;
wire btn_pause = 1'b0;
wire btn_dual_game_toggle = m_tilt;

///////////////////   DIPS   ////////////////////
wire [7:0] sw[8];
assign sw[0] = status[23:16];

// Game metadata
`include "../rtl/games.v"

// Extract per-game DIPs
// - Alpha Fighter / Head On
wire dip_alphafighter_headon_lives = sw[0][0];
wire [1:0] dip_alphafighter_lives = sw[0][2:1];
wire dip_alphafighter_bonuslifeforfinalufo = sw[0][3];
wire dip_alphafighter_bonuslife = sw[0][4];
// - Borderline
wire dip_borderline_cabinet = sw[0][0];
wire dip_borderline_bonuslife = sw[0][1];
wire [2:0] dip_borderline_lives = sw[0][4:2];
// - Car Hunt / Deep Scan (France) & Invinco + Car Hunt (Germany)
wire [1:0] dip_carhunt_dual_game1_lives = sw[0][1:0];
wire [1:0] dip_carhunt_dual_game2_lives = sw[0][3:2];
// - Carnival
wire dip_carnival_demosounds = sw[0][0];
// - Digger
wire [1:0] dip_digger_lives = sw[0][1:0];
// - Frogs
wire dip_frogs_demosounds = sw[0][0];
wire dip_frogs_freegame = sw[0][1];
wire dip_frogs_gametime = sw[0][2];
wire dip_frogs_coinage = sw[0][3];
// - Head On
wire dip_headon_demosounds = sw[0][0];
wire [1:0] dip_headon_lives = sw[0][2:1];
// - Head On 2
wire dip_headon2_demosounds = sw[0][0];
wire [1:0] dip_headon2_lives = sw[0][2:1];
// - Heiankyo Alien
wire dip_heiankyo_2player = sw[0][0];
wire dip_heiankyo_lives = sw[0][1];
// - Invinco
wire [1:0] dip_invinco_lives = sw[0][1:0];
// - Invinco / Deep Scan
wire [1:0] dip_invinco_deepscan_game1_lives = sw[0][1:0];
wire [1:0] dip_invinco_deepscan_game2_lives = sw[0][3:2];
// - Invinco / Head On 2
wire [1:0] dip_invinco_headon2_game1_lives = sw[0][1:0];
wire [1:0] dip_invinco_headon2_game2_lives = sw[0][3:2];
// - N-Sub

// - Pulsar
wire [1:0] dip_pulsar_lives = sw[0][1:0];
// - Safari

// - Samurai
wire dip_samurai_lives = sw[0][0];
// - Space Attack
wire dip_spaceattack_bonuslifeforfinalufo = sw[0][0];
wire [2:0] dip_spaceattack_lives = (sw[0][2:1] == 2'd0) ? DIP_SPACEATTACK_LIVES_3 :
									(sw[0][2:1] == 2'd1) ? DIP_SPACEATTACK_LIVES_4 :
									(sw[0][2:1] == 2'd2) ? DIP_SPACEATTACK_LIVES_5 :
									DIP_SPACEATTACK_LIVES_6;
wire dip_spaceattack_bonuslife = sw[0][3]; 
wire dip_spaceattack_creditsdisplay = sw[0][4];
// - Space Attack + Head On
wire dip_spaceattack_headon_bonuslifeforfinalufo = sw[0][0];
wire [1:0] dip_spaceattack_headon_game1_lives = sw[0][2:1];
wire dip_spaceattack_headon_bonuslife = sw[0][3]; 
wire dip_spaceattack_headon_creditsdisplay = sw[0][4];
wire dip_spaceattack_headon_game2_lives = sw[0][5];
// - Space Trek
wire dip_spacetrek_lives = sw[0][0];
wire dip_spacetrek_bonuslife = sw[0][1];
// - Star Raker
wire dip_starraker_cabinet = sw[0][0];
wire dip_starraker_bonuslife = sw[0][1];
// - Sub Hunt

// - Tranquilizer Gun
// N/A
// - Wanted
wire dip_wanted_cabinet = sw[0][0];
wire dip_wanted_bonuslife = sw[0][1];
wire [1:0] dip_wanted_lives = sw[0][3:2];


///////////////////   CORE INPUTS   ////////////////////
wire  [4:0] game_mode = core_mod[4:0]/*verilator public_flat*/;
reg	[7:0]	IN_P1;
reg	[7:0]	IN_P2;
reg	[7:0]	IN_P3;
reg	[7:0]	IN_P4;
reg			landscape;

always @(posedge clk_sys) 
begin
	// Set defaults
	landscape <= 1'b0;
	simultaneous2player <= 1'b0;

	IN_P1 <= 8'hFF;
	IN_P2 <= 8'hFF;
	IN_P3 <= 8'hFF;
	IN_P4 <= 8'hFF;

	// Game specific inputs
	case (game_mode)
		GAME_ALPHAFIGHTER:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, dip_alphafighter_headon_lives, dip_alphafighter_lives[0], ~p2_fire1, ~p2_up };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_alphafighter_lives[1], 1'b1, ~p2_right };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_alphafighter_bonuslife, 1'b1, ~p2_down };
			IN_P4 <= { 2'b11, ~start_p2, 2'b11, dip_alphafighter_bonuslifeforfinalufo, 1'b1, ~p2_left };
		end
		GAME_BORDERLINE:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, dip_borderline_cabinet, dip_borderline_lives[0], ~p1_fire1, ~p1_up };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_borderline_lives[1], ~p1_fire1, ~p1_right };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_borderline_lives[2], 1'b1, ~p1_down };
			IN_P4 <= { 2'b11, ~start_p2, 2'b11, dip_borderline_bonuslife, 1'b1, ~p1_left };
		end
		GAME_CARHUNT_DUAL:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_carhunt_dual_game1_lives[0], 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_carhunt_dual_game1_lives[1], 2'b11 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_carhunt_dual_game2_lives[0], 2'b11 };
			IN_P4 <= { 2'b11, ~start_p2, ~p1_fire2, 1'b1, dip_carhunt_dual_game2_lives[1], 2'b11 };
		end
		GAME_CARNIVAL:
		begin
			IN_P1 <= { 3'b111, dip_carnival_demosounds, 4'b1111 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 4'b1011 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 4'b1111 };
			IN_P4 <= { 2'b11, ~start_p2, 5'b11111 };
		end
		GAME_DIGGER:
		begin
			IN_P1 <= { ~p1_up, ~p1_left, ~p1_down, ~p1_right, ~p1_fire2, ~p1_fire1, ~start_p2, ~start_p1 };
			IN_P3 <= { 6'b111111, dip_digger_lives };
		end
		GAME_FROGS:
		begin
			IN_P1 <= { ~p1_fire1, dip_frogs_coinage, dip_frogs_gametime, dip_frogs_freegame, dip_frogs_demosounds, ~p1_left, ~p1_up, ~p1_right };
			landscape <= 1'b1;
		end
		GAME_HEADON:
		begin
			IN_P1 <= { ~p1_up, ~p1_left, ~p1_down, ~p1_right, ~p1_fire1, dip_headon_demosounds, dip_headon_lives };
			landscape <= 1'b1;
		end
		GAME_HEADON2:
		begin
			IN_P1 <= { ~p1_up, ~p1_left, ~p1_down, ~p1_right, ~p1_fire1, 1'b1, ~start_p2, ~start_p1 };
			IN_P3 <= { 3'b111, dip_headon2_lives, 3'b111 };
			IN_P4 <= { 6'b111111, dip_headon2_demosounds, 1'b1 };
			landscape <= 1'b1;
		end
		GAME_HEIANKYO:
		begin
			IN_P1 <= { 2'b11, ~p1_fire1, ~p1_up, dip_heiankyo_2player, 1'b1, ~p2_fire2, ~p2_up };
			IN_P2 <= { 2'b11, ~p1_fire2, ~p1_right, 2'b01, ~p2_fire2, ~p2_right };
			IN_P3 <= { 3'b110, ~p1_down, 3'b110, ~p1_down };
			IN_P4 <= { 2'b11, ~start_p1, ~p1_left, 1'b1, dip_heiankyo_lives, ~start_p2, ~p2_left };
			simultaneous2player <= ~dip_heiankyo_2player;
		end
		GAME_INVINCO:
		begin
			IN_P1 <= { 1'b1, ~p1_left, 1'b1, ~p1_right, ~p1_fire1, 1'b1, ~start_p2, ~start_p1 };
			IN_P3 <= { 6'b11, dip_invinco_lives };
		end
		GAME_INVINCO_DEEPSCAN:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_invinco_deepscan_game1_lives[0], 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_invinco_deepscan_game1_lives[1], 2'b11 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_invinco_deepscan_game2_lives[0], 2'b11 };
			IN_P4 <= { 2'b11, ~start_p2, ~p1_fire2, 1'b1, dip_invinco_deepscan_game2_lives[1], 2'b11 };
		end
		GAME_INVINCO_HEADON2:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_invinco_headon2_game1_lives[0], 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_invinco_headon2_game1_lives[1], 2'b11 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_invinco_headon2_game2_lives[0], 2'b11 };
			IN_P4 <= { 2'b11, ~start_p2, ~p1_fire2, 1'b1, dip_invinco_headon2_game2_lives[1], 2'b11 };
		end
		GAME_NSUB:
		begin
			IN_P1 <= ~{ p1_up, p1_left, p1_down, p1_right, p1_fire2, p1_fire1, start_p2, start_p1 };
		end
		GAME_PULSAR:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_pulsar_lives[0], 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_pulsar_lives[1], 2'b11 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 4'b1111 };
			IN_P4 <= { 2'b11, ~start_p2, 5'b11111 };
		end
		GAME_SAFARI:
		begin
			IN_P1 <= { ~p1_fire1, 1'b0, ~p1_fire3, ~p1_fire2, ~p1_left, ~p1_right, ~p1_down, ~p1_up };
			landscape <= 1'b1;
		end
		GAME_SAMURAI:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_samurai_lives, 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 4'b1111 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 4'b1111 };
			IN_P4 <= { 2'b11, ~start_p2, 5'b11111 };
		end
		GAME_SPACEATTACK:
		begin
			IN_P1 <= { ~p1_left, ~p2_left, ~p2_right, ~p2_fire1, ~start_p2, ~start_p1, ~p1_fire1, ~p1_right };
			IN_P3 <= { dip_spaceattack_creditsdisplay, 2'b11, dip_spaceattack_bonuslife, dip_spaceattack_lives, dip_spaceattack_bonuslifeforfinalufo };
		end
		GAME_SPACEATTACK_HEADON:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, dip_spaceattack_headon_game2_lives, dip_spaceattack_headon_game1_lives[0], ~p2_fire1, ~p2_up };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_spaceattack_headon_game1_lives[1], 1'b1, ~p2_right };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_spaceattack_headon_bonuslife, 1'b1, ~p2_down };
			IN_P4 <= { 2'b11, ~start_p2, 2'b11, dip_spaceattack_headon_bonuslifeforfinalufo, 1'b1, ~p2_left };
		end
		GAME_SPACETREK:
		begin
			IN_P1 <= { 2'b11, ~p1_left, ~p1_right, 1'b1, dip_spacetrek_lives, 2'b11 };
			IN_P2 <= { 2'b11, ~p1_up, ~p1_down, 4'b1111 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_spacetrek_bonuslife, 2'b11 };
			IN_P4 <= { 2'b11, ~start_p2, ~p1_fire2, 4'b1111 };
		end
		GAME_STARRAKER:
		begin
			IN_P1 <= { 2'b11, ~p1_left, ~p1_right, dip_starraker_cabinet, 1'b1, ~p1_fire1, ~p1_up };
			IN_P2 <= { 2'b11, ~p1_up, ~p1_down, 2'b11, ~p1_fire1, ~p1_right };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 3'b111, ~p1_down };
			IN_P4 <= { 2'b11, ~start_p2, 2'b11, dip_starraker_bonuslife, 1'b1, ~p1_left };
		end
		GAME_SUBHUNT:
		begin
			// IN_P1 <= ~{ 2'b0, p1_left, p1_right, 2'b0, p1_fire1, p1_up };
			// IN_P2 <= ~{ 2'b0, p1_up, p1_down, 2'b0, p1_fire1, p1_right };
			// IN_P3 <= ~{ 2'b0, p1_fire1, start_p1, 3'b0, p1_down };
			// IN_P4 <= ~{ 2'b0, start_p2, 4'b0, p1_left };
		end
		GAME_TRANQUILIZERGUN:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 2'b11, ~p1_fire1, ~p1_up };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 3'b111, ~p1_right };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 3'b111, ~p1_down };
			IN_P4 <= { 2'b11, ~start_p2, 4'b1111, ~p1_left };
		end
		GAME_WANTED:
		begin
			IN_P1 <= { 2'b11, ~p1_up, ~p1_down, 1'b1, dip_wanted_lives[0], 2'b11 };
			IN_P2 <= { 2'b11, ~p1_right, ~p1_left, 1'b1, dip_wanted_lives[1], 2'b11 };
			IN_P3 <= { 2'b11, ~p1_fire1, ~start_p1, 1'b1, dip_wanted_cabinet, 2'b11 };
			IN_P4 <= { 2'b11, ~start_p2, ~p1_fire2, 1'b1, dip_wanted_bonuslife, 2'b11 };
		end
	endcase
end

endmodule 