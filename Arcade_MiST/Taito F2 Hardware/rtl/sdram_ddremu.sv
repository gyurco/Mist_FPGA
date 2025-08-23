//
// sdram.v
//
// sdram controller implementation for the MiST board
// https://github.com/mist-devel/mist-board
// 
// Copyright (c) 2013 Till Harbaum <till@harbaum.org> 
// Copyright (c) 2019-2022 Gyorgy Szombathelyi
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version. 
// 
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//

module sdram_ddremu (

	// interface to the MT48LC16M16 chip
	inout  reg [15:0] SDRAM_DQ,   // 16 bit bidirectional data bus
	output reg [12:0] SDRAM_A,    // 13 bit multiplexed address bus
	output reg        SDRAM_DQML, // two byte masks
	output reg        SDRAM_DQMH, // two byte masks
	output reg [1:0]  SDRAM_BA,   // two banks
	output            SDRAM_nCS,  // a single chip select
	output            SDRAM_nWE,  // write enable
	output            SDRAM_nRAS, // row address select
	output            SDRAM_nCAS, // columns address select

	// cpu/chipset interface
	input             init_n,     // init signal after FPGA config to initialize RAM
	input             sdr_clk,    // sdram clock
	input             clk,

	input      [24:0] addr,
	input      [63:0] wdata,
	output reg [63:0] rdata,
	input             read,
	input             write,
	input       [7:0] burstcnt,
	input       [7:0] byteenable,
	output            busy,
	output reg        rdata_ready
);

parameter  MHZ = 16'd80; // 80 MHz default clock, set it to proper value to calculate refresh rate

localparam RASCAS_DELAY   = 3'd3;   // tRCD=20ns -> 2 cycles@<100MHz
localparam BURST_LENGTH   = 3'b000; // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE    = 1'b0;   // 0=sequential, 1=interleaved
localparam CAS_LATENCY    = 3'd3;   // 2/3 allowed
localparam OP_MODE        = 2'b00;  // only 00 (standard operation) allowed
localparam NO_WRITE_BURST = 1'b1;   // 0= write burst enabled, 1=only single access write

localparam MODE = { 3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH}; 

// 64ms/8192 rows = 7.8us
localparam RFRSH_CYCLES = 16'd78*MHZ/4'd10;

// ---------------------------------------------------------------------
// ------------------------ cycle state machine ------------------------
// ---------------------------------------------------------------------

localparam STATE_RAS       = 4'd0;   // first state in cycle
localparam STATE_CAS0      = 4'd3;
localparam STATE_CAS1      = 4'd4;
localparam STATE_CAS2      = 4'd5;
localparam STATE_CAS3      = 4'd6;
localparam STATE_LAST      = 4'd7;

reg [2:0] t;

always @(posedge sdr_clk) begin
	t <= t + 1'd1;
	if (t == STATE_LAST) t <= STATE_RAS;
	if (read_r && t == STATE_CAS3 && (burstcnt_reg !=0 || read_seq[4])) t<=STATE_CAS3;
end

// ---------------------------------------------------------------------
// --------------------------- startup/reset ---------------------------
// ---------------------------------------------------------------------

// wait 1ms (32 8Mhz cycles) after FPGA config is done before going
// into normal operation. Initialize the ram in the last 16 reset cycles (cycles 15-0)
reg [4:0]  reset;
reg        init = 1'b1;
always @(posedge sdr_clk, negedge init_n) begin
	if(!init_n) begin
		reset <= 5'h1f;
		init <= 1'b1;
	end else begin
		if((t == STATE_LAST) && (reset != 0)) reset <= reset - 5'd1;
		init <= !(reset == 0);
	end
end

// ---------------------------------------------------------------------
// ------------------ generate ram control signals ---------------------
// ---------------------------------------------------------------------

// all possible commands
localparam CMD_INHIBIT         = 4'b1111;
localparam CMD_NOP             = 4'b0111;
localparam CMD_ACTIVE          = 4'b0011;
localparam CMD_READ            = 4'b0101;
localparam CMD_WRITE           = 4'b0100;
localparam CMD_BURST_TERMINATE = 4'b0110;
localparam CMD_PRECHARGE       = 4'b0010;
localparam CMD_AUTO_REFRESH    = 4'b0001;
localparam CMD_LOAD_MODE       = 4'b0000;

reg [3:0]  sd_cmd;   // current command sent to sd ram
reg [15:0] sd_din;
// drive control signals according to current command
assign SDRAM_nCS  = sd_cmd[3];
assign SDRAM_nRAS = sd_cmd[2];
assign SDRAM_nCAS = sd_cmd[1];
assign SDRAM_nWE  = sd_cmd[0];

