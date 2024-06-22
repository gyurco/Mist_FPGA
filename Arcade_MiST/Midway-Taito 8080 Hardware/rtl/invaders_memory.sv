
module invaders_memory(
	input            Clock,
	input            RW_n,
	input            CPU_RW_n,
	input     [15:0] Addr,
	input     [15:0] Ram_Addr,
	output    [7:0]  Ram_out,
	input     [7:0]  Ram_in,
	output    [7:0]  Rom_out,
	output    [7:0]  color_prom_out,
	input     [10:0] color_prom_addr,
	input     [15:0] dn_addr,
	input     [7:0]  dn_data,
	input            dn_wr,
	output           Vortex_bit,
	output reg[7:0]  PlanePos,
	
	// Machine ID (where needed)
	input            mod_vortex,
	input            mod_attackforce,
	input            mod_cosmo,
	input            mod_polaris,
	input            mod_lupin,
	input            mod_indianbattle,
	input            mod_spacechaser,
	
	// Hiscore system
	input      [15:0] hs_address,
	input       [7:0] hs_data_in,
	output      [7:0] hs_data_out,
	input             hs_write,
	input             hs_access
);

wire [7:0] color_prom_out_rom;

wire [7:0]rom_data;
wire [7:0]rom2_data;

wire [15:0]rom_addr_vortex = {Addr[15:10],~Addr[9],Addr[8:4],~Addr[3],Addr[2:1],~Addr[0]};
wire [15:0]rom_addr_attackforce = {Addr[15:10],Addr[8],Addr[9],Addr[7:0]};
wire [15:0]rom_addr = mod_vortex? rom_addr_vortex : mod_attackforce ? rom_addr_attackforce : Addr;

wire rom_cs  = dn_wr & dn_addr[15:13]==3'b000;
wire rom2_cs = dn_wr & dn_addr[15:13]==3'b001;
wire vrom_cs = dn_wr & dn_addr[15:11]==5'b01000;

// Low ROM 0000-1FFF
dpram #(.addr_width_g(13),
	.data_width_g(8))
cpu_prog_rom(
	.clock_a(Clock),
	.wren_a(rom_cs),
	.address_a(dn_addr[12:0]),
	.data_a(dn_data),

	.clock_b(Clock),
	.address_b(rom_addr[12:0]),
	.q_b(rom_data)
);

// High ROM 4000-5FFF
dpram #(.addr_width_g(13),
	.data_width_g(8))
cpu_prog_rom2(
	.clock_a(Clock),
	.wren_a(rom2_cs),
	.address_a(dn_addr[12:0]),
	.data_a(dn_data),

	.clock_b(Clock),
	.address_b(rom_addr[12:0]),
	.q_b(rom2_data)
);

// Lupin, Polaris use colour ram but weirdly mapped from C000-DFFF (so does space chaser, but it doesn't invert the output)
wire ScatteredRam = (mod_lupin | mod_polaris);

// 0 - RED, 1 - BLUE, 2 - GREEN
assign color_prom_out = (mod_cosmo | mod_indianbattle) ? {color_prom_out_rom[7:3],color_prom_out_rom[1],color_prom_out_rom[2],color_prom_out_rom[0]} : ScatteredRam ? ~color_prom_out_rom : color_prom_out_rom;

// Cosmo can read/write Colour RAM (5C00-5FFF)
// Scattered ram mapped from C000-DFFF
wire color_ram_wr = mod_cosmo ? (rom_addr[15:10]==6'b010111 & ~CPU_RW_n) : (ScatteredRam | mod_spacechaser) ? (rom_addr[15:13]==3'b110 & ~CPU_RW_n):1'b0;

wire [10:0] cosmo_addr = {1'b0,rom_addr[9:0]};
//wire [10:0] Scattered_addr = {1'd0,rom_addr[12:8],rom_addr[4:0]};
wire [10:0] Scattered_addr = {rom_addr[13:8],rom_addr[4:0]};

wire [7:0]  color_ram_out;
wire [10:0] color_ram_addr = (ScatteredRam | mod_spacechaser) ? Scattered_addr : cosmo_addr;

dpram #(.addr_width_g(11),
	.data_width_g(8))
video_rom(
	.clock_a(Clock),
	.wren_a(vrom_cs | color_ram_wr),
	.address_a(vrom_cs ? dn_addr[10:0] : color_ram_addr),
	.data_a(vrom_cs ? dn_data : Ram_in),
	.q_a(color_ram_out),

	.clock_b(Clock),
	.address_b(color_prom_addr),
	.q_b(color_prom_out_rom)
);
	
always @(rom_addr, rom_data, rom2_data, color_ram_out, ScatteredRam, mod_spacechaser, mod_cosmo, RW_n, Ram_in) begin
	
	Rom_out = 8'b00000000;

	// Lupin, Polaris & others uses C000-DFFF - allow them to read back the color_ram (ScatteredRam)
	if (rom_addr[15]==1'b1) begin
	   if ((ScatteredRam | mod_spacechaser) & rom_addr[14:13]==2'b10) begin
			Rom_out = color_ram_out;
	   end
	end
	else
	begin
		case (rom_addr[15:11])
			5'b00000 : Rom_out = rom_data;
			5'b00001 : Rom_out = rom_data;
			5'b00010 : Rom_out = rom_data;
			5'b00011 : Rom_out = rom_data;
			
			5'b01000 : Rom_out = rom2_data;
			5'b01001 : Rom_out = rom2_data;
			5'b01010 : Rom_out = rom2_data;
			5'b01011 : if (mod_cosmo & (rom_addr[10]==1'b1)) begin
							 Rom_out = color_ram_out;
						  end 
						  else begin
							 Rom_out = rom2_data;
						  end
			default : Rom_out = 8'b00000000;
		endcase
	end
	
end

// Save Polaris Plane position
always @(posedge Clock) begin
	if (rom_addr == 16'b0010000011101010 & ~RW_n) begin
		PlanePos <= Ram_in;
	end;
end

// For Vortex - Read next screen byte (picked up in real hardware in latch to load shifter)
wire [15:0] VortexAddr = Ram_Addr + 1'b1;
wire [7:0]  VortexColour;

assign Vortex_bit = VortexColour[0];


// Hiscore system
// - Shares RAM port with extra Vortex functionality - Vortex has no high score support so no conflict
assign hs_data_out = VortexColour;

dpram #(
	.addr_width_g(13),
	.data_width_g(8)) 
u_ram0(
	.clock_a(Clock),
	.address_a(Ram_Addr[12:0]),
	.data_a(Ram_in),
	.wren_a(~RW_n),
	.q_a(Ram_out),
	
	.clock_b(Clock),
	.address_b(hs_access ? hs_address[12:0] : VortexAddr[12:0]),
	.wren_b(hs_access ? hs_write : 1'b0),
	.data_b(hs_access ? hs_data_in : Ram_in),
	.q_b(VortexColour)
	);
endmodule 
