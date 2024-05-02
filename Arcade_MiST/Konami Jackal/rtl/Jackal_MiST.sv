module Jackal_MiST (
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
	"JACKAL;;",
	"O2,Rotate Controls,Off,On;",
`ifdef DUAL_SDRAM
	"OWX,Orientation,Vertical,Clockwise,Anticlockwise;",
	"OY,Rotation filter,Off,On;",
`endif
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"O7,Service,Off,On;",
	"O1,Rotary speed,Normal,Fast;",
	`SEP
	"DIP;",
	`SEP
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire        rotate = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];
wire        joyswap = status[6];
wire        service = status[7];
wire        rotary_speed = status[1];
wire  [1:0] rotate_screen = status[33:32];
wire        rotate_filter = status[34];

wire  [1:0] orientation = 2'b11;
wire [23:0] dip_sw = ~status[31:8];

wire  [1:0] is_bootleg = core_mod[1:0];

assign 		LED = ~ioctl_downl;
assign 		SDRAM_CLK = clock_98;
assign 		SDRAM_CKE = 1;

wire clock_98, clock_49, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_98),
	.c1(clock_49),//49.152MHz
	.locked(pll_locked)
	);

`ifdef DUAL_SDRAM
wire pll2_locked;
pll pll2(
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
	.clk_sys        (clock_49       ),
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

wire [15:0] audio_l, audio_r;
wire        hs, vs, cs;
wire        hb, vb;
wire        blankn = ~(hb | vb);
wire  [4:0] r, g, b;
wire        key_strobe;
wire        key_pressed;
wire  [7:0] key_code;

wire [16:0] main_rom_addr;
wire [15:0] main_rom_do;
wire [14:0] sub_rom_addr;
wire [15:0] sub_rom_do;
wire [15:0] ch1_addr;
wire [15:0] ch1_do;
wire [15:0] ch2_addr;
wire [15:0] ch2_do;
wire        sp1_req, sp1_ack;
wire [15:0] sp1_addr;
wire [15:0] sp1_do;
wire        sp2_req, sp2_ack;
wire [15:0] sp2_addr;
wire [15:0] sp2_do;

wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

data_io data_io(
	.clk_sys       ( clock_98     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);
wire [24:0] bg_ioctl_addr = ioctl_addr - 18'h20000;

reg port1_req, port2_req;
sdram #(98) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clock_98     ),

	// port1 for CPUs
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( ioctl_downl ? 16'h0000 : main_rom_addr[16:1] ),
	.cpu1_q        ( main_rom_do ),
	.cpu2_addr     ( ioctl_downl ? 16'h0000 : sub_rom_addr[14:1] + 16'hc000 ),
	.cpu2_q        ( sub_rom_do ),

	// port2 for graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( {bg_ioctl_addr[23:18], bg_ioctl_addr[16:0]} ), // merge gfx roms to 16-bit wide words
	.port2_ds      ( {~bg_ioctl_addr[17], bg_ioctl_addr[17]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.ch1_addr      ( ioctl_downl ? 16'hffff : ch1_addr ),
	.ch1_q         ( ch1_do ),
	.ch2_addr      ( ioctl_downl ? 16'hffff : ch2_addr ),
	.ch2_q         ( ch2_do ),
	.sp1_req       ( sp1_req ),
	.sp1_ack       ( sp1_ack ),
	.sp1_addr      ( ioctl_downl ? 16'hffff : sp1_addr ),
	.sp1_q         ( sp1_do ),
	.sp2_req       ( sp2_req ),
	.sp2_ack       ( sp2_ack ),
	.sp2_addr      ( ioctl_downl ? 16'hffff : sp2_addr ),
	.sp2_q         ( sp2_do )
);

// ROM download controller
always @(posedge clock_98) begin
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
always @(posedge clock_49) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;

	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

Jackal Jackal(
	.reset(~reset),
	.clk_49m(clock_49), 
	.coins({~m_coin2,~m_coin1}),
	.btn_start({~m_two_players,~m_one_player}),
	.p1_joystick({~m_down1, ~m_up1, ~m_right1, ~m_left1}),
	.p2_joystick({~m_down2, ~m_up2, ~m_right2, ~m_left2}),
	.p1_rotary(~p1_rotary),
	.p2_rotary(~p2_rotary),
	.p1_buttons({~m_fire1[1], ~m_fire1[0]}),
	.p2_buttons({~m_fire2[1], ~m_fire2[0]}),
	.btn_service(~service),
	.dipsw(dip_sw),
	.is_bootleg(is_bootleg),
	.video_hsync(hs), 
	.video_vsync(vs), 
	.video_csync(cs),
	.video_hblank(hb), 
	.video_vblank(vb),
	.video_r(r), 
	.video_g(g), 
	.video_b(b),
	.sound_l(audio_l),
	.sound_r(audio_r),
	.pause(1'b1),
	.ioctl_clk(clock_98),
	.ioctl_addr(ioctl_addr),
	.ioctl_data(ioctl_dout),
	.ioctl_wr(ioctl_wr),

	.main_cpu_rom_addr(main_rom_addr),
	.main_cpu_rom_do(main_rom_addr[0] ? main_rom_do[15:8] : main_rom_do[7:0]),
	.sub_cpu_rom_addr(sub_rom_addr),
	.sub_cpu_rom_do(sub_rom_addr[0] ? sub_rom_do[15:8] : sub_rom_do[7:0]),
	.char1_rom_addr(ch1_addr),
	.char1_rom_do(ch1_do),
	.char2_rom_addr(ch2_addr),
	.char2_rom_do(ch2_do),
	.sp1_req(sp1_req),
	.sp1_ack(sp1_ack),
	.sp1_rom_addr(sp1_addr),
	.sp1_rom_do(sp1_do),
	.sp2_req(sp2_req),
	.sp2_ack(sp2_ack),
	.sp2_rom_addr(sp2_addr),
	.sp2_rom_do(sp2_do)
);

mist_dual_video #(.COLOR_DEPTH(5), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(VGA_BITS), .USE_BLANKS(1'b1), .BIG_OSD(BIG_OSD)) mist_video(
	.clk_sys        ( clock_98         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( b                ),
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
	.clk_sdram      ( clock_98         ),
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

i2c_master #(49_000_000) i2c_master (
	.CLK         (clock_49),

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

assign HDMI_PCLK = clock_49;

`endif

