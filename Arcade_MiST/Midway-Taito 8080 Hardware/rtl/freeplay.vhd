-- Coin Up style hardware device for games that do not have freeplay option
--
-- version 1 initial release
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;


entity freeplay is
	generic(
		count : integer := 20000;	-- About 1/10 second in cycles
		delay : integer := 1 		-- Delay between coin and start
	);
	port (
    i_clk             : in   std_logic;

    -- control signals in
    i_coin            : in   std_logic;
    i_start1          : in   std_logic;
    i_start2          : in   std_logic;

    -- control signals out
    o_coin            : out  std_logic;
    o_start1          : out  std_logic;
    o_start2          : out  std_logic;
	 
    -- other
    enable            : in   std_logic
  );
end;

architecture RTL of freeplay is

  signal counter			: integer := 0;
  signal last_start1		: std_logic;
  signal last_start2		: std_logic;
  signal Start          : std_logic_vector(1 downto 0);
  signal DelayCount     : integer;
  
  type FlowControl is (Idle, Clear_Coin, Set_Coin, Set_Start, DelayLoop, Clear_Start);
  signal sequence       : FlowControl := Idle;
  
begin

  main : process
  begin
    wait until rising_edge(i_clk);
	 if (enable = '1') then
		if (sequence = Idle) then
			
			last_start1 <= i_start1;
			last_start2 <= i_start2;
			
			if (i_start1 = '1' and last_start1 = '0') then
				-- Kick on 1 coin followed by start 1
				counter <= 0;
				o_coin <= '1';
				Start <= "01";
				DelayCount <= delay;
				sequence <= DelayLoop;
			else 
				if (i_start2 = '1' and last_start2 = '0') then
					-- Kick off 2 x coin followed by start 2
					counter <= 0;
					o_coin <= '1';
					Start <= "10";
					DelayCount <= delay;
					sequence <= Clear_Coin;
				end if;
			end if;
		else
			if (counter = count) then
			
				-- sequence of events for one or two coins
				-- Pulses coin once or twice for count cycles
				-- then delays for required time before pressing start
				
				counter <= 0;
				
				case sequence is
				
					when Clear_Coin => 
								o_coin <= '0';
								sequence <= Set_Coin;
									  
					when Set_Coin => 
								o_coin <= '1';
								sequence <= DelayLoop;					
										
					when DelayLoop => 
								o_coin <= '0';
								if (DelayCount = 0) then
									sequence <= Set_Start;
								else
									DelayCount <= DelayCount - 1;
								end if;
								
					when Set_Start => 
								o_start1 <= Start(0);
								o_start2 <= Start(1);
								sequence <= Clear_Start;

					when Clear_Start => 
								o_start1 <= '0';
					         o_start2 <= '0';
								sequence <= Idle;
									  
					when others => 
					         -- Should not happen, but just in case
								sequence <= Clear_Start;
					
				end case;
			else
				counter <= counter + 1;
			end if;
		end if;		 
	 else
		-- Normal, just pass through real buttons
		o_coin <= i_coin;
		o_start1 <= i_start1;
		o_start2 <= i_start2;
	 end if;
		
  end process;
  
end architecture RTL;

