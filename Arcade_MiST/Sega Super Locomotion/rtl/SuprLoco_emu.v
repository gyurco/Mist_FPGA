module SuprLoco_emu (
    input   wire            i_EMU_MCLK,
    input   wire            i_EMU_INITRST,
    input   wire            i_EMU_SOFTRST,

    //video syncs
    output  wire            o_HSYNC_n,
    output  wire            o_VSYNC_n,
    output  wire            o_CSYNC_n,
    output  wire            o_HBLANK_n,
    output  wire            o_VBLANK_n,

    output  wire            o_VIDEO_CEN, //video clock enable
    output  wire            o_VIDEO_DEN, //video data enable

    output  wire    [2:0]   o_VIDEO_R,
    output  wire    [2:0]   o_VIDEO_G,
    output  wire    [2:0]   o_VIDEO_B,

    //sound
    output  wire signed     [15:0]  o_SOUND,

    //user inputs
    input   wire    [15:0]  i_JOYSTICK0,
    input   wire    [15:0]  i_JOYSTICK1,

    //mister ioctl
    input   wire    [15:0]  ioctl_index,
    input   wire            ioctl_download,
    input   wire    [26:0]  ioctl_addr,
    input   wire    [7:0]   ioctl_data,
    input   wire            ioctl_wr, 
    output  wire            ioctl_wait,

    output  wire            debug
);


///////////////////////////////////////////////////////////
//////  INPUT MAPPER
////

/*
    MiSTer joystick(SNES)
    bit   
    0   right
    1   left
    2   down
    3   up
    4   attack(A)
    5   jump(B)
    6   test(START)
    7   service(SELECT)
    8   coin(R)
    9   start(L)
*/

/*
    SYS_BTN
        76543210
          ||||||
          |||||^-- coin 1
          ||||^--- coin 2
          |||^---- service
          ||^----- test
          |^------ start 1
          ^------- start 2
        
    P1_BTN
        76543210
          ||||||
          |||||^-- right
          ||||^--- left
          |||^---- up
          ||^----- down
          |^------ btn 1
          ^------- btn 2
    
    P2_BTN(only for the cocktail mode)
        76543210
          ||||||
          |||||^-- right
          ||||^--- left
          |||^---- up
          ||^----- down
          |^------ btn 1
          ^------- btn 2
*/

wire    [7:0]   SYS_BTN, P1_BTN, P2_BTN;

//System control
assign          SYS_BTN[0]  = ~i_JOYSTICK0[8];
assign          SYS_BTN[1]  = ~i_JOYSTICK1[8];
assign          SYS_BTN[2]  = ~i_JOYSTICK0[6];
assign          SYS_BTN[3]  = ~i_JOYSTICK0[7];
assign          SYS_BTN[4]  = ~i_JOYSTICK0[9];
assign          SYS_BTN[5]  = ~i_JOYSTICK1[9];
assign          SYS_BTN[6]  = 1'b1;
assign          SYS_BTN[7]  = 1'b1;

//Player 1 control
assign          P1_BTN[0]   = ~i_JOYSTICK0[0];
assign          P1_BTN[1]   = ~i_JOYSTICK0[1];
assign          P1_BTN[2]   = ~i_JOYSTICK0[3];
assign          P1_BTN[3]   = ~i_JOYSTICK0[2];
assign          P1_BTN[4]   = ~i_JOYSTICK0[4]; //btn 1
assign          P1_BTN[5]   = ~i_JOYSTICK0[5]; //btn 2
assign          P1_BTN[6]   = 1'b1;
assign          P1_BTN[7]   = 1'b1;

//Player 2 control
assign          P2_BTN[0]   = ~i_JOYSTICK1[0];
assign          P2_BTN[1]   = ~i_JOYSTICK1[1];
assign          P2_BTN[2]   = ~i_JOYSTICK1[3];
assign          P2_BTN[3]   = ~i_JOYSTICK1[2];
assign          P2_BTN[4]   = ~i_JOYSTICK1[4]; //btn 1
assign          P2_BTN[5]   = ~i_JOYSTICK1[5]; //btn 2
assign          P2_BTN[6]   = 1'b1;
assign          P2_BTN[7]   = 1'b1;



///////////////////////////////////////////////////////////
//////  ROM DISTRUBUTOR
////

