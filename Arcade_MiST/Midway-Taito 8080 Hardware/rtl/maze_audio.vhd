--
-- Amazing Maze music
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity MAZE_MUSIC is
  port (
    I_JOYSTICK        : in  std_logic_vector(3 downto 0);
	 I_COIN            : in  std_logic;
    --
    O_TRIGGER         : out std_logic_vector(7 downto 0);
    CLK               : in  std_logic
    );
end;

architecture RTL of MAZE_MUSIC is

	signal OnTimer   : integer := 300000000;
	signal NoteTimer : integer := 0;
	
begin

	process (CLK)
	begin
		if rising_edge(CLK) then

			-- 30 second timer since last activated
		
			if OnTimer = 0 then
				-- Coin restarts 30 seconds
				if I_COIN = '1' then
					OnTimer <= 300000000;
				end if;
			else
				OnTimer <= OnTimer - 1;
			end if;
			
			-- Anything playing / pressed (whilst still active)
			if NoteTimer = 0 then
				if I_JOYSTICK /= "0000" and OnTimer /= 0 then
					-- button pressed, so reset timers and trigger sample
					OnTimer <= 300000000;
					NoteTimer <= 4682000;
					if I_JOYSTICK(3)='1' then
						O_TRIGGER <= "00000001";
					else
						if I_JOYSTICK(2)='1' then
							O_TRIGGER <= "00000010";
						else
							if I_JOYSTICK(1)='1' then
								O_TRIGGER <= "00000100";
							else
								O_TRIGGER <= "00001000";
							end if;
						end if;
					end if;
				end if;
			else
				NoteTimer <= NoteTimer - 1;
				-- clear trigger ready for next sample
				if NoteTimer < 2000 then
					O_TRIGGER <= "00000000";
				end if;
			end if;			
		end if;
	end process;
	
end architecture RTL;
