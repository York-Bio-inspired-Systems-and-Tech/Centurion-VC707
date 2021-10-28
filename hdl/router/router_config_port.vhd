library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;

entity router_config_port is
	port (
		clk : in std_logic;
		rst : in std_logic;

		--input channel
		data_in : in std_logic_vector(ROUTER_DATA_WIDTH-1 downto 0);
		control_sel_in : in std_logic;
		data_valid_in : in std_logic;
		
		--input response
		rd_en_out : out std_logic;
		
		--output channel
		output_en : in std_logic;
		data_out : out std_logic_vector(ROUTER_DATA_WIDTH-1 downto 0);
		control_sel_out : out std_logic;
		data_valid_out : out std_logic;
		--output response
		rd_en_in : in std_logic;
		EOP_Detect_out : out std_logic;
		
		--signals to control uC
		RCAP_data : out std_logic_vector(ROUTER_DATA_WIDTH-1 downto 0);
		RCAP_data_valid : out std_logic;
		RCAP_rd_en : in std_logic
		

		
		
	);
end entity router_config_port;

architecture RTL of router_config_port is
	signal rd_en_int : std_logic;
	
	type reg_state is (load, hold, skip);
	signal if_state : reg_state;
	signal if_next_state : reg_state;
	type RCAP_state is (idle, header, routing_table_load_offset, routing_table_load_task, routing_table_load_dir, 
						reg_file_load_value, intel_load_ID, intel_load_byte, intel_load_bits, intel_load_last_bit_count, intel_bits_done);
	signal state : RCAP_state;

	signal data_in_valid : std_logic;
	
	signal routing_table_update_task : unsigned(NUM_TASKS_Log2-1 downto 0);
	signal routing_table_update_offset : unsigned(ROUTER_TABLE_LEN_log2 -1 downto 0);
	
	
	signal Routing_Table_Update : std_logic;
	
	type reg_file_t is array(0 to ROUTER_RCAP_NUM_REGS - 1) of std_logic_vector(ROUTER_DATA_WIDTH -1 downto 0);
	signal reg_file : reg_file_t;
	signal reg_addr : unsigned(log2(ROUTER_RCAP_NUM_REGS) -1 downto 0);
	signal RCAP_header_processed : std_logic;
	
	type routing_table_dir is array(0 to ROUTER_TABLE_LEN -1) of router_direction;
	type routing_table_task is array(0 to ROUTER_TABLE_LEN-1) of unsigned(NUM_tasks_log2 -1 downto 0);
	signal routing_table_dirs : routing_table_dir;
	signal routing_table_tasks : routing_table_task;
	
	signal EOP_Detect : std_logic;
	--TODO: refactor
	signal routing_table_update_reg : std_logic;
	
  	signal	timer_threshold : std_logic_vector(TIMER_WIDTH -1 downto 0);
	signal node_enable_int : std_logic;
	signal div_value_int :   STD_LOGIC_VECTOR (DIVIDER_COUNTER_WIDTH-1 downto 0);



		
	begin
	
	
	--currently the config port is write only
	data_valid_out <= '0';
	control_sel_out <= '0';
	data_out <= (others => '0');
	
	--response channel 
	rd_en_out <= rd_en_int;  
	 
	--routing table
	
 	EOP_Detect <= '1' when data_valid_in = '1' and control_sel_in = '1' and data_in = ROUTER_EOP_PACKET and if_state = hold
					else '0';
	 EOP_Detect_out <= EOP_Detect;
	 
	 

	RCAP_data <= data_in;
	RCAP_data_valid <= data_in_valid;
		
	data_in_valid <= '1' when if_state = hold and EOP_Detect = '0' else '0';
	



rd_en_int <= RCAP_rd_en when (data_valid_in = '1' and if_state = hold ) else 
			'1' 		when if_state = skip 
			else '0';

state_comb_proc : process(if_state, data_valid_in, output_en, rd_en_int) is
begin
	if_next_state <= if_state;
	case if_state is 
	when load =>
			if data_valid_in = '1' and output_en = '1' then
				if_next_state <= hold;
			elsif data_valid_in = '1' and output_en = '0' then
				if_next_state <= skip;
			end if;
		when hold =>
			if rd_en_int = '1' then
				if_next_state <= load;
			end if;
		when skip =>
			if_next_state <= load;
			
	end case;
end process state_comb_proc;


state_sync_proc : process (clk) is
begin
	if rising_edge(clk) then
		if rst = '1' then
			if_state <= load;
		else
			if_state <= if_next_state;
		end if;
	end if;
end process state_sync_proc;

--



end architecture RTL;



