module SuprLoco_top (
    input   wire            i_EMU_CLK40M,
    input   wire            i_EMU_INITRST_n,
    input   wire            i_EMU_SOFTRST_n,

    //video syncs
    output  reg             o_HSYNC_n,
    output  wire            o_VSYNC_n,
    output  wire            o_CSYNC_n,
    output  reg             o_HBLANK_n,
    output  reg             o_VBLANK_n,

    output  wire            o_VIDEO_CEN, //video clock enable
    output  reg             o_VIDEO_DEN, //video data enable

    output  wire    [2:0]   o_VIDEO_R,
    output  wire    [2:0]   o_VIDEO_G,
    output  wire    [2:0]   o_VIDEO_B,

    //sound
    output  reg signed      [15:0]  o_SOUND,

    //user inputs
    input   wire    [7:0]   i_P1_BTN,
    input   wire    [7:0]   i_P2_BTN,
    input   wire    [7:0]   i_SYS_BTN,
    input   wire    [7:0]   i_DIPSW1,
    input   wire    [7:0]   i_DIPSW2,

	 // external ROMs
    output  wire   [15:0]   cpu1_addr,
    output  wire            cpu1_rd,
    input   wire    [7:0]   cpu1_din,

    output  wire   [12:0]   cpu2_addr,
    output  wire            cpu2_rd,
    input   wire    [7:0]   cpu2_din,

    //BRAM programming
    input   wire    [16:0]  i_EMU_BRAM_ADDR,
    input   wire    [7:0]   i_EMU_BRAM_DATA,
    input   wire            i_EMU_BRAM_WR,
    
    input   wire            i_EMU_BRAM_PGMROM0_CS, //27128(AW14)
    input   wire            i_EMU_BRAM_PGMROM1_CS, //27128
    input   wire            i_EMU_BRAM_DATAROM_CS, //27128
    input   wire            i_EMU_BRAM_OBJROM0_CS, //27128
    input   wire            i_EMU_BRAM_OBJROM1_CS, //2764
    input   wire            i_EMU_BRAM_TMROM0_CS,  //2764
    input   wire            i_EMU_BRAM_TMROM1_CS,  //2764
    input   wire            i_EMU_BRAM_TMROM2_CS,  //2764
    input   wire            i_EMU_BRAM_SNDPRG_CS,  //2764
    input   wire            i_EMU_BRAM_CONVLUT_CS, //82S137(AW10)
    input   wire            i_EMU_BRAM_PALROM_CS,  //82S141(AW9)
    input   wire            i_EMU_BRAM_TMSEQROM_CS //82S123(AW5)
);

parameter PATH = "D:/cores/ikacore_SuprLoco/rtl/roms/";

///////////////////////////////////////////////////////////
//////  Clocking information and prescaler
////

/*
    74LS321 acts really weird - see the LS321 sigrok waveform

    CLK40M      ¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|
    prescaler   -0-|-1-|-2-|-3-|-4-|-5-|-6-|-7-|-0-|-1-|-2-|-3-|-4-|-5-|-6-|-7-|-0-|-1-|-2-|

    CLK20Mp     ¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|___|¯¯¯|
    
    CLK10Mp     ¯¯¯|___________|¯¯¯|___________|¯¯¯|___________|¯¯¯|___________|¯¯¯|________
    CLK10Mn     ___|¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯¯¯¯|___|¯¯¯¯¯¯¯¯

    CLK5Mp      ___|¯¯¯¯¯¯¯¯¯¯¯|___________________|¯¯¯¯¯¯¯¯¯¯¯|___________________|¯¯¯¯¯¯¯¯
    CLK5Mn      ¯¯¯|___________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|________

    CLK20M -> use posedge
    CLK10Mp -> use negedge(315-5012 internally inverts the clock)
    CLK5Mp -> use negedge
*/

reg     [2:0]   prescaler;
wire            initrst_n = i_EMU_INITRST_n;
wire            softrst_n = i_EMU_SOFTRST_n;
wire            clk40m = i_EMU_CLK40M;
reg             clk20m_pcen, clk20m_ncen, __ref_clk20m;
reg             clk10m_pcen, clk10m_ncen, __ref_clk10m;
reg             clk5m_pcen, clk5m_ncen, __ref_clk5m;

always @(posedge clk40m) begin
    if(!initrst_n) prescaler <= 3'd0;
    else prescaler <= prescaler == 3'd7 ? 3'd0 : prescaler + 3'd1;

    //clock enables
    clk20m_pcen <= ~prescaler[0];
    clk20m_ncen <= prescaler[0];

    clk10m_pcen <= prescaler == 3'd2 || prescaler == 3'd6;
    clk10m_ncen <= prescaler == 3'd3 || prescaler == 3'd7;

    clk5m_pcen <= prescaler == 3'd7;
    clk5m_ncen <= prescaler == 3'd2;

    //generate reference clocks
    if(clk20m_pcen) __ref_clk20m <= 1'b1;
    else if(clk20m_ncen) __ref_clk20m <= 1'b0;

    if(clk10m_pcen) __ref_clk10m <= 1'b1;
    else if(clk10m_ncen) __ref_clk10m <= 1'b0;

    if(clk5m_pcen) __ref_clk5m <= 1'b1;
    else if(clk5m_ncen) __ref_clk5m <= 1'b0;
end



///////////////////////////////////////////////////////////
//////  Main CPU
////

