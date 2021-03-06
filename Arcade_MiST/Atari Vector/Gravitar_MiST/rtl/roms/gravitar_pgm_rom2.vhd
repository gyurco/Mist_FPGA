library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity gravitar_pgm_rom2 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(11 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of gravitar_pgm_rom2 is
	type rom is array(0 to  4095) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"E5",X"24",X"85",X"24",X"A5",X"24",X"85",X"1A",X"84",X"22",X"20",X"6E",X"DE",X"A5",X"1C",X"85",
		X"38",X"A4",X"22",X"C8",X"B1",X"5A",X"88",X"29",X"7F",X"85",X"19",X"20",X"6E",X"DE",X"A4",X"22",
		X"A5",X"1B",X"18",X"65",X"38",X"85",X"38",X"A9",X"00",X"65",X"1C",X"85",X"39",X"C8",X"B1",X"5A",
		X"20",X"63",X"A0",X"88",X"BD",X"64",X"02",X"85",X"3A",X"BD",X"4D",X"02",X"85",X"3B",X"20",X"A2",
		X"A0",X"A9",X"00",X"85",X"41",X"86",X"24",X"20",X"D2",X"A4",X"A6",X"24",X"B0",X"05",X"A9",X"00",
		X"9D",X"EC",X"02",X"20",X"83",X"A0",X"C6",X"23",X"D0",X"87",X"C6",X"21",X"30",X"03",X"4C",X"84",
		X"9F",X"60",X"19",X"10",X"10",X"A5",X"33",X"38",X"E5",X"38",X"85",X"38",X"A5",X"34",X"E5",X"39",
		X"85",X"39",X"4C",X"82",X"A0",X"A5",X"33",X"18",X"65",X"38",X"85",X"38",X"A5",X"34",X"65",X"39",
		X"85",X"39",X"60",X"A5",X"33",X"18",X"71",X"58",X"85",X"33",X"A5",X"34",X"C8",X"71",X"58",X"88",
		X"85",X"34",X"A5",X"31",X"18",X"71",X"56",X"85",X"31",X"A5",X"32",X"C8",X"71",X"56",X"85",X"32",
		X"C8",X"60",X"BD",X"1F",X"02",X"85",X"3C",X"BD",X"08",X"02",X"85",X"3D",X"BD",X"64",X"02",X"85",
		X"3E",X"BD",X"4D",X"02",X"85",X"3F",X"60",X"A5",X"31",X"38",X"FD",X"64",X"02",X"A5",X"32",X"FD",
		X"4D",X"02",X"85",X"24",X"A5",X"31",X"18",X"71",X"56",X"85",X"3A",X"A5",X"32",X"C8",X"71",X"56",
		X"88",X"85",X"3B",X"A5",X"3A",X"38",X"FD",X"64",X"02",X"A5",X"3B",X"FD",X"4D",X"02",X"45",X"24",
		X"10",X"04",X"38",X"4C",X"E7",X"A0",X"18",X"60",X"A2",X"03",X"B5",X"44",X"95",X"31",X"CA",X"10",
		X"F9",X"A5",X"2B",X"85",X"21",X"A5",X"21",X"0A",X"A8",X"E6",X"32",X"A5",X"33",X"18",X"71",X"5C",
		X"85",X"33",X"A5",X"34",X"C8",X"71",X"5C",X"85",X"34",X"E6",X"21",X"A5",X"21",X"29",X"0F",X"85",
		X"21",X"C5",X"2A",X"D0",X"E0",X"A2",X"03",X"B5",X"31",X"95",X"44",X"CA",X"10",X"F9",X"A4",X"2A",
		X"B1",X"5E",X"D0",X"01",X"60",X"85",X"21",X"B1",X"60",X"A8",X"20",X"36",X"A5",X"90",X"62",X"B1",
		X"56",X"F0",X"5E",X"B1",X"5A",X"85",X"19",X"A5",X"0D",X"38",X"E5",X"31",X"85",X"24",X"A5",X"0E",
		X"E5",X"32",X"10",X"07",X"A9",X"00",X"38",X"E5",X"24",X"85",X"24",X"A5",X"24",X"85",X"1A",X"84",
		X"22",X"20",X"6E",X"DE",X"A4",X"22",X"A5",X"1C",X"85",X"38",X"C8",X"B1",X"5A",X"29",X"7F",X"85",
		X"19",X"20",X"6E",X"DE",X"A4",X"22",X"A5",X"1B",X"18",X"65",X"38",X"85",X"38",X"A9",X"00",X"65",
		X"1C",X"85",X"39",X"C8",X"B1",X"5A",X"20",X"63",X"A0",X"88",X"A5",X"0D",X"85",X"3A",X"A5",X"0E",
		X"85",X"3B",X"20",X"6F",X"A5",X"A9",X"00",X"85",X"41",X"20",X"D2",X"A4",X"B0",X"03",X"4C",X"80",
		X"A5",X"20",X"83",X"A0",X"C6",X"21",X"D0",X"92",X"60",X"06",X"28",X"00",X"28",X"1C",X"28",X"32",
		X"28",X"40",X"28",X"00",X"28",X"5A",X"28",X"68",X"28",X"00",X"28",X"6E",X"28",X"74",X"28",X"7A",
		X"28",X"80",X"28",X"9A",X"28",X"AC",X"28",X"BE",X"28",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"CE",X"2A",X"EC",X"2A",X"12",X"2B",X"44",X"2B",X"5A",X"2B",X"78",X"2B",X"9E",X"2B",X"D0",
		X"2B",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"E6",X"2B",X"F4",X"2B",X"06",X"2C",X"20",
		X"2C",X"3A",X"2C",X"60",X"2C",X"82",X"2C",X"AC",X"2C",X"BE",X"2C",X"D0",X"2C",X"EA",X"2C",X"08",
		X"2D",X"26",X"2D",X"40",X"2D",X"4E",X"2D",X"6C",X"2D",X"CA",X"28",X"E8",X"28",X"0E",X"29",X"30",
		X"29",X"52",X"29",X"60",X"29",X"86",X"29",X"B4",X"29",X"C2",X"29",X"E8",X"29",X"12",X"2A",X"34",
		X"2A",X"56",X"2A",X"78",X"2A",X"A2",X"2A",X"AC",X"2A",X"00",X"00",X"00",X"00",X"00",X"00",X"7E",
		X"2D",X"8C",X"2D",X"AE",X"2D",X"D4",X"2D",X"EE",X"2D",X"14",X"2E",X"46",X"2E",X"78",X"2E",X"AE",
		X"2E",X"C8",X"2E",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"28",X"D2",X"2E",X"00",X"28",X"D8",
		X"2E",X"00",X"28",X"00",X"28",X"D2",X"2E",X"D2",X"2E",X"00",X"28",X"D8",X"2E",X"00",X"28",X"D8",
		X"2E",X"D2",X"2E",X"00",X"28",X"D8",X"2E",X"00",X"28",X"D8",X"2E",X"DE",X"2E",X"F4",X"2E",X"00",
		X"28",X"06",X"2F",X"18",X"2F",X"D2",X"2E",X"2A",X"2F",X"40",X"2F",X"D8",X"2E",X"00",X"28",X"52",
		X"2F",X"00",X"28",X"60",X"2F",X"00",X"28",X"00",X"28",X"00",X"00",X"00",X"00",X"00",X"00",X"72",
		X"2F",X"94",X"2F",X"B2",X"2F",X"D4",X"2F",X"FA",X"2F",X"0C",X"30",X"32",X"30",X"58",X"30",X"86",
		X"30",X"B0",X"30",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"28",X"C6",X"30",X"D4",X"30",X"DE",
		X"30",X"E4",X"30",X"F6",X"30",X"08",X"31",X"00",X"28",X"0E",X"31",X"28",X"31",X"56",X"31",X"7C",
		X"31",X"A2",X"31",X"D0",X"31",X"00",X"28",X"E2",X"31",X"0E",X"37",X"20",X"37",X"36",X"37",X"0E",
		X"37",X"20",X"37",X"54",X"37",X"7E",X"37",X"94",X"37",X"C2",X"37",X"00",X"28",X"D8",X"37",X"F6",
		X"37",X"00",X"28",X"14",X"38",X"2A",X"38",X"00",X"28",X"00",X"00",X"00",X"00",X"00",X"00",X"A6",
		X"33",X"C0",X"33",X"DE",X"33",X"0C",X"34",X"26",X"34",X"50",X"34",X"76",X"34",X"90",X"34",X"BE",
		X"34",X"DC",X"34",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"28",X"EC",X"31",X"FE",X"31",X"28",
		X"32",X"4E",X"32",X"74",X"32",X"92",X"32",X"A8",X"32",X"C2",X"32",X"E0",X"32",X"F6",X"32",X"10",
		X"33",X"2A",X"33",X"44",X"33",X"6A",X"33",X"90",X"33",X"00",X"FF",X"00",X"00",X"E0",X"01",X"C0",
		X"FE",X"20",X"FF",X"00",X"00",X"C0",X"01",X"40",X"FF",X"00",X"00",X"C0",X"00",X"80",X"FF",X"E0",
		X"FE",X"00",X"00",X"00",X"00",X"20",X"02",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"E0",X"FE",X"A0",X"FF",X"A0",X"00",X"A0",X"FF",X"00",X"00",X"20",X"FF",X"E0",X"01",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"FE",X"20",X"FF",X"00",X"00",X"60",
		X"00",X"E0",X"00",X"E0",X"FE",X"40",X"00",X"00",X"02",X"80",X"FE",X"C0",X"FF",X"80",X"FF",X"80",
		X"00",X"C0",X"01",X"60",X"FE",X"40",X"00",X"60",X"01",X"80",X"00",X"C0",X"FF",X"20",X"00",X"00",
		X"00",X"A0",X"FF",X"00",X"00",X"80",X"00",X"40",X"00",X"00",X"00",X"80",X"FF",X"40",X"00",X"A0",
		X"FF",X"20",X"00",X"00",X"00",X"40",X"00",X"80",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FF",X"00",X"FF",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"01",X"00",
		X"01",X"00",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",
		X"01",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"FF",X"00",X"00",X"00",X"01",X"00",X"00",X"00",
		X"01",X"00",X"FF",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"02",X"00",X"FD",X"00",X"00",X"00",X"01",X"00",X"01",X"00",X"00",X"00",
		X"01",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FF",X"00",X"FF",X"00",X"00",X"00",X"02",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",
		X"01",X"00",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"C0",X"02",X"C0",X"00",X"00",
		X"02",X"C0",X"FB",X"00",X"00",X"40",X"FE",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FF",X"00",X"FF",X"00",X"01",X"00",X"00",X"00",X"FF",X"00",X"01",X"00",X"00",X"00",X"FF",X"00",
		X"01",X"00",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"FE",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"C0",X"00",X"00",X"00",X"C0",X"00",X"00",X"00",X"00",X"FF",X"00",
		X"00",X"C0",X"FE",X"80",X"00",X"00",X"01",X"40",X"02",X"A2",X"02",X"B5",X"38",X"38",X"F5",X"3C",
		X"95",X"38",X"B5",X"39",X"F5",X"3D",X"95",X"39",X"CA",X"CA",X"10",X"EF",X"A9",X"00",X"85",X"55",
		X"A2",X"02",X"B5",X"39",X"10",X"14",X"A9",X"00",X"38",X"F5",X"38",X"95",X"38",X"A9",X"00",X"F5",
		X"39",X"95",X"39",X"A5",X"55",X"1D",X"CF",X"A4",X"85",X"55",X"CA",X"CA",X"10",X"E4",X"60",X"01",
		X"00",X"02",X"20",X"99",X"A4",X"A5",X"39",X"05",X"3B",X"D0",X"1F",X"A6",X"41",X"10",X"03",X"4C",
		X"FC",X"A4",X"A5",X"38",X"DD",X"2A",X"A5",X"B0",X"0C",X"A5",X"3A",X"DD",X"2E",X"A5",X"B0",X"05",
		X"65",X"38",X"DD",X"32",X"A5",X"A5",X"38",X"4C",X"FB",X"A4",X"38",X"60",X"A4",X"22",X"A5",X"38",
		X"D9",X"12",X"A5",X"B0",X"0C",X"A5",X"3A",X"D9",X"1A",X"A5",X"B0",X"05",X"65",X"38",X"D9",X"22",
		X"A5",X"60",X"24",X"24",X"24",X"24",X"24",X"24",X"24",X"24",X"2E",X"2E",X"2E",X"2E",X"2E",X"2E",
		X"2E",X"2E",X"40",X"40",X"40",X"40",X"40",X"40",X"40",X"40",X"13",X"10",X"23",X"30",X"11",X"14",
		X"24",X"50",X"18",X"1C",X"32",X"70",X"A5",X"31",X"38",X"E5",X"0D",X"85",X"7B",X"A5",X"32",X"E5",
		X"0E",X"85",X"22",X"D0",X"08",X"A5",X"7B",X"C9",X"02",X"B0",X"02",X"38",X"60",X"A5",X"31",X"18",
		X"71",X"56",X"85",X"23",X"A5",X"32",X"C8",X"71",X"56",X"88",X"85",X"24",X"A5",X"23",X"38",X"E5",
		X"0D",X"A5",X"24",X"E5",X"0E",X"45",X"22",X"10",X"04",X"38",X"4C",X"6E",X"A5",X"18",X"60",X"A5",
		X"0F",X"85",X"3C",X"A5",X"10",X"85",X"3D",X"A5",X"0D",X"85",X"3E",X"A5",X"0E",X"85",X"3F",X"60",
		X"20",X"8A",X"A5",X"20",X"C0",X"C8",X"20",X"EB",X"E0",X"60",X"A9",X"00",X"A6",X"CF",X"95",X"88",
		X"A5",X"0F",X"85",X"38",X"A5",X"10",X"85",X"39",X"A5",X"0D",X"85",X"3A",X"A5",X"0E",X"85",X"3B",
		X"60",X"40",X"00",X"60",X"00",X"60",X"00",X"A0",X"FF",X"60",X"00",X"40",X"00",X"C0",X"00",X"C0",
		X"00",X"40",X"FF",X"60",X"00",X"40",X"00",X"60",X"00",X"80",X"00",X"80",X"FF",X"FF",X"00",X"60",
		X"00",X"A0",X"FF",X"40",X"00",X"C0",X"00",X"40",X"FF",X"C0",X"00",X"FF",X"00",X"A0",X"00",X"60",
		X"FF",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"00",
		X"00",X"40",X"FF",X"40",X"00",X"80",X"FF",X"FF",X"00",X"FF",X"00",X"01",X"FF",X"FF",X"00",X"01",
		X"FF",X"A0",X"00",X"60",X"FF",X"80",X"00",X"80",X"00",X"C0",X"00",X"40",X"00",X"00",X"00",X"60",
		X"00",X"40",X"FF",X"60",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"40",X"01",X"C0",X"00",X"40",
		X"00",X"00",X"00",X"A0",X"FF",X"80",X"FF",X"40",X"FF",X"00",X"00",X"C0",X"00",X"E0",X"00",X"00",
		X"00",X"A0",X"FF",X"60",X"FE",X"80",X"FF",X"00",X"00",X"40",X"01",X"E0",X"00",X"A0",X"FF",X"40",
		X"FF",X"00",X"00",X"C0",X"00",X"80",X"FF",X"E0",X"FE",X"00",X"00",X"E0",X"00",X"40",X"00",X"80",
		X"00",X"A0",X"00",X"00",X"00",X"00",X"00",X"E0",X"00",X"60",X"01",X"00",X"00",X"00",X"00",X"20",
		X"01",X"00",X"00",X"00",X"01",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"01",X"00",X"82",X"AA",
		X"81",X"00",X"00",X"00",X"00",X"00",X"00",X"AA",X"01",X"00",X"01",X"AA",X"00",X"00",X"00",X"00",
		X"81",X"00",X"81",X"80",X"81",X"00",X"00",X"00",X"02",X"55",X"02",X"00",X"00",X"80",X"80",X"20",
		X"82",X"AA",X"80",X"00",X"00",X"00",X"02",X"66",X"01",X"60",X"80",X"C0",X"80",X"00",X"00",X"C0",
		X"00",X"80",X"80",X"10",X"81",X"00",X"00",X"00",X"81",X"55",X"00",X"00",X"02",X"40",X"01",X"00",
		X"00",X"00",X"00",X"00",X"81",X"60",X"01",X"00",X"00",X"00",X"00",X"CC",X"01",X"00",X"00",X"00",
		X"02",X"55",X"81",X"00",X"00",X"00",X"0A",X"0E",X"18",X"1E",X"2A",X"2C",X"32",X"34",X"36",X"38",
		X"3A",X"3C",X"48",X"50",X"58",X"05",X"02",X"05",X"03",X"06",X"01",X"03",X"01",X"01",X"01",X"01",
		X"01",X"06",X"04",X"04",X"02",X"C0",X"00",X"40",X"00",X"00",X"00",X"60",X"FF",X"A0",X"00",X"80",
		X"FF",X"80",X"FF",X"60",X"00",X"60",X"00",X"40",X"00",X"00",X"00",X"C0",X"FF",X"40",X"00",X"00",
		X"00",X"C0",X"FF",X"40",X"FF",X"60",X"00",X"A0",X"FF",X"00",X"00",X"60",X"00",X"A0",X"00",X"80",
		X"FF",X"80",X"00",X"00",X"00",X"A0",X"FF",X"60",X"00",X"80",X"FF",X"80",X"FF",X"A0",X"00",X"60",
		X"00",X"00",X"00",X"80",X"FF",X"80",X"FF",X"FF",X"00",X"00",X"00",X"01",X"FF",X"60",X"00",X"80",
		X"00",X"80",X"FF",X"A0",X"FF",X"FF",X"00",X"01",X"FF",X"A0",X"00",X"60",X"00",X"A0",X"FF",X"60",
		X"00",X"00",X"00",X"A0",X"FF",X"60",X"FF",X"40",X"00",X"80",X"00",X"40",X"00",X"A0",X"FF",X"60",
		X"00",X"C0",X"FF",X"40",X"00",X"00",X"00",X"C0",X"FF",X"40",X"00",X"60",X"FF",X"A0",X"FF",X"C0",
		X"00",X"40",X"00",X"80",X"FF",X"E0",X"FF",X"A0",X"FF",X"00",X"00",X"40",X"00",X"A0",X"FE",X"00",
		X"00",X"A0",X"00",X"00",X"00",X"80",X"00",X"A0",X"FF",X"40",X"00",X"C0",X"FF",X"40",X"FF",X"C0",
		X"FF",X"00",X"00",X"80",X"03",X"00",X"00",X"40",X"FF",X"A0",X"FF",X"A0",X"FF",X"C0",X"FF",X"00",
		X"00",X"A0",X"00",X"80",X"00",X"80",X"00",X"20",X"03",X"A0",X"FF",X"A0",X"FF",X"00",X"00",X"80",
		X"FF",X"00",X"00",X"A0",X"FF",X"00",X"03",X"00",X"00",X"80",X"00",X"00",X"00",X"7E",X"04",X"80",
		X"FF",X"00",X"00",X"80",X"FF",X"80",X"FF",X"00",X"00",X"00",X"00",X"00",X"FF",X"60",X"FF",X"60",
		X"00",X"00",X"00",X"60",X"00",X"E0",X"03",X"00",X"00",X"80",X"01",X"40",X"00",X"00",X"00",X"40",
		X"00",X"60",X"00",X"80",X"00",X"40",X"00",X"40",X"00",X"20",X"01",X"40",X"00",X"40",X"00",X"00",
		X"00",X"60",X"00",X"00",X"00",X"40",X"00",X"80",X"00",X"00",X"00",X"60",X"00",X"00",X"00",X"00",
		X"01",X"00",X"00",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"01",X"00",X"81",X"AA",X"00",X"00",
		X"81",X"00",X"01",X"00",X"81",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"81",X"00",X"81",X"00",
		X"81",X"00",X"01",X"00",X"00",X"00",X"01",X"00",X"01",X"00",X"01",X"00",X"81",X"00",X"81",X"00",
		X"81",X"00",X"00",X"00",X"81",X"00",X"00",X"00",X"81",X"00",X"01",X"00",X"00",X"00",X"01",X"00",
		X"00",X"00",X"00",X"81",X"80",X"00",X"00",X"00",X"81",X"00",X"81",X"00",X"00",X"00",X"00",X"00",
		X"81",X"00",X"81",X"00",X"01",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"00",X"66",X"02",X"00",
		X"01",X"00",X"00",X"00",X"01",X"00",X"01",X"00",X"01",X"00",X"01",X"00",X"01",X"00",X"00",X"00",
		X"01",X"00",X"01",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"01",X"00",X"01",X"00",X"00",X"00",
		X"01",X"00",X"00",X"00",X"00",X"00",X"0E",X"20",X"38",X"42",X"50",X"62",X"7A",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"07",X"09",X"0C",X"05",X"07",X"09",X"0C",X"05",X"00",X"00",X"00",
		X"00",X"FF",X"00",X"40",X"FF",X"C0",X"00",X"FF",X"00",X"00",X"00",X"A0",X"FF",X"60",X"00",X"FF",
		X"00",X"00",X"00",X"A0",X"FF",X"60",X"FF",X"00",X"00",X"FF",X"00",X"A0",X"00",X"60",X"00",X"00",
		X"00",X"01",X"FF",X"00",X"00",X"FF",X"00",X"60",X"00",X"60",X"00",X"40",X"00",X"00",X"00",X"A0",
		X"FF",X"C0",X"FF",X"A0",X"FF",X"00",X"00",X"FF",X"00",X"80",X"00",X"80",X"FF",X"00",X"00",X"FF",
		X"00",X"00",X"00",X"60",X"FF",X"60",X"00",X"40",X"00",X"60",X"00",X"A0",X"00",X"00",X"00",X"C0",
		X"FF",X"A0",X"FF",X"A0",X"FF",X"00",X"00",X"40",X"00",X"C0",X"FF",X"FF",X"00",X"A0",X"00",X"60",
		X"00",X"01",X"FF",X"FF",X"00",X"FF",X"00",X"00",X"00",X"A0",X"FF",X"60",X"00",X"FF",X"00",X"00",
		X"00",X"C0",X"FF",X"40",X"FF",X"00",X"00",X"FF",X"00",X"80",X"00",X"80",X"00",X"00",X"00",X"20",
		X"FF",X"E0",X"FF",X"00",X"00",X"FF",X"00",X"60",X"00",X"A0",X"00",X"00",X"00",X"20",X"FF",X"E0",
		X"FF",X"00",X"00",X"FF",X"00",X"60",X"00",X"A0",X"00",X"40",X"FF",X"C0",X"FF",X"00",X"00",X"FF",
		X"00",X"40",X"00",X"40",X"00",X"80",X"00",X"80",X"00",X"40",X"00",X"40",X"00",X"00",X"00",X"01",
		X"FF",X"80",X"00",X"80",X"00",X"C0",X"00",X"40",X"FF",X"00",X"00",X"FF",X"00",X"00",X"00",X"40",
		X"FF",X"40",X"FF",X"20",X"FF",X"80",X"01",X"E0",X"00",X"00",X"00",X"00",X"00",X"E0",X"00",X"00",
		X"00",X"A0",X"00",X"E0",X"00",X"00",X"00",X"00",X"00",X"60",X"00",X"80",X"01",X"00",X"FF",X"80",
		X"01",X"00",X"00",X"A0",X"00",X"00",X"00",X"40",X"00",X"A0",X"00",X"40",X"00",X"00",X"00",X"C0",
		X"FF",X"80",X"00",X"00",X"00",X"00",X"00",X"A0",X"00",X"80",X"00",X"00",X"00",X"00",X"FF",X"20",
		X"FF",X"A0",X"FF",X"00",X"00",X"40",X"00",X"00",X"00",X"00",X"01",X"80",X"FF",X"80",X"00",X"00",
		X"00",X"00",X"01",X"C0",X"FF",X"C0",X"FF",X"80",X"FF",X"80",X"00",X"A0",X"00",X"E0",X"00",X"00",
		X"00",X"80",X"FE",X"00",X"01",X"80",X"00",X"00",X"00",X"C0",X"FF",X"C0",X"00",X"00",X"00",X"80",
		X"00",X"80",X"00",X"00",X"00",X"80",X"FF",X"00",X"00",X"80",X"01",X"00",X"00",X"C0",X"FF",X"00",
		X"01",X"00",X"00",X"80",X"00",X"00",X"00",X"40",X"01",X"00",X"00",X"C0",X"FF",X"C0",X"00",X"00",
		X"00",X"80",X"00",X"00",X"00",X"C0",X"00",X"00",X"00",X"80",X"00",X"00",X"00",X"80",X"FF",X"A0",
		X"FF",X"C0",X"00",X"00",X"00",X"40",X"00",X"00",X"00",X"E0",X"00",X"00",X"00",X"80",X"00",X"00",
		X"00",X"00",X"00",X"E0",X"00",X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"81",X"00",X"81",X"E0",
		X"80",X"00",X"00",X"55",X"02",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"01",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"81",X"00",X"00",X"00",X"00",X"AA",
		X"01",X"00",X"00",X"00",X"01",X"00",X"00",X"AA",X"00",X"00",X"00",X"AA",X"80",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"66",X"81",X"00",X"81",X"00",
		X"00",X"AA",X"00",X"00",X"00",X"00",X"00",X"00",X"82",X"55",X"01",X"00",X"00",X"00",X"00",X"00",
		X"81",X"00",X"81",X"80",X"80",X"CC",X"00",X"AA",X"01",X"E0",X"00",X"00",X"00",X"80",X"81",X"00",
		X"00",X"55",X"01",X"00",X"00",X"40",X"80",X"00",X"00",X"00",X"00",X"AA",X"00",X"00",X"00",X"00",
		X"00",X"00",X"81",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"82",X"00",X"00",X"00",X"00",X"55",
		X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"82",X"00",X"00",X"00",X"00",X"55",X"01",X"00",
		X"00",X"00",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"82",X"80",X"81",X"80",X"81",X"00",
		X"00",X"00",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"00",X"2B",
		X"01",X"00",X"00",X"00",X"00",X"00",X"06",X"0E",X"1A",X"26",X"38",X"48",X"5C",X"64",X"6C",X"78",
		X"86",X"94",X"A0",X"A6",X"B4",X"03",X"04",X"06",X"06",X"09",X"08",X"0A",X"04",X"04",X"06",X"07",
		X"07",X"06",X"03",X"07",X"04",X"FF",X"00",X"00",X"00",X"C0",X"FF",X"C0",X"FF",X"80",X"FF",X"00",
		X"00",X"FF",X"00",X"80",X"00",X"40",X"00",X"40",X"00",X"00",X"00",X"C0",X"FF",X"C0",X"FF",X"80",
		X"FF",X"00",X"00",X"FF",X"00",X"20",X"00",X"60",X"00",X"40",X"00",X"40",X"00",X"00",X"00",X"01",
		X"FF",X"00",X"00",X"FF",X"00",X"40",X"00",X"80",X"00",X"40",X"00",X"00",X"00",X"01",X"FF",X"00",
		X"00",X"C0",X"00",X"40",X"00",X"40",X"00",X"40",X"00",X"80",X"00",X"20",X"00",X"40",X"00",X"A0",
		X"00",X"00",X"00",X"80",X"FF",X"C0",X"FF",X"C0",X"FF",X"40",X"00",X"C0",X"00",X"20",X"00",X"40",
		X"00",X"20",X"00",X"80",X"00",X"00",X"00",X"80",X"FF",X"C0",X"FF",X"C0",X"FF",X"00",X"00",X"C0",
		X"00",X"40",X"00",X"40",X"00",X"60",X"00",X"60",X"00",X"80",X"00",X"40",X"00",X"40",X"00",X"00",
		X"00",X"C0",X"FF",X"C0",X"FF",X"80",X"FF",X"40",X"00",X"C0",X"00",X"40",X"00",X"40",X"00",X"60",
		X"00",X"20",X"00",X"00",X"00",X"C0",X"FF",X"C0",X"FF",X"80",X"FF",X"00",X"00",X"FF",X"00",X"40",
		X"00",X"40",X"00",X"40",X"00",X"40",X"00",X"00",X"00",X"01",X"FF",X"00",X"00",X"FF",X"00",X"40",
		X"00",X"40",X"00",X"40",X"00",X"40",X"00",X"00",X"00",X"01",X"FF",X"00",X"00",X"FF",X"00",X"40",
		X"00",X"40",X"00",X"40",X"00",X"40",X"00",X"00",X"00",X"01",X"FF",X"00",X"00",X"FF",X"00",X"40",
		X"00",X"40",X"00",X"80",X"00",X"00",X"00",X"C0",X"FF",X"C0",X"FF",X"80",X"FF",X"00",X"00",X"C0",
		X"00",X"40",X"00",X"60",X"00",X"A0",X"00",X"40",X"00",X"40",X"00",X"40",X"00",X"40",X"00",X"00",
		X"00",X"01",X"FF",X"40",X"00",X"C0",X"00",X"80",X"00",X"E0",X"01",X"60",X"FF",X"A0",X"00",X"00",
		X"00",X"40",X"00",X"00",X"00",X"00",X"00",X"80",X"00",X"40",X"FF",X"20",X"02",X"A0",X"FF",X"60",
		X"00",X"00",X"00",X"40",X"00",X"00",X"00",X"20",X"00",X"00",X"00",X"60",X"00",X"A0",X"FF",X"00",
		X"02",X"00",X"00",X"40",X"00",X"00",X"00",X"C0",X"FF",X"00",X"00",X"40",X"00",X"00",X"02",X"00",
		X"00",X"40",X"00",X"00",X"00",X"C0",X"FF",X"C0",X"00",X"40",X"FF",X"A0",X"FF",X"80",X"00",X"00",
		X"00",X"80",X"FF",X"60",X"02",X"00",X"00",X"60",X"FF",X"A0",X"00",X"40",X"00",X"00",X"00",X"80",
		X"00",X"00",X"00",X"80",X"FF",X"80",X"00",X"E0",X"01",X"00",X"00",X"80",X"FF",X"80",X"00",X"40",
		X"00",X"00",X"00",X"C0",X"FF",X"A0",X"FF",X"00",X"00",X"A0",X"00",X"00",X"00",X"60",X"00",X"A0",
		X"FF",X"A0",X"01",X"60",X"FF",X"A0",X"00",X"00",X"00",X"40",X"00",X"00",X"00",X"60",X"00",X"A0",
		X"FF",X"00",X"00",X"80",X"FF",X"20",X"02",X"A0",X"FF",X"60",X"00",X"00",X"00",X"40",X"00",X"00",
		X"00",X"00",X"00",X"40",X"00",X"80",X"00",X"80",X"FF",X"E0",X"01",X"00",X"00",X"40",X"00",X"00",
		X"00",X"A0",X"FF",X"00",X"00",X"80",X"00",X"80",X"FF",X"40",X"02",X"00",X"00",X"40",X"00",X"00",
		X"00",X"20",X"00",X"00",X"00",X"C0",X"00",X"40",X"FF",X"20",X"02",X"00",X"00",X"40",X"00",X"00",
		X"00",X"40",X"00",X"00",X"00",X"C0",X"FF",X"20",X"02",X"80",X"FF",X"80",X"00",X"00",X"00",X"40",
		X"00",X"00",X"00",X"C0",X"FF",X"40",X"00",X"00",X"00",X"A0",X"00",X"60",X"FF",X"00",X"00",X"80",
		X"FF",X"60",X"02",X"00",X"00",X"40",X"00",X"00",X"00",X"80",X"00",X"00",X"00",X"80",X"82",X"80",
		X"02",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"02",X"00",X"83",X"00",X"00",X"80",
		X"81",X"80",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"01",X"00",X"00",X"80",X"01",X"80",
		X"81",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"81",X"00",X"00",X"00",X"01",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"81",X"00",X"03",X"00",X"83",X"C0",X"80",X"00",
		X"04",X"00",X"00",X"CC",X"80",X"00",X"00",X"00",X"00",X"80",X"82",X"80",X"02",X"00",X"01",X"00",
		X"00",X"00",X"04",X"00",X"00",X"00",X"84",X"00",X"01",X"00",X"00",X"00",X"00",X"00",X"82",X"00",
		X"02",X"00",X"00",X"00",X"00",X"00",X"81",X"80",X"81",X"00",X"00",X"AA",X"01",X"00",X"00",X"80",
		X"01",X"80",X"81",X"00",X"00",X"80",X"82",X"80",X"02",X"00",X"00",X"00",X"01",X"00",X"00",X"80",
		X"01",X"80",X"81",X"00",X"00",X"00",X"84",X"00",X"00",X"80",X"81",X"80",X"01",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"01",X"00",X"02",X"00",X"82",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"55",X"81",X"00",X"00",X"00",X"02",X"00",X"82",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"80",X"00",X"00",X"00",X"00",X"03",X"00",X"83",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"01",X"00",X"00",X"80",X"80",X"00",X"00",X"00",X"82",X"00",X"02",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"81",X"AA",X"00",X"00",X"00",X"80",X"02",X"80",X"82",X"00",
		X"00",X"55",X"81",X"00",X"00",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"0E",X"20",X"30",X"40",
		X"46",X"58",X"6E",X"74",X"86",X"9A",X"AA",X"BA",X"CA",X"DE",X"E2",X"07",X"09",X"08",X"08",X"03",
		X"09",X"0B",X"03",X"09",X"0A",X"08",X"08",X"08",X"0A",X"02",X"08",X"FF",X"00",X"00",X"00",X"01",
		X"FF",X"FF",X"00",X"00",X"00",X"80",X"FF",X"80",X"00",X"00",X"00",X"01",X"FF",X"FF",X"00",X"80",
		X"FF",X"FF",X"00",X"00",X"00",X"01",X"FF",X"00",X"00",X"FF",X"00",X"00",X"00",X"01",X"FF",X"00",
		X"00",X"FF",X"00",X"FF",X"00",X"00",X"00",X"80",X"FF",X"81",X"FF",X"00",X"00",X"FF",X"00",X"FF",
		X"00",X"00",X"00",X"01",X"FF",X"00",X"00",X"FF",X"00",X"00",X"00",X"01",X"FF",X"00",X"00",X"FF",
		X"00",X"FF",X"00",X"00",X"00",X"01",X"FF",X"00",X"00",X"FF",X"00",X"00",X"00",X"80",X"FF",X"80",
		X"00",X"00",X"00",X"01",X"FF",X"00",X"00",X"FF",X"00",X"FF",X"00",X"00",X"00",X"80",X"FF",X"81",
		X"FF",X"00",X"00",X"FF",X"00",X"00",X"00",X"01",X"FF",X"00",X"00",X"FF",X"00",X"00",X"00",X"01",
		X"FF",X"FF",X"00",X"01",X"FF",X"FF",X"00",X"00",X"00",X"81",X"FF",X"80",X"FF",X"FF",X"00",X"01",
		X"FF",X"00",X"00",X"FF",X"00",X"00",X"00",X"80",X"FF",X"81",X"FF",X"FF",X"00",X"01",X"FF",X"80",
		X"00",X"80",X"FF",X"00",X"00",X"FF",X"00",X"FF",X"00",X"01",X"FF",X"00",X"FF",X"00",X"02",X"00",
		X"FF",X"00",X"FF",X"80",X"01",X"80",X"00",X"80",X"00",X"80",X"01",X"00",X"FF",X"00",X"03",X"80",
		X"00",X"00",X"FF",X"80",X"01",X"00",X"01",X"00",X"01",X"00",X"01",X"80",X"01",X"00",X"FF",X"00",
		X"02",X"00",X"FF",X"00",X"00",X"00",X"01",X"00",X"00",X"80",X"00",X"00",X"03",X"00",X"01",X"00",
		X"00",X"00",X"01",X"00",X"00",X"80",X"03",X"00",X"FF",X"00",X"02",X"00",X"FF",X"00",X"01",X"00",
		X"01",X"00",X"00",X"00",X"01",X"00",X"00",X"80",X"02",X"00",X"FF",X"80",X"01",X"80",X"00",X"00",
		X"00",X"00",X"01",X"00",X"00",X"00",X"01",X"00",X"01",X"00",X"00",X"80",X"01",X"80",X"FF",X"00",
		X"00",X"80",X"01",X"00",X"00",X"80",X"01",X"00",X"00",X"80",X"00",X"00",X"00",X"00",X"01",X"00",
		X"00",X"00",X"01",X"80",X"00",X"00",X"01",X"80",X"00",X"80",X"FF",X"00",X"00",X"80",X"00",X"00",
		X"01",X"80",X"00",X"00",X"FF",X"80",X"01",X"80",X"00",X"00",X"00",X"00",X"01",X"80",X"00",X"80",
		X"00",X"80",X"00",X"80",X"01",X"00",X"FF",X"00",X"01",X"00",X"01",X"00",X"81",X"00",X"00",X"00",
		X"81",X"00",X"81",X"00",X"00",X"00",X"01",X"00",X"01",X"00",X"00",X"00",X"81",X"00",X"01",X"00",
		X"01",X"00",X"81",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"81",X"00",
		X"01",X"00",X"81",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"01",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"81",X"00",X"01",X"00",X"81",X"00",X"01",X"00",
		X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"81",X"00",X"01",X"00",X"01",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"00",X"00",X"81",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"01",X"00",X"81",X"00",X"01",X"00",X"00",X"00",X"81",X"00",X"00",X"00",X"00",X"00",
		X"01",X"00",X"00",X"00",X"81",X"00",X"00",X"00",X"01",X"00",X"00",X"00",X"01",X"00",X"81",X"00",
		X"01",X"00",X"01",X"00",X"00",X"00",X"81",X"00",X"01",X"00",X"01",X"00",X"00",X"00",X"00",X"06",
		X"16",X"28",X"34",X"46",X"5E",X"76",X"90",X"9C",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"08",
		X"09",X"06",X"09",X"0C",X"0C",X"0D",X"06",X"02",X"00",X"00",X"00",X"FF",X"00",X"FF",X"00",X"FF",
		X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"FF",
		X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"FF",X"00",X"00",X"00",X"00",X"FF",X"00",
		X"00",X"00",X"01",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"FF",X"00",X"00",X"00",X"01",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
