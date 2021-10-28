library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
 
package centurion_pkg is
	constant ROUTER_DATA_WIDTH  : integer                                          := 8;
	constant ROUTER_SOP_INDEX   : integer                                          := ROUTER_DATA_WIDTH - 1;
	constant ROUTER_SOP_MASK    : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0) := x"C0";
	constant ROUTER_SOP_PACKET  : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0) := x"80";
	constant ROUTER_SOPN_PACKET : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0) := x"C0";
	constant ROUTER_SOPE_PACKET : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0) := x"C1";
	constant ROUTER_SOPS_PACKET : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0) := x"C2";
	constant ROUTER_SOPW_PACKET : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0) := x"C3";
	constant ROUTER_SOPI_PACKET : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0) := x"C4";
	constant ROUTER_SOPR_PACKET : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0) := x"C5";

	constant ROUTER_TABLE_UPDATE_PACKET : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0) := 	x"0A";
	constant INTEL_CONFIG_PACKET : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0) := 	x"0B";

	constant ROUTER_ROUTING_TABLE_WIDTH_LOG2 : integer := 2;	--table is 4 deep
	constant ROUTER_TABLE_LEN : integer := 32;
	constant ROUTER_TABLE_LEN_log2 : integer := 5;
	

	constant ROUTER_EOP_PACKET : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0) := x"7F";
	constant NUM_TASKS         : integer                                          := 4; --TODO: Move to project config
	constant NUM_TASKS_Log2    : integer                                          := integer(log2(real(NUM_TASKS)));
	constant THRESHOLD_WIDTH : integer := 6;
	constant ROUTER_RCAP_NUM_REGS : integer := 3;	
	
	constant DIVIDER_COUNTER_WIDTH : integer := 5;

	constant NUM_PORTS : integer := 6;
	
	constant PACKET_ID_LENGTH : integer := 16;
	constant RO_TEMP_WIDTH_OUT : integer := 16;

	constant TIMER_WIDTH : integer := 4;
	type timer_array is array(0 to NUM_PORTS -2) of unsigned(TIMER_WIDTH-1 downto 0);
	
	type packet_id_array is array(integer range <>) of unsigned(PACKET_ID_LENGTH-1 downto 0);
	
	type router_in_port is record
		data_in     : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0);
		control_sel : std_logic;
		data_valid  : std_logic;
		rd_en       : std_logic;
	end record router_in_port;

	type router_out_port is record
		data_out    : std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0);
		control_sel : std_logic;
		data_valid  : std_logic;
		rd_en       : std_logic;
	end record router_out_port;

	type router_direction is (North, East, South, West, Internal, RCAP, Idle);

	type data_ports_array is array (integer range <>) of std_logic_vector(ROUTER_DATA_WIDTH - 1 downto 0);
	type routing_dir_array is array (integer range <>) of router_direction;
	
	

	function dir_to_vector(dir : router_direction) return std_logic_vector;
	function vector_to_dir(vec : std_logic_vector(2 downto 0)) return router_direction;
	function dir_to_int(dir : router_direction) return integer;
	function log2( i : natural) return integer;

end package centurion_pkg;

package body centurion_pkg is
	function dir_to_vector(dir : router_direction) return std_logic_vector is
	begin
		case dir is
			when North    => return "000";
			when East     => return "001";
			when South    => return "010";
			when West     => return "011";
			when Internal => return "100";
			when RCAP 	  => return "101"; 
			when Idle	  => return "111";
		end case;
	end;

	function vector_to_dir(vec : std_logic_vector(2 downto 0)) return router_direction is
	begin
		case vec is
			when "000" => return North;
			when "001" => return East;
			when "010" => return South;
			when "011" => return West;
			when "100" => return Internal;
			when "101" => return RCAP;
			when "111" => return Idle;
			when others => return Internal;
		end case;
	end;

	function dir_to_int(dir : router_direction) return integer is
	begin
		case dir is
			when North    => return 0;
			when East     => return 1;
			when South    => return 2;
			when West     => return 3;
			when Internal => return 4;
			when RCAP	  => return 5;
			when others   => return 4;
		end case;
	end;

--shamelessly stolen from http://www.edaboard.com/thread186363.html
function log2( i : natural) return integer is
    variable temp    : integer := i;
    variable ret_val : integer := 1; 
  begin					
    while temp > 1 loop
      ret_val := ret_val + 1;
      temp    := temp / 2;     
    end loop;
  	
    return ret_val;
  end function;
end;