//start addr    length        comp num     mame rom     parts num     location     description
//0x0000_0000   0x0000_4000   IC37         epr-5226     27C128        BRAM         program rom 0(encrypted)
//0x0000_4000   0x0000_4000   IC15         epr-5227     27C128        BRAM         program rom 1(encrypted)
//0x0000_8000   0x0000_4000   IC28         epr-5228     27C128        BRAM         game data rom

//0x0000_C000   0x0000_4000   IC55         epr-5229     27C128        BRAM         sprite data 0
//0x0001_0000   0x0000_2000   IC56         epr-5230     27C64         BRAM         sprite data 1

//0x0001_2000   0x0000_2000   IC61         epr-5223     27C64         BRAM         tilemap data 0
//0x0001_4000   0x0000_2000   IC62         epr-5224     27C64         BRAM         tilemap data 1
//0x0001_6000   0x0000_2000   IC63         epr-5225     27C64         BRAM         tilemap data 2

//0x0001_8000   0x0000_2000   IC64         epr-5222     27C64         BRAM         sound program

//0x0001_A000   0x0000_0400   IC89         pr-5219      TBP24S41      BRAM         3bpp->4bpp conversion LUT
//0x0001_A400   0x0000_0200   IC100        pr-5220      TBP28S46      BRAM         palette rom
//0x0001_A600   0x0000_0020   IC7          pr-5221      TBP18S030     BRAM         tilemap sequencer

//0x0001_A620          <-----------------ROM END----------------->

//Note 1: TBP24S41  = 82S137
//        TBP28S46  = 82S141
//        TBP18S030 = 82S123


//
//  DIPSW BANK
//

reg     [7:0]   DIPSW1 = 8'h40;
reg     [7:0]   DIPSW2 = 8'hF0;

/*        
    DIPSW1
        76543210
        ||||||||
        ||||||||     NEGATIVE LOGIC!! SW-ON is ZERO
        |||||^^^---- coin A           / 000=1C1P 001=1C2P 010=1C3P 011=1C6P
        |||||                         / 100=2C1P 101=3C1P 110=4C1P 111=5C1P
        ||^^^------- coin B           / 000=1C1P 001=1C2P 010=1C3P 011=1C6P
        ||                            / 100=2C1P 101=3C1P 110=4C1P 111=5C1P
        ^^---------- trains           / 00=2 01=3 10=4 11=5

    DIPSW2
        76543210
        ||||| ||
        ||||| ^^---- bonus points     / 00=20000 01=30000 10=40000 11=50000
        ||||^------- free play        / 0=enable 1=disable
        |||^-------- difficulty       / 0=hard 1=normal
        ||^--------- invincibility    / 0=no accident 1=accident occurs
        |^---------- name entry       / 0=disable 1=enable
        ^----------- cabinet type     / 0=upright 1=table
*/


//
//  BRAM DOWNLOADER INTERFACE
//

assign          ioctl_wait = 1'b0;

//download complete
reg             rom_download_done = 1'b0;

//enables
reg             prog_bram_en = 1'b0;
reg             prog_dipsw_en = 1'b0;

//bram control
reg     [7:0]   prog_bram_din_buf;
reg     [16:0]  prog_bram_addr;
reg             prog_bram_wr;
reg     [11:0]  prog_bram_csreg;

