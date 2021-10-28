------------------------------------------------------------------------------
-- rtc.vhd - entity/architecture pair
------------------------------------------------------------------------------
-- IMPORTANT:
-- DO NOT MODIFY THIS FILE EXCEPT IN THE DESIGNATED SECTIONS.
--
-- SEARCH FOR --USER TO DETERMINE WHERE CHANGES ARE ALLOWED.
--
-- TYPICALLY, THE ONLY ACCEPTABLE CHANGES INVOLVE ADDING NEW
-- PORTS AND GENERICS THAT GET PASSED THROUGH TO THE INSTANTIATION
-- OF THE USER_LOGIC ENTITY.
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          rtc.vhd
-- Version:           1.00.a
-- Description:       Top level design, instantiates library components and user logic.
-- Date:              Mon Mar 21 11:44:47 2016 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_S_AXI_DATA_WIDTH           -- AXI4LITE slave: Data width
--   C_S_AXI_ADDR_WIDTH           -- AXI4LITE slave: Address Width
--   C_S_AXI_MIN_SIZE             -- AXI4LITE slave: Min Size
--   C_USE_WSTRB                  -- AXI4LITE slave: Write Strobe
--   C_DPHASE_TIMEOUT             -- AXI4LITE slave: Data Phase Timeout
--   C_BASEADDR                   -- AXI4LITE slave: base address
--   C_HIGHADDR                   -- AXI4LITE slave: high address
--   C_FAMILY                     -- FPGA Family
--   C_NUM_REG                    -- Number of software accessible registers
--   C_NUM_MEM                    -- Number of address-ranges
--   C_SLV_AWIDTH                 -- Slave interface address bus width
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--
-- Definition of Ports:
--   S_AXI_ACLK                   -- AXI4LITE slave: Clock 
--   S_AXI_ARESETN                -- AXI4LITE slave: Reset
--   S_AXI_AWADDR                 -- AXI4LITE slave: Write address
--   S_AXI_AWVALID                -- AXI4LITE slave: Write address valid
--   S_AXI_WDATA                  -- AXI4LITE slave: Write data
--   S_AXI_WSTRB                  -- AXI4LITE slave: Write strobe
--   S_AXI_WVALID                 -- AXI4LITE slave: Write data valid
--   S_AXI_BREADY                 -- AXI4LITE slave: Response ready
--   S_AXI_ARADDR                 -- AXI4LITE slave: Read address
--   S_AXI_ARVALID                -- AXI4LITE slave: Read address valid
--   S_AXI_RREADY                 -- AXI4LITE slave: Read data ready
--   S_AXI_ARREADY                -- AXI4LITE slave: read addres ready
--   S_AXI_RDATA                  -- AXI4LITE slave: Read data
--   S_AXI_RRESP                  -- AXI4LITE slave: Read data response
--   S_AXI_RVALID                 -- AXI4LITE slave: Read data valid
--   S_AXI_WREADY                 -- AXI4LITE slave: Write data ready
--   S_AXI_BRESP                  -- AXI4LITE slave: Response
--   S_AXI_BVALID                 -- AXI4LITE slave: Resonse valid
--   S_AXI_AWREADY                -- AXI4LITE slave: Wrte address ready
------------------------------------------------------------------------------

