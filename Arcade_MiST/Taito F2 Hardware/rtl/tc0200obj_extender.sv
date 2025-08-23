module TC0200OBJ_Extender(
    input clk,

    input [1:0] mode,

    // CPU interface
    input cs,
    input [11:0] cpu_addr,
    input [1:0] cpu_ds_n,
    input cpu_rw,
    input [15:0] din,
    output [15:0] dout,

    input code_req,
    input [12:0] code_original,
    output reg [18:0] code_modified,
    input [14:0] obj_addr,

    ssbus_if.slave ssb
);

wire [7:0] ram_a_data, ram_a_q;
wire [11:0] ram_a_addr;
wire ram_a_wr;
wire [7:0] cpu_byte_din = mode == 2'b10 ? din[15:8] : din[7:0];
wire [7:0] cpu_byte_dout;

assign dout = { cpu_byte_dout, cpu_byte_dout };
wire cpu_ram_wr = cs & ~cpu_rw & ~cpu_ds_n[0];

dualport_ram_unreg #(.WIDTH(8), .WIDTHAD(12)) extension_ram(
    .clock_a(clk),
    .wren_a(ram_a_wr),
    .address_a(ram_a_addr),
    .data_a(ram_a_data),
    .q_a(ram_a_q),

    .clock_b(clk),
    .wren_b(cpu_ram_wr),
    .address_b(cpu_addr[11:0]),
    .data_b(cpu_byte_din),
    .q_b(cpu_byte_dout)
);

ram_ss_adaptor #(.WIDTH(8), .WIDTHAD(12), .SS_IDX(SSIDX_EXTENSION_RAM)) extension_ram_ss(
    .clk,

    .wren_in(0),
    .addr_in({1'b0, obj_addr[14], obj_addr[12:3]}),
    .data_in(0),

    .wren_out(ram_a_wr),
    .addr_out(ram_a_addr),
    .data_out(ram_a_data),

    .q(ram_a_q),

    .ssbus(ssb)
);


always_ff @(posedge clk) begin
    if (mode == 2'b00) begin // passthrough
        code_modified <= { 6'd0, code_original };
    end else if (mode == 2'b01 || mode == 2'b10) begin
        if (code_req) begin
            code_modified <= { 3'd0, ram_a_q, code_original[7:0] };
        end
    end
end

endmodule
