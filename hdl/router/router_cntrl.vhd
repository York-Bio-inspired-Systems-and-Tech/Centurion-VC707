library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library centurion;
use centurion.centurion_pkg.all;

entity router_cntrl is
	port (
		clk : in std_logic;
		rst : in std_logic;
			
		Routing_Dirs_out : out routing_dir_array(NUM_PORTS -1 downto 0);
		Routing_Dirs_source : out routing_dir_array(NUM_PORTS -1 downto 0);	
		 
		Input_Port_Packet_in_Progress : out std_logic_vector(NUM_PORTS - 1 downto 0);
		
		Output_Port_Enable : out std_logic_vector(NUM_PORTS - 1 downto 0);
		Output_Port_Skip : out std_logic_vector(NUM_PORTS - 1 downto 0);
		
		SOP_Detected_in : in std_logic_vector(NUM_PORTS - 2 downto 0);
		EOP_Detected_in : in std_logic_vector(NUM_PORTS-1 downto 0);
		
		Packet_IDs_in : in packet_id_array(NUM_PORTS - 2 downto 0);
		
		deadlock_status : out std_logic_vector(7 downto 0);
		--router ports
		data_in : in data_ports_array(NUM_PORTS -1 downto 0);
		data_cntrl_bit_in : in std_logic_vector(NUM_PORTS - 2 downto 0);
		input_timeouts_in : in std_logic_vector(NUM_PORTS - 2 downto 0);
		router_timeouts_clear : out std_logic_vector(NUM_PORTS - 2 downto 0);

		intel_bus_in : in std_logic_vector(15 downto 0);
		intel_bus_out : out std_logic_vector(15 downto 0);
		intel_wr_req : out std_logic;
		intel_rd_req : in std_logic;
					
		node_rd_req : out std_logic;
		node_data_out : out std_logic_vector(15 downto 0);
		
		node_wr_req : in std_logic;
		node_data_in : in std_logic_vector(7 downto 0);
		
		router_noc_data_in : in std_logic_vector(8 downto 0);
		router_noc_data_out : out std_logic_vector(8 downto 0);
		router_noc_int_in : in std_logic;
		router_noc_data_valid_in : in std_logic
		
	);
end entity router_cntrl;

