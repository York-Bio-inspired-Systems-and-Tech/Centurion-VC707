library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;

entity centurion_PE is
	generic (
		node_index : integer := 0
	);
	port(
		NoC_Clk				: IN STD_LOGIC;
		Reset             : IN  STD_LOGIC;
		RTC_in            : in  std_logic_vector(31 downto 0);
		--router ports
		North_In_Port     : in  router_in_port;
		North_Out_Port    : out router_out_port;
		East_In_Port      : in  router_in_port;
		East_Out_Port     : out router_out_port;
		South_In_Port     : in  router_in_port;
		South_Out_Port    : out router_out_port;
		West_In_Port      : in  router_in_port;
		West_Out_Port     : out router_out_port;
		
		--neighbouring nodes intel
		Intel_N : in std_logic_vector(7 downto 0);
		Intel_E : in std_logic_vector(7 downto 0);
		Intel_S : in std_logic_vector(7 downto 0);
		Intel_W : in std_logic_vector(7 downto 0);
		Intel_out : out std_logic_vector(7 downto 0);
		Intel_req_in : in std_logic_vector(3 downto 0);
		Intel_req_out : out std_logic_vector(3 downto 0);		

		debug_out : OUT STD_LOGIC_vector(8 downto 0);
		debug_in : in STD_LOGIC_vector(8 downto 0);
		Debug_Node_src_sel : in STD_LOGIC_vector(1 downto 0);
		debug_in_valid : in STD_LOGIC;
		debug_in_interrupt : in STD_LOGIC;
		
		Hi_Speed_Download_en    : in  std_logic;
		Hi_Speed_Upload_en    : in  std_logic;

		UART_out : out std_logic
	);
end entity centurion_PE;

architecture RTL of centurion_PE is	

	signal router_I_out_port : router_out_port;
	signal router_I_in_port : router_in_port;
	signal MCS_reset : std_logic;
	
	signal node_debug_in : std_logic_vector(8 downto 0);
	signal node_broadcast_in : std_logic_vector(8 downto 0);
	signal router_debug_in : std_logic_vector(8 downto 0);
	signal intel_debug_in : std_logic_vector(8 downto 0);
	
	signal node_debug_out : std_logic_vector(8 downto 0);
	
	signal router_debug_out : std_logic_vector(8 downto 0);
	signal intel_debug_out : std_logic_vector(8 downto 0);
	
	signal debug_out_reg : STD_LOGIC_vector(8 downto 0);
	
	signal NoC_reset_reg : std_logic;
	
	signal node_rd_req_intel : std_logic;
	signal node_rd_req_router : std_logic;
	signal node_to_router_data: std_logic_vector(7 downto 0);
	signal router_to_node_data: std_logic_vector(15 downto 0);
	signal node_to_intel_data: std_logic_vector(7 downto 0);
	signal intel_to_node_data: std_logic_vector(7 downto 0);

	signal node_wr_req_intel : std_logic;
	signal node_wr_req_router : std_logic;
	
	signal router_int : std_logic;
	signal intel_int : std_logic;

	signal MCS_clk : std_logic;
	signal MB_tick : std_logic;
	signal MB_interrupt : std_logic;	
	

begin
	
	debug_out <= debug_out_reg;
	
	
--buffer large global signals to reduce fanout
reset_tree_proc : process(NoC_Clk) 
begin
	if rising_edge(NoC_clk) then		
		NoC_reset_reg <= reset;				
	end if;
end process;

