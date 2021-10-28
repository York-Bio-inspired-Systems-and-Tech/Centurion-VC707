library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;

entity centurion_router is
	generic (
			node_index : integer := 0
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
	
		--router ports
		North_In_Port : in router_in_port;
		North_Out_Port : out router_out_port;
		East_In_Port : in router_in_port;
		East_Out_Port : out router_out_port;
		South_In_Port : in router_in_port;
		South_Out_Port : out router_out_port;		
		West_In_Port : in router_in_port;
		West_Out_Port : out router_out_port;
		Internal_In_Port : in router_in_port;
		Internal_Out_Port : out router_out_port;
	 
	 	node_reset : out std_logic;
	 	node_clk : out std_logic;
	
		node_rd_req_router : out std_logic;
		node_rd_req_intel : out std_logic;
		router_data_out : out std_logic_vector(15 downto 0);
		intel_data_out : out std_logic_vector(7 downto 0);
		
		--from node
		node_wr_req_intel : in std_logic;
		node_wr_req_router : in std_logic;
		router_node_data_in : in std_logic_vector(7 downto 0);
		intel_node_data_in : in std_logic_vector(7 downto 0);
		
		router_noc_data_in : in std_logic_vector(8 downto 0);
		intel_noc_data_in : in std_logic_vector(8 downto 0);
		router_noc_data_out : out std_logic_vector(8 downto 0);
		intel_noc_data_out : out std_logic_vector(8 downto 0);
		
		router_noc_int_in : in std_logic;
		intel_noc_int_in : in std_logic;
		
		noc_data_valid_in : in std_logic;
		
		MB_tick_out : out std_logic;
		
		--neighbouring nodes intel
		Intel_N : in std_logic_vector(7 downto 0);
		Intel_E : in std_logic_vector(7 downto 0);
		Intel_S : in std_logic_vector(7 downto 0);
		Intel_W : in std_logic_vector(7 downto 0);
		Intel_out : out std_logic_vector(7 downto 0);
		Intel_req_in : in std_logic_vector(3 downto 0);
		Intel_req_out : out std_logic_vector(3 downto 0)		
			
		);
end entity centurion_router;

architecture RTL of centurion_router is
	signal Input_Direction : router_direction;
	
	signal data_ports_in : data_ports_array(NUM_PORTS -1 downto 0);
	signal control_sel_in : std_logic_vector(NUM_PORTS -1 downto 0);
	signal data_valid_in : std_logic_vector(NUM_PORTS -1 downto 0);
	
	signal data_ports_in_FIFO : data_ports_array(NUM_PORTS -1 downto 0);
	signal control_sel_in_FIFO : std_logic_vector(NUM_PORTS -1 downto 0);
	signal data_valid_in_FIFO : std_logic_vector(NUM_PORTS -1 downto 0);
	signal rd_en_out_FIFO : std_logic_vector(NUM_PORTS -1 downto 0);
	
	signal control_sel_out_switch : std_logic_vector(NUM_PORTS -1 downto 0);
	signal data_valid_out_switch : std_logic_vector(NUM_PORTS -1 downto 0);
	
	signal data_out: data_ports_array(NUM_PORTS -1 downto 0);
	signal data_out_switch : data_ports_array(NUM_PORTS -1 downto 0);
	signal control_sel_out : std_logic_vector(4 downto 0);
	signal data_valid_out : std_logic_vector(4 downto 0);
	signal routing_dirs : routing_dir_array(NUM_PORTS -1 downto 0);
	
	signal times : timer_array;
	signal timer_threshold : unsigned(TIMER_WIDTH-1 downto 0);
	
	signal Input_Port_Packet_in_Progress : std_logic_vector(NUM_PORTS -1 downto 0);
	signal Output_Port_Enable : std_logic_vector(NUM_PORTS -1 downto 0);
	signal Output_Port_Skip : std_logic_vector(NUM_PORTS -1 downto 0);
	
	signal routing_dirs_source : routing_dir_array(NUM_PORTS -1 downto 0);
	signal rd_en_in_switch : std_logic_vector(NUM_PORTS -1 downto 0);
	signal rd_en_in : std_logic_vector(NUM_PORTS -1 downto 0);
	signal rd_en_out_switch : std_logic_vector(NUM_PORTS -1 downto 0);
	
	signal EOP_detect : std_logic_vector(NUM_PORTS-1 downto 0);
	
	--RCAP port
	signal RCAP_In_Port : router_in_port;
	signal RCAP_Out_Port : router_out_port;
	
	signal packet_ids : packet_id_array(NUM_PORTS -2 downto 0);
	signal sop_detect : std_logic_vector(NUM_PORTS - 1 downto 0);
	signal deadlock_status : std_logic_vector(7 downto 0);
	signal deadlock_timeouts : std_logic_vector(NUM_PORTS - 2 downto 0);
	signal deadlock_timeouts_clear : std_logic_vector(NUM_PORTS - 2 downto 0);
	
	signal clk_en_int : std_logic;
	signal clk_freq_int : STD_LOGIC_VECTOR (DIVIDER_COUNTER_WIDTH-1 downto 0);
		

	signal	router_debug_status : std_logic_vector(15 downto 0);

	signal  Node_Temperature_int : std_logic_vector(RO_TEMP_WIDTH_OUT - 1 downto 0);
	signal Node_Temperature_RO : std_logic;

	signal router_to_intel : std_logic_vector(15 downto 0);
	signal router_intel_wr_en : std_logic;
	signal intel_to_router : std_logic_vector(15 downto 0);
	signal intel_router_wr_en : std_logic;
	
	signal deadlock_timer_tick : std_logic;
	signal global_timebases : std_logic_vector(3 downto 0);
	
	signal RO_en : std_logic;
	signal conversion_en : std_logic;
	
	