//main CPU prescaler
wire            mcpu_m1_n;
reg     [2:0]   mcpu_prescaler;
wire            mcpu_pcen = (mcpu_prescaler == 3'b011) & clk20m_pcen;
wire            mcpu_ncen = (mcpu_prescaler == 3'b101) & clk20m_pcen;
always @(posedge clk40m) begin
    if(!initrst_n) mcpu_prescaler <= 3'b111;
    else begin if(clk20m_pcen) begin
        mcpu_prescaler <= (mcpu_prescaler == 3'b111) ? {2'b01, mcpu_m1_n} : mcpu_prescaler + 3'd1;
    end end
end

//buses
wire    [15:0]  mcpu_addr;
wire    [7:0]   mcpu_wrbus;
reg     [7:0]   mcpu_rdbus;
wire            mcpu_rd_n, mcpu_wr_n;

//wait until tilemap data writing is done
wire            mcpu_mreq_n;
reg             mcpu_wait_n;

//misc
wire            mcpu_rfsh;
wire            mcpu_int_n;

SuprLoco_CPU u_mcpu (
    .i_CLK                      (clk40m                     ),
    .i_RST_n                    (softrst_n                  ),
    
    .i_PCEN                     (mcpu_pcen                  ),
    .i_NCEN                     (mcpu_ncen                  ),

    .i_WAIT_n                   (mcpu_wait_n                ),
    .i_INT_n                    (mcpu_int_n                 ),
    .i_NMI_n                    (1'b1                       ),

    .o_RD_n                     (mcpu_rd_n                  ),
    .o_WR_n                     (mcpu_wr_n                  ),
    .o_IORQ_n                   (                           ),
    .o_MREQ_n                   (mcpu_mreq_n                ),
    .o_M1_n                     (mcpu_m1_n                  ),
    .o_ADDR                     (mcpu_addr                  ),
    .o_DO                       (mcpu_wrbus                 ),
    .i_DI                       (mcpu_rdbus                 ),

    .i_BUSRQ_n                  (1'b1                       ),
    .o_BUSAK_n                  (                           ),

    .o_RFSH_n                   (mcpu_rfsh                  ),
    .o_HALT_n                   (                           )
);

//address decoder... no enum in Verilog syntax?? not SV
localparam  PGMROM0 = 0;
localparam  PGMROM1 = 1;
localparam  DATAROM = 2;
localparam  OBJRAM  = 3;
localparam  TMRAM   = 4;
localparam  MAINRAM = 5;
localparam  IO_SYS  = 6;
localparam  IO_P1   = 7;
localparam  IO_P2   = 8;
localparam  IO_DIP  = 9;
localparam  IO_PPI  = 10;
localparam  INVALID = 11;

reg     [3:0]   active_device_id;
reg             ram_en;

always @(*) begin
    ram_en = 1'b0;
    active_device_id = INVALID;

    if(mcpu_rfsh) begin
        case(mcpu_addr[15:14])
            2'b00: active_device_id = PGMROM0;
            2'b01: active_device_id = PGMROM1;
            2'b10: active_device_id = DATAROM;
            2'b11: ram_en = 1'b1;
        endcase
    end

    if(ram_en) begin
        case(mcpu_addr[13:11])
            3'b000: active_device_id = OBJRAM;
            3'b001: active_device_id = IO_SYS;
            3'b010: active_device_id = IO_P1;
            3'b011: active_device_id = IO_P2;
            3'b100: active_device_id = IO_DIP;
            3'b101: active_device_id = IO_PPI;
            3'b110: active_device_id = TMRAM;
            3'b111: active_device_id = MAINRAM;
        endcase
    end
end



///////////////////////////////////////////////////////////
//////  Main CPU ROM/RAM devices
////

wire    [7:0]   pgmrom0_do, pgmrom1_do, datarom_do, mainram_do;

assign cpu1_rd = active_device_id == PGMROM0 || active_device_id == PGMROM1 || active_device_id == DATAROM;
assign cpu1_addr = mcpu_addr[15:0];
assign pgmrom0_do = cpu1_din;
assign pgmrom1_do = cpu1_din;
assign datarom_do = cpu1_din;
/*
//SuprLoco_PROM #(.AW(14), .DW(8), .simhexfile({PATH, "epr-5226.txt"})) u_pgmrom0 (
SuprLoco_PROM #(.AW(14), .DW(8), .simhexfile()) u_pgmrom0 (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[13:0]      ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA            ),
    .i_PROG_CS                  (i_EMU_BRAM_PGMROM0_CS      ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     (mcpu_addr[13:0]            ),
    .o_DOUT                     (pgmrom0_do                 ),
    .i_RD                       (active_device_id == PGMROM0)
);

//SuprLoco_PROM #(.AW(14), .DW(8), .simhexfile({PATH, "epr-5227.txt"})) u_pgmrom1 (
SuprLoco_PROM #(.AW(14), .DW(8), .simhexfile()) u_pgmrom1 (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[13:0]      ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA            ),
    .i_PROG_CS                  (i_EMU_BRAM_PGMROM1_CS      ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     (mcpu_addr[13:0]            ),
    .o_DOUT                     (pgmrom1_do                 ),
    .i_RD                       (active_device_id == PGMROM1)
);

//SuprLoco_PROM #(.AW(14), .DW(8), .simhexfile({PATH, "epr-5228.txt"})) u_datarom (
SuprLoco_PROM #(.AW(14), .DW(8), .simhexfile()) u_datarom (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[13:0]      ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA            ),
    .i_PROG_CS                  (i_EMU_BRAM_DATAROM_CS      ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     (mcpu_addr[13:0]            ),
    .o_DOUT                     (datarom_do                 ),
    .i_RD                       (active_device_id == DATAROM)
);
*/
SuprLoco_SRAM #(.AW(11), .DW(8), .simhexfile()) u_mainram (
    .i_MCLK                     (clk40m                     ),

    .i_ADDR                     (mcpu_addr[10:0]            ),
    .i_DIN                      (mcpu_wrbus                 ),
    .o_DOUT                     (mainram_do                 ),
    .i_RD                       ((active_device_id == MAINRAM)/* && ~mcpu_rd_n*/),
    .i_WR                       ((active_device_id == MAINRAM) && ~mcpu_wr_n)
);



///////////////////////////////////////////////////////////
//////  Video timing generator
////

wire            flip;
wire    [7:0]   hcntr_preload_val = flip ? 8'd63 : 8'd192;
wire    [7:0]   vcntr_preload_val = flip ? 8'd223 : 8'd0;
wire            hcntr_ld_n, vcntr_ld_n;
reg     [7:0]   hcntr, vcntr;
wire            vclk_pcen;
always @(posedge clk40m) begin
    if(!initrst_n) begin
        hcntr <= 8'd0;
        vcntr <= 8'd0;
    end
    else begin if(clk5m_ncen) begin
        if(!hcntr_ld_n) hcntr <= hcntr_preload_val;
        else hcntr <= flip ? hcntr + 8'd255 : hcntr + 8'd1;

        if(vclk_pcen) begin
            if(!vcntr_ld_n) vcntr <= vcntr_preload_val;
            else vcntr <= flip ? vcntr + 8'd255 : vcntr + 8'd1;
        end
    end end 
end

wire            dmaend, vblank, vsync_n;
wire            vclk, dmaon_n;
assign  vclk_pcen = vclk == 1'b0 && (flip ? hcntr == 8'd0 : hcntr == 8'd255) && clk5m_ncen;
assign  o_VSYNC_n = vsync_n;
SuprLoco_PAL16R4_PA5017 u_pa5017 (
    .i_MCLK                     (clk40m                     ),
    .i_RST_n                    (initrst_n                  ),
    .i_CEN                      (clk5m_ncen                 ),

    .i_HCNTR                    (hcntr                      ),
    .i_FLIP_n                   (~flip                      ),
    .i_VBLANK                   (vblank                     ),
    .i_VSYNC_n                  (vsync_n                    ),
    .i_DMAEND                   (dmaend                     ),

    .o_HCNTR_LD_n               (hcntr_ld_n                 ),
    .o_VCLK                     (vclk                       ),
    .o_DMAON_n                  (dmaon_n                    ),
    .o_CSYNC_n                  (o_CSYNC_n                  )
);

wire            blank;
SuprLoco_PAL16R4_PA5016 u_pa5016 (
    .i_MCLK                     (clk40m                     ),
    .i_RST_n                    (initrst_n                  ),
    .i_CEN                      (vclk_pcen                  ),

    .i_VCNTR                    (vcntr                      ),
    .i_FLIP_n                   (~flip                      ),

    .o_VCNTR_LD_n               (vcntr_ld_n                 ),
    .o_BLANK_n                  (                           ),
    .o_VSYNC_n                  (vsync_n                    ),
    .o_VBLANK                   (vblank                     ),
    .o_VBLANK_PNCEN_n           (                           ),
    .o_BLANK                    (blank                      ),
    .o_IRQ_n                    (mcpu_int_n                 )
);

//external hsync generator(the PAL doesn't make it explicitly)
always @(posedge clk40m) if(clk5m_ncen) begin
    if(flip) begin
        if(vclk) begin
            if(hcntr == 8'd51) o_HSYNC_n <= 1'b0;
            else if(hcntr == 27) o_HSYNC_n <= 1'b1;
        end
    end
    else begin
        if(vclk) begin
            if(hcntr == 8'd204) o_HSYNC_n <= 1'b0;
            else if(hcntr == 228) o_HSYNC_n <= 1'b1;
        end
    end
end

reg             vclk_z, blank_z;
always @(posedge clk40m) if(clk5m_ncen) begin
    vclk_z <= vclk;
    blank_z <= blank;
    if (hcntr == 8'hf9) o_HBLANK_n <= 0; else if (hcntr == 8'h09) o_HBLANK_n <= 1;
    //o_HBLANK_n = ~vclk_z;
    o_VBLANK_n = ~blank_z;
end



///////////////////////////////////////////////////////////
//////  Tilemap
////

//tilemap sequencer control bits
wire            tmram_wrtime_n; //tilemap write strobe for CPU access
wire            mcpu_wait_clr_n;
wire            htile_addr_lsb;
wire            codelatch_lo_tick, codelatch_hi_tick;
wire            dlylatch_tick;
wire            scrlatch_en_n;
wire    [1:0]   tmram_addrsel;
wire    [1:0]   tmsr_modesel;

//tick positive edge enables
wire            dlylatch_tick_pcen;
wire            codelatch_lo_tick_pcen;
wire            codelatch_hi_tick_pcen;

//maincpu wait(asynchronous)
reg             mreq_n_z;
wire            mreg_nedet = mreq_n_z & ~mcpu_mreq_n;
always @(posedge clk40m) begin
    mreq_n_z <= mcpu_mreq_n;

    if(!mcpu_wait_clr_n) mcpu_wait_n <= 1'b1;
    else begin
        if(mreg_nedet) mcpu_wait_n <= ~(active_device_id == TMRAM);
    end
end

//tilemap/scroll ram
wire    [7:0]   tmram_do;
reg     [10:0]  tmram_addr;
wire            tmram_wr = (active_device_id == TMRAM) & ~mcpu_wr_n & ~tmram_wrtime_n;
//SuprLoco_SRAM #(.AW(11), .DW(8), .simhexfile({PATH, "tilemap.txt"})) u_tmram (
SuprLoco_SRAM #(.AW(11), .DW(8), .simhexfile()) u_tmram (
    .i_MCLK                     (clk40m                     ),

    .i_ADDR                     (tmram_addr                 ),
    .i_DIN                      (mcpu_wrbus                 ),
    .o_DOUT                     (tmram_do                   ),
    .i_RD                       (1'b1                       ),
    .i_WR                       (tmram_wr                   )
);

//attribute latches
reg     [7:0]   scrlatch; //74LS377
reg     [7:0]   codelatch_lo, codelatch_hi; //74LS273
always @(posedge clk40m) begin
    if(!initrst_n) scrlatch <= 8'h00;
    else begin if(clk5m_ncen) begin
        if(codelatch_lo_tick_pcen & ~scrlatch_en_n) scrlatch <= tmram_do;
        if(codelatch_lo_tick_pcen) codelatch_lo <= tmram_do;
        if(codelatch_hi_tick_pcen) codelatch_hi <= tmram_do;
    end end
end

//scroll value generator
wire    [7:0]   scrval = hcntr + scrlatch;

//tmram address selector
always @(*) begin
    case(tmram_addrsel)
        2'b00: tmram_addr = mcpu_addr[10:0];
        2'b01: tmram_addr = mcpu_addr[10:0];
        2'b10: tmram_addr = {vcntr[7:3], scrval[7:3], htile_addr_lsb}; //htile index
        2'b11: tmram_addr = {6'b111111, vcntr[7:3]}; //scroll register address
    endcase
end

//tilemap sequencer 
wire        [4:0]   tmseqrom_addr = {~flip, tmram_addrsel[0], scrval[2:0]};
wire        [7:0]   tmseqrom_data;
//SuprLoco_PROM #(.AW(5), .DW(8), .simhexfile({PATH, "pr-5221.txt"})) u_seqrom (
SuprLoco_PROM #(.AW(5), .DW(8), .simhexfile()) u_seqrom (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[4:0]       ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA            ),
    .i_PROG_CS                  (i_EMU_BRAM_TMSEQROM_CS     ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     (tmseqrom_addr              ),
    .o_DOUT                     (tmseqrom_data              ),
    .i_RD                       (1'b1                       )
);

//LS273
reg     [7:0]   tmseqrom_273_device;
always @(posedge clk40m) begin
    if(!initrst_n) tmseqrom_273_device <= 8'h00;
    else begin if(clk5m_ncen) begin
        tmseqrom_273_device[0] <= tmseqrom_data[0];
        tmseqrom_273_device[1] <= tmseqrom_data[1];
        tmseqrom_273_device[6] <= tmseqrom_data[2];
        tmseqrom_273_device[7] <= tmseqrom_data[3];
        tmseqrom_273_device[5] <= tmseqrom_data[4];
        tmseqrom_273_device[4] <= tmseqrom_data[5];

        tmseqrom_273_device[2] <= tmseqrom_273_device[1];
        tmseqrom_273_device[3] <= tmseqrom_273_device[2];
    end end
end

//reassign the bits
assign  htile_addr_lsb = tmseqrom_273_device[0];
assign  codelatch_lo_tick = tmseqrom_273_device[1];
assign  codelatch_hi_tick = tmseqrom_273_device[3];
assign  dlylatch_tick = tmseqrom_273_device[4];
assign  tmram_addrsel[1] = tmseqrom_273_device[5];
assign  mcpu_wait_clr_n = tmseqrom_273_device[6];
assign  tmram_wrtime_n = tmseqrom_273_device[7];
assign  tmsr_modesel = tmseqrom_data[7:6];

//tick positive edge enables
assign  dlylatch_tick_pcen     = tmseqrom_data[5] & ~dlylatch_tick; //5MHz cen
assign  codelatch_lo_tick_pcen = tmseqrom_data[1] & ~codelatch_lo_tick;
assign  codelatch_hi_tick_pcen = tmseqrom_273_device[2] & ~codelatch_hi_tick;

//external LS109 device
wire    [1:0]   tmseqrom_109_device_rst_n;
reg     [1:0]   tmseqrom_109_device_reg;
wire    [1:0]   tmseqrom_109_device_q = tmseqrom_109_device_reg & tmseqrom_109_device_rst_n;

assign  tmram_addrsel[0] = tmseqrom_109_device_q[0];
assign  scrlatch_en_n = ~tmseqrom_109_device_q[0];

assign  tmseqrom_109_device_rst_n[0] = ~tmseqrom_109_device_q[1];
assign  tmseqrom_109_device_rst_n[1] = vclk;

always @(posedge clk40m) 
    if(!initrst_n) tmseqrom_109_device_reg <= 2'b00;
    else begin if(clk5m_ncen) begin
        if(!tmseqrom_109_device_rst_n[0]) tmseqrom_109_device_reg[0] <= 1'b0;
        else begin if(dlylatch_tick_pcen) begin
            //J=vclk, /K=GND
            if(vclk) tmseqrom_109_device_reg[0] <= ~tmseqrom_109_device_reg[0];
            else     tmseqrom_109_device_reg[0] <= 1'b0;
        end end

        if(!tmseqrom_109_device_rst_n[1]) tmseqrom_109_device_reg[1] <= 1'b0;
        else begin if(dlylatch_tick_pcen) begin
            //J=tmram_addrsel[0], /K=Vcc
            if(tmram_addrsel[0]) tmseqrom_109_device_reg[1] <= 1'b1;
        end end
    end
end

//tilemap attributes
wire    [10:0]  tilecode = {codelatch_hi[2:0], codelatch_lo};
wire    [1:0]   palcode = codelatch_hi[4:3];
wire            force_obj_top_n = codelatch_hi[5];

//tilemap roms
wire    [7:0]   tilerom0_do, tilerom1_do, tilerom2_do;
//SuprLoco_PROM #(.AW(13), .DW(8), .simhexfile({PATH, "epr-5223.txt"})) u_tilerom0 (
SuprLoco_PROM #(.AW(13), .DW(8), .simhexfile()) u_tilerom0 (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[12:0]      ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA            ),
    .i_PROG_CS                  (i_EMU_BRAM_TMROM0_CS       ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     ({tilecode[9:0], vcntr[2:0]}),
    .o_DOUT                     (tilerom0_do                ),
    .i_RD                       (1'b1                       )
);
//SuprLoco_PROM #(.AW(13), .DW(8), .simhexfile({PATH, "epr-5224.txt"})) u_tilerom1 (
SuprLoco_PROM #(.AW(13), .DW(8), .simhexfile()) u_tilerom1 (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[12:0]      ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA            ),
    .i_PROG_CS                  (i_EMU_BRAM_TMROM1_CS       ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     ({tilecode[9:0], vcntr[2:0]}),
    .o_DOUT                     (tilerom1_do                ),
    .i_RD                       (1'b1                       )
);
//SuprLoco_PROM #(.AW(13), .DW(8), .simhexfile({PATH, "epr-5225.txt"})) u_tilerom2 (
SuprLoco_PROM #(.AW(13), .DW(8), .simhexfile()) u_tilerom2 (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[12:0]      ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA            ),
    .i_PROG_CS                  (i_EMU_BRAM_TMROM2_CS       ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     ({tilecode[9:0], vcntr[2:0]}),
    .o_DOUT                     (tilerom2_do                ),
    .i_RD                       (1'b1                       )
);

//LS299 for pixel shifting
reg     [7:0]   tilerom_299_device_a, tilerom_299_device_b, tilerom_299_device_c;
always @(posedge clk40m) if(clk5m_ncen) begin
    case(tmsr_modesel)
        2'b00: begin 
            tilerom_299_device_a <= tilerom_299_device_a;
            tilerom_299_device_b <= tilerom_299_device_b;
            tilerom_299_device_c <= tilerom_299_device_c;
        end
        2'b01: begin 
            tilerom_299_device_a <= tilerom_299_device_a << 1;
            tilerom_299_device_b <= tilerom_299_device_b << 1;
            tilerom_299_device_c <= tilerom_299_device_c << 1;
        end
        2'b10: begin 
            tilerom_299_device_a <= tilerom_299_device_a >> 1;
            tilerom_299_device_b <= tilerom_299_device_b >> 1;
            tilerom_299_device_c <= tilerom_299_device_c >> 1;
        end
        2'b11: begin 
            tilerom_299_device_a <= tilerom0_do;
            tilerom_299_device_b <= tilerom1_do;
            tilerom_299_device_c <= tilerom2_do;
        end
    endcase
end

//LS157 for MSB/LSB selecting
wire    [2:0]   tmpx_3bpp = flip ? {tilerom_299_device_c[0], tilerom_299_device_b[0], tilerom_299_device_a[0]} :
                                   {tilerom_299_device_c[7], tilerom_299_device_b[7], tilerom_299_device_a[7]};

//palette latch(Z)
reg     [7:0]   tilecode_z;
reg     [1:0]   palcode_z;
reg             force_obj_top_n_z;
always @(posedge clk40m) if(clk5m_ncen) begin
    if(dlylatch_tick_pcen) begin
        tilecode_z <= tilecode[10:3];
        palcode_z <= palcode;
        force_obj_top_n_z <= force_obj_top_n;
    end
end

//3bpp -> 4bpp converting LUT
wire    [3:0]   tmpx_4bpp;
//SuprLoco_PROM #(.AW(10), .DW(4), .simhexfile({PATH, "pr-5219.txt"})) u_bppconvlut (
SuprLoco_PROM #(.AW(10), .DW(4), .simhexfile()) u_bppconvlut (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[9:0]       ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA[3:0]       ),
    .i_PROG_CS                  (i_EMU_BRAM_CONVLUT_CS      ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     ({tilecode_z[6:0], tmpx_3bpp}),
    .o_DOUT                     (tmpx_4bpp                  ),
    .i_RD                       (1'b1                       )
);





///////////////////////////////////////////////////////////
//////  Sprite engine
////

/*
    SPRITE RAM INFORMATION

    WORD3
    {BYTE7, BYTE6}: SPRITE TILE INDEX
    
    WORD2
    {BYTE5, BYTE4}: INDEX OFFSET(can be negative, should be added to the index value)

    WORD0
    BYTE0: Y TOP(starting scanline)
    BYTE1: Y BOTTOM(ending scanline)
    
    WORD1
    {BYTE3[0], BYTE2}: X POS
*/

`ifdef SUPRLOCO_SIMULATION
reg     [7:0]   objram_buf[0:2047];
reg     [7:0]   objram_buf_even[0:1023];
reg     [7:0]   objram_buf_odd[0:1023];
integer         i;
initial begin
    $readmemh({PATH, "sprite.txt"}, objram_buf);
    for(i=0; i<2048; i=i+1) begin
        if(i&1) objram_buf_odd[i>>1] = objram_buf[i];
        else    objram_buf_even[i>>1] = objram_buf[i];
    end
    $writememh({PATH, "sprite_even.txt"}, objram_buf_even);
    $writememh({PATH, "sprite_odd.txt"}, objram_buf_odd);
end
`endif

//instantiate the 315-5012 module
wire            objram_cs_n, objramlo_wr_n, objramhi_wr_n, bufhi_en_n, buflo_en_n;
wire    [9:0]   objram_addr;
wire            objend_n, ptend, lohp_n, cwen, vcul_n, ven_n, deltax_n, alulo_n, ontrf;
Sega_315_5012 u_315_5012_main (
    .i_MCLK                     (clk40m                     ),
    .i_CLK5MNCEN                (clk5m_ncen                 ),
    .i_CLK10MPCEN               (clk10m_pcen                ),

    .o_DMAEND                   (dmaend                     ),
    .i_DMAON_n                  (dmaon_n                    ),
    .i_ONELINE_n                (vcntr_ld_n                 ),

    .i_AD                       (mcpu_addr[10:0]            ),
    .i_OBJ_n                    (~(active_device_id == OBJRAM)),
    .i_RD_n                     (mcpu_rd_n                  ),
    .i_WR_n                     (mcpu_wr_n                  ),

    .o_BUFENH_n                 (bufhi_en_n                 ),
    .o_BUFENL_n                 (buflo_en_n                 ),

    .i_OBJEND_n                 (objend_n                   ),
    .i_PTEND                    (ptend                      ),

    .o_LOHP_n                   (lohp_n                     ),
    .o_CWEN                     (cwen                       ),
    .o_VCUL_n                   (vcul_n                     ),
    .i_VEN_n                    (ven_n                      ),
    .o_DELTAX_n                 (deltax_n                   ),
    .o_ALULO_n                  (alulo_n                    ),
    .o_ONTRF                    (ontrf                      ),

    .o_RCS_n                    (objram_cs_n                ),
    .o_RAMWRH_n                 (objramhi_wr_n              ),
    .o_RAMWRL_n                 (objramlo_wr_n              ),
    .o_RA                       (objram_addr                )
);

reg     [15:0]  obj_attr_bus;
wire    [15:0]  ro_do;
wire            ro_do_oe;
wire            swap;
Sega_315_5011 u_315_5011_main (
    .i_MCLK                     (clk40m                     ),
    .i_CLK5MNCEN                (clk5m_ncen                 ),

    .i_V                        (vcntr                      ),
    .i_RO_DI                    (obj_attr_bus               ),
    .o_RO_DO                    (ro_do                      ),
    .o_RO_DO_OE                 (ro_do_oe                   ),

    .i_CWEN                     (cwen                       ),
    .i_VCUL_n                   (vcul_n                     ),
    .i_DELTAX_n                 (deltax_n                   ),
    .i_ALULO_n                  (alulo_n                    ),
    .i_ONTRF                    (ontrf                      ),

    .o_VEN_n                    (ven_n                      ),
    .o_SWAP                     (swap                       )
);

//declare object attribute RAM(MBM2148 1k*4 SRAM x 4)
wire    [15:0]  objram_do;
SuprLoco_SRAM #(.AW(10), .DW(8), .simhexfile()) u_objramhi (
    .i_MCLK                     (clk40m                     ),

    .i_ADDR                     (objram_addr                ),
    .i_DIN                      (obj_attr_bus[15:8]         ),
    .o_DOUT                     (objram_do[15:8]             ),
    .i_RD                       (1'b1/*~objram_cs_n*/               ),
    .i_WR                       (~(objram_cs_n | objramhi_wr_n))
);

SuprLoco_SRAM #(.AW(10), .DW(8), .simhexfile()) u_objramlo (
    .i_MCLK                     (clk40m                     ),

    .i_ADDR                     (objram_addr                ),
    .i_DIN                      (obj_attr_bus[7:0]          ),
    .o_DOUT                     (objram_do[7:0]              ),
    .i_RD                       (1'b1/*~objram_cs_n*/               ),
    .i_WR                       (~(objram_cs_n | objramlo_wr_n))
);

//object attribute bus: there are two sources
always @(*) begin
    if(ro_do_oe) obj_attr_bus = ro_do;
    else if(~(bufhi_en_n & buflo_en_n)) obj_attr_bus = {mcpu_wrbus, mcpu_wrbus};
    else if(~objram_cs_n) obj_attr_bus = objram_do;
    else obj_attr_bus = 16'h0000;
end

//sprite data ROM
wire    [7:0]   objrom0_do, objrom1_do;

//intel D27128
//SuprLoco_PROM #(.AW(14), .DW(8), .simhexfile({PATH, "epr-5229.txt"})) u_objrom0 (
SuprLoco_PROM #(.AW(14), .DW(8), .simhexfile()) u_objrom0 (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[13:0]      ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA            ),
    .i_PROG_CS                  (i_EMU_BRAM_OBJROM0_CS      ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     (obj_attr_bus[13:0]         ),
    .o_DOUT                     (objrom0_do                 ),
    .i_RD                       (1'b1                       )
);

//Fujitsu MBM2764
//SuprLoco_PROM #(.AW(13), .DW(8), .simhexfile({PATH, "epr-5230.txt"})) u_objrom1 (
SuprLoco_PROM #(.AW(13), .DW(8), .simhexfile()) u_objrom1 (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[12:0]      ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA            ),
    .i_PROG_CS                  (i_EMU_BRAM_OBJROM1_CS      ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     (obj_attr_bus[12:0]         ),
    .o_DOUT                     (objrom1_do                 ),
    .i_RD                       (1'b1                       )
);

//sprite data output latch
reg     [7:0]   objdata_reg;
wire    [7:0]   objdata = objdata_reg & {8{ontrf}};
always @(posedge clk40m) begin
    if(!initrst_n) objdata_reg <= 8'h00;
    else begin if(clk5m_ncen) begin
        if(!ontrf) objdata_reg <= 8'h00;
        else begin
            if(cwen) objdata_reg <= obj_attr_bus[14] ? objrom1_do : objrom0_do;
        end
    end end 
end

//select pixel nibble
wire    [3:0]   objdata_nibble = swap ? objdata[7:4] : objdata[3:0];
reg     [3:0]   objdata_nibble_z;
always @(posedge clk40m) if(clk5m_ncen) objdata_nibble_z <= objdata_nibble;

//object X pos counter
reg             obj_xposcntr_cnt;
always @(posedge clk40m) if(clk5m_ncen) obj_xposcntr_cnt <= ontrf;

reg     [7:0]   obj_xposcntr;
wire            obj_xposcntr_cout = (obj_xposcntr == 8'd255) && obj_xposcntr_cnt;
always @(posedge clk40m) begin
    if(!initrst_n) obj_xposcntr <= 8'd0;
    else begin if(clk5m_ncen) begin
        if(!lohp_n) obj_xposcntr <= obj_attr_bus[7:0];
        else begin
            if(obj_xposcntr_cnt) obj_xposcntr <= obj_xposcntr + 8'd1;
        end
    end end
end

//sprite engine control signal
assign  objend_n = ~&{obj_attr_bus[15:12]};
assign  ptend = &{objdata_nibble} | obj_xposcntr_cout; //de morgan



///////////////////////////////////////////////////////////
//////  Sprite line buffer
////

//object pixel transparent flag
reg             obj_transparent;
always @(posedge clk40m) if(clk5m_ncen) obj_transparent <= objdata_nibble == 4'h0 || objdata_nibble == 4'hF;

//line select
wire            obj_read_evenbuf = ~vcntr[0];
wire            obj_read_oddbuf = vcntr[0];

/*
    LINE BUFFER RW TIMING DESCRIPTION(ORIGINAL PCB)

    WHEN WRITING SPRITES
    CLK5Mp      ___|¯¯¯¯¯¯¯¯¯¯¯|___________________|¯¯¯¯¯¯¯¯¯¯¯|___________________|¯¯¯¯¯¯¯¯
    RAM /CS     ¯¯¯|___________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|________
    RAM /WR     ¯¯¯|___________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|________
                   <-----------> <---- RAM WRITE WINDOW

    WEHN READING SPRITES
    CLK5Mp      ___|¯¯¯¯¯¯¯¯¯¯¯|___________________|¯¯¯¯¯¯¯¯¯¯¯|___________________|¯¯¯¯¯¯¯¯
    RAM /CS     ____________________________________________________________________________
    RAM /WR     ¯¯¯|___________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|___________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|________
                   <----------->                      <---- RAM WRITE WINDOW(initialize with 0xF)
                               <------------------->  <---- RAM READING WINDOW             
                                                   ^  <---- RAM OUTPUT DATA LATCHING TIMING
*/

//EVEN sprite line buffer(left)
wire    [8:0]   obj_evenbuf_addr = obj_read_evenbuf ? {vclk, hcntr} : {obj_transparent, obj_xposcntr};
wire    [3:0]   obj_evenbuf_di = obj_read_evenbuf ? 4'hF : objdata_nibble_z;
wire    [3:0]   obj_evenbuf_do;
SuprLoco_SRAM #(.AW(9), .DW(4), .simhexfile()) u_obj_evenbuf (
    .i_MCLK                     (clk40m                     ),

    .i_ADDR                     (obj_evenbuf_addr           ),
    .i_DIN                      (obj_evenbuf_di             ),
    .o_DOUT                     (obj_evenbuf_do             ),
    .i_RD                       (1'b1                       ),
    .i_WR                       (clk5m_ncen                 )
);

//ODD sprite line buffer(right)
wire    [8:0]   obj_oddbuf_addr = obj_read_oddbuf ? {vclk, hcntr} : {obj_transparent, obj_xposcntr};
wire    [3:0]   obj_oddbuf_di = obj_read_oddbuf ? 4'hF : objdata_nibble_z;
wire    [3:0]   obj_oddbuf_do;
SuprLoco_SRAM #(.AW(9), .DW(4), .simhexfile()) u_obj_oddbuf (
    .i_MCLK                     (clk40m                     ),

    .i_ADDR                     (obj_oddbuf_addr            ),
    .i_DIN                      (obj_oddbuf_di              ),
    .o_DOUT                     (obj_oddbuf_do              ),
    .i_RD                       (1'b1                       ),
    .i_WR                       (clk5m_ncen                 )
);

//sprite pixel data output latch
reg     [3:0]   objpx;
always @(posedge clk40m) if(clk5m_pcen) objpx <= obj_read_evenbuf ? obj_evenbuf_do : obj_oddbuf_do;



///////////////////////////////////////////////////////////
//////  Priority handler
////

reg             pxsel;
wire    [3:0]   pxout = pxsel ? tmpx_4bpp : objpx;
always @(*) begin
    if(objpx == 4'hF) pxsel = 1'b1; //transparent sprite
    else begin
        if(!force_obj_top_n_z) pxsel = 1'b0; //obj on tm
        else begin
            if(tmpx_4bpp == 4'h0) pxsel = 1'b0; //tm on obj, but the tm is transparent
            else pxsel = 1'b1;
        end
    end
end



///////////////////////////////////////////////////////////
//////  Palette ROM
////

wire            palrom_banksel;
wire    [8:0]   palrom_addr = {palrom_banksel, pxsel, palcode_z, tilecode_z[7], pxout};
wire    [7:0]   palrom_do;
//SuprLoco_PROM #(.AW(9), .DW(8), .simhexfile({PATH, "pr-5220.txt"})) u_palrom (
SuprLoco_PROM #(.AW(9), .DW(8), .simhexfile()) u_palrom (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[8:0]       ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA            ),
    .i_PROG_CS                  (i_EMU_BRAM_PALROM_CS       ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     (palrom_addr                ),
    .o_DOUT                     (palrom_do                  ),
    .i_RD                       (1'b1                       )
);

//screen blanking(async) control 1-bit registrer
wire            screen_force_blank_n;
wire            screen_blank_d = ~(blank | vclk | ~screen_force_blank_n);
reg             screen_blank_q;
wire            screen_blank = ~(screen_force_blank_n & screen_blank_q);

//final pixel register
reg     [7:0]   final_px_reg;
wire    [7:0]   final_px_q = final_px_reg;

always @(posedge clk40m) if(clk5m_ncen) begin
    screen_blank_q <= screen_blank_d;

    if(screen_blank) final_px_reg <= 8'h00;
    else final_px_reg <= palrom_do;

    o_VIDEO_DEN <= ~screen_blank;
end

assign  o_VIDEO_CEN = clk5m_ncen;
assign  o_VIDEO_R = final_px_q[2:0];
assign  o_VIDEO_G = final_px_q[5:3];
assign  o_VIDEO_B = {final_px_q[7:6], 1'b0};



///////////////////////////////////////////////////////////
//////  i8255
////

wire    [7:0]   ppi_do;
wire    [7:0]   ppi_pa_do, ppi_pb_do, ppi_pc_do;
assign  screen_force_blank_n = ppi_pb_do[4];
assign  palrom_banksel = ppi_pb_do[5];
assign  flip = ppi_pb_do[7];
wire            snd_mute = ppi_pc_do[0];
wire            scpu_nmi_n = ppi_pc_do[7];
wire            scpu_nmi_ack_n;

jt8255 u_ppi_main (
    .clk                        (clk40m                     ),
    .rst                        (~initrst_n                 ),

    .addr                       (mcpu_addr[1:0]             ),
    .din                        (mcpu_wrbus                 ),
    .dout                       (ppi_do                     ),
    .rdn                        (mcpu_rd_n                  ),
    .wrn                        (mcpu_wr_n                  ),
    .csn                        (~(active_device_id == IO_PPI)),

    .porta_din                  (8'h00                      ),
    .portb_din                  (8'h00                      ),
    .portc_din                  ({1'b1, scpu_nmi_ack_n, 6'h3F}),

    .porta_dout                 (ppi_pa_do                  ),
    .portb_dout                 (ppi_pb_do                  ),
    .portc_dout                 (ppi_pc_do                  )
);



///////////////////////////////////////////////////////////
//////  Sound CPU
////

//prescaler
reg     [3:0]   scpu_prescaler;
always @(posedge clk40m) begin
    if(!initrst_n) begin
        scpu_prescaler <= 4'b0000;
    end
    else begin if(clk20m_ncen) begin
        if(scpu_prescaler[2:0] == 3'b100) begin
            scpu_prescaler[3] <= ~scpu_prescaler[3];
            scpu_prescaler[2:0] <= 3'b000;
        end
        else scpu_prescaler <= scpu_prescaler + 4'd1;
    end end
end

//clock enables
reg             scpu_prescaler_bit1_pcen, scpu_prescaler_bit1_ncen;
reg             scpu_prescaler_bit3_pcen, scpu_prescaler_bit3_ncen;
always @(posedge clk40m) if(clk20m_ncen) begin
    scpu_prescaler_bit1_pcen <= scpu_prescaler[2:0] == 3'b000;
    scpu_prescaler_bit1_ncen <= scpu_prescaler[2:0] == 3'b010;

    scpu_prescaler_bit3_pcen <= scpu_prescaler == 4'b0011;
    scpu_prescaler_bit3_ncen <= scpu_prescaler == 4'b1011;
end

wire            scpu_pcen = scpu_prescaler_bit1_ncen & clk20m_ncen;
wire            scpu_ncen = scpu_prescaler_bit1_pcen & clk20m_ncen;
wire            sn76489_a_pcen = scpu_prescaler_bit1_pcen & clk20m_ncen;
wire            sn76489_b_pcen = scpu_prescaler_bit3_pcen & clk20m_ncen;


//buses
wire    [15:0]  scpu_addr;
wire    [7:0]   scpu_wrbus;
reg     [7:0]   scpu_rdbus;
wire            scpu_rd_n, scpu_wr_n;
wire            scpu_mreq_n;

//misc
wire            scpu_wait_n;
wire            scpu_rfsh;
reg             scpu_int_n;
wire            scpu_iorq_n;

T80pa u_soundcpu (
    .RESET_n                    (softrst_n                  ),
    .CLK                        (clk40m                     ),
    .CEN_p                      (scpu_pcen                  ),
    .CEN_n                      (scpu_ncen                  ),
    .WAIT_n                     (scpu_wait_n                ),
    .INT_n                      (scpu_int_n                 ),
    .NMI_n                      (scpu_nmi_n                 ),
    .RD_n                       (scpu_rd_n                  ),
    .WR_n                       (scpu_wr_n                  ),
    .A                          (scpu_addr                  ),
    .DI                         (scpu_rdbus                 ),
    .DO                         (scpu_wrbus                 ),
    .IORQ_n                     (scpu_iorq_n                ),
    .M1_n                       (                           ),
    .MREQ_n                     (scpu_mreq_n                ),
    .BUSRQ_n                    (                           ),
    .BUSAK_n                    (                           ),
    .RFSH_n                     (scpu_rfsh                  ),
    .out0                       (1'b0                       ), //?????
    .HALT_n                     (                           )
);

//sound interrupt generator
reg             vcntr_bit5_z;
wire            vcntr_bit5_nedet = vcntr_bit5_z & ~vcntr[5];
always @(posedge clk40m) vcntr_bit5_z <= vcntr[5];

always @(posedge clk40m) begin
    if(!scpu_iorq_n | !initrst_n) scpu_int_n <= 1'b1;
    else begin
        if(vcntr_bit5_nedet) scpu_int_n <= ~scpu_int_n;
    end
end

//nmi ack
assign  scpu_nmi_ack_n = ~(scpu_addr[15:13] == 3'b111);

//sound program
wire    [7:0]   sndprg_do;
/*
SuprLoco_PROM #(.AW(13), .DW(8), .simhexfile()) u_sndprg (
    .i_MCLK                     (clk40m                     ),

    .i_PROG_ADDR                (i_EMU_BRAM_ADDR[12:0]      ),
    .i_PROG_DIN                 (i_EMU_BRAM_DATA            ),
    .i_PROG_CS                  (i_EMU_BRAM_SNDPRG_CS       ),
    .i_PROG_WR                  (i_EMU_BRAM_WR              ),

    .i_ADDR                     (scpu_addr[12:0]            ),
    .o_DOUT                     (sndprg_do                  ),
    .i_RD                       (scpu_addr[15:13] == 3'b000 )
);
*/
assign cpu2_rd = scpu_addr[15:13] == 3'b000;
assign cpu2_addr = scpu_addr[12:0];
assign sndprg_do = cpu2_din;

//sound ram
wire    [7:0]   sndram_do;
SuprLoco_SRAM #(.AW(11), .DW(8), .simhexfile()) u_sndram (
    .i_MCLK                     (clk40m                     ),

    .i_ADDR                     (scpu_addr[10:0]            ),
    .i_DIN                      (scpu_wrbus                 ),
    .o_DOUT                     (sndram_do                  ),
    .i_RD                       (scpu_addr[15:13] == 3'b100 ),
    .i_WR                       (scpu_addr[15:13] == 3'b100 & ~scpu_wr_n)
);


wire            sn76489_a_rdy, sn76489_b_rdy;
assign  scpu_wait_n = sn76489_a_rdy & sn76489_b_rdy;
wire signed     [10:0]  sn76489_a_snd, sn76489_b_snd;
jt89 u_sn76489_a (
    .rst                        (~softrst_n                 ),
    .clk                        (clk40m                     ),
    .clk_en                     (sn76489_a_pcen             ),

    .wr_n                       (scpu_wr_n                  ),
    .cs_n                       (~(scpu_addr[15:13] == 3'b101)),
    .din                        (scpu_wrbus                 ),

    .sound                      (sn76489_a_snd              ),
    .ready                      (sn76489_a_rdy              )
);

jt89 u_sn76489_b (
    .rst                        (~softrst_n                 ),
    .clk                        (clk40m                     ),
    .clk_en                     (sn76489_b_pcen             ),

    .wr_n                       (scpu_wr_n                  ),
    .cs_n                       (~(scpu_addr[15:13] == 3'b110)),
    .din                        (scpu_wrbus                 ),

    .sound                      (sn76489_b_snd              ),
    .ready                      (sn76489_b_rdy              )
);

/*
wire signed     [13:0]  sn76489_a_snd, sn76489_b_snd;
sn76489_audio u_sn76489_a (
    .clk_i                      (clk40m                     ),
    .en_clk_psg_i               (sn76489_a_pcen             ),

    .wr_n_i                     (scpu_wr_n                  ),
    .ce_n_i                     (~(scpu_addr[15:13] == 3'b101)),
    .data_i                     (scpu_wrbus                 ),

    .ready_o                    (sn76489_a_rdy              ),
    .pcm14s_o                   (sn76489_a_snd              )
);

sn76489_audio u_sn76489_b (
    .clk_i                      (clk40m                     ),
    .en_clk_psg_i               (sn76489_b_pcen             ),

    .wr_n_i                     (scpu_wr_n                  ),
    .ce_n_i                     (~(scpu_addr[15:13] == 3'b110)),
    .data_i                     (scpu_wrbus                 ),

    .ready_o                    (sn76489_b_rdy              ),
    .pcm14s_o                   (sn76489_b_snd              )
);
*/

always @(posedge clk40m) o_SOUND <= (sn76489_a_snd + sn76489_b_snd) * 4'sd7;



///////////////////////////////////////////////////////////
//////  Read bus selector
////

always @(*) begin
    case(active_device_id)
        PGMROM0: mcpu_rdbus = pgmrom0_do;
        PGMROM1: mcpu_rdbus = pgmrom1_do;
        DATAROM: mcpu_rdbus = datarom_do;
        OBJRAM : mcpu_rdbus = mcpu_addr[0] ? objram_do[15:8] : objram_do[7:0];
        TMRAM  : mcpu_rdbus = tmram_do;
        MAINRAM: mcpu_rdbus = mainram_do;
        IO_SYS : mcpu_rdbus = i_SYS_BTN;
        IO_P1  : mcpu_rdbus = i_P1_BTN;
        IO_P2  : mcpu_rdbus = i_P2_BTN;
        IO_DIP : mcpu_rdbus = mcpu_addr[0] ? i_DIPSW2 : i_DIPSW1;
        IO_PPI : mcpu_rdbus = ppi_do;
        INVALID: mcpu_rdbus = 8'hFF;
        default: mcpu_rdbus = 8'hFF;
    endcase

    scpu_rdbus = 8'hFF;
         if(scpu_addr[15:13] == 3'b000) scpu_rdbus = sndprg_do;
    else if(scpu_addr[15:13] == 3'b100) scpu_rdbus = sndram_do;
    else if(scpu_addr[15:13] == 3'b111) scpu_rdbus = ppi_pa_do;
end


endmodule