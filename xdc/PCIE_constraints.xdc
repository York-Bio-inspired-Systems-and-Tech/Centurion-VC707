# Si5324_OUT_C_P REFCLK+ Integrated EndPoint block differential clock pair from PCIe
#set_property IOSTANDARD LVDS [get_ports PCIE_ref_clk_clk_p[0]]

# Si5324_OUT_C_N REFCLK- Integrated EndPoint block differential clock pair from PCIe
set_property PACKAGE_PIN AB8 [get_ports {PCIE_ref_clk_clk_p[0]}]
set_property PACKAGE_PIN AB7 [get_ports {PCIE_ref_clk_clk_n[0]}]
#set_property IOSTANDARD LVDS [get_ports PCIE_ref_clk_clk_n[0]]

set_property PACKAGE_PIN AU36 [get_ports UART_node_tx_0]
set_property IOSTANDARD LVCMOS18 [get_ports UART_node_tx_0]

#set_property IS_ENABLED 0 [get_drc_checks {LUTLP-1}]