begin


switch_inst : entity work.switch
	port map(
		routing_dirs_out    => routing_dirs,
		Routing_Dirs_source => Routing_Dirs_source,
		data_valid_in       => data_valid_in_FIFO,
		data_ports_in       => data_ports_in_FIFO,
		control_sel_in      => control_sel_in_FIFO,
		rd_en_out           => rd_en_out_switch,
		data_ports_out      => data_out_switch,
		control_sel_out     => control_sel_out_switch,
		data_valid_out      => data_valid_out_switch,
		rd_en_in            => rd_en_in_switch
	);

	
router_cntrl_inst : entity work.router_cntrl
	port map(
		clk                           => clk,
		rst                           => rst,
		Routing_Dirs_out              => routing_dirs,
		Routing_Dirs_source			  => routing_dirs_source,
		Input_Port_Packet_in_Progress => Input_Port_Packet_in_Progress,
		Output_Port_Enable            => Output_Port_Enable,
		Output_Port_Skip 			  => Output_Port_Skip,
		sop_detected_in => sop_detect(NUM_PORTS -2 downto 0),
		EOP_detected_in				  => EOP_detect,
		input_timeouts_in 			  => deadlock_timeouts,
		router_timeouts_clear 		  => deadlock_timeouts_clear,
		
		data_in => data_ports_in_FIFO,
		data_cntrl_bit_in => control_sel_in(NUM_PORTS-2 downto 0),
		packet_ids_in => packet_ids,
		deadlock_status => deadlock_status,
		
		intel_bus_in => intel_to_router,
		intel_bus_out => router_to_intel,
		intel_wr_req => router_intel_wr_en,
		intel_rd_req => intel_router_wr_en,
		
		node_rd_req => node_rd_req_router,
		node_data_out => router_data_out,
		node_wr_req => node_wr_req_router,
		node_data_in => router_node_data_in,
		
		router_noc_data_in => router_noc_data_in,
		router_noc_data_out => router_noc_data_out,
		router_noc_int_in => router_noc_int_in,
		router_noc_data_valid_in => noc_data_valid_in			
	);
	
	timer_threshold <= (others => '1');

	data_ports_in(0) <= North_In_Port.data_in;
	data_ports_in(1) <= East_In_Port.data_in;
	data_ports_in(2) <= South_In_Port.data_in;
	data_ports_in(3) <= West_In_Port.data_in;
	data_ports_in(4) <= Internal_In_Port.data_in;
	
	control_sel_in(0) <= North_In_Port.control_sel;
	control_sel_in(1) <= East_In_Port.control_sel;
	control_sel_in(2) <= South_In_Port.control_sel;
	control_sel_in(3) <= West_In_Port.control_sel;
	control_sel_in(4) <= Internal_In_Port.control_sel;
	
	data_valid_in(0) <= North_In_Port.data_valid;
	data_valid_in(1) <= East_In_Port.data_valid;
	data_valid_in(2) <= South_In_Port.data_valid;
	data_valid_in(3) <= West_In_Port.data_valid;
	data_valid_in(4) <= Internal_In_Port.data_valid;

	rd_en_in(0) <= North_In_Port.rd_en;
	rd_en_in(1) <= East_In_Port.rd_en;
	rd_en_in(2) <= South_In_Port.rd_en;
	rd_en_in(3) <= West_In_Port.rd_en;
	rd_en_in(4) <= Internal_In_Port.rd_en;
	

	North_out_Port.data_out     <= data_out(0);
	East_out_Port.data_out      <= data_out(1);
	South_out_Port.data_out     <= data_out(2);
	West_out_Port.data_out      <= data_out(3);
	Internal_out_Port.data_out  <= data_out(4);
	
	North_out_Port.control_sel     <= control_sel_out(0);
	East_out_Port.control_sel      <= control_sel_out(1);
	South_out_Port.control_sel     <= control_sel_out(2);
	West_out_Port.control_sel      <= control_sel_out(3);
	Internal_out_Port.control_sel  <= control_sel_out(4);
	
	North_out_Port.data_valid     <= data_valid_out(0);
	East_out_Port.data_valid      <= data_valid_out(1);
	South_out_Port.data_valid     <= data_valid_out(2);
	West_out_Port.data_valid      <= data_valid_out(3);
	Internal_out_Port.data_valid  <= data_valid_out(4);
	
	--RD enable is not registered (an "input channel" ouput...)
	North_Out_Port.rd_en     <= rd_en_out_FIFO(0);
	East_out_Port.rd_en      <= rd_en_out_FIFO(1);
	South_out_Port.rd_en     <= rd_en_out_FIFO(2);
	West_out_Port.rd_en      <= rd_en_out_FIFO(3);
	Internal_out_Port.rd_en  <= rd_en_out_FIFO(4);	
	
	out_regs_gen : for i in 0 to 4 generate
		output_port_reg_inst : entity work.output_port_reg
			port map(
				clk             => clk,
				rst             => rst,
				data_in         => data_out_switch(i),
				control_sel_in  => control_sel_out_switch(i),
				data_valid_in   => data_valid_out_switch(i),
				rd_en_out       => rd_en_in_switch(i),
				output_en       => Output_Port_Enable(i),
				Output_Port_Skip => Output_Port_Skip(i),
				data_out        => data_out(i),
				control_sel_out => control_sel_out(i),
				data_valid_out  => data_valid_out(i),
				rd_en_in        => rd_en_in(i),
			EOP_detect_out 	=> EOP_detect(i)
			);
		
	end generate out_regs_gen;
	
