library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_port_RAM_asymmetric_A32RW_B8W is

	generic(
		WIDTHA     : integer := 32;
		SIZEA      : integer := 1024;
		ADDRWIDTHA : integer := 10;
		WIDTHB     : integer := 8;
		SIZEB      : integer := 4096;
		ADDRWIDTHB : integer := 12
	);

	port(
		clkA  : in  std_logic;
		enA   : in  std_logic;
		addrA : in  std_logic_vector(ADDRWIDTHA - 1 downto 0);
		weA   : in  std_logic_vector(3 downto 0);
		diA   : in  std_logic_vector(WIDTHA - 1 downto 0);
		doA   : out std_logic_vector(WIDTHA - 1 downto 0);
		
		clkB  : in  std_logic;
		weB   : in  std_logic;
		addrB : in  std_logic_vector(ADDRWIDTHB - 1 downto 0);	
		diB   : in std_logic_vector(WIDTHB - 1 downto 0)
	);
end entity dual_port_RAM_asymmetric_A32RW_B8W;

architecture RTL of dual_port_RAM_asymmetric_A32RW_B8W is

	function max(L, R : INTEGER) return INTEGER is
	begin
		if L > R then
			return L;
		else
			return R;
		end if;
	end;

	function min(L, R : INTEGER) return INTEGER is
	begin
		if L < R then
			return L;
		else
			return R;
		end if;
	end;

	function log2(val : INTEGER) return natural is
		variable res : natural;
	begin
		for i in 0 to 31 loop
			if (val = (2**i)) then
				res := i;
				exit;
			end if;
		end loop;
		return res;
	end function Log2;

	constant minWIDTH : integer := min(WIDTHA, WIDTHB);
	constant maxWIDTH : integer := max(WIDTHA, WIDTHB);
	constant maxSIZE  : integer := max(SIZEA, SIZEB);
	constant RATIO    : integer := maxWIDTH / minWIDTH;

	-- An asymmetric RAM is modeled in a similar way as a symmetric RAM, with an
	-- array of array object. Its aspect ratio corresponds to the port with the
	-- lower data width (larger depth)
	type ramType is array (0 to maxSIZE - 1) of std_logic_vector(minWIDTH - 1 downto 0);

	-- You need to declare ram as a shared variable when :
	--   - the RAM has two write ports,
	--   - the RAM has only one write port whose data width is maxWIDTH
	-- In all other cases, ram can be a signal.
	--shared variable ram : ramType := (others => (others => '0'));
	signal ram : ramType := (others => (others => '0'));

	signal readA : std_logic_vector(WIDTHA - 1 downto 0) := (others => '0');
	signal readB : std_logic_vector(WIDTHB - 1 downto 0) := (others => '0');
	signal regA  : std_logic_vector(WIDTHA - 1 downto 0) := (others => '0');
	signal regB  : std_logic_vector(WIDTHB - 1 downto 0) := (others => '0');

	signal di0, di1, di2, di3 : std_logic_vector((WIDTHA/4) - 1 downto 0);
	signal dA  : std_logic_vector(WIDTHA - 1 downto 0) := (others => '0');
	
begin

	process(clkA)
	begin
		if rising_edge(clkA) then
			if enA = '1' then
				for i in 0 to RATIO - 1 loop
				
					-- The read statement below is placed after the write statement on purpose
					-- to ensure write-first synchronization through the variable mechanism
					readA((i + 1)*minWIDTH - 1 downto i*minWIDTH) <= ram(to_integer(unsigned(unsigned(addrA) & to_unsigned(i, log2(RATIO)))));
				end loop;
			end if;
			regA <= readA;
		end if;
	end process;
	
	
	process(clkB)
	begin
		if rising_edge(clkB) then
			if weB = '1' then				
				ram(to_integer(unsigned(addrB))) <= diB ;
			end if;
		end if;
	end process;

	doA <= readA;


end architecture RTL;