architecture RTL of router_cntrl is
	signal Packet_in_Progress : std_logic_vector(NUM_PORTS - 1 downto 0);
		
	--FSM enumerations
	type input_port_state is (idle, Wait_for_uC_ack, Header_delete,  In_use, EOP_detected);
	type channel_setup_state is (RR_idle, Request, Setup, EOP);
	type routing_FSM_states is (RR_idle, Request, Match);
	
	--array declarations
	type task_id_array is array(integer range <>) of unsigned(NUM_TASKS_Log2 -1 downto 0);
	type task_offset_array is array(integer range <>) of unsigned(1 downto 0); 
	type input_port_array is array(integer range <>) of input_port_state;
	
	--input port signals (per port, NESWI)
	signal input_ports_state : input_port_array(NUM_PORTS - 2 downto 0);
	signal task_packet_detect : std_logic_vector(NUM_PORTS-2 downto 0);
	signal requested_out_dirs : routing_dir_array(NUM_PORTS-2 downto 0);
	signal output_port_EOP_reports  : std_logic_vector(NUM_PORTS-2 downto 0);
	signal header_delete_reg   : std_logic_vector(NUM_PORTS-1 downto 0);
	signal output_en_input_port   : std_logic_vector(NUM_PORTS-1 downto 0);
	
	
	--routing dir signals
	signal task_indexes : task_id_array(NUM_PORTS - 2 downto 0);
	signal task_option_offsets : task_offset_array(NUM_PORTS - 2 downto 0);
	signal routing_lookup_requests : std_logic_vector(NUM_PORTS - 2 downto 0);
	signal routing_lookup_done : std_logic_vector(NUM_PORTS - 2 downto 0);
	signal routing_dir_value : router_direction;
	signal routing_lookup_state : routing_FSM_states;
	signal routing_RR_dir :  unsigned(2 downto 0);
	signal routing_ID_value : unsigned(PACKET_ID_LENGTH - 1 downto 0);
	signal routing_current_task : unsigned(NUM_TASKS_Log2 -1 downto 0);
	signal routing_current_offset : unsigned(1 downto 0);	
	signal routing_offset_count : unsigned(1 downto 0);	
	signal routing_entry_counter : unsigned(ROUTER_TABLE_LEN_log2 -1 downto 0);

	--output port request signals
	signal output_port_requests : std_logic_vector(NUM_PORTS - 2 downto 0);
	signal output_port_acks : std_logic_vector(NUM_PORTS - 2 downto 0);
	signal output_setup_state : channel_setup_state;
	signal Output_Port_Busy_reg : std_logic_vector(NUM_PORTS - 1 downto 0);
	signal Output_Port_header_delete : std_logic_vector(NUM_PORTS - 1 downto 0);
	signal output_RR_dir	: unsigned(2 downto 0);
	signal current_selected_out_dir : router_direction;
	signal output_dirs_reg : routing_dir_array(NUM_PORTS -1 downto 0);
	signal output_dirs_source_reg : routing_dir_array(NUM_PORTS -1 downto 0);
	signal output_en :  std_logic_vector(NUM_PORTS-1 downto 0);
	signal deadlock_detect_reg : std_logic_vector(NUM_PORTS -2 downto 0);
	signal channel_setup_acks_uC_out : std_logic_vector(NUM_PORTS -2 downto 0);
	signal EOP_detect_UC_in : std_logic_vector(NUM_PORTS -2 downto 0);
	signal timeout_UC_reset : std_logic_vector(NUM_PORTS - 2 downto 0);
	
	signal internal_packet_offset_reg : unsigned(1 downto 0);
	
	signal Routing_Dirs_sink_int : routing_dir_array(NUM_PORTS -1 downto 0);
	signal Routing_Dirs_source_int : routing_dir_array(NUM_PORTS -1 downto 0);	
		
	
	signal intel_bus_out_int : std_logic_vector(15 downto 0);
	signal intel_wr_req_int : std_logic;
	signal nodes_busy_int : std_logic_vector(NUM_PORTS -1 downto 0);
	signal nodes_intel_busy_int : std_logic_vector(NUM_PORTS -2 downto 0);
	signal timer_threshold_int  : unsigned(TIMER_WIDTH -1 downto 0);

	
	signal node_rd_req_int : std_logic;
	signal node_data_out_int : std_logic_vector(15 downto 0);
	
	signal SOHPP_Detected_in : std_logic_vector(NUM_PORTS -2 downto 0);
	
	--
-- Declaration of the KCPSM6 component including default values for generics.
--

  component kcpsm6 
    generic(                 hwbuild : std_logic_vector(7 downto 0) := X"00";
                    interrupt_vector : std_logic_vector(11 downto 0) := X"380";
             scratch_pad_memory_size : integer := 64);
    port (                   address : out std_logic_vector(11 downto 0);
                         instruction : in std_logic_vector(17 downto 0);
                         bram_enable : out std_logic;
                             in_port : in std_logic_vector(7 downto 0);
                            out_port : out std_logic_vector(7 downto 0);
                             port_id : out std_logic_vector(7 downto 0);
                        write_strobe : out std_logic;
                      k_write_strobe : out std_logic;
                         read_strobe : out std_logic;
                           interrupt : in std_logic;
                       interrupt_ack : out std_logic;
                               sleep : in std_logic;
                               reset : in std_logic;
                                 clk : in std_logic);
  end component;
	
	-- Signals for connection of KCPSM6 and Program Memory.
	--
	
	signal         uC_address : std_logic_vector(11 downto 0);
	signal     uC_instruction : std_logic_vector(17 downto 0);
	signal     uC_bram_enable : std_logic;
	signal         uC_in_port : std_logic_vector(7 downto 0);
	signal       uC_out_port : std_logic_vector(7 downto 0);
	signal         uC_port_id : std_logic_vector(7 downto 0);
	signal    uC_write_strobe : std_logic;
	signal  uC_k_write_strobe : std_logic;
	signal     uC_read_strobe : std_logic;
	signal       uC_interrupt : std_logic;
	signal   uC_interrupt_ack : std_logic;
	signal    uC_kcpsm6_sleep : std_logic;
	signal    uC_kcpsm6_reset : std_logic;

	signal uC_interrupt_latch : std_logic;
	signal interrupt : std_logic_vector(2 downto 0);
	signal interrupt_reg : std_logic_vector(2 downto 0);
	signal interrupt_en_reg : std_logic_vector(2 downto 0);
	signal router_noc_int_reg : std_logic;
	signal router_noc_int_pulse : std_logic;

	signal NoC_debug_out : std_logic_vector(7 downto 0);
	signal NoC_debug_valid_out : std_logic;
			
	signal uC_b_addr : std_logic_vector(11 downto 0);
	signal uC_b_din : std_logic_vector(17 downto 0);
	signal uC_b_dout : std_logic_vector(17 downto 0);
	signal uC_b_wr_en : std_logic;
	
	signal packet_ID_sel : unsigned(2 downto 0);
	signal packet_ID_sel_int : integer; 
	signal packet_ID_reg : unsigned(15 downto 0);
	