--	router_config_port_inst : entity work.router_config_port
--		port map(
--			clk             => clk,
--			rst             => rst,
--			data_in         => data_out_switch(5),
--			control_sel_in  => control_sel_out_switch(5),
--			data_valid_in   => data_valid_out_switch(5),
--			rd_en_out       => rd_en_in_switch(5),
--			output_en       =>Output_Port_Enable(5),
--			data_out        =>	data_ports_in(5),
--			control_sel_out => control_sel_in(5),
--			data_valid_out  => data_valid_in(5),
--			rd_en_in        => rd_en_in(5),
--			EOP_detect_out 	=> EOP_detect(5),
--			
--			RCAP_data => RCAP_data,
--			RCAP_data_valid => RCAP_data_valid,
--			RCAP_rd_en => RCAP_rd_en
--		
--			
--		);
--		
		rd_en_in(5) <= '0';
		data_out(5) <= (others => '0');
		  
	
	input_fifo_gen : for i in 0 to 4 generate
		input_fifo_inst : entity work.input_fifo
			port map(
				clk             => clk,
				rst             => rst,
				data_in         => data_ports_in(i),
				control_sel_in  => control_sel_in(i),
				data_valid_in   => data_valid_in(i),
				rd_en_out       => rd_en_out_FIFO(i),
				data_out        => data_ports_in_FIFO(i),
				control_sel_out => control_sel_in_FIFO(i),
				data_valid_out  => data_valid_in_FIFO(i),
				rd_en_in        => rd_en_out_switch(i),
				current_packet_id	=> packet_ids(i),
				SOP_detected 	=> sop_detect(i),
				channel_in_use => Input_Port_Packet_in_Progress(i),
				timer_tick 		=> deadlock_timer_tick,
				timer_threshold => timer_threshold,
				deadlock_timer_expire => deadlock_timeouts(i),
				deadlock_timeout_clear => deadlock_timeouts_clear(i)
			);		
	end generate input_fifo_gen;
	
	deadlock_timer_tick <= global_timebases(1);

	RCAP_In_Port.data_in <= data_out_switch(5);
	RCAP_In_Port.control_sel <= control_sel_out_switch(5);
	RCAP_In_Port.data_valid <= data_valid_out_switch(5);
	RCAP_In_Port.rd_en <= rd_en_out_FIFO(5); 
	
	data_ports_in_FIFO(5) <= RCAP_Out_Port.data_out;
	control_sel_in_FIFO(5) <= RCAP_Out_Port.control_sel;
	data_valid_in_FIFO(5) <= RCAP_Out_Port.data_valid;	
	rd_en_in_switch(5) <= RCAP_Out_Port.rd_en;
	
	
	
