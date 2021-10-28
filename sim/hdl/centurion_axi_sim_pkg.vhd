library ieee;
use ieee.std_logic_1164.all;

package centurion_axi_sim_pkg is


	constant	C_S_AXI_DATA_WIDTH     : integer := 32;
	constant	C_S_AXI_ADDR_WIDTH     : integer := 32;
	constant	C_S_AXI_ID_WIDTH       : integer := 4;
	constant	C_RDATA_FIFO_DEPTH     : integer := 0;
	constant	C_INCLUDE_TIMEOUT_CNT  : integer := 0;
	constant	C_TIMEOUT_CNTR_VAL     : integer := 8;
	constant	C_ALIGN_BE_RDADDR      : integer := 0;
	constant	C_S_AXI_SUPPORTS_WRITE : integer := 1;
	constant	C_S_AXI_SUPPORTS_READ  : integer := 1;

        
	--global AXI signals
	signal S_AXI_ACLK    : std_logic := '1';
    signal S_AXI_ARESETN : std_logic := '0';
    signal S_AXI_AWADDR  : std_logic_vector (c_s_axi_addr_width - 1 downto 0) := (others => '0'); 
    signal S_AXI_AWVALID : std_logic := '0';
    signal S_AXI_WDATA   : std_logic_vector (c_s_axi_data_width - 1 downto 0) := (others => '0');
    signal S_AXI_WSTRB   : std_logic_vector ((c_s_axi_data_width / 8) - 1 downto 0) := (others => '0');
    signal S_AXI_WVALID  : std_logic := '0';
    signal S_AXI_BREADY  : std_logic := '0';
    signal S_AXI_ARADDR  : std_logic_vector (c_s_axi_addr_width - 1 downto 0) := (others => '0');
    signal S_AXI_ARVALID : std_logic := '0';
    signal S_AXI_RREADY  : std_logic := '0';
    signal S_AXI_ARREADY : std_logic := '0';
    signal S_AXI_RDATA   : std_logic_vector (c_s_axi_data_width - 1 downto 0) := (others => '0');
    signal S_AXI_RRESP   : std_logic_vector (1 downto 0) := (others => '0');
    signal S_AXI_RVALID  : std_logic := '0';
    signal S_AXI_WREADY  : std_logic := '0';
    signal S_AXI_BRESP   : std_logic_vector (1 downto 0) := (others => '0');
    signal S_AXI_BVALID  : std_logic := '0';
    signal S_AXI_AWREADY : std_logic := '0';
    signal S_AXI_AWID    : std_logic_vector (c_s_axi_id_width - 1 downto 0) := (others => '0');
    signal S_AXI_AWLEN   : std_logic_vector (7 downto 0) := (others => '0');
    signal S_AXI_AWSIZE  : std_logic_vector (2 downto 0) := (others => '0');
    signal S_AXI_AWBURST : std_logic_vector (1 downto 0) := (others => '0');
    signal S_AXI_AWLOCK  : std_logic := '0';
    signal S_AXI_AWCACHE : std_logic_vector (3 downto 0) := (others => '0');
    signal S_AXI_AWPROT  : std_logic_vector (2 downto 0) := (others => '0');
    signal S_AXI_WLAST   : std_logic := '0';
    signal S_AXI_BID     : std_logic_vector (c_s_axi_id_width - 1 downto 0) := (others => '0');
    signal S_AXI_ARID    : std_logic_vector (c_s_axi_id_width - 1 downto 0) := (others => '0');
    signal S_AXI_ARLEN   : std_logic_vector (7 downto 0) := (others => '0');
    signal S_AXI_ARSIZE  : std_logic_vector (2 downto 0) := (others => '0');
    signal S_AXI_ARBURST : std_logic_vector (1 downto 0) := (others => '0');
    signal S_AXI_ARLOCK  : std_logic := '0';
    signal S_AXI_ARCACHE : std_logic_vector (3 downto 0) := (others => '0');
    signal S_AXI_ARPROT  : std_logic_vector (2 downto 0) := (others => '0');
    signal S_AXI_RID     : std_logic_vector (c_s_axi_id_width - 1 downto 0) := (others => '0');
    signal S_AXI_RLAST   : std_logic := '0';
    
    
     procedure AXI_write
	(
		data : in std_logic_vector(31 downto 0);
		address : in std_logic_vector(31 downto 0);
		
		signal S_AXI_ACLK : in std_logic;
		signal S_AXI_WREADY  : std_logic;
		signal S_AXI_BVALID  : in std_logic;
		
		signal S_AXI_WDATA : out std_logic_vector (c_s_axi_data_width - 1 downto 0);
		signal S_AXI_AWADDR  : out std_logic_vector (c_s_axi_addr_width - 1 downto 0) ;
    	signal S_AXI_AWVALID : out std_logic;
    	signal S_AXI_WVALID  : out std_logic;
    	signal S_AXI_BREADY  : out std_logic
				
	) ;
	
	procedure AXI_read
	(
		data : out std_logic_vector(31 downto 0);
		address : in std_logic_vector(31 downto 0);
		
		signal S_AXI_ACLK : in std_logic;
		signal S_AXI_RVALID  : in std_logic;
		
		signal S_AXI_ARADDR  : out std_logic_vector (c_s_axi_addr_width - 1 downto 0) ;
    	signal S_AXI_ARVALID : out std_logic;
    	signal S_AXI_RREADY  : out std_logic
				
	);
	
