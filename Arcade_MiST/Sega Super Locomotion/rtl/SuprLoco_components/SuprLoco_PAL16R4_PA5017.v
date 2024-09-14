module SuprLoco_PAL16R4_PA5017 (
    input   wire            i_MCLK,
    input   wire            i_RST_n,
    input   wire            i_CEN,

    input   wire    [7:0]   i_HCNTR,            //{Pin12, [Pin8:Pin2]}
    input   wire            i_FLIP_n,           //Pin19
    input   wire            i_VBLANK,           //Pin9
    input   wire            i_VSYNC_n,          //Pin18
    input   wire            i_DMAEND,           //Pin13

    //registered output
    output  reg             o_HCNTR_LD_n,       //Pin16
    output  reg             o_VCLK,             //Pin15
    output  reg             o_DMAON_n,          //Pin14
    output  reg             o_CSYNC_n           //Pin17
);

always @(posedge i_MCLK) begin
    if(!i_RST_n) begin
        o_HCNTR_LD_n <= 1'b1;
        o_VCLK <= 1'b1;
        o_DMAON_n <= 1'b1;
        o_CSYNC_n <= 1'b1;
    end
    else begin if(i_CEN) begin
        o_CSYNC_n <= ~|{( i_FLIP_n & o_VCLK & (i_HCNTR[5:2] == 4'b0011)              & i_VSYNC_n),
                        ( i_FLIP_n & o_VCLK &  i_HCNTR[4]               & ~o_CSYNC_n & i_VSYNC_n),
                        ( i_FLIP_n & o_VCLK & ~i_HCNTR[2]               & ~o_CSYNC_n & i_VSYNC_n),
                        (~i_FLIP_n & o_VCLK & (i_HCNTR[5:2] == 4'b1100)              & i_VSYNC_n),
                        (~i_FLIP_n & o_VCLK & ~i_HCNTR[4]               & ~o_CSYNC_n & i_VSYNC_n),
                        (~i_FLIP_n & o_VCLK &  i_HCNTR[2]               & ~o_CSYNC_n & i_VSYNC_n),
                        ~i_VSYNC_n};

        if(i_FLIP_n) begin
            //o_HCNTR_LD_n
            if(i_HCNTR == 8'd254) o_HCNTR_LD_n <= o_VCLK;
            else o_HCNTR_LD_n <= 1'b1;

            //o_VCLK
            if(!o_HCNTR_LD_n) o_VCLK <= 1'b1;
            else begin
                if(i_HCNTR == 8'd255) o_VCLK <= 1'b0;
            end

            //o_DMAON
            if(i_VBLANK) o_DMAON_n <= 1'b1;
            else begin
                if(i_HCNTR == 8'd193 && o_VCLK) o_DMAON_n <= 1'b0;
                else begin
                    if(i_DMAEND) o_DMAON_n <= 1'b1;
                end
            end

        end
        else begin
            //o_HCNTR_LD_n
            if(i_HCNTR == 8'd1) o_HCNTR_LD_n <= o_VCLK;
            else o_HCNTR_LD_n <= 1'b1;

            //o_VCLK
            if(!o_HCNTR_LD_n) o_VCLK <= 1'b1;
            else begin
                if(i_HCNTR == 8'd0) o_VCLK <= 1'b0;
            end

            //o_DMAON
            if(i_VBLANK) o_DMAON_n <= 1'b1;
            else begin
                if(i_HCNTR == 8'd162 && o_VCLK) o_DMAON_n <= 1'b0;
                else begin
                    if(i_DMAEND) o_DMAON_n <= 1'b1;
                end
            end
        end
    end end
end

endmodule