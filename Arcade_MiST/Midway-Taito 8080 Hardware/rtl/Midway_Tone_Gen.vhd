library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ToneGen is
port(
	 -- Sound related
	 Tone_enabled   : in  std_logic;
	 Tone_Low       : in  std_logic_vector(5 downto 0);
	 Tone_High      : in  std_logic_vector(5 downto 0);
	 
	 Tone_out       : out std_logic_vector(15 downto 0);
	 
	 -- Clocks and things
	 CLK_SYS        : in  std_logic; -- 10Mhz
	 reset          : in  std_logic  -- high to reset
 );
end ToneGen;

architecture struct of ToneGen is

 -- Clock dividers
 signal Tone_clk_cnt : std_logic_vector(5 downto 0); -- Main frequency = clock / 40
 signal Tone_Out_en  : std_logic := '0';
 
 signal Tone_count   : std_logic_vector(11 downto 0);
 signal Tone_clk     : std_logic;
 
begin

-- Get clock for main counter (sys clock / 20)

process (CLK_SYS,reset)
variable ID : integer;
begin
	if rising_edge(CLK_SYS) then
		if reset='1' then
			Tone_clk_cnt <= (others=>'0');
			Tone_Out_en  <= '0';
		else
			if Tone_clk_cnt = "100111" then
				Tone_clk_cnt <= (others=>'0');
				Tone_Out_en <= '1';
			else
				Tone_clk_cnt <= Tone_clk_cnt + 1;
				Tone_Out_en <= '0';
			end if;
		end if;
	end if;
end process;
 
---------------
-- Generator --
---------------

process (CLK_SYS,reset,Tone_enabled)
begin

	if reset='1' or Tone_enabled='0' then
		Tone_count <= (others=>'0');
		Tone_out   <= (others=>'0');
	else 
		if rising_edge(CLK_SYS) then
			if (Tone_Out_en='1') then				
				if Tone_count = x"FFF" then
					Tone_clk   <= not Tone_clk;
					Tone_Count <= Tone_High & Tone_Low;
					if Tone_clk='1' then
						Tone_out <= x"6000";
					else
						Tone_out <= (others=>'0');
					end if;
				else
					Tone_count <= Tone_count + 1;
				end if;
			end if; -- Tone_Out_EN
		end if; -- rising clock

	end if; -- reset
						
end process;

end;