reg [11:0] refresh_cnt;
wire       need_refresh = refresh_cnt >= RFRSH_CYCLES;

reg [63:0] wdata_reg, rdata_reg;
reg  [9:0] burstcnt_reg;
reg  [7:0] byteenable_reg;
reg        read_r, write_r;
reg  [9:1] casaddr;
reg        read_d, write_d;
reg        rdy, rdy_d;
reg        busy_next;
reg  [4:0] read_seq;
reg  [1:0] reccnt;

wire       read_up = ~read_d & read;
wire       write_up = ~write_d & write;

assign     busy = read_up | write_up | busy_next;

always @(posedge sdr_clk) begin

	// permanently latch ram data to reduce delays
	sd_din <= SDRAM_DQ;
	SDRAM_DQ <= 16'bZZZZZZZZZZZZZZZZ;
	{ SDRAM_DQMH, SDRAM_DQML } <= 2'b11;
	sd_cmd <= CMD_NOP;  // default: idle
	refresh_cnt <= refresh_cnt + 1'd1;

	if(init) begin
		busy_next <= 0;
		refresh_cnt <= 0;
		// initialization takes place at the end of the reset phase
		if(t == STATE_RAS) begin

			if(reset == 15) begin
				sd_cmd <= CMD_PRECHARGE;
				SDRAM_A[10] <= 1'b1;      // precharge all banks
			end

			if(reset == 10 || reset == 8) begin
				sd_cmd <= CMD_AUTO_REFRESH;
			end

			if(reset == 2) begin
				sd_cmd <= CMD_LOAD_MODE;
				SDRAM_A <= MODE;
				SDRAM_BA <= 2'b00;
			end
		end
	end else begin
		read_d <= read;
		write_d <= write;
		if (read_up | write_up) busy_next <= 1;
		// RAS phase
		// bank 0,1
		if(t == STATE_RAS) begin
			read_r <= 0;
			write_r <= 0;
			if (need_refresh) begin
				sd_cmd <= CMD_AUTO_REFRESH;
				refresh_cnt <= refresh_cnt - RFRSH_CYCLES;
			end else if (busy) begin
				SDRAM_A <= addr[22:10];
				SDRAM_BA <= addr[24:23];
				sd_cmd <= CMD_ACTIVE;
				wdata_reg <= wdata;
				burstcnt_reg <= { burstcnt, 2'b00 };
				byteenable_reg <= byteenable;
				casaddr <= addr[9:1];
				read_r <= 0;
				write_r <= 0;
				if (write)
					write_r <= write;
				else
					read_r <= read;
				busy_next <= 0;
				read_seq <= 0;
				reccnt <= 0;
			end
		end

		// read continously
		if(t >= STATE_CAS0 && t <= STATE_CAS3 && read_r) begin
			if (burstcnt_reg != 0) begin
				sd_cmd <= CMD_READ;
				SDRAM_A <= { 4'b0000, casaddr };
				casaddr <= casaddr + 1'd1;
				burstcnt_reg <= burstcnt_reg - 1'd1;
				if (burstcnt_reg == 1) SDRAM_A[10] <= 1; // auto precharge on the last read
				read_seq <= {read_seq[3:0], 1'b1};
			end else
				read_seq <= {read_seq[3:0], 1'b0};

			if (read_seq[0]) {SDRAM_DQMH, SDRAM_DQML} <= 2'b00;
			if (read_seq[4]) begin
				rdata_reg <= {sd_din, rdata_reg[63:16]};
				reccnt <= reccnt + 1'd1;
				if (reccnt == 3) begin
					rdy <= ~rdy;
					rdata <= {sd_din, rdata_reg[63:16]};
				end
			end				
		end

		// write
		if(t >= STATE_CAS0 && t <= STATE_CAS3 && write_r) begin
			burstcnt_reg <= burstcnt_reg - 1'd1;
			wdata_reg <= {16'd0, wdata_reg[63:16]};
			byteenable_reg <= {2'b11, byteenable_reg[7:2]};
			casaddr <= casaddr + 1'd1;
			sd_cmd <= CMD_WRITE;
			SDRAM_A <= { 4'b0000, casaddr };
			if (burstcnt_reg == 1) SDRAM_A[10] = 1; // auto precharge
			SDRAM_DQ <= wdata_reg[15:0];
			{SDRAM_DQMH, SDRAM_DQML} <= ~byteenable_reg[1:0];
		end
	end
end

always @(posedge clk) begin
	rdata_ready <= 0;
	rdy_d <= rdy;
	if (rdy_d ^ rdy)rdata_ready <= 1;
end

endmodule
