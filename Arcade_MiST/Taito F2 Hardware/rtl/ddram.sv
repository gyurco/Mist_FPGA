interface ddr_if;
    logic        acquire;

    logic [31:0] addr;
    logic [63:0] wdata;
    logic [63:0] rdata;
    logic        read;
    logic        write;
    logic  [7:0] burstcnt;
    logic  [7:0] byteenable;
    logic        busy;
    logic        rdata_ready;

    modport to_host(
        output addr, wdata, read, write, burstcnt, byteenable, acquire,
        input rdata, busy, rdata_ready
    );

    modport from_host(
        output rdata, busy, rdata_ready,
        input addr, wdata, read, write, burstcnt, byteenable, acquire
    );


endinterface

module ddr_mux(
    input clk,

    ddr_if.to_host x,

    ddr_if.from_host a,
    ddr_if.from_host b
);

reg a_active = 0;

always_comb begin
    a.rdata = x.rdata;
    b.rdata = x.rdata;

    if (a_active) begin
        x.addr = a.addr;
        x.wdata = a.wdata;
        x.read = a.read;
        x.write = a.write;
        x.burstcnt = a.burstcnt;
        x.byteenable = a.byteenable;

        a.busy = x.busy;
        a.rdata_ready = x.rdata_ready;
        a.rdata = x.rdata;

        b.busy = 1;
        b.rdata_ready = 0;
    end else begin
        x.addr = b.addr;
        x.wdata = b.wdata;
        x.read = b.read;
        x.write = b.write;
        x.burstcnt = b.burstcnt;
        x.byteenable = b.byteenable;

        b.busy = x.busy;
        b.rdata_ready = x.rdata_ready;
        b.rdata = x.rdata;

        a.busy = 1;
        a.rdata_ready = 0;
    end
end

assign x.acquire = a.acquire | b.acquire;

always_ff @(posedge clk) begin
    if (a.acquire & ~b.acquire) a_active <= 1;
    if (~a.acquire & b.acquire) a_active <= 0;
end

endmodule


