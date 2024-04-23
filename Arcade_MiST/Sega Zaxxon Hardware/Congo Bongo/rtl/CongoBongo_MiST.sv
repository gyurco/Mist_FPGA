
module CongoBongo_MiST(
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
	"CONGO;;",
	"O2,Rotate Controls,Off,On;",
`ifdef DUAL_SDRAM
	"O89,Orientation,Vertical,Clockwise,Anticlockwise;",
	"OA,Rotation filter,Off,On;",
`endif
	"O1,Pause,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O8,Diagonal joystick,Off,On;",
	"O5,Blend,Off,On;",
	"O6,Flip,Off,On;",
	"O7,Service,Off,On;",
	`SEP
	"DIP;",
	`SEP
	"T0,Reset;",
	"V,v2.0.",`BUILD_DATE
};

wire           pause = status[1];
wire          rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire           blend = status[5];
wire           flip  = status[6];
wire        service  = status[7];
wire       diagonal  = status[8];
wire [1:0] rotate_screen = status[9:8];
wire       rotate_filter = status[10];

wire [7:0]       sw1 = status[23:16];
wire [7:0]       sw2 = status[31:24];


assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_sd;
assign SDRAM_CKE = 1;

wire clk_sys, clk_sd;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.c0(clk_sd),//48
	.c1(clk_sys),//24
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

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        key_pressed;
wire        key_strobe;
wire  [7:0] key_code;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
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
	.scandoubler_disable (scandoublerD	  ),
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
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         ),
	.core_mod       (core_mod       )
	);

wire [14:0] rom_addr;
wire [15:0] rom_do;
wire [12:0] bg_addr;
wire [31:0] bg_do;
wire [13:0] sp_addr;
wire [31:0] sp_do;
wire [19:0] wave_addr;
wire [15:0] wave_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

// ROM structure
// 00000-06FFF CPU ROM   28k  u27-u28-u29-(u29-u29)
// 07000-0EFFF Tiledata  32k  u91-u90-u93-u92
// 0F000-0F7FF char1      2k  u68
// 0F800-0FFFF char2      2k  u69
// 10000-17FFF bg        32k  u113-u112-u111-(u111)
// 18000-27FFF spr       64k  u77-u78-u79-(u79)
// 28000-280FF          256b  u76
// 28100-281FF          256b  u72

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

wire [24:0] gfx_ioctl_addr = ioctl_addr - 17'hE000;

reg port1_req, port2_req;
sdram #(48) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_sd       ),

	// port1 used for main CPU
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 19'h7ffff : {5'd0, rom_addr[14:1]}),
	.cpu1_q        ( rom_do ),
	.cpu2_addr     ( wave_addr[19:1] + 17'h13100 ),
	.cpu2_q        ( wave_do ),

	// port2 for gfx
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( gfx_ioctl_addr[23:1] ),
	.port2_ds      ( {gfx_ioctl_addr[0], ~gfx_ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.bg_addr       ( bg_addr ),
	.bg_q          ( bg_do ),
	.sp_addr       ( sp_addr + 16'h2000),
	.sp_q          ( sp_do )
);

always @(posedge clk_sys) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
			port2_req <= ~port2_req;
		end
	end
end

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clk_sd) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire dl_wr = ioctl_wr && ioctl_index == 0;

wire m_north, m_south, m_east, m_west;

always @(*) begin
	if (~diagonal) begin
		m_north <= m_up;
		m_south <= m_down;
		m_east  <= m_right;
		m_west  <= m_left;
	end
	else begin
		m_north <= m_up    & m_right;
		m_south <= m_down  & m_left;
		m_east  <= m_right & m_down;
		m_west  <= m_left  & m_up;
	end 
end

wire [15:0] audio_l;
wire [15:0] audio_r;
wire        hs, vs, cs, hb, vb;
wire  [2:0] g, r;
wire  [1:0] b;

congo_bongo congo_bongo
(
	.clock_24(clk_sys),
	.reset(reset),
	.pause(pause),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_vblank(vb),
	.video_hblank(hb),
	.video_hs(hs),
	.video_vs(vs),

	.audio_out_l(audio_l),
	.audio_out_r(audio_r),

	.cpu_rom_addr ( rom_addr  ),
	.cpu_rom_do   ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.bg_graphics_addr( bg_addr ),
	.bg_graphics_do  ( bg_do   ),
	.sp_graphics_addr( sp_addr ),
	.sp_graphics_do  ( sp_do   ),

	.dl_addr(ioctl_addr[17:0]),
	.dl_wr(dl_wr),
	.dl_data(ioctl_dout),

	.coin1(m_coin1),
	.coin2(m_coin2),
	.start1(m_one_player),
	.start2(m_two_players),

	.right(m_east),
	.left(m_west),
	.up(m_north),
	.down(m_south),
	.fire(m_fireA),
 
	.right_c(m_east),
	.left_c(m_west),
	.up_c(m_north),
	.down_c(m_south),
	.fire_c(m_fireA),

	.sw1_input(sw1), // cocktail(1) / sound(1) / ships(2) / N.U.(2) /  extra ship (2)	
	.sw2_input(8'h33), // coin b(4) / coin a(4)  -- "3" => 1c_1c

	.service(service),
	.flip_screen(flip)
	
//Dar	.wave_data(wave_data),
//Dar	.wave_addr(wave_addr),
//Dar	.wave_rd(wave_rd),
	
//Dar	.hs_address(hs_address),
//Dar	.hs_data_out(hs_data_out),
//Dar	.hs_data_in(hs_data_in),
//Dar	.hs_write(hs_write_enable)
);


mist_dual_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(VGA_BITS), .USE_BLANKS(1'b1), .BIG_OSD(BIG_OSD)) mist_video(
	.clk_sys        ( clk_sd           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( {b,b[1]}         ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.HBlank         ( hb               ),
	.VBlank         ( vb               ),
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
	.clk_sdram      ( clk_sd           ),
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
	.ce_divider     ( 4'd7             ),
	.blend          ( blend            ),
	.rotate         ( {flip, rotate}   ),
	.rotate_screen  ( rotate_screen    ),
	.rotate_hfilter ( rotate_filter    ),
	.rotate_vfilter ( rotate_filter    ),
	.scandoubler_disable(scandoublerD  ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

`ifdef USE_HDMI

i2c_master #(24_000_000) i2c_master (
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

dac #(
	.C_bits(16))
dacl(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_l),
	.dac_o(AUDIO_L)
	);

dac #(
	.C_bits(16))
dacr(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_r),
	.dac_o(AUDIO_R)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_sd),
	.clk_rate(32'd48_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan({2'b00, audio_l[15:2]}),
	.right_chan({2'b00, audio_r[15:2]})
);
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clk_sd),
	.clk_rate_i(32'd48_000_000),
	.spdif_o(SPDIF),
	.sample_i({2'b00, audio_r[15:2], 2'b00, audio_l[15:2]})
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clk_sd) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
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
	.orientation ( {flip, ~|rotate_screen} ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b1        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule 
