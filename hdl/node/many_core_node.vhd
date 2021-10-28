library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

library xil_defaultlib;

library centurion;
use centurion.centurion_pkg.all;

entity many_core_node is
	generic(
		BUFF_DEPTH : integer := 4096;
		node_index : integer := 0
	);
	port(
		MCS_Clk                 : IN  STD_LOGIC;
		NoC_Clk                 : in  std_logic;
		NoC_Reset               : IN  STD_LOGIC;
		MCS_reset               : in  std_logic;
		tick_in				    : in  std_logic;  
		Node_In_Port            : in  router_out_port;
		Node_Out_Port           : out router_in_port;
		RTC_in                  : in  std_logic_vector(31 downto 0);
		debug_out               : OUT STD_LOGIC_vector(8 downto 0);
		debug_in                : in  STD_LOGIC_vector(8 downto 0);
		debug_in_valid          : in  STD_LOGIC;
		Hi_Speed_Upload_en    : in  std_logic;
		Hi_Speed_Download_en    : in  std_logic;
		
		UART_out : out std_logic;
		
		node_rd_req_router : in std_logic;
		node_rd_req_intel : in std_logic;
		router_data_in : in std_logic_vector(15 downto 0);
		intel_data_in : in std_logic_vector(7 downto 0);
		
		node_wr_req_intel : out std_logic;
		node_wr_req_router : out std_logic;
		router_data_out : out std_logic_vector(7 downto 0);
		intel_data_out : out std_logic_vector(7 downto 0)
	
	);
end many_core_node;

