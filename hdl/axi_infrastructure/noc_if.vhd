library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;

entity noc_if is
	generic(
			RAM_DEPTH : integer := 2048;
			BUFF_SIZE_bytes : integer := 2048 * 4;
			BUFF_SIZE_bytes_log2 : integer := log2( 2048 * 4 - 1)
	);
	port (
		MB_clk : in std_logic;
		NoC_clk : in std_logic;
		reset : in std_logic;
		
		--write channel
		wr_addr		: in std_logic_vector(BUFF_SIZE_bytes_log2-1 downto 0);
		data_in 	: in std_logic_vector(35 downto 0);
		wr_en 		: in std_logic_vector(3 downto 0);
		
		--read channel
		rd_addr		: in std_logic_vector(BUFF_SIZE_bytes_log2-1 downto 0);
		data_out 	: out std_logic_vector(35 downto 0);
		rd_burst_sel 	: in std_logic;
		
		--control signals
		MB_TX_start : in std_logic; 
		MB_TX_len : in unsigned(BUFF_SIZE_bytes_log2 -1 downto 0);
		MB_RX_Ack : in std_logic;
		--status signals
		TX_busy : out std_logic; 
		RX_done : out std_logic;
  		RX_length : out unsigned(BUFF_SIZE_bytes_log2 -1 downto 0);
  	
		--NoC Interface
		NoC_In_Port     : in  router_out_port;
		NoC_Out_Port    : out router_in_port
		
	);
end entity noc_if;

architecture RTL of noc_if is
	
	constant RAM_WIDTH : integer := 36;
	
		
	type TX_states is(Idle, Write, Write_Hold, Write_done);
	signal TX_state : TX_states;
	type RX_states is(Idle, read_wait, Read, Read_done);
	signal RX_state : RX_states;
	

	signal NoC_buff_wr : std_logic_vector(3 downto 0);
	signal NoC_tx_count : unsigned(BUFF_SIZE_bytes_log2 -1 downto 0);
	signal NOC_TX_done : std_logic;
	signal MB_TX_buff_wr : std_logic_vector(3 downto 0);
	signal MB_TX_buff_addr : std_logic_vector(log2(RAM_DEPTH - 1) - 1 downto 0);
	signal MB_TX_buff_in : std_logic_vector(RAM_WIDTH - 1 downto 0);
	signal MB_TX_buff_out : std_logic_vector(RAM_WIDTH - 1 downto 0);
	signal NoC_TX_buff_wr : std_logic_vector(3 downto 0);
	signal NoC_TX_buff_addr : std_logic_vector(log2(RAM_DEPTH - 1) - 1 downto 0);
	signal NoC_TX_buff_in : std_logic_vector(RAM_WIDTH - 1 downto 0);
	signal NoC_TX_buff_out : std_logic_vector(RAM_WIDTH - 1 downto 0);
	
	signal NoC_word_out : std_logic_vector(8 downto 0);
	signal NoC_word_out_sel : unsigned(1 downto 0);
	
	
	signal MB_RX_buff_wr : std_logic_vector(3 downto 0);
	signal MB_RX_buff_addr : std_logic_vector(log2(RAM_DEPTH - 1) - 1 downto 0);
	signal MB_RX_buff_in : std_logic_vector(RAM_WIDTH - 1 downto 0);
	signal MB_RX_buff_out : std_logic_vector(RAM_WIDTH - 1 downto 0);
	signal NoC_RX_buff_wr : std_logic_vector(3 downto 0);
	signal NoC_RX_buff_addr : std_logic_vector(log2(RAM_DEPTH - 1) - 1 downto 0);
	signal NoC_word_in_sel : unsigned(1 downto 0);
	signal NoC_RX_buff_in : std_logic_vector(RAM_WIDTH - 1 downto 0);
	signal NoC_RX_buff_out : std_logic_vector(RAM_WIDTH - 1 downto 0);
	
	
	signal EOP_detect : std_logic;
	signal NoC_RX_rd_en : std_logic;
	signal NOC_RX_done : std_logic;
	signal NoC_rx_count :  unsigned(BUFF_SIZE_bytes_log2 -1 downto 0);
	signal NoC_TX_rd_en : std_logic;
	
begin
	
	MB_TX_buff_addr <= wr_addr(log2(RAM_DEPTH - 1) + 2 - 1 downto 2);
	MB_TX_buff_in <= data_in;
	MB_TX_buff_wr <= wr_en;
	NoC_TX_buff_wr <= (others => '0');
	NoC_TX_buff_in <= (others => '0');
	

TX_buff_RAM : entity centurion.dual_port_RAM_36
		generic map(
			RAM_DEPTH => RAM_DEPTH,
			RAM_WIDTH => RAM_WIDTH
		)
		port map(
			clk_a   => MB_clk,
			wr_en_a => MB_TX_buff_wr,
			addr_a  => MB_TX_buff_addr,
			din_a   => MB_TX_buff_in,
			dout_a  => MB_TX_buff_out,
			clk_b   => NoC_Clk,
			wr_en_b => NoC_TX_buff_wr,
			addr_b  => NoC_TX_buff_addr,
			din_b   => NoC_TX_buff_in,
			dout_b  => NoC_TX_buff_out
		);
		
		MB_RX_buff_addr <= rd_addr(log2(RAM_DEPTH - 1) + 2 - 1 downto 2);
		MB_RX_buff_wr <= (others => '0');
		MB_RX_buff_in <= (others => '0');
		data_out <= MB_RX_buff_out;
		RX_length <= NoC_rx_count;
		RX_done <=  NOC_RX_done;

