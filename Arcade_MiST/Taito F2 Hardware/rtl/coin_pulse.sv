module coin_pulse(
    input clk,

    input vblank,

    input button,
    output pulse
);

reg [15:0] shift;
reg prev_button;
reg prev_vblank;

assign pulse = |shift[3:0];

always_ff @(posedge clk) begin
    prev_vblank <= vblank;
    prev_button <= button;

    if (vblank & ~prev_vblank) begin
        shift <= { shift[14:0], 1'b0 };
    end

    if (~|shift & ~button & prev_button) begin
        shift[0] <= 1;
    end
end

endmodule
