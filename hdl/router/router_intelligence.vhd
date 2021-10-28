library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library centurion;
use centurion.centurion_pkg.all;

entity router_intelligence is
	generic (
			node_index : integer := 0
	);
	port (
		clk : in std_logic;
		reset : in std_logic;
		
		--monitors
		M_node_thermal_state : in std_logic;
			
		--knobs
		K_clk_en : out std_logic;
		K_clk_freq : out std_logic_vector(DIVIDER_COUNTER_WIDTH -1 downto 0);
		K_node_reset : out std_logic;
		
		router_cntrl_bus_in : in std_logic_vector(15 downto 0);
		intel_bus_out : out std_logic_vector(15 downto 0);
		router_intel_req : in std_logic;
		intel_router_req : out std_logic;
		
		node_rd_req_intel : out std_logic;
		intel_node_data_out : out std_logic_vector(7 downto 0);
	
		node_wr_req_intel : in std_logic;
		intel_node_data_in : in std_logic_vector(7 downto 0);		
		
		intel_noc_data_in : in std_logic_vector(8 downto 0);
		intel_noc_data_out : out std_logic_vector(8 downto 0);
		intel_noc_int_in : in std_logic;
		--this signal shows if the data is valid for just this node (will need to be handled in software)
		intel_noc_data_valid_in : in std_logic;
		
		--timebases
		MB_timer_tick : out std_logic;
		
		RO_en : out std_logic; 
		RO_conversion_en : out std_logic;
		
		--neighbouring nodes intel
		Intel_N : in std_logic_vector(7 downto 0);
		Intel_E : in std_logic_vector(7 downto 0);
		Intel_S : in std_logic_vector(7 downto 0);
		Intel_W : in std_logic_vector(7 downto 0);
		Intel_out : out std_logic_vector(7 downto 0);
		Intel_req_in : in std_logic_vector(3 downto 0);
		Intel_req_out : out std_logic_vector(3 downto 0);
		
		--RCAP signals
		RCAP_In_Port : in router_in_port;
		RCAP_Out_Port : out router_out_port;
		RCAP_output_en : in std_logic;
		RCAP_SOP_detect : out std_logic;
		RCAP_EOP_detect : out std_logic
		
	);
end entity router_intelligence;

architecture RTL of router_intelligence is
	--config signals
	
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
	
	signal knobs_cntrl : std_logic_vector(15 downto 0);
	signal router_rd_req_int : std_logic;
	signal node_data_out : std_logic_vector(7 downto 0);
	signal node_rd_req_int : std_logic;
	

	signal K_node_reset_int : std_logic;
	signal K_clk_en_int : std_logic;
	signal K_clk_freq_int : std_logic_vector(DIVIDER_COUNTER_WIDTH -1 downto 0);

	signal Intel_req_out_int : std_logic_vector(3 downto 0); 
 	signal Intel_out_int : std_logic_vector(7 downto 0);

	signal RCAP_data_in : std_logic_vector(7 downto 0);
	signal RCAP_control_sel_in : std_logic;
	signal RCAP_data_valid_in : std_logic;
	signal RCAP_rd_en_out : std_logic;
	
	signal RCAP_data_out : std_logic_vector(7 downto 0);
	signal RCAP_control_sel_out : std_logic;
	signal RCAP_data_valid_out : std_logic;	
	signal RCAP_rd_en_in : std_logic;

	
	signal uC_interrupt_latch : std_logic;
	signal interrupt : std_logic_vector(7 downto 0);
	signal interrupt_reg : std_logic_vector(7 downto 0);
	signal interrupt_en_reg : std_logic_vector(7 downto 0);
	
	
	signal prescaler_tick : std_logic;
	signal prescaler_count : unsigned(7 downto 0);
	signal prescaler_value : unsigned(7 downto 0);
	
	
	signal pB_tick : std_logic;
	signal pB_count : unsigned(15 downto 0);
	signal pB_value : unsigned(15 downto 0);
	signal pB_tick_en : std_logic;
	
	signal mB_tick : std_logic;
	signal mB_count : unsigned(15 downto 0);
	signal mB_value : unsigned(15 downto 0);
	signal mB_tick_en : std_logic;
	
	
	signal NoC_debug_out : std_logic_vector(7 downto 0);
	signal NoC_debug_valid_out : std_logic;
	
	signal uC_b_addr : std_logic_vector(11 downto 0);
	signal uC_b_din : std_logic_vector(17 downto 0);
	signal uC_b_dout : std_logic_vector(17 downto 0);
	signal uC_b_wr_en : std_logic;

	signal intel_noc_int_reg : std_logic;
	signal intel_noc_int_pulse : std_logic;

	

