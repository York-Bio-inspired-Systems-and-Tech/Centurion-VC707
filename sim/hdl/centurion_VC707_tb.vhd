-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 21.3.2019 16:39:40 GMT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_axi_sim_pkg.all;

entity centurion_axi_tb is
end centurion_axi_tb;

architecture tb of centurion_axi_tb is

	signal UART_node_tx : std_logic;

	constant clk_period : time      := 10 ns; -- EDIT Put right period here
	signal clk          : std_logic := '0';

begin

	dut : entity centurion.centurion_axi
		generic map(
			NOC_Width          => 2,
			NOC_Height         => 2,
			NOC_NUM_NODES_LOG2 => 2
		)
		port map(UART_node_tx  => UART_node_tx,
		         S_AXI_ACLK    => S_AXI_ACLK,
		         S_AXI_ARESETN => S_AXI_ARESETN,
		         S_AXI_AWADDR  => S_AXI_AWADDR,
		         S_AXI_AWVALID => S_AXI_AWVALID,
		         S_AXI_WDATA   => S_AXI_WDATA,
		         S_AXI_WSTRB   => S_AXI_WSTRB,
		         S_AXI_WVALID  => S_AXI_WVALID,
		         S_AXI_BREADY  => S_AXI_BREADY,
		         S_AXI_ARADDR  => S_AXI_ARADDR,
		         S_AXI_ARVALID => S_AXI_ARVALID,
		         S_AXI_RREADY  => S_AXI_RREADY,
		         S_AXI_ARREADY => S_AXI_ARREADY,
		         S_AXI_RDATA   => S_AXI_RDATA,
		         S_AXI_RRESP   => S_AXI_RRESP,
		         S_AXI_RVALID  => S_AXI_RVALID,
		         S_AXI_WREADY  => S_AXI_WREADY,
		         S_AXI_BRESP   => S_AXI_BRESP,
		         S_AXI_BVALID  => S_AXI_BVALID,
		         S_AXI_AWREADY => S_AXI_AWREADY,
		         S_AXI_AWID    => S_AXI_AWID,
		         S_AXI_AWLEN   => S_AXI_AWLEN,
		         S_AXI_AWSIZE  => S_AXI_AWSIZE,
		         S_AXI_AWBURST => S_AXI_AWBURST,
		         S_AXI_AWLOCK  => S_AXI_AWLOCK,
		         S_AXI_AWCACHE => S_AXI_AWCACHE,
		         S_AXI_AWPROT  => S_AXI_AWPROT,
		         S_AXI_WLAST   => S_AXI_WLAST,
		         S_AXI_BID     => S_AXI_BID,
		         S_AXI_ARID    => S_AXI_ARID,
		         S_AXI_ARLEN   => S_AXI_ARLEN,
		         S_AXI_ARSIZE  => S_AXI_ARSIZE,
		         S_AXI_ARBURST => S_AXI_ARBURST,
		         S_AXI_ARLOCK  => S_AXI_ARLOCK,
		         S_AXI_ARCACHE => S_AXI_ARCACHE,
		         S_AXI_ARPROT  => S_AXI_ARPROT,
		         S_AXI_RID     => S_AXI_RID,
		         S_AXI_RLAST   => S_AXI_RLAST);

	-- Clock generation
	clk <= not clk after clk_period / 2;

	S_AXI_ACLK <= clk;

	stimuli : process
