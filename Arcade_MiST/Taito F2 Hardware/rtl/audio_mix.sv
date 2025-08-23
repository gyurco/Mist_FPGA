module audio_mix(
    input clk,
    input reset,

    input               fm_sample,
    input signed [15:0] fm_left,
    input signed [15:0] fm_right,
    input        [ 9:0] psg,

    output reg signed [15:0] mono_output

);

// 2mhz, 4mhz
wire ce_2x, ce;
jtframe_frac_cen #(2) mix_cen
(
    .clk(clk),
    .cen_in(1),
    .n(10'd35),
    .m(10'd467),
    .cen({ce, ce_2x}),
    .cenb()
);


reg [15:0] stage1_in_l, stage1_in_r;
wire [15:0] stage1_out_l, stage1_out_r;
reg [15:0] stage2_in_l, stage2_in_r;
wire [15:0] stage2_out_l, stage2_out_r;

IIR_filter #( .use_params(1), .stereo(1),
    .coeff_x(0.00202671686372780935),
    .coeff_x0(2), .coeff_x1(1), .coeff_x2(0),
    .coeff_y0(-1.96768012268835534861), .coeff_y1(0.97027297798961131825), .coeff_y2(0.00000000000000000000)
    ) pre_filter (
    .clk(clk),
    .reset(reset),

    .ce(ce_2x),
    .sample_ce(ce),

    .cx(), .cx0(), .cx1(), .cx2(), .cy0(), .cy1(), .cy2(),

    .input_l(stage1_in_l),
    .input_r(stage1_in_r),
    .output_l(stage1_out_l),
    .output_r(stage1_out_r)
);

IIR_filter #( .use_params(1), .stereo(1),
    .coeff_x(0.00015337009365802624),
    .coeff_x0(2), .coeff_x1(1), .coeff_x2(0),
    .coeff_y0(-1.99065970687776427894), .coeff_y1(0.99082479882215979128), .coeff_y2(0.00000000000000000000)
    ) main_filter (
    .clk(clk),
    .reset(reset),

    .ce(ce_2x),
    .sample_ce(ce),

    .cx(), .cx0(), .cx1(), .cx2(), .cy0(), .cy1(), .cy2(),

    .input_l(stage2_in_l),
    .input_r(stage2_in_r),
    .output_l(stage2_out_l),
    .output_r(stage2_out_r)
);


reg [15:0] fm_left_final, fm_right_final;
reg [15:0] fm_combined;

always @(posedge clk) begin
    if (ce) begin
        stage1_in_l <= fm_left;
        stage1_in_r <= fm_right;

        stage2_in_l <= stage1_out_l;
        stage2_in_r <= stage1_out_r;

        fm_left_final <= stage2_out_l;
        fm_right_final <= stage2_out_r;

        fm_combined <= fm_left_final + fm_right_final;
        mono_output <= fm_combined + {fm_combined[15], fm_combined[15:1]} + { 1'b0, psg[9:0], 5'd0 };
    end
end

endmodule



