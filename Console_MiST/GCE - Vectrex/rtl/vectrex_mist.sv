module vectrex_mist
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
	inout         HDMI_SDA,
	inout         HDMI_SCL,
	input         HDMI_INT,
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
`ifdef USE_MIDI_PINS
	input         MIDI_IN,
	output        MIDI_OUT,
`endif
`ifdef SIDI128_EXPANSION
	input         UART_CTS,
	output        UART_RTS,
	inout         EXP7,
	inout         MOTOR_CTRL,
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

`ifdef USE_AUDIO_IN
localparam bit USE_AUDIO_IN = 1;
`else
localparam bit USE_AUDIO_IN = 0;
`endif

`ifdef USE_MIDI_PINS
localparam bit USE_MIDI_PINS = 1;
`else
localparam bit USE_MIDI_PINS = 0;
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
	"Vectrex;BINVECROM;",
	"O1,CPU,MC6809,CPU09;",
	"O2,Show Frame,Yes,No;",
	"O3,Skip Logo,Yes,No;",
	"O4,Joystick swap,Off,On;",
	"O5,Second port,Joystick,Speech;",
//	"O23,Phosphor persistance,1,2,3,4;",
//	"O8,Overburn,No,Yes;",	
	"T6,Reset;",
	"V,v1.50.",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire [15:0] joy_ana_0;
