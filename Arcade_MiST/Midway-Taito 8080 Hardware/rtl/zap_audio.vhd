library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.Numeric_Std.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity zap_audio is
	Port (
	  Clk : in  std_logic;
	  S1  : in  std_logic_vector(5 downto 0);
	  S2  : in  std_logic_vector(5 downto 0);
	  Aud : out std_logic_vector(15 downto 0)
	  );
end;

 --* Port 3: (S1)
 --* bit 0= sound freq
 --* bit 1= sound freq
 --* bit 2= sound freq
 --* bit 3= sound freq
 --* bit 4= HI SHIFT MODIFIER
 --* bit 5= LO SHIFT MODIFIER
 --* bit 6= NC
 --* bit 7= NC
 --*
 --* Port 5: (S2)
 --* bit 0= BOOM sound
 --* bit 1= ENGINE sound
 --* bit 2= Screeching Sound
 --* bit 3= after car blows up, before it appears again
 --* bit 4= NC
 --* bit 5= coin counter
 --* bit 6= NC
 --* bit 7= NC

 
-- This is a simplified integer mathmatic model that produces results in line with the real thing
--
-- C18 and C19 are capacitors with counters 15 bit range from 0 (empty) to 23250 (full)
--
-- Clocked from 10Mhz 
--
-- C18 changes up/down to get to Accelerator setting (4 bits) * 1550
--       charge add 1 every 945 (2.2 seconds empty to full)
--			discharge subtract 1 every 215 cycles (0.5 seconds from full to empty)
--
--C19 - we use this to drive output in high gear 
--
--    low gear 
--			subtract 1 every 8 cycles (fast discharge)
--
--    high gear - timings from you tube
--       add 1 every 1462 cycles (5 seconds) 
--       subtract 1 every 731 cycles (1.7 seconds)
--			
--oscillators all count from 0 to 127 and back down again, with a count derived from C19
--
-- Low Gear
--OSC1 count = Cap / 64
--OSC2 count = Cap / 256
--OSC3 count = (OSC2 count / 2) + (OSC2 count / 4) + (OSC2 count) / 16 (gives * 0.8125 but all bit manipulation)
--
-- High Gear - as above, but using C19 as source
--
-- OSC3 implemented by base 2 logarithm mask lookup OSC1 + OSC2 (bit shifted to give 15 bits)
--
--if enginenoise is turned off, C18 = C19 = 0

architecture Behavioral of zap_audio is

	type MASK is array(NATURAL range <>) of std_logic_vector(15 downto 0);
	
	constant lookup : MASK := (
		X"0001",X"0003",X"0007",X"000F",X"001F",X"003F",X"007F",X"007F",X"007F",X"00FF",X"00FF",X"00FF",X"00FF",X"01FF",X"01FF",X"01FF",
		X"01FF",X"01FF",X"01FF",X"03FF",X"03FF",X"03FF",X"03FF",X"03FF",X"03FF",X"03FF",X"03FF",X"03FF",X"03FF",X"03FF",X"07FF",X"07FF",
		X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",X"07FF",
		X"07FF",X"07FF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",
		X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"0FFF",
		X"0FFF",X"0FFF",X"0FFF",X"0FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",
		X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",
		X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",
		X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"1FFF",X"3FFF",
		X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",
		X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",
		X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",
		X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",
		X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",
		X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",
		X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"3FFF",X"7FFF",X"7FFF",X"7FFF",X"7FFF",X"7FFF");

	-- Signals
	signal Target		: unsigned(14 downto 0) := (others => '0');

	-- Capacitors	
	signal C18				: unsigned(14 downto 0) := (others => '0');
	signal C19				: unsigned(14 downto 0) := (others => '0');
	signal C18Count		: unsigned(9 downto 0) := (others => '0');
	signal C19Count		: unsigned(11 downto 0) := (others => '0');

	-- Oscillators
	signal OSC1Out		: unsigned(6 downto 0) := (others => '0');
	signal OSC2Out		: unsigned(6 downto 0) := (others => '0');
	signal OSC3Out		: unsigned(6 downto 0) := (others => '0');
	signal OSC1Count  : unsigned(12 downto 0) := (others => '0');
	signal OSC2Count  : unsigned(10 downto 0) := (others => '0');
	signal OSC3Count  : unsigned(10 downto 0) := (others => '0'); 
	signal OSC1Up     : std_logic := '1';
	signal OSC2Up     : std_logic := '1';
	signal OSC3Up     : std_logic := '1';
	signal OSC1Target : unsigned(12 downto 0) := (others => '0'); 
	signal OSC2Target : unsigned(10 downto 0) := (others => '0'); 
	signal OSC3Target : unsigned(10 downto 0) := (others => '0'); 

begin

