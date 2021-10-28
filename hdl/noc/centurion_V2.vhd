LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
library centurion;
use centurion.centurion_pkg.all;

library UNISIM;
use UNISIM.VComponents.all;
 
 
entity centurion_V2 IS
generic(
		NOC_WIDTH : integer := 8;
		NOC_HEIGHT : integer := 8;
		NOC_NUM_NODES_LOG2 : integer := 6
    );
port (
       
    NoC_clk : in std_logic; 
    NoC_reset : in STD_LOGIC;
	UART_node_tx : out std_logic;
	
	NoC_if_Out_Port  : in  router_in_port;
    NoC_if_in_Port : out router_out_port;
    
    --RTC
    RTC_value : in std_logic_vector(31 downto 0);

    --Node debug interface
    Debug_Node_sel : in std_logic_vector(NOC_NUM_NODES_LOG2-1 downto 0);
    Debug_Node_src_sel : in std_logic_vector(1 downto 0);
    Debug_Node_UART_sel : in std_logic_vector(NOC_NUM_NODES_LOG2-1 downto 0);
               
    Debug_Node_debug_value_out : out std_logic_vector(8 downto 0);
    Debug_command_in : in std_logic_vector(8 downto 0);
    Debug_command_interrupt_in : in std_logic;
    Debug_HS_download_en : in std_logic;
    Debug_HS_upload_en : in std_logic
		 
	 );
END entity centurion_V2;
 
ARCHITECTURE behavior OF centurion_V2 IS 

	constant NOC_Num_Nodes : integer := NOC_Height * NOC_Width;
	
	type router_in_port_array is array( NOC_Num_Nodes - 1 downto 0) of router_in_port;
	type router_out_port_array is array( NOC_Num_Nodes - 1 downto 0) of router_out_port;
	
	signal North_In_Port : router_in_port_array;
	signal East_In_Port : router_in_port_array;
	signal South_In_Port : router_in_port_array;
	signal West_In_Port : router_in_port_array;

	signal North_Out_Port : router_out_port_array;
	signal East_Out_Port : router_out_port_array;
	signal South_Out_Port : router_out_port_array;
	signal West_Out_Port : router_out_port_array;
	
	--debug interface signals
	signal debug_index : Natural  := 0;
	signal debug_row_sel : Natural ;
	signal debug_col_sel : Natural ;
	
	type debug_array is array( NOC_Num_Nodes -1 downto 0) of std_logic_vector(8 downto 0);
	signal node_debug : debug_array;
	signal node_debug_reg : std_logic_vector(8 downto 0);
	
	signal MB_debug : debug_array;
	signal debug_row_reg_0 : debug_array;
	signal debug_row_reg_1 : debug_array;
	
	type intel_node_array is array(4 downto 0) of std_logic_vector(7 downto 0);
	type intel_array is array(NOC_Num_Nodes -1 downto 0) of intel_node_array;
	signal intel_interconnect : intel_array;
	type intel_req_array is array(NOC_Num_Nodes -1 downto 0) of std_logic_vector(3 downto 0);
	signal intel_reqs_out : intel_req_array;
	signal intel_reqs_in : intel_req_array;
	
	
	signal debug_sel_reg : std_logic_vector(NOC_NUM_NODES_LOG2-1 downto 0) := (others => '0');
	signal Debug_Node_src_sel_reg : std_logic_vector(1 downto 0);
	signal Debug_Broadcast_sel_reg : std_logic;

	signal MB_node_debug_cmd : std_logic_vector(8 downto 0);
	signal debug_cmd_reg : std_logic_vector(8 downto 0);
	signal MB_node_debug_output : std_logic_vector(8 downto 0);
	
	signal node_debug_resets : std_logic_vector(NOC_num_nodes - 1 downto 0);	
	signal node_debug_MB_cmd_valid : std_logic;
	signal node_debug_cmd_valid_array_regs : std_logic_vector(NOC_NUM_NODES -1 downto 0);
	signal node_debug_cmd_interrupt_array_regs : std_logic_vector(NOC_NUM_NODES -1 downto 0);
	signal Hi_Speed_Download_ens_regs : std_logic_vector(NOC_Num_Nodes-1 downto 0);
	signal Hi_Speed_Upload_ens_regs : std_logic_vector(NOC_Num_Nodes-1 downto 0);


	signal nodes_uart_out : std_logic_vector(NOC_Num_Nodes-1 downto 0);
	type Node_Temp_array is array( NOC_NUM_NODES - 1 downto 0) of std_logic_vector(15 downto 0);
	signal Node_Temps : Node_Temp_array;
	
	type RTC_array is array( NOC_NUM_NODES - 1 downto 0) of std_logic_vector(31 downto 0);
	signal RTC_regs : RTC_array;
	signal noc_reset_reg : std_logic_vector(NOC_Num_Nodes-1 downto 0);
	signal MCS_glbl_reset_reg : std_logic_vector(NOC_Num_Nodes-1 downto 0);
	
	
