-------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;



entity noc_if_axi is
	generic(
		-- ADD USER GENERICS BELOW THIS LINE ---------------
		NOC_NUM_NODES_LOG2 : integer := 6;
		-- ADD USER GENERICS ABOVE THIS LINE ---------------
		RAM_DEPTH              : integer := 2048;
		BUFF_SIZE_bytes        : integer := 2048 * 4;
		BUFF_SIZE_bytes_log2   : integer := log2((2048 * 4) - 1);
		-- DO NOT EDIT BELOW THIS LINE ---------------------
		-- Bus protocol parameters, do not add to or delete
		C_S_AXI_MEM0_BASEADDR  : std_logic_vector(31 downto 0) := x"90000000";
		C_S_AXI_MEM0_HighADDR  : std_logic_vector(31 downto 0) := x"9FFFFFFF";
		C_S_AXI_DATA_WIDTH     : integer := 32;
		C_S_AXI_ADDR_WIDTH     : integer := 32;
		C_S_AXI_ID_WIDTH       : integer := 4;
		C_RDATA_FIFO_DEPTH     : integer := 0;
		C_INCLUDE_TIMEOUT_CNT  : integer := 0;
		C_TIMEOUT_CNTR_VAL     : integer := 8;
		C_ALIGN_BE_RDADDR      : integer := 0;
		C_S_AXI_SUPPORTS_WRITE : integer := 1;
		C_S_AXI_SUPPORTS_READ  : integer := 1;
		C_FAMILY               : string  := "virtex6";
		NUM_INTERFACES         : integer := 10
	-- DO NOT EDIT ABOVE THIS LINE ---------------------
	);
	port(
		-- ADD USER PORTS BELOW THIS LINE ------------------
		--USER ports added here

		NoC_Out_Port  : out  router_in_port;
		NoC_in_Port : in router_out_port;
		NoC_reset : out std_logic;
		MCS_glbl_reset : out std_logic;
		--RTC
		RTC_value : out std_logic_vector(31 downto 0);
		
		--Node debug interface
		Debug_Node_sel : out std_logic_vector(NOC_NUM_NODES_LOG2-1 downto 0);
		Debug_Node_src_sel : out std_logic_vector(1 downto 0);
		Debug_Node_UART_sel : out std_logic_vector(NOC_NUM_NODES_LOG2-1 downto 0);
				
		Debug_Node_debug_value : in std_logic_vector(8 downto 0);
		Debug_command_out : out std_logic_vector(8 downto 0);
		Debug_command_valid : out std_logic;
	
		Debug_HS_download_en : out std_logic;
		Debug_HS_upload_en : out std_logic;
		
		IRQ : out std_logic;

		-- ADD USER PORTS ABOVE THIS LINE ------------------

		-- DO NOT EDIT BELOW THIS LINE ---------------------
		-- Bus protocol ports, do not add to or delete
		S_AXI_ACLK           : in  std_logic;
		S_AXI_ARESETN        : in  std_logic;
		S_AXI_AWADDR         : in  std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
		S_AXI_AWVALID        : in  std_logic;
		S_AXI_WDATA          : in  std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
		S_AXI_WSTRB          : in  std_logic_vector((C_S_AXI_DATA_WIDTH / 8) - 1 downto 0);
		S_AXI_WVALID         : in  std_logic;
		S_AXI_BREADY         : in  std_logic;
		S_AXI_ARADDR         : in  std_logic_vector(C_S_AXI_ADDR_WIDTH - 1 downto 0);
		S_AXI_ARVALID        : in  std_logic;
		S_AXI_RREADY         : in  std_logic;
		S_AXI_ARREADY        : out std_logic;
		S_AXI_RDATA          : out std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
		S_AXI_RRESP          : out std_logic_vector(1 downto 0);
		S_AXI_RVALID         : out std_logic;
		S_AXI_WREADY         : out std_logic;
		S_AXI_BRESP          : out std_logic_vector(1 downto 0);
		S_AXI_BVALID         : out std_logic;
		S_AXI_AWREADY        : out std_logic;
		S_AXI_AWID           : in  std_logic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);
		S_AXI_AWLEN          : in  std_logic_vector(7 downto 0);
		S_AXI_AWSIZE         : in  std_logic_vector(2 downto 0);
		S_AXI_AWBURST        : in  std_logic_vector(1 downto 0);
		S_AXI_AWLOCK         : in  std_logic;
		S_AXI_AWCACHE        : in  std_logic_vector(3 downto 0);
		S_AXI_AWPROT         : in  std_logic_vector(2 downto 0);
		S_AXI_WLAST          : in  std_logic;
		S_AXI_BID            : out std_logic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);
		S_AXI_ARID           : in  std_logic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);
		S_AXI_ARLEN          : in  std_logic_vector(7 downto 0);
		S_AXI_ARSIZE         : in  std_logic_vector(2 downto 0);
		S_AXI_ARBURST        : in  std_logic_vector(1 downto 0);
		S_AXI_ARLOCK         : in  std_logic;
		S_AXI_ARCACHE        : in  std_logic_vector(3 downto 0);
		S_AXI_ARPROT         : in  std_logic_vector(2 downto 0);
		S_AXI_RID            : out std_logic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);
		S_AXI_RLAST          : out std_logic
	-- DO NOT EDIT ABOVE THIS LINE ---------------------
	);

	attribute MAX_FANOUT : string;
	attribute SIGIS : string;
	attribute MAX_FANOUT of S_AXI_ACLK : signal is "10000";
	attribute MAX_FANOUT of S_AXI_ARESETN : signal is "10000";
	attribute SIGIS of S_AXI_ACLK : signal is "Clk";
	attribute SIGIS of S_AXI_ARESETN : signal is "Rst";
