module TC0360PRI #(parameter SS_IDX=-1) (
    input clk,
    input ce_pixel,
    input reset,

    // CPU Interface
    input [7:0] cpu_din,
    output reg [7:0] cpu_dout,

    input        cs,
    input [3:0]  cpu_addr,
    input        cpu_rw,
    input        cpu_ds_n,

    input        fullwidth,

    input [14:0] color_in0 /* verilator public_flat */,
    input [14:0] color_in1 /* verilator public_flat */,
    input [14:0] color_in2 /* verilator public_flat */,
    output [12:0] color_out /* verilator public_flat */,

    ssbus_if.slave ssbus
);

reg [7:0] ctrl[16];

always_ff @(posedge clk) begin
    if (reset) begin
        int i;
        for (int i = 0; i < 16; i = i + 1) begin
            ctrl[i] <= 0;
        end
    end else begin
        if (cs) begin
            if (cpu_rw) begin
                cpu_dout <= ctrl[cpu_addr[3:0]];
            end else begin
                if (~cpu_ds_n) ctrl[cpu_addr[3:0]]  <= cpu_din;
            end
        end

        ssbus.setup(SS_IDX, 16, 0);
        if (ssbus.access(SS_IDX)) begin
            if (ssbus.write) begin
                ctrl[ssbus.addr[3:0]] <= ssbus.data[7:0];
                ssbus.write_ack(SS_IDX);
            end else if (ssbus.read) begin
                ssbus.read_response(SS_IDX, { 56'b0, ctrl[ssbus.addr[3:0]] });
            end
        end
    end
end


wire [1:0] sel0 = color_in0[14:13];
wire [1:0] sel1 = color_in1[14:13];
wire [1:0] sel2 = fullwidth ? color_in2[14:13] : ctrl[1][7:6];

wire [15:0] prio_vals0 = { ctrl[5], ctrl[4] };
wire [15:0] prio_vals1 = { ctrl[7], ctrl[6] };
wire [15:0] prio_vals2 = { ctrl[9], ctrl[8] };

wire [3:0] prio0 = |color_in0[3:0] ? { prio_vals0[ 4 * sel0 +: 4 ] } : 4'b0;
wire [3:0] prio1 = |color_in1[3:0] ? { prio_vals1[ 4 * sel1 +: 4 ] } : 4'b0;
wire [3:0] prio2 = |color_in2[3:0] ? { prio_vals2[ 4 * sel2 +: 4 ] } : 4'b0;

wire [12:0] color0 = color_in0[12:0];
wire [12:0] color1 = color_in1[12:0];
wire [12:0] color2 = fullwidth ? color_in2[12:0] : { 1'b0, ctrl[1][5:0], color_in2[5:0] };

wire [1:0] blend_mode = ctrl[0][7:6];
wire [1:0] blend0 = ctrl[0][1:0];
wire [1:0] blend1 = ctrl[0][3:2];
wire [1:0] blend2 = ctrl[0][5:4];

reg [12:0] color_final;

function bit [12:0] blend(input [1:0] hi_mode, input [12:0] hi, input [12:0] lo);
    bit [12:0] r;
    if (blend_mode == 2'b11) begin
        case (hi_mode)
            2'b00: r = { lo[12:4], hi[3:0] };
            2'b01: r = { lo[12:5], hi[4:0] };
            2'b10: r = { lo[12:6], hi[5], lo[4], hi[3:0] };
            2'b11: r = { lo[12:6], hi[5:0] };
        endcase
    end else if (blend_mode == 2'b10) begin
        case (hi_mode)
            2'b00: r = { hi[12:5], 1'b0, hi[3:0] };
            2'b01,
            2'b10: r = { hi[12:6], 1'b0, hi[4:0] };
            2'b11: r = { hi[12:7], 1'b0, hi[5:0] };
        endcase
    end else begin
        r = hi;
    end

    return r;
endfunction


assign color_out = color_final;

always_ff @(posedge clk) begin
    if (ce_pixel) begin
        color_final <= 13'd0;
        if (|prio0 && prio0 > prio1 && prio0 > prio2) begin
            color_final <= color0;
            if (prio1 == (prio0 - 4'd1)) begin
                color_final <= blend(blend0, color0, color1);
            end
            if (prio2 == (prio0 - 4'd1)) begin
                color_final <= blend(blend0, color0, color2);
            end
        end else if (|prio1 && prio1 > prio0 && prio1 > prio2) begin
            color_final <= color1;
            if (prio0 == (prio1 - 4'd1)) begin
                color_final <= blend(blend1, color1, color0);
            end
            if (prio2 == (prio1 - 4'd1)) begin
                color_final <= blend(blend1, color1, color2);
            end
        end else if (|prio2 && prio2 > prio0 && prio2 > prio1) begin
            color_final <= color2;
            if (prio0 == (prio2 - 4'd1)) begin
                color_final <= blend(blend2, color2, color0);
            end
            if (prio1 == (prio2 - 4'd1)) begin
                color_final <= blend(blend2, color2, color1);
            end
        end
    end
end


endmodule
