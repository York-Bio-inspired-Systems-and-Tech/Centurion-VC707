library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;

entity dual_port_RAM_36 is
	generic(
		RAM_DEPTH : integer := 2048;
		RAM_WIDTH : integer := 36;
		NB_COL    : integer := 4;       -- Number of write columns
		COL_WIDTH : integer := 9        -- Width of each write column
	);
	port(
		clk_a   : in  std_logic;
		wr_en_a : in  std_logic_vector(3 downto 0);
		addr_a  : in  std_logic_vector(log2(RAM_DEPTH - 1) - 1 downto 0);
		din_a   : in  std_logic_vector(RAM_WIDTH - 1 downto 0);
		dout_a  : out std_logic_vector(RAM_WIDTH - 1 downto 0);
		clk_b   : in  std_logic;
		wr_en_b : in  std_logic_vector(3 downto 0);
		addr_b  : in  std_logic_vector(log2(RAM_DEPTH - 1) - 1 downto 0);
		din_b   : in  std_logic_vector(RAM_WIDTH - 1 downto 0);
		dout_b  : out std_logic_vector(RAM_WIDTH - 1 downto 0)
	);
end entity dual_port_RAM_36;

architecture RTL of dual_port_RAM_36 is
	type ram_type is array (RAM_DEPTH - 1 downto 0) of std_logic_vector(RAM_WIDTH - 1 downto 0);
	-- If using Dual Port, 2 Clocks, 2 Read/Write Ports use the following definition for <ram_name>
	shared variable ram_inst : ram_type := (others => (others => '0'));
begin
	process(clk_a)
	begin
		if rising_edge(clk_a) then
			for i in 0 to NB_COL - 1 loop
				if wr_en_a(i) = '1' then
					ram_inst(to_integer(unsigned(addr_a)))((i + 1) * COL_WIDTH - 1 downto i * COL_WIDTH) := din_a((i + 1) * COL_WIDTH - 1 downto i * COL_WIDTH);
				end if;
			end loop;
			dout_a <= ram_inst(to_integer(unsigned(addr_a)));
		end if;
	end process;

	process(clk_b)
	begin
		if rising_edge(clk_b) then
			for i in 0 to NB_COL - 1 loop
				if wr_en_b(i) = '1' then
					ram_inst(to_integer(unsigned(addr_b)))((i + 1) * COL_WIDTH - 1 downto i * COL_WIDTH) := din_b((i + 1) * COL_WIDTH - 1 downto i * COL_WIDTH);
				end if;
			end loop;
			dout_b <= ram_inst(to_integer(unsigned(addr_b)));
		end if;
	end process;

end architecture RTL;