BEGIN

debug_index <= to_integer(unsigned(debug_sel_reg));
debug_row_sel <= debug_index / NOC_Width when debug_index < NOC_Num_Nodes else 0;
debug_col_sel <= debug_index mod NOC_Width when debug_index < NOC_Num_Nodes else 0;

UART_node_tx <= nodes_uart_out(to_integer(unsigned(Debug_Node_UART_sel)));
Debug_Node_debug_value_out <= node_debug_reg;

debug_regs_proc : process(NoC_clk)
begin
	if rising_edge(NoC_clk) then
		debug_sel_reg <= Debug_Node_sel;
		Debug_Node_src_sel_reg <= Debug_Node_src_sel;
		node_debug_reg <= debug_row_reg_1(debug_row_sel);
		debug_cmd_reg <= Debug_command_in;
	 	node_debug_cmd_valid_array_regs <= (others => '0');
	 	node_debug_cmd_interrupt_array_regs <= (others => '0');
	 	Hi_Speed_Download_ens_regs <= (others => '0');
	 	Hi_Speed_Upload_ens_regs <= (others => '0');
	 	
	 	if Debug_Node_src_sel = "00" then
	 		--broadcast mode
	 		if Debug_command_interrupt_in = '1' then
	 			node_debug_cmd_interrupt_array_regs <= (others => '1');
	 		 end if;		
	 	else
			 if debug_index < NOC_NUM_NODES then
				node_debug_cmd_valid_array_regs(debug_index) <= '1';
				node_debug_cmd_interrupt_array_regs(debug_index) <= Debug_command_interrupt_in;
				Hi_Speed_Download_ens_regs(debug_index) <= Debug_HS_download_en;
				Hi_Speed_Upload_ens_regs(debug_index) <= Debug_HS_upload_en;
			end if;
		end if;		
	end if;
end process;

--build up the debug MUX rows
debug_row_gen : for i in 0 to NOC_Height -1 generate
debug_rows_proc : process(NoC_clk)
begin
	if rising_edge(NoC_clk) then
		debug_row_reg_0(i) <= node_debug((i * NOC_Width) + debug_col_sel);
		debug_row_reg_1(i) <= debug_row_reg_0(i);
	end if;
end process;
end generate;

 
		
 noc_reset_regs_proc : process(NoC_clk)
begin
	if rising_edge(NoC_clk) then
		for i in 0 to NoC_Num_Nodes - 1 loop
			noc_reset_reg(i) <= noc_reset;
			RTC_regs(i) <= RTC_value; 
		end loop;
	end if;