RX_buff_RAM : entity centurion.dual_port_RAM_36
		generic map(
			RAM_DEPTH => RAM_DEPTH,
			RAM_WIDTH => RAM_WIDTH
		)
		port map(
			clk_a   => MB_clk,
			wr_en_a => MB_RX_buff_wr,
			addr_a  => MB_RX_buff_addr,
			din_a   => MB_RX_buff_in,
			dout_a  => MB_RX_buff_out,
			clk_b   => NoC_Clk,
			wr_en_b => NoC_RX_buff_wr,
			addr_b  => NoC_RX_buff_addr,
			din_b   => NoC_RX_buff_in,
			dout_b  => NoC_RX_buff_out
		);


	NoC_Out_Port.control_sel     <= NoC_word_out(8);
	NoC_Out_Port.data_in     <= NoC_word_out(7 downto 0);
	NoC_Out_Port.data_valid <= '1' when TX_state = write_hold else '0';
	NoC_TX_rd_en <= NoC_In_Port.rd_en;
	NoC_TX_buff_addr <= std_logic_vector(NoC_tx_count(NoC_tx_count'left downto 2));
	NoC_word_out_sel <= NoC_tx_count(1 downto 0);
	NoC_word_out <= NoC_TX_buff_out(8 downto 0) when NoC_word_out_sel = "00" else
					NoC_TX_buff_out(17 downto 9) when NoC_word_out_sel = "01" else
					NoC_TX_buff_out(26 downto 18) when NoC_word_out_sel = "10" else
					NoC_TX_buff_out(35 downto 27) when NoC_word_out_sel = "11";
	
	TX_busy <= '0' when TX_state = idle else '1';
	
	NoC_TX_proc : process (NoC_Clk) is
	begin
		if rising_edge(NoC_Clk) then
			if reset = '1' then
				NoC_tx_count <= (others => '0');
				TX_state <= idle;
				NOC_TX_done <= '0';
			else
				case TX_state is 
				when idle =>
					NOC_TX_done <= '0';
					NoC_tx_count <= (others => '0');
						if MB_TX_start = '1' then 
							TX_state <= write;
						end if;
					when write =>
						TX_state <= write_hold;
						
					when write_hold =>
						if NoC_TX_rd_en = '1' then
							NoC_tx_count  <= NoC_tx_count + 1;
							if  NoC_tx_count + 1 =  unsigned(MB_TX_len) then
								TX_state <= write_done;
							else
								TX_state <= write;
							end if;
						end if;
					when write_done =>
						NOC_TX_done <= '1';
						if MB_TX_start = '0' then
							TX_state <= idle;
						end if;
				end case;
				
			end if;
		end if;
	end process NoC_TX_proc;
	
	NoC_RX_buff_addr <= std_logic_vector(resize(NoC_rx_count(NoC_rx_count'left downto 2), log2(RAM_DEPTH - 1)));
	EOP_detect <= '1' when NoC_In_Port.data_valid = '1' and NoC_In_Port.control_sel = '1' and NoC_In_Port.data_out = ROUTER_EOP_PACKET else '0';
	NoC_Out_Port.rd_en <= NoC_RX_rd_en;
	
	
	
	
	NoC_RX_buff_in <= (NoC_In_Port.control_sel & NoC_In_Port.data_out) 
					& (NoC_In_Port.control_sel & NoC_In_Port.data_out)
					& (NoC_In_Port.control_sel & NoC_In_Port.data_out)
					& (NoC_In_Port.control_sel & NoC_In_Port.data_out);
	NoC_word_in_sel <= NoC_rx_count(1 downto 0);
	
	rx_wr_en_gen : for i in 0 to 3 generate
		NoC_RX_buff_wr(i) <= '1' when RX_state = read and NoC_word_in_sel = i else '0';
	end generate rx_wr_en_gen;
	
	NoC_RX_rd_en <= '1' when RX_state = read else '0';
	NoC_RX_proc : process(NoC_Clk) is
	begin
		if rising_edge(NoC_Clk) then
			if reset = '1' then
				NoC_rx_count <= (others => '0');
				RX_state     <= idle;
			--	NoC_RX_rd_en <= '0';
				NOC_RX_done <= '0';
			else
				case RX_state is
				when idle =>
					NOC_RX_done <= '0';				
					NoC_rx_count <= (others => '0');
						if NoC_In_Port.data_valid = '1' then
							RX_state     <= Read;
						end if;
					when read =>
							
							NoC_rx_count    <= NoC_rx_count + 1;
							if EOP_detect = '1' or NoC_RX_buff_addr = std_logic_vector(to_unsigned(RAM_DEPTH-1, NoC_RX_buff_addr'length)) then
								RX_state <= read_done;
							else
								RX_state        <= read_wait;
							end if;
							--NoC_RX_rd_en <= '1';
					when read_wait =>
						--NoC_RX_rd_en <= '0';
						if NoC_In_Port.data_valid = '1' then
							RX_state     <= Read;
						end if;
					when read_done =>
						NOC_RX_done <= '1';
						if MB_RX_Ack = '1' then
							RX_state <= idle;
						end if;
				end case;

			end if;
		end if;
	end process NoC_RX_proc;
	
	
	





end architecture RTL;
