library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity rom_sprite_l is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(11 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of rom_sprite_l is
	type rom is array(0 to  4095) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"AA",X"80",X"2A",X"A0",X"1A",X"A9",X"D5",X"55",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"55",X"40",X"55",X"55",
		X"D5",X"7F",X"05",X"FF",X"05",X"00",X"14",X"00",X"55",X"50",X"00",X"00",X"00",X"00",X"00",X"00",
		X"F5",X"00",X"C0",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"02",X"81",X"0A",X"05",X"28",X"15",X"2A",X"AA",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"42",X"80",X"50",X"A0",X"54",X"28",X"AA",X"A8",
		X"AF",X"EF",X"2A",X"AA",X"28",X"15",X"0A",X"05",X"02",X"81",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FB",X"FA",X"AA",X"A8",X"54",X"28",X"50",X"A0",X"42",X"80",X"00",X"00",X"00",X"00",X"00",X"00",
		X"AA",X"AA",X"A5",X"55",X"9A",X"AA",X"9A",X"F7",X"69",X"35",X"A6",X"3D",X"9A",X"3D",X"28",X"0D",
		X"AA",X"AA",X"55",X"56",X"AA",X"A9",X"7C",X"FA",X"70",X"3E",X"F0",X"4D",X"F0",X"FD",X"C0",X"3D",
		X"00",X"05",X"00",X"05",X"00",X"26",X"00",X"26",X"00",X"05",X"00",X"05",X"00",X"01",X"00",X"01",
		X"40",X"4D",X"40",X"FD",X"60",X"3D",X"60",X"4D",X"40",X"FD",X"40",X"3D",X"00",X"4C",X"00",X"FC",
		X"AA",X"AA",X"A5",X"55",X"9A",X"AA",X"9A",X"00",X"69",X"00",X"A6",X"00",X"9A",X"00",X"28",X"00",
		X"AA",X"AA",X"99",X"56",X"AA",X"A9",X"00",X"FA",X"00",X"3E",X"00",X"4D",X"00",X"FD",X"00",X"3D",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"47",X"00",X"FD",X"00",X"3D",X"00",X"47",X"00",X"FD",X"00",X"3D",X"00",X"4C",X"00",X"FC",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"02",X"00",X"08",X"00",X"28",X"C0",X"AB",X"08",X"2E",X"A0",X"BA",X"80",X"E2",X"00",
		X"00",X"03",X"00",X"0C",X"00",X"30",X"00",X"C0",X"05",X"00",X"05",X"00",X"10",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"10",X"00",X"17",X"00",X"16",X"00",X"16",X"00",X"06",X"00",X"05",X"00",X"05",X"00",X"01",
		X"41",X"00",X"75",X"00",X"65",X"00",X"65",X"00",X"A4",X"00",X"94",X"00",X"94",X"00",X"90",X"00",
		X"00",X"02",X"00",X"02",X"00",X"0E",X"00",X"0E",X"00",X"02",X"00",X"02",X"00",X"00",X"00",X"00",
		X"A0",X"00",X"A0",X"00",X"EC",X"00",X"EC",X"00",X"A0",X"00",X"A0",X"00",X"80",X"00",X"80",X"00",
		X"00",X"00",X"10",X"00",X"05",X"00",X"05",X"00",X"00",X"C0",X"00",X"30",X"00",X"0C",X"00",X"03",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"E2",X"00",X"BA",X"80",X"2E",X"A0",X"AB",X"08",X"28",X"C0",X"08",X"00",X"02",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"05",X"40",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"02",X"AA",X"0A",X"A0",
		X"55",X"7F",X"05",X"40",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FF",X"FE",X"0A",X"A0",X"02",X"AA",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"5D",X"55",X"4D",X"55",X"5D",X"57",X"4D",X"5E",X"5D",X"5F",X"4D",X"5B",X"5F",X"EE",X"4C",X"FB",
		X"55",X"55",X"AA",X"A8",X"FF",X"FC",X"A9",X"70",X"AA",X"5C",X"C0",X"17",X"C0",X"00",X"B0",X"00",
		X"5C",X"3E",X"4C",X"03",X"5C",X"00",X"4C",X"00",X"5C",X"00",X"4C",X"00",X"5C",X"00",X"40",X"00",
		X"E0",X"00",X"A9",X"00",X"29",X"00",X"16",X"40",X"01",X"A0",X"00",X"A0",X"00",X"0C",X"00",X"03",
		X"5D",X"55",X"4D",X"55",X"5D",X"57",X"47",X"52",X"5D",X"50",X"4D",X"50",X"5C",X"00",X"4C",X"00",
		X"55",X"55",X"AA",X"A8",X"FF",X"FC",X"A9",X"70",X"AA",X"5C",X"00",X"17",X"00",X"00",X"00",X"00",
		X"5C",X"00",X"4C",X"00",X"5C",X"00",X"4C",X"00",X"5C",X"00",X"4C",X"00",X"5C",X"00",X"40",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"80",X"0C",X"20",X"03",X"E8",X"23",X"9A",X"0A",X"66",X"02",X"99",X"00",X"A6",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"00",X"40",X"00",
		X"00",X"09",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"5C",X"00",X"5C",X"00",X"F7",X"00",X"0D",X"40",X"01",X"40",X"00",X"20",X"00",X"08",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"AA",X"80",X"0A",X"A8",X"3D",X"55",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"3C",X"00",X"57",X"40",
		X"FA",X"AA",X"3D",X"55",X"0A",X"A8",X"AA",X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"55",X"5A",X"57",X"40",X"3C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"2A",X"01",X"88",X"85",X"AA",X"29",X"88",X"BA",X"2A",X"EF",X"08",X"BA",X"02",X"6F",X"00",X"AA",
		X"40",X"A8",X"52",X"22",X"68",X"AA",X"AE",X"22",X"FB",X"A8",X"AE",X"20",X"F9",X"80",X"AA",X"00",
		X"00",X"0F",X"00",X"07",X"00",X"03",X"00",X"03",X"00",X"03",X"00",X"0F",X"00",X"1D",X"00",X"11",
		X"F0",X"00",X"D0",X"00",X"C0",X"00",X"C0",X"00",X"C0",X"00",X"F0",X"00",X"74",X"00",X"44",X"00",
		X"00",X"01",X"18",X"BC",X"0D",X"A0",X"01",X"66",X"0F",X"BB",X"3E",X"39",X"2A",X"D8",X"06",X"78",
		X"80",X"10",X"AE",X"20",X"FA",X"41",X"C7",X"C4",X"96",X"38",X"66",X"AF",X"49",X"6A",X"26",X"3C",
		X"C6",X"4A",X"56",X"F6",X"39",X"C9",X"32",X"D8",X"0E",X"4B",X"06",X"4A",X"30",X"81",X"04",X"08",
		X"A9",X"8C",X"F9",X"95",X"E1",X"EC",X"56",X"44",X"3A",X"08",X"90",X"10",X"61",X"20",X"68",X"00",
		X"00",X"42",X"00",X"D2",X"00",X"14",X"00",X"00",X"00",X"04",X"00",X"AE",X"00",X"02",X"00",X"00",
		X"2A",X"7E",X"A6",X"89",X"57",X"E9",X"E8",X"EA",X"E8",X"7A",X"ED",X"DF",X"E9",X"BF",X"60",X"3E",
		X"00",X"08",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"3F",X"A9",X"03",X"21",X"25",X"24",X"14",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"6A",X"96",X"6E",X"A9",X"AB",X"98",X"E2",X"E6",X"57",X"E8",X"6A",X"DA",X"62",X"D5",X"AA",X"AE",
		X"52",X"00",X"03",X"00",X"4F",X"00",X"68",X"00",X"04",X"00",X"A0",X"00",X"80",X"00",X"30",X"00",
		X"71",X"A0",X"35",X"44",X"0A",X"80",X"02",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"8C",X"00",X"90",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"04",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"02",X"02",X"0A",X"00",X"10",X"A8",X"04",X"09",
		X"00",X"00",X"00",X"2E",X"00",X"0A",X"00",X"00",X"00",X"00",X"00",X"2A",X"00",X"06",X"00",X"06",
		X"26",X"C6",X"01",X"5A",X"93",X"06",X"9B",X"D6",X"02",X"EA",X"9A",X"AF",X"9A",X"F9",X"17",X"3A",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"A0",X"02",X"1F",X"83",X"34",X"8C",X"12",X"03",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"A0",X"00",X"00",X"00",X"C4",X"10",
		X"7C",X"A3",X"B6",X"96",X"3F",X"11",X"ED",X"AB",X"AA",X"2D",X"09",X"B0",X"B5",X"BB",X"F1",X"BB",
		X"E8",X"00",X"99",X"00",X"48",X"00",X"6A",X"00",X"40",X"00",X"0C",X"00",X"D0",X"00",X"43",X"00",
		X"DE",X"AA",X"CE",X"55",X"FE",X"AA",X"FE",X"80",X"DE",X"FC",X"CC",X"FF",X"FC",X"FE",X"FC",X"3A",
		X"AA",X"95",X"6A",X"15",X"A0",X"15",X"00",X"14",X"00",X"14",X"2A",X"A0",X"A8",X"0C",X"A0",X"3A",
		X"DC",X"0A",X"CC",X"2A",X"FC",X"28",X"30",X"20",X"00",X"20",X"55",X"63",X"55",X"4E",X"55",X"42",
		X"40",X"3A",X"10",X"EA",X"07",X"AA",X"0F",X"AA",X"3A",X"AA",X"EA",X"AA",X"AA",X"AA",X"AA",X"AA",
		X"C0",X"F0",X"C0",X"F5",X"C1",X"F5",X"FA",X"FA",X"F5",X"F5",X"3D",X"7D",X"1F",X"7D",X"AA",X"AA",
		X"0F",X"03",X"5F",X"03",X"5F",X"43",X"AF",X"AF",X"5F",X"5F",X"7D",X"7C",X"7D",X"F4",X"AA",X"AA",
		X"3F",X"BF",X"3F",X"BF",X"65",X"96",X"96",X"56",X"26",X"56",X"25",X"95",X"01",X"96",X"00",X"16",
		X"FE",X"FC",X"FE",X"FC",X"96",X"59",X"95",X"96",X"95",X"98",X"96",X"58",X"96",X"40",X"94",X"00",
		X"11",X"11",X"68",X"0A",X"28",X"0A",X"40",X"00",X"D2",X"80",X"C6",X"80",X"F1",X"11",X"BF",X"FF",
		X"11",X"00",X"0A",X"40",X"0A",X"10",X"00",X"04",X"A0",X"A3",X"A0",X"A7",X"11",X"13",X"FF",X"FC",
		X"AA",X"AA",X"2A",X"AA",X"03",X"FF",X"05",X"55",X"02",X"AA",X"00",X"AA",X"00",X"14",X"00",X"00",
		X"AA",X"A0",X"AA",X"00",X"C0",X"00",X"50",X"00",X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"44",X"44",X"28",X"0A",X"68",X"0A",X"00",X"00",X"D2",X"80",X"C6",X"80",X"F0",X"50",X"BF",X"FF",
		X"50",X"40",X"0A",X"10",X"0A",X"04",X"00",X"00",X"A0",X"A7",X"A0",X"A3",X"44",X"47",X"FF",X"FC",
		X"AA",X"AA",X"2A",X"AA",X"03",X"FF",X"05",X"55",X"02",X"AA",X"00",X"AA",X"00",X"14",X"00",X"00",
		X"AA",X"A0",X"AA",X"00",X"C0",X"00",X"50",X"00",X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"11",X"11",X"68",X"0A",X"28",X"0A",X"40",X"00",X"D2",X"80",X"C6",X"80",X"F1",X"11",X"BF",X"FF",
		X"11",X"00",X"0A",X"40",X"0A",X"10",X"00",X"04",X"A0",X"A3",X"A0",X"A7",X"11",X"13",X"FF",X"FC",
		X"AA",X"AA",X"2A",X"AA",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"AA",X"A0",X"AA",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"44",X"44",X"28",X"0A",X"68",X"0A",X"00",X"00",X"D2",X"80",X"C6",X"80",X"F0",X"50",X"BF",X"FF",
		X"50",X"40",X"0A",X"10",X"0A",X"04",X"00",X"00",X"A0",X"A7",X"A0",X"A3",X"44",X"47",X"FF",X"FC",
		X"AA",X"AA",X"2A",X"AA",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"AA",X"A0",X"AA",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"00",X"C0",X"00",X"32",X"00",X"0B",X"00",X"E6",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"C3",X"00",X"8C",X"00",X"60",X"00",X"B8",X"C0",
		X"03",X"2E",X"00",X"09",X"00",X"32",X"00",X"C3",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"9B",X"00",X"E0",X"00",X"8C",X"00",X"03",X"00",X"C0",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"01",X"00",X"0D",X"00",X"3F",X"00",X"3F",X"00",X"0F",X"00",X"03",
		X"00",X"00",X"00",X"00",X"40",X"00",X"70",X"00",X"FC",X"00",X"FC",X"00",X"F0",X"00",X"C0",X"00",
		X"00",X"06",X"00",X"06",X"00",X"0A",X"00",X"0A",X"00",X"2A",X"00",X"28",X"00",X"20",X"00",X"00",
		X"90",X"00",X"90",X"00",X"A0",X"00",X"A0",X"00",X"A8",X"00",X"28",X"00",X"08",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"FE",X"3F",X"FF",X"FF",X"33",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"FF",X"AA",X"A0",X"FF",X"F5",X"AA",X"AA",
		X"17",X"33",X"05",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FF",X"F5",X"57",X"A8",X"15",X"7F",X"08",X"00",X"28",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"0A",X"80",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"28",X"00",X"0F",X"F4",X"28",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"02",X"80",X"02",X"80",X"00",X"00",X"00",X"00",X"00",X"00",
		X"0C",X"30",X"0E",X"B0",X"0D",X"70",X"01",X"40",X"01",X"40",X"0B",X"E0",X"05",X"50",X"01",X"40",
		X"80",X"B0",X"26",X"ED",X"32",X"CA",X"F5",X"6C",X"1A",X"DA",X"3B",X"15",X"12",X"80",X"C0",X"84",
		X"00",X"00",X"05",X"50",X"2A",X"A8",X"FF",X"FF",X"2A",X"A8",X"0A",X"A0",X"03",X"C0",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"07",X"C0",X"07",X"C0",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"30",X"05",X"D7",X"FC",X"30",X"05",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"04",X"0C",X"01",X"00",X"29",X"03",X"81",X"08",X"C5",X"20",X"3D",X"00",X"5F",X"05",X"1F",
		X"00",X"00",X"08",X"0C",X"20",X"30",X"8F",X"00",X"7C",X"20",X"F0",X"40",X"F6",X"55",X"BD",X"40",
		X"51",X"7F",X"00",X"D7",X"23",X"05",X"0C",X"81",X"00",X"81",X"30",X"20",X"00",X"C0",X"00",X"00",
		X"F5",X"08",X"7C",X"20",X"5F",X"00",X"42",X"C0",X"08",X"30",X"82",X"0C",X"40",X"00",X"40",X"00",
		X"00",X"3F",X"3F",X"FC",X"C0",X"03",X"00",X"03",X"00",X"4C",X"01",X"F9",X"00",X"A8",X"02",X"94",
		X"3A",X"95",X"FF",X"79",X"F7",X"FA",X"3F",X"FE",X"7F",X"FD",X"BF",X"EF",X"FC",X"BF",X"F2",X"5F",
		X"00",X"83",X"02",X"0C",X"00",X"00",X"00",X"02",X"00",X"08",X"00",X"00",X"00",X"00",X"00",X"00",
		X"C2",X"4F",X"08",X"17",X"20",X"03",X"81",X"03",X"04",X"00",X"C0",X"08",X"00",X"00",X"00",X"80",
		X"5A",X"AF",X"75",X"FD",X"7D",X"7F",X"7B",X"FF",X"7F",X"EF",X"FD",X"FA",X"7F",X"78",X"FB",X"DC",
		X"F0",X"00",X"FF",X"00",X"7F",X"40",X"D4",X"FC",X"F5",X"00",X"F5",X"40",X"BD",X"10",X"2C",X"00",
		X"D0",X"FC",X"C0",X"3F",X"00",X"0F",X"01",X"08",X"20",X"40",X"00",X"14",X"08",X"00",X"00",X"00",
		X"0B",X"00",X"02",X"C0",X"C0",X"A0",X"F1",X"20",X"30",X"00",X"0C",X"00",X"03",X"00",X"00",X"00",
		X"00",X"00",X"C0",X"00",X"30",X"0C",X"0C",X"00",X"03",X"C0",X"00",X"FD",X"00",X"BF",X"00",X"AF",
		X"00",X"01",X"0C",X"00",X"03",X"00",X"13",X"C4",X"42",X"C1",X"2A",X"F3",X"EB",X"F3",X"7F",X"BC",
		X"00",X"0B",X"0C",X"02",X"03",X"F0",X"00",X"3F",X"00",X"0F",X"14",X"03",X"10",X"88",X"04",X"01",
		X"DF",X"EF",X"F7",X"FF",X"BB",X"FB",X"FF",X"FE",X"FD",X"FE",X"FF",X"5E",X"FF",X"D5",X"FE",X"F5",
		X"00",X"00",X"04",X"01",X"30",X"08",X"30",X"28",X"F4",X"A0",X"F0",X"83",X"FC",X"BF",X"FE",X"FF",
		X"00",X"00",X"00",X"00",X"0C",X"00",X"30",X"00",X"F0",X"10",X"C0",X"40",X"C5",X"00",X"08",X"00",
		X"7B",X"FC",X"7F",X"DE",X"7F",X"6F",X"7D",X"BF",X"56",X"FF",X"57",X"DF",X"59",X"7F",X"96",X"FA",
		X"A0",X"00",X"A3",X"F0",X"BF",X"00",X"FC",X"10",X"BD",X"40",X"00",X"0C",X"FF",X"C0",X"0F",X"FE",
		X"01",X"15",X"05",X"C5",X"15",X"C7",X"05",X"71",X"01",X"5D",X"00",X"44",X"01",X"11",X"00",X"12",
		X"5F",X"FB",X"F5",X"6A",X"55",X"AA",X"46",X"9A",X"5A",X"57",X"65",X"1F",X"B5",X"7D",X"51",X"D5",
		X"00",X"08",X"00",X"42",X"00",X"02",X"00",X"04",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"54",X"54",X"05",X"51",X"11",X"CC",X"41",X"75",X"04",X"57",X"00",X"90",X"00",X"0F",X"00",X"00",
		X"FA",X"55",X"BA",X"A9",X"AE",X"B5",X"E2",X"FD",X"AB",X"F5",X"6A",X"FD",X"6F",X"BF",X"5B",X"C7",
		X"D4",X"C0",X"53",X"54",X"D5",X"50",X"14",X"00",X"53",X"40",X"7D",X"10",X"51",X"54",X"54",X"60",
		X"58",X"15",X"5E",X"5D",X"97",X"15",X"B5",X"4D",X"05",X"04",X"C1",X"40",X"00",X"00",X"00",X"00",
		X"CA",X"80",X"01",X"00",X"D4",X"00",X"51",X"00",X"40",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"1F",X"01",X"0F",X"00",X"83",X"00",X"0F",X"00",X"0A",X"00",X"A8",X"00",X"04",X"00",X"00",
		X"3F",X"2B",X"FA",X"5E",X"D5",X"56",X"55",X"16",X"1F",X"D2",X"CF",X"15",X"33",X"D6",X"CF",X"25",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"03",X"C5",X"10",X"01",X"00",X"81",X"00",X"00",X"00",X"02",X"00",X"02",X"00",X"00",X"00",X"00",
		X"A9",X"5A",X"EA",X"57",X"55",X"A5",X"14",X"55",X"5B",X"ED",X"4C",X"FF",X"7F",X"33",X"4C",X"C0",
		X"C3",X"00",X"F0",X"00",X"3C",X"00",X"70",X"00",X"54",X"00",X"05",X"00",X"30",X"00",X"C0",X"00",
		X"00",X"CC",X"C3",X"00",X"00",X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"02",X"FB",X"13",X"BE",X"0F",X"EA",X"0F",X"5E",X"3E",X"95",X"38",X"65",X"C0",X"A6",X"02",X"9B",
		X"FD",X"E0",X"E6",X"84",X"9A",X"E1",X"6B",X"F8",X"AA",X"BC",X"6F",X"C3",X"AB",X"F0",X"BB",X"4C",
		X"08",X"1F",X"20",X"4F",X"01",X"0C",X"04",X"3C",X"00",X"3C",X"0C",X"30",X"00",X"C3",X"00",X"C0",
		X"BE",X"10",X"2F",X"84",X"73",X"E0",X"70",X"C8",X"BC",X"C2",X"8C",X"30",X"0C",X"00",X"03",X"00",
		X"0C",X"0F",X"20",X"3F",X"00",X"FD",X"03",X"C2",X"00",X"10",X"0A",X"03",X"20",X"0C",X"80",X"30",
		X"DB",X"EA",X"6F",X"FB",X"BF",X"2A",X"FE",X"FB",X"F3",X"CE",X"02",X"FE",X"03",X"CA",X"0F",X"22",
		X"00",X"00",X"00",X"00",X"00",X"08",X"00",X"20",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"3C",X"00",X"30",X"0C",X"02",X"00",X"08",X"00",X"00",X"00",X"20",X"00",X"03",X"00",X"00",X"00",
		X"CA",X"BF",X"FE",X"A0",X"FD",X"A3",X"D5",X"28",X"5D",X"62",X"83",X"5A",X"13",X"14",X"80",X"C1",
		X"4F",X"00",X"40",X"C0",X"10",X"00",X"14",X"00",X"01",X"00",X"80",X"10",X"A0",X"04",X"20",X"00",
		X"80",X"00",X"20",X"00",X"08",X"0C",X"02",X"00",X"C0",X"00",X"00",X"80",X"10",X"00",X"04",X"00",
		X"C8",X"03",X"32",X"00",X"00",X"80",X"00",X"00",X"C0",X"00",X"0C",X"00",X"02",X"00",X"00",X"00",
		X"00",X"00",X"00",X"02",X"00",X"00",X"04",X"05",X"01",X"10",X"00",X"57",X"0C",X"17",X"03",X"5C",
		X"0A",X"00",X"02",X"00",X"86",X"8D",X"A5",X"5C",X"69",X"90",X"DA",X"96",X"D6",X"AA",X"35",X"9A",
		X"02",X"F5",X"30",X"96",X"00",X"2A",X"0F",X"03",X"03",X"E7",X"00",X"3C",X"00",X"FF",X"03",X"07",
		X"F9",X"59",X"E9",X"44",X"AA",X"55",X"A9",X"95",X"E9",X"59",X"F5",X"6A",X"35",X"AA",X"D6",X"FB",
		X"00",X"32",X"00",X"02",X"0C",X"4A",X"0B",X"1A",X"02",X"D6",X"00",X"B5",X"3C",X"29",X"AF",X"E5",
		X"00",X"00",X"80",X"50",X"05",X"C0",X"97",X"00",X"5C",X"0C",X"5A",X"AA",X"DA",X"80",X"55",X"0D",
		X"02",X"A5",X"08",X"B6",X"00",X"1B",X"30",X"53",X"01",X"00",X"04",X"23",X"00",X"80",X"00",X"00",
		X"B5",X"40",X"AB",X"54",X"AA",X"04",X"4A",X"80",X"42",X"A0",X"10",X"20",X"13",X"00",X"10",X"00",
		X"00",X"00",X"00",X"05",X"01",X"14",X"00",X"00",X"00",X"03",X"00",X"0F",X"00",X"FC",X"00",X"02",
		X"57",X"EC",X"41",X"AA",X"3E",X"BA",X"FE",X"D6",X"FB",X"5E",X"F5",X"7F",X"14",X"3F",X"43",X"FF",
		X"00",X"04",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"F1",X"03",X"C1",X"05",X"04",X"10",X"04",X"00",X"10",X"00",X"00",X"00",X"00",X"00",X"00",
		X"6A",X"BA",X"A9",X"7F",X"AA",X"D7",X"9A",X"BD",X"95",X"AC",X"BD",X"F3",X"BD",X"7F",X"EF",X"53",
		X"D4",X"00",X"30",X"00",X"C0",X"00",X"F0",X"00",X"30",X"00",X"0C",X"00",X"C0",X"00",X"F0",X"00",
		X"FF",X"DC",X"FC",X"D5",X"3C",X"3D",X"0F",X"3D",X"03",X"0F",X"00",X"C0",X"00",X"00",X"00",X"00",
		X"3C",X"00",X"03",X"C0",X"00",X"00",X"50",X"00",X"C4",X"00",X"50",X"00",X"04",X"00",X"01",X"00",
		X"01",X"55",X"00",X"01",X"00",X"0A",X"00",X"A8",X"00",X"00",X"00",X"00",X"00",X"03",X"00",X"03",
		X"55",X"A5",X"69",X"69",X"95",X"65",X"01",X"26",X"30",X"15",X"FF",X"D9",X"C7",X"A5",X"1A",X"06",
		X"00",X"0C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"20",X"02",X"80",X"C2",X"03",X"0E",X"0C",X"0C",X"00",X"00",X"00",X"0C",X"00",X"00",X"00",X"00",
		X"5A",X"AA",X"6A",X"B0",X"9B",X"FC",X"AA",X"C3",X"A6",X"50",X"65",X"6A",X"69",X"50",X"05",X"D5",
		X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"A0",X"00",X"00",X"00",
		X"4A",X"FD",X"70",X"8F",X"0F",X"C0",X"00",X"C0",X"00",X"F0",X"00",X"00",X"00",X"00",X"00",X"00",
		X"40",X"00",X"10",X"00",X"C4",X"00",X"30",X"00",X"0C",X"00",X"03",X"00",X"00",X"00",X"00",X"00",
		X"00",X"02",X"01",X"10",X"23",X"01",X"0A",X"72",X"00",X"1F",X"02",X"8A",X"30",X"17",X"C3",X"1C",
		X"08",X"00",X"30",X"C0",X"8C",X"08",X"BE",X"34",X"FF",X"C0",X"CB",X"12",X"EF",X"FC",X"FE",X"04",
		X"08",X"23",X"21",X"0C",X"00",X"F2",X"02",X"0A",X"08",X"48",X"00",X"23",X"01",X"30",X"00",X"02",
		X"33",X"81",X"9C",X"F0",X"09",X"4C",X"D4",X"A0",X"CC",X"08",X"03",X"00",X"10",X"C0",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"55",X"00",X"50",X"00",X"50",X"00",X"50",X"00",X"50",X"00",X"55",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"00",X"0F",X"00",X"FF",X"0F",X"FF",X"FF",X"FF",
		X"00",X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FA",X"FF",X"FF",X"FF",X"FF",X"FF",X"FA",X"FF",X"AA",
		X"00",X"00",X"51",X"55",X"51",X"01",X"01",X"01",X"01",X"01",X"51",X"01",X"51",X"55",X"00",X"00",
		X"00",X"00",X"45",X"55",X"45",X"05",X"40",X"14",X"41",X"40",X"45",X"05",X"45",X"55",X"00",X"00",
		X"00",X"00",X"0A",X"AA",X"FF",X"EA",X"AA",X"AA",X"FA",X"AA",X"AA",X"A8",X"AA",X"A0",X"AA",X"80",
		X"AA",X"FF",X"A8",X"FF",X"A0",X"FF",X"80",X"3F",X"0C",X"3F",X"0F",X"FF",X"0F",X"F1",X"0F",X"FF",
		X"00",X"00",X"14",X"51",X"14",X"51",X"14",X"51",X"15",X"55",X"15",X"05",X"14",X"01",X"00",X"00",
		X"00",X"00",X"15",X"15",X"15",X"14",X"15",X"14",X"15",X"14",X"15",X"14",X"15",X"15",X"00",X"00",
		X"FF",X"AA",X"FF",X"2A",X"FF",X"0A",X"FC",X"02",X"FC",X"00",X"FC",X"00",X"3C",X"00",X"F0",X"00",
		X"00",X"00",X"AA",X"A0",X"AB",X"FF",X"AA",X"AA",X"AA",X"AF",X"2A",X"AA",X"0A",X"AA",X"02",X"AA",
		X"00",X"00",X"54",X"00",X"14",X"00",X"00",X"00",X"00",X"00",X"14",X"00",X"54",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"FF",X"FF",X"AF",X"FF",X"FF",X"FF",X"FF",X"FF",X"AF",X"FF",X"AA",X"FF",
		X"00",X"00",X"00",X"00",X"00",X"00",X"C0",X"00",X"F0",X"00",X"FF",X"00",X"FF",X"F0",X"FF",X"FF",
		X"A8",X"00",X"AB",X"0A",X"AA",X"02",X"2A",X"C2",X"2A",X"C2",X"2A",X"AA",X"2A",X"B2",X"0A",X"B2",
		X"00",X"00",X"A0",X"AA",X"BC",X"AA",X"B2",X"AA",X"B2",X"AA",X"BA",X"BA",X"BA",X"BA",X"BA",X"BA",
		X"0A",X"BA",X"0A",X"BA",X"0A",X"BA",X"02",X"AA",X"02",X"AB",X"00",X"A8",X"00",X"A0",X"00",X"00",
		X"CA",X"C2",X"EA",X"C2",X"EA",X"C2",X"2A",X"C2",X"2A",X"CA",X"AA",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"0A",X"80",X"C2",X"AA",X"C2",X"AA",X"C2",X"AF",X"C2",X"AC",X"BA",X"AA",X"B2",X"AA",
		X"00",X"00",X"00",X"00",X"A2",X"A8",X"AC",X"AF",X"EC",X"AC",X"0C",X"AC",X"B0",X"AF",X"C0",X"AE",
		X"B2",X"AC",X"B2",X"AF",X"B2",X"AA",X"B2",X"AA",X"8A",X"A8",X"00",X"00",X"00",X"00",X"00",X"00",
		X"0C",X"AE",X"EC",X"AA",X"AC",X"AB",X"A2",X"AA",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"2A",X"82",X"EA",X"0A",X"EA",X"0A",X"AA",X"EA",X"BA",X"EA",X"BA",X"EA",
		X"00",X"00",X"00",X"00",X"AA",X"0A",X"BA",X"BA",X"3A",X"BA",X"3A",X"BA",X"EA",X"BA",X"00",X"3A",
		X"BA",X"EA",X"3A",X"EA",X"FA",X"3A",X"2A",X"8A",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"3F",X"3A",X"FA",X"BA",X"BA",X"BA",X"AA",X"BA",X"AA",X"0A",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"2A",X"A2",X"AA",X"AE",X"AB",X"AE",X"BF",X"8E",X"83",X"0E",X"AA",X"0E",X"AA",X"0E",
		X"00",X"AA",X"A3",X"A8",X"A2",X"A0",X"AE",X"A0",X"AE",X"80",X"AA",X"80",X"AA",X"00",X"AA",X"A8",
		X"8E",X"0E",X"80",X"CE",X"B0",X"EE",X"AB",X"EE",X"AA",X"AE",X"2A",X"A2",X"00",X"00",X"00",X"00",
		X"A0",X"EA",X"A0",X"EA",X"A3",X"EA",X"AF",X"AA",X"AA",X"A8",X"AA",X"A8",X"0A",X"80",X"00",X"00",
		X"00",X"00",X"01",X"31",X"10",X"5A",X"04",X"6F",X"05",X"2E",X"01",X"79",X"54",X"A9",X"07",X"65",
		X"43",X"00",X"14",X"C4",X"94",X"50",X"E1",X"9C",X"9E",X"80",X"DA",X"E4",X"F6",X"95",X"5A",X"E0",
		X"03",X"6A",X"0C",X"AB",X"30",X"59",X"01",X"45",X"0C",X"54",X"00",X"10",X"00",X"C0",X"00",X"00",
		X"DA",X"A7",X"AB",X"10",X"AE",X"54",X"51",X"40",X"90",X"50",X"44",X"24",X"41",X"00",X"40",X"00",
		X"00",X"30",X"02",X"04",X"1C",X"68",X"C5",X"85",X"06",X"97",X"10",X"AF",X"05",X"AA",X"2B",X"FE",
		X"8C",X"00",X"A3",X"20",X"6C",X"80",X"BC",X"78",X"F9",X"61",X"AA",X"99",X"A6",X"8C",X"61",X"F0",
		X"0F",X"8A",X"30",X"9F",X"0A",X"53",X"11",X"0B",X"40",X"36",X"00",X"38",X"00",X"C0",X"03",X"00",
		X"9F",X"87",X"A5",X"F0",X"E5",X"8C",X"4E",X"42",X"53",X"90",X"00",X"84",X"91",X"00",X"00",X"30",
		X"00",X"80",X"00",X"E0",X"04",X"08",X"01",X"C1",X"C0",X"74",X"30",X"07",X"03",X"31",X"00",X"87",
		X"30",X"0C",X"8C",X"80",X"12",X"10",X"58",X"40",X"61",X"00",X"44",X"00",X"1D",X"50",X"51",X"03",
		X"20",X"D1",X"08",X"14",X"00",X"50",X"20",X"42",X"03",X"08",X"0C",X"00",X"00",X"20",X"80",X"00",
		X"D4",X"80",X"75",X"0E",X"12",X"40",X"10",X"10",X"08",X"00",X"00",X"30",X"10",X"0C",X"00",X"00",
		X"00",X"02",X"02",X"08",X"2B",X"EA",X"AC",X"38",X"BF",X"D3",X"AD",X"7F",X"95",X"CF",X"57",X"FB",
		X"00",X"00",X"00",X"00",X"30",X"00",X"F0",X"00",X"E4",X"00",X"90",X"00",X"C3",X"00",X"C0",X"00",
		X"5A",X"A1",X"6A",X"97",X"9A",X"7E",X"A9",X"FF",X"6A",X"F4",X"5A",X"BD",X"A6",X"FF",X"EA",X"8F",
		X"7C",X"00",X"FF",X"C0",X"B0",X"30",X"E0",X"00",X"08",X"0C",X"00",X"C0",X"C0",X"00",X"FC",X"00",
		X"00",X"00",X"00",X"08",X"00",X"20",X"00",X"33",X"01",X"01",X"04",X"04",X"00",X"40",X"00",X"00",
		X"0F",X"EA",X"35",X"E8",X"D3",X"EA",X"0F",X"AE",X"2E",X"BE",X"3F",X"FF",X"BC",X"F7",X"F0",X"1D",
		X"0C",X"05",X"30",X"04",X"00",X"C0",X"00",X"82",X"02",X"00",X"00",X"03",X"00",X"08",X"00",X"00",
		X"CB",X"7C",X"43",X"F0",X"8F",X"14",X"0F",X"00",X"3C",X"12",X"00",X"10",X"00",X"40",X"04",X"00",
		X"8F",X"D0",X"DF",X"F4",X"F7",X"39",X"FD",X"82",X"B7",X"70",X"B1",X"FC",X"FC",X"71",X"CE",X"1C",
		X"00",X"00",X"C4",X"00",X"40",X"00",X"00",X"80",X"A0",X"00",X"0C",X"00",X"03",X"00",X"20",X"10",
		X"F0",X"35",X"FC",X"BD",X"34",X"30",X"3C",X"0C",X"0C",X"00",X"83",X"20",X"80",X"08",X"20",X"02",
		X"00",X"04",X"02",X"00",X"80",X"80",X"00",X"00",X"04",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FE",X"EF",X"6F",X"EF",X"67",X"FE",X"66",X"FF",X"66",X"6E",X"26",X"6F",X"26",X"6E",X"26",X"6F",
		X"FB",X"BF",X"FB",X"F9",X"BF",X"D9",X"FF",X"99",X"B9",X"99",X"F9",X"99",X"B9",X"98",X"F9",X"98",
		X"26",X"6F",X"06",X"55",X"01",X"55",X"03",X"FF",X"02",X"AA",X"00",X"FF",X"00",X"0A",X"00",X"03",
		X"F9",X"98",X"55",X"90",X"55",X"40",X"FF",X"C0",X"AA",X"80",X"FF",X"00",X"A0",X"00",X"C0",X"00",
		X"55",X"55",X"55",X"55",X"6A",X"A5",X"5A",X"95",X"56",X"A5",X"55",X"A9",X"55",X"6A",X"55",X"5A",
		X"55",X"55",X"55",X"55",X"5A",X"A9",X"56",X"A5",X"5A",X"95",X"6A",X"55",X"A9",X"55",X"A5",X"55",
		X"55",X"5A",X"55",X"6A",X"55",X"A9",X"56",X"A5",X"5A",X"95",X"6A",X"A5",X"55",X"55",X"55",X"55",
		X"A5",X"55",X"A9",X"55",X"6A",X"55",X"5A",X"95",X"56",X"A5",X"5A",X"A9",X"55",X"55",X"55",X"55");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