end entity noc_if_axi;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of noc_if_axi is
	
	signal reset : std_logic;

	type NoC_if_contrl is record
		TX_start  : std_logic;
		TX_length : unsigned(BUFF_SIZE_bytes_log2 - 1 downto 0);
		RX_ack    : std_logic;
	end record NoC_if_contrl;

	type NoC_if_status is record
		TX_busy : std_logic;
		RX_done   : std_logic;
		RX_length : unsigned(BUFF_SIZE_bytes_log2 - 1 downto 0);
	end record NoC_if_status;

	signal if_cntrl : NoC_if_contrl;
	signal if_status : NoC_if_status;

	type axi_wr_states is (Idle, Write_single, Write_Burst, Write_done);
	signal axi_wr_state      : axi_wr_states;
	signal axi_wr_state_next : axi_wr_states;

	type axi_rd_states is (Idle, Read_single, Read_Burst, Read_reg, Read_done);
	signal axi_rd_state      : axi_rd_states;
	signal axi_rd_state_next : axi_rd_states;

	constant num_regs : integer := 13;

	type reg_file is array (num_regs - 1 downto 0) of std_logic_vector(31 downto 0);
	signal regs : reg_file;

	signal cntrl_reg  : std_logic_vector(31 downto 0);
	signal status_reg : std_logic_vector(31 downto 0);

	signal axi_reg_wr   : std_logic;
	signal axi_reg_rd   : std_logic;
	signal reg_wr_sel   : std_logic_vector(num_regs - 1 downto 0);
	signal reg_rd_sel   : std_logic_vector(num_regs - 1 downto 0);
	signal reg_index_wr : unsigned(log2(num_regs - 1) - 1 downto 0);
	signal reg_index_rd : unsigned(log2(num_regs - 1) - 1 downto 0);

	signal axi_tx_burst_len : unsigned(7 downto 0);
	signal axi_rx_burst_len : unsigned(7 downto 0);
	
	signal if_rd_data : std_logic_vector(35 downto 0);

	signal wr_en : std_logic_vector(3 downto 0);
	
	signal if_rd_index : unsigned(3 downto 0);
	signal if_wr_index : unsigned(3 downto 0);
	
	signal NoC_Reset_int : std_logic;
	
	signal wr_buff_addr : std_logic_vector(BUFF_SIZE_bytes_log2-1 downto 0);
	signal rd_buff_addr : std_logic_vector(BUFF_SIZE_bytes_log2-1 downto 0);
	
	signal wr_data : std_logic_vector(35 downto 0);
	signal single_wr_data : std_logic_vector(35 downto 0);
	signal rd_index : unsigned(1 downto 0);
	signal rd_data : std_logic_vector(35 downto 0);
	signal single_rd_data : std_logic_vector(31 downto 0);
	
	signal IRQ_reg : std_logic;
	signal IRQ_TX_busy_reg : std_logic;
	signal IRQ_RX_done_reg : std_logic;
	
	signal RTC_reset : std_logic;
	signal RTC_count : unsigned(31 downto 0);
	signal RTC_scaler : unsigned(31 downto 0);
	signal RTC_scaler_value : unsigned(31 downto 0);
	
	signal node_sel : std_logic_vector(NOC_NUM_NODES_LOG2-1 downto 0) :=  (others => '0');
	signal debug_src_sel : std_logic_vector(1 downto 0) :=  (others => '0');
	signal node_uart_sel : std_logic_vector(NOC_NUM_NODES_LOG2-1 downto 0) :=  (others => '0');
	signal debug_node_data : std_logic_vector(31 downto 0);
	signal command_out : std_logic_vector(8 downto 0);
	signal command_valid : std_logic;
	
	
	constant HS_BUFF_SIZE_WORDS : integer := 1024;
	signal HS_buff_addr      : unsigned(11 downto 0);
	signal HS_buff_wr_en : std_logic;
	type Hi_Speed_FSM_states is (idle, setup0, setup1, setup2, setup3, setup4, setup5, setup6, setup7, setup8, download);
	signal HS_fsm_state : Hi_Speed_FSM_states;
	signal HS_download_count      : unsigned(11 downto 0);
	signal HS_download_len      : unsigned(11 downto 0);
	signal HS_download_en_int  : std_logic;
	signal HS_upload_en_int  : std_logic;
	signal debug_HS_rd : std_logic_vector(31 downto 0);
	
