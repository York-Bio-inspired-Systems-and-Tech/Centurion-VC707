
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity centurion_debug is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    RTC_PRESCALER_VALUE : integer := 0;
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_S_AXI_DATA_WIDTH             : integer              := 32;
    C_S_AXI_ADDR_WIDTH             : integer              := 32;
    C_S_AXI_MIN_SIZE               : std_logic_vector     := X"000001FF";
    C_USE_WSTRB                    : integer              := 0;
    C_DPHASE_TIMEOUT               : integer              := 8;
    C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
    C_HIGHADDR                     : std_logic_vector     := X"00000000";
    C_FAMILY                       : string               := "virtex6";
    C_NUM_REG                      : integer              := 1;
    C_NUM_MEM                      : integer              := 1;
    C_SLV_AWIDTH                   : integer              := 32;
    C_SLV_DWIDTH                   : integer              := 32
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------    
	MCS_debug_value : in std_logic_vector(8 downto 0);
	MCS_clk_EN_value : in std_logic;
	MCS_clk_value : in std_logic_vector(4 downto 0);
	MCS_sel_value : out std_logic_vector(7 downto 0);
	MCS_command_out : out std_logic_vector(8 downto 0);
	MCS_command_valid : out std_logic;
	router_sel : out std_logic_vector(3 downto 0);
	--FPGA_temp : in std_logic_vector(9 downto 0);
	
	HS_download_en : out std_logic;
	
    -- ADD USER PORTS ABOVE THIS LINE ------------------
		-- BRAM BUFFER 
	HS_clka  : in std_logic;                       			  -- Port A Clock
	HS_wea   : in std_logic_vector(3 downto 0);                       			  -- Port A Write enable
	HS_ena   : in std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
	HS_rsta  : in std_logic;                       			  -- Port A Output reset (does not affect memory contents)
	HS_addra : in std_logic_vector(32-1 downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
	HS_dina  : out std_logic_vector(32-1 downto 0);		  -- Port A RAM input data
	HS_douta : in std_logic_vector(32-1 downto 0);
		
	
	-- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    S_AXI_ACLK                     : in  std_logic;
    S_AXI_ARESETN                  : in  std_logic;
    S_AXI_AWADDR                   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWVALID                  : in  std_logic;
    S_AXI_WDATA                    : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB                    : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID                   : in  std_logic;
    S_AXI_BREADY                   : in  std_logic;
    S_AXI_ARADDR                   : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARVALID                  : in  std_logic;
    S_AXI_RREADY                   : in  std_logic;
    S_AXI_ARREADY                  : out std_logic;
    S_AXI_RDATA                    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP                    : out std_logic_vector(1 downto 0);
    S_AXI_RVALID                   : out std_logic;
    S_AXI_WREADY                   : out std_logic;
    S_AXI_BRESP                    : out std_logic_vector(1 downto 0);
    S_AXI_BVALID                   : out std_logic;
    S_AXI_AWREADY                  : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;
  attribute MAX_FANOUT of S_AXI_ACLK       : signal is "10000";
  attribute MAX_FANOUT of S_AXI_ARESETN       : signal is "10000";
  attribute SIGIS of S_AXI_ACLK       : signal is "Clk";
  attribute SIGIS of S_AXI_ARESETN       : signal is "Rst";
end entity centurion_debug;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of centurion_debug is

	signal node_sel : std_logic_vector(7 downto 0);
	signal router_sel_reg : std_logic_vector(3 downto 0);
	signal debug_data_out : std_logic_vector(31 downto 0);
	signal debug_command_out : std_logic_vector(8 downto 0);
	signal debug_command_valid : std_logic;
	
	
	constant HS_BUFF_SIZE_WORDS : integer := 1024;
	signal HS_buff_addr      : unsigned(11 downto 0);
	signal HS_buff_wr_en : std_logic;
	type Hi_Speed_FSM_states is (idle, setup0, setup1, setup2, setup3, setup4, setup5, setup6, setup7, setup8, download);
	signal HS_fsm_state : Hi_Speed_FSM_states;
	signal HS_download_count      : unsigned(11 downto 0);
	signal HS_download_len      : unsigned(11 downto 0);
	signal HS_download_en_int  : std_logic;
	signal cntrl_sigs : std_logic_vector(2 downto 0);
		
begin

	--write response channel signals
	S_AXI_AWREADY <= S_AXI_AWVALID;
	S_AXI_WREADY <= S_AXI_WVALID;
    S_AXI_BRESP  <= "00";
    S_AXI_BVALID  <= S_AXI_WVALID;
	
	--read response channel signals
	S_AXI_ARREADY   <= S_AXI_ARVALID;
    S_AXI_RRESP      <= "00";
    S_AXI_RVALID     <= S_AXI_RREADY;
	MCS_sel_value <= std_logic_vector(node_sel);
	MCS_command_out <= debug_command_out;
	MCS_command_valid <= debug_command_valid;
	S_AXI_RDATA <= std_logic_vector(debug_data_out);
	router_sel <= router_sel_reg;

 debug_reg_proc : process(S_AXI_ACLK) is
  begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then 
				node_sel <= (others => '0');
				debug_command_out <= (others => '0');
				debug_command_valid <= '0';
				router_sel_reg <= "0000";
				HS_download_len <= (others => '0');
				cntrl_sigs <= "000";
			else
				if S_AXI_WVALID = '1' then
					if S_AXI_AWADDR(7 downto 0) = x"00" then
						node_sel <= S_AXI_WDATA(7 downto 0);
						router_sel_reg <= S_AXI_WDATA(11 downto 8);
					elsif  S_AXI_AWADDR(7 downto 0) = x"04" then
						debug_command_out <= S_AXI_WDATA(8 downto 0);
					elsif  S_AXI_AWADDR(7 downto 0) = x"08" then
						debug_command_valid <= '1';
					elsif  S_AXI_AWADDR(7 downto 0) = x"0C" then
						debug_command_valid <= '0';
					elsif  S_AXI_AWADDR(7 downto 0) = x"10" then
						HS_download_len <= unsigned(S_AXI_WDATA(11 downto 0));
					elsif  S_AXI_AWADDR(7 downto 0) = x"14" then
						cntrl_sigs <= S_AXI_WDATA(2 downto 0);
					end if;
					
					
				end if;
				
				if HS_fsm_state = download then
					HS_download_len <= (others => '0');
				end if;
				
				debug_data_out(8 downto 0) <= MCS_debug_value;
				debug_data_out(13 downto 9) <= MCS_clk_value;
				debug_data_out(14) <= MCS_clk_EN_value;
			--	debug_data_out(24 downto 15) <= FPGA_temp;
				debug_data_out(15) <= HS_download_en_int;
				debug_data_out(31 downto 16) <= Node_Temp_in;
			end if;
		end if;
	end process;

	centurion_debug_0_intel_enable <= cntrl_sigs(0);
	centurion_debug_0_intel_freq_sel <= cntrl_sigs(1);
	centurion_debug_0_intel_clk_sel <= cntrl_sigs(2);
	
	
	HS_buff_wr_en <= '1' when HS_fsm_state = download else '0';
	HS_download_en_int <= '0' when HS_fsm_state = idle else '1';
	
	HS_download_en <= HS_download_en_int;

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
						HS_download_count <= HS_download_len;
						--wait for rising edge on download select
						if HS_download_len /= 0 then
							HS_fsm_state <= setup0;
						end if;
					when setup0 =>
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

				
	HS_data_buffer : entity centurion_debug_v1_00_a.dual_port_RAM_asymmetric_A32RW_B8W

		port map(
			clkA  => HS_clka,
			enA   => HS_ena,
			weA   => HS_wea,
			addrA => HS_addra(11 downto 2),
			diA   => HS_douta,
			doA   => HS_dina,
			
			clkB  => S_AXI_ACLK,
			weB  => HS_buff_wr_en,
			addrB => std_logic_vector(HS_buff_addr),
			diB   => MCS_debug_value(7 downto 0)
		);
	
end IMP;

