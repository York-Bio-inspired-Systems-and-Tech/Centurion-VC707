--Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
--Date        : Fri Feb 15 17:38:18 2019
--Host        : elecpc279.its running 64-bit CentOS Linux release 7.6.1810 (Core)
--Command     : generate_target pcie_bd_wrapper.bd
--Design      : pcie_bd_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity pcie_bd_wrapper is
  port (
    PCIE_ref_clk_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    PCIE_ref_clk_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    UART_node_tx_0 : out STD_LOGIC;
    dip_switches_8bits_tri_i : in STD_LOGIC_VECTOR ( 7 downto 0 );
    led_8bits_tri_o : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pcie_7x_mgt_0_rxn : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pcie_7x_mgt_0_rxp : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pcie_7x_mgt_0_txn : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pcie_7x_mgt_0_txp : out STD_LOGIC_VECTOR ( 7 downto 0 );
    reset : in STD_LOGIC;
    sys_diff_clock_clk_n : in STD_LOGIC;
    sys_diff_clock_clk_p : in STD_LOGIC
  );
end pcie_bd_wrapper;

architecture STRUCTURE of pcie_bd_wrapper is
  component pcie_bd is
  port (
    reset : in STD_LOGIC;
    UART_node_tx_0 : out STD_LOGIC;
    sys_diff_clock_clk_n : in STD_LOGIC;
    sys_diff_clock_clk_p : in STD_LOGIC;
    dip_switches_8bits_tri_i : in STD_LOGIC_VECTOR ( 7 downto 0 );
    PCIE_ref_clk_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    PCIE_ref_clk_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    led_8bits_tri_o : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pcie_7x_mgt_0_rxn : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pcie_7x_mgt_0_rxp : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pcie_7x_mgt_0_txn : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pcie_7x_mgt_0_txp : out STD_LOGIC_VECTOR ( 7 downto 0 )
  );
  end component pcie_bd;
begin
pcie_bd_i: component pcie_bd
     port map (
      PCIE_ref_clk_clk_n(0) => PCIE_ref_clk_clk_n(0),
      PCIE_ref_clk_clk_p(0) => PCIE_ref_clk_clk_p(0),
      UART_node_tx_0 => UART_node_tx_0,
      dip_switches_8bits_tri_i(7 downto 0) => dip_switches_8bits_tri_i(7 downto 0),
      led_8bits_tri_o(7 downto 0) => led_8bits_tri_o(7 downto 0),
      pcie_7x_mgt_0_rxn(7 downto 0) => pcie_7x_mgt_0_rxn(7 downto 0),
      pcie_7x_mgt_0_rxp(7 downto 0) => pcie_7x_mgt_0_rxp(7 downto 0),
      pcie_7x_mgt_0_txn(7 downto 0) => pcie_7x_mgt_0_txn(7 downto 0),
      pcie_7x_mgt_0_txp(7 downto 0) => pcie_7x_mgt_0_txp(7 downto 0),
      reset => reset,
      sys_diff_clock_clk_n => sys_diff_clock_clk_n,
      sys_diff_clock_clk_p => sys_diff_clock_clk_p
    );
end STRUCTURE;
