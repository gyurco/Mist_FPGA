-- Space Invaders core logic
-- 9.984MHz clock
--
-- Version : 0242
--
-- Copyright (c) 2002 Daniel Wallner (jesus@opencores.org)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--      http://www.fpgaarcade.com
--
-- Limitations :
--
-- File history :
--
--      0241 : First release
--
--      0242 : Cleaned up reset logic
--
--      0300 : MikeJ tidyup for audio release

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity invaderst is
	port(
		Rst_n           : in  std_logic;
		Clk             : in  std_logic;
		ENA             : out  std_logic;

		GDB0            : in std_logic_vector(7 downto 0);
		GDB1            : in std_logic_vector(7 downto 0);
		GDB2            : in std_logic_vector(7 downto 0);
		GDB3            : in std_logic_vector(7 downto 0);
		GDB4            : in std_logic_vector(7 downto 0);
		GDB5            : in std_logic_vector(7 downto 0);
		GDB6            : in std_logic_vector(7 downto 0);

		RDB             : in  std_logic_vector(7 downto 0);
		IB              : in  std_logic_vector(7 downto 0);
		RWD             : out std_logic_vector(7 downto 0);
		RAB             : out std_logic_vector(12 downto 0);
		AD              : out std_logic_vector(15 downto 0);
		SoundCtrl3      : out std_logic_vector(7 downto 0);
		SoundCtrl5      : out std_logic_vector(7 downto 0);
		Tone_Low        : out std_logic_vector(5 downto 0);
		Tone_High       : out std_logic_vector(7 downto 0);
		Rst_n_s         : out std_logic;
		RWE_n           : out std_logic;
		CPU_RW_n        : out std_logic; -- for colour ram decode		
		Video           : out std_logic;

		color_prom_out  : in  std_logic_vector(7 downto 0);
		color_prom_addr : out std_logic_vector(10 downto 0);
		ScreenFlip      : in  std_logic;
		Overlay_Align   : in  std_logic;
					 
		O_VIDEO_R       : out std_logic;
		O_VIDEO_G       : out std_logic;
		O_VIDEO_B       : out std_logic;
		O_VIDEO_A       : out std_logic;
		
		WD_Enabled      : in std_logic;
		Overlay         : in std_logic;
		OverlayTest     : in std_logic;
		
		VBlank          : out std_logic;
		HBlank          : out std_logic;

		HSync           : out std_logic;
		VSync           : out std_logic;

		VShift		    : in  std_logic_vector(3 downto 0);
		HShift		    : in  std_logic_vector(3 downto 0);

		pause           : in std_logic;

		-- PortWR triggers
		Trigger_ShiftCount    : in std_logic;
		Trigger_ShiftData     : in std_logic;
		Trigger_AudioDeviceP1 : in std_logic;
		Trigger_AudioDeviceP2 : in std_logic;
		Trigger_WatchDogReset : in std_logic;
		Trigger_Tone_Low      : in std_logic;
		Trigger_Tone_High     : in std_logic;

		PortWr       			 : out std_logic_vector(7 downto 0);

		-- output of shifter
		S            			 : out std_logic_vector(7 downto 0);
		ShiftReverse 			 : out std_logic;

		mod_vortex      		 :	in std_logic;
		overclock      		 :	in std_logic;
		Vortex_Col      		 : in std_logic
);
end invaderst;

architecture rtl of invaderst is

	component mw8080
	port(
		Rst_n           : in  std_logic;
		Clk             : in  std_logic;
		ENA             : out  std_logic;
		RWE_n           : out std_logic;
		RDB             : in  std_logic_vector(7 downto 0);
		RAB             : out std_logic_vector(12 downto 0);
		Sounds          : out std_logic_vector(7 downto 0);
		Ready           : out std_logic;
		GDB             : in  std_logic_vector(7 downto 0);
		IB              : in  std_logic_vector(7 downto 0);
		DB              : out std_logic_vector(7 downto 0);
		AD              : out std_logic_vector(15 downto 0);
		Status          : out std_logic_vector(7 downto 0);
		Systb           : out std_logic;
		Int             : out std_logic;
		Hold_n          : in  std_logic;
		IntE            : out std_logic;
		DBin_n          : out std_logic;
		Vait            : out std_logic;
		HldA            : out std_logic;
		Sample          : out std_logic;
		Wr              : out std_logic;
		Video           : out std_logic;
		color_prom_out  : in  std_logic_vector(7 downto 0);
		color_prom_addr : out std_logic_vector(10 downto 0);
		O_VIDEO_R       : out std_logic;
		O_VIDEO_G       : out std_logic;
		O_VIDEO_B       : out std_logic;
		O_VIDEO_A       : out std_logic;
		Overlay         : in std_logic;
		OverlayTest     : in std_logic;
		ScreenFlip      : in std_logic;
		Overlay_Align   : in std_logic;

		VBlank          : out std_logic;
		HBlank          : out std_logic;
		HSync           : out std_logic;
		VSync           : out std_logic;
		
		VShift		    : in  std_logic_vector(3 downto 0);
		HShift		    : in  std_logic_vector(3 downto 0);

	   mod_vortex      : in std_logic;
		overclock       : in std_logic;
		Vortex_Col      : in std_logic;
		pause           : in std_logic
	);
	end component;

	signal GDB          : std_logic_vector(7 downto 0);
	signal DB           : std_logic_vector(7 downto 0);
	signal Sounds       : std_logic_vector(7 downto 0);
	signal AD_i         : std_logic_vector(15 downto 0);
	signal CPU_WR	     : std_logic;

	signal EA           : std_logic_vector(2 downto 0);
	signal A           : std_logic_vector(2 downto 0);
	signal D5           : std_logic_vector(15 downto 0);
	signal WD_Cnt       : unsigned(7 downto 0);
	signal Sample       : std_logic;
	signal Rst_n_s_i    : std_logic;
	signal GDB_A        : unsigned(2 downto 0);
	