router_intelligence_inst : entity work.router_intelligence		
	generic map (
		node_index => node_index
	) 
	port map(
		clk               => clk,
		reset               => rst,
		
		M_node_thermal_state => Node_Temperature_RO,	
		K_clk_en => clk_en_int,
		K_clk_freq => clk_freq_int,
		K_node_reset => node_reset,
	
		node_rd_req_intel => node_rd_req_intel,
		intel_node_data_out 	=>	intel_data_out,
	                       
		node_wr_req_intel => node_wr_req_intel,
		intel_node_data_in  => intel_node_data_in,		
		
		intel_noc_data_in => intel_noc_data_in,
		intel_noc_data_out => intel_noc_data_out,
		intel_noc_int_in => intel_noc_int_in,
		intel_noc_data_valid_in => noc_data_valid_in,
		
		router_cntrl_bus_in => router_to_intel,
		router_intel_req => router_intel_wr_en,  
		intel_bus_out => intel_to_router,
		intel_router_req => intel_router_wr_en,

		--timebases
		MB_timer_tick => MB_tick_out,
		
		RO_en => RO_en, 
		RO_conversion_en => Conversion_en,
		
		--neighbouring nodes intel  	
		Intel_N      => Intel_N,
		Intel_E      => Intel_E,
		Intel_S     => Intel_S,
		Intel_W    => Intel_W,
		Intel_out     => Intel_out,
		Intel_req_in     => Intel_req_in,
		Intel_req_out    => Intel_req_out,
		
		RCAP_In_Port => RCAP_in_port,
		RCAP_Out_Port => RCAP_out_port,
		RCAP_output_en => Output_Port_Enable(5),
		RCAP_SOP_detect => sop_detect(5),
		RCAP_EOP_detect => EOP_detect(5)
	);


temp_sensor : entity work.RO_temp_sensor
	port map
	(
		clk => clk, 
		ring_osc_en => RO_en, 
		conversion_en => Conversion_en,
		tick_1us => global_timebases(1),
		temp_out => Node_Temperature_int,
		ro_out => Node_Temperature_RO
	);
	
	
mcs_clk_inst : entity centurion.dynamic_node_clk
	port map( 
		 	fast_clk_in => clk,
			div_value => clk_freq_int,
			node_clk_enable => clk_en_int,
			div_clk_out => node_clk
           );



end architecture RTL;