begin
	
	intel_noc_data_out <= NoC_debug_valid_out & NoC_debug_out;

	intel_bus_out <= knobs_cntrl;
	intel_node_data_out <= node_data_out;
	node_rd_req_intel <= node_rd_req_int;
	intel_router_req <= router_rd_req_int;
	
	K_clk_en <= K_clk_en_int;
	K_clk_freq <= K_clk_freq_int;
	
	MB_timer_tick <= mB_tick;
	RO_en <= '0';
	RO_conversion_en <= '0';

	RCAP_data_in <= RCAP_In_Port.data_in;
	RCAP_control_sel_in <= RCAP_In_Port.control_sel;
	RCAP_data_valid_in <= RCAP_In_Port.data_valid;
	RCAP_Out_Port.rd_en     <= RCAP_rd_en_out;
	
	RCAP_Out_Port.data_out     <= RCAP_data_out;
	RCAP_Out_Port.control_sel     <= RCAP_control_sel_out;
	RCAP_Out_Port.data_valid     <= RCAP_data_valid_out;	
	RCAP_rd_en_in <= RCAP_In_Port.rd_en;

	

intel_picoblaze_BRAM : entity centurion.picoblaze_BRAM    
    generic map(
        ROM_FILE => "intel.mem"
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

 intel_picoblaze: entity centurion.kcpsm6
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
                 interrupt => uC_interrupt_latch,
             interrupt_ack => uC_interrupt_ack,
                     sleep => uC_kcpsm6_sleep,
                     reset => uC_kcpsm6_reset,
                       clk => clk);


 uC_kcpsm6_sleep <= '0';
 uC_kcpsm6_reset <= reset;
 uC_interrupt <= or_reduce(interrupt and interrupt_en_reg);
 
 interrupt <= 	"0" 
 			& 	"0"
 			& 	mB_tick
 			& 	pB_tick 
 			& 	intel_noc_int_pulse
 			& 	node_wr_req_intel
 			& 	router_intel_req
 			&  RCAP_data_valid_in;
 
 
 K_node_reset <= K_node_reset_int;
 Intel_req_out <= Intel_req_out_int; 
 Intel_out <= Intel_out_int;


intel_noc_int_pulse <= intel_noc_int_in and (not intel_noc_int_reg);


noc_int_sync_proc : process (clk) is
begin
	if rising_edge(clk) then
		if reset = '1' then
			intel_noc_int_reg <= '0';
		else
			intel_noc_int_reg <= intel_noc_int_in;
		end if;
	end if;
