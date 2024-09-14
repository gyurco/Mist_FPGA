module SuprLoco_MiST (
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
	"SUPRLOCO;;",
	"O2,Rotate Controls,Off,On;",
//	"OWX,Orientation,Vertical,Clockwise,Anticlockwise;",
//	"OY,Rotation filter,Off,On;",
	"O34,Scanlines,None,CRT 25%,CRT 50%,CRT 75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	`SEP
	"DIP;",
	`SEP
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire       rotate = status[2];
wire [1:0] scanlines = status[4:3];
wire       blend = status[5];
wire       joyswap = status[6];
wire [1:0] orientation = {core_mod[2], core_mod[0]};
wire [1:0] rotate_screen = 0;//status[33:32];
//wire       rotate_filter = status[34];

assign    LED = ~ioctl_downl;
assign    AUDIO_R = AUDIO_L;
assign    SDRAM_CLK = clock_40;
assign    SDRAM_CKE = 1;

wire pll_locked, clock_40;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_40),
	.locked(pll_locked)
	);

wire  [6:0] core_mod;
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
	.clk_sys        (clock_40       ),
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
wire [15:0] rom_addr;
wire        rom_oe;

wire [15:0] rom2_dout;
wire [12:0] rom2_addr;
wire        rom2_oe;

data_io data_io(
	.clk_sys       ( clock_40     ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_DI        ( SPI_DI       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   )
);

wire        hsync_n, vsync_n;
wire        hblank_n, vblank_n;
wire  [2:0] video_r, video_g, video_b;
wire [15:0] sound;


sdram #(.MHZ(40)) sdram(
	.*,
	.init_n        ( pll_locked   ),
	.clk           ( clock_40     ),

	// ROM upload
	.port1_req     ( port1_req    ),
	.port1_ack     ( ),
	.port1_a       ( ioctl_addr[22:1] ),
	.port1_ds      ( { ioctl_addr[0], ~ioctl_addr[0] } ),
	.port1_we      ( ioctl_downl ),
	.port1_d       ( {ioctl_dout, ioctl_dout} ),

	// CPU
	.cpu1_addr     ( ioctl_downl ? 17'h1ffff : {2'b000, rom_addr[15:1] } ),
	.cpu1_q        ( rom_dout  ),
	.cpu2_addr     ( ioctl_downl ? 17'h1ffff : {5'b01100, rom2_addr[12:1] } ),
	.cpu2_q        ( rom2_dout  )
);

always @(posedge clock_40) begin
	reg        ioctl_wr_last = 0;
 
	ioctl_wr_last <= ioctl_wr;
	if (ioctl_downl) begin
		if (~ioctl_wr_last && ioctl_wr) begin
			port1_req <= ~port1_req;
		end
	end
end

reg reset;
always @(posedge clock_40) reset <= status[0] | buttons[1] | ioctl_downl;

//bram control
reg     [7:0]   prog_bram_din_buf;
reg     [16:0]  prog_bram_addr;
reg             prog_bram_wr;
reg     [11:0]  prog_bram_csreg;
reg             rom_download_done = 1'b0;
reg             prog_bram_en = 1'b0;

always @(posedge clock_40, negedge pll_locked) begin
	if (~pll_locked) begin
        //enables
        prog_bram_en <= 1'b0;

        //bram
        prog_bram_din_buf <= 8'hFF;
        prog_bram_addr <= 17'h1FFFF;
        prog_bram_wr <= 1'b0;
        prog_bram_csreg <= 12'b0000_0000_0000;
	end
   else if(rom_download_done) begin
        //enables
        prog_bram_en <= 1'b0;

        //bram
        prog_bram_din_buf <= 8'hFF;
        prog_bram_addr <= 17'h1FFFF;
        prog_bram_wr <= 1'b0;
        prog_bram_csreg <= 12'b0000_0000_0000;
    end
    else begin
        //  ROM DATA UPLOAD
        if(ioctl_index == 0) begin //ROM DATA
            prog_bram_en <= 1'b1;

            if(ioctl_wr == 1'b1) begin
                prog_bram_din_buf <= ioctl_dout;
                prog_bram_addr <= ioctl_addr[16:0];
                prog_bram_wr <= 1'b1;

                if(ioctl_addr[16] == 1'b0) begin
                         if(ioctl_addr[15:14] == 2'b00) prog_bram_csreg <= 12'b0000_0000_0001;
                    else if(ioctl_addr[15:14] == 2'b01) prog_bram_csreg <= 12'b0000_0000_0010;
                    else if(ioctl_addr[15:14] == 2'b10) prog_bram_csreg <= 12'b0000_0000_0100;
                    else if(ioctl_addr[15:14] == 2'b11) prog_bram_csreg <= 12'b0000_0000_1000;
                end
                else begin
                         if(ioctl_addr[15:13] == 3'b000) prog_bram_csreg <= 12'b0000_0001_0000;
                    else if(ioctl_addr[15:13] == 3'b001) prog_bram_csreg <= 12'b0000_0010_0000;
                    else if(ioctl_addr[15:13] == 3'b010) prog_bram_csreg <= 12'b0000_0100_0000;
                    else if(ioctl_addr[15:13] == 3'b011) prog_bram_csreg <= 12'b0000_1000_0000;
                    else if(ioctl_addr[15:13] == 3'b100) prog_bram_csreg <= 12'b0001_0000_0000;
                    else if(ioctl_addr[15:13] == 3'b101) begin
                             if(ioctl_addr[12:9] == 4'b0_000) prog_bram_csreg <= 12'b0010_0000_0000;
                        else if(ioctl_addr[12:9] == 4'b0_001) prog_bram_csreg <= 12'b0010_0000_0000;
                        else if(ioctl_addr[12:9] == 4'b0_010) prog_bram_csreg <= 12'b0100_0000_0000;
                        else if(ioctl_addr[12:9] == 4'b0_011) prog_bram_csreg <= 12'b1000_0000_0000;
                    end
                end
            end
            else begin
                prog_bram_wr <= 1'b0;
            end
        end
    end
end

wire  [7:0] P1_BTN = {2'b11, ~m_fireB, ~m_fireA, ~m_down, ~m_up, ~m_left, ~m_right};
wire  [7:0] P2_BTN = {2'b11, ~m_fire2B, ~m_fire2A, ~m_down2, ~m_up2, ~m_left2, ~m_right2};
wire  [7:0] SYS_BTN = {2'b11, ~m_two_players, ~m_one_player, ~m_fireC, ~m_fireD, ~m_coin2, ~m_coin1};
wire  [7:0] DIPSW1 = status[23:16];
wire  [7:0] DIPSW2 = status[31:24];

SuprLoco_top u_gameboard_main (
    .i_EMU_CLK40M               (clock_40           ),
    .i_EMU_INITRST_n            (pll_locked         ),
    .i_EMU_SOFTRST_n            (~reset             ),

    .o_HSYNC_n                  (hsync_n            ),
    .o_VSYNC_n                  (vsync_n            ),
    .o_CSYNC_n                  (                   ),
    .o_HBLANK_n                 (hblank_n           ),
    .o_VBLANK_n                 (vblank_n           ),

    .o_VIDEO_CEN                (                   ),
    .o_VIDEO_DEN                (                   ),
    .o_VIDEO_R                  (video_r            ),
    .o_VIDEO_G                  (video_g            ),
    .o_VIDEO_B                  (video_b            ),

    .o_SOUND                    (sound              ),

    .i_P1_BTN                   (P1_BTN             ),
    .i_P2_BTN                   (P2_BTN             ),
    .i_SYS_BTN                  (SYS_BTN            ),
    .i_DIPSW1                   (DIPSW1             ),
    .i_DIPSW2                   (DIPSW2             ),

	 .cpu1_addr                  (rom_addr           ),
	 .cpu1_din                   (rom_addr[0] ? rom_dout[15:8] : rom_dout[7:0]),
	 .cpu2_addr                  (rom2_addr          ),
	 .cpu2_din                   (rom2_addr[0] ? rom2_dout[15:8] : rom2_dout[7:0]),

    .i_EMU_BRAM_ADDR            (prog_bram_addr     ),
    .i_EMU_BRAM_DATA            (prog_bram_din_buf  ),
    .i_EMU_BRAM_WR              (prog_bram_wr       ),
    
    .i_EMU_BRAM_PGMROM0_CS      (prog_bram_csreg[0] ),
    .i_EMU_BRAM_PGMROM1_CS      (prog_bram_csreg[1] ),
    .i_EMU_BRAM_DATAROM_CS      (prog_bram_csreg[2] ),
    .i_EMU_BRAM_OBJROM0_CS      (prog_bram_csreg[3] ),
    .i_EMU_BRAM_OBJROM1_CS      (prog_bram_csreg[4] ),
    .i_EMU_BRAM_TMROM0_CS       (prog_bram_csreg[5] ),
    .i_EMU_BRAM_TMROM1_CS       (prog_bram_csreg[6] ),
    .i_EMU_BRAM_TMROM2_CS       (prog_bram_csreg[7] ),
    .i_EMU_BRAM_SNDPRG_CS       (prog_bram_csreg[8] ),
    .i_EMU_BRAM_CONVLUT_CS      (prog_bram_csreg[9] ),
    .i_EMU_BRAM_PALROM_CS       (prog_bram_csreg[10]),
    .i_EMU_BRAM_TMSEQROM_CS     (prog_bram_csreg[11])
);

mist_dual_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(9), .OUT_COLOR_DEPTH(VGA_BITS), .BIG_OSD(BIG_OSD), .USE_BLANKS(1'b1)) mist_video(
	.clk_sys        ( clock_40         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( video_r          ),
	.G              ( video_g          ),
	.B              ( video_b          ),
	.HBlank         ( ~hblank_n        ),
	.VBlank         ( ~vblank_n        ),
	.HSync          ( hsync_n          ),
	.VSync          ( vsync_n          ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 4'd7             ),
`ifdef USE_HDMI
	.HDMI_R         ( HDMI_R           ),
	.HDMI_G         ( HDMI_G           ),
	.HDMI_B         ( HDMI_B           ),
	.HDMI_VS        ( HDMI_VS          ),
	.HDMI_HS        ( HDMI_HS          ),
	.HDMI_DE        ( HDMI_DE          ),
`endif
/*
	.clk_sdram      ( clock_40         ),
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
*/
	.blend          ( blend            ),
	.rotate         ( {orientation[1], rotate} ),
/*
	.rotate_screen  ( rotate_screen    ),
	.rotate_hfilter ( rotate_filter    ),
	.rotate_vfilter ( rotate_filter    ),
*/
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( ypbpr            ),
	.no_csync       ( no_csync         )
	);

`ifdef USE_HDMI

i2c_master #(40_000_000) i2c_master (
	.CLK         (clock_40),

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

assign HDMI_PCLK = clock_40;
`endif

dac #(.C_bits(16))dac(
	.clk_i(clock_40),
	.res_n_i(1),
	.dac_i({~sound[15], sound[14:0]}),
	.dac_o(AUDIO_L)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clock_40),
	.clk_rate(32'd40_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan(sound),
	.right_chan(sound)
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(clock_40) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
	.rst_i(1'b0),
	.clk_i(clock_40),
	.clk_rate_i(32'd40_000_000),
	.spdif_o(SPDIF),
	.sample_i({2{sound}})
);
`endif

wire m_up, m_down, m_left, m_right, m_fireA, m_fireB, m_fireC, m_fireD, m_fireE, m_fireF;
wire m_up2, m_down2, m_left2, m_right2, m_fire2A, m_fire2B, m_fire2C, m_fire2D, m_fire2E, m_fire2F;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_one_player, m_two_players, m_three_players, m_four_players;

arcade_inputs #(.START1(9), .START2(10), .COIN1(8)) inputs (
	.clk         ( clock_40    ),
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
	.player1     ( {m_fireF, m_fireE, m_fireD, m_fireC, m_fireB, m_fireA, m_up, m_down, m_left, m_right} ),
	.player2     ( {m_fire2F, m_fire2E, m_fire2D, m_fire2C, m_fire2B, m_fire2A, m_up2, m_down2, m_left2, m_right2} )
);

endmodule