Engine : process(clk)
variable OSCIn : unsigned(14 downto 0);
variable X : unsigned(10 downto 0);
variable Rev : std_logic_vector(7 downto 0);
variable Rev16 : std_logic_vector(15 downto 0);
begin
  if(rising_edge(Clk)) then
		-- Where we want C18 to get to
		Target <= to_unsigned(1550,11) * unsigned(S1(3 downto 0)); 

		-- Feed for oscillators
		if (S1(5) = '1') then
			OSCIn := C18 + 1000;
		else
			OSCIn := C19 + 1500;
		end if;

		if S2(1)='1' then -- Engine noise off
		
			C18Count <= (others => '0');
			C19Count <= (others => '0');
			C18 <= (others => '0');
			C19 <= (others => '0');
		
			OSC1Count <= (others => '0');
			OSC1Target <= (others => '0'); 
			OSC2Count <= (others => '0');
			OSC2Target <= (others => '0'); 
			OSC3Count <= (others => '0');
			OSC3Target <= (others => '0'); 
			
			Aud <= (others => '0');
			
		else

			-- C18 Capacitor (controlled by Target)
			if Target > C18 and C18Count = 945 then
				C18Count <= (others => '0');
				C18 <= C18 + 1;
			else
				if Target < C18  and C18Count = 215 then
					C18Count <= (others => '0');
					C18 <= C18 - 1;
				else
					C18Count <= C18Count + 1;
				end if;
			end if;

			if (S1(5) = '1') then
				-- Low Gear, discharges C19
				if C19Count = to_unsigned(8,10) and C19 /= 0 then
					C19Count <= (others => '0');
					C19 <= C19 - 1;
				end if;
			else
				-- High Gear, C19 wants to equal output over 5 seconds (ish)
				-- really done by feedback, but simpler this way
				if Target > C19 and C19Count = 2100 then
					C19Count <= (others => '0');
					C19 <= C19 + 1;
				else
					if Target < C19 and C19Count = 731 then
						C19 <= C19 - 1;
					else
						C19Count <= C19Count + 1;
					end if;
				end if;
			end if;
		
		end if;
		
		-- Oscillators
		if OSC1Count = OSC1Target then
			OSC1Count <= (others => '0');
			OSC1Target <= (to_unsigned(7631,13) - OSCIn(14 downto 2));
			if OSC1Up='1' then
				-- Counting up
				if OSC1Out = 127 then
					OSC1Up <= '0';
				else
					OSC1Out <= OSC1Out + 1;
				end if;
			else
				-- Counting down
				if OSC1Out = 0 then
					OSC1Up <= '1';
				else
					OSC1Out <= OSC1Out - 1;
				end if;
			end if;
		else
			OSC1Count <= OSC1Count + 1;
		end if;

		if OSC2Count = OSC2Target then
			OSC2Count <= (others => '0');
			OSC2Target <= (to_unsigned(1907,11) - OSCIn(14 downto 4));
			if OSC2Up='1' then
				-- Counting up
				if OSC2Out = 127 then
					OSC2Up <= '0';
				else
					OSC2Out <= OSC2Out + 1;
				end if;
			else
				-- Counting down
				if OSC2Out = 0 then
					OSC2Up <= '1';
				else
					OSC2Out <= OSC2Out - 1;
				end if;
			end if;
		else
			OSC2Count <= OSC2Count + 1;
		end if;

		if OSC3Count = OSC3Target then
			OSC3Count <= (others => '0');
			X := (to_unsigned(953,11) - OSCIn(14 downto 5)); -- OSC2/2
			OSC3Target <= X + X(9 downto 1) + X(9 downto 4); -- (OSC2 count / 2) + (OSC2 count / 4) + (OSC2 count) / 16
			IF S2(1)='1' then
				OSC3Out <= (others => '0');
			else
				if OSC3Up='1' then
					-- Counting up
					if OSC3Out = 127 then
						OSC3Up <= '0';
					else
						OSC3Out <= OSC3Out + 1;
					end if;
				else
					-- Counting down
					if OSC3Out = 0 then
						OSC3Up <= '1';
					else
						OSC3Out <= OSC3Out - 1;
					end if;
				end if;
			end if;
		else
			OSC3Count <= OSC3Count + 1;
		end if;
		
		-- Output
		Rev := std_logic_vector(('0' &OSC1Out) + OSC2Out);									-- Add OSC1 and OSC2 together
		Rev16(15) := '0';																				-- extend to 16 bits 
		Rev16(14 downto 7) := Rev(7 downto 0);
		Rev16(6 downto 0) := Rev(7 downto 1); 									
		Aud <= Rev16 and lookup(to_integer(unsigned(OSC3Out(6 downto 0) & '0')));	-- Mask volume according to OSC3
		
	end if;
end process;

end Behavioral;
