module SuprLoco_CPU (
    input   wire            i_CLK, i_RST_n,
    input   wire            i_PCEN, i_NCEN,

    input   wire            i_WAIT_n, i_INT_n, i_NMI_n,

    output  wire            o_RD_n, o_WR_n, o_IORQ_n, o_MREQ_n, o_M1_n,
    output  wire    [15:0]  o_ADDR,
    output  wire    [7:0]   o_DO,
    input   wire    [7:0]   i_DI,

    input   wire            i_BUSRQ_n,
    output  wire            o_BUSAK_n,

    output  wire            o_RFSH_n,
    output  wire            o_HALT_n
);


///////////////////////////////////////////////////////////
//////  Decrypter
////

wire            decr_en = ~o_ADDR[15] & ~o_MREQ_n;
reg     [7:0]   dd;
wire    [6:0]   decrtable_addr = {o_ADDR[12], o_ADDR[8], o_ADDR[4], o_ADDR[0], o_M1_n, i_DI[5] ^ i_DI[7], i_DI[3] ^ i_DI[7]};
wire    [7:0]   decrtable_data = decr_en ? {dd[7] ^ i_DI[7], i_DI[6], dd[5] ^ i_DI[7], i_DI[4], dd[3] ^ i_DI[7], i_DI[2:0]} : i_DI;

