//============================================================================
//  Copyright (C) 2023 Martin Donlon
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module GA23(
    input clk,

    input ce,
    input ce_pix,

    input paused,

    input reset,

    input mem_cs,
    input mem_wr,
    input mem_rd,
    input io_wr,

    output busy,

    input [15:0] addr,
    input [15:0] cpu_din,
    output reg [15:0] cpu_dout,
    
    output reg [14:0] vram_addr,
    input [15:0] vram_din,
    output reg [15:0] vram_dout,
    output reg vram_we,

    input NL,

    input  [31:0] sdr_data_a,
    output [23:0] sdr_addr_a,
    output        sdr_req_a,
    input         sdr_ack_a,

    input  [31:0] sdr_data_b,
    output [23:0] sdr_addr_b,
    output        sdr_req_b,
    input         sdr_ack_b,

    input  [31:0] sdr_data_c,
    output [23:0] sdr_addr_c,
    output        sdr_req_c,
    input         sdr_ack_c,

    input  [31:0] sdr_data_d,
    output [23:0] sdr_addr_d,
    output        sdr_req_d,
    input         sdr_ack_d,

    output reg vblank,
    output reg vsync,
    output reg hblank,
    output reg hsync,
    output reg color_blank,

    output reg hpulse,
    output reg vpulse,
    output reg hint,

    output reg [10:0] color_out,
    output reg prio_out,

    input [3:0] dbg_en_layers
);


//// VIDEO TIMING
reg [9:0] hcnt, vcnt;
reg [9:0] hint_line;
reg [15:0] misc_reg;

