// Don't know what the pin names are, so basing them on TC0100SCN

module tc0430grw_fifo
(
    input clk,

    input reset,

    input wr,
    input [15:0] code,
    input [2:0]  pixel_x,
    input [2:0]  pixel_y,

    input rd,
    output [5:0] color,

    // ROM interface
    output reg [26:0] rom_address,
    input      [15:0] rom_data,
    output reg        rom_req,
    input             rom_ack
);

reg [8:0] input_wr_idx, input_rd_idx;
wire [15:0] next_code;
wire [2:0] next_pixel_x, next_pixel_y;

reg [8:0] output_wr_idx, output_rd_idx;
reg wr_output;
reg [5:0] pixel_color;
reg [1:0] nibble;
reg [1:0] color_hi;

dualport_ram_unreg #(.WIDTH(22), .WIDTHAD(9)) input_fifo(
    .clock_a(clk),
    .wren_a(wr),
    .address_a(input_wr_idx),
    .data_a({code, pixel_x, pixel_y}),
    .q_a(),

    .clock_b(clk),
    .wren_b(0),
    .address_b(input_rd_idx),
    .data_b(0),
    .q_b({next_code, next_pixel_x, next_pixel_y})
);

dualport_ram_unreg #(.WIDTH(6), .WIDTHAD(9)) output_fifo(
    .clock_a(clk),
    .wren_a(wr_output),
    .address_a(output_wr_idx),
    .data_a(pixel_color),
    .q_a(),

    .clock_b(clk),
    .wren_b(0),
    .address_b(output_rd_idx),
    .data_b(0),
    .q_b(color)
);

reg waiting;
reg reset_pending;
reg wr_prev;
always_ff @(posedge clk) begin
    if (reset) begin
        reset_pending <= 1;
    end
    wr_prev <= wr;
    if (~wr & wr_prev) begin
        input_wr_idx <= input_wr_idx + 1;
    end

    if (rd) begin
        output_rd_idx <= output_rd_idx + 1;
    end

    if (wr_output) begin
        output_wr_idx <= output_wr_idx + 1;
        wr_output <= 0;
    end

    if (waiting) begin
        if (rom_req == rom_ack) begin
            waiting <= 0;
            unique case(nibble)
                1: pixel_color <= { color_hi, rom_data[ 3:0 ] };
                0: pixel_color <= { color_hi, rom_data[ 7:4 ] };
                3: pixel_color <= { color_hi, rom_data[ 11:8 ] };
                2: pixel_color <= { color_hi, rom_data[ 15:12 ] };
            endcase
            wr_output <= 1;
        end
    end else if (reset_pending) begin
        input_wr_idx <= 0;
        input_rd_idx <= 0;
        output_rd_idx <= 0;
        output_wr_idx <= 0;
        reset_pending <= 0;
    end
    if (!reset_pending && (!waiting || rom_req == rom_ack) && input_wr_idx != input_rd_idx) begin
        if (|next_code[13:0]) begin
            rom_address <= PIVOT_ROM_SDR_BASE[26:0] + { 8'b0, next_code[13:0], next_pixel_y[2:0], next_pixel_x[2], 1'b0 };
            rom_req <= ~rom_req;
            color_hi <= next_code[15:14];
            nibble <= next_pixel_x[1:0];
            waiting <= 1;
            input_rd_idx <= input_rd_idx + 1;
        end else if (!waiting) begin
            pixel_color <= 6'd0;
            wr_output <= 1;
            input_rd_idx <= input_rd_idx + 1;
        end
    end

end


endmodule



module TC0430GRW #(parameter SS_IDX=-1) (
    input clk,
    input ce_13m,
    input ce_pixel,

    input reset,

    input is_280grd,

    // CPU interface
    input [12:0] VA,
    input [15:0] Din,
    output reg [15:0] Dout,
    input LDSn,
    input UDSn,
    input SCCSn,
    input RW,
    output DACKn,

    // RAM interface
    output reg [11:0] SA,
    input      [15:0] SDin,
    output     [15:0] SDout,
    output reg        WEUPn,
    output reg        WELOn,

    // ROM interface
    output reg [26:0] rom_address,
    input      [15:0] rom_data,
    output reg        rom_req,
    input             rom_ack,


    // Video interface
    output reg [5:0] SC,

    // assume it is positioned using sync,
    // FIXME - confirm what video signals are inputs
    input HBLANKn,
    input VBLANKn,

    ssbus_if.slave ssbus
);

reg dtack_n;
reg prev_cs_n;

reg ram_pending = 0;
reg ram_access = 0;

reg [15:0] ctrl[8];