entity rtc is
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
    RTC_value : out std_logic_vector(31 downto 0);
	 RTC_1us_tick : out std_logic;
	 RTC_1ms_tick : out std_logic;
	 RTC_user_0_tick : out std_logic;
	 RTC_user_1_tick : out std_logic;
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
end entity rtc;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of rtc is

	 signal RTC_count : unsigned(31 downto 0);
	 signal RTC_scaler : unsigned(31 downto 0);

	signal RTC_1us_count : unsigned(6 downto 0);
	signal RTC_1ms_count : unsigned(16 downto 0);
	signal RTC_user_0_count : unsigned(31 downto 0);
	signal RTC_user_0_period : unsigned(31 downto 0);
	signal RTC_user_1_count : unsigned(31 downto 0);
	signal RTC_user_1_period : unsigned(31 downto 0);
	
	signal RTC_1us_tick_int : std_logic;
	signal RTC_1ms_tick_int : std_logic;
	signal RTC_user_0_tick_int : std_logic;
	signal RTC_user_1_tick_int : std_logic;
	signal RTC_1us_tick_reg : std_logic;
	signal RTC_1ms_tick_reg : std_logic;
	signal RTC_user_0_tick_reg : std_logic;
	signal RTC_user_1_tick_reg : std_logic;
	signal deadlock_count_en : std_logic;

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
	RTC_value <= std_logic_vector(RTC_count);
	S_AXI_RDATA <= std_logic_vector(RTC_count);

 RTC_count_proc : process(S_AXI_ACLK) is
  begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then 
				RTC_count <= (others => '0');
				RTC_scaler <= to_unsigned(RTC_PRESCALER_VALUE, 32);
				deadlock_count_en <= '0';
			else
				if S_AXI_WVALID = '1' then
					if S_AXI_AWADDR(7 downto 0) = x"00" then
						RTC_count <= (others => '0');
						RTC_scaler <= to_unsigned(RTC_PRESCALER_VALUE, 32);
					elsif S_AXI_AWADDR(7 downto 0) = x"04" then
						deadlock_count_en <= S_AXI_WDATA(0);

					elsif  S_AXI_AWADDR(7 downto 0) = x"08" then
						RTC_user_0_period <= unsigned(S_AXI_WDATA);
					elsif  S_AXI_AWADDR(7 downto 0) = x"0C" then
						RTC_user_1_period <= unsigned(S_AXI_WDATA);
					end if;
					
				elsif RTC_scaler = 0 then
					RTC_scaler <= to_unsigned(RTC_PRESCALER_VALUE, 32);
					RTC_count <= RTC_count + 1;
				else
					RTC_scaler <= RTC_scaler - 1;
				end if;
			end if;	
		end if;
	end process;
	

	
RTC_1us_tick_int 	<= not RTC_1us_tick_reg when RTC_1us_count = 100 else RTC_1us_tick_reg;
RTC_1ms_tick_int 	<= not RTC_1ms_tick_reg when RTC_1ms_count = 100000 else RTC_1ms_tick_reg;
RTC_user_0_tick_int 	<= not RTC_user_0_tick_reg when RTC_user_0_count = RTC_user_0_period else RTC_user_0_tick_reg;
RTC_user_1_tick_int 	<= not RTC_user_1_tick_reg when RTC_user_1_count = RTC_user_1_period else RTC_user_1_tick_reg;

RTC_1us_tick <= RTC_1us_tick_reg;
RTC_1ms_tick <= RTC_1ms_tick_reg;
RTC_user_0_tick <= RTC_user_0_tick_reg;
RTC_user_1_tick <= RTC_user_1_tick_reg;
	
	
RTC_timers_proc : process(S_AXI_ACLK) is
  begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then 
				RTC_1us_count <= (others => '0');
				RTC_1ms_count <= (others => '0');
				RTC_user_0_count <= (others => '0');
				RTC_user_1_count <= (others => '0');
				RTC_1us_tick_reg <= '0';
				RTC_1ms_tick_reg <= '0';
				RTC_user_0_tick_reg <= '0';
				RTC_user_1_tick_reg <= '0';
			else
				RTC_1us_tick_reg <= RTC_1us_tick_int;
				RTC_1ms_tick_reg <= RTC_1ms_tick_int;
				RTC_user_0_tick_reg <= RTC_user_0_tick_int;
				RTC_user_1_tick_reg <= RTC_user_1_tick_int;

				--assume a 100MHz clock
				if RTC_1us_count = 100 then
					RTC_1us_count <= (others => '0');
				else
					RTC_1us_count <= RTC_1us_count + 1;
				end if;
				
				--assume a 100MHz clock
				if RTC_1ms_count = 100000 then
					RTC_1ms_count <= (others => '0');
				else
					if deadlock_count_en = '1' then
						RTC_1ms_count <= RTC_1ms_count + 1;
					end if;
				end if;

	
				if RTC_user_0_count = RTC_user_0_period then
					RTC_user_0_count <= (others => '0');
				else
					RTC_user_0_count <= RTC_user_0_count + 1;
				end if;
	
				if RTC_user_1_count = RTC_user_1_period then
					RTC_user_1_count <= (others => '0');
				else
					RTC_user_1_count <= RTC_user_1_count + 1;
				end if;
	
	
				
			end if;
		end if;
	end process;



end IMP;