wire [15:0] joy_ana_1;
wire        ypbpr;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;

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
	.clk_sys        (clk_24         ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.core_mod       (core_mod       ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.status         (status         ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.joystick_analog_0( joy_ana_0   ),
	.joystick_analog_1( joy_ana_1   ),
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
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.no_csync       (no_csync       )
	);
	
wire  [7:0]	pot_x_1, pot_x_2;
wire  [7:0]	pot_y_1, pot_y_2;
wire  [9:0] audio;
wire 			hs, vs, cs;
wire  [3:0] r, g, b;
wire 			hb, vb;
wire 			cart_rd;
wire [14:0] cart_addr;
wire  [7:0] cart_do;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;


assign LED = !ioctl_downl;

wire 			clk_24, clk_12;
wire 			pll_locked;

pll pll (
	.inclk0 ( CLOCK_27   ),
	.areset ( 0          ),
	.c0     ( clk_24     ),
	.c1     ( clk_12     ),
	.locked ( pll_locked )
	);

assign SDRAM_CLK = clk_24;
assign SDRAM_CKE = 1;

reg         sdram_req;
wire [24:1] sdram_a = ioctl_downl ? ioctl_addr[24:1] : cart_addr[14:1];
wire  [1:0] sdram_ds = ioctl_downl ? {ioctl_addr[0], ~ioctl_addr[0]} : 2'b11;
wire [15:0] sdram_q;
assign      cart_do = cart_addr[0] ? sdram_q[15:8] : sdram_q[7:0];

sdram #(24) cart
(
	.*,
	.clk(clk_24),
	.init_n(pll_locked),
	.port1_req(sdram_req),
	.port1_ack(),
	.port1_a(sdram_a),
	.port1_we(ioctl_downl),
	.port1_ds(sdram_ds),
	.port1_d({ioctl_dout, ioctl_dout}),
	.port1_q(sdram_q)
);

always @(posedge clk_24) begin
	reg [14:1] cart_addrD;

	if (ioctl_downl) begin
		if (ioctl_wr) sdram_req <= !sdram_req;
	end
	else begin
		cart_addrD <= cart_addr[14:1];
		if (cart_rd & cart_addr[14:1] != cart_addrD) sdram_req <= !sdram_req;
	end
end

reg reset = 0;
reg second_reset = 0;

always @(posedge clk_24) begin
	integer timeout = 0;
	reg [15:0] reset_counter = 0;
	reg reset_start;

	reset <= 0;
	reset_start <= status[0] | status[6] | buttons[1] | ioctl_downl | second_reset;
	if (reset_counter) begin
		reset <= 1'b1;
		reset_counter <= reset_counter - 1'd1;
	end
	if (reset_start) reset_counter <= 16'd1000;

	second_reset <= 0;
	if (timeout) begin
		timeout <= timeout - 1;
		if(timeout == 1) second_reset <= 1'b1;
	end
	if(ioctl_downl && !status[3]) timeout <= 5000000;
end

assign pot_x_1 = status[4] ? joy_ana_1[15:8] : joy_ana_0[15:8];
assign pot_x_2 = status[4] ? joy_ana_0[15:8] : joy_ana_1[15:8];
assign pot_y_1 = status[4] ? ~joy_ana_1[ 7:0] : ~joy_ana_0[ 7:0];
assign pot_y_2 = status[4] ? ~joy_ana_0[ 7:0] : ~joy_ana_1[ 7:0];

vectrex vectrex (
	.clock_24     ( clk_24    ),
	.clock_12     ( clk_12    ),
	.reset        ( reset     ),
	.cpu          ( status[1] ),
	.video_r      ( rr				),
	.video_g      ( gg				),
	.video_b      ( bb				),
	.video_csync  ( cs				),
	.video_hblank ( hb				),
	.video_vblank ( vb				),
	.speech_mode  ( status[5]		),
	.video_hs     ( hs				),
	.video_vs     ( vs				),
	.frame        ( frame_line	),
	.audio_out    ( audio			),
	.cart_addr    ( cart_addr		),
	.cart_do      ( cart_do		),
	.cart_rd      ( cart_rd		),	
	.btn11        ( status[4] ? joystick_1[4] : joystick_0[4]),
	.btn12        ( status[4] ? joystick_1[5] : joystick_0[5]),
	.btn13        ( status[4] ? joystick_1[6] : joystick_0[6]),
	.btn14        ( status[4] ? joystick_1[7] : joystick_0[7]),
	.pot_x_1      ( pot_x_1			),
	.pot_y_1      ( pot_y_1			),
	.btn21        ( status[4] ? joystick_0[4] : joystick_1[4]),
	.btn22        ( status[4] ? joystick_0[5] : joystick_1[5]),
	.btn23        ( status[4] ? joystick_0[6] : joystick_1[6]),
	.btn24        ( status[4] ? joystick_0[7] : joystick_1[7]),
	.pot_x_2      ( pot_x_2			),
	.pot_y_2      ( pot_y_2			),
	.leds         ( ),
	.dbg_cpu_addr ( )
	);

dac #(10) dac (
	.clk_i			( clk_24			),
	.res_n_i		( 1				),
	.dac_i			( audio			),
	.dac_o			( AUDIO_L		)
	);
assign AUDIO_R = AUDIO_L;

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_24),
	.clk_rate(32'd24_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan({3'd0, audio, 3'd0}),
	.right_chan({3'd0, audio, 3'd0})
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clk_24) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clk_24),
	.clk_rate_i(32'd24_000_000),
	.spdif_o(SPDIF),
	.sample_i({2{3'd0, audio, 3'd0}})
);
`endif

//////////////////   VIDEO   //////////////////

wire frame_line;
wire [3:0] rr,gg,bb;

assign r = status[2] & frame_line ? 4'h4 : rr;
assign g = status[2] & frame_line ? 4'h0 : gg;
assign b = status[2] & frame_line ? 4'h0 : bb;

mist_dual_video #(.COLOR_DEPTH(4), .OUT_COLOR_DEPTH(VGA_BITS), .USE_BLANKS(1'b1), .BIG_OSD(BIG_OSD)) mist_video
(
	.clk_sys(clk_24),
	.SPI_DI(SPI_DI),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.scandoubler_disable(1'b1),
	.rotateonly(1'b1),
	.rotate(2'b00),
	.ypbpr(ypbpr),
	.HBlank(hb),
	.VBlank(vb),
	.HSync(hs),
	.VSync(vs),
	.R(r),
	.G(g),
	.B(b),
`ifdef USE_HDMI
	.HDMI_R         ( HDMI_R           ),
	.HDMI_G         ( HDMI_G           ),
	.HDMI_B         ( HDMI_B           ),
	.HDMI_VS        ( HDMI_VS          ),
	.HDMI_HS        ( HDMI_HS          ),
	.HDMI_DE        ( HDMI_DE          ),
`endif
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B)
);

`ifdef USE_HDMI
i2c_master #(24_000_000) i2c_master (
	.CLK         (clk_24),
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

assign HDMI_PCLK = clk_24;

`endif
    
////////////////////////////////////////////
data_io data_io (
	.clk_sys       ( clk_24       ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
	);

endmodule 