debug_signals_proc : process(NoC_Clk) 
begin
	if rising_edge(NoC_clk) then		
		if NoC_reset_reg = '1' then
			debug_out_reg <= (others => '0');
			node_debug_in <= (others => '0');
			node_broadcast_in <= (others => '0');
			router_debug_in <= (others => '0');
			intel_debug_in <= (others => '0');
			router_int <= '0';
			intel_int <= '0';
		else
			router_int <= '0';
			intel_int <= '0';
			MB_interrupt <= '0';
			if Debug_Node_src_sel = "00" then
				if debug_in_interrupt = '1' then
					node_broadcast_in <= debug_in;
				end if;
				node_debug_in <= node_broadcast_in;
				debug_out_reg <= node_debug_out;
				
			elsif Debug_Node_src_sel = "01" then
				if debug_in_valid = '1' then
					node_debug_in <= debug_in;		
					MB_interrupt <= debug_in_interrupt;
				end if;
				debug_out_reg <= node_debug_out;
				
			elsif Debug_Node_src_sel = "10" then
				router_int <= debug_in_interrupt;
				router_debug_in <= debug_in;
				debug_out_reg <= router_debug_out;
			
			elsif Debug_Node_src_sel = "11" then
				intel_int <= debug_in_interrupt;
				intel_debug_in <= debug_in;
				debug_out_reg <= intel_debug_out;
			end if;
		end if;	
	end if;
end process;


	
node_inst: entity work.many_core_node
		generic map (
		node_index => node_index
	) 
	PORT MAP (
	    	    MCS_Clk => MCS_Clk,
			NoC_Clk => NoC_Clk,
		        MCS_reset => MCS_reset,
			NoC_reset => NoC_reset_reg ,
	          	Node_Out_Port  => router_I_in_port,
			Node_In_Port => router_I_Out_Port,
			RTC_in => RTC_in,
			tick_in => MB_tick,
			
			debug_out => node_debug_out,
			debug_in => node_debug_in,
			debug_in_valid => MB_interrupt,
			Hi_Speed_Download_en => Hi_Speed_Download_en,
			Hi_Speed_Upload_en => Hi_Speed_Upload_en,
			UART_out => UART_out,
			
			node_rd_req_router => node_rd_req_router,
			node_rd_req_intel => node_rd_req_intel,
			router_data_in => router_to_node_data,
			intel_data_in => intel_to_node_data,
			
			node_wr_req_intel => node_wr_req_intel,
			node_wr_req_router => node_wr_req_router,
			router_data_out => node_to_router_data,
			intel_data_out => node_to_intel_data
        );
		  
		centurion_router_inst : entity centurion.centurion_router
					generic map (
				node_index => node_index
			) 
			port map(
				clk               => NoC_Clk,
				rst               => NoC_reset_reg ,
				North_In_Port     => North_In_Port,
				North_Out_Port    => North_Out_Port,
				East_In_Port      => East_In_Port,
				East_Out_Port     => East_Out_Port,
				South_In_Port     => South_In_Port,
				South_Out_Port    => South_Out_Port,
				West_In_Port      => West_In_Port,
				West_Out_Port     => West_Out_Port,
				Internal_In_Port  => router_I_in_port,
				Internal_Out_Port => router_I_Out_Port,

				node_clk => MCS_clk,
				node_reset => MCS_reset,
				MB_tick_out => MB_tick,
			
				node_rd_req_router => node_rd_req_router,
				node_rd_req_intel => node_rd_req_intel,
				router_data_out => router_to_node_data,
				intel_data_out => intel_to_node_data,
				
				node_wr_req_intel => node_wr_req_intel,
				node_wr_req_router => node_wr_req_router,
				router_node_data_in => node_to_router_data,
				intel_node_data_in => node_to_intel_data,
				
				router_noc_data_in => router_debug_in,
				intel_noc_data_in => intel_debug_in,
				router_noc_data_out => router_debug_out,
				intel_noc_data_out => intel_debug_out,
				
				router_noc_int_in => router_int,
				intel_noc_int_in => intel_int,
				noc_data_valid_in => debug_in_valid,
						
				--neighbouring nodes intel  	
				Intel_N      => Intel_N,
				Intel_E      => Intel_E,
				Intel_S     => Intel_S,
				Intel_W    => Intel_W,
				Intel_out     => Intel_out,
				Intel_req_in     => Intel_req_in,
				Intel_req_out    => Intel_req_out	

			);	




			
end architecture RTL;


