package system_consts;
    parameter int SSIDX_GLOBAL = 0;
    parameter int SSIDX_SCN_RAM_0 = 1;
    parameter int SSIDX_COLOR_RAM = 2;
    parameter int SSIDX_CPU_RAM = 3;
    parameter int SSIDX_SCN_0 = 4;
    parameter int SSIDX_OBJ_RAM = 5;
    parameter int SSIDX_AUDIO_RAM = 6;
    parameter int SSIDX_Z80 = 7;
    parameter int SSIDX_YM = 8;
    parameter int SSIDX_EXTENSION_RAM = 9;
    parameter int SSIDX_PRIORITY = 10;
    parameter int SSIDX_190FMC = 11;
    parameter int SSIDX_CCHIP_RAM = 12;
    parameter int SSIDX_PIVOT_CTRL = 13;
    parameter int SSIDX_PIVOT_RAM = 14;
    parameter int SSIDX_SCN_MUX_RAM = 15;
    parameter int SSIDX_SCN_1 = 16;
    parameter int SSIDX_480SCP = 17;


    parameter bit [31:0] SS_DDR_BASE       = 32'h3E00_0000;
    parameter bit [31:0] OBJ_FB_DDR_BASE   = 32'h3800_0000;
    parameter bit [31:0] OBJ_DATA_DDR_BASE = 32'h3810_0000;
    parameter bit [31:0] DOWNLOAD_DDR_BASE = 32'h3000_0000;

    // SDR channel 1
    parameter bit [31:0] CPU_ROM_SDR_BASE       = 32'h0000_0000;
    parameter bit [31:0] CPU_EXTRA_ROM_SDR_BASE = 32'h0040_0000;
    parameter bit [31:0] AUDIO_ROM_SDR_BASE     = 32'h0060_0000;
    parameter bit [31:0] ADPCMA_ROM_SDR_BASE    = 32'h0080_0000;
    parameter bit [31:0] ADPCMB_ROM_SDR_BASE    = 32'h00a0_0000;
    parameter bit [31:0] SCN0_ROM_SDR_BASE      = 32'h00c0_0000;

    // SDR channel 2
    parameter bit [31:0] SCN1_ROM_SDR_BASE      = 32'h0000_0000;
    parameter bit [31:0] PIVOT_ROM_SDR_BASE     = 32'h0080_0000;

    typedef enum bit [3:0] {
        STORAGE_SDR_CH1,
        STORAGE_SDR_CH2,
        STORAGE_DDR,
        STORAGE_BLOCK
    } region_storage_t;

    typedef enum bit [3:0] {
        ENCODING_NORMAL
    } region_encoding_t;

    typedef struct packed {
        bit [31:0] base_addr;
        region_storage_t storage;
        region_encoding_t encoding;
    } region_t;

    parameter region_t REGION_CPU_ROM       = '{ base_addr:CPU_ROM_SDR_BASE,       storage:STORAGE_SDR_CH1,   encoding:ENCODING_NORMAL };
    parameter region_t REGION_SCN0          = '{ base_addr:SCN0_ROM_SDR_BASE,      storage:STORAGE_SDR_CH1,   encoding:ENCODING_NORMAL };
    parameter region_t REGION_OBJ0          = '{ base_addr:OBJ_DATA_DDR_BASE,      storage:STORAGE_DDR,       encoding:ENCODING_NORMAL };
    parameter region_t REGION_AUDIO_ROM     = '{ base_addr:AUDIO_ROM_SDR_BASE,     storage:STORAGE_SDR_CH1,   encoding:ENCODING_NORMAL };
    parameter region_t REGION_ADPCMA        = '{ base_addr:ADPCMA_ROM_SDR_BASE,    storage:STORAGE_SDR_CH1,   encoding:ENCODING_NORMAL };
    parameter region_t REGION_ADPCMB        = '{ base_addr:ADPCMB_ROM_SDR_BASE,    storage:STORAGE_SDR_CH1,   encoding:ENCODING_NORMAL };
    parameter region_t REGION_PIVOT         = '{ base_addr:PIVOT_ROM_SDR_BASE,     storage:STORAGE_SDR_CH2,   encoding:ENCODING_NORMAL };
    parameter region_t REGION_SCN1          = '{ base_addr:SCN1_ROM_SDR_BASE,      storage:STORAGE_SDR_CH2,   encoding:ENCODING_NORMAL };
    parameter region_t REGION_CPU_EXTRA_ROM = '{ base_addr:CPU_EXTRA_ROM_SDR_BASE, storage:STORAGE_SDR_CH1,   encoding:ENCODING_NORMAL };

    parameter region_t LOAD_REGIONS[9] = '{
        REGION_CPU_ROM,
        REGION_SCN0,
        REGION_OBJ0,
        REGION_AUDIO_ROM,
        REGION_ADPCMA,
        REGION_ADPCMB,
        REGION_PIVOT,
        REGION_SCN1,
        REGION_CPU_EXTRA_ROM
    };

    typedef enum bit [7:0] {
        GAME_FINALB,
        GAME_DONDOKOD,
        GAME_MEGAB,
        GAME_THUNDFOX,
        GAME_CAMELTRY,
        GAME_QTORIMON,
        GAME_LIQUIDK,
        GAME_QUIZHQ,
        GAME_SSI,
        GAME_GUNFRONT,
        GAME_GROWL,
        GAME_MJNQUEST,
        GAME_FOOTCHMP,
        GAME_KOSHIEN,
        GAME_YUYUGOGO,
        GAME_NINJAK,
        GAME_SOLFIGTR,
        GAME_QZQUEST,
        GAME_PULIRULA,
        GAME_METALB,
        GAME_QZCHIKYU,
        GAME_YESNOJ,
        GAME_DEADCONX,
        GAME_DINOREX,
        GAME_QJINSEI,
        GAME_QCRAYON,
        GAME_QCRAYON2,
        GAME_DRIFTOUT,
        GAME_DEADCONXJ
    } game_t;

    typedef struct packed {
        game_t    game;
        bit [7:0] unused;
    } board_cfg_t;

endpackage