end process;
 
			  	  
	PE_gen : for i in 0 to NOC_Num_Nodes - 1 generate
		many_core_PE_inst : entity centurion.centurion_PE
			generic map(
				node_index => i
			)
			port map(
				noc_clk           => NoC_clk,
				reset             => NoC_reset_reg(i),
				RTC_in 		      => RTC_regs(i),
				
				North_In_Port     => North_In_Port(i),
				North_Out_Port    => North_Out_Port(i),
				East_In_Port      => East_In_Port(i),
				East_Out_Port     => East_Out_Port(i),
				South_In_Port     => South_In_Port(i),
				South_Out_Port    => South_Out_Port(i),
				West_In_Port      => West_In_Port(i),
				West_Out_Port     => West_Out_Port(i),
				
				Intel_N 		=> intel_interconnect(i)(0),
				Intel_E 		=> intel_interconnect(i)(1),
				Intel_S			=> intel_interconnect(i)(2),
				Intel_W			=> intel_interconnect(i)(3),
				Intel_out		=> intel_interconnect(i)(4),
				Intel_req_in 	=> intel_reqs_in(i),
				Intel_req_out 	=> intel_reqs_out(i),	
				
				debug_out => node_debug(i),
				debug_in => Debug_command_in,
				Debug_Node_src_sel => Debug_Node_src_sel_reg,
				debug_in_valid => node_debug_cmd_valid_array_regs(i),
				debug_in_interrupt => node_debug_cmd_interrupt_array_regs(i),
				UART_out => nodes_uart_out(i),
				
				Hi_Speed_Download_en => Hi_Speed_Download_ens_regs(i),
				Hi_Speed_Upload_en => Hi_Speed_Upload_ens_regs(i)
        );	
		end generate PE_gen;
			
	
		noc_y : for i in 0 to (NOC_Height -1) generate
		noc_x : for j in 0 to (NOC_Width -1) generate
		N_boundary_a : if i=0 generate
			N_boundary_a_1 : if j = 0 generate
				North_In_Port(i*(NOC_Width) + j) <= NoC_if_Out_Port;
				NoC_if_In_Port <= North_Out_Port(i*(NOC_Width) + j);
			end generate N_boundary_a_1;
			
			N_boundary_a_2 : if j /= 0 generate
				North_In_Port(i*(NOC_Width) + j).data_in <= (others => '0');
				North_In_Port(i*(NOC_Width) + j).control_sel <= '0';
				North_In_Port(i*(NOC_Width) + j).data_valid <= '0';
				North_In_Port(i*(NOC_Width) + j).rd_en <= '0';
			end generate N_boundary_a_2;
		end generate N_boundary_a;
		
		N_boundary_b : if i>0 generate
			North_In_Port(i*(NOC_Width) + j).data_in 	 <= South_Out_Port(((i-1)*NOC_Width) + j).data_out;
			North_In_Port(i*(NOC_Width) + j).control_sel <= South_Out_Port(((i-1)*NOC_Width) + j).control_sel;
			North_In_Port(i*(NOC_Width) + j).data_valid  <= South_Out_Port(((i-1)*NOC_Width) + j).data_valid;
			North_In_Port(i*(NOC_Width) + j).rd_en		 <= South_Out_Port(((i-1)*NOC_Width) + j).rd_en;
		end generate N_boundary_b;
		
		S_boundary_a : if i=NOC_Height -1 generate			
			South_In_Port(i*(NOC_Width) + j).data_in <= (others => '0');
			South_In_Port(i*(NOC_Width) + j).control_sel <= '0';
			South_In_Port(i*(NOC_Width) + j).data_valid <= '0';
			South_In_Port(i*(NOC_Width) + j).rd_en <= '0';
		end generate S_boundary_a;
		
		S_boundary_b : if i < NOC_Height -1 generate
			South_In_Port(i*(NOC_Width) + j).data_in 	 <= North_Out_Port(((i+1)*NOC_Width) + j).data_out;
			South_In_Port(i*(NOC_Width) + j).control_sel <= North_Out_Port(((i+1)*NOC_Width) + j).control_sel;
			South_In_Port(i*(NOC_Width) + j).data_valid  <= North_Out_Port(((i+1)*NOC_Width) + j).data_valid;
			South_In_Port(i*(NOC_Width) + j).rd_en 		 <= North_Out_Port(((i+1)*NOC_Width) + j).rd_en; 
		end generate S_boundary_b;
			
		E_boundary_a : if j=NOC_Width-1 generate
            East_In_Port(i*(NOC_Width) + j).data_in <= (others => '0');
            East_In_Port(i*(NOC_Width) + j).control_sel <= '0';
            East_In_Port(i*(NOC_Width) + j).data_valid <= '0';
            East_In_Port(i*(NOC_Width) + j).rd_en <= '0';
        end generate E_boundary_a;
		
		E_boundary_b : if j<NOC_Width -1 generate
			East_In_Port(i*(NOC_Width) + j).data_in 	 <= West_Out_Port(((i)*NOC_Width) + j+1).data_out;
			East_In_Port(i*(NOC_Width) + j).control_sel <= 	West_Out_Port(((i)*NOC_Width) + j+1).control_sel;
			East_In_Port(i*(NOC_Width) + j).data_valid  <= 	West_Out_Port(((i)*NOC_Width) + j+1).data_valid;
			East_In_Port(i*(NOC_Width) + j).rd_en 		 <= West_Out_Port(((i)*NOC_Width) + j+1).rd_en; 	
		end generate E_boundary_b;
		
		W_boundary_a : if j=0 generate
			West_In_Port(i*(NOC_Width) + j).data_in <= (others => '0');
			West_In_Port(i*(NOC_Width) + j).control_sel <= '0';
			West_In_Port(i*(NOC_Width) + j).data_valid <= '0';
			West_In_Port(i*(NOC_Width) + j).rd_en <= '0';
		end generate W_boundary_a;
		
		W_boundary_b : if j > 0 generate
			West_In_Port(i*(NOC_Width) + j).data_in 	 <= East_Out_Port(((i)*NOC_Width) + j-1).data_out;
			West_In_Port(i*(NOC_Width) + j).control_sel <= 	East_Out_Port(((i)*NOC_Width) + j-1).control_sel;
			West_In_Port(i*(NOC_Width) + j).data_valid  <= 	East_Out_Port(((i)*NOC_Width) + j-1).data_valid;
			West_In_Port(i*(NOC_Width) + j).rd_en 		 <= East_Out_Port(((i)*NOC_Width) + j-1).rd_en; 
		end generate W_boundary_b;
		
		end generate noc_x;
	end generate noc_y;



	noc_intel_y : for i in 0 to (NOC_Height -1) generate
		noc_intel_x : for j in 0 to (NOC_Width -1) generate
		N_boundary_a : if i=0 generate
			intel_interconnect(i*(NOC_Width) + j)(0) <= (others => '0');
			intel_reqs_in(i*(NOC_Width) + j)(0) <= '0';
		end generate N_boundary_a;
		
		N_boundary_b : if i>0 generate
			intel_interconnect(i*(NOC_Width) + j)(0) <=	intel_interconnect((i-1)*(NOC_Width) + j)(4);
			intel_reqs_in(i*(NOC_Width) + j)(0) <= intel_reqs_out((i-1)*(NOC_Width) + j)(0);
		end generate N_boundary_b;
		
		S_boundary_a : if i=NOC_Height -1 generate			
			intel_interconnect(i*(NOC_Width) + j)(2) <= (others => '0');
			intel_reqs_in(i*(NOC_Width) + j)(2) <= '0';
		end generate S_boundary_a;
		
		S_boundary_b : if i < NOC_Height -1 generate
			intel_interconnect(i*(NOC_Width) + j)(2) <= intel_interconnect((i+1)*(NOC_Width) + j)(4);
			intel_reqs_in(i*(NOC_Width) + j)(2) <= intel_reqs_out((i+1)*(NOC_Width) + j)(2);
		end generate S_boundary_b;
			
		E_boundary_a : if j=NOC_Width-1 generate
			intel_interconnect(i*(NOC_Width) + j)(1) <= (others => '0');
			intel_reqs_in(i*(NOC_Width) + j)(1) <= '0';
        end generate E_boundary_a;
		
		E_boundary_b : if j<NOC_Width -1 generate
			intel_interconnect(i*(NOC_Width) + j)(1) <= intel_interconnect((i)*(NOC_Width) + j+1)(4);
			intel_reqs_in(i*(NOC_Width) + j)(1) <= intel_reqs_out((i)*(NOC_Width) + j+1)(1);
		end generate E_boundary_b;
		
		W_boundary_a : if j=0 generate
			intel_interconnect(i*(NOC_Width) + j)(3) <= (others => '0');
			intel_reqs_in(i*(NOC_Width) + j)(3) <= '0';
		end generate W_boundary_a;
		
		W_boundary_b : if j > 0 generate
			intel_interconnect(i*(NOC_Width) + j)(3) <= intel_interconnect((i)*(NOC_Width) + j-1)(4);
			intel_reqs_in(i*(NOC_Width) + j)(3) <= intel_reqs_out((i)*(NOC_Width) + j-1)(3);
		end generate W_boundary_b;
		
		end generate noc_intel_x;
	end generate noc_intel_y;





END;