begin

	Rst_n_s <= Rst_n_s_i;
	RWD <= DB;
	AD <= AD_i;
	CPU_RW_n <= CPU_WR;

	process (Rst_n, Clk)
		variable Rst_n_r : std_logic;
	begin
		if Rst_n = '0' then
			Rst_n_r := '0';
			Rst_n_s_i <= '0';
		elsif Clk'event and Clk = '1' then
			Rst_n_s_i <= Rst_n_r;
			if WD_Cnt = 255 and WD_Enabled='1' then
				Rst_n_s_i <= '0';
			end if;
			Rst_n_r := '1';
		end if;
	end process;

	process (Rst_n_s_i, Clk)
		variable Old_S0 : std_logic;
	begin
		if Rst_n_s_i = '0' then
			WD_Cnt <= (others => '0');
			Old_S0 := '1';
		elsif Clk'event and Clk = '1' then
			if Sounds(0) = '1' and Old_S0 = '0' then
				WD_Cnt <= WD_Cnt + 1;
			end if;
			if Trigger_WatchDogReset = '1' then
				WD_Cnt <= (others => '0');
			end if;
			Old_S0 := Sounds(0);
		end if;
	end process;

	u_mw8080: mw8080
		port map(
			Rst_n => Rst_n_s_i,
			Clk => Clk,
			ENA => ENA,
			RWE_n => RWE_n,
			RDB => RDB,
			IB => IB,
			RAB => RAB,
			Sounds => Sounds,
			Ready => open,
			GDB => GDB,
			DB => DB,
			AD => AD_i,
			Status => open,
			Systb => open,
			Int => open,
			Hold_n => '1',
			IntE => open,
			DBin_n => open,
			Vait => open,
			HldA => open,
			Sample => Sample,
			Wr => CPU_WR,
			Video => Video,
			color_prom_out  => color_prom_out,
			color_prom_addr => color_prom_addr,
			O_VIDEO_R => O_VIDEO_R,
			O_VIDEO_G => O_VIDEO_G,
			O_VIDEO_B => O_VIDEO_B,
			O_VIDEO_A => O_VIDEO_A,
			Overlay => Overlay,
			OverlayTest => OverlayTest,
			ScreenFlip => ScreenFlip,
			Overlay_Align => Overlay_Align,
			VBlank => VBlank,
			HBlank => HBlank,
			HSync => HSync,
			VSync => VSync,
			VShift => VShift,
			HShift => HShift,
			mod_vortex => mod_vortex,
			overclock => overclock,
			Vortex_Col => Vortex_Col,
			pause => pause
		);


        with (mod_vortex) select
                GDB_A <= 
			  AD_i(10) & not AD_i(9) & AD_i(8) when '1',
			   AD_i(10) & AD_i(9) & AD_i(8) when '0';

	--with AD_i(9 downto 8) select
	with GDB_A select
		GDB <= GDB0 when "000",
				GDB1 when "001",
				GDB2 when "010",
				GDB3 when "011",
				GDB4 when "100",
				GDB5 when "101",
				GDB6 when others;

	PortWr(0) <= '1' when AD_i(10 downto 8) = "000" and Sample = '1' else '0';
	PortWr(1) <= '1' when AD_i(10 downto 8) = "001" and Sample = '1' else '0';
	PortWr(2) <= '1' when AD_i(10 downto 8) = "010" and Sample = '1' else '0';
	PortWr(3) <= '1' when AD_i(10 downto 8) = "011" and Sample = '1' else '0';
	PortWr(4) <= '1' when AD_i(10 downto 8) = "100" and Sample = '1' else '0';
	PortWr(5) <= '1' when AD_i(10 downto 8) = "101" and Sample = '1' else '0';
	PortWr(6) <= '1' when AD_i(10 downto 8) = "110" and Sample = '1' else '0';
	PortWr(7) <= '1' when AD_i(10 downto 8) = "111" and Sample = '1' else '0';


	process (Rst_n_s_i, Clk)
		variable OldSample : std_logic;
	begin
		if Rst_n_s_i = '0' then
			D5 <= (others => '0');
			EA <= (others => '0');
			SoundCtrl3 <= (others => '0');
			SoundCtrl5 <= (others => '0');
			OldSample := '0';
			ShiftReverse <= '0';
		elsif Clk'event and Clk = '1' then
			if Trigger_ShiftCount = '1' then
				EA <= DB(2 downto 0);
				ShiftReverse <= DB(3);
			end if;
			if Trigger_AudioDeviceP1 = '1' then
				SoundCtrl3 <= DB(7 downto 0);
			end if;
			if Trigger_ShiftData = '1' and OldSample = '0' then
				D5(15 downto 8) <= DB;
				D5(7 downto 0) <= D5(15 downto 8);
			end if;
			if Trigger_AudioDeviceP2 = '1' then
				SoundCtrl5 <= DB(7 downto 0);
			end if;
			if Trigger_Tone_Low = '1' then
				Tone_Low <= DB(5 downto 0);
			end if;
			if Trigger_Tone_High = '1' then
				Tone_High <= DB(7 downto 0);
			end if;
			OldSample := Sample;
		end if;
	end process;


	with EA select
		S <= D5(15 downto 8) when "000",
		     D5(14 downto 7) when "001",
		     D5(13 downto 6) when "010",
		     D5(12 downto 5) when "011",
		     D5(11 downto 4) when "100",
		     D5(10 downto 3) when "101",
		     D5( 9 downto 2) when "110",
		     D5( 8 downto 1) when others;

end;
