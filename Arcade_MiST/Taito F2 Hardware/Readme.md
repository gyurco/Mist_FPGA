# Taito F2 System MiSTer Core

This is an FPGA implementation of the Taito F2 arcade system for the MiSTer platform. The Taito F2 system was used for arcade games from the late 1980s to early 1990s and featured advanced graphics capabilities including sprite scaling, multiple scroll layers, rotation, zoom and ADPCM sample playback.

The [F1](https://www.system16.com/hardware.php?id=662) and [F2](https://www.system16.com/hardware.php?id=661) System 16 pages both cover this hardware. It's unclear what the distinction is between them or where the naming comes from since the PCBs do not contain any markings with either name.

## Supported Games

The following games are currently supported by this core:

### Fully Implemented
- **Cameltry** (1989) - Unique ball-rolling puzzle game with rotatable mazes
- **Dino Rex** (1992) - Prehistoric fighting game with large dinosaur sprites
- **Don Doko Don** (1989) - Platform action game featuring hammer-wielding characters
- **Thunder Fox** (1990) - Side scrolling run and gun
- **Drift Out** (1991) - Rally racing game with overhead perspective
- **Final Blow** (1989) - Boxing game with detailed fighter animations
- **Growl** (1990) - Beat-em-up action game set in an African safari
- **Gun Frontier** (1990) - Vertical scrolling shoot-em-up
- **Liquid Kids** (1990) - Platform game featuring water-based gameplay mechanics
- **Mega Blast** (1989) - Space shooter with scaling sprite effects
- **The Ninja Kids** (1990) - Action platformer with ninja characters
- **PuLiRuLa** (1991) - Quirky action game with magical transformations
- **Solitary Fighter** (1991) - One-on-one fighting game
- **Super Space Invaders '91** (1990) - Enhanced remake of the classic Space Invaders

## System Components

### CPU Architecture
- **Main CPU**: Motorola 68000 running at 12MHz
- **Audio CPU**: Zilog Z80 for sound processing
- **Sound Chips**: Yamaha YM2610 (OPNB) for FM synthesis and ADPCM playback

### Graphics Subsystem
- **TC0100SCN**: Tilemapping
- **TC0200OBJ**: Sprite rendering with scaling capabilities
- **TC0110PCR**: Two input priority and palette
- **TC0360PRI**: Three input priority mixer with blending support
- **TC0260DAR**: Palette and DAC
- **TC0430GRW**: Tilemapping with rotation and scaling

### Audio Processing
- **TC0140SYT**: Sound communication interface between CPUs
- **YM2610**: 4-channel FM + 6-channel ADPCM-A + 1-channel ADPCM-B

## Credits

Many people, knowingly or not, contributed to this work.

- MAME project and all those who contributed to the F2 driver: David Graves, Bryan McPhail, Brad Oliver, Andrew Prime, Brian Troha, Nicola Salmoria
- @sorgelig, for developing and maintaining MiSTer.
- @jotego, for the YM2610 implementation, various utility modules and lots of examples of 68000 usage.
- @ArtemioUrbina, for their support building MDfourier tests.
- The MiSTer FPGA discord server for support, advice and testing.