wire [23:0] origin_x = { ctrl[0][7:0], ctrl[1] };
wire [23:0] dxx = is_280grd ? { {7{ctrl[2][15]}}, ctrl[2], 1'b0 } : { {8{ctrl[2][15]}}, ctrl[2] };
wire [23:0] dyx = is_280grd ? { {7{ctrl[6][15]}}, ctrl[6], 1'b0 } : { {8{ctrl[6][15]}}, ctrl[6] };
wire [23:0] origin_y = { ctrl[4][7:0], ctrl[5] };
wire [23:0] dxy = { {8{ctrl[3][15]}}, ctrl[3] };
wire [23:0] dyy = { {8{ctrl[7][15]}}, ctrl[7] };


assign DACKn = SCCSn ? 0 : dtack_n;
assign SDout = Din;

reg [23:0] row_x, row_y;
reg [23:0] cur_x, cur_y;

wire [2:0] pixel_x = cur_x[14:12];
wire [5:0] tile_x = cur_x[20:15];
wire [2:0] pixel_y = cur_y[14:12];
wire [5:0] tile_y = cur_y[20:15];

wire [5:0] fifo_color;
reg fifo_rd, fifo_wr;
reg [15:0] fifo_code;
reg [2:0] fifo_x, fifo_y;
reg fifo_reset;
tc0430grw_fifo fifo(
    .clk,

    .reset(fifo_reset),

    .code(fifo_code),
    .pixel_x(fifo_x),
    .pixel_y(fifo_y),
    .wr(fifo_wr),

    .rd(fifo_rd),
    .color(fifo_color),

    .rom_address,
    .rom_data,
    .rom_ack,
    .rom_req
);

reg prev_vblank_n, prev_hblank_n;

reg [8:0] hcnt;
reg [8:0] vcnt;

// 90 was determined experimentally to get the layers to line up between read
// hardware and the core. vblank seems to be the correct signal to use to
// determine vertical alignment

// 280grd offsets not confirmed
wire [8:0] hcnt_begin = is_280grd ? 85 : 90;

wire [8:0] vcnt_begin = is_280grd ? 20 : 36;


wire do_h_increments = hcnt > hcnt_begin;
wire do_v_increments = vcnt > vcnt_begin;

reg read_line_data;
reg write_line_data;

wire do_fifo_reads = read_line_data && hcnt >= hcnt_begin;
wire do_rom_reads = write_line_data && hcnt >= hcnt_begin;


always @(posedge clk) begin
    if (ce_pixel) begin
        prev_hblank_n <= HBLANKn;
        prev_vblank_n <= VBLANKn;
        fifo_reset <= 0;

        hcnt <= hcnt + 9'd1;

        if (~HBLANKn & prev_hblank_n) begin
            vcnt <= vcnt + 9'd1;
            write_line_data <= vcnt > vcnt_begin;
            read_line_data <= write_line_data;
            fifo_reset <= ~(write_line_data | read_line_data);
            hcnt <= 0;

            if( do_v_increments ) begin
                row_x <= row_x + dxy;
                row_y <= row_y + dyy;
                cur_x <= row_x + dxy;
                cur_y <= row_y + dyy;
            end else begin
                row_x <= origin_x;
                row_y <= origin_y;
                cur_x <= origin_x;
                cur_y <= origin_y;
            end
        end else if (~VBLANKn & prev_vblank_n) begin
            vcnt <= 0;
        end else if (do_h_increments) begin
            cur_x <= cur_x + dxx;
            cur_y <= cur_y + dyx;
        end
    end
end

//wire [3:0] access_cycle = full_hcnt[3:0];

reg [1:0] color_hi;
reg [1:0] nibble;
reg valid_pixel;

always @(posedge clk) begin
    bit [8:0] v;
    bit [5:0] h;

    fifo_rd <= 0;
    fifo_wr <= 0;

    if (reset) begin
        dtack_n <= 1;
        ram_pending <= 0;
        ram_access <= 0;
    end else if (ce_13m) begin
        WEUPn <= 1;
        WELOn <= 1;
        // CPu interface handling
        prev_cs_n <= SCCSn;
        if (~SCCSn & prev_cs_n) begin // CS edge
            if (VA[12]) begin // control access
                if (RW) begin
                    Dout <= ctrl[VA[2:0]];
                end else begin
                    if (~UDSn) ctrl[VA[2:0]][15:8] <= Din[15:8];
                    if (~LDSn) ctrl[VA[2:0]][7:0]  <= Din[7:0];
                end
                dtack_n <= 0;
            end else begin // ram access
                ram_pending <= 1;
            end
        end else if (SCCSn) begin
            dtack_n <= 1;
        end

        if (ce_pixel) begin
            if (do_rom_reads) begin
                fifo_wr <= 1;
                fifo_code <= SDin;
                fifo_x <= pixel_x;
                fifo_y <= pixel_y;
            end

            if (do_fifo_reads) begin
                SC <= fifo_color;
                fifo_rd <= 1;
            end

            SA <= VA[11:0];
            if (ram_pending) begin
                WELOn <= RW | LDSn;
                WEUPn <= RW | UDSn;
                ram_access <= 1;
                ram_pending <= 0;
            end
        end else begin
            SA <= { tile_y, tile_x };
            if (ram_access) begin
                Dout <= SDin;
                dtack_n <= 0;
                ram_access <= 0;
            end
        end
    end

    ssbus.setup(SS_IDX, 8, 1);
    if (ssbus.access(SS_IDX)) begin
        if (ssbus.write) begin
            ctrl[ssbus.addr[2:0]] <= ssbus.data[15:0];
            ssbus.write_ack(SS_IDX);
        end else if (ssbus.read) begin
            ssbus.read_response(SS_IDX, { 48'b0, ctrl[ssbus.addr[2:0]] });
        end
    end
end

endmodule


