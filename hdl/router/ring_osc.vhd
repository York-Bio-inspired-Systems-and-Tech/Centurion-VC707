library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;
 
library centurion;
use centurion.centurion_pkg.all;

entity ring_osc is
	generic(
		C_LEN : integer := 16;
		C_TAP : integer := 0
	);
	Port(
		en : in  STD_LOGIC;
		o  : out STD_LOGIC);
end ring_osc;

architecture Behavioral of ring_osc is

	attribute BEL  : string;
	attribute rloc : string;

	attribute KEEP    : string;
	signal delay_line : std_logic_vector(C_LEN - 1 downto 0);
	attribute KEEP of delay_line : signal is "true";

	--attribute rloc of LUT2_inst : label is "X0Y0";

	--	
begin
	--
	o <= delay_line(C_TAP);

	LUT2_inst : LUT2
		generic map(
			INIT => "0100")
		port map(
			O  => delay_line(0),        -- LUT general output
			I0 => delay_line(C_LEN - 1), -- LUT inputv
			I1 => en                    -- LUT input
		);

	delay_line_gen : for i in 1 to C_LEN - 1 generate

		--attribute rloc of LUT2_buf_inst : label is "X" & INTEGER'image((i/C_LEN) + (i mod 2)) & "Y" & INTEGER'image(0);
	begin
		LUT2_buf_inst : LUT2
			generic map(
				INIT => "1000")
			port map(
				O  => delay_line(i),    -- LUT general output
				I0 => delay_line(i - 1), -- LUT input
				I1 => en                -- LUT input
			);

	end generate;

end Behavioral;