end package centurion_axi_sim_pkg;

package body centurion_axi_sim_pkg is

  procedure AXI_write
	(
		data : in std_logic_vector(31 downto 0);
		address : in std_logic_vector(31 downto 0);
		
		signal S_AXI_ACLK : in std_logic;
		signal S_AXI_WREADY  : std_logic;
		signal S_AXI_BVALID  : in std_logic;
		
		signal S_AXI_WDATA : out std_logic_vector (c_s_axi_data_width - 1 downto 0);
		signal S_AXI_AWADDR  : out std_logic_vector (c_s_axi_addr_width - 1 downto 0) ;
    	signal S_AXI_AWVALID : out std_logic;
    	signal S_AXI_WVALID  : out std_logic;
    	signal S_AXI_BREADY  : out std_logic
				
	) is
			
	begin
        S_AXI_WDATA <= data;
        S_AXI_AWADDR <= address;
		wait until S_AXI_ACLK= '0';
            S_AXI_AWVALID<='1';
            S_AXI_WVALID<='1';
        wait until S_AXI_WREADY = '1';  --Ready to read address/data        
            S_AXI_BREADY<='1';
        wait until S_AXI_BVALID = '1';  -- Write result valid
            assert S_AXI_BRESP = "00" report "AXI data not written" severity failure;
            S_AXI_AWVALID<='0';
            S_AXI_WVALID<='0';
            S_AXI_BREADY<='1';
        wait until S_AXI_BVALID = '0';  -- All finished
            S_AXI_BREADY<='0';
	
        S_AXI_WDATA <= x"DEADBEEF";
        S_AXI_AWADDR <= x"CAFEBABE";
	
		end procedure AXI_write;
    
      procedure AXI_read
	(
		data : out std_logic_vector(31 downto 0);
		address : in std_logic_vector(31 downto 0);
		
		signal S_AXI_ACLK : in std_logic;
		signal S_AXI_RVALID  : in std_logic;
		
		signal S_AXI_ARADDR  : out std_logic_vector (c_s_axi_addr_width - 1 downto 0) ;
    	signal S_AXI_ARVALID : out std_logic;
    	signal S_AXI_RREADY  : out std_logic
				
	) is
			
	begin
         
        S_AXI_ARVALID<='0';
    	S_AXI_RREADY<='0';
    	S_AXI_ARADDR <= address;
		wait until S_AXI_ACLK= '0';
             S_AXI_ARVALID<='1';
             S_AXI_RREADY<='1';
        wait until S_AXI_ARREADY = '1';  --Ready to read address/data       
        wait until S_AXI_RVALID = '1';  -- Write result valid
            assert S_AXI_RRESP = "00" report "AXI data not read" severity failure;
            S_AXI_ARVALID<='0';
            S_AXI_RREADY<='1';
        
        data := S_AXI_RDATA;
    
		end procedure AXI_read;
	
end package body centurion_axi_sim_pkg;
