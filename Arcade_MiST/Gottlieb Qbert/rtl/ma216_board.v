
module ma216_board(
  input clk,
  input cen,
  input reset,

  input [5:0] IP2720,

  output [15:0] audio_votrax,
  output [7:0] audio_dac,

  input rom_init,
  input [17:0] rom_init_address,
  input [7:0] rom_init_data
);

assign audio_dac = U7_8;

wire [15:0] AB;
wire  [7:0] DBo;
wire        RWn, irq, U14_AR;
wire  [7:0] U5_dout, U6_dout, U6000_dout, U6800_dout;
wire  [7:0] U15_D_O;
wire  [7:0] SB1 = 8'hFF;
reg   [7:0] U11_18, U7_8;
reg   [1:0] inflection_reg;
reg         stb;
reg         rom0_ce, rom1_ce, riot_ce, dac0_ce, dac1_ce, stb_ce;

wire  [7:0] DBi = riot_ce ? U15_D_O : U5_dout | U6_dout | U6000_dout | U6800_dout;

T65 U3(
  .Mode(2'b00),
  .Res_n(~reset),
  .Clk(clk),
  .Enable(cen),
  .Rdy(1'b1),
  .R_W_n(RWn),
  .A(AB),
  .DI(DBi),
  .DO(DBo),
  .IRQ_n(irq),
  .NMI_n(~U14_AR)
);

always @(*) begin : U4
	rom0_ce = 0;
	rom1_ce = 0;
	riot_ce = 0;
	dac0_ce = 0;
	dac1_ce = 0;
	stb_ce  = 0;
	case (AB[14:12])
		3'd0: riot_ce = 1;
		3'd1: dac0_ce = 1;
		3'd2: stb_ce  = 1;
		3'd3: dac1_ce = 1;
		3'd6: rom0_ce = 1;
		3'd7: rom1_ce = 1;
		default: ;
	endcase
end

dpram #(.addr_width(11),.data_width(8)) U6000 (
  .clk(clk),
  .addr(AB[10:0]),
  .dout(U6000_dout),
  .ce(~rom0_ce),
  .oe(AB[11]),
  .we(rom_init & rom_init_address < 18'hC800),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);

dpram #(.addr_width(11),.data_width(8)) U6800 (
  .clk(clk),
  .addr(AB[10:0]),
  .dout(U6800_dout),
  .ce(~rom0_ce),
  .oe(~AB[11]),
  .we(rom_init & rom_init_address < 18'hD000),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);

dpram #(.addr_width(11),.data_width(8)) U5 (
  .clk(clk),
  .addr(AB[10:0]),
  .dout(U5_dout),
  .ce(~rom1_ce),
  .oe(AB[11]),
  .we(rom_init & rom_init_address < 18'hD800),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);

dpram #(.addr_width(11),.data_width(8)) U6 (
  .clk(clk),
  .addr(AB[10:0]),
  .dout(U6_dout),
  .ce(~rom1_ce),
  .oe(~AB[11]),
  .we(rom_init & rom_init_address < 18'hE000),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);

// U7 U8
always @(posedge clk)
  if (dac0_ce) U7_8 <= DBo;

// U11 U18
always @(posedge clk)
  if (dac1_ce) U11_18 <= DBo;

// U9 latch for inflection
always @(posedge clk)
  if (stb_ce) inflection_reg <= DBo[7:6];

always @(posedge clk)
  stb <= stb_ce & ~RWn;

sc01a #(.CLK_HZ(40_000_000), .ENABLE_RESAMPLER(0)) U14(
    .clk(clk),
    .reset_n(~reset),
    .p(~DBo[5:0]),
    .inflection(inflection_reg),
    .stb(stb),
    .ar(U14_AR),
    .clk_dac(U11_18),
    .audio_out_u(audio_votrax),
    .audio_out(),
    .audio_valid()
);

M6532 U15(
  .clk(clk),          // PHI 2
  .ce(cen),           // Clock enable
  .res_n(~reset),     // reset
  .addr(AB[6:0]),     // Address
  .RW_n(RWn),         // 1 = read, 0 = write
  .d_in(DBo),
  .d_out(U15_D_O),
  .RS_n(AB[9]),       // RAM select
  .IRQ_n(irq),
  .CS1(riot_ce),      // Chip select 1, 1 = selected
  .CS2_n(~riot_ce),   // Chip select 2, 0 = selected
  .PA_in({ &IP2720[3:0], 1'b0, ~IP2720 }),
  .PA_out(),
  .PB_in({ ~U14_AR, 1'b1, ~SB1[5:0] }),
  .PB_out(),
  .oe()
);

endmodule
