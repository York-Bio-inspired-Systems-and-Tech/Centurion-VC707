library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;

entity dual_port_RAM is
	generic(
		RAM_DEPTH : integer := 2048;
		RAM_WIDTH : integer := 9
	);
	port (
		clk_a : in std_logic;
		en_a : in std_logic;
		wr_en_a : in std_logic;		
		addr_a : in std_logic_vector(log2(RAM_DEPTH-1) -1 downto 0);
		din_a : in std_logic_vector(RAM_WIDTH -1 downto 0);
		dout_a : out std_logic_vector(RAM_WIDTH -1 downto 0);
		clk_b : in std_logic;
		en_b : in std_logic;
		wr_en_b : in std_logic;
		addr_b : in std_logic_vector(log2(RAM_DEPTH-1) -1 downto 0);
		din_b : in std_logic_vector(RAM_WIDTH -1 downto 0);
		dout_b : out std_logic_vector(RAM_WIDTH -1 downto 0)
		
	);
end entity dual_port_RAM;

architecture RTL of dual_port_RAM is
		type ram_type is array (RAM_DEPTH - 1 downto 0) of std_logic_vector (RAM_WIDTH-1 downto 0);
	-- If using Dual Port, 2 Clocks, 2 Read/Write Ports use the following definition for <ram_name>
	shared variable ram_inst : ram_type;
begin
	
	process (clk_a)
	begin
	   if rising_edge(clk_a) then
	      if (en_a = '1') then
	         if (wr_en_a = '1') then
	           ram_inst(to_integer(unsigned(addr_a))) := din_a;
	         end if;
	         dout_a <= ram_inst(to_integer(unsigned(addr_a)));
	      end if;
	   end if;
	end process;
	
	process (clk_b)
	begin
	   if rising_edge(clk_b) then
	      if (en_b = '1') then
	         if (wr_en_b = '1') then
	           ram_inst(to_integer(unsigned(addr_b))) := din_b;
	         end if;
	         dout_b <= ram_inst(to_integer(unsigned(addr_b)));
	      end if;
	   end if;
end process;

end architecture RTL;
