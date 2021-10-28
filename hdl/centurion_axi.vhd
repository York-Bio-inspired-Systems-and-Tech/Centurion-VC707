-------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library centurion;
use centurion.centurion_pkg.all;



entity centurion_axi is
generic(
		-- ADD USER GENERICS BELOW THIS LINE ---------------
		NOC_WIDTH : integer := 8;
		NOC_HEIGHT : integer := 8;
		NOC_NUM_NODES_LOG2 : integer := 6;
		-- ADD USER GENERICS ABOVE THIS LINE ---------------
		C_S_AXI_DATA_WIDTH     : integer := 32;
		C_S_AXI_ADDR_WIDTH     : integer := 32;
		C_S_AXI_ID_WIDTH       : integer := 4;
		C_RDATA_FIFO_DEPTH     : integer := 0;
		C_INCLUDE_TIMEOUT_CNT  : integer := 0;
		C_TIMEOUT_CNTR_VAL     : integer := 8;
		C_ALIGN_BE_RDADDR      : integer := 0;
		C_S_AXI_SUPPORTS_WRITE : integer := 1;
		C_S_AXI_SUPPORTS_READ  : integer := 1
	-- DO NOT EDIT ABOVE THIS LINE ---------------------
	);
	port(
		-- ADD USER PORTS BELOW THIS LINE ------------------
		--USER ports added here

		UART_node_tx : out std_logic;

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
end entity centurion_axi;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of centurion_axi is

    constant NOC_NUM_NODES : integer := NOC_WIDTH * NOC_HEIGHT;
    
	signal NoC_if_Out_Port  : router_in_port;
	signal NoC_if_in_Port :  router_out_port;
	signal NoC_reset : std_logic;

	--RTC
	signal RTC_value : std_logic_vector(31 downto 0);

	--Node debug interface
	signal Debug_Node_sel : std_logic_vector(NOC_NUM_NODES_LOG2 -1 downto 0);
	signal Debug_Node_UART_sel :  std_logic_vector(NOC_NUM_NODES_LOG2 -1 downto 0);
	signal Debug_Node_src_sel : std_logic_vector(1 downto 0);
	signal Debug_command_Broadcast : std_logic;
	signal Debug_Node_debug_value :  std_logic_vector(8 downto 0);
	signal Debug_command :  std_logic_vector(8 downto 0);
	signal Debug_command_valid :  std_logic;
	signal Debug_HS_download_en :  std_logic;
	signal Debug_HS_upload_en :  std_logic;
	

begin


centurion_inst : ENTITY centurion.centurion_V2 
generic map(
		NOC_WIDTH => NOC_WIDTH,
		NOC_HEIGHT => NOC_HEIGHT,
		NOC_NUM_NODES_LOG2 => NOC_NUM_NODES_LOG2
)
port map (
       
    NoC_clk => S_AXI_ACLK, 
    NoC_reset => noc_reset,
	UART_node_tx => UART_node_tx,
	
	NoC_if_Out_Port => NoC_if_Out_Port,
    NoC_if_in_Port => NoC_if_in_Port,
    
    --RTC
    RTC_value => RTC_value,
    
    --Node debug interface
    Debug_Node_sel => Debug_Node_sel,
    Debug_Node_src_sel => Debug_Node_src_sel,
    Debug_Node_UART_sel => Debug_Node_UART_sel,  
    Debug_Node_debug_value_out => Debug_Node_debug_value,
    Debug_command_in => Debug_command,
    Debug_command_interrupt_in => Debug_command_valid,
    Debug_HS_download_en => Debug_HS_download_en,
    Debug_HS_upload_en => Debug_HS_upload_en
		 
	 );




axi_cntrl_inst : entity centurion.noc_if_axi 
generic map(
		NOC_NUM_NODES_LOG2 => NOC_NUM_NODES_LOG2
	)
	port map(
		NoC_Out_Port  => NoC_if_Out_Port,
		NoC_in_Port => NoC_if_in_Port,
		NoC_reset => noc_reset,
		--RTC
		RTC_value => RTC_value,
		
		--Node debug interface
		Debug_Node_sel => Debug_Node_sel,
    	Debug_Node_src_sel => Debug_Node_src_sel,
		Debug_Node_UART_sel => Debug_Node_UART_sel,
		Debug_Node_debug_value => Debug_Node_debug_value,
		Debug_command_out => Debug_command,
		Debug_command_valid => Debug_command_valid,
		Debug_HS_download_en => Debug_HS_download_en,
		Debug_HS_upload_en => Debug_HS_upload_en,
		
		IRQ => open,

		-- ADD USER PORTS ABOVE THIS LINE ------------------

		-- DO NOT EDIT BELOW THIS LINE ---------------------
		-- Bus protocol ports, do not add to or delete
		S_AXI_ACLK      =>    S_AXI_ACLK,
		S_AXI_ARESETN   =>    S_AXI_ARESETN,
		S_AXI_AWADDR    =>    S_AXI_AWADDR,   
		S_AXI_AWVALID   =>    S_AXI_AWVALID,   
		S_AXI_WDATA     =>    S_AXI_WDATA,     
		S_AXI_WSTRB     =>    S_AXI_WSTRB,     
		S_AXI_WVALID    =>    S_AXI_WVALID,    
		S_AXI_BREADY    =>    S_AXI_BREADY,    
		S_AXI_ARADDR    =>    S_AXI_ARADDR,    
		S_AXI_ARVALID   =>    S_AXI_ARVALID,   
		S_AXI_RREADY    =>    S_AXI_RREADY,    
		S_AXI_ARREADY   =>    S_AXI_ARREADY,   
		S_AXI_RDATA     =>    S_AXI_RDATA,     
		S_AXI_RRESP     =>    S_AXI_RRESP,     
		S_AXI_RVALID    =>    S_AXI_RVALID,    
		S_AXI_WREADY    =>    S_AXI_WREADY,    
		S_AXI_BRESP     =>    S_AXI_BRESP,     
		S_AXI_BVALID    =>    S_AXI_BVALID,    
		S_AXI_AWREADY   =>    S_AXI_AWREADY,   
		S_AXI_AWID      =>    S_AXI_AWID,      
		S_AXI_AWLEN     =>    S_AXI_AWLEN,     
		S_AXI_AWSIZE    =>    S_AXI_AWSIZE,    
		S_AXI_AWBURST   =>    S_AXI_AWBURST,   
		S_AXI_AWLOCK    =>    S_AXI_AWLOCK,    
		S_AXI_AWCACHE   =>    S_AXI_AWCACHE,   
		S_AXI_AWPROT    =>    S_AXI_AWPROT,   
		S_AXI_WLAST     =>    S_AXI_WLAST,     
		S_AXI_BID       =>    S_AXI_BID,       
		S_AXI_ARID      =>    S_AXI_ARID,      
		S_AXI_ARLEN     =>    S_AXI_ARLEN,     
		S_AXI_ARSIZE    =>    S_AXI_ARSIZE,    
		S_AXI_ARBURST   =>    S_AXI_ARBURST,   
		S_AXI_ARLOCK    =>    S_AXI_ARLOCK,    
		S_AXI_ARCACHE   =>    S_AXI_ARCACHE,   
		S_AXI_ARPROT    =>    S_AXI_ARPROT,    
		S_AXI_RID       =>    S_AXI_RID,       
		S_AXI_RLAST     =>    S_AXI_RLAST     
	-- DO NOT EDIT ABOVE THIS LINE ---------------------
	);
	
	

	
end IMP;