architecture Behavioral of many_core_node is
--	COMPONENT centurion_node
--		PORT(
--			Clk : IN STD_LOGIC;
--			 Reset : IN STD_LOGIC;
--			 IO_Addr_Strobe : OUT STD_LOGIC;
--			 IO_Read_Strobe : OUT STD_LOGIC;
--			 IO_Write_Strobe : OUT STD_LOGIC;
--			 IO_Address : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--			 IO_Byte_Enable : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--			 IO_Write_Data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--			 IO_Read_Data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--			 IO_Ready : IN STD_LOGIC;
--			 UART_Tx : OUT STD_LOGIC;
	--		 GPO1 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
--			 GPI1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--			
--			 GPI2 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
	--		 INTC_Interrupt : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
 -- );

	--END COMPONENT;
	
	constant BUFF_WIDTH       : integer  := 9;
	constant NUM_REGS         : integer  := 8;
	constant FRAME_BUFF_WORDS : integer  := 512;
	constant RX_BASE_ADDR     : unsigned := "100000000000";

	type reg_array is array (NUM_REGS - 1 downto 0) of std_logic_vector(31 downto 0);
	signal reg_file   : reg_array;
	signal reg_index  : unsigned(log2(NUM_REGS) - 1 downto 0);
	signal reg_sel    : std_logic;
	signal reg_wr_sel : std_logic_vector(NUM_REGS - 1 downto 0);

	type TX_states is (Idle, Write, Write_Hold, Write_done);
	signal TX_state : TX_states;
	type RX_states is (Idle, read_wait, Read, Read_done);
	signal RX_state : RX_states;

	signal IO_Addr_Strobe  : std_logic;
	signal IO_Read_Strobe  : std_logic;
	signal IO_Write_Strobe : std_logic;
	signal IO_Address      : std_logic_vector(31 downto 0);
	signal IO_Byte_Enable  : std_logic_vector(3 downto 0);
	signal IO_Write_Data   : std_logic_vector(31 downto 0);
	signal IO_Read_Data    : std_logic_vector(31 downto 0);
	signal IO_Ready        : std_logic;

	signal cntrl_reg      : std_logic_vector(31 downto 0);
	signal status_reg     : std_logic_vector(31 downto 0);
	signal IO_addr        : std_logic_vector(3 downto 0);
	signal INTC_Interrupt : STD_LOGIC_VECTOR(4 DOWNTO 0);
	signal INTC_IRQ       : STD_LOGIC;

	signal MCS_buff_sel  : std_logic;
	signal MCS_buff_wr   : std_logic;
	signal MCS_buff_addr : std_logic_vector(log2(BUFF_DEPTH - 1) - 1 downto 0);
	signal MCS_buff_in   : std_logic_vector(BUFF_WIDTH - 1 downto 0);
	signal MCS_buff_out  : std_logic_vector(BUFF_WIDTH - 1 downto 0);
	signal MCS_buff_rd   : std_logic;
	signal MCS_reg_rd    : std_logic;

	signal MCS_TX_busy : std_logic;
	signal NOC_TX_done : std_logic;

	signal NoC_buff_wr      : std_logic;
	signal NoC_buff_addr    : std_logic_vector(log2(BUFF_DEPTH - 1) - 1 downto 0);
	signal NoC_buff_in      : std_logic_vector(BUFF_WIDTH - 1 downto 0);
	signal NoC_buff_out     : std_logic_vector(BUFF_WIDTH - 1 downto 0);
	signal NoC_TX_buff_addr : std_logic_vector(log2(BUFF_DEPTH - 1) - 1 downto 0);
	signal NoC_TX_rd_en     : std_logic;
	signal NoC_TX_buff_reg  : std_logic_vector(BUFF_WIDTH - 1 downto 0);
	signal NoC_TX_buff_req  : std_logic;
	signal NoC_RX_buff_addr : std_logic_vector(log2(BUFF_DEPTH - 1) - 1 downto 0);
	signal NoC_RX_buff_req  : std_logic;
	signal NoC_RX_buff_ack  : std_logic;
	signal NoC_RX_rd_en     : std_logic;
	signal NoC_RX_done      : std_logic;

	signal TX_len_reg       : std_logic_vector(log2(BUFF_DEPTH - 1) - 1 downto 0);
	signal NoC_TX_len_reg   : std_logic_vector(log2(BUFF_DEPTH - 1) - 1 downto 0);
	signal RX_len_reg       : std_logic_vector(log2(BUFF_DEPTH - 1) - 1 downto 0);
	signal NoC_tx_count     : unsigned(log2(BUFF_DEPTH - 1) - 1 downto 0);
	signal MCS_tx_count     : unsigned(log2(BUFF_DEPTH - 1) - 1 downto 0);
	signal NoC_rx_count     : unsigned(log2(BUFF_DEPTH - 1) - 1 downto 0);
	signal MCS_RX_Ack       : std_logic;
	signal MCS_RX_Ack_NOC_0 : std_logic;
	signal MCS_RX_Ack_NOC_1 : std_logic;

	signal EOP_detect : std_logic;

	signal frame_buff_wr_en : std_logic_vector(3 downto 0);
	signal frame_buff_addr  : std_logic_vector(log2(FRAME_BUFF_WORDS - 1)  downto 0);
	signal frame_buff_din   : std_logic_vector(31 downto 0);
	signal frame_buff_dout  : std_logic_vector(31 downto 0);
	signal frame_sel        : std_logic;
	signal frame_rd_reg     : std_logic;

	signal reset_MCS_clk      : std_logic;
	signal reset_mcs_clk_reg0 : std_logic;


	signal MCS_TX_busy_NoC_clk_0 : std_logic;
	signal MCS_TX_busy_NoC_clk_1 : std_logic;
	signal NOC_TX_done_MCS_clk_0 : std_logic;
	signal NOC_TX_done_MCS_clk_1 : std_logic;

	signal NOC_debug_out_0 : STD_LOGIC_vector(8 downto 0);
	signal NOC_debug_out_1 : STD_LOGIC_vector(8 downto 0);
	signal NOC_debug_out_2 : STD_LOGIC_vector(8 downto 0);
	signal NOC_debug_in_0  : STD_LOGIC_vector(8 downto 0);
	signal NOC_debug_in_1  : STD_LOGIC_vector(8 downto 0);
	signal noc_debug_int_0 : std_logic_vector(2 downto 0);
	signal noc_debug_int_1 : std_logic_vector(2 downto 0);

	
	signal RTC_reg_0                        : std_logic_vector(31 downto 0);
	signal RTC_reg_1                        : std_logic_vector(31 downto 0);

	signal tick_in_latch : std_logic;
	signal tick_in_MCS : std_logic;
	signal tick_in_reg0 : std_logic;
	signal tick_in_reg1 : std_logic;

	signal MB_frame_buff_en         : std_logic;
	signal MB_frame_buff_addr      : unsigned(log2((FRAME_BUFF_WORDS*4) - 1) downto 0);
	signal MB_frame_buff_dout : std_logic_vector(7 downto 0);
	
	type Hi_Speed_FSM_states is (idle, setup, upload);
	signal HS_fsm_state : Hi_Speed_FSM_states;
	
	signal router_data_reg : std_logic_vector(7 downto 0);
	signal intel_data_reg : std_logic_vector(7 downto 0);
				
	