begin
	NoC_Reset <= cntrl_reg(0) or reset;
	NoC_Reset_int <= cntrl_reg(0) or reset;
	RTC_reset <= cntrl_reg(1);
	MCS_glbl_reset <= cntrl_reg(2);
	reset <= not S_AXI_ARESETN;
	IRQ <= IRQ_reg;
	 
	Debug_Node_src_sel <= Debug_src_sel;

	reg_index_wr <= unsigned(S_AXI_AWADDR(log2(num_regs - 1) - 1 + 2 downto 2));
	reg_index_rd <= unsigned(S_AXI_ARADDR(log2(num_regs - 1) - 1 + 2 downto 2));
	reg_en_gen : for i in 0 to NUM_REGS - 1 generate
		reg_wr_sel(i) <= '1' when axi_reg_wr = '1' and S_AXI_WVALID = '1' and  axi_wr_state = Write_single and reg_index_wr = to_unsigned(i, log2(NUM_REGS)) else '0';
		reg_rd_sel(i) <= '1' when axi_reg_rd = '1' and S_AXI_RREADY = '1' and reg_index_rd = to_unsigned(i, log2(NUM_REGS)) else '0';
	end generate reg_en_gen;

	if_wr_index <= unsigned(S_AXI_AWADDR(19 downto 16));
	if_rd_index <= unsigned(S_AXI_ARADDR(19 downto 16));
	wr_buff_addr <= S_AXI_AWADDR(BUFF_SIZE_bytes_log2-1 + 2 downto 2);
	rd_buff_addr <= S_AXI_ARADDR(BUFF_SIZE_bytes_log2-1 + 2 downto 2);

	regs(0) <= cntrl_reg;
	regs(1) <= std_logic_vector(resize(unsigned(status_reg), 32));
	regs(2) <= std_logic_vector(resize(unsigned'("" & (if_cntrl.RX_ack) & (if_cntrl.TX_start)), 32));
	regs(3) <= std_logic_vector(resize(unsigned'("" & if_status.TX_busy & if_status.RX_done), 32));
	regs(4) <= std_logic_vector(resize(unsigned(if_cntrl.TX_length), 32));
	regs(5) <= std_logic_vector(resize(unsigned(if_status.RX_length), 32));
	regs(6) <= std_logic_vector(RTC_count);
	regs(10) <= debug_node_data;

	--IRQ generation
	IRQ_proc : process (S_AXI_ACLK) is
	begin
		if rising_edge(S_AXI_ACLK) then
			if reset = '1' then
				IRQ_reg <= '0';
			else
				IRQ_reg <= '0';
					if (IRQ_TX_busy_reg = '1' and if_status.TX_busy = '0') or (IRQ_RX_done_reg = '0' and if_status.RX_done = '1') then
						IRQ_reg <= '1';
					end if;
					IRQ_TX_busy_reg <= if_status.TX_busy;
					IRQ_RX_done_reg <= if_status.RX_done;
				
				
				
			end if;
		end if;
	end process IRQ_proc;
	
	

	wr_en <=	"0001" when S_AXI_AWADDR(3 downto 2) = "00" and axi_wr_state = Write_single and S_AXI_AWADDR(19 downto 16) = x"1" else
				"0010" when	S_AXI_AWADDR(3 downto 2) = "01" and axi_wr_state = Write_single and S_AXI_AWADDR(19 downto 16) = x"1" else
				"0100" when	S_AXI_AWADDR(3 downto 2) = "10" and axi_wr_state = Write_single and S_AXI_AWADDR(19 downto 16) = x"1" else
				"1000" when	S_AXI_AWADDR(3 downto 2) = "11" and axi_wr_state = Write_single and S_AXI_AWADDR(19 downto 16) = x"1" else
				"1111" when	axi_wr_state = Write_Burst else
				"0000";
	
	
	
		noc_if_inst : entity centurion.noc_if
			generic map(
				RAM_DEPTH            => RAM_DEPTH,
				BUFF_SIZE_bytes      => BUFF_SIZE_bytes,
				BUFF_SIZE_bytes_log2 => BUFF_SIZE_bytes_log2
			)
			port map(
				MB_clk         => S_AXI_ACLK,
				NoC_clk        => S_AXI_ACLK,
				reset          => NoC_Reset_int,
				wr_addr        => wr_buff_addr,
				data_in        => wr_data,
				wr_en          => wr_en,
				rd_addr        => rd_buff_addr,
				data_out       => if_rd_data,
				rd_burst_sel   => '0',
				MB_TX_start    => if_cntrl.TX_start,
				MB_TX_len      => if_cntrl.TX_length,
				MB_RX_Ack      => if_cntrl.RX_ack,
				TX_busy        => if_status.TX_busy,
				RX_done        => if_status.RX_done,
				RX_length      => if_status.RX_length,
				NoC_In_Port    => NoC_In_Port,
				NoC_Out_Port   => NoC_Out_Port
	);


	axi_reg_wr       <= '1' when S_AXI_AWADDR(19 downto 16) = x"0" else '0';
	axi_tx_burst_len <= unsigned(S_AXI_AWLEN);
	S_AXI_AWREADY    <= '1' when axi_wr_state = idle else '0';
	S_AXI_BRESP      <= "00";
	S_AXI_BVALID     <= '1' when axi_wr_state = Write_done else '0';
	S_AXI_WREADY     <= '1' when axi_wr_state = Write_single else '0';
	single_wr_data   <=	"000000000" & "000000000" & "000000000" & S_AXI_WDATA(8 downto 0)	when S_AXI_AWADDR(3 downto 2) = "00" else
						"000000000" & "000000000" & S_AXI_WDATA(8 downto 0) & "000000000" 	when S_AXI_AWADDR(3 downto 2) = "01" else
						"000000000" & S_AXI_WDATA(8 downto 0) & "000000000" & "000000000" 	when S_AXI_AWADDR(3 downto 2) = "10" else
						S_AXI_WDATA(8 downto 0) & "000000000" & "000000000" & "000000000"	when S_AXI_AWADDR(3 downto 2) = "11" else
						(others => '0');
				
	wr_data 		 <= single_wr_data when axi_tx_burst_len = 0 else
						'0' & S_AXI_WDATA(31 downto 24) & '0' & S_AXI_WDATA(23 downto 16) 	
						& '0' & S_AXI_WDATA(15 downto 8) & '0' & S_AXI_WDATA(7 downto 0); 
	
	wr_state_proc : process(S_AXI_AWVALID, S_AXI_WLAST, S_AXI_WVALID, axi_tx_burst_len, axi_wr_state, S_AXI_BREADY) is
	begin
		axi_wr_state_next <= axi_wr_state;
		case axi_wr_state is
			when Idle =>
				if S_AXI_AWVALID = '1' then
					if axi_tx_burst_len = 0 then
						axi_wr_state_next <= Write_single;
					else
						axi_wr_state_next <= Write_burst;
					end if;
				end if;

			when Write_single =>
				if S_AXI_WVALID = '1' then
					axi_wr_state_next <= Write_done;
				end if;
			when Write_Burst =>
				if S_AXI_WLAST = '1' and S_AXI_WVALID = '1' then
					axi_wr_state_next <= Write_done;
				end if;
			when Write_done =>
				if S_AXI_BREADY = '1' then
					axi_wr_state_next <= idle;
				end if;
		end case;
	end process wr_state_proc;

	wr_sync_proc : process(S_AXI_ACLK) is
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				cntrl_reg    <= (others => '0');
				axi_wr_state <= idle;
		
				if_cntrl.RX_ack    <= '0';
				if_cntrl.TX_start  <= '0';
				if_cntrl.TX_length <= (others => '0');
				RTC_scaler_value  <= (others => '0');
				node_sel <= (others => '0');
				node_UART_sel <= (others => '0');
				command_out <= (others => '0');
				command_valid <= '0';
				HS_download_len <= (others => '0');
				debug_src_sel <= "00";
				
			else
						
                if NoC_Reset_int = '1' then
                    if_cntrl.RX_ack    <= '0';
				    if_cntrl.TX_start  <= '0';
				    if_cntrl.TX_length <= (others => '0');
				    HS_download_len <= (others => '0');
                end if;
			
			
				axi_wr_state <= axi_wr_state_next;

				if reg_wr_sel(0) = '1' then
					cntrl_reg <= S_AXI_WDATA;
				end if;
				
				if reg_wr_sel(2) = '1' then
					if_cntrl.RX_ack   <= S_AXI_WDATA(1);
					if_cntrl.TX_start <= S_AXI_WDATA(0);
				end if;
				if reg_wr_sel(4) = '1' then
					if_cntrl.TX_length <= unsigned(S_AXI_WDATA(BUFF_SIZE_bytes_log2 - 1 downto 0));
				end if;
				
				if reg_wr_sel(6) = '1' then
					RTC_scaler_value <= unsigned(S_AXI_WDATA(31 downto 0));
				end if;

				
				if reg_wr_sel(7) = '1' then
					node_UART_sel <= S_AXI_WDATA(NOC_NUM_NODES_LOG2-1 downto 0);
				end if;
				if reg_wr_sel(8) = '1' then
					node_sel <= S_AXI_WDATA(NOC_NUM_NODES_LOG2-1 downto 0);
				end if;
				
				if reg_wr_sel(9) = '1' then
					debug_src_sel <= S_AXI_WDATA(1 downto 0);
				end if;
				
				if reg_wr_sel(10) = '1' then
					command_out <= S_AXI_WDATA(8 downto 0);
				end if;
				if reg_wr_sel(11) = '1' then
					command_valid <= S_AXI_WDATA(0);
				end if;
				if reg_wr_sel(12) = '1' then
					HS_download_len <= unsigned(S_AXI_WDATA(11 downto 0));
				end if;

				if HS_fsm_state = download then
					HS_download_len <= (others => '0');
				end if;
				
				
			end if;
		end if;
	end process wr_sync_proc;

	axi_reg_rd       <= '1' when S_AXI_ARADDR(19 downto 16) = x"0" else '0';
	axi_rx_burst_len <= unsigned(S_AXI_ARLEN);
	S_AXI_ARREADY    <= '1' when axi_rd_state = idle else '0';
	S_AXI_RVALID     <= '1' when axi_rd_state = Read_single or axi_rd_state = Read_burst or axi_rd_state = Read_reg else '0';

	rd_data		<= if_rd_data when axi_rd_state = Read_single else
					(others => '0'); 
					
	single_rd_data <= 	std_logic_vector(resize(unsigned(rd_data(8 downto 0)),32)) when S_AXI_ARADDR(3 downto 2) = "00" else
						std_logic_vector(resize(unsigned(rd_data(17 downto 9)),32)) when S_AXI_ARADDR(3 downto 2) = "01" else
						std_logic_vector(resize(unsigned(rd_data(26 downto 18)),32)) when S_AXI_ARADDR(3 downto 2) = "10" else
						std_logic_vector(resize(unsigned(rd_data(35 downto 27)),32)) when S_AXI_ARADDR(3 downto 2) = "11" else
						(others => '0');
						
	
	
	S_AXI_RDATA <= 	regs(to_integer(reg_index_rd)) when axi_rd_state = Read_reg else
					debug_HS_rd when axi_rd_state = Read_single and if_rd_index = x"2" else
					single_rd_data when axi_rd_state = Read_single else
					(others => '0'); 
	S_AXI_RLAST        <= '1' when axi_rd_state = Read_single or axi_rd_state = Read_reg  else '0';

	rd_state_proc : process(S_AXI_ARVALID, S_AXI_RREADY, axi_rd_state, axi_reg_rd, axi_rx_burst_len) is
	begin
		axi_rd_state_next <= axi_rd_state;
		case axi_rd_state is
			when Idle =>
				if S_AXI_ARVALID = '1' then
					if axi_reg_rd = '1' then
						axi_rd_state_next <= Read_reg;
					elsif axi_Rx_burst_len = 0 then
						axi_rd_state_next <= Read_single;
					else
						axi_rd_state_next <= Read_burst;
					end if;
				end if;

			when Read_single =>
				if S_AXI_RREADY = '1' then
					axi_rd_state_next <= Read_done;
				end if;
			when Read_Burst =>
				--TODO: slave needs to drive RLAST
				--if S_AXI_RLAST = '1' and S_AXI_RREADY = '1' then
				axi_rd_state_next <= Read_done;
			--end if;
			when Read_reg =>
				if S_AXI_RREADY = '1' then
					axi_rd_state_next <= Read_done;
				end if;
			when Read_done =>
				axi_rd_state_next <= idle;
		end case;
	end process rd_state_proc;

	rd_sync_proc : process(S_AXI_ACLK) is
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				axi_rd_state <= idle;
			else
				axi_rd_state <= axi_rd_state_next;
			end if;
		end if;
	end process rd_sync_proc;
	
	
	
		S_AXI_RRESP         <= "00";
		S_AXI_BID           <= S_AXI_AWID;
		S_AXI_RID            <= S_AXI_ARID;
		
		

RTC_value <= std_logic_vector(RTC_count);
	
RTC_timers_proc : process(S_AXI_ACLK) is
begin
	if rising_edge(S_AXI_ACLK) then
		if S_AXI_ARESETN = '0' then 
			RTC_count <= (others => '0');
			RTC_scaler <= (others => '1');
		else
			if RTC_reset = '1' then
				RTC_count <= (others => '0');
				RTC_scaler <= RTC_scaler_value;
			elsif RTC_scaler = 0 then
				RTC_scaler <= RTC_scaler_value;
				RTC_count <= RTC_count + 1;
			else
				RTC_scaler <= RTC_scaler - 1;
			end if;

			
		end if;
	end if;
end process;



--Node debug interface
Debug_Node_sel <= node_sel;
Debug_Node_UART_sel <= node_uart_sel;
		
Debug_command_out <= command_out;
Debug_command_valid <= command_valid;

Debug_HS_download_en <= HS_download_en_int;
Debug_HS_upload_en <= '0';

HS_buff_wr_en <= '1' when HS_fsm_state = download else '0';
HS_download_en_int <= '0' when HS_fsm_state = idle else '1';





 debug_reg_proc : process(S_AXI_ACLK) is
  begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then 
				debug_node_data <= (others => '0');
			else
				debug_node_data(8 downto 0) <= Debug_Node_debug_value;
				debug_node_data(14 downto 9) <= (others => '0');
				debug_node_data(15) <= HS_download_en_int;
			end if;
		end if;
	end process;

	
	Hi_speed_download_proc: process (S_AXI_ACLK) is
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				HS_fsm_state <= Idle;
				HS_download_count <= (others => '0');
			else
				case HS_fsm_state is 
					when idle =>
						HS_buff_addr <= (others => '0');
					
						--wait for rising edge on download select
						if reg_wr_sel(12) = '1' then
							HS_fsm_state <= setup0;
						end if;
					when setup0 =>
							HS_download_count <= HS_download_len;
							HS_fsm_state <= setup1;
					when setup1 =>
							HS_fsm_state <= setup2;
					when setup2 =>
							HS_fsm_state <= setup3;
					when setup3 =>
							HS_fsm_state <= setup4;
					when setup4 =>
							HS_fsm_state <= setup5;
					when setup5 =>
							HS_fsm_state <= setup6;
					when setup6 =>
							HS_fsm_state <= setup7;
					when setup7 =>
							HS_fsm_state <= setup8;
					when setup8 =>
							HS_fsm_state <= download;

					when download =>
						HS_download_count <= HS_download_count - 1;
						HS_buff_addr <= HS_buff_addr + 1;
						if HS_download_count = 0 then
							HS_fsm_state <= idle;
						end if;
				end case;
			end if;
		end if;
	end process Hi_speed_download_proc;

				
	HS_data_buffer : entity centurion.dual_port_RAM_asymmetric_A32RW_B8W

		port map(
			clkA  => S_AXI_ACLK,
			enA   => '1',
			weA   => "0000",
			addrA => S_AXI_ARADDR(11 downto 2),
			diA   => x"00000000",
			doA   => debug_HS_rd,
			
			clkB  => S_AXI_ACLK,
			weB  => HS_buff_wr_en,
			addrB => std_logic_vector(HS_buff_addr),
			diB   => Debug_Node_debug_value(7 downto 0)
		);
	
	
end IMP;

