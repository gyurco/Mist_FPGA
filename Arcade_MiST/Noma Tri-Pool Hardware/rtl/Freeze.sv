module Freeze (
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
	"Freeze;;",
	"O2,Rotate Controls,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	`SEP
	"DIP;",
	`SEP
//	"OOR,CRT H adjust,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;",
//   "OSV,CRT V adjust,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;",
//	"OC,Monochrome,Off,On;",
//	"O7,Service,Off,On;",
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};


wire          rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire           blend = status[5];
wire       joyswap   = status[6];
//wire        service  = status[7];
wire [1:0] orientation = 2'b01;


assign 		LED = ~ioctl_downl;
assign 		AUDIO_R = AUDIO_L;
assign 		SDRAM_CLK = ~clock_48;
assign 		SDRAM_CKE = 1;

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
	.FEATURES(32'h0 | (BIG_OSD << 13) | (HDMI << 14)))
user_io(
	.clk_sys        (clock_48       ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD),
	.ypbpr          (ypbpr          ),
	.core_mod       (core_mod       ),
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
	.status         (status         )
	);

wire  [9:0] audio;
wire        hs, vs, cs;
wire        hb, vb;
wire  [2:0] r, g;
wire  [1:0] b;
wire        ioctl_downl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

reg reset = 1;
reg rom_loaded = 0;
always @(posedge clock_48) begin
	reg ioctl_downlD;
	ioctl_downlD <= ioctl_downl;
	if (ioctl_downlD & ~ioctl_downl) rom_loaded <= 1;
	reset <= status[0] | buttons[1] | ~rom_loaded;
end

wire clock_48, pll_locked;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_48),//48 MHz
	.locked(pll_locked)
	);

data_io data_io(
	.clk_sys       ( clock_48     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(9), .OUT_COLOR_DEPTH(VGA_BITS), .USE_BLANKS(1'd1), .BIG_OSD(BIG_OSD)) mist_video(
	.clk_sys        ( clock_48         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( {b[1],b}         ),
	.HBlank         ( hb               ),
	.VBlank         ( vb               ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 3'd7             ),
	.rotate         ( { orientation[1], rotate } ),
	.blend          ( blend            ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

`ifdef USE_HDMI

i2c_master #(48_000_000) i2c_master (
	.CLK         (clock_48),

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

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(9), .OUT_COLOR_DEPTH(8), .USE_BLANKS(1'd1), .BIG_OSD(BIG_OSD)) hdmi_video(
	.clk_sys        ( clock_48         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( {b[1],b}         ),
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
	.ce_divider     ( 3'd7             ),
	.rotate         ( { orientation[1], rotate } ),
	.blend          ( blend            ),
	.scandoubler_disable( 1'b0         ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( 1'b0             ),
	.no_csync       ( 1'b1             )
	);

	assign HDMI_PCLK = clock_48;

`endif

dac #(.C_bits(16))dac_l(
	.clk_i(clock_48),
	.res_n_i(1),
	.dac_i({ 1'b0, audio, 5'd0 }),
	.dac_o(AUDIO_L)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clock_48),
	.clk_rate(32'd48_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan({ 1'b0, audio, 5'd0 }),
	.right_chan({ 1'b0, audio, 5'd0 })
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clock_48) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clock_48),
	.clk_rate_i(32'd48_000_000),
	.spdif_o(SPDIF),
	.sample_i({ 1'b0, audio, 5'd0, 1'b0, audio, 5'd0 })
);
`endif
	
wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs #(.START1(9), .START2(10), .COIN1(11), .COIN2(12)) inputs (
	.clk         ( clock_48    ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( orientation ),
	.joyswap     ( joyswap     ),
	.oneplayer   ( 1'b0   		),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_four_players, m_three_players, m_two_players, m_one_player} ),
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

wire [13:0] mcpu_rom1_addr;
wire [15:0] mcpu_rom1_data;
wire [13:0] mcpu_rom2_addr;
wire [15:0] mcpu_rom2_data;
reg         port1_req;	
sdram #(48) sdram(
	.*,
	.init_n        ( pll_locked ),
	.clk           ( clock_48   ),

	// port1
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[23:1] ),
	.port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),
	.port1_q       ( ),
	.cpu1_addr     ( ioctl_downl ? 16'hffff : {2'b00, mcpu_rom1_addr[13:1]} ),
	.cpu1_q        ( mcpu_rom1_data ),
	.cpu2_addr     ( ioctl_downl ? 16'hffff : {2'b00, mcpu_rom2_addr[13:1] + 16'h2000} ),//check
	.cpu2_q        ( mcpu_rom2_data ),
	// port2
	.port2_req     ( ),
	.port2_ack     ( ),
	.port2_a       ( ),
	.port2_ds      ( ),
	.port2_we      ( ),
	.port2_d       ( ),
	.port2_q       ( ),

	.bg_addr       ( ),
	.bg_q          ( )
);

// ROM download controller
always @(posedge clock_48) begin
	reg        ioctl_wr_last = 0;

	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
		end
	end
end

wire [7:0] DSW1 = status[23:16];
wire [7:0] DSW2 = status[31:24];
wire btn_A, btn_B, btn_C;
always @(posedge clock_48) begin
	if(key_strobe) begin
		case(key_code)
		'h1C: btn_A        <= key_pressed; // A
		'h32: btn_B        <= key_pressed; // B
		'h21: btn_C        <= key_pressed; // C
		endcase
	end
end
		
wire [7:0] p0, p1, p2, p3;
wire [6:0] core_mod;
always @* begin
	p0 = 8'hFF;
	p1 = 8'hFF;
	p2 = 8'hFF;
	p3 = 8'hFF;
	case (core_mod)
		7'h0: begin // freeze
			p0 = { 2'b0, m_coin1 , 3'b0, m_two_players, m_one_player };
			p1 = { 6'd0, m_left, m_right };
			p2 = { 6'd0, m_fireB, m_fireA };
			p3 = { 6'd0, m_fire2B, m_fire2A };
		end
		7'h1: begin // jack
			p0 = { 1'b0, m_coin1, m_coin2 , 3'b0, m_two_players, m_one_player };
			p1 = { m_left2, m_right2, m_down2, m_up2, m_left, m_right, m_down, m_up };
			p2 = { 6'd0, m_fireB, m_fireA };
			p3 = { 6'd0, m_fire2B, m_fire2A };
		end
		7'h2: begin // zzyzzyxx
			p0 = { 1'b0, m_coin1, m_coin2 , 3'b0, m_two_players, m_one_player };
			p1 = { 2'b00, m_down2, m_up2, 2'b00, m_down, m_up };
			p2 = { 7'd0, m_fireA };
			p3 = { 7'd0, m_fire2A };
		end
		7'h3: begin // super casino
			p0 = { 1'b0, m_coin1, 4'b0, m_two_players, m_one_player };
			p1 = { m_left2, m_right2, 1'b0, 1'b0, m_left, m_right, 1'b0, 1'b0 };
			p2 = { 7'd0, m_fireA };
			p3 = { 7'd0, m_fire2A };
		end
		7'h4: begin // tri-pool
			p0 = { 1'b0, m_coin1, m_coin2 , btn_C | m_fireE, btn_B | m_fireD, btn_A | m_fireC, m_two_players, m_one_player };
			p1 = { m_left2, m_right2, m_down2, m_up2, m_left, m_right, m_down, m_up };
			p2 = { 6'd0, m_fireB, m_fireA };
			p3 = { 6'd0, m_fire2B, m_fire2A };
		end
		default;
	endcase
end

core core(
	.reset				(reset),
	.clk_sys				(clock_48),
	.dsw1					(DSW1),
	.dsw2					(DSW2),
	.p0					(p0),
	.p1					(p1),
	.p2					(p2),
	.p3					(p3),
	.red					(r),
	.green				(g),
	.blue					(b),
	.hb					(hb),
	.vb					(vb),
	.hs					(hs),
	.vs					(vs),
	.ce_pix				(),//out
	.sound				(audio),
	.mcpu_rom1_addr	(mcpu_rom1_addr),
	.mcpu_rom1_data	(mcpu_rom1_addr[0] ? mcpu_rom1_data[15:8] : mcpu_rom1_data[7:0]),	
	.mcpu_rom2_addr	(mcpu_rom2_addr),
	.mcpu_rom2_data	(mcpu_rom2_addr[0] ? mcpu_rom2_data[15:8] : mcpu_rom2_data[7:0]),	 
	.ioctl_download	(ioctl_downl),
	.ioctl_addr			(ioctl_addr),
	.ioctl_dout			(ioctl_dout),
	.ioctl_wr			(ioctl_wr)
);

endmodule 