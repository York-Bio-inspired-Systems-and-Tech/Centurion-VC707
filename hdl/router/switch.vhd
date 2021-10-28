library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;

entity switch is
	port (

		routing_dirs_out : in routing_dir_array;		
		Routing_Dirs_source : in routing_dir_array;		
		
		--incoming data valid
		data_valid_in :  in std_logic_vector(NUM_PORTS - 1 downto 0);
				
		--router ports
		data_ports_in : in data_ports_array;
		control_sel_in : in std_logic_vector(NUM_PORTS - 1 downto 0);
		rd_en_out : out std_logic_vector(NUM_PORTS - 1 downto 0);
		
		data_ports_out : out data_ports_array;
		control_sel_out : out std_logic_vector(NUM_PORTS - 1 downto 0);
		data_valid_out : out std_logic_vector(NUM_PORTS - 1 downto 0);
		rd_en_in : in std_logic_vector(NUM_PORTS - 1 downto 0)
	);
end entity switch;

architecture RTL of switch is

begin
	
	
	output_gen : for i in 0 to NUM_PORTS - 1 generate
		data_ports_out(i) <=	data_ports_in(0) when routing_dirs_out(i) = North else
						 		data_ports_in(1) when routing_dirs_out(i) = East else
						 		data_ports_in(2) when routing_dirs_out(i) = South else
								data_ports_in(3) when routing_dirs_out(i) = West else
						 		data_ports_in(4) when routing_dirs_out(i) = Internal else
						 		data_ports_in(5) when routing_dirs_out(i) = RCAP else
						 		(others => '0');
		control_sel_out(i) <=	control_sel_in(0) when routing_dirs_out(i) = North else
						 		control_sel_in(1) when routing_dirs_out(i) = East else
						 		control_sel_in(2) when routing_dirs_out(i) = South else
								control_sel_in(3) when routing_dirs_out(i) = West else
						 		control_sel_in(4) when routing_dirs_out(i) = Internal else
						 		control_sel_in(5) when routing_dirs_out(i) = RCAP else
						 		'0'; 
		
		data_valid_out(i) <= 	data_valid_in(0) when routing_dirs_out(i) = North else
						 		data_valid_in(1) when routing_dirs_out(i) = East else
						 		data_valid_in(2) when routing_dirs_out(i) = South else
								data_valid_in(3) when routing_dirs_out(i) = West else
						 		data_valid_in(4) when routing_dirs_out(i) = Internal else
						 		data_valid_in(5) when routing_dirs_out(i) = RCAP else
						 		'0'; 
		
		rd_en_out(i) <=  		rd_en_in(0) when Routing_Dirs_source(i) = North else
						 		rd_en_in(1) when Routing_Dirs_source(i) = East else
						 		rd_en_in(2) when Routing_Dirs_source(i) = South else
								rd_en_in(3) when Routing_Dirs_source(i) = West else
						 		rd_en_in(4) when Routing_Dirs_source(i) = Internal else
						 		rd_en_in(5) when Routing_Dirs_source(i) = RCAP else
						 		'0'; 
		
		
		
	end generate output_gen;
	
--	n_in_gen : for i in 0 to 4 generate
--		N_data_in(i) <= data_
--	
--	end generate;
--	
--	n_output_gen : for i in 0 to 4 generate
--		data_ports_out(i) <= data_ports_in(dir_to_int(Input_Direction)) when dir_to_int(Output_Direction) = i and rst = '0' else (others => '0');  
--		control_sel_out(i) <= control_sel_in(dir_to_int(Input_Direction)) when dir_to_int(Output_Direction) = i and rst = '0'  else '0';
--		data_valid_out(i) <= data_valid_in when dir_to_int(Output_Direction) = i else '0';
--	end generate n_output_gen;





end architecture RTL;
