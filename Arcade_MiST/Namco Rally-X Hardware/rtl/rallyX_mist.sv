module rallyX_mist (
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

localparam CONF_STR = {
	"RALLYX;;",
	"O2,Rotate Controls,Off,On;",
	"OWX,Orientation,Vertical,Clockwise,Anticlockwise;",
	"OY,Rotation filter,Off,On;",
	"O34,Scanlines,None,CRT 25%,CRT 50%,CRT 75%;",
	"O5,Blend,Off,On;",
	`SEP
	"DIP;",
	`SEP
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire       rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend = status[5];
wire [1:0] orientation = {core_mod[2], core_mod[0]};
wire [1:0] rotate_screen = status[33:32];
wire       rotate_filter = status[34];

assign    LED = ~ioctl_downl;
assign    AUDIO_R = AUDIO_L;
assign    SDRAM_CLK = clock_96;
assign    SDRAM_CKE = 1;

wire pll_locked, clock_24, clock_96;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_96),
	.c1(clock_24), //24.576MHz
	.locked(pll_locked)
	);

// for Time Pilot sound board
wire clock_14, clock_56;
pll_snd pll_snd(
	.inclk0(CLOCK_27),
	.c0(clock_14),
	.c1(clock_56)
);

wire  [6:0] core_mod;
wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [31:0] joystick_0;
wire  [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
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
	.clk_sys        (clock_24       ),
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

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
reg         port1_req;
wire [15:0] rom_dout;
wire [14:0] rom_addr;
wire        rom_oe;

data_io data_io(
	.clk_sys       ( clock_24     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire  [7:0] audio;
wire        hs, vs;
wire        hb, vb;
wire  [2:0] r, g;
wire  [1:0] b;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

reg   [7:0] iDSW1, iDSW2, iCTR1, iCTR2;

always @(*) begin
	iDSW1 = ~status[15:8];
	iDSW2 = ~status[23:16];
	iCTR1 = ~{ m_coin1, m_one_player,  m_up,  m_down,  m_right,  m_left,  m_fireA,  1'b0 };
	iCTR2 = ~{ m_coin2, m_two_players, m_up2, m_down2, m_right2, m_left2, m_fire2A, 1'b0 };

	if (core_mod[0]) begin
		//Jungler, Loco-Motion, Tactician
		iCTR1 = ~{ m_coin1, m_coin2,  m_right, m_left, m_fireA, 1'b0, m_fireB, m_up2 };
		iCTR2 = ~{ m_one_player, m_two_players, m_left2, m_right2, m_fire2A, m_fire2B, m_down2, m_up };
		iDSW1[7] = ~m_down;
	end
	if (core_mod[3]) begin
		//Commando
		iCTR1 = ~{ m_coin1, m_coin2,  m_right, m_left, m_fireB, 2'b00, m_up };
		iCTR2 = ~{ m_one_player, m_two_players, m_left2, m_right2, m_fire2B, m_fire2A, m_down2, m_up };
		iDSW1[7] = ~m_down;
		iDSW1[6] = ~m_fireA;
	end
end
/*
sdram #(.MHZ(24)) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clock_24     ),
        
	// ROM upload
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[22:1] ),
	.port1_ds      ( { ioctl_addr[0], ~ioctl_addr[0] } ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
      
	// CPU
	.cpu1_addr     ( ioctl_downl ? 17'h1ffff : {3'b000, rom_addr[14:1] } ),
	.cpu1_q        ( rom_dout  )
);
*/
always @(posedge clock_24) begin
	reg        ioctl_wr_last = 0;
 
	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
		end
	end
end

fpga_nrx fpga_nrx(
	.RESET(status[0] | buttons[1]),
	.CLK24M(clock_24),
	.CLK14M(clock_14),
	.mod_jungler(core_mod[0]),
	.mod_loco(core_mod[1]),
	.mod_tact(core_mod[2]),
	.mod_comm(core_mod[3]),
	.hsync(hs),
	.vsync(vs),
	.hblank(hb),
	.vblank(vb),
	.r(r),
	.g(g),
	.b(b),
	.cpu_rom_addr(rom_addr),
	.cpu_rom_data(rom_addr[0] ? rom_dout[15:8] : rom_dout[7:0]),
	.cpu_rom_oe(rom_oe),
	.SND(audio),
	.DSW1(iDSW1),
	.DSW2(iDSW2),
	.CTR1(iCTR1),
	.CTR2(iCTR2),
	.LAMP(),
	// ROM download
	.ROMCL(clock_24),
	.ROMAD(ioctl_addr[15:0]),
	.ROMDT(ioctl_dout),
	.ROMEN(ioctl_wr)
	);

mist_dual_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(11), .OUT_COLOR_DEPTH(VGA_BITS), .BIG_OSD(BIG_OSD), .USE_BLANKS(1'b1)) mist_video(
	.clk_sys        ( clock_96         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( {b,1'b0}         ),
	.HBlank         ( hb               ),
	.VBlank         ( vb               ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 4'd15            ),
`ifdef USE_HDMI
	.HDMI_R         ( HDMI_R           ),
	.HDMI_G         ( HDMI_G           ),
	.HDMI_B         ( HDMI_B           ),
	.HDMI_VS        ( HDMI_VS          ),
	.HDMI_HS        ( HDMI_HS          ),
	.HDMI_DE        ( HDMI_DE          ),
`endif
	.clk_sdram      ( clock_96         ),
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

	.ram_din       ( {ioctl_dout, ioctl_dout} ),
	.ram_dout      ( ),
	.ram_addr      ( ioctl_addr[22:1] ),
	.ram_ds        ( { ioctl_addr[0], ~ioctl_addr[0] } ),
	.ram_req       ( port1_req ),
	.ram_we        ( ioctl_downl ),
	.ram_ack       ( ),
	.rom_oe        ( rom_oe ),
	.rom_addr      ( rom_addr[14:1] ),
	.rom_dout      ( rom_dout ),

	.blend          ( blend            ),
	.rotate         ( {orientation[1], rotate} ),
	.rotate_screen  ( rotate_screen    ),
	.rotate_hfilter ( rotate_filter    ),
	.rotate_vfilter ( rotate_filter    ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

`ifdef USE_HDMI

i2c_master #(24_000_000) i2c_master (
	.CLK         (clock_24),

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

assign HDMI_PCLK = clock_24;
`endif

dac #(.C_bits(16))dac(
	.clk_i(core_mod[0] ? clock_56 : clock_96),
	.res_n_i(1),
	.dac_i({audio,audio}),
	.dac_o(AUDIO_L)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(core_mod[0] ? clock_56 : clock_96),
	.clk_rate(core_mod[0] ? 32'd56_000_000 : 32'd98_304_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan({1'b0, audio, audio[7:1]}),
	.right_chan({1'b0, audio, audio[7:1]})
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(core_mod[0] ? clock_56 : clock_96) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(core_mod[0] ? clock_56 : clock_96),
	.clk_rate_i(core_mod[0] ? 32'd56_000_000 : 32'd98_304_000),
	.spdif_o(SPDIF),
	.sample_i({2{1'b0, audio, audio[7:1]}})
);
`endif

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs #(.START1(10), .START2(12), .COIN1(11)) inputs (
	.clk         ( clock_24    ),
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
