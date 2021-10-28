library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;

entity output_port_reg is
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
		Output_Port_Skip : in std_logic;
		data_out : out std_logic_vector(ROUTER_DATA_WIDTH-1 downto 0);
		control_sel_out : out std_logic;
		data_valid_out : out std_logic;
		--output response
		rd_en_in : in std_logic;
		
		EOP_Detect_out : out std_logic
					
		
	);
end entity output_port_reg;

architecture RTL of output_port_reg is
	signal data_reg :std_logic_vector(ROUTER_DATA_WIDTH-1 downto 0);
	signal control_sel_reg : std_logic;
	signal rd_en_int : std_logic;
	
	type reg_state is (load, hold, skip);
	signal state : reg_state;
	signal next_state : reg_state;
	
	signal skip_latch : std_logic;
	signal skip_req : std_logic;
	
begin
	
	
	data_valid_out <= '1' when state = hold else '0';
	rd_en_out <= rd_en_int;  
	data_out <= data_reg;
	control_sel_out <= control_sel_reg;
	
	EOP_Detect_out <= '1' when state = hold and rd_en_in = '1' and control_sel_reg = '1' and data_reg = ROUTER_EOP_PACKET
					else '0';

	
rd_en_proc : process (clk) is
begin
	if rising_edge(clk) then
		if rst = '1' then
			rd_en_int <= '0';	
		else
			if (data_valid_in = '1' and state = load and rd_en_int = '0') or state = skip then
				rd_en_int <= '1';
			else 
				rd_en_int <= '0';
			end if; 
		end if;
	end if;
end process;

reg_proc : process (clk) is
begin
	if rising_edge(clk) then
		if rst = '1' then
			skip_latch <= '0';
			skip_req <= '0';
		else
			skip_latch <= Output_Port_Skip;			
			if Output_Port_Skip = '1' and skip_latch = '0' then
				skip_req <= '1';
			end if;
			
			if state = skip then
				skip_req <= '0';
			end if;
			
			if data_valid_in = '1' and state = load and output_en = '1' then
				data_reg <= data_in;
				control_sel_reg <= control_sel_in;
			else
				data_reg <= data_reg;
				control_sel_reg <= control_sel_reg;
			end if;
					 
		end if;
	end if;
end process reg_proc;

state_comb_proc : process(state, data_valid_in, rd_en_in, output_en) is
begin
	next_state <= state; 
	case state is 
	when load =>
		if data_valid_in = '1' and output_en = '1' and skip_req = '1' then
			next_state <= skip;
		elsif data_valid_in = '1' and output_en = '1' then
			next_state <= hold;
		end if;
		
	when hold =>
		if rd_en_in = '1' then
			next_state <= load;
		end if;
	when skip =>
		next_state <= load;
			
	end case;
end process state_comb_proc;



state_sync_proc : process (clk) is
begin
	if rising_edge(clk) then
		if rst = '1' then
			state <= load;
		else
			state <= next_state;
		end if;
	end if;
end process state_sync_proc;


end architecture RTL;
