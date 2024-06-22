library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;


entity invaders_video is
	port(
		Video             : in    std_logic;
		Overlay           : in    std_logic;
		OverlayTest       : in    std_logic;
		CLK               : in    std_logic;
		Rst_n_s           : in    std_logic;
		HSync             : in    std_logic;
		VSync             : in    std_logic;
		O_VIDEO_R         : out   std_logic;
		O_VIDEO_G         : out   std_logic;
		O_VIDEO_B         : out   std_logic;
		O_HSYNC           : out   std_logic;
		O_VSYNC           : out   std_logic;
		O_HBLANK          : out   std_logic;
		O_VBLANK          : out   std_logic; 
                color_prom_out    : in    std_logic_vector(7 downto 0);
                color_prom_addr    : out    std_logic_vector(10 downto 0)
		);
end invaders_video;

architecture rtl of invaders_video is

	signal hblank          : std_logic;
	signal vblank          : std_logic;
	signal HCnt            : std_logic_vector(11 downto 0);
	signal VCnt            : std_logic_vector(11 downto 0);
	signal HSync_t1        : std_logic;
	signal Overlay_G1      : boolean;
	signal Overlay_G2      : boolean;
	signal Overlay_R1      : boolean;
	signal Overlay_G1_VCnt : boolean;
	signal VideoRGB        : std_logic_vector(2 downto 0);
begin	
	process (Rst_n_s, Clk)
		variable cnt : unsigned(3 downto 0);
	begin
		if Rst_n_s = '0' then
			cnt := "0000";
		elsif Clk'event and Clk = '1' then
			if cnt = 9 then
				cnt := "0000";
			else
				cnt := cnt + 1;
			end if;
		end if;
	end process;
	
  p_overlay : process(Rst_n_s, Clk)
	variable HStart : boolean;
  begin
	if Rst_n_s = '0' then
	  HCnt <= (others => '0');
	  VCnt <= (others => '0');
	  HSync_t1 <= '0';
	  Overlay_G1_VCnt <= false;
	  Overlay_G1 <= false;
	  Overlay_G2 <= false;
	  Overlay_R1 <= false;
	  hblank <='1';
	  vblank <='1';
	elsif Clk'event and Clk = '1' then
	  HSync_t1 <= HSync;
	  HStart := (HSync_t1 = '0') and (HSync = '1');
	  if HStart then
		HCnt <= (others => '0');
	  else
		HCnt <= HCnt + "1";
	  end if;

	  if (VSync = '0') then
		VCnt <= (others => '0');
	  elsif HStart then
		VCnt <= VCnt + "1";
	  end if;
          if (HCnt = 538) then  -- 511
             hblank<='1';
          end if;
          if (HCnt = 27) then  -- 27?
             hblank<='0';
          end if;

	  if HStart then
		if (Vcnt = x"1F") then
		  Overlay_G1_VCnt <= true;
		elsif (Vcnt = x"95") then
		  Overlay_G1_VCnt <= false;
		end if;
	  end if;
	  if (Vcnt = 32) then
		  vblank<='0';
	  end if;
	  if (Vcnt = 255) then
		  vblank<='1';
	  end if;

	  if (HCnt = x"027") and Overlay_G1_VCnt then
		Overlay_G1 <= true;
	  elsif (HCnt = x"046") then
		Overlay_G1 <= false;
	  end if;

	  if (HCnt = x"046") then
		Overlay_G2 <= true;
	  elsif (HCnt = x"0B6") then
		Overlay_G2 <= false;
	  end if;

	  if (HCnt = x"1A6") then
		Overlay_R1 <= true;
	  elsif (HCnt = x"1E6") then
		Overlay_R1 <= false;
	  end if;

     if (HCnt(2 downto 0) = "000") then
		  --color_prom_addr<= std_logic_vector( '0' & VCnt(7 downto 3) & HCnt(8 downto 4)); -- first 0 needs to be a 1 for cocktail
		  color_prom_addr<= std_logic_vector( '0' & VCnt(7 downto 3) & ( std_logic_vector(unsigned(HCnt(8 downto 4)) + 8))); -- first 0 needs to be a 1 for cocktail
	  end if;

	end if;
  end process;

  p_video_out_comb : process(Video, color_prom_out, OverlayTest, Overlay_G1, Overlay_G2, Overlay_R1)
  begin
	if OverlayTest = '1' then
	  VideoRGB <= color_prom_out(0) & color_prom_out(2) & color_prom_out(1);
	elsif (Video = '0') then
	  VideoRGB  <= "000";
	else
	  VideoRGB <= color_prom_out(0) & color_prom_out(2) & color_prom_out(1);
	  --if Overlay_G1 or Overlay_G2 then
	--	VideoRGB  <= "010";
	 -- elsif Overlay_R1 then
	--	VideoRGB  <= "100";
	 -- else
	--	VideoRGB  <= "111";
	 -- end if;
	end if;
  end process;

  O_VIDEO_R <= VideoRGB(2) when (Overlay = '1') else VideoRGB(0) or VideoRGB(1) or VideoRGB(2);
  O_VIDEO_G <= VideoRGB(1) when (Overlay = '1') else VideoRGB(0) or VideoRGB(1) or VideoRGB(2);
  O_VIDEO_B <= VideoRGB(0) when (Overlay = '1') else VideoRGB(0) or VideoRGB(1) or VideoRGB(2);
  O_HSYNC   <= not HSync;
  O_VSYNC   <= not VSync;

  O_VBLANK  <= vblank;
  O_HBLANK  <= hblank;

end;
