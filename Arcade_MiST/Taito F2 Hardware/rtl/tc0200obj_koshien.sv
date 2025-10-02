module TC0200OBJ_Koshien #(parameter SS_IDX) (
    input clk,

    // CPU interface
    input cs_n,
    input [1:0] cpu_ds_n,
    input cpu_rw,
    input [15:0] din,

    input [12:0] code_original,
    output reg [18:0] code_modified,

    ssbus_if.slave ssb
);

reg [15:0] ctrl;

wire [4:0] ofs0 = 5'b0;
wire [4:0] ofs1 = { 1'b0, ctrl[ 3:0] } + 5'd1;
wire [4:0] ofs2 = { 1'b0, ctrl[ 7:4] } + 5'd1;
wire [4:0] ofs3 = { 1'b0, ctrl[11:8] } + 5'd1;

always_ff @(posedge clk) begin
    if (~(cs_n | cpu_rw)) begin
        if (~cpu_ds_n[0]) ctrl[7:0] <= din[7:0];
        if (~cpu_ds_n[1]) ctrl[15:8] <= din[15:8];
    end

    case(code_original[12:11])
        2'b00: code_modified <= { 3'b0, ofs0, code_original[10:0] };
        2'b01: code_modified <= { 3'b0, ofs1, code_original[10:0] };
        2'b10: code_modified <= { 3'b0, ofs2, code_original[10:0] };
        2'b11: code_modified <= { 3'b0, ofs3, code_original[10:0] };
    endcase

    ssb.setup(SS_IDX, 1, 1); // 1, 16-bit value
    if (ssb.access(SS_IDX)) begin
        if (ssb.read) begin
            ssb.read_response(SS_IDX, { 48'd0, ctrl });
        end else if (ssb.write) begin
            ctrl <= ssb.data[15:0];
            ssb.write_ack(SS_IDX);
        end
    end

end

endmodule
