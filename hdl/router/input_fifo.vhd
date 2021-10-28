library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;

entity input_fifo is
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
		data_out : out std_logic_vector(ROUTER_DATA_WIDTH-1 downto 0);
		control_sel_out : out std_logic;
		data_valid_out : out std_logic;
		--output response
		rd_en_in : in std_logic;

		channel_in_use : in std_logic;
		
		SOP_detected : out std_logic;
		current_packet_id : out unsigned(PACKET_ID_LENGTH-1 downto 0);
		
		timer_tick : in std_logic;
		timer_threshold : in unsigned(TIMER_WIDTH -1 downto 0);
		deadlock_timer_expire : out std_logic;
		deadlock_timeout_clear : in std_logic
		
		
	);
end entity input_fifo;

architecture RTL of input_fifo is
	constant depth_local_clk : integer := 3;
	
	
	type input_bundle is array(integer range <>) of std_logic_vector(ROUTER_DATA_WIDTH downto 0);
	signal regs : input_bundle(0 to depth_local_clk-1);
	signal reg_valid : std_logic_vector(depth_local_clk-1 downto 0);
	signal rd_en_out_reg : std_logic;
	
	signal packet_id_reg : unsigned(PACKET_ID_LENGTH-1 downto 0);
	signal packet_id : unsigned(PACKET_ID_LENGTH-1 downto 0);
	signal SOP_detect : std_logic;
	signal EOP_detect : std_logic;
	signal channel_close_hold : std_logic;
	
	signal timer_reg : unsigned(TIMER_WIDTH -1 downto 0);
	signal timer_expire : std_logic;
	
begin
  
 	deadlock_timer_expire <= timer_expire;
	
	regs(0)(ROUTER_DATA_WIDTH-1 downto 0) <= data_in;	
	regs(0)(ROUTER_DATA_WIDTH) <= control_sel_in;	
	data_out <= regs(2)(ROUTER_DATA_WIDTH-1 downto 0);
	control_sel_out <= regs(2)(ROUTER_DATA_WIDTH);
		
	reg_valid(0) <= data_valid_in;
	data_valid_out <= reg_valid(2) when channel_close_hold = '0' else '0';
	rd_en_out <= rd_en_out_reg;
	
	packet_id <= unsigned(regs(1)(ROUTER_DATA_WIDTH -1 downto 0)) & unsigned(regs(0)(ROUTER_DATA_WIDTH -1 downto 0)); 
	current_packet_id <= packet_id_reg;
	
	
	SOP_detect <= '1' when regs(2)(ROUTER_DATA_WIDTH) = '1' and reg_valid(2) = '1' and reg_valid(1) = '1' and reg_valid(0) = '1' and rd_en_out_reg = '0' 
								and regs(2)(ROUTER_SOP_INDEX) = '1' else '0';
	--detect when EOP is read by output port
	EOP_detect <= '1' when regs(2)(ROUTER_DATA_WIDTH) = '1' and reg_valid(2) = '1' and rd_en_in = '1' 
								and regs(2)(ROUTER_DATA_WIDTH-1 downto 0) = ROUTER_EOP_PACKET else '0';	
			
	SOP_detected <= SOP_detect;	
	
	
	

sync_proc : process (clk) is
begin
	if rising_edge(clk) then
		if rst = '1' then
			--regs(1) <= (others => '0'); 		
		--	regs(2) <= (others => '0'); 
			reg_valid(1) <= '0'; 
			reg_valid(2) <= '0';
		--	packet_id_reg <= (others => '0'); 
			rd_en_out_reg <= '0';
			channel_close_hold <= '0';
		else
			--hold channel until router controller has released it
			if EOP_detect = '1' and channel_in_use = '1' then
				channel_close_hold <= '1';
			end if;
			if channel_close_hold = '1' and channel_in_use = '0' then
				channel_close_hold <= '0';
			end if;


			if reg_valid(0) = '1' and reg_valid(1) = '0' then
				regs(1)	<= regs(0);
				reg_valid(1) <= '1';
				rd_en_out_reg <= '1';
			else
				rd_en_out_reg <= '0';
			end if;
			
			if reg_valid(1) = '1' and reg_valid(2) = '0' then
				regs(2)	<= regs(1);
				reg_valid(2) <= '1';
				reg_valid(1) <= '0';
			end if;
			
			if reg_valid(2) = '1' and rd_en_in = '1' then
				reg_valid(2) <= '0';
			end if;
			
			if SOP_detect = '1' then 
				packet_id_reg <= packet_id;
			end if;
			
		end if;
	end if;
end process sync_proc;


--timer monitor
timer_expire <= '1' when timer_reg = timer_threshold else '0';

timer_proc : process (clk) is
begin
	if rising_edge(clk) then
		if rst = '1' then
			--timer_reg <= (others => '0'); 	
		else
			if SOP_detect = '1' and deadlock_timeout_clear  = '0' then
				if timer_expire = '0' and  timer_tick = '1' then
					timer_reg <= timer_reg + 1;
				end if;	
			else
				timer_reg <= (others => '0'); 	
			end if;
		
		end if;
	end if;
end process timer_proc;

end architecture RTL;