always @(posedge i_EMU_MCLK) begin
    if((i_EMU_INITRST | rom_download_done) == 1'b1) begin
        //enables
        prog_bram_en <= 1'b0;
        prog_dipsw_en <= 1'b0;

        //bram
        prog_bram_din_buf <= 8'hFF;
        prog_bram_addr <= 17'h1FFFF;
        prog_bram_wr <= 1'b0;
        prog_bram_csreg <= 12'b0000_0000_0000;
    end
    else begin
        //  ROM DATA UPLOAD
        if(ioctl_index == 16'd0) begin //ROM DATA
            prog_bram_en <= 1'b1;
            prog_dipsw_en <= 1'b0;

            if(ioctl_wr == 1'b1) begin
                prog_bram_din_buf <= ioctl_data;
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
        else if(ioctl_index == 16'd254) begin //DIP SWITCH
            if(ioctl_addr[24:1] == 24'h00_0000) begin
                prog_bram_en <= 1'b0;
                prog_dipsw_en <= 1'b1;

                if(ioctl_wr == 1'b1) begin
                    if(ioctl_addr[0] == 1'b0) begin
                        DIPSW1 <= ioctl_data;
                    end
                    else if(ioctl_addr[0] == 1'b1) begin
                        DIPSW2 <= ioctl_data;
                    end
                end
            end
            else begin
                prog_bram_en <= 1'b0;
                prog_dipsw_en <= 1'b0;
            end
        end
    end
end



//
//  DOWNLOAD COMPLETE
//

reg     [1:0]   dwnld_done_negdet;
reg     [1:0]   dwnld_done_flags;
wire            bram_done_set = dwnld_done_negdet[1] & ~prog_bram_en;
wire            dipsw_done_set = dwnld_done_negdet[0] & ~prog_dipsw_en;
always @(posedge i_EMU_MCLK) begin
    if(i_EMU_INITRST == 1'b1) begin
        dwnld_done_negdet <= 2'b00;
        dwnld_done_flags <= 2'b00;
        rom_download_done <= 1'b0;
    end
    else begin
        dwnld_done_negdet[1] <= prog_bram_en;
        dwnld_done_negdet[0] <= prog_dipsw_en;

        if(bram_done_set) dwnld_done_flags[1] <= 1'b1;
        if(dipsw_done_set) dwnld_done_flags[0] <= 1'b1;

        rom_download_done <= &{dwnld_done_flags};
    end
end



///////////////////////////////////////////////////////////
//////  GAME BOARD
////

wire            core_reset = i_EMU_INITRST | ~rom_download_done;
wire            cpu_soft_reset = i_EMU_INITRST | i_EMU_SOFTRST;

assign  debug = rom_download_done;

SuprLoco_top u_gameboard_main (
    .i_EMU_CLK40M               (i_EMU_MCLK                 ),
    .i_EMU_INITRST_n            (~core_reset                ),
    .i_EMU_SOFTRST_n            (~cpu_soft_reset            ),

    .o_HSYNC_n                  (o_HSYNC_n                  ),
    .o_VSYNC_n                  (o_VSYNC_n                  ),
    .o_CSYNC_n                  (o_CSYNC_n                  ),
    .o_HBLANK_n                 (o_HBLANK_n                 ),
    .o_VBLANK_n                 (o_VBLANK_n                 ),

    .o_VIDEO_CEN                (o_VIDEO_CEN                ),
    .o_VIDEO_DEN                (o_VIDEO_DEN                ),
    .o_VIDEO_R                  (o_VIDEO_R                  ),
    .o_VIDEO_G                  (o_VIDEO_G                  ),
    .o_VIDEO_B                  (o_VIDEO_B                  ),

    .o_SOUND                    (o_SOUND                    ),

    .i_P1_BTN                   (P1_BTN                     ),
    .i_P2_BTN                   (P2_BTN                     ),
    .i_SYS_BTN                  (SYS_BTN                    ),
    .i_DIPSW1                   (DIPSW1                     ),
    .i_DIPSW2                   (DIPSW2                     ),

    .i_EMU_BRAM_ADDR            (prog_bram_addr             ),
    .i_EMU_BRAM_DATA            (prog_bram_din_buf          ),
    .i_EMU_BRAM_WR              (prog_bram_wr               ),
    
    .i_EMU_BRAM_PGMROM0_CS      (prog_bram_csreg[0]         ),
    .i_EMU_BRAM_PGMROM1_CS      (prog_bram_csreg[1]         ),
    .i_EMU_BRAM_DATAROM_CS      (prog_bram_csreg[2]         ),
    .i_EMU_BRAM_OBJROM0_CS      (prog_bram_csreg[3]         ),
    .i_EMU_BRAM_OBJROM1_CS      (prog_bram_csreg[4]         ),
    .i_EMU_BRAM_TMROM0_CS       (prog_bram_csreg[5]         ),
    .i_EMU_BRAM_TMROM1_CS       (prog_bram_csreg[6]         ),
    .i_EMU_BRAM_TMROM2_CS       (prog_bram_csreg[7]         ),
    .i_EMU_BRAM_SNDPRG_CS       (prog_bram_csreg[8]         ),
    .i_EMU_BRAM_CONVLUT_CS      (prog_bram_csreg[9]         ),
    .i_EMU_BRAM_PALROM_CS       (prog_bram_csreg[10]        ),
    .i_EMU_BRAM_TMSEQROM_CS     (prog_bram_csreg[11]        )
);


endmodule