library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use UNISIM.VComponents.all; 
library centurion;
use centurion.centurion_pkg.all;



entity RO_temp_sensor is
	port(
		clk         : in  std_logic;
		ring_osc_en : in  std_logic;
		conversion_en : in  std_logic;
		tick_1us : in std_logic;
		temp_out    : out STD_LOGIC_VECTOR(RO_TEMP_WIDTH_OUT -1 downto 0);
		ro_out      : out std_logic
	);
end entity RO_temp_sensor;

architecture RTL of RO_temp_sensor is

	constant C_COUNTER_WIDTH        : integer := 16;
	constant C_CAPTURE_WINDOW_WIDTH : integer := 8;
	
	signal captured           : std_logic;
	signal ring_osc_out       : std_logic;
	signal ring_osc_out_div_2 : std_logic;

	signal count               : unsigned(C_COUNTER_WIDTH - 1 downto 0);
	signal count_cntrl         : unsigned(C_CAPTURE_WINDOW_WIDTH - 1 downto 0);
	signal temp_reg            : unsigned(C_COUNTER_WIDTH - 1 downto 0);

	signal capture_en      : std_logic;
	signal capture_en_RO_0 : std_logic;
	signal capture_en_RO_1 : std_logic;
	signal captured_RO_0  : std_logic;	
	signal captured_RO_1  : std_logic;
	signal RO_hold : std_logic;
	signal RO_hold_CLK_0 : std_logic;
	signal RO_hold_CLK_1 : std_logic;


	attribute buffer_type   : string;
	attribute KEEP : string;
	attribute buffer_type of ring_osc_out : signal is "none";
	attribute keep of ring_osc_out : signal is "true";
begin

	temp_out <= std_logic_vector(temp_reg);
	ro_out   <= ring_osc_out;

	ring_osc_inst : entity centurion.ring_osc
		port map(
			en => ring_osc_en,
			o  => ring_osc_out
		);

	capture_en <= '1' when count_cntrl /= 0 else '0';

	cntrl_process : process(clk)
	begin
		if rising_edge(clk) then
			RO_hold_CLK_0 <= RO_hold;
			RO_hold_CLK_1 <= RO_hold_CLK_0;
			
			
			if count_cntrl = 0 then
				if captured = '0' and RO_hold_CLK_1 = '1' then
					temp_reg <= count;
					captured <= '1';
				elsif conversion_en = '1' and captured = '1' and RO_hold_CLK_1 = '0' then
						count_cntrl <= (others => '1');
						captured        <= '0';
				end if;
			else
				if tick_1us = '1' then
					count_cntrl <= count_cntrl - 1;
				end if;
			end if;
		end if;
	end process;

--	ring_osc_out_div_2_proc : process(ring_osc_out)
--	begin
--		if rising_edge(ring_osc_out) then
--			ring_osc_out_div_2 <= not ring_osc_out_div_2;
--		end if;
--	end process;

	timing_process : process(ring_osc_out)
	begin
		if rising_edge(ring_osc_out) then
			capture_en_RO_0 <= capture_en;
			capture_en_RO_1 <= capture_en_RO_0;		
			
			captured_RO_0 <= captured;
			captured_RO_1 <= captured_RO_0;
	
			if capture_en_RO_1 = '1' then
				count           <= count + 1;
				RO_hold <= '0';
			else
				RO_hold <= '1';
				if captured_RO_1 = '1' then
					count <= (others => '0');
					RO_hold <= '0';
				end if;
			end if;
		end if;
	end process;

end architecture RTL;



