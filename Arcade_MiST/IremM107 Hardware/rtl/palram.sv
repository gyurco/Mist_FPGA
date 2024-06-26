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

module palram(
    input clk,

    input ce_pix,

    input [15:0] vid_ctrl,
    input dma_busy,
    input color_blank_in,
    input vblank_in,
    input hblank_in,
    input vsync_in,
    input hsync_in,


    input [9:0] cpu_addr,

    input [12:0] ga21_addr,
    input        ga21_we,
    input        ga21_req,
    
    input [10:0] obj_color,
    input        obj_prio,
    input        obj_active,

    input [10:0] pf_color,
    input        pf_prio,

    input [15:0] din,
    output [15:0] dout,

    output reg [15:0] rgb_out,
    output reg vblank_out,
    output reg hblank_out,
    output reg vsync_out,
    output reg hsync_out
);

wire obj_pal_bank = 0; // TODO ~vid_ctrl[13] & obj_prio;
wire obj_avail = obj_active; // TODO ~vid_ctrl[7] & obj_active;

wire n_sela = ~dma_busy & (
    ( obj_prio & obj_avail ) |
    ( ~obj_prio & pf_prio & obj_avail ) |
    ( vid_ctrl[12] ) |
    ga21_req
);

wire selb = ~dma_busy & ~ga21_req & ~vid_ctrl[12];

wire [1:0] sel = { selb, ~n_sela };

wire [12:0] full_cpu_addr = { vid_ctrl[10:8], cpu_addr[9:0] };
wire [12:0] obj_addr = { vid_ctrl[15], obj_pal_bank, obj_color };
wire [12:0] pf_addr = { vid_ctrl[15], vid_ctrl[14], pf_color };

wire we = sel == 0 ? ga21_we : sel == 1 ? ga21_we : 1'b0;
wire [12:0] selected_addr = sel == 0 ? full_cpu_addr :
                            sel == 1 ? ga21_addr :
                            sel == 2 ? obj_addr :
                            pf_addr;

singleport_unreg_ram #(.widthad(13), .width(16), .name("PALRAM")) ram
(
    .clock(clk),
    .address(selected_addr),
    .q(dout),
    .wren(we),
    .data(din)
);

reg cb;
always_ff @(posedge clk) begin
    if (ce_pix) begin
        rgb_out <= color_blank_in ? 16'd0 : dout;
        vblank_out <= vblank_in;
        hblank_out <= hblank_in;
        vsync_out <= vsync_in;
        hsync_out <= hsync_in;
    end
end

endmodule