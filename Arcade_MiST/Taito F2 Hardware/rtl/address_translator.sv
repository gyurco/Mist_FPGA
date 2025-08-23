import system_consts::*;

module address_translator(
    input game_t game,

    input [1:0]  cpu_ds_n,
    input [23:0] cpu_word_addr,
    input        ss_override,

    input [15:0] cfg_addr_rom,
    input [15:0] cfg_addr_rom1,
    input [15:0] cfg_addr_extra_rom,
    input [15:0] cfg_addr_work_ram,
    input [15:0] cfg_addr_screen0,
    input [15:0] cfg_addr_screen1,
    input [15:0] cfg_addr_obj,
    input [15:0] cfg_addr_color,
    input [15:0] cfg_addr_io0,
    input [15:0] cfg_addr_io1,
    input [15:0] cfg_addr_sound,
    input [15:0] cfg_addr_extension,
    input [15:0] cfg_addr_priority,
    input [15:0] cfg_addr_roz,
    input [15:0] cfg_addr_cchip,

    output logic WORKn,
    output logic ROMn,
    output logic EXTRA_ROMn,
    output logic SCREEN0n,
    output logic SCREEN1n,
    output logic COLORn,
    output logic IO0n,
    output logic IO1n,
    output logic OBJECTn,
    output logic SOUNDn,
    output logic PRIORITYn,
    output logic EXTENSIONn,
    output logic CCHIPn,
    output logic GROWL_HACKn,
    output logic PIVOTn,
    output logic SS_SAVEn,
    output logic SS_RESETn,
    output logic SS_VECn
);

function bit match_addr_n(input [23:0] addr, input [15:0] sel);
    bit r;
    r = (addr[23:16] & sel[7:0]) == sel[15:8];
    return ~r;
endfunction


/* verilator lint_off CASEX */

always_comb begin
    WORKn = 1;
    ROMn = 1;
    EXTRA_ROMn = 1;
    SCREEN0n = 1;
    SCREEN1n = 1;
    COLORn = 1;
    PRIORITYn = 1;
    IO0n = 1;
    IO1n = 1;
    OBJECTn = 1;
    SOUNDn = 1;
    SS_SAVEn = 1;
    SS_RESETn = 1;
    SS_VECn = 1;
    EXTENSIONn = 1;
    GROWL_HACKn = 1;
    CCHIPn = 1;
    PIVOTn = 1;

    if (ss_override) begin
        if (~&cpu_ds_n) begin
            casex(cpu_word_addr)
                24'h00000x: begin
                    SS_RESETn = 0;
                end
                24'h00007c: begin
                    SS_VECn = 0;
                end
                24'h00007e: begin
                    SS_VECn = 0;
                end
                24'hff00xx: begin
                    SS_SAVEn = 0;
                end
            endcase
        end
    end

    if (~&cpu_ds_n) begin
        ROMn = match_addr_n(cpu_word_addr, cfg_addr_rom)
                & match_addr_n(cpu_word_addr, cfg_addr_rom1)
                & match_addr_n(cpu_word_addr, cfg_addr_extra_rom);
        EXTRA_ROMn = match_addr_n(cpu_word_addr, cfg_addr_extra_rom);
        WORKn = match_addr_n(cpu_word_addr, cfg_addr_work_ram);
        SCREEN0n = match_addr_n(cpu_word_addr, cfg_addr_screen0);
        SCREEN1n = match_addr_n(cpu_word_addr, cfg_addr_screen1);
        OBJECTn = match_addr_n(cpu_word_addr, cfg_addr_obj);
        COLORn = match_addr_n(cpu_word_addr, cfg_addr_color);
        IO0n = match_addr_n(cpu_word_addr, cfg_addr_io0);
        IO1n = match_addr_n(cpu_word_addr, cfg_addr_io1);
        SOUNDn = match_addr_n(cpu_word_addr, cfg_addr_sound);
        EXTENSIONn = match_addr_n(cpu_word_addr, cfg_addr_extension);
        PRIORITYn = match_addr_n(cpu_word_addr, cfg_addr_priority);
        CCHIPn = match_addr_n(cpu_word_addr, cfg_addr_cchip);
        PIVOTn = match_addr_n(cpu_word_addr, cfg_addr_roz);

        if (game == GAME_GROWL) begin
            GROWL_HACKn = ~(cpu_word_addr[23:16] == 8'h50 && cpu_word_addr[15]);
        end
    end
end
/* verilator lint_on CASEX */


endmodule