dac #(.C_bits(16))dac_l(
	.clk_i(clock_49),
	.res_n_i(1'b1),
	.dac_i({~audio_l[15], audio_l[14:0]}),
	.dac_o(AUDIO_L)
	);

dac #(.C_bits(16))dac_r(
	.clk_i(clock_49),
	.res_n_i(1'b1),
	.dac_i({~audio_r[15], audio_r[14:0]}),
	.dac_o(AUDIO_R)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clock_49),
	.clk_rate(32'd49_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan(audio_l),
	.right_chan(audio_r)
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clock_49) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clock_49),
	.clk_rate_i(32'd49_000_000),
	.spdif_o(SPDIF),
	.sample_i({audio_r, audio_l})
);
`endif

//Rotary controls (disable for bootleg ROM sets as although these support rotary controls, bootleg PCBs
//have no means of supporting rotary controls as there are no footprints for the required hardware)
//TODO: Map the inputs to absolute inputs using an analog stick (Jackal ignores out-of-order inputs)
reg [22:0] rotary_div = 23'd0;
reg [7:0] rotary1 = 8'h01;
reg [7:0] rotary2 = 8'h01;
wire m_rotary1_l = m_fire1[2] | m_left1B | m_down1B;
wire m_rotary1_r = m_fire1[3] | m_right1B | m_up1B;
wire m_rotary2_l = m_fire2[2] | m_left2B | m_down2B;
wire m_rotary2_r = m_fire2[3] | m_right2B | m_up2B;

wire rotary_en = rotary_speed ? !rotary_div[21:0] : !rotary_div;
always_ff @(posedge clock_49) begin
	rotary_div <= rotary_div + 23'd1;
	if(rotary_en) begin
		if(m_rotary1_l) begin
			if(rotary1 != 8'h80)
				rotary1 <= rotary1 << 1;
			else
				rotary1 <= 8'h01;
		end
		else if(m_rotary1_r) begin
			if(rotary1 != 8'h01)
				rotary1 <= rotary1 >> 1;
			else
				rotary1 <= 8'h80;
		end

		if(m_rotary2_l) begin
			if(rotary2 != 8'h80)
				rotary2 <= rotary2 << 1;
			else
				rotary2 <= 8'h01;
		end
		else if(m_rotary2_r) begin
			if(rotary2 != 8'h01)
				rotary2 <= rotary2 >> 1;
			else
				rotary2 <= 8'h80;
		end
	end
end
wire [7:0] p1_rotary = (is_bootleg == 2'b01) ? 8'hFF : rotary1;
wire [7:0] p2_rotary = (is_bootleg == 2'b01) ? 8'hFF : rotary2;

wire m_up1, m_down1, m_left1, m_right1, m_up1B, m_down1B, m_left1B, m_right1B;
wire m_up2, m_down2, m_left2, m_right2, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;
wire [11:0] m_fire1, m_fire2;

arcade_inputs inputs (
	.clk         ( clock_49    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( orientation ^ {1'b0, |rotate_screen} ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0   		),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_up1B, m_down1B, m_left1B, m_right1B, m_fire1, m_up1, m_down1, m_left1, m_right1} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, m_fire2, m_up2, m_down2, m_left2, m_right2} )
);

endmodule
