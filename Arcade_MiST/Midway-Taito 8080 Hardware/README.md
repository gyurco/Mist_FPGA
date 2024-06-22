# Space Invaders Board

Space Invaders is a classic arcade game. However, the same hardware with different sound boards, and slight modifications was used on many many games.

## Credits

Original Authors:
* Daniel Wallner
* Mike J
* Paul Walsh
MiST and MiSTer Port:
* Gehstock
* Gyurco
* David Woods
* Mike Coates
* Shane Lynch (Gun support)
* Alan Steremberg

## Scripts and Such

### Color Overlay

The Midway games often shipped with a plastic color overlay to add color to the games. The Taito boards had color overlay hardware. This included two roms (one for each direction of cocktail games) that added color in a fixed position on the screen. The Taito rom was a digital version of the plastic overlay. Included is a python script that converts the MAME .lay files into Taito color overlay rom format. All games that had plastic overlays now have color roms included.

### Graphic Overlays

Many games were enhanced with 1/2 silvered mirrors and fancy graphics. Some games like 280Z ZZap even had a toy car in view. There is a script that will convert a PNG into raw hex codes to include in the MRA file. 