--		declare the forwarding function of write and read, allows signals to be driven
		procedure AXI_write(
			data    : in std_logic_vector(31 downto 0);
			address : in std_logic_vector(31 downto 0)
		) is
		begin
			AXI_write(data, address, S_AXI_ACLK, S_AXI_WREADY, S_AXI_BVALID, S_AXI_WDATA, S_AXI_AWADDR, S_AXI_AWVALID, S_AXI_WVALID, S_AXI_BREADY);
		end AXI_write;

		procedure AXI_read(
			data    : out std_logic_vector(31 downto 0);
			address : in std_logic_vector(31 downto 0)
		) is
		begin
			AXI_read(data, address, S_AXI_ACLK, S_AXI_RVALID, S_AXI_ARADDR, S_AXI_ARVALID, S_AXI_RREADY);
		end AXI_read;

		procedure AXI_Reset_NoC is
		begin
			AXI_write(x"00000001", x"00000000");
			wait for 100 ns;
			AXI_write(x"00000000", x"00000000");
		end AXI_Reset_NoC;

		procedure AXI_Debug_Broadcast(
			data : in std_logic_vector(8 downto 0)
		) is
	begin
			AXI_write(x"00000000", x"00000024");
			AXI_write(std_logic_vector(resize(unsigned(data), 32)), x"00000028");
			AXI_write(x"00000001", x"0000002C");
			AXI_write(x"00000000", x"0000002C");
			
			
		end AXI_Debug_Broadcast;
		
		procedure Node_Debug_Sel(
			node       : in integer;
			destn_addr : in integer
		) is
		begin
			AXI_write(std_logic_vector(to_unsigned(node, 32)), x"00000020");
			AXI_write(std_logic_vector(to_unsigned(destn_addr, 32)), x"00000024");
		end procedure Node_Debug_Sel;
		
		
		procedure Node_debug_Spinlock(value : std_logic_vector(31 downto 0))
		is
			variable read_data : std_logic_vector(31 downto 0);
		begin
			read_data := (others => '-');
			while read_data /= value loop
				AXI_read(read_data, x"00000028");
			end loop;
		
			
		end procedure Node_debug_Spinlock;
		
		procedure Node_intel_valid_Spinlock(value : std_logic)
		is
			variable read_data : std_logic_vector(31 downto 0);
		begin
			read_data := (others => '-');
			while read_data(8) /= value loop
				AXI_read(read_data, x"00000028");
			end loop;
		
			
		end procedure Node_intel_valid_Spinlock;
		
		
		
		
		procedure Intel_WR_byte (
			data       : in std_logic_vector(7 downto 0);
			addr : in std_logic_vector(7 downto 0)
		) is
		begin
			--address with valid raised		
			AXI_write(x"000001" & addr, x"00000028");
			Node_intel_valid_Spinlock('1');
			
			--data with valid dropped		
			AXI_write(x"000000" & data, x"00000028");
			Node_intel_valid_Spinlock('0');
			
		end procedure Intel_WR_byte;
		
		procedure Router_WR_byte (
			data       : in std_logic_vector(7 downto 0)
		) is
		begin
			--data with valid raised		
			AXI_write(x"000001" & data, x"00000028");
			Node_intel_valid_Spinlock('1');
			
			--data with valid dropped		
			AXI_write(x"000000" & data, x"00000028");
			Node_intel_valid_Spinlock('0');
			
		end procedure Router_WR_byte;
		
		procedure Intel_WR_instruction (
			data : in std_logic_vector(19 downto 0);
			addr : in std_logic_vector(11 downto 0)
		) is
		begin
			--write the address
			Intel_WR_byte(addr(7 downto 0), x"60");
			Intel_WR_byte("0000" & addr(11 downto 8), x"61");
			
			--write the data
			Intel_WR_byte(data(7 downto 0), x"62");
			Intel_WR_byte(data(15 downto 8), x"63");
			Intel_WR_byte("000000" & data(17 downto 16), x"64");
			
			--strobe the write
			Intel_WR_byte(x"01", x"06");
			Intel_WR_byte(x"00", x"06");
			
		end procedure Intel_WR_instruction;
		
		
		procedure Router_WR_SPM (
			node : in integer;
			addr : in std_logic_vector(7 downto 0);
			data : in std_logic_vector(7 downto 0)
		) is
	begin
			--set the src to router bus 
			 Node_Debug_Sel(node, 2);
			 --interrupt the node
			 AXI_write(x"00000001", x"0000002C");
			 AXI_write(x"00000000", x"0000002C");
			
			--set SPM write mode
			Router_WR_byte(x"02");

			--write the address
			Router_WR_byte(addr);
			
			--write the data
			Router_WR_byte(data);
			
		end procedure Router_WR_SPM;
	

		
				
		procedure Node_Write_Debug_Safe(
			data : in std_logic_vector(7 downto 0)
			
		) is
		begin
			--Write the data with SW valid raised
			AXI_write(x"000001" & data, x"00000028");
			--wait for remote end to match
			Node_debug_Spinlock(x"000001" & data);			 
			--Drop the valid flag the data with SW valid raised
			AXI_write(x"000000" & data, x"00000028");
			--Wait for far end to drop their valid flag
			Node_debug_Spinlock(x"000000" & data);
		end procedure Node_Write_Debug_Safe;
		
		procedure Node_RDO_Byte_Set(
			node : in integer;
			object_index : in integer;
			data : in std_logic_vector(7 downto 0)
			) is
		begin
			--select the node and node debug mode
			Node_Debug_Sel(node, 1);	
			
			--raise the interrupt on the node
			AXI_write(x"00000001", x"0000002C");
			--wait for xAB to show that the node has entered the interrupt handler
			Node_debug_Spinlock(x"000000AB");
			--write the set RDO command
			Node_Write_Debug_Safe(x"01");
			--write the RDO index
			Node_Write_Debug_Safe(std_logic_vector(to_unsigned(object_index, 8)));
			--write the RDO size in bytes
			Node_Write_Debug_Safe(std_logic_vector(to_unsigned(1, 8)));
			--write the value 
			Node_Write_Debug_Safe(data);
			
			--clear the interrupt on the node
			AXI_write(x"00000000", x"0000002C");
			
			--Put the nodes back into broadcast mode
			Node_Debug_Sel(node, 0);	
			
		end procedure Node_RDO_Byte_Set;


	begin
		-- Reset generation
		S_AXI_ARESETN <= '0';
		wait for 100 ns;
		S_AXI_ARESETN <= '1';
		wait for 100 ns;

		AXI_Reset_NoC;
		wait for 1000 ns;

		AXI_Debug_Broadcast("0" & x"FE");
		Node_debug_Spinlock(x"00000053");
		--Node_RDO_Byte_Set(1, 0, x"DE");
		
		wait for 5 us;
		
--		Router_WR_SPM(0, x"20", x"AB");	
--		Router_WR_SPM(0, x"21", x"CD");	
--		Router_WR_SPM(0, x"22", x"EF");	
--		Router_WR_SPM(0, x"23", x"55");	
--		Router_WR_SPM(0, x"24", x"AA");	
--		Router_WR_SPM(0, x"25", x"AE");
--		Router_WR_SPM(0, x"26", x"BA");
--		Router_WR_SPM(3, x"25", x"DD");		
		
		
		--AXI_write(x"00000010", x"00000030");		
		
		

		wait;
	end process;

end tb;