begin

	mcs_node_inst : entity xil_defaultlib.centurion_node
		PORT MAP(
			Clk             => MCS_CLK,
			Reset           => MCS_reset,
			IO_Addr_Strobe  => IO_Addr_Strobe,
			IO_Read_Strobe  => IO_Read_Strobe,
			IO_Write_Strobe => IO_Write_Strobe,
			IO_Address      => IO_Address,
			IO_Byte_Enable  => IO_Byte_Enable,
			IO_Write_Data   => IO_Write_Data,
			IO_Read_Data    => IO_Read_Data,
			IO_Ready        => IO_Ready,
			GPI1            => RTC_reg_1,
			INTC_Interrupt  => INTC_Interrupt,
			GPO1            => NOC_debug_out_0,
			GPI2            => NOC_debug_in_1,
			UART_TX => UART_out
		);


	debug_out <= "0" & MB_frame_buff_dout when MB_frame_buff_en = '1' else NOC_debug_out_2; 

	router_data_out <= router_data_reg;
	intel_data_out <= intel_data_reg;

	Noc_clk_sync : process(NoC_Clk) is
	begin
		if rising_edge(NoC_Clk) then
			if NoC_Reset = '1' then
				tick_in_latch <= '0';
			else
				if tick_in = '1' then
					tick_in_latch <= not tick_in_latch;
				end if; 
			end if;
			
			NOC_debug_out_2 <= NOC_debug_out_1;
			NOC_debug_out_1 <= NOC_debug_out_0;
		end if;
	end process Noc_clk_sync;
	
	
	MCS_buff_sel <= '1' when IO_Address(31 downto 24) = x"C1" else '0';

	MCS_buff_wr   <= IO_Write_Strobe and MCS_buff_sel;
	MCS_buff_addr <= IO_Address(log2(BUFF_DEPTH - 1) - 1 + 2 downto 2);
	MCS_buff_in   <= IO_Write_Data(BUFF_WIDTH - 1 downto 0);

	MCS_buff_RAM : entity centurion.dual_port_RAM
		generic map(
			RAM_DEPTH => BUFF_DEPTH,
			RAM_WIDTH => BUFF_WIDTH
		)
		port map(
			clk_a   => MCS_Clk,
			en_a    => '1',
			wr_en_a => MCS_buff_wr,
			addr_a  => MCS_buff_addr,
			din_a   => MCS_buff_in,
			dout_a  => MCS_buff_out,
			clk_b   => NoC_Clk,
			en_b    => '1',
			wr_en_b => NoC_buff_wr,
			addr_b  => NoC_buff_addr,
			din_b   => NoC_buff_in,
			dout_b  => NoC_buff_out
		);

	
	mcs_clk_sync : process(MCS_clk)
	begin
		if rising_edge(MCS_clk) then
			NOC_debug_in_0  <= debug_in;
			NOC_debug_in_1  <= NOC_debug_in_0;
			noc_debug_int_0 <= node_rd_req_intel & node_rd_req_router & debug_in_valid;
			noc_debug_int_1 <= noc_debug_int_0;
			
			tick_in_reg0 <= tick_in_latch;
			tick_in_reg1 <= tick_in_reg0; 
			

			reset_MCS_clk      <= reset_mcs_clk_reg0;
			reset_mcs_clk_reg0 <= MCS_reset;
			RTC_reg_1          <= RTC_reg_0;
			RTC_reg_0          <= RTC_in;
		end if;
	end process;
	
	tick_in_MCS <= '1' when tick_in_reg0 /= tick_in_reg1 else '0';

	reg_sel   <= '1' when IO_Address(31 downto 24) = x"C0" else '0';
	reg_index <= unsigned(IO_Address(log2(NUM_REGS) - 1 + 2 downto 2));

	generate_label : for i in 0 to NUM_REGS - 1 generate
		reg_wr_sel(i) <= '1' when reg_sel = '1' and IO_Write_Strobe = '1' and reg_index = to_unsigned(i, log2(NUM_REGS)) else '0';
	end generate generate_label;

	reg_file(0) <= cntrl_reg;
	reg_file(1) <= std_logic_vector(resize(unsigned(status_reg), 32));
	reg_file(2) <= std_logic_vector(resize(unsigned(TX_len_reg), 32));
	reg_file(3) <= std_logic_vector(resize(unsigned(RX_len_reg), 32));
	reg_file(4) <= std_logic_vector(resize(unsigned(MCS_tx_count), 32));
	reg_file(5) <= std_logic_vector(to_unsigned(node_index, 32));
	reg_file(6) <= std_logic_vector(resize(unsigned(router_data_in), 32));
	reg_file(7) <= std_logic_vector(resize(unsigned(intel_data_in), 32));
		

	IO_Read_Data <= reg_file(to_integer(reg_index)) when MCS_reg_rd = '1'
		else std_logic_vector(resize(unsigned(MCS_buff_out), 32)) when MCS_buff_rd = '1'
		else frame_buff_dout when frame_rd_reg <= '1'
		else (others => '0');

	cntrl_regs_proc : process(MCS_Clk, NoC_reset) is
	begin
		if NoC_reset = '1' then
			MCS_TX_busy <= '0';
			cntrl_reg   <= (others => '0');
		else
			if rising_edge(MCS_Clk) then
				if reset_MCS_clk = '1' then
				--	cntrl_reg <= (others => '0');
				--TX_len_reg <= (others => '0');
				--	 MCS_TX_busy <= '0';
				
					router_data_reg <= (others => '0');
					intel_data_reg <= (others => '0');
					
				else
					MCS_tx_count <= NoC_tx_count;

					NOC_TX_done_MCS_clk_1 <= NOC_TX_done_MCS_clk_0;
					NOC_TX_done_MCS_clk_0 <= NOC_TX_done;

					if reg_wr_sel(0) = '1' then
						cntrl_reg <= IO_Write_Data;
					elsif reg_wr_sel(2) = '1' then
						TX_len_reg  <= IO_Write_Data(log2(BUFF_DEPTH - 1) - 1 downto 0);
						MCS_TX_busy <= '1';
					elsif reg_wr_sel(6) = '1' then
						router_data_reg <= IO_Write_Data(7 downto 0);
					elsif reg_wr_sel(7) = '1' then
						intel_data_reg <= IO_Write_Data(7 downto 0);
	
					end if;

					if NOC_TX_done_MCS_clk_1 = '1' then
						MCS_TX_busy <= '0';
					end if;

				end if;
			end if;
		end if;
	end process cntrl_regs_proc;

	IO_signals_proc : process(MCS_Clk) is
	begin
		if rising_edge(MCS_Clk) then
			if reset_MCS_clk = '1' then
				MCS_buff_rd  <= '0';
				MCS_reg_rd   <= '0';
				IO_Ready     <= '0';
				frame_rd_reg <= '0';
			else
				if IO_Write_Strobe = '1' or IO_Read_Strobe = '1' then
					IO_Ready <= '1';
				else
					IO_Ready <= '0';
				end if;

				MCS_reg_rd   <= '0';
				MCS_buff_rd  <= '0';
				frame_rd_reg <= '0';
				if IO_Read_Strobe = '1' then
					if MCS_buff_sel = '1' then
						MCS_buff_rd <= '1';
					elsif frame_sel = '1' then
						frame_rd_reg <= '1';
					else
						MCS_reg_rd <= '1';
					end if;

				end if;
			end if;
		end if;
	end process IO_signals_proc;

	INTC_Interrupt(2 downto 0) <= noc_debug_int_1;
	INTC_Interrupt(3) <= tick_in_MCS;
	INTC_Interrupt(4 downto 4) <= (others => '0');

	-- IO_Read_Data <= std_logic_vector(resize(unsigned(IO_Read_Data_int),32));

	status_reg(0)           <= NoC_RX_done;
	status_reg(1)           <= MCS_TX_busy;
		
	MCS_RX_Ack <= cntrl_reg(1);
	
	node_wr_req_intel <= cntrl_reg(4);
	node_wr_req_router  <= cntrl_reg(5);

	IO_addr <= IO_Address(5 downto 2);

	--out ports

	Node_Out_Port.control_sel <= NoC_buff_out(8) when TX_state = write else NoC_TX_buff_reg(8);
	Node_Out_Port.data_in     <= NoC_buff_out(7 downto 0) when TX_state = write else NoC_TX_buff_reg(7 downto 0);
	Node_Out_Port.data_valid  <= '1' when TX_state = write or TX_state = write_hold else '0';
	NoC_TX_rd_en              <= Node_In_Port.rd_en;
	NoC_TX_buff_req           <= MCS_TX_busy_NoC_clk_1 when TX_state = idle else NoC_TX_rd_en;
	NoC_TX_buff_addr          <= std_logic_vector(NoC_tx_count);

	NoC_TX_proc : process(NoC_Clk) is
	begin
		if rising_edge(NoC_Clk) then
			if NoC_Reset = '1' then
				TX_state    <= idle;
				NOC_TX_done <= '0';
			else

		
				MCS_TX_busy_NoC_clk_1 <= MCS_TX_busy_NoC_clk_0;
				MCS_TX_busy_NoC_clk_0 <= MCS_TX_busy;

				case TX_state is
					when idle =>
						NOC_TX_done    <= '0';
						NoC_tx_count   <= (others => '0');
						NoC_TX_len_reg <= TX_len_reg;
						if MCS_TX_busy_NoC_clk_1 = '1' then
							TX_state <= write;

						end if;
					when write =>
						TX_state        <= write_hold;
						NoC_TX_buff_reg <= NoC_buff_out;
						NoC_tx_count    <= NoC_tx_count + 1;
					when write_hold =>
						if NoC_TX_rd_en = '1' then
							if NoC_tx_count = unsigned(NoC_TX_len_reg) then
								TX_state <= write_done;
							else
								TX_state <= write;
							end if;
						end if;
					when write_done =>
						NOC_TX_done <= '1';
						if MCS_TX_busy_NoC_clk_1 = '0' then
							TX_state <= idle;
						end if;
				end case;

			end if;
		end if;
	end process NoC_TX_proc;

	NoC_RX_buff_addr    <= std_logic_vector(RX_BASE_ADDR + NoC_rx_count);
	EOP_detect          <= '1' when Node_In_Port.data_valid = '1' and Node_In_Port.control_sel = '1' and Node_In_Port.data_out = ROUTER_EOP_PACKET else '0';
	Node_Out_Port.rd_en <= NoC_RX_rd_en;

	NoC_RX_proc : process(NoC_Clk) is
	begin
		if rising_edge(NoC_Clk) then
			if NoC_Reset = '1' then
				NoC_rx_count <= (others => '0');
				RX_state     <= idle;
				NoC_RX_rd_en <= '0';
				NOC_RX_done  <= '0';
				RX_len_reg   <= (others => '0');
			else
				MCS_RX_Ack_NOC_0 <= MCS_RX_Ack;
				MCS_RX_Ack_NOC_1 <= MCS_RX_Ack_NOC_0;
				case RX_state is
					when idle =>
						NOC_RX_done  <= '0';
						NoC_rx_count <= (others => '0');
						if Node_In_Port.data_valid = '1' then
							RX_state <= Read;
						end if;
					when read =>
						--if we get the ack then we have written to the BRAM
						if NoC_RX_buff_ack = '1' then
							RX_state     <= read_wait;
							NoC_rx_count <= NoC_rx_count + 1;
							NoC_RX_rd_en <= '1';
						end if;
					when read_wait =>
						NoC_RX_rd_en <= '0';
						if EOP_detect = '1' or NoC_RX_buff_addr = std_logic_vector(to_unsigned(BUFF_DEPTH - 1, NoC_RX_buff_addr'length)) then
							RX_state <= read_done;
						else
							RX_state <= read;
						end if;
					when read_done =>
						NOC_RX_done <= '1';
						RX_len_reg  <= std_logic_vector(NoC_rx_count);
						if MCS_RX_Ack_NOC_1 = '1' then
							RX_state <= idle;
						end if;
				end case;

			end if;
		end if;
	end process NoC_RX_proc;

	NoC_RX_buff_req <= Node_In_Port.data_valid when RX_state = read else '0';
	NoC_RX_buff_ack <= NoC_RX_buff_req and not NoC_TX_buff_req;
	--TX request always wins!
	NoC_buff_addr   <= NoC_TX_buff_addr when NoC_TX_buff_req = '1' else NoC_RX_buff_addr;
	NoC_buff_wr     <= NoC_RX_buff_ack;
	NoC_buff_in     <= Node_In_Port.control_sel & Node_In_Port.data_out;

	frame_sel        <= '1' when IO_Address(31 downto 24) = x"C5" else '0';
	frame_buff_addr  <= IO_Address(log2(FRAME_BUFF_WORDS - 1) + 2 downto 2);
	frame_buff_wr_en <= IO_Byte_Enable when (frame_sel = '1' and IO_Write_Strobe = '1') else "0000";
	frame_buff_din   <= IO_Write_Data;

	--
	--	frame_buffer : entity work.single_port_RAM_32
	--		generic map(
	--			RAM_DEPTH_WORDS => FRAME_BUFF_WORDS
	--		)
	--		port map(
	--			clk_a   => MCS_Clk,
	--			wr_en_a => frame_buff_wr_en,
	--			addr_a  => frame_buff_addr,
	--			din_a   => frame_buff_din,
	--			dout_a  => frame_buff_dout
	--		);
	--
	
	MB_frame_buff_en <= '1' when HS_fsm_state = setup or HS_fsm_state = upload else '0';
	
	
	Hi_speed_download_proc: process (NoC_Clk) is
	begin
		if rising_edge(NoC_Clk) then
			if NoC_Reset = '1' then
				HS_fsm_state <= Idle;
			else
				case HS_fsm_state is 
					when idle =>
						MB_frame_buff_addr <= (others => '0');
						--wait for rising edge on download select
						if Hi_Speed_Download_en = '1' then
							HS_fsm_state <= setup;
						end if;
					when setup =>
							HS_fsm_state <= upload;
					when upload =>
						MB_frame_buff_addr <= MB_frame_buff_addr + 1;
						if Hi_Speed_Download_en = '0' then
							HS_fsm_state <= idle;
						end if;
				end case;
			end if;
		end if;
	end process Hi_speed_download_proc;
	

			
	frame_buffer : entity work.dual_port_RAM_asymmetric_A32WR_B8R
		port map(
			clkB  => NoC_Clk,
			enB  => MB_frame_buff_en,
			addrB => std_logic_vector(MB_frame_buff_addr(log2((FRAME_BUFF_WORDS*4) - 1) downto 0)),
			doB   => MB_frame_buff_dout,

			clkA  => MCS_Clk,
			enA   => '1',
			weA   => frame_buff_wr_en(0 downto 0),
			addrA => frame_buff_addr,
			diA   => frame_buff_din,
			doA   => frame_buff_dout
			
		);

end Behavioral;