begin
	
	router_noc_data_out <= NoC_debug_valid_out & NoC_debug_out;
	
	Output_Port_Skip <= header_delete_reg;
	
	Output_Port_Enable <= output_en;
	deadlock_status <= (others => '0');

	Routing_Dirs_out <= Routing_Dirs_sink_int;
	Routing_Dirs_source <= Routing_Dirs_source_int;
		

	Input_Port_Packet_in_Progress <= Packet_in_Progress;
	Packet_in_Progress(5) <= '0';
	router_timeouts_clear <= timeout_UC_reset;
	
	intel_bus_out <= intel_bus_out_int;
	intel_wr_req <= intel_wr_req_int;
	node_data_out <= node_data_out_int;
	node_rd_req <= node_rd_req_int;
		
output_en_gen : for i in 0 to NUM_PORTS - 1 generate
--	output_en(i) <= not Output_Port_header_delete(i);
	output_en(i) <= '1' when input_ports_state(dir_to_int(Routing_Dirs_sink_int(i))) = In_use and Routing_Dirs_sink_int(i) /= Idle else '0';
end generate output_en_gen;	




Input_Port_FSM_gen : for i in 0 to NUM_ports - 2 generate
SOHPP_Detected_in(i) <= data_in(i)(5) when input_ports_state(i) = Wait_for_uC_ack else '0';


Packet_in_Progress(i) <= '1' when input_ports_state(i) = In_use or input_ports_state(i) = Header_delete or input_ports_state(i) = EOP_detected else '0';

fsm_proc : process (clk) is
begin
	if rising_edge(clk) then
		if rst = '1' then
			input_ports_state(i) <= idle;
			EOP_detect_uC_in(i) <= '0';
			Output_Port_header_delete(i) <= '0';
		else
			case input_ports_state(i) is
			when idle =>
				EOP_detect_uC_in(i) <= '0';
				if SOP_Detected_in(i) = '1' then
					input_ports_state(i) <= Wait_for_uC_ack;
				end if;
						
			when Wait_for_uC_ack =>
					if header_delete_reg(i) = '1' then
						Output_Port_header_delete(i) <= '1';
					end if;

				if channel_setup_acks_uC_out(i) = '1' then
					input_ports_state(i) <= In_use;
				end if;
				
			when Header_delete =>
					input_ports_state(i) <= In_use;
				
			when In_use =>	
				Output_Port_header_delete(i) <= '0';
				if EOP_Detected_in(dir_to_int(Routing_Dirs_source_int(i))) = '1' then
					input_ports_state(i) <= EOP_detected;	
					EOP_detect_UC_in(i) <= '1';
				end if;
					
			when EOP_detected =>
				if channel_setup_acks_uC_out(i) = '0' then
					input_ports_state(i) <= idle;	
				end if;
			end case;
			
		end if;
	end if;
end process fsm_proc;

end generate Input_Port_FSM_gen;


cntrl_picoblaze_BRAM : entity centurion.picoblaze_BRAM
    generic map(
        ROM_FILE => "router.mem"
    )
	port map (
		clk_a => clk,
		en_a => uC_bram_enable,
		addr_a => uC_address,
		dout_a => uC_instruction,
		

		wr_en_b => uC_b_wr_en,
		addr_b => uC_b_addr,
		din_b => uC_b_din,
		dout_b => uC_b_dout
	);

  cntrl_picoblaze: kcpsm6
    generic map (        hwbuild => X"00", 
                         interrupt_vector => X"380",
                  scratch_pad_memory_size => 256)
    port map(      address => uC_address,
               instruction => uC_instruction,
               bram_enable => uC_bram_enable,
                   port_id => uC_port_id,
              write_strobe => uC_write_strobe,
            k_write_strobe => uC_k_write_strobe,
                  out_port => uC_out_port,
               read_strobe => uC_read_strobe,
                   in_port => uC_in_port,
                 interrupt => uC_interrupt,
             interrupt_ack => uC_interrupt_ack,
                     sleep => uC_kcpsm6_sleep,
                     reset => uC_kcpsm6_reset,
                       clk => clk);


 uC_kcpsm6_sleep <= '0';
 uC_kcpsm6_reset <= rst;
 uC_interrupt <=  or_reduce(interrupt and interrupt_en_reg); 
 
  interrupt <= 	 
 				router_noc_int_pulse
 			&	node_wr_req
 			& 	intel_rd_req;
 
