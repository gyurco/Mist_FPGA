module invaders_MiST (
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
	"INVADERS;;",
	"O2,Rotate Controls,Off,On;",
	"O67,Orientation,Vertical,Clockwise,Anticlockwise;",
	"O1,Rotation filter,Off,On;",
	"O8,Blend,Off,On;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Overlay,On,Off;",
	`SEP
	"DIP;",
	`SEP
	"OCD,Gun Control,Joy1,Joy2,Mouse,Disabled;",
	"OEF,Crosshair,Small,Medium,Big,None;",
	`SEP
	"T0,Reset;",
	"V,v1.20.",`BUILD_DATE
};

wire  [1:0] scanlines = status[4:3];
wire        rotate    = status[2];
wire        overlay   = ~status[5];
wire  [1:0] rotate_screen = status[7:6];
wire        rotate_filter = status[1];
wire        blend = status[8];

wire  [7:0] sw[8];
assign sw[0] = status[23:16];
assign sw[1] = status[31:24];
assign sw[2] = status[39:32];
assign sw[3] = status[47:40];

assign LED = ~ioctl_downl;
assign AUDIO_R = AUDIO_L;

wire clk_sys, clk_vid;
wire pll_locked;
pll pll
(
	.inclk0(CLOCK_27),
	.areset(),
	.locked(pll_locked),
	.c0(clk_vid),
	.c1(clk_sys)
);

wire  [6:0] core_mod;
wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [31:0] joystick_0;
wire  [31:0] joystick_1;
wire [31:0] joystick_analog_0;
wire [31:0] joystick_analog_1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire        key_pressed;
wire  [7:0] key_code;
wire        key_strobe;
wire        mouse_strobe;
wire  [7:0] mouse_flags;  // YOvfl, XOvfl, dy8, dx8, 1, mbtn, rbtn, lbtn
wire  [8:0] mouse_x;
wire  [8:0] mouse_y;

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

reg reset_sys;
always @(posedge clk_sys) reset_sys <= status[0] | buttons[1] | ioctl_downl;

// Games - Completed
localparam mod_boothill      = 5;
localparam mod_seawolf       = 33;

// Games - Working
localparam mod_spaceinvaders = 0;
localparam mod_vortex        = 2;
localparam mod_spacewalk     = 9;
localparam mod_spaceinvaderscv = 10;
localparam mod_ballbomb      = 16;
localparam mod_clowns        = 19;			// P2 Controls / Flip
localparam mod_cosmo         = 20;
localparam mod_indianbattle  = 26;
localparam mod_lupin         = 27; // Set 2 - uses colour ram

localparam mod_attackforce   = 15;
localparam mod_polaris       = 30;

// Games - Not yet looked at
localparam mod_shuffleboard  = 1;
localparam mod_280zap        = 3;
localparam mod_blueshark     = 4;
localparam mod_lunarrescue   = 6;
localparam mod_ozmawars      = 7;
localparam mod_spacelaser    = 8;
localparam mod_unknown1      = 11;
localparam mod_unknown2      = 12;
localparam mod_spaceinvadersii = 13;
localparam mod_amazingmaze   = 14;
localparam mod_bowler        = 17;
localparam mod_checkmate     = 18;
localparam mod_dogpatch      = 21;
localparam mod_doubleplay    = 22;
localparam mod_guidedmissle  = 23;
localparam mod_claybust      = 24;
localparam mod_gunfight      = 25;
localparam mod_m4            = 28;
localparam mod_phantom       = 29;
localparam mod_desertgun     = 31;
localparam mod_lagunaracer   = 32;
localparam mod_yosakdon      = 34;
localparam mod_spacechaser   = 35;
localparam mod_steelworker   = 36;
localparam mod_rollingcrash  = 37;
localparam mod_lupin1        = 38; // Set 1 : uses colour prom rather than colour ram
localparam mod_spaceinvaders2= 39;
localparam mod_spaceenc      = 40;

wire  [6:0] mod = core_mod;

// Global Enables
reg  landscape;			// Landscape
reg  ccw;					// Rotates Counter Clockwise
reg  color_rom_enabled;	// Uses colour prom / ram
wire WDEnabled;			// Uses Watchdog
wire ShiftReverse;		// Uses shifter that does both directions
wire Audio_Output;		// Audio output control
wire ScreenFlip;			// Flip the screen 180 degrees
wire Overlay4;          // Overlay aligned to 4 pixels (otherwise 8)
reg  software_flip;     // Flip the screen when software says to 

// Trigger addresses - set addresses where these registers are written to
wire Trigger_ShiftCount;
wire Trigger_ShiftData;
wire Trigger_AudioDeviceP1;
wire Trigger_AudioDeviceP2;
wire Trigger_WatchDogReset;
wire Trigger_Tone_Low;
wire Trigger_Tone_High;

wire [15:0] joya  = joystick_analog_0[15:0];
wire [15:0] joya2 = joystick_analog_1[15:0];

// Port data 
wire  [7:0] PortWr;

// Shifter data
wire  [7:0] S;
wire  [7:0] SR= { S[0], S[1], S[2], S[3], S[4], S[5], S[6], S[7]} ;

// Midway Tone Generator data
wire  [5:0] Tone_Low;
wire  [7:0] Tone_High; // Also used for Balloon Bomber and Polaris
wire  [7:0] GDB0;
wire  [7:0] GDB1;
wire  [7:0] GDB2;
wire  [7:0] GDB3;
wire  [7:0] GDB4;
wire  [7:0] GDB5;
wire  [7:0] GDB6;

