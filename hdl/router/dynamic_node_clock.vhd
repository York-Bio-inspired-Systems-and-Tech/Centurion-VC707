library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity dynamic_node_clk is
	generic (
			DIVIDER_COUNTER_WIDTH : integer := 5
	);
    Port ( 	fast_clk_in : in std_logic;
			div_value : in  STD_LOGIC_VECTOR (DIVIDER_COUNTER_WIDTH-1 downto 0);
			node_clk_enable : in std_logic;
			
			div_clk_out : out  STD_LOGIC
           );
end dynamic_node_clk;


architecture Behavioral of dynamic_node_clk is

	signal div_clk_CE : std_logic;
	signal count : unsigned(DIVIDER_COUNTER_WIDTH-1 downto 0) := (others => '0');
	signal div_buff_reg : unsigned(DIVIDER_COUNTER_WIDTH-1 downto 0);
	signal node_en_reg_1 : std_logic;
	signal node_en_reg_0 : std_logic;
	signal div_clk_CE_reg : std_logic;
	
begin


  -- BUFHCE: HROW Clock Buffer for a Single Clocking Region with Clock Enable
   --         Virtex-6
   -- Xilinx HDL Language Template, version 14.7

   BUFHCE_inst : BUFHCE
   generic map (
      INIT_OUT => 0  -- Initial output value
   )
   port map (
      O => div_clk_out,   -- 1-bit output: Clock output
      CE => div_clk_CE, -- 1-bit input: Active high enable input
      I => fast_clk_in    -- 1-bit input: Clock input
   );

	
	
clk_div_counter : process(fast_clk_in)
  begin
		if rising_edge(fast_clk_in) then
			div_buff_reg <= unsigned(div_value);
			node_en_reg_0 <= node_clk_enable;
						
			if node_en_reg_0 = '1' and count = 0 then
				div_clk_CE <= '1';
			else
				div_clk_CE <= '0';
			end if;
			
			if node_en_reg_0 = '1' then
				if count = 0  then
					count <= div_buff_reg;
				else
					count <= count - 1;
				end if;
			end if;

	end if;
  end process;


end Behavioral;