router_noc_int_pulse <= router_noc_int_in and (not router_noc_int_reg);


noc_int_sync_proc : process (clk) is
begin
	if rising_edge(clk) then
		if rst = '1' then
			router_noc_int_reg <= '0';
		else
			router_noc_int_reg <= router_noc_int_reg;
		end if;
	end if;
end process;
			
 --output port decode
 uC_output_sync_proc : process (clk) is
 begin
 	if rising_edge(clk) then
	
		if rst = '1' then
			for i in 0 to NUM_PORTS -1 loop
				Routing_Dirs_sink_int(i) <= idle;
				Routing_Dirs_source_int(i) <= idle;
			end loop;
			
				header_delete_reg <= (others => '0');
				channel_setup_acks_uC_out <= (others => '0');
				timeout_UC_reset <=(others => '0');
				
				intel_wr_req_int <= '0';
				intel_bus_out_int(7 downto 0) <= (others => '0');
				intel_bus_out_int(15 downto 8) <= (others => '0');
				
				interrupt_en_reg <= (others => '0');
 				uC_interrupt_latch <= '0';
				
				node_rd_req_int <= '0';
				node_data_out_int <= (others => '0');
				NoC_debug_valid_out <= '0';
				
				 uC_b_wr_en <= '0';
				uC_b_addr  <= (others => '0');
				uC_b_din	<= (others => '0');
                          
		else
			
				--clear interrupt on ISR handler read
 			if uC_read_strobe = '1' and uC_port_id = x"05" then
 				interrupt_reg <= (others => '0');
 				uC_interrupt_latch <= '0';	
 			end if;
 			
 			if uC_interrupt = '1' then
 				uC_interrupt_latch <= '1';
 				interrupt_reg <= interrupt and interrupt_en_reg;
 			end if;
			
			intel_wr_req_int <= '0';
			if uC_write_strobe = '1' then
				case uC_port_id is
					when x"10" => Routing_Dirs_sink_int(0) <= vector_to_dir(uC_out_port(2 downto 0));
					when x"11" => Routing_Dirs_sink_int(1) <= vector_to_dir(uC_out_port(2 downto 0));
					when x"12" => Routing_Dirs_sink_int(2) <= vector_to_dir(uC_out_port(2 downto 0));
					when x"13" => Routing_Dirs_sink_int(3) <= vector_to_dir(uC_out_port(2 downto 0));
					when x"14" => Routing_Dirs_sink_int(4) <= vector_to_dir(uC_out_port(2 downto 0));
					when x"15" => Routing_Dirs_sink_int(5) <= vector_to_dir(uC_out_port(2 downto 0));
						
					
					when x"20" => Routing_Dirs_source_int(0) <= vector_to_dir(uC_out_port(2 downto 0));
					when x"21" => Routing_Dirs_source_int(1) <= vector_to_dir(uC_out_port(2 downto 0));
					when x"22" => Routing_Dirs_source_int(2) <= vector_to_dir(uC_out_port(2 downto 0));
					when x"23" => Routing_Dirs_source_int(3) <= vector_to_dir(uC_out_port(2 downto 0));
					when x"24" => Routing_Dirs_source_int(4) <= vector_to_dir(uC_out_port(2 downto 0));
					when x"25" => Routing_Dirs_source_int(5) <= vector_to_dir(uC_out_port(2 downto 0));
					
					when x"30" => header_delete_reg <= uC_out_port(NUM_PORTS -1 downto 0);
					when x"31" => channel_setup_acks_uC_out <= uC_out_port(NUM_PORTS -2 downto 0);
					when x"32" => timeout_UC_reset <= uC_out_port(NUM_PORTS -2 downto 0);
					when x"33" => packet_ID_sel  <= unsigned(uC_out_port(2 downto 0));
					
					when x"04" => intel_wr_req_int <= uC_out_port(0);
					when x"40" => intel_bus_out_int(7 downto 0) <= uC_out_port(7 downto 0);
					when x"41" => intel_bus_out_int(15 downto 8) <= uC_out_port(7 downto 0);
					
					when x"05" => node_rd_req_int <= uC_out_port(0);
					when x"50" => node_data_out_int(7 downto 0) <= uC_out_port(7 downto 0);
					when x"51" => node_data_out_int(15 downto 8) <= uC_out_port(7 downto 0);
					
					
					when x"06" => uC_b_wr_en  <=  uC_out_port(0);
					when x"60" => uC_b_addr(7 downto 0) <= uC_out_port(7 downto 0);
					when x"61" => uC_b_addr(11 downto 8) <= uC_out_port(3 downto 0);
					when x"62" => uC_b_din(7 downto 0) <= uC_out_port(7 downto 0);
					when x"63" => uC_b_din(15 downto 8) <= uC_out_port(7 downto 0);
					when x"64" => uC_b_din(17 downto 16) <= uC_out_port(1 downto 0);
			
					
					when x"80" => NoC_debug_out  <= uC_out_port(7 downto 0);
					when x"81" => NoC_debug_valid_out  <= uC_out_port(0);
						
					when x"09" => interrupt_en_reg  <=  uC_out_port(2 downto 0);
						
					
					 
					when others => null;
				end case;
			end if;
			
			if uC_k_write_strobe = '1' then
				case uC_port_id(3 downto 0) is

					when x"9" => interrupt_en_reg  <=  uC_out_port(2 downto 0);

					when others => null;
				end case;
			end if;
		end if;
 	end if;
 end process uC_output_sync_proc;