wire [9:0] VE = vcnt ^ {1'b0, {9{NL}}};

always_ff @(posedge clk) begin
    bit _vblank_wide;
    bit _hblank, _vblank;

    if (ce_pix) begin
        hcnt <= hcnt + 10'd1;
        if (hcnt == 10'd469) begin
            hcnt <= 10'd46;
            vcnt <= vcnt + 10'd1;
            if (vcnt == 10'd375) begin
                vcnt <= 10'd114;
            end
        end

        _vblank_wide = vcnt > 10'd367 || vcnt < 10'd144;
        _hblank = hcnt < 10'd102 || hcnt > 10'd421;
        _vblank = vcnt > 10'd375 || vcnt < 10'd136;

        hblank <= _hblank;
        vblank <= _vblank;
        hsync <= hcnt < 10'd71 || hcnt > 10'd454;
        vsync <= vcnt > 10'd114 && vcnt < 10'd125;
        hpulse <= hcnt == 10'd46;
        vpulse <= (vcnt == 10'd124 && hcnt > 10'd260) || (vcnt == 10'd125 && hcnt < 10'd260);
        color_blank <= _hblank | _vblank | misc_reg[0] | (~misc_reg[2] & _vblank_wide);
        hint <= VE == hint_line && hcnt > 10'd422 && ~paused;
    end
end

wire [21:0] rom_addr[4];
wire [31:0] rom_data[4];
wire        rom_req[4];
wire        rom_ack[4];

//// MEMORY ACCESS
reg [2:0] mem_cyc;
reg [3:0] rs_cyc;
reg busy_we;

reg [9:0] x_ofs[4], y_ofs[4];
reg [15:0] control[4];
reg [9:0] rowscroll[4];
reg [9:0] rowselect[4];

wire [14:0] layer_vram_addr[4];
reg layer_load[4];
wire layer_prio[4];
wire [10:0] layer_color[4];
wire layer_enabled[4];
reg [15:0] vram_latch;

reg [1:0] cpu_access_st;
reg cpu_access_we;
reg [15:0] cpu_access_din;

reg [55:0] control_save_0[512];
reg [55:0] control_save_1[512];
reg [55:0] control_save_2[512];
reg [55:0] control_save_3[512];

reg [55:0] control_restore[4];

reg rowscroll_active, rowscroll_pending;

assign busy = |cpu_access_st;
reg prev_access;

always_ff @(posedge clk) begin
    bit [9:0] rs_y;
    if (reset) begin
        mem_cyc <= 0;
        cpu_access_st <= 2'd0;
        vram_we <= 0;
        
        // layer regs
        x_ofs[0] <= 10'd0; x_ofs[1] <= 10'd0; x_ofs[2] <= 10'd0; x_ofs[3] <= 10'd0;
        y_ofs[0] <= 10'd0; y_ofs[1] <= 10'd0; y_ofs[2] <= 10'd0; y_ofs[3] <= 10'd0;
        control[0] <= 16'd0; control[1] <= 16'd0; control[2] <= 16'd0; control[3] <= 16'd0;
        hint_line <= 10'd0;
        misc_reg <= 16'd0;

        rowscroll_pending <= 0;
        rowscroll_active <= 0;

    end else begin
        prev_access <= mem_cs & (mem_rd | mem_wr);
        if (mem_cs & (mem_rd | mem_wr) & ~busy & ~prev_access) begin
            cpu_access_st <= 2'd1;
            cpu_access_we <= mem_wr;
            cpu_access_din <= cpu_din;
        end
        
        vram_we <= 0;

        if (ce) begin
            if (ce_pix) begin
                layer_load[0] <= 0; layer_load[1] <= 0; layer_load[2] <= 0; layer_load[3] <= 0;
                mem_cyc <= mem_cyc + 3'd1;

                if (hpulse) begin
                    mem_cyc <= 3'd7;
                    rowscroll_pending <= 1;
                end
            end

            if (rowscroll_active) begin
                rs_cyc <= rs_cyc + 4'd1;
                case(rs_cyc)
                0: begin
                    rs_y = y_ofs[0] + VE;
                    vram_addr <= 15'h7000 + { ~VE[7], VE[6:0] };
                end
                1: rowscroll[0] <= vram_din[9:0];
                2: begin
                    rs_y = y_ofs[1] + VE;
                    vram_addr <= 15'h7100 + { ~VE[7], VE[6:0] };
                end
                3: rowscroll[1] <= vram_din[9:0];
                4: begin
                    rs_y = y_ofs[2] + VE;
                    vram_addr <= 15'h7200 + { ~VE[7], VE[6:0] };
                end
                5: rowscroll[2] <= vram_din[9:0];
                6: begin
                    rs_y = y_ofs[3] + VE;
                    vram_addr <= 15'h7300 + { ~VE[7], VE[6:0] };
                end
                7: rowscroll[3] <= vram_din[9:0];
                8: begin
                    rs_y = y_ofs[0] + VE;
                    vram_addr <= 15'h7400 + { ~VE[7], VE[6:0] };
                end
                9: rowselect[0] <= vram_din[9:0];
                10: begin
                    rs_y = y_ofs[1] + VE;
                    vram_addr <= 15'h7500 + { ~VE[7], VE[6:0] };
                end
                11: rowselect[1] <= vram_din[9:0];
                12: begin
                    rs_y = y_ofs[2] + VE;
                    vram_addr <= 15'h7600 + { ~VE[7], VE[6:0] };
                end
                13: rowselect[2] <= vram_din[9:0];
                14: begin
                    rs_y = y_ofs[3] + VE;
                    vram_addr <= 15'h7700 + { ~VE[7], VE[6:0] };
                end
                15: begin
                    rowselect[3] <= vram_din[9:0];
                    rowscroll_active <= 0;
                end
                endcase
 
            end else begin
                if (ce_pix) begin
                    case(mem_cyc)
                        3'd0: begin
                            vram_addr <= layer_vram_addr[0];
                        end
                        3'd2: begin
                            vram_addr <= layer_vram_addr[1];
                        end
                        3'd4: begin
                            vram_addr <= layer_vram_addr[2];
                        end
                        3'd6: begin
                            vram_addr <= layer_vram_addr[3];
                        end
                        default: begin
                            if (cpu_access_st == 2'd1) begin
                                vram_addr <= addr[15:1];
                                vram_we <= cpu_access_we;
                                vram_dout <= cpu_access_din;
                                cpu_access_st <= 2'd2;
                            end
                        end
                    endcase

                    prio_out <= layer_prio[0] | layer_prio[1] | layer_prio[2] | layer_prio[3];

                    // determine base opaque color
                    color_out <= layer_color[3];

                    // override with transparent
                    if (|layer_color[0][3:0]) begin
                        color_out <= layer_color[0];
                    end else if (|layer_color[1][3:0]) begin
                        color_out <= layer_color[1];
                    end else if (|layer_color[2][3:0]) begin
                        color_out <= layer_color[2];
                    end

                end else if (ce) begin
                    case(mem_cyc)
                        3'd1: begin
                            vram_addr[0] <= 1;
                            vram_latch <= vram_din;
                            layer_load[0] <= 1;
                        end
                        3'd3: begin
                            vram_addr[0] <= 1;
                            vram_latch <= vram_din;
                            layer_load[1] <= 1;
                        end
                        3'd5: begin
                            vram_addr[0] <= 1;
                            vram_latch <= vram_din;
                            layer_load[2] <= 1;
                        end
                        3'd7: begin
                            vram_addr[0] <= 1;
                            vram_latch <= vram_din;
                            layer_load[3] <= 1;
                        end
                        default: begin
                            if (cpu_access_st == 2'd2) begin
                                cpu_access_st <= 2'd0;
                                cpu_access_we <= 0;
                                cpu_dout <= vram_din;
                            end
                            
                            if (rowscroll_pending && cpu_access_st == 2'd0) begin
                                rowscroll_pending <= 0;
                                rowscroll_active <= 1;
                                rs_cyc <= 4'd0;
                            end
                        end
                    endcase
                end
            end
        end

        if (io_wr) begin
            case(addr[7:0])
            'h80: y_ofs[0][9:0] <= cpu_din[9:0];
            'h82: x_ofs[0][9:0] <= cpu_din[9:0];
            
            'h84: y_ofs[1][9:0] <= cpu_din[9:0];
            'h86: x_ofs[1][9:0] <= cpu_din[9:0];
            
            'h88: y_ofs[2][9:0] <= cpu_din[9:0];
            'h8a: x_ofs[2][9:0] <= cpu_din[9:0];

            'h8c: y_ofs[3][9:0] <= cpu_din[9:0];
            'h8e: x_ofs[3][9:0] <= cpu_din[9:0];

            'h90: control[0] <= cpu_din;
            'h92: control[1] <= cpu_din;
            'h94: control[2] <= cpu_din;
            'h96: control[3] <= cpu_din;

            'h98: misc_reg <= cpu_din;
            'h9e: hint_line[9:0] <= cpu_din[9:0];
            endcase
        end

`ifdef CTRL_SAVE
        if (hcnt == 10'd104 && ~paused) begin // end of hblank
            control_save_0[vcnt] <= { y_ofs[0], x_ofs[0], control[0], rowscroll[0] };
            control_save_1[vcnt] <= { y_ofs[1], x_ofs[1], control[1], rowscroll[1] };
            control_save_2[vcnt] <= { y_ofs[2], x_ofs[2], control[2], rowscroll[2] };
            control_save_3[vcnt] <= { y_ofs[3], x_ofs[3], control[3], rowscroll[3] };
        end else if (paused) begin
            control_restore[0] <= control_save_0[vcnt];
            control_restore[1] <= control_save_1[vcnt];
            control_restore[2] <= control_save_2[vcnt];
            control_restore[3] <= control_save_3[vcnt];
        end
`endif
    end
end


assign rom_data[0] = sdr_data_a;
assign sdr_addr_a = REGION_TILE.base_addr[23:0] | rom_addr[0];
assign sdr_req_a = rom_req[0];
assign rom_ack[0] = sdr_ack_a;

assign rom_data[1] = sdr_data_b;
assign sdr_addr_b = REGION_TILE.base_addr[23:0] | rom_addr[1];
assign sdr_req_b = rom_req[1];
assign rom_ack[1] = sdr_ack_b;

assign rom_data[2] = sdr_data_c;
assign sdr_addr_c = REGION_TILE.base_addr[23:0] | rom_addr[2];
assign sdr_req_c = rom_req[2];
assign rom_ack[2] = sdr_ack_c;

assign rom_data[3] = sdr_data_d;
assign sdr_addr_d = REGION_TILE.base_addr[23:0] | rom_addr[3];
assign sdr_req_d = rom_req[3];
assign rom_ack[3] = sdr_ack_d;

//// LAYERS
generate
	genvar i;
    for(i = 0; i < 4; i = i + 1 ) begin : generate_layer
        wire [9:0] _y_ofs = paused ? control_restore[i][55:46] : y_ofs[i];
        wire [9:0] _x_ofs = paused ? control_restore[i][45:36] : x_ofs[i];
        wire [15:0] _control = paused ? control_restore[i][35:20] : control[i];
        wire [9:0] _rowselect = paused ? control_restore[i][19:10] : rowselect[i];
        wire [9:0] _rowscroll = paused ? control_restore[i][9:0] : rowscroll[i];

        // TODO: rowselect?

        ga23_layer layer(
            .clk(clk),
            .ce_pix(ce_pix),

            .NL(NL),

            .control(_control),

            .x_base(_x_ofs + {hcnt[9:3] ^ {7{NL}}, 3'd0}),
            .y_base(_y_ofs + VE),
            .rowscroll(_rowscroll),
            .rowselect(_rowselect),

            .vram_addr(layer_vram_addr[i]),

            .load(layer_load[i]),
            .attrib(vram_din),
            .index(vram_latch),

            .color_out(layer_color[i]),
            .prio_out(layer_prio[i]),
            .color_enabled(layer_enabled[i]),

            .sdr_addr(rom_addr[i]),
            .sdr_data(rom_data[i]),
            .sdr_req(rom_req[i]),
            .sdr_ack(rom_ack[i]),

            .dbg_enabled(dbg_en_layers[i])
        );
    end
endgenerate
endmodule
