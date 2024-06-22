--
-- Balloon Bomber music
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity BALLOON_MUSIC is
  port (
    I_MUSIC_ON        : in  std_logic;
    I_TONE            : in  std_logic_vector(7 downto 0);
    --
    O_AUDIO           : out std_logic_vector(15 downto 0);
    CLK               : in  std_logic
    );
end;

architecture RTL of BALLOON_MUSIC is

	-- global
	signal AUDIO_EN     : std_logic := '0';
	signal CLOCK_CNT    : integer := 0;
	-- Music --
	signal W_2CD_LDn    : std_logic := '0';
	signal LAST_2CD_LDn : std_logic := '0';
	signal W_2CD_Q      : std_logic_vector(7 downto 0) := (others => '0');
	signal W_4E_Q       : std_logic_vector(2 downto 0) := (others => '0');
	signal W_SDAT1      : std_logic_vector(7 downto 0) := (others => '0');
	signal W_SDAT2      : std_logic_vector(7 downto 0) := (others => '0');
	signal MUSIC_OUT    : std_logic_vector(7 downto 0) := (others => '0');
	
begin
	--
	-- Music runs from 31,948 hz clock
	--
	process (CLK)
	begin
		if rising_edge(CLK) then
			-- 10 Mhz / 313 = 31948 Hz
			if CLOCK_CNT=312 then
				CLOCK_CNT <= 0;
				AUDIO_EN <= '1';
			else
				CLOCK_CNT <= CLOCK_CNT + 1;
				AUDIO_EN <= '0';
			end if;
		end if;
	end process;
	
	process (CLK)
	begin
		if rising_edge(CLK) then  
			if (AUDIO_EN='1') then
				if (W_2CD_LDn = '0') then
					W_2CD_Q <= I_TONE;
				else
					W_2CD_Q <= W_2CD_Q + 1;
				end if;
			end if;
		end if;
	end process;
	
	process (CLK)
	begin
		if rising_edge(CLK)  then
			if (AUDIO_EN='1') then
				if (W_2CD_Q = x"ff") then
					W_2CD_LDn <= '0' ;
				else
					W_2CD_LDn <= '1' ;
				end if;
			end if;
		end if;
	end process;

	process (CLK)
	begin
		if rising_edge(CLK) then
		
			LAST_2CD_LDn <= W_2CD_LDn;
			
			-- Equivalent to Falling Edge W_2CD_LDn
			if (LAST_2CD_LDn='1' and W_2CD_LDn='0') then
				if W_4E_Q = "100" then
					-- Resets at 5
					W_4E_Q <= "000";
				else
					W_4E_Q <= W_4E_Q + 1;
				end if;
			end if;
		end if;
	end process;

	process (CLK)
	begin
		if rising_edge(CLK) then
			if (AUDIO_EN='1') then
				if I_MUSIC_ON='1' then
					MUSIC_OUT <= (W_SDAT1 + W_SDAT2);
				else
					MUSIC_OUT <= (others => '0');
				end if;

				if W_4E_Q(1)='1' then
					W_SDAT1 <= x"2a";
				else
					W_SDAT1 <= (others => '0');
				end if;

				if W_4E_Q(2)='1' then
					W_SDAT2 <= x"69";
				else
					W_SDAT2 <= (others => '0');
				end if;
			end if;
		end if;		
	end process;

	-- Ouput it
	O_AUDIO <= '0' & MUSIC_OUT & "0000000";
	
end architecture RTL;