end process;
			



 --output port decode
 uC_output_sync_proc : process (clk) is
 begin
 	if rising_edge(clk) then
 		if reset = '1' then
 			K_clk_en_int <= '0';
 			K_clk_freq_int <= (others => '0');
 			knobs_cntrl <= (others => '0');
 			router_rd_req_int <= '0';
 			node_data_out <= (others => '0');
 			node_rd_req_int <= '0';
 			Intel_req_out_int <= (others => '0');
 			K_node_reset_int <= '0';

 			interrupt_en_reg <= (others => '0');
 			
 			pB_value <= (others => '0');
 			MB_value <= (others => '0');
 			prescaler_value <= (others => '0');
 			pB_tick_en <= '0';
 			mB_tick_en <= '0';
 			uC_interrupt_latch <= '0';
 			
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
 			
 			
 			
	 		if uC_write_strobe = '1' then
				case uC_port_id is
					
					when x"00" => K_node_reset_int <=  uC_out_port(0);
					when x"01" => K_clk_en_int <=  uC_out_port(0);
					when x"02" => K_clk_freq_int <=  uC_out_port(DIVIDER_COUNTER_WIDTH -1 downto 0);

					when x"04" => interrupt_en_reg  <=  uC_out_port(7 downto 0);

					when x"06" => uC_b_wr_en  <=  uC_out_port(0);

					when x"20" => knobs_cntrl(7 downto 0) <= uC_out_port(7 downto 0);
					when x"21" => knobs_cntrl(15 downto 8) <= uC_out_port(7 downto 0);
					when x"22" => router_rd_req_int <= uC_out_port(0);
						
					when x"30" => node_data_out(7 downto 0) <= uC_out_port(7 downto 0);
					when x"31" => node_rd_req_int <= uC_out_port(0);
				
					when x"60" => uC_b_addr(7 downto 0) <= uC_out_port(7 downto 0);
					when x"61" => uC_b_addr(11 downto 8) <= uC_out_port(3 downto 0);
					when x"62" => uC_b_din(7 downto 0) <= uC_out_port(7 downto 0);
					when x"63" => uC_b_din(15 downto 8) <= uC_out_port(7 downto 0);
					when x"64" => uC_b_din(17 downto 16) <= uC_out_port(1 downto 0);
						
				
					when x"70" => Intel_req_out_int <= uC_out_port(3 downto 0);
					when x"71" => Intel_out_int <= uC_out_port(7 downto 0);
			
					when x"80" => NoC_debug_out  <= uC_out_port(7 downto 0);
					when x"81" => NoC_debug_valid_out  <= uC_out_port(0);
					
					when x"90" => pB_value(7 downto 0) <= unsigned(uC_out_port(7 downto 0));
					when x"91" => pB_value(15 downto 8) <= unsigned(uC_out_port(7 downto 0));
					when x"92" => pB_tick_en <= uC_out_port(0);
					
					when x"93" => mB_value(7 downto 0) <= unsigned(uC_out_port(7 downto 0));
					when x"94" => mB_value(15 downto 8) <= unsigned(uC_out_port(7 downto 0));
					when x"95" => mB_tick_en <= uC_out_port(0);
					
					when x"96" => prescaler_value(7 downto 0) <= unsigned(uC_out_port(7 downto 0));
						
								

					when others => null;
				end case;
			end if;

			if uC_k_write_strobe = '1' then
				case uC_port_id(3 downto 0) is
					
					when x"0" => K_node_reset_int <=  uC_out_port(0);
					when x"1" => K_clk_en_int <=  uC_out_port(0);
					when x"2" => K_clk_freq_int <=  uC_out_port(DIVIDER_COUNTER_WIDTH -1 downto 0);

					when x"4" => interrupt_en_reg  <=  uC_out_port(7 downto 0);

					when x"6" => uC_b_wr_en  <=  uC_out_port(0);
					when others => null;
				end case;
			end if;

					

		end if;
 	end if;
 end process uC_output_sync_proc;



 --input port decode
 uC_input_sync_proc : process (clk) is
 begin
 	if rising_edge(clk) then
				uC_in_port <= (others => '0');
			case uC_port_id is
				when x"00" => uC_in_port(7 downto 0) <= std_logic_vector(to_unsigned(node_index, 8)); 
				when x"04" => uC_in_port(7 downto 0) <= interrupt_en_reg;
				when x"05" => uC_in_port(7 downto 0) <= interrupt_reg;
					 
				
				when x"20" => uC_in_port(7 downto 0) <= router_cntrl_bus_in(7 downto 0); -- Data to the router LSB
				when x"21" => uC_in_port(7 downto 0) <= router_cntrl_bus_in(15 downto 8);  -- Data to the router MSB

				when x"30" => uC_in_port(7 downto 0) <= intel_node_data_in(7 downto 0);
					
				when x"60" => uC_in_port(7 downto 0) <= "000000" & RCAP_control_sel_in & (RCAP_data_valid_in and RCAP_output_en);
				when x"61" => uC_in_port(7 downto 0) <= RCAP_data_in;
					
				when x"62" => uC_in_port(7 downto 0) <= uC_b_dout(7 downto 0);
				when x"63" => uC_in_port(7 downto 0) <= uC_b_dout(15 downto 8);
				when x"64" => uC_in_port(7 downto 0) <= "000000" & uC_b_dout(17 downto 16);
			
					
				--neighbouring nodes intel
				when x"70" 	=> uC_in_port(7 downto 0) <= "0000" & Intel_req_in;
				when x"71" 	=> uC_in_port(7 downto 0) <= Intel_N;
				when x"72" 	=> uC_in_port(7 downto 0) <= Intel_E;
				when x"73" 	=> uC_in_port(7 downto 0) <= Intel_S;
				when x"74" 	=> uC_in_port(7 downto 0) <= Intel_W;
				
				when x"80" => uC_in_port(7 downto 0) <= intel_noc_data_in(7 downto 0);
				when x"81" => uC_in_port(7 downto 0) <= "000000" & intel_noc_data_valid_in & intel_noc_data_in(8);
					

				when others => uC_in_port <= "XXXXXXXX";
			end case;
 	end if;
 end process uC_input_sync_proc;
 
 
 
 
 --RCAP interface
 RCAP_EOP_detect <= '1' when RCAP_rd_en_out = '1' and RCAP_control_sel_in = '1' and RCAP_data_in = x"7F" else '0';

RCAP_sync_proc : process (clk) is
 begin
 	if rising_edge(clk) then
 		if reset = '1' then
 			RCAP_rd_en_out <= '0';
 		else
 			if RCAP_data_valid_in = '1' and ((uC_port_id = x"61" and uC_read_strobe = '1') or RCAP_output_en = '0') then
 				RCAP_rd_en_out <= '1';
 		    else
 		    	RCAP_rd_en_out <= '0';
 		    end if;		
 		
 		end if;	
 		 
 		
 	end if;
 end process RCAP_sync_proc;
 
 
 prescaler_tick <= '1' when prescaler_count = 0 else '0';
 pB_tick <= '1' when pB_count = 0 and pB_tick_en = '1' else '0';
 mB_tick <= '1' when mB_count = 0 and mB_tick_en = '1' else '0';
 
 --timebases
 timebase_proc : process (clk) is
 begin
 	if rising_edge(clk) then
 		if reset = '1' then
			pB_count <= (others => '0');
			mB_count <= (others => '0');
			prescaler_count <= (others => '0');
		else
			if prescaler_count = 0 then
				prescaler_count <= prescaler_value;
			else
				prescaler_count <= prescaler_count - 1;
			end if;
			
			
			if pB_count = 0 or pB_tick_en = '0' then
				pB_count <= pB_value;
			else
				if pB_tick_en = '1' and prescaler_tick = '1' then
					pB_count <= pB_count - 1;
				end if;
			end if;
			
			if mB_count = 0 or mB_tick_en = '0' then
				mB_count <= mB_value;
			else
				if mB_tick_en = '1' and prescaler_tick = '1' then
					mB_count <= mB_count - 1;
				end if;
			end if;
 			
 		end if;
 	end if;
 end process timebase_proc;
 


end architecture RTL;

