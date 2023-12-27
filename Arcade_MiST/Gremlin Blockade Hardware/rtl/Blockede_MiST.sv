module Blockede_MiST(
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
	"BLOCKADE;;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O7,Pause,Off,On;",
	"OGJ,Analog Video H-Pos,0,-1,-2,-3,-4,-5,-6,-7,8,7,6,5,4,3,2,1;",
	"OKN,Analog Video V-Pos,0,-1,-2,-3,-4,-5,-6,-7,8,7,6,5,4,3,2,1;",
	"DIP;",
	"T0,Reset;",
	"V,v1.50.",`BUILD_DATE
};

wire [1:0] scanlines 			= status[4:3];
wire       blend     			= status[5];
wire       btn_pause   			= status[7];
assign LED = ~(ioctl_downl);
assign AUDIO_R = AUDIO_L;

wire clk_sys;
wire pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys)
	);

wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
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

wire   		vid;wire  [2:0] video_rgb = {3{vid}} & overlay_mask;
wire  [5:0] rgb_out;
wire        scandoublerD;
wire        hs, vs, vb, hb;
wire        blankn = ~(hb | vb);
wire        ypbpr;
wire        no_csync;

wire [15:0] audio;

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

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
	.ioctl_dout    ( ioctl_dout   ),
	.ioctl_din     ( ioctl_din    )
);

mist_video #(.COLOR_DEPTH(2), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(VGA_BITS), .USE_BLANKS(1'b1), .BIG_OSD(BIG_OSD)) mist_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( rgb_out[5:4]     ),
	.G              ( rgb_out[3:2]     ),
	.B              ( rgb_out[1:0]     ),
	.HBlank         ( hb               ),
	.VBlank         ( vb               ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scanlines      ( scanlines        ),
	.ce_divider     ( 1'b0             ),
	.scandoubler_disable(scandoublerD  ),
	.no_csync       ( no_csync         ),
	.ypbpr          ( ypbpr            )
	);
	
// H/V offset
wire [3:0]  voffset = status[23:20];
wire [3:0]  hoffset = status[19:16];
wire hs_original, vs_original;
wire ce_pix;
jtframe_resync jtframe_resync
(
	.clk(clk_sys),
	.pxl_cen(ce_pix),
	.hs_in(hs_original),
	.vs_in(vs_original),
	.LVBL(~vb),
	.LHBL(~hb),
	.hoffset(hoffset),
	.voffset(voffset),
	.hs_out(hs),
	.vs_out(vs)
);

`ifdef USE_HDMI

i2c_master #(21_000_000) i2c_master (
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

mist_video #(.COLOR_DEPTH(2), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(8), .USE_BLANKS(1'b1), .BIG_OSD(BIG_OSD)) hdmi_video(
	.clk_sys        ( clk_sys          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( rgb_out[5:4]     ),
	.G              ( rgb_out[3:2]     ),
	.B              ( rgb_out[1:0]     ),
	.HBlank         ( hb               ),
	.VBlank         ( vb               ),
	.HSync          ( hs_original      ),
	.VSync          ( vs_original      ),
	.VGA_R          ( HDMI_R           ),
	.VGA_G          ( HDMI_G           ),
	.VGA_B          ( HDMI_B           ),
	.VGA_VS         ( HDMI_VS          ),
	.VGA_HS         ( HDMI_HS          ),
	.VGA_DE         ( HDMI_DE          ),
	.scanlines      ( scanlines        ),
	.ce_divider     ( 1'b0             ),
	.scandoubler_disable(1'b0          ),
	.no_csync       ( 1'b1             ),
	.ypbpr          ( 1'b0             )
	);
	
assign HDMI_PCLK = clk_sys;
`endif

dac #(
	.C_bits(16))
dac (
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i({~audio[15],audio[14:0]}),
	.dac_o(AUDIO_L)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_sys),
	.clk_rate(32'd20_769_230),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan(audio),
	.right_chan(audio)
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
	.clk_rate_i(32'd20_769_230),
	.spdif_o(SPDIF),
	.sample_i({audio, audio})
);
`endif

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_up3, m_down3, m_left3, m_right3, m_fire3A, m_fire3B, m_fire3C, m_fire3D, m_fire3E, m_fire3F;
wire m_up4, m_down4, m_left4, m_right4, m_fire4A, m_fire4B, m_fire4C, m_fire4D, m_fire4E, m_fire4F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_fire3F, m_fire3E, m_fire3D, m_fire3C, m_fire3B, m_fire3A, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_fire4F, m_fire4E, m_fire4D, m_fire4C, m_fire4B, m_fire4A, m_up4, m_down4, m_left4, m_right4} )
);

///////////////////   DIPS   ////////////////////

reg [2:0] dip_blockade_lives;
reg dip_comotion_lives;
reg [1:0] dip_hustle_coin;
reg [7:0] dip_hustle_freegame;
reg dip_hustle_time;
reg [1:0] dip_blasto_coin;
reg dip_blasto_demosounds;
reg dip_blasto_time;
reg dip_boom;
reg [2:0] dip_minesweeper_lives;
reg dip_minesweeper_cabinet;
reg [1:0] dip_overlay_type;
reg [2:0] overlay_mask;
wire [7:0] sw = status[15:8];
reg [7:0] IN_1;
reg [7:0] IN_2;
reg [7:0] IN_4;
always @(posedge clk_sys)
begin
 	case(core_mod)
	7'h0: // GAME_BLOCKADE
	begin
		// The lives DIP behaves strangely in Blockade, so it is remapped here
		case(sw[1:0])
		2'd0: dip_blockade_lives <= 3'b011; // 3 lives
		2'd1: dip_blockade_lives <= 3'b110; // 4 lives
		2'd2: dip_blockade_lives <= 3'b100; // 5 lives
		2'd3: dip_blockade_lives <= 3'b000; // 6 lives		
		endcase
		dip_boom <= sw[4];
		dip_overlay_type <= sw[3:2];
		IN_1 <= ~{m_coin1, dip_blockade_lives, 1'b0, dip_boom, 2'b00};
		IN_2 <= ~{m_left, m_down, m_right, m_up, m_left2, m_down2, m_right2, m_up2};
		IN_4 <= ~{8'b00000000}; // Unused		
	end
	7'h1: // GAME_COMOTION
	begin
		dip_comotion_lives <= sw[0];
		dip_overlay_type <= sw[2:1];
		dip_boom <= sw[3];		
		IN_1 <= ~{m_coin1, 2'b0, m_one_player, dip_comotion_lives, dip_boom, 2'b00}; 
		IN_2 <= ~{m_left3, m_down3, m_right3, m_up3, m_left, m_down, m_right, m_up};
		IN_4 <= ~{m_left4, m_down4, m_right4, m_up4, m_left4, m_down4, m_right4, m_up4};
	end
	7'h2: // GAME_HUSTLE
	begin
		dip_hustle_coin <= sw[1:0];
		case(sw[3:2])
		2'd0: dip_hustle_freegame <= 8'b11100001;
		2'd1: dip_hustle_freegame <= 8'b11010001;
		2'd2: dip_hustle_freegame <= 8'b10110001;
		2'd3: dip_hustle_freegame <= 8'b01110001;		
		endcase
		dip_hustle_time <= sw[4];
		dip_overlay_type <= sw[6:5];
		IN_1 <= ~{m_coin1, 2'b0, m_two_players, m_one_player, dip_hustle_time, dip_hustle_coin};
		IN_2 <= ~{m_left, m_down, m_right, m_up, m_left2, m_down2, m_right2, m_up2};
		IN_4 <= dip_hustle_freegame; // Extra DIPS
	end
	7'h3: // GAME_BLASTO
	begin
		dip_blasto_coin <= sw[1:0];
		dip_blasto_demosounds <= sw[2];
		dip_blasto_time = sw[3];		
		dip_overlay_type <= sw[5:4];
		IN_1 <= ~{m_coin1, 3'b0, dip_blasto_time, dip_blasto_demosounds, dip_blasto_coin};
		IN_2 <= ~{m_fireA, m_two_players, m_one_player, 4'b0000, m_fire2A}; 
		IN_4 <= ~{m_up, m_left, m_down, m_right, m_up2, m_left2, m_down2, m_right2};		
	end
	7'h4: // GAME_Minesweeper
	begin
		dip_minesweeper_cabinet <= sw[0];
		dip_boom <= sw[1];
		dip_minesweeper_lives <= sw[3:2];
		dip_overlay_type <= sw[5:4];
		IN_1 <= ~{m_coin1, dip_minesweeper_lives, 1'b0, dip_boom, 1'b0/*dip_minesweeper_cabinet*/, 1'b0};
		IN_2 <= ~{m_left2, m_down2, m_right2, m_up2, m_left, m_down, m_right, m_up}; 
		IN_4 <= ~{8'b00000000};		
	end
	7'h5: // GAME_Minesweeper (4-Player)
	begin
		dip_minesweeper_cabinet <= sw[0];
		dip_boom <= sw[1];
		dip_minesweeper_lives <= sw[3:2];
		dip_overlay_type <= sw[5:4];
		IN_1 <= ~{m_coin1, dip_minesweeper_lives, 1'b0, dip_boom, 1'b0/*dip_minesweeper_cabinet*/, 1'b0};
		IN_2 <= ~{m_left2, m_down2, m_right2, m_up2, m_left, m_down, m_right, m_up}; 
		IN_4 <= ~{m_left4, m_down4, m_right4, m_up4, m_left3, m_down3, m_right3, m_up3}; 	
	end
	endcase
		// Generate overlay colour mask
	case(dip_overlay_type)
	2'd0: overlay_mask <= 3'b010; // Green
	2'd1: overlay_mask <= 3'b111; // White
	2'd2: overlay_mask <= 3'b011; // Yellow
	2'd3: overlay_mask <= 3'b001; // Red
	endcase

end

wire		pause_cpu;
pause #(2,2,2,24) pause (
	.rgb_out(rgb_out),
	.r({2{video_rgb[0]}}),
	.g({2{video_rgb[1]}}),
	.b({2{video_rgb[2]}}),
	.user_button(btn_pause),
	.pause_request(),
	.options(~status[26:25])
);


///////////////////   GAME   ////////////////////
reg rom_downloaded = 1'b0;
wire rom_download = ioctl_downl && ioctl_index == 8'b0;
wire reset = (status[0] | buttons[1] | rom_download | ~rom_downloaded);
// Latch release reset if ROM data is received (stops sound circuit from going off if ROMs are not found)
always @(posedge clk_sys) 
	if(rom_download && ioctl_dout > 8'b0) rom_downloaded <= 1'b1; 

blockade blockade(
	.clk				(clk_sys),
	.reset			(reset),
	.pause			(btn_pause),
	.game_mode		(core_mod),
	.ce_pix			(ce_pix),
	.video			(vid),
	.vsync			(vs_original),
	.hsync			(hs_original),
	.vblank			(vb),
	.hblank			(hb),

	.audio_l			(audio),

	.in_1				(IN_1),
	.in_2				(IN_2),
	.in_4				(IN_4),
	.coin				(m_coin1),

	.dn_addr			(ioctl_addr[13:0]),
	.dn_wr			(ioctl_wr & rom_download),
	.dn_data			(ioctl_dout)
);

endmodule
