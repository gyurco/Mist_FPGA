module SuprLoco_PAL16R4_PA5016 (
    input   wire            i_MCLK,
    input   wire            i_RST_n,
    input   wire            i_CEN,

    input   wire    [7:0]   i_VCNTR,            //[Pin9:Pin2]
    input   wire            i_FLIP_n,           //Pin19

    //combinational output
    output  reg             o_VCNTR_LD_n,       //Pin14
    output  reg             o_BLANK_n,          //Pin15
    output  reg             o_VSYNC_n,          //Pin16
    output  reg             o_VBLANK,           //Pin17

    //registered output
    output  reg             o_VBLANK_PNCEN_n,   //Pin18
    output  reg             o_BLANK,            //Pin13
    output  reg             o_IRQ_n             //Pin12
);

always @(posedge i_MCLK) begin
    if(!i_RST_n) begin
        o_VBLANK_PNCEN_n <= 1'b1;
        o_BLANK <= 1'b1;
        o_IRQ_n <= 1'b1;
    end
    else begin if(i_CEN) begin
        if(i_FLIP_n) begin
            //o_VBLANK_PNCEN_n
            if(i_VCNTR == 8'd222 || (i_VCNTR == 8'd5 && o_VBLANK)) o_VBLANK_PNCEN_n <= 1'b0;
            else o_VBLANK_PNCEN_n <= 1'b1;

            //o_BLANK
            if(i_VCNTR[7] == 1'b1) begin
                if(o_VBLANK_PNCEN_n == 1'b0) o_BLANK <= 1'b1;
            end
            else begin
                if(o_VCNTR_LD_n == 1'b0) o_BLANK <= 1'b0;
            end

            //o_IRQ
            if(i_VCNTR == 8'd223) o_IRQ_n <= 1'b0;
            else o_IRQ_n <= 1'b1;
        end
        else begin //flipped
            //o_VBLANK_PNCEN_n
            if(i_VCNTR == 8'd1 || (i_VCNTR == 8'd218 && o_VBLANK)) o_VBLANK_PNCEN_n <= 1'b0;
            else o_VBLANK_PNCEN_n <= 1'b1;

            //o_BLANK
            if(i_VCNTR[7] == 1'b0) begin
                if(o_VBLANK_PNCEN_n == 1'b0) o_BLANK <= 1'b1;
            end
            else begin
                if(o_VCNTR_LD_n == 1'b0) o_BLANK <= 1'b0;
            end

            //o_IRQ
            if(i_VCNTR == 8'd0) o_IRQ_n <= 1'b0;
            else o_IRQ_n <= 1'b1;
        end
    end end
end

always @(*) begin
    if(i_FLIP_n) begin        
        o_VCNTR_LD_n <= ~(i_VCNTR == 8'd7 & o_BLANK);
        o_BLANK_n <= ~o_BLANK;
        o_VSYNC_n <= ~|{i_VCNTR == 8'd237, i_VCNTR == 8'd238, i_VCNTR == 8'd239, i_VCNTR == 8'd240};
        o_VBLANK <= o_BLANK & o_VCNTR_LD_n;
    end
    else begin //flipped
        o_VCNTR_LD_n <= ~(i_VCNTR == 8'd216 & o_BLANK);
        o_BLANK_n <= ~o_BLANK;
        o_VSYNC_n <= ~|{i_VCNTR == 8'd239, i_VCNTR == 8'd240, i_VCNTR == 8'd241, i_VCNTR == 8'd242};
        o_VBLANK <= o_BLANK & o_VCNTR_LD_n;
    end
end

endmodule