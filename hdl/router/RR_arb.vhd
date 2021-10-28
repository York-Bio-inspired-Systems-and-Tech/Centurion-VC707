library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;

entity RR_arb is
	port (
		clk : in std_logic;
		rst : in std_logic;
		
		Input_Direction_out : out router_direction

	);
end entity RR_arb;

architecture RTL of RR_arb is
	signal input_direction : router_direction;
	signal input_direction_next : router_direction;
begin 

	Input_Direction_out <= input_direction;

	input_dir : process (input_direction) is
	begin
		input_direction_next <= input_direction;
		case input_direction is 
			when North =>
				input_direction_next <= East;
			when East =>
				input_direction_next <= South;
			when South =>
				input_direction_next <= West;
			when West =>
				input_direction_next <= Internal;
			when Internal =>
				input_direction_next <= North;
			when Idle =>
				input_direction_next <= North;
			when RCAP=>
				input_direction_next <= North;
		
		end case;

	end process input_dir;
	

	seq_proc : process (clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				input_direction <= North;
			else
				input_direction <= input_direction_next;
			end if;
		end if;
	end process seq_proc;
	

end architecture RTL;
