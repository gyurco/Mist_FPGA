//============================================================================
//  Arcade: Williams rev.2
//

module Williams2_MiST(
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

`define CORE_NAME "TSHOOT"
//`define CORE_NAME "JOUST2"
//`define CORE_NAME "INFERNO"
//`define CORE_NAME "MYSTICM"

localparam CONF_STR = {
	`CORE_NAME,";;",
	"O2,Rotate Controls,Off,On;",
`ifdef DUAL_SDRAM
	"OGH,Orientation,Vertical,Clockwise,Anticlockwise;",
	"OI,Rotation filter,Off,On;",
`endif
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	"O7,Auto up,Off,On;",
	"T8,Advance;",
	"T9,HS Reset;",
	"R1024,Save NVRAM;",
	"T0,Reset;",
	"V,v1.2.",`BUILD_DATE
};

wire        rotate    = status[2];
wire  [1:0] scanlines = status[4:3];
wire        blend     = status[5];
wire        joyswap   = status[6];
wire        autoup    = status[7];
wire        adv       = status[8];
wire        hsr       = status[9];
wire  [1:0] rotate_screen = status[17:16];
wire        rotate_filter = status[18];

wire advance, hsreset;
trigger adv_button(clk_sys, adv, advance);
trigger hsr_button(clk_sys, hsr, hsreset);

wire [6:0] core_mod;
reg  [7:0] input1;
reg  [7:0] input2;
wire       input_sel;
reg  [1:0] orientation; // [left/right, landscape/portrait]
wire [5:0] gun_gray_code;
reg        oneplayer;   // only one joystick

always @(*) begin
	input1 = 0;
	input2 = 0;
	orientation = 2'b10;
	oneplayer = 1;

	case (core_mod)
	7'h0: // Turkey Shoot
	begin
		input1 = {~(m_fireA | m_fire2A | mouse_flags[0]), 1'b0, gun_gray_code};
		input2 = { m_two_players, m_one_player, 4'd0, m_fireC | m_fire2C | mouse_flags[2], m_fireB | m_fire2B | mouse_flags[1] };
	end
	7'h1: // Joust 2
	begin
		oneplayer = 0;
		orientation = 2'b01;
		input1[7:4] = { 2'b11, ~m_fireB, ~m_fire2B };
		input1[3:0] = input_sel ? ~{1'b0, m_fire2A, m_right2, m_left2} : ~{1'b0, m_fireA, m_right, m_left};
	end
	7'h2: // Inferno
	begin
		oneplayer = 0;
		input1 = input_sel ? ~{m_down2B | m_fire2E, m_right2B | m_fire2D, m_left2B | m_fire2C, m_up2B | m_fire2B, m_down2, m_right2, m_left2, m_up2} :
		                     ~{m_downB | m_fireE, m_rightB | m_fireD, m_leftB | m_fireC, m_upB | m_fireB, m_down, m_right, m_left, m_up};
		input2 = { m_two_players, m_one_player, 4'd0, m_fire2A, m_fireA };
	end
	7'h3: // Mystic Marathon
	begin
		input1 = { m_fireA, 1'b0, m_two_players, m_one_player, m_left, m_down, m_right, m_up };
	end
	default: ;
	endcase

end

assign LED = ~ioctl_downl;
assign SDRAM_CLK = clk_mem;
assign SDRAM_CKE = 1;

wire clk_sys, clk_vid, clk_mem;
wire pll_locked;
pll_mist pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_mem),//96
	.c1(clk_vid),//48
	.c2(clk_sys),//12
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
wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire        mouse_strobe;
wire signed [8:0] mouse_x;
wire signed [8:0] mouse_y;
wire  [7:0] mouse_flags;

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
	.core_mod       (core_mod       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.mouse_strobe   (mouse_strobe   ),
	.mouse_flags    (mouse_flags    ),
	.mouse_x        (mouse_x        ),
	.mouse_y        (mouse_y        ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;
wire        rom_downl = ioctl_downl & ioctl_index == 0;

data_io data_io (
	.clk_sys       ( clk_mem      ),
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

reg         port1_req, port2_req;
wire [17:0] rom_addr;
reg  [17:0] rom_addr_r;
wire [15:0] rom_do;
wire [13:0] gfx_addr;
wire [31:0] gfx_do;
wire [12:0] snd_addr;
reg  [19:0] snd_addr_r;
wire [15:0] snd_do;
wire [16:0] snd2_addr;
reg  [19:0] snd2_addr_r;
wire [15:0] snd2_do;

wire [24:0] gfx_ioctl_addr = ioctl_addr - 20'h25000;

always @(posedge clk_mem) begin
	rom_addr_r <= rom_downl ? 18'd0 : rom_addr;
	snd_addr_r <= rom_downl ? 20'd0 : snd_addr + 20'h23000;
	snd2_addr_r <= rom_downl ? 20'd0 : snd2_addr + 20'h35000;
end

sdram #(.MHZ(96)) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clk_mem      ),

	// port1 used for main and sound CPUs
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),

	.cpu1_addr     ( rom_addr_r[17:1] ),
	.cpu1_q        ( rom_do ),
	.cpu2_addr     ( snd_addr_r[19:1] ),
	.cpu2_q        ( snd_do ),
	.cpu3_addr     ( snd2_addr_r[19:1] ),
	.cpu3_q        ( snd2_do ),

	// port2 for background graphics
	.port2_req     ( port2_req ),
	.port2_ack     ( ),
	.port2_a       ( gfx_ioctl_addr[23:1] ),
	.port2_ds      ( {gfx_ioctl_addr[0], ~gfx_ioctl_addr[0]} ),
	.port2_we      ( ioctl_downl ),
	.port2_d       ( {ioctl_dout, ioctl_dout} ),
	.port2_q       ( ),

	.sp_addr       ( gfx_addr ),
	.sp_q          ( gfx_do )
);

always @(posedge clk_mem) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (rom_downl) begin
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
	reset <= status[0] | buttons[1] | ioctl_downl | ~rom_loaded;
end

wire [16:0] audio_left;
wire [16:0] audio_right;
wire        hs, vs;
wire        blankn;
wire  [3:0] r,g,b,i;

williams2 williams2 (
	.clock_12         ( clk_sys         ),
	.reset            ( reset           ),
	.hwsel            ( core_mod[1:0]   ),

	.rom_addr         ( rom_addr        ),
	.rom_do           ( rom_addr[0] ? rom_do[15:8] : rom_do[7:0] ),
	.gfx_rom_addr     ( gfx_addr        ),
	.gfx_rom_do       ( gfx_do          ),
	.snd_rom_addr     ( snd_addr        ),
	.snd_rom_do       ( snd_addr[0] ? snd_do[15:8] : snd_do[7:0] ),
	.snd2_rom_addr    ( snd2_addr        ),
	.snd2_rom_do      ( snd2_addr[0] ? snd2_do[15:8] : snd2_do[7:0] ),

	.video_r          ( r               ),
	.video_g      	  ( g               ),
	.video_b      	  ( b               ),
	.video_i          ( i               ),
	.video_hs     	  ( hs              ),
	.video_vs     	  ( vs              ),
	.video_blankn 	  ( blankn          ),
	.audio_left       ( audio_left      ),
	.audio_right      ( audio_right     ),

	.btn_auto_up      ( autoup          ),
	.btn_advance      ( advance         ),
	.btn_high_score_reset ( hsreset     ),
	.btn_coin         ( m_coin1 | m_coin2 ),

	.input1           ( input1          ),
	.input2           ( input2          ),
	.input_sel        ( input_sel       ),

	.dl_clock         ( clk_mem ),
	.dl_addr          ( ioctl_addr[15:0] ),
	.dl_data          ( ioctl_dout ),
	.dl_wr            ( ioctl_wr && ioctl_index == 0 ),
	.up_data          ( ioctl_din  ),
	.cmos_wr          ( ioctl_wr && ioctl_index == 8'hff )
);

wire  [7:0] red;
wire  [7:0] green;
wire  [7:0] blue;

williams2_colormix williams2_colormix (
	.mysticm   ( core_mod[1:0] == 3 ),
	.r         ( r     ),
	.g         ( g     ),
	.b         ( b     ),
	.intensity ( i     ),
	.vga_r     ( red   ),
	.vga_g     ( green ),
	.vga_b     ( blue  )
);

mist_dual_video #(.COLOR_DEPTH(8), .SD_HCNT_WIDTH(9), .OUT_COLOR_DEPTH(VGA_BITS), .USE_BLANKS(1'b1), .BIG_OSD(BIG_OSD)) mist_video(
	.clk_sys        ( clk_mem          ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( red              ),
	.G              ( green            ),
	.B              ( blue             ),
	.HBlank         ( ~blankn          ),
	.VBlank         ( ~vs              ),
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
`ifdef DUAL_SDRAM
	.clk_sdram      ( clk_mem          ),
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
	.rotate         ( {orientation[1],rotate} ),
	.rotate_screen  ( rotate_screen    ),
	.rotate_hfilter ( rotate_filter    ),
	.rotate_vfilter ( rotate_filter    ),
	.scandoubler_disable( scandoublerD ),
	.no_csync       ( no_csync         ),
	.scanlines      ( scanlines        ),
	.blend          ( blend            ),
	.ypbpr          ( ypbpr            )
	);
	
`ifdef USE_HDMI

i2c_master #(12_000_000) i2c_master (
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

dac #(
	.C_bits(17))
dacl(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_left),
	.dac_o(AUDIO_L)
	);

dac #(
	.C_bits(17))
dacr(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio_right),
	.dac_o(AUDIO_R)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_vid),
	.clk_rate(32'd48_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan({1'b0, audio_left[16:2]}),
	.right_chan({1'b0, audio_right[16:2]})
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
	.clk_rate_i(32'd48_000_000),
	.spdif_o(SPDIF),
	.sample_i({1'b0, audio_right[16:2], 1'b0, audio_left[16:2]})
);
`endif

// Turkey shot guns
reg  signed [8:0] x, y;
wire [5:0] gun_v = x[8:3], gun_h = y[8:3];
wire [5:0] gun_bin_code =  input_sel ? gun_v : gun_h;

always @(posedge clk_sys) begin
	if (mouse_strobe) begin
		x <= x + mouse_x;
		y <= y - mouse_y;
	end
end

gray_code gun_gray_encoder (
	.clk(clk_sys),
	.addr(gun_bin_code),
	.data(gun_gray_code)
);

// Common inputs
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF, m_upB, m_downB, m_leftB, m_rightB;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F, m_up2B, m_down2B, m_left2B, m_right2B;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

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
	.oneplayer   ( oneplayer   ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_upB, m_downB, m_leftB, m_rightB, 6'd0, m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_up2B, m_down2B, m_left2B, m_right2B, 6'd0, m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule

module trigger (
	input clk,
	input btn,
	output trigger
);

reg  [23:0] counter;
assign      trigger = (counter != 0);

always @(posedge clk) begin
	reg btn_d;

	btn_d <= btn;
	if (~btn_d & btn) counter <= 24'hfffff;
	if (counter != 0) counter <= counter - 1'd1;
end

endmodule