always @(posedge i_CLK) begin
    case(decrtable_addr)
        //OPCODE
        7'd0  :dd<=8'h20; 7'd1  :dd<=8'h00; 7'd2  :dd<=8'ha0; 7'd3  :dd<=8'h80;
        7'd8  :dd<=8'h20; 7'd9  :dd<=8'h00; 7'd10 :dd<=8'ha0; 7'd11 :dd<=8'h80;
        7'd16 :dd<=8'h20; 7'd17 :dd<=8'h00; 7'd18 :dd<=8'ha0; 7'd19 :dd<=8'h80;
        7'd24 :dd<=8'h88; 7'd25 :dd<=8'h08; 7'd26 :dd<=8'h80; 7'd27 :dd<=8'h00;
        7'd32 :dd<=8'h88; 7'd33 :dd<=8'h08; 7'd34 :dd<=8'h80; 7'd35 :dd<=8'h00;
        7'd40 :dd<=8'h20; 7'd41 :dd<=8'h00; 7'd42 :dd<=8'ha0; 7'd43 :dd<=8'h80;
        7'd48 :dd<=8'h88; 7'd49 :dd<=8'h08; 7'd50 :dd<=8'h80; 7'd51 :dd<=8'h00;
        7'd56 :dd<=8'h28; 7'd57 :dd<=8'ha8; 7'd58 :dd<=8'h08; 7'd59 :dd<=8'h88;
        7'd64 :dd<=8'h20; 7'd65 :dd<=8'h00; 7'd66 :dd<=8'ha0; 7'd67 :dd<=8'h80;
        7'd72 :dd<=8'h88; 7'd73 :dd<=8'h08; 7'd74 :dd<=8'h80; 7'd75 :dd<=8'h00;
        7'd80 :dd<=8'h88; 7'd81 :dd<=8'h08; 7'd82 :dd<=8'h80; 7'd83 :dd<=8'h00;
        7'd88 :dd<=8'h20; 7'd89 :dd<=8'h00; 7'd90 :dd<=8'ha0; 7'd91 :dd<=8'h80;
        7'd96 :dd<=8'h88; 7'd97 :dd<=8'h08; 7'd98 :dd<=8'h80; 7'd99 :dd<=8'h00;
        7'd104:dd<=8'h28; 7'd105:dd<=8'ha8; 7'd106:dd<=8'h08; 7'd107:dd<=8'h88;
        7'd112:dd<=8'h20; 7'd113:dd<=8'h00; 7'd114:dd<=8'ha0; 7'd115:dd<=8'h80;
        7'd120:dd<=8'h88; 7'd121:dd<=8'h08; 7'd122:dd<=8'h80; 7'd123:dd<=8'h00;

        //DATA
        7'd4  :dd<=8'ha8; 7'd5  :dd<=8'ha0; 7'd6  :dd<=8'h88; 7'd7  :dd<=8'h80;
        7'd12 :dd<=8'ha8; 7'd13 :dd<=8'ha0; 7'd14 :dd<=8'h88; 7'd15 :dd<=8'h80;
        7'd20 :dd<=8'ha8; 7'd21 :dd<=8'ha0; 7'd22 :dd<=8'h88; 7'd23 :dd<=8'h80;
        7'd28 :dd<=8'ha0; 7'd29 :dd<=8'h80; 7'd30 :dd<=8'ha8; 7'd31 :dd<=8'h88;
        7'd36 :dd<=8'ha0; 7'd37 :dd<=8'h80; 7'd38 :dd<=8'ha8; 7'd39 :dd<=8'h88;
        7'd44 :dd<=8'ha8; 7'd45 :dd<=8'ha0; 7'd46 :dd<=8'h88; 7'd47 :dd<=8'h80;
        7'd52 :dd<=8'ha0; 7'd53 :dd<=8'h80; 7'd54 :dd<=8'ha8; 7'd55 :dd<=8'h88;
        7'd60 :dd<=8'h88; 7'd61 :dd<=8'h80; 7'd62 :dd<=8'h08; 7'd63 :dd<=8'h00;
        7'd68 :dd<=8'ha8; 7'd69 :dd<=8'ha0; 7'd70 :dd<=8'h88; 7'd71 :dd<=8'h80;
        7'd76 :dd<=8'ha0; 7'd77 :dd<=8'h80; 7'd78 :dd<=8'ha8; 7'd79 :dd<=8'h88;
        7'd84 :dd<=8'ha0; 7'd85 :dd<=8'h80; 7'd86 :dd<=8'ha8; 7'd87 :dd<=8'h88;
        7'd92 :dd<=8'ha8; 7'd93 :dd<=8'ha0; 7'd94 :dd<=8'h88; 7'd95 :dd<=8'h80;
        7'd100:dd<=8'ha0; 7'd101:dd<=8'h80; 7'd102:dd<=8'ha8; 7'd103:dd<=8'h88;
        7'd108:dd<=8'h88; 7'd109:dd<=8'h80; 7'd110:dd<=8'h08; 7'd111:dd<=8'h00;
        7'd116:dd<=8'ha8; 7'd117:dd<=8'ha0; 7'd118:dd<=8'h88; 7'd119:dd<=8'h80;
        7'd124:dd<=8'ha0; 7'd125:dd<=8'h80; 7'd126:dd<=8'ha8; 7'd127:dd<=8'h88;
    endcase
end



///////////////////////////////////////////////////////////
//////  CPU
////

T80pa maincpu (
    .RESET_n                    (i_RST_n                    ),
    .CLK                        (i_CLK                      ),
    .CEN_p                      (i_PCEN                     ),
    .CEN_n                      (i_NCEN                     ),
    .WAIT_n                     (i_WAIT_n                   ),
    .INT_n                      (i_INT_n                    ),
    .NMI_n                      (i_NMI_n                    ),
    .RD_n                       (o_RD_n                     ),
    .WR_n                       (o_WR_n                     ),
    .A                          (o_ADDR                     ),
    .DI                         (decrtable_data             ),
    .DO                         (o_DO                       ),
    .IORQ_n                     (o_IORQ_n                   ),
    .M1_n                       (o_M1_n                     ),
    .MREQ_n                     (o_MREQ_n                   ),
    .BUSRQ_n                    (i_BUSRQ_n                  ),
    .BUSAK_n                    (o_BUSAK_n                  ),
    .RFSH_n                     (o_RFSH_n                   ),
    .out0                       (1'b0                       ), //?????
    .HALT_n                     (o_HALT_n                   )
);

endmodule