always @(*) begin

	// Defaults - games in case statement change these as needed
	software_flip     = 0;      
	gun_game          = 0;
	landscape         = 1;
	ccw               = 0;
	color_rom_enabled = 0;
	WDEnabled         = 1;
	GDB0              = 8'hFF;
	GDB1              = 8'hFF;
	GDB2              = 8'hFF;
	GDB3              = S;
	GDB4              = 8'hFF;
	GDB5              = 8'hFF;
	GDB6              = 8'hFF;
	Audio_Output      = 1;        // Default = ON : won't do anything if no sample header loaded. 
	                              // some games control audio output via an output bit somewhere!
	Force_Red         = 0;
	Background_Col    = {1'b0,1'b0,1'b0}; // Black

	ScreenFlip        = status[6];
	Overlay4          = 0;        // Default aligned to characters

	// default PortWr mapping
	Trigger_ShiftCount     = PortWr[2];
	Trigger_AudioDeviceP1  = PortWr[3];
	Trigger_ShiftData      = PortWr[4];
	Trigger_AudioDeviceP2  = PortWr[5];
	Trigger_WatchDogReset  = PortWr[6];		  
	Trigger_Tone_Low       = 0;
	Trigger_Tone_High      = 0;

    case (mod) 
  
	mod_spaceinvaders:
	begin
		landscape      = 0;
		ccw            = 1;

		GDB0 = sw[0] | { 1'b1, m_right,m_left,m_fire_a,1'b1,1'b1, 1'b1,1'b1};
		GDB1 = sw[1] | { 1'b1, m_right,m_left,m_fire_a,1'b1,m_start1, m_start2, m_coin1 };
		GDB2 = sw[2] | { 1'b0, m_right,m_left,m_fire_a,1'b0,1'b0, 1'b0, 1'b0 };
	end

	mod_spaceinvaders2: // invad2ct
	begin
		landscape     = 0;
		ccw           = 0;

		GDB0 = sw[0] | { 1'b1, 1'b0,1'b0,1'b0,1'b1,1'b1, 1'b1,1'b1};
		GDB1 = sw[1] | { 1'b1, m_left1,m_right1,m_fire1a,1'b1,m_start1, m_start2, m_coin1 };
		GDB2 = sw[2] | { 1'b0, m_right2,m_left2,m_fire2a,1'b0,1'b0, 1'b0, 1'b0 };
	end

	mod_shuffleboard:
	begin
		landscape     = 0;
		ccw           = 0;

		GDB1 = S;
		GDB2 = sw[0];
		GDB3 = SR;
		GDB4 = ~{ 4'd0, m_fire_a, m_start2, m_start1, m_coin1 };	  // IN0
		GDB5 = Sum_Y;  // Trackball
		GDB6 = Sum_X;  // Trackball

		Trigger_ShiftCount     = PortWr[1];
		Trigger_AudioDeviceP1  = PortWr[5];
		Trigger_ShiftData      = PortWr[2];
		Trigger_AudioDeviceP2  = PortWr[6];
		Trigger_WatchDogReset  = PortWr[4];
		software_flip          = 0;      
	end

	mod_vortex:
	begin
		//GDB0 -- all FF
		//
		landscape     = 0;
		ccw           = 1;
		// note because the CPU has the address line A9 (A1 for IO) inverted
		// we have to be careful in looking at mame mapping
		// Currently: GDB0-7 have A9 inverted, but PortWr doesn't
		// we should probably not invert A9 in GDB0-7? AJS TODO
		// IN0
		GDB0 = sw[0] | { 1'b0, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0};
		// IN1
		GDB1 = sw[1] | { 1'b1, m_right,m_left,m_fire_a,1'b0,m_start1, m_start2, ~m_coin1 };
		GDB2 = sw[2] | { 1'b0, m_right,m_left,m_fire_a,1'b0,1'b0, 1'b0, 1'b0 };
		// IN2 -- settings
		GDB3 = S;

		Trigger_ShiftCount     = PortWr[0];
		Trigger_AudioDeviceP1  = PortWr[1];
		Trigger_ShiftData      = PortWr[6];
		Trigger_AudioDeviceP2  = PortWr[7];
		Trigger_WatchDogReset  = PortWr[4];
		software_flip          = 0;      
	end

	mod_lagunaracer:
	begin
		landscape     = 0;
		ccw           = 0;
		GDB0 = sw[0] | { ~m_start1, ~m_coin1, 1'b1, fire_toggle, pedal[7:4]};
		GDB1 = steering_adj;
		GDB2 = sw[2] | { 1'b0, 1'b0, 1'b0,1'b0,1'b0,1'b0, 1'b0, 1'b0 };
		Trigger_ShiftCount     = PortWr[4];
		Trigger_AudioDeviceP1  = PortWr[2];
		Trigger_ShiftData      = PortWr[3];
		Trigger_AudioDeviceP2  = PortWr[5];
		Trigger_WatchDogReset  = PortWr[7];
		software_flip          = 0;
	end

	mod_280zap:
	begin
		landscape     = 1;
		ccw           = 0;
		GDB0 = sw[0] | { ~m_start1, ~m_coin1, 1'b1, fire_toggle, pedal[7:4]};
		GDB1 = steering_adj;
		GDB2 = sw[2] | { 1'b0, 1'b0, 1'b0,1'b0,1'b0,1'b0, 1'b0, 1'b0 };
		Trigger_ShiftCount     = PortWr[4];
		Trigger_AudioDeviceP1  = PortWr[2];
		Trigger_ShiftData      = PortWr[3];
		Trigger_AudioDeviceP2  = PortWr[5];
		Trigger_WatchDogReset  = PortWr[7];
		software_flip          = 0;
	end

	mod_blueshark:
	begin
		gun_game = 1;
		GDB0 = SR;
		GDB1 = blue_shark_x;
		GDB2 = sw[2] | { 1'b0, 1'b0,1'b0,1'b1,1'b1,1'b1,m_coin1, ~(m_fire_a | |mouse_flags[2:0])};
		Trigger_ShiftCount     = PortWr[1];
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = PortWr[2];
		Trigger_WatchDogReset  = PortWr[4];
		software_flip          = 0;
	end

	mod_boothill:
	begin 
		// IN0
		GDB0 = sw[0] | { ~m_fire2a,boothill_y_2,~m_right2,~m_left2,~m_down2,~m_up2};
		// IN1
		GDB1 = sw[1] | { ~m_fire1a, boothill_y,~m_right1,~m_left1,~m_down1,~m_up1};
		// IN2
		GDB2 = sw[2] | { ~m_start2, ~m_coin1,~m_start1,1'b0,1'b0,1'b0, 1'b0, 1'b0 };
		Trigger_ShiftCount     = PortWr[1]; // IS THIS WEIRD?
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = PortWr[2];
		Trigger_WatchDogReset  = PortWr[4];
		Trigger_Tone_Low       = PortWr[5];
		Trigger_Tone_High      = PortWr[6];
		Audio_Output           = SoundCtrl3[3];
		software_flip          = 0;
		GDB3 = ShiftReverse ? SR: S;
	end

	mod_lunarrescue:
	begin
		landscape         = 0;
		color_rom_enabled = 1;
		ccw               = 1;
		WDEnabled         = 1'b0;
		GDB0 <= sw[0] | { 1'b0, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0};
		GDB1 <= sw[1] | { 1'b1, m_right,m_left,m_fire_a,1'b0,m_start1, m_start2, ~m_coin1 };
		GDB2 <= sw[2] | { 1'b1, m_right,m_left,m_fire_a,1'b0,1'b0, 1'b0, 1'b0 };
		software_flip     = 0;
		Force_Red =  SoundCtrl3[2];
	end

	mod_ozmawars:
	begin
		landscape         = 0;
		ccw               = 1;
		color_rom_enabled = 1;
		// GDB0 <= sw[0] | ~{ 1'b0, m_right,m_left,m_fire_a,1'b0,1'b1, 1'b1,1'b1};
		GDB1 <= sw[1] | { 1'b1, m_right,m_left,m_fire_a,1'b0,m_start1, m_start2, ~m_coin1 };
		GDB2 <= sw[2] | { m_start1, m_coin1,m_start2,1'b0,1'b0,1'b0, 1'b0, 1'b0 };
		software_flip     = 0;      
	end

	mod_spacelaser:
	begin
		landscape         = 0;
		ccw               = 1;
		color_rom_enabled = 1;
        // GDB0 <= sw[0] | ~{ 1'b0, m_right,m_left,m_fire_a,1'b0,1'b1, 1'b1,1'b1};
		GDB1 = sw[1] | { 1'b1, m_right1,m_left1,m_fire1a,1'b1,m_start1, m_start2, m_coin1 };
		GDB2 = sw[2] | { 1'b1, m_right2,m_left2,m_fire2a,1'b0,1'b0, 1'b0, 1'b0 };
	end

	mod_spacewalk:
	begin
		WDEnabled = 1'b1;
		GDB0 = -Sum_X;//~(8'd127-joya[7:0]);
		GDB1 = sw[1] | { 1'b1,~m_coin1,~m_start1,~m_start2,1'b1,1'b1,1'b1,1'b1};
		GDB2 = sw[2];
		Trigger_ShiftCount     = PortWr[1];
		Trigger_AudioDeviceP1  = PortWr[7];
		Trigger_ShiftData      = PortWr[2];
		Trigger_AudioDeviceP2  = PortWr[3];
		Trigger_WatchDogReset  = PortWr[4];
		Audio_Output           = SoundCtrl5[2];
		Trigger_Tone_Low       = PortWr[5];
		Trigger_Tone_High      = PortWr[6];
		Overlay4               = 1;
		software_flip          = 0;      
	end

	mod_spaceinvaderscv:
	begin
		landscape = 0;
		ccw       = 1;
		color_rom_enabled = 1;
		//if (Trigger_AudioDeviceP2) software_flip = SoundCtrl5[5] & sw[3][0];
		GDB0 = sw[0] | { 1'b0, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0};
		GDB1 = sw[1] | { 1'b1, m_right,m_left,m_fire_a,1'b1,m_start1, m_start2, m_coin1 };
		GDB2 = sw[2] | { 1'b1, m_right,m_left,m_fire_a,1'b0,1'b0, 1'b0, 1'b0 };
		software_flip     = 0;      
	end

	mod_rollingcrash:
	begin
		landscape = 0;
		ccw       = 1;
		color_rom_enabled = 1;
		if (Trigger_AudioDeviceP2) software_flip = SoundCtrl5[5] & sw[3][0];
		GDB0 = sw[0] | { 1'b0, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0};
		GDB1 = sw[1] | { 1'b1, m_right,m_left,m_fire_a,1'b1,m_start1, m_start2, m_coin1 };
		GDB2 = sw[2] | { 1'b1, m_right,m_left,m_fire_a,1'b0,1'b0, 1'b0, 1'b0 };
	end

	mod_unknown1:
	begin
		GDB0 = 8'hFF;
		GDB1 = 8'hFF;
		GDB2 = 8'hFF;
	end
	mod_unknown2:
	begin
		GDB0 = 8'h00;
		GDB1 = 8'h00;
		GDB2 = 8'h00;
	end

	mod_spaceinvadersii:
	begin
		landscape = 0;
		ccw       = 1;
		color_rom_enabled = 1;
		GDB0 = sw[0] | { 1'b0, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0};
		//GDB0 = sw[0] | { 1'b0, 1'b0, 1'b0, m_right,m_left,m_fire_a,1'b1,1'b1, 1'b1,1'b1};
		GDB1 = sw[1] | { 1'b1, m_right,m_left,m_fire_a,1'b0,m_start1, m_start2, ~m_coin1 };
		GDB2 = sw[2] | { 1'b0, m_right,m_left,m_fire_a,1'b0,1'b0, 1'b0, 1'b0 };
		software_flip     = 0;      
	end

	mod_amazingmaze:
	begin
		WDEnabled = 1'b0;
		GDB0      = sw[0] | { m_up2, m_down2, m_right2, m_left2, m_up1, m_down1, m_right1, m_left1} ;
		GDB1      = sw[1] | { 1'b0, 1'b0,1'b0,1'b0,m_coin1, 1'b0, m_start2, m_start1};
		GDB2      = 8'b0;
		software_flip  = 0;
	end

	mod_attackforce:
	begin
		landscape = 1;
		WDEnabled = 1'b0;
		ccw = 1;
		GDB0 = sw[0] | { ~m_coin1, 1'b1,1'b1,1'b1,1'b1,~m_fire_a, ~m_left,~m_right};
		GDB1 = 8'b0;
		GDB2 = 8'b0;
		Trigger_ShiftCount     = PortWr[7];
		Trigger_AudioDeviceP1  = PortWr[4];
		Trigger_ShiftData      = PortWr[3];
		Trigger_AudioDeviceP2  = PortWr[6];
		Trigger_WatchDogReset  = PortWr[5];
		software_flip  = 0;
	end

	mod_ballbomb:
	begin
		landscape = 0;
		WDEnabled = 1'b0;
		ccw = 1;
		color_rom_enabled = 1;
		GDB0 = sw[0] | { 1'b1, m_right,m_left,m_fire_a,1'b0,1'b0, 1'b0, 1'b0 };
		GDB1 = sw[1] | { 1'b1, m_right,m_left,m_fire_a,1'b1,m_start1, m_start2, m_coin1 };
		GDB2 = sw[2] | { 1'b0, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0};
		Audio_Output = SoundCtrl3[5];
		if (Trigger_AudioDeviceP2) software_flip = SoundCtrl5[5] & sw[3][0];
		Trigger_Tone_High = PortWr[1]; // out 1 = music generator!
		Force_Red =  SoundCtrl3[2]; // Base hit - all red
		Background_Col     = {1'b0,1'b0,1'b1}; // Blue
		if (BBPixel) Background_Col = {1'b1,1'b1,1'b1}; // White clouds
	end

	mod_bowler:
	begin
		landscape = 0;
		software_flip = 0;
		// 0 - dips
		GDB0 = sw[0];
		// 1 - controls
		GDB1 = ~S;
		// 2, 3 trackball
		GDB2 = sw[0];
		GDB3 = SR;
		GDB4 <= ~{ 1'b0, 1'b0, 1'b0, 1'b0, m_fire_b, m_start1, m_fire_a, m_coin1 };
		GDB5 = -Sum_Y;
		GDB6 = -Sum_X;
		Trigger_ShiftCount     = PortWr[1];
		//Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = PortWr[2];
		//Trigger_AudioDeviceP2  = PortWr[6];
		Trigger_WatchDogReset  = PortWr[4];
		//<= PortWr[5]; // bowler_audio_1_w 
		//<= PortWr[6]; // bowler_audio_2_w
		//<= PortWr[7]; // bowler_lights_1_w
		//<= PortWr[8]; //
		//<= PortWr[9]; //
		//<= PortWr[A]; //
		//<= PortWr[E]; //
		//<= PortWr[F]; //
	end

	mod_checkmate:
	begin
		WDEnabled = 1'b0;
		// IN0
		GDB0 = sw[0] | { m_right2,m_left2,m_down2,m_up2,m_right1,m_left1,m_down1,m_up1};
		GDB1 = sw[1] | { m_right4,m_left4,m_down4,m_up4,m_right3,m_left3,m_down3,m_up3};
		GDB2 = sw[2]; // dips
		GDB3 = sw[3] | { m_coin1, 1'b0,1'b0,1'b0,m_start4,m_start3,m_start2,m_start1};
		//GDB3 = sw[3] | { m_coin1, 1'b0,1'b0,1'b0,1'b0,1'b0,m_start2,m_start1};
				//<= PortWr[3]; //  checkmat_io_w
		software_flip = 0;
	end

	mod_clowns:
	begin
		//GDB0 -- all FF
		landscape = 1;
		// IN0
		// 2 player is broken - they are multiplexed
		//GDB0 = SoundCtrl3[1] ? ~(8'd127-joya[7:0]) : ~(8'd127-joya2[7:0]);
		GDB0 = -Sum_X;
		GDB1 = { 1'b1,~m_coin1,~m_start1,~m_start2,1'b1,1'b1,1'b1,1'b1};
		GDB2 = sw[2] | { 1'b0, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0};
		GDB3 = S;

		Trigger_ShiftCount     = PortWr[1];
		Trigger_AudioDeviceP1  = PortWr[7];
		Trigger_ShiftData      = PortWr[2];
		Trigger_AudioDeviceP2  = PortWr[3];
		Trigger_WatchDogReset  = PortWr[4];
		Audio_Output           = SoundCtrl3[3];
		Trigger_Tone_Low       = PortWr[5];
		Trigger_Tone_High      = PortWr[6];
		software_flip          = 1'd0;
	end

	mod_cosmo:
	begin
		landscape = 0;
		ccw       = 0;
		color_rom_enabled = 1;
		GDB0 = sw[0] | { 1'b0, 1'b0,1'b0,1'b0,1'b0,1'b0, 1'b0,1'b0};
		GDB1 = sw[1] | { 1'b0, m_right,m_left,m_fire_a,1'b1,m_start1, m_start2, m_coin1 };
		GDB2 = sw[2] | { 1'b1, m_right,m_left,m_fire_a,1'b0,1'b0, 1'b0, 1'b0 };
		Trigger_ShiftCount     = 1'b0;
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = 1'b0;
		Trigger_AudioDeviceP2  = PortWr[5];
		Trigger_WatchDogReset  = PortWr[6];
		software_flip          = 1'd0;
	end

	mod_dogpatch:
	begin
		landscape = 1;
		ccw       = 0;
		color_rom_enabled = 1;
		GDB0 = sw[0] | { ~m_fire_b, dogpatch_y_2, 1'b1, ~m_start2, ~m_start1, ~m_coin1 };
		GDB1 = sw[1] | { ~m_fire_a, dogpatch_y, 1'b1, 1'b1, 1'b1 , 1'b1};
		GDB2 = sw[2];
		Trigger_ShiftCount     = PortWr[1];
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = PortWr[2];
		Trigger_AudioDeviceP2  = PortWr[7];
		Trigger_WatchDogReset  = PortWr[4];
		//<= PortWr[5]; // tone_generator_low_w
		//<= PortWr[6]; // tone_generator_hi_w

		// AJS -- will this work:
		Trigger_Tone_Low       = PortWr[5];
		Trigger_Tone_High      = PortWr[6];

		software_flip          = 0;
	end

	mod_doubleplay:
	begin
		landscape = 1;
		ccw       = 0;
		color_rom_enabled = 1;
		GDB0 = sw[0] | { ~m_start1, joya[7:2], ~m_fire_a};
		GDB1 = sw[1] | { ~m_start2, joya[7:2], ~m_fire_a};
		GDB2 = sw[2] | { ~m_coin1, 7'b0 };
		Trigger_ShiftCount     = PortWr[1];
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = PortWr[2];
		//Trigger_AudioDeviceP2  <= PortWr[7];
		Trigger_WatchDogReset  = PortWr[4];
		//<= PortWr[5]; // tone_generator_low_w
		//<= PortWr[6]; // tone_generator_hi_w
		// AJS -- will this work:
		Trigger_Tone_Low       = PortWr[5];
		Trigger_Tone_High      = PortWr[6];
		software_flip          = 0;
	end

	mod_guidedmissle:
	begin 
		// IN0
		GDB0 = sw[0] | {~m_fire2a,~m_start1,1'b1,1'b1,~m_right2,~m_left2,1'b1,1'b1};
		GDB1 = sw[1] | {~m_fire1a,~m_start2,1'b1,1'b1,~m_right1,~m_left1,~m_coin1,1'b1};
		// IN2
		GDB2 = sw[2];
		Trigger_ShiftCount     = PortWr[1]; // IS THIS WEIRD?
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = PortWr[2];
		Trigger_WatchDogReset  = PortWr[4];
		//<= PortWr[5]; // tone_generator_low_w
		//<= PortWr[6]; // tone_generator_hi_w
		Trigger_Tone_Low       = PortWr[5];
		Trigger_Tone_High      = PortWr[6];
		GDB3 = ShiftReverse ? SR: S;
		software_flip          <= 0;
	end

	mod_claybust:
	begin 
		gun_game = 1;
		// IN0
		GDB1 = sw[1] | { 1'b0,1'b0,1'b0,1'b0, ~m_start1, ~m_coin1, |claybust_gun_on, |claybust_gun_on};
		GDB2 =  claybust_gun_pos_lo;
		GDB6 =  claybust_gun_pos_hi;
		Trigger_ShiftCount     = PortWr[1];
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = PortWr[2];
		Trigger_WatchDogReset  = PortWr[4];
		software_flip          = 0;
	end

	mod_gunfight:
	begin
		WDEnabled = 1'b0;
		// IN0
		GDB0 = sw[0] | { m_fire1a,~gunfight_y, m_right1,m_left1,m_down1,m_up1};
		GDB1 = sw[1] | { m_fire2a,~gunfight_y_2,m_right2,m_left2,m_down2,m_up2};
		GDB2 = sw[2] | { m_start1,m_coin1, 6'b0};
		Trigger_ShiftCount     = PortWr[2];
		Trigger_AudioDeviceP1  = PortWr[1];
		Trigger_ShiftData      = PortWr[4];
		//Trigger_WatchDogReset  = PortWr[4];
		software_flip          = 0;
	end

	mod_indianbattle:
	begin
		landscape = 0;
		ccw       = 1;
		color_rom_enabled = 1;
		GDB0 = sw[0];
		GDB1 = sw[1] | { 1'b1,m_right1,m_left1,m_fire1a, 1'b0,  m_start1,m_start2,~m_coin1};
		GDB2 = sw[2];
		Trigger_ShiftCount     = PortWr[2];
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = PortWr[4];
		Trigger_AudioDeviceP2  = PortWr[5];
		Trigger_WatchDogReset  = PortWr[6];
		software_flip          = 0;      
	end

	mod_lupin:
	begin
		landscape = 0;
		ccw       = 1;
		color_rom_enabled = 1;
		GDB0 = sw[0] | { m_up2,m_left2,m_down2,m_right2,m_fire2a,1'b0,1'b0,1'b0};
		GDB1 = sw[1] | { m_up1,m_left1,m_down1,m_right1,m_fire1a,m_start1,m_start2,m_coin1};
		GDB2 = sw[2];
		Trigger_ShiftCount     = PortWr[2];
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = PortWr[4];
		Trigger_AudioDeviceP2  = PortWr[5];
		Trigger_WatchDogReset  = PortWr[6];
		software_flip          = 0;      
	end

	mod_lupin1:
	begin 
		landscape = 0;
		ccw       = 1;
		color_rom_enabled = 1;
		GDB0 = sw[0] | { m_up2,m_left2,m_down2,m_right2,m_fire2a,1'b0,1'b1,1'b1};
		GDB1 = sw[1] | { m_up1,m_left1,m_down1,m_right1,m_fire1a,m_start1,m_start2,m_coin1};
		GDB2 = sw[2];
		Trigger_ShiftCount     = PortWr[2];
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = PortWr[4];
		Trigger_AudioDeviceP2  = PortWr[5];
		Trigger_WatchDogReset  = PortWr[6];
		software_flip          = 0;      
	end
		  
	mod_m4:
	begin 
		landscape = 1;
		WDEnabled = 1'b0;
		// IN0
		GDB0 = sw[0] | { 1'b1, 1'b1,~m_fire2b,~m_fire2a,~m_down2,1'b1,~m_up2,1'b1};
		GDB1 = sw[1] | { 1'b1,~m_start2,~m_fire1b,~m_fire1a,~m_down1,~m_start1,~m_up1,~m_coin1};
		GDB2 = sw[2];
		Trigger_ShiftCount     = PortWr[1]; // IS THIS WEIRD?
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_ShiftData      = PortWr[2];
		Trigger_WatchDogReset  = PortWr[4];
		Trigger_AudioDeviceP2  = PortWr[5];
		GDB3 = ShiftReverse ? SR: S;
		software_flip          = 0;      
	end

	mod_phantom:
	begin
		landscape = 1;
		GDB0 = SR;
		GDB1 = sw[1] | { 1'b1,1'b1,~m_coin1,~m_fire1a,~m_right1,~m_left1,~m_down1,~m_up1};
		GDB2 = sw[2];
		Trigger_ShiftCount     = PortWr[1];
		Trigger_ShiftData      = PortWr[2];
		Trigger_WatchDogReset  = PortWr[4];
		Trigger_AudioDeviceP1  = PortWr[5];
		Trigger_AudioDeviceP2  = PortWr[6];
		software_flip          = 0;      
	end

	mod_polaris:
	begin
		landscape = 0;
		ccw       = 1;
		color_rom_enabled = 1;

		GDB0 = sw[0];

		if (software_flip) begin
			GDB1 = { m_up2,m_left2,m_down2,m_right2,m_fire2a,m_start1,m_start2,m_coin1};
		end
		else begin
			GDB1 = { m_up1,m_left1,m_down1,m_right1,m_fire1a,m_start1,m_start2,m_coin1};
		end;

		GDB2 = sw[2];

		Audio_Output           = SoundCtrl3[5];
		Trigger_ShiftCount     = PortWr[1];
		Trigger_Tone_High      = PortWr[2];
		Trigger_ShiftData      = PortWr[3];
		Trigger_AudioDeviceP1  = PortWr[4];
		Trigger_WatchDogReset  = PortWr[5];
		Trigger_AudioDeviceP2  = PortWr[6];

		software_flip = SoundCtrl5[5] & sw[3][0];

		// Background colour split mid screen
		if (VCount < 2) begin
			Background_Col     = {1'b0,1'b0,1'b0}; 			// Black
		end
		else begin
			if (HCount < 127) begin // was 128
				Background_Col     = {1'b0,1'b0,1'b1}; 	// Blue
			end
			else begin
				Background_Col     = {1'b0,1'b1,1'b1}; 	// Cyan
			end;
			if (PolarisPixel) Background_Col = {1'b1,1'b1,1'b1}; // White clouds
		end;
	end

	mod_desertgun:
	begin
		gun_game = 1;
		landscape = 1;
		GDB0 = SR;
		GDB1 = desert_gun_select ? desert_gun_x[7:0] : desert_gun_y[7:0];
		GDB2 = sw[2] | { ~(m_fire1a | |mouse_flags[2:0]),m_coin1, 2'b0, 2'b0, 2'b0};

		Trigger_ShiftCount     = PortWr[1];
		Trigger_ShiftData      = PortWr[2];
		Trigger_WatchDogReset  = PortWr[4];
		Trigger_AudioDeviceP1  = PortWr[3];
		//<= PortWr[5]; // tone_generator_low_w
		//<= PortWr[6]; // tone_generator_hi_w
		Trigger_AudioDeviceP2  = PortWr[7];
		Trigger_Tone_Low       = PortWr[5];
		Trigger_Tone_High      = PortWr[6];
		software_flip          = 0;      
	end

	mod_seawolf:
	begin
		gun_game  = 1;
		landscape = 1;
		WDEnabled = 1'b0;
		ccw       = 0;
		GDB0      = SR;
		// IN0
		GDB1 = sw[0] | { 2'b0, m_fire_a | |mouse_flags[2:0], seawolf_position};
		GDB2 = sw[1] | { 3'b0,1'b0 /*erase?*/, 2'b0,m_start1,m_coin1};
		Trigger_ShiftData      = PortWr[3];
		Trigger_ShiftCount     = PortWr[4];
		//<= PortWr[5];
		//<= PortWr[6];
		//<= PortWr[4];
		Trigger_AudioDeviceP1  = PortWr[5];
		Trigger_AudioDeviceP2  = 1'b0;
		software_flip          = 0;
	end

	mod_yosakdon:
	begin
		WDEnabled = 1'b0;
		landscape  = 0;
		ccw = 1;
		//GDB0 <= SR;
		// IN0
		GDB1 = sw[0] | { 1'b0, m_right,m_left,m_fire_a,1'b0,m_start1, m_start2, m_coin1 };
		// IN1
		GDB2 = sw[1] | { 1'b0, m_right,m_left,m_fire_a,1'b0,1'b0,1'b0,1'b0};
		Trigger_AudioDeviceP1  = PortWr[3];
		Trigger_AudioDeviceP2  = PortWr[5];
		software_flip          = 0;      
	end

	mod_spacechaser:
	begin
		landscape = 0;
		ccw       = 1;
		color_rom_enabled = 1;
		GDB0 = { sw[0][7:5],  m_fire2a,  m_right2,m_down2,m_left2,m_up2};
		GDB1 = { m_coin1,m_start1,m_start2,m_fire_a,m_right,m_down,m_left,m_up};
		GDB2 = sw[2];
		software_flip  = 0;    
		Background_Col = {1'b0,1'b0,1'b1}; // Blue		
	end

	mod_steelworker:
	begin
		WDEnabled = 1'b0;
		GDB0 = 0;
		GDB1 = sw[1] |{ ~m_fire1b, m_right,m_left,m_fire1a,1'b0,m_start1,m_start2, ~m_coin1};
		GDB2 = sw[2] |{ ~m_fire2b, m_right2, m_left2 , m_fire2a,1'b0,1'b0, 1'b0,1'b0} ;
		Trigger_ShiftCount     = PortWr[2];
		//Trigger_AudioDeviceP1  = PortWr[2];
		Trigger_ShiftData      = PortWr[4];
		//Trigger_AudioDeviceP2  = PortWr[5];
		//Trigger_WatchDogReset  = PortWr[7];
		software_flip          = 0;      
	end

	mod_spaceenc:
	begin
		WDEnabled = 1'b1;
		GDB0 = -Sum_X;//~(8'd127-joya[7:0]);
		GDB1 = sw[1] | { 1'b1,~m_coin1,~m_start1,~m_start2,1'b1,1'b1,1'b1,1'b1};
		GDB2 = sw[2];
		Trigger_ShiftCount     = PortWr[1];
		Trigger_AudioDeviceP1  = PortWr[7];
		Trigger_ShiftData      = PortWr[2];
		Trigger_AudioDeviceP2  = PortWr[3];
		Trigger_WatchDogReset  = PortWr[4];
		Audio_Output           = SoundCtrl5[2];
		Trigger_Tone_Low       = PortWr[5];
		Trigger_Tone_High      = PortWr[6];
		Overlay4               = 1;
		software_flip          = 0;      
	end

	default:
	begin
		landscape	=0;
		ccw			=1;

		GDB0 <= sw[0] | { 1'b1, m_right,m_left,m_fire_a,1'b1,1'b1, 1'b1,1'b1};
		GDB1 <= sw[1] | { 1'b1, m_right,m_left,m_fire_a,1'b1,m_start1, m_start2, m_coin1 };
		GDB2 <= sw[2] | { 1'b1, m_right,m_left,m_fire_a,1'b0,1'b0, 1'b1, 1'b1 };
	end

	endcase
end


wire [10:0] color_prom_addr;
wire  [7:0] color_prom_out;
wire [15:0] RAB;
wire [15:0] AD;
wire  [7:0] RDB;
wire  [7:0] RWD;
wire  [7:0] IB;
wire  [7:0] SoundCtrl3;
wire  [7:0] SoundCtrl5;
wire        Rst_n_s;
wire        RWE_n;
wire        Video;
wire        HSync;
wire        VSync;
wire        HBlank;
wire        VBlank;
wire        r,g,b;
wire        CPU_RW_n;

wire [11:0] HCount;
wire [11:0] VCount;

wire        Vortex_Col;

invaderst invaderst(
	.Rst_n(~(reset_sys)),
	.Clk(clk_sys),
	.ENA(),

	.GDB0(GDB0),
	.GDB1(GDB1),
	.GDB2(GDB2),
	.GDB3(GDB3),
	.GDB4(GDB4),
	.GDB5(GDB5),
	.GDB6(GDB6),

	.WD_Enabled(WDEnabled),

	.RDB(RDB),
	.IB(IB),
	.RWD(RWD),
	.RAB(RAB),
	.AD(AD),
	.SoundCtrl3(SoundCtrl3),
	.SoundCtrl5(SoundCtrl5),
	.Tone_Low(Tone_Low),
	.Tone_High(Tone_High),
	.Rst_n_s(Rst_n_s),
	.RWE_n(RWE_n),
	.Video(Video),
	.CPU_RW_n(CPU_RW_n),

	.color_prom_addr(color_prom_addr),
	.color_prom_out(color_prom_out),
	.ScreenFlip(DoScreenFlip),
	.Overlay_Align(Overlay4),

	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_VIDEO_A(fg),

	.HBLANK(HBlank),
	.VBLANK(VBlank),
	.HSync(HSync),
	.VSync(VSync),

	.HShift(),
	.VShift(),
		
	.Overlay(overlay),

	.OverlayTest(1'd0),

	.pause(pause_cpu),

	.Trigger_ShiftCount(Trigger_ShiftCount),
	.Trigger_ShiftData(Trigger_ShiftData),
	.Trigger_AudioDeviceP1(Trigger_AudioDeviceP1),
	.Trigger_AudioDeviceP2(Trigger_AudioDeviceP2),
	.Trigger_WatchDogReset(Trigger_WatchDogReset),
	.Trigger_Tone_Low(Trigger_Tone_Low),
	.Trigger_Tone_High(Trigger_Tone_High),

	.PortWr(PortWr),
	.S(S),
	.ShiftReverse(ShiftReverse),

	.mod_vortex(mod==mod_vortex),
	.overclock(mod_polaris && sw[3][1]),
	.Vortex_Col(Vortex_Col)
);
  
invaders_memory invaders_memory (
	.Clock(clk_sys),
	.RW_n(RWE_n),
	.CPU_RW_n(CPU_RW_n),
	.Addr(AD),
	.Ram_Addr(RAB),
	.Ram_out(RDB),
	.Ram_in(RWD),
	.Rom_out(IB),
	.color_prom_out(color_prom_out),
	.color_prom_addr(color_prom_addr),
	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr&ioctl_index==0),
	.Vortex_bit(Vortex_Col),
	.PlanePos(PlanePos),
	.mod_vortex(mod==mod_vortex),
	.mod_attackforce(mod==mod_attackforce),
	.mod_cosmo(mod==mod_cosmo),
	.mod_polaris(mod==mod_polaris),
	.mod_lupin(mod==mod_lupin),
	.mod_indianbattle(mod==mod_indianbattle),
	.mod_spacechaser(mod==mod_spacechaser),

	.hs_address(hs_address),
	.hs_data_in(hs_data_in),
	.hs_data_out(hs_data_out),
	.hs_write(hs_write_enable),
	.hs_access(hs_access_read|hs_access_write)
);

wire BBPixel;

bb_clouds bb_clouds
(
	.clk(clk_vid),
	.pixel_en(ce_pix),
	.v(VCount),
	.h(HCount),
	.flip(DoScreenFlip),
	.pixel(BBPixel)
);

// Cloud for Polaris

wire PolarisPixel;

polaris_cloud polaris_cloud
(
	.clk(clk_vid),
	.pixel_en(ce_pix),
	.v(VCount),
	.h(HCount),
	.flip(DoScreenFlip),
	.pixel(PolarisPixel)
);


/// AUDIO ///
wire [15:0] audio;

wire [7:0] inv_audio_data;
invaders_audio invaders_audio (
	.Clk(clk_sys),
	.S1(SoundCtrl3),
	.S2(SoundCtrl5),
	.Aud(inv_audio_data)
);

// 280z engine noise
wire [15:0] zap_audio_data;
zap_audio zap_audio (
	.Clk(clk_sys),
	.S1(SoundCtrl3),
	.S2(SoundCtrl5),
	.Aud(zap_audio_data)
);

// Music for Amazing Maze

reg [7:0] MazeTrigger;

MAZE_MUSIC MAZE_MUSIC
(
	.I_JOYSTICK({m_up1 || m_up2,m_down1 || m_down2,m_left1 || m_left2,m_right1 || m_right2}),
	.I_COIN(m_coin1),
	.O_TRIGGER(MazeTrigger),
	.CLK(clk_sys)
);

// Sound changes for Lupin 3

reg [7:0] LupinPort;
reg LastStep = 0;
reg LastBit;

always @(posedge clk_sys)
begin
	LastBit <= SoundCtrl3[0];
	// on falling bit, change step
	if(LastBit && ~SoundCtrl3[0]) LastStep <= ~LastStep;           
	// set fake output accordingly
	if (SoundCtrl3[0]) begin
		LupinPort <= {LastStep,~LastStep,SoundCtrl3[5:0]};
	end
	else begin
		LupinPort <= {2'd0,SoundCtrl3[5:0]};
	end;
end

// Tone Generator

reg [15:0] Tone_Out;

ToneGen ToneGen
(
	.Tone_enabled(Tone_Low[0]),
	.Tone_Low({Tone_Low[5:1],1'b0}),
	.Tone_High(Tone_High[5:0]),

	.Tone_out(Tone_Out),
	 
	.CLK_SYS(clk_sys),
	.reset(reset_sys)
);

// Balloon Bomber tune generator

reg [15:0] BB_Tone_Out;

BALLOON_MUSIC BALLOON_MUSIC
(
	.I_MUSIC_ON(Tone_High != 7'd127),
	.I_TONE({1'b1,Tone_High[6:0]}),
	.O_AUDIO(BB_Tone_Out),
	.CLK(clk_sys)
);

// Polaris tune generator (music or plane position)
reg [15:0] P_Tone_Out;
reg  [7:0] PlanePos;
wire [7:0] PolarTone = SoundCtrl5[1] ? PlanePos : Tone_High;

BALLOON_MUSIC POLARIS_MUSIC
(
	.I_MUSIC_ON(PolarTone != 8'd255),
	.I_TONE(PolarTone),
	.O_AUDIO(P_Tone_Out),
	.CLK(clk_sys)
);        

assign audio =  mod == mod_polaris ? P_Tone_Out : 
                mod == mod_ballbomb ? BB_Tone_Out :
               (mod == mod_280zap || mod == mod_lagunaracer) ? zap_audio_data :
               (mod == mod_spaceinvaders || mod == mod_spaceinvadersii || mod == mod_lunarrescue) ? {inv_audio_data,inv_audio_data} :
                Tone_Out;

//// VIDEO OUTPUT ////
reg Force_Red;
reg [2:0] Background_Col;

wire rr = (Force_Red ? r|g|b : r);
wire gg = (Force_Red ? 1'b0 : g);
wire bb = (Force_Red ? 1'b0 : b);

wire rrr = (gun_game & gun_target) | (fg ? rr : Background_Col[2]);
wire ggg = (gun_game & gun_target) | (fg ? gg : Background_Col[1]);
wire bbb = (gun_game & gun_target) | (fg ? bb : Background_Col[0]);

mist_dual_video #(.COLOR_DEPTH(1),.OUT_COLOR_DEPTH(VGA_BITS),.USE_BLANKS(1'b1),.BIG_OSD(BIG_OSD),.SD_HCNT_WIDTH(10),.VIDEO_CLEANER(1'b1)) mist_video(
	.clk_sys(clk_vid),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(rrr),
	.G(ggg),
	.B(bbb),
	.HBlank(HBlank),
	.VBlank(VBlank),
	.HSync(HSync),
	.VSync(VSync),
	.rotate({~ccw,rotate}),
	.rotate_screen(rotate_screen),
	.rotate_hfilter(rotate_filter),
	.rotate_vfilter(rotate_filter),
	.scandoubler_disable(scandoublerD),
	.scanlines(scanlines),
	.ce_divider(4'h7),
	.blend(blend),
	.ypbpr(ypbpr),
	.no_csync(no_csync),
`ifdef USE_HDMI
	.HDMI_R(HDMI_R),
	.HDMI_G(HDMI_G),
	.HDMI_B(HDMI_B),
	.HDMI_VS(HDMI_VS),
	.HDMI_HS(HDMI_HS),
	.HDMI_DE(HDMI_DE),
`endif
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),

	.clk_sdram(clk_vid),
	.sdram_init(~pll_locked),
	.SDRAM_A(SDRAM_A),
	.SDRAM_DQ(SDRAM_DQ),
	.SDRAM_DQML(SDRAM_DQML),
	.SDRAM_DQMH(SDRAM_DQMH),
	.SDRAM_nWE(SDRAM_nWE),
	.SDRAM_nCAS(SDRAM_nCAS),
	.SDRAM_nRAS(SDRAM_nRAS),
	.SDRAM_nCS(SDRAM_nCS),
	.SDRAM_BA(SDRAM_BA)
	);

assign SDRAM_CKE = 1;
assign SDRAM_CLK = clk_vid;

`ifdef USE_HDMI
i2c_master #(10_000_000) i2c_master (
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

/// AUDIO OUTPUT ///
dac #(16) dac (
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

`ifdef I2S_AUDIO
i2s i2s (
	.reset(1'b0),
	.clk(clk_vid),
	.clk_rate(32'd40_000_000),
	.sclk(I2S_BCK),
	.lrclk(I2S_LRCK),
	.sdata(I2S_DATA),
	.left_chan({~audio[15], audio[14:0]}),
	.right_chan({~audio[15], audio[14:0]})
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
	.clk_rate_i(32'd40_000_000),
	.spdif_o(SPDIF),
	.sample_i({2{{~audio[15], audio[14:0]}}})
);
`endif

/// CONTROLS /////
wire fire_toggle;
input_toggle fire(clk_sys, reset_sys, m_fire_a, fire_toggle);

// Virtual Gun pointer
wire [1:0] gun_mode = status[13:12];
wire [1:0] gun_cross_size = status[15:14];
wire       gun_target;
wire [7:0] gun_x, gun_y;
reg        gun_game = 0;

reg ce_pix;
always @(posedge clk_vid) begin
	reg [2:0] div;

	div <= div + 1'd1;
	ce_pix <= div == 0;
end

reg         mouse_strobe_level;
wire [24:0] ps2_mouse = { mouse_strobe_level, mouse_y[7:0], mouse_x[7:0], mouse_flags };

always @(posedge clk_sys) if (mouse_strobe) mouse_strobe_level <= ~mouse_strobe_level;

virtualgun virtualgun
(
	.CLK(clk_vid),

	.MOUSE(ps2_mouse),
	.MOUSE_XY(gun_mode[1]),
	.JOY_X(!gun_mode ? joya[7:0] : joya2[7:0]),
	.JOY_Y(!gun_mode ? joya[15:8] : joya2[15:8]),

	.HDE(~HBlank),
	.VDE(~VBlank),
	.CE_PIX(ce_pix),

	.SIZE(gun_cross_size),

	.H_COUNT(HCount),
	.V_COUNT(VCount),

	.TARGET(gun_target),
	.X_OUT(gun_x),
	.Y_OUT(gun_y)
);

/* controls for blue shark */
wire [7:0] bluerange = { 1'b0, gun_x[7:1]+8'd8 };
reg [7:0] blue_shark_x;

always @(posedge clk_sys) 
begin
   if (bluerange > 9'h082)
	   blue_shark_x=8'h82;
   else
	   blue_shark_x=bluerange[7:0];
end

/* controls for claybust */
wire [15:0] gun_x_16 = gun_x;
wire [15:0] gun_y_16 = gun_y + 8'h20;
wire [15:0] claybust_gun_pos = (((gun_x_16 >> 3) | (gun_y_16 << 5)) + 2'd2);
reg [7:0] claybust_gun_pos_lo;
reg [7:0] claybust_gun_pos_hi;
reg [19:0] claybust_gun_on;
reg claybust_old_fire;
wire claybust_fire = m_fire_a | |mouse_flags[2:0];
always @(posedge clk_sys) begin
	claybust_gun_pos_lo <= claybust_gun_pos[7:0];
	claybust_gun_pos_hi <= claybust_gun_pos[15:8];
	claybust_old_fire <= claybust_fire;
	if (~claybust_old_fire & claybust_fire) claybust_gun_on <= 20'hfffff; // arbitrary
	else if (claybust_gun_on) claybust_gun_on <= claybust_gun_on - 1'd1;
end

/* controls for desert gun */
reg [7:0] desert_gun_x;
reg [7:0] desert_gun_y;
reg desert_gun_select;

always @(posedge clk_sys) 
begin
	desert_gun_x <= (gun_x[7:0]>>1)+8'h10;
	desert_gun_y <= (gun_y[7:0]>>1)+8'h10;
	if (Trigger_AudioDeviceP2) desert_gun_select <= SoundCtrl5[3];
end

/* controls for dogpatch */
/* dogpatch has some weird non incremental thing going on*/
/*0x07, 0x06, 0x04, 0x05, 0x01, 0x00, 0x02*/
/* gunfight */
/*0x06, 0x02, 0x00, 0x04, 0x05, 0x01, 0x03*/
/* boothill */
/* 	0x00, 0x04, 0x06, 0x07, 0x03, 0x01, 0x05 */
reg [2:0] dogpatch_y_count= 0;
reg [2:0] dogpatch_y_2_count= 0;
reg [2:0] gunfight_y_count= 0;
reg [2:0] gunfight_y_count_2= 0;
wire [2:0] dogpatch_y;
wire [2:0] dogpatch_y_2;
wire [2:0] gunfight_y;
wire [2:0] gunfight_y_2;

wire [2:0] boothill_y;
wire [2:0] boothill_y_2;

reg vsync_r;
reg [5:0] dogpatch_timer= 0;
always @(posedge clk_sys) 
begin
    vsync_r <= VSync;
    if (vsync_r ==0 && VSync== 1) 
    begin
	if (dogpatch_timer == 8'd5) 
	begin
          if (m_up&& dogpatch_y_count< 7)
            dogpatch_y_count<= dogpatch_y_count+1'b1;
          else if (m_down&& dogpatch_y_count > 0)
            dogpatch_y_count<= dogpatch_y_count-1'b1;

          if (m_up2&& dogpatch_y_2_count< 7)
            dogpatch_y_2_count<= dogpatch_y_2_count+1'b1;
          else if (m_down2&& dogpatch_y_2_count > 0)
            dogpatch_y_2_count<= dogpatch_y_2_count-1'b1;

          if (m_fire1b&& gunfight_y_count< 7)
            gunfight_y_count<= gunfight_y_count+1'b1;
          else if (m_fire1c&& gunfight_y_count > 0)
            gunfight_y_count<= gunfight_y_count-1'b1;

          if (m_fire2b&& gunfight_y_count_2< 7)
            gunfight_y_count_2<= gunfight_y_count_2+1'b1;
          else if (m_fire2c&& gunfight_y_count_2 > 0)
            gunfight_y_count_2<= gunfight_y_count_2-1'b1;


          dogpatch_timer <= 0;
        end
	else 
	begin
          dogpatch_timer <= dogpatch_timer +1'b1;
	end
    case (dogpatch_y_count) 
		3'b000: dogpatch_y <= 3'h7;
		3'b001: dogpatch_y <= 3'h6;
		3'b010: dogpatch_y <= 3'h4;
		3'b011: dogpatch_y <= 3'h5;
		3'b100: dogpatch_y <= 3'h1;
		3'b101: dogpatch_y <= 3'h0;
		3'b110: dogpatch_y <= 3'h2;
		3'b111: dogpatch_y <= 3'h2; // ?
	endcase
    case (dogpatch_y_2_count) 
		3'b000: dogpatch_y_2 <= 3'h7;
		3'b001: dogpatch_y_2 <= 3'h6;
		3'b010: dogpatch_y_2 <= 3'h4;
		3'b011: dogpatch_y_2 <= 3'h5;
		3'b100: dogpatch_y_2 <= 3'h1;
		3'b101: dogpatch_y_2 <= 3'h0;
		3'b110: dogpatch_y_2 <= 3'h2;
		3'b111: dogpatch_y_2 <= 3'h2; // ?
	endcase
    case (gunfight_y_count) 
		3'b000: gunfight_y <= 3'h6;
		3'b001: gunfight_y <= 3'h2;
		3'b010: gunfight_y <= 3'h0;
		3'b011: gunfight_y <= 3'h4;
		3'b100: gunfight_y <= 3'h5;
		3'b101: gunfight_y <= 3'h1;
		3'b110: gunfight_y <= 3'h3;
		3'b111: gunfight_y <= 3'h3; //?
	endcase
   case (gunfight_y_count_2) 
		3'b000: gunfight_y_2 <= 3'h6;
		3'b001: gunfight_y_2 <= 3'h2;
		3'b010: gunfight_y_2 <= 3'h0;
		3'b011: gunfight_y_2 <= 3'h4;
		3'b100: gunfight_y_2 <= 3'h5;
		3'b101: gunfight_y_2 <= 3'h1;
		3'b110: gunfight_y_2 <= 3'h3;
		3'b111: gunfight_y_2 <= 3'h3; //?
	endcase
	
	case (gunfight_y_count)
		3'b000: boothill_y <= 3'h0;
		3'b001: boothill_y <= 3'h4;
		3'b010: boothill_y <= 3'h6;
		3'b011: boothill_y <= 3'h7;
		3'b100: boothill_y <= 3'h3;
		3'b101: boothill_y <= 3'h1;
		3'b110: boothill_y <= 3'h5;
		3'b111: boothill_y <= 3'h5; //?
	endcase
	case (gunfight_y_count_2)
		3'b000: boothill_y_2 <= 3'h0;
		3'b001: boothill_y_2 <= 3'h4;
		3'b010: boothill_y_2 <= 3'h6;
		3'b011: boothill_y_2 <= 3'h7;
		3'b100: boothill_y_2 <= 3'h3;
		3'b101: boothill_y_2 <= 3'h1;
		3'b110: boothill_y_2 <= 3'h5;
		3'b111: boothill_y_2 <= 3'h5; //?
	endcase

	
    end
end


/* controls for seawolf */
wire [7:0] seawolf_shifted_x = gun_x[7:0]>>3;
reg [4:0] seawolf_position;

always @(posedge clk_sys) 
begin
   case (seawolf_shifted_x[4:0]) 
      5'b00000: seawolf_position <= ~5'h1e; // clamp
      5'b00001: seawolf_position <= ~5'h1e;
      5'b00010: seawolf_position <= ~5'h1c;
      5'b00011: seawolf_position <= ~5'h1d;
      5'b00100: seawolf_position <= ~5'h19;
      5'b00101: seawolf_position <= ~5'h18;
      5'b00110: seawolf_position <= ~5'h1a;
      5'b00111: seawolf_position <= ~5'h1b;
      5'b01000: seawolf_position <= ~5'h13;
      5'b01001: seawolf_position <= ~5'h12;
      5'b01010: seawolf_position <= ~5'h10;
      5'b01011: seawolf_position <= ~5'h11;
      5'b01100: seawolf_position <= ~5'h15;
      5'b01101: seawolf_position <= ~5'h14;
      5'b01110: seawolf_position <= ~5'h16;
      5'b01111: seawolf_position <= ~5'h17;
      5'b10000: seawolf_position <= ~5'h07;
      5'b10001: seawolf_position <= ~5'h06;
      5'b10010: seawolf_position <= ~5'h04;
      5'b10011: seawolf_position <= ~5'h05;
      5'b10100: seawolf_position <= ~5'h01;
      5'b10101: seawolf_position <= ~5'h00;
      5'b10110: seawolf_position <= ~5'h02;
      5'b10111: seawolf_position <= ~5'h03;
      5'b11000: seawolf_position <= ~5'h0b;
      5'b11001: seawolf_position <= ~5'h0a;
      5'b11010: seawolf_position <= ~5'h08;
      5'b11011: seawolf_position <= ~5'h09;
      5'b11100: seawolf_position <= ~5'h0d;
      5'b11101: seawolf_position <= ~5'h0c;
      5'b11110: seawolf_position <= ~5'h0e;
      5'b11111: seawolf_position <= ~5'h0e; // clamp
   endcase
end

/* Mouse - Trackball for Shuffleboard */

reg signed [7:0] Sum_X;
reg signed [7:0] Sum_Y;

always @(posedge clk_sys)
begin
	/* sum up delta changes from mouse */
	if(mouse_strobe) begin
		// Mouse X
		Sum_X <= Sum_X - mouse_x[8:1];  // 1/2 Scale
		// Mouse Y
		Sum_Y <= Sum_Y - mouse_y[8:1]; // 1/2 Scale
	end
end

/* Laguna Racer / 280ZZAP */
wire signed [7:0] steering;
wire signed [7:0] steering_adj = -(steering + 8'h10); // range adjust and negate: 30-b0 -> 40-c0
wire [7:0] pedal;

spy_hunter_control controls (
	.clock_40(clk_sys),
	.reset(reset_sys),
	.vsync(VSync),
	.gas_plus(m_up),
	.gas_minus(m_down),
	.steering_plus(m_right),
	.steering_minus(m_left),
	.steering(steering),
	.gas(pedal)
);

wire m_fire_a  = m_fire1a | m_fire2a;
wire m_fire_b  = m_fire1b | m_fire2b;
wire m_left    = m_left1  | m_left2;
wire m_right   = m_right1 | m_right2;
wire m_up      = m_up1    | m_up2;
wire m_down    = m_down1  | m_down2;

wire m_up1, m_down1, m_left1, m_right1, m_fire1a, m_fire1b, m_fire1c, m_fire1d, m_fire1e, m_fire1f;
wire m_up2, m_down2, m_left2, m_right2, m_fire2a, m_fire2b, m_fire2c, m_fire2d, m_fire2e, m_fire2f;
wire m_up3, m_down3, m_left3, m_right3, m_fire3a, m_fire3b, m_fire3c, m_fire3d, m_fire3e, m_fire3f;
wire m_up4, m_down4, m_left4, m_right4, m_fire4a, m_fire4b, m_fire4c, m_fire4d, m_fire4e, m_fire4f;
wire m_tilt, m_coin1, m_coin2, m_coin3, m_coin4, m_start1, m_start2, m_start3, m_start4;

arcade_inputs #(.START1(10), .START2(12), .COIN1(11)) inputs (
	.clk         ( clk_sys     ),
	.key_strobe  ( key_strobe  ),
	.key_pressed ( key_pressed ),
	.key_code    ( key_code    ),
	.joystick_0  ( joystick_0  ),
	.joystick_1  ( joystick_1  ),
	.rotate      ( rotate      ),
	.orientation ( {~ccw,~landscape ^ |rotate_screen} ),
	.joyswap     ( 1'b0        ),
	.oneplayer   ( 1'b0        ),
	.controls    ( {m_tilt, m_coin4, m_coin3, m_coin2, m_coin1, m_start4, m_start3, m_start2, m_start1} ),
	.player1     ( {m_fire1f, m_fire1e, m_fire1d, m_fire1c, m_fire1b, m_fire1a, m_up1, m_down1, m_left1, m_right1} ),
	.player2     ( {m_fire2f, m_fire2e, m_fire2d, m_fire2c, m_fire2b, m_fire2a, m_up2, m_down2, m_left2, m_right2} ),
	.player3     ( {m_fire3f, m_fire3e, m_fire3d, m_fire3c, m_fire3b, m_fire3a, m_up3, m_down3, m_left3, m_right3} ),
	.player4     ( {m_fire4f, m_fire4e, m_fire4d, m_fire4c, m_fire4b, m_fire4a, m_up4, m_down4, m_left4, m_right4} )
);

endmodule
