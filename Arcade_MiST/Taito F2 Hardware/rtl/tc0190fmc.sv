module TC0190FMC #(parameter SS_IDX=-1) (
    input clk,
    input reset,

    // CPU Interface
    input [7:0] cpu_din,

    input        cs,
    input [2:0]  cpu_addr,
    input        cpu_rw,
    input        cpu_ds_n,

    input code_req,
    input [12:0] code_original,
    output reg [18:0] code_modified,

    ssbus_if.slave ssbus
);

reg [7:0] ctrl[8];

always_ff @(posedge clk) begin
    if (reset) begin
        int i;
        for (int i = 0; i < 8; i = i + 1) begin
            ctrl[i] <= 0;
        end
    end else begin
        if (cs) begin
            if (~cpu_rw & ~cpu_ds_n) begin
                ctrl[cpu_addr[2:0]] <= cpu_din[7:0];
            end
        end

        ssbus.setup(SS_IDX, 8, 0);
        if (ssbus.access(SS_IDX)) begin
            if (ssbus.write) begin
                ctrl[ssbus.addr[2:0]] <= ssbus.data[7:0];
                ssbus.write_ack(SS_IDX);
            end else if (ssbus.read) begin
                ssbus.read_response(SS_IDX, { 56'b0, ctrl[ssbus.addr[2:0]] });
            end
        end
    end

    if (code_req) begin
        unique case(code_original[12:10])
            3'b000,
            3'b001: code_modified <= { ctrl[2], code_original[10:0] };
            3'b010,
            3'b011: code_modified <= { ctrl[3], code_original[10:0] };
            3'b100: code_modified <= { 1'b0, ctrl[4], code_original[9:0] };
            3'b101: code_modified <= { 1'b0, ctrl[5], code_original[9:0] };
            3'b110: code_modified <= { 1'b0, ctrl[6], code_original[9:0] };
            3'b111: code_modified <= { 1'b0, ctrl[7], code_original[9:0] };
        endcase
    end
end

endmodule