packet_ID_sel_int <= to_integer(packet_ID_sel) when to_integer(packet_ID_sel) < NUM_PORTS -1 else 0;  

 --input port decode
 uC_input_sync_proc : process (clk) is
 begin
 	if rising_edge(clk) then
 		
 		packet_ID_reg <= Packet_IDs_in(packet_ID_sel_int);
 		
		--if uC_read_strobe = '1' then
				uC_in_port <= (others => '0');
			case uC_port_id is
				when x"10" => uC_in_port(NUM_PORTS -2 downto 0) <= SOP_Detected_in;
				when x"11" => uC_in_port(NUM_PORTS -2 downto 0) <= EOP_detect_UC_in;
				when x"12" => uC_in_port(NUM_PORTS -2 downto 0) <= input_timeouts_in;  
				when x"13" => uC_in_port(0) <= node_wr_req; 
				when x"14" => uC_in_port(NUM_PORTS -2 downto 0) <= SOHPP_Detected_in;
				
				when x"20" => uC_in_port(7 downto 0) <= data_in(0)(7 downto 0);
				when x"21" => uC_in_port(7 downto 0) <= data_in(1)(7 downto 0);
				when x"22" => uC_in_port(7 downto 0) <= data_in(2)(7 downto 0);
				when x"23" => uC_in_port(7 downto 0) <= data_in(3)(7 downto 0);
				when x"24" => uC_in_port(7 downto 0) <= data_in(4)(7 downto 0);
				when x"25" => uC_in_port(NUM_PORTS -2 downto 0) <= data_cntrl_bit_in;
				
				when x"30" => uC_in_port(7 downto 0) <= std_logic_vector(packet_ID_reg(7 downto 0));
				when x"31" => uC_in_port(7 downto 0) <= std_logic_vector(packet_ID_reg(15 downto 8));

				
				when x"01" => uC_in_port(7 downto 0) <= intel_bus_in(7 downto 0);
				when x"02" => uC_in_port(7 downto 0) <= intel_bus_in(15 downto 8);
				
				when x"50" => uC_in_port(7 downto 0) <= node_data_in;

				when x"62" => uC_in_port(7 downto 0) <= uC_b_dout(7 downto 0);
				when x"63" => uC_in_port(7 downto 0) <= uC_b_dout(15 downto 8);
				when x"64" => uC_in_port(7 downto 0) <= "000000" & uC_b_dout(17 downto 16);
			

				when x"80" => uC_in_port(7 downto 0) <= router_noc_data_in(7 downto 0);
				when x"81" => uC_in_port(7 downto 0) <= "000000" & router_noc_data_valid_in & router_noc_data_in(8);

				when x"05" => uC_in_port(7 downto 0) <= "00000" & interrupt_reg;
				

				when others => uC_in_port <= "XXXXXXXX";
			end case;
		--end if;
 	end if;
 end process uC_input_sync_proc;
  


end architecture RTL;
