library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.video_controller_pkg.all;

entity mpatrol is
	port (
		clk_sys : in std_logic;
		reset : in std_logic;
		palmode : in std_logic;
		switches_i : from_SWITCHES_t;

		p1_left  : in std_logic;
		p1_right : in std_logic;
		p1_up    : in std_logic;
		p1_down  : in std_logic; 
		p1_fireA : in std_logic;
		p1_fireB : in std_logic;
		p1_start : in std_logic;

		p2_left  : in std_logic;
		p2_right : in std_logic;
		p2_up    : in std_logic;
		p2_down  : in std_logic;
		p2_fireA : in std_logic;
		p2_fireB : in std_logic;
		p2_start : in std_logic;

		coin1    : in std_logic;
		coin2    : in std_logic;

		sound_data : out std_logic_vector(7 downto 0);
		video_r : out std_logic_vector(5 downto 0);
		video_g : out std_logic_vector(5 downto 0);
		video_b : out std_logic_vector(5 downto 0);
		video_hs: out std_logic;
		video_vs: out std_logic;
		video_hb: out std_logic;
		video_vb: out std_logic
  );    
end mpatrol;

architecture SYN of mpatrol is

  signal init       		: std_logic := '1';  
  signal clkrst_i       : from_CLKRST_t;
  signal buttons_i      : from_BUTTONS_t;
  signal leds_o         : to_LEDS_t;
  signal inputs_i       : from_INPUTS_t;
  signal video_i        : from_VIDEO_t;
  signal video_o        : to_VIDEO_t;

begin

	clkrst_i.clk(0)	<=	clk_sys;
	clkrst_i.clk(1)	<=	clk_sys;

	video_i.clk     <= clk_sys;
	video_i.clk_ena <= '1';
	video_i.reset 	<= clkrst_i.rst(1);

--RESET

	process (clk_sys) begin
		if rising_edge(clk_sys) then
			clkrst_i.arst    <= reset;
			clkrst_i.arst_n  <= not reset;
		end if;
	end process;

  GEN_RESETS : for i in 0 to 3 generate

    process (clkrst_i)
      variable rst_r : std_logic_vector(2 downto 0) := (others => '0');
    begin
      if clkrst_i.arst = '1' then
        rst_r := (others => '1');
      elsif rising_edge(clkrst_i.clk(i)) then
        rst_r := rst_r(rst_r'left-1 downto 0) & '0';
      end if;
      clkrst_i.rst(i) <= rst_r(rst_r'left);
    end process;

  end generate GEN_RESETS;	 
	 
	inputs_i.jamma_n.coin(1) <= not coin1;
	inputs_i.jamma_n.p(1).start <= not p1_start;
	inputs_i.jamma_n.p(1).up <= not p1_up;
	inputs_i.jamma_n.p(1).down <= not p1_down;
	inputs_i.jamma_n.p(1).left <= not p1_left;
	inputs_i.jamma_n.p(1).right <= not p1_right;
	inputs_i.jamma_n.p(1).button(1) <= not p1_fireA;--Fire
	inputs_i.jamma_n.p(1).button(2) <= not p1_fireB;--Jump
	inputs_i.jamma_n.p(1).button(3) <= '1';
	inputs_i.jamma_n.p(1).button(4) <= '1';
	inputs_i.jamma_n.p(1).button(5) <= '1';		
	inputs_i.jamma_n.p(2).start <= not p2_start;
	inputs_i.jamma_n.p(2).up <= not p2_up;
	inputs_i.jamma_n.p(2).down <= not p2_down;
	inputs_i.jamma_n.p(2).left <= not p2_left;
	inputs_i.jamma_n.p(2).right <= not p2_right;
	inputs_i.jamma_n.p(2).button(1) <= not p2_fireA;--Fire
	inputs_i.jamma_n.p(2).button(2) <= not p2_fireB; --Jump
	inputs_i.jamma_n.p(2).button(3) <= '1';
	inputs_i.jamma_n.p(2).button(4) <= '1';
	inputs_i.jamma_n.p(2).button(5) <= '1';
	-- not currently wired to any inputs
	inputs_i.jamma_n.coin_cnt <= (others => '1');
	inputs_i.jamma_n.coin(2) <= not coin2;
	inputs_i.jamma_n.service <= '1';
	inputs_i.jamma_n.tilt <= '1';
	inputs_i.jamma_n.test <= '1';

	pace_inst : entity work.pace                                            
		port map (
			clkrst_i				=> clkrst_i,
			palmode         => palmode,
			buttons_i       => buttons_i,
			switches_i      => switches_i,
			leds_o          => open,
			inputs_i        => inputs_i,
			video_i         => video_i,
			video_o         => video_o,
			sound_data_o 		=> sound_data
		);

		video_hs <= not video_o.hsync;
		video_vs <= not video_o.vsync;
		video_hb <= video_o.hblank;
		video_vb <= video_o.vblank;
		video_r <= video_o.rgb.r(9 downto 4);
		video_g <= video_o.rgb.g(9 downto 4);
		video_b <= video_o.rgb.b(9 downto 4);

end SYN;
