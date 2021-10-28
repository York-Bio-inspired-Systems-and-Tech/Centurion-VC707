library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;

library STD;
use STD.TEXTIO.all;

library centurion;
use centurion.centurion_pkg.all;


library unisim;
use unisim.vcomponents.all;



entity picoblaze_BRAM is
	generic(
		RAM_DEPTH : integer := 1024;
		RAM_ADDR_WIDTH : integer := 12;
		RAM_WIDTH : integer := 18;
      	ROM_FILE : string;           -- ROM memory contents in .mem or .hex format
        STYLE    : string := "BLOCK" -- Set to "DISTRIBUTED" to use distributed RAM
	);
	port (
		clk_a : in std_logic;
		en_a : in std_logic;
		addr_a : in std_logic_vector(RAM_ADDR_WIDTH -1 downto 0);
		dout_a : out std_logic_vector(RAM_WIDTH -1 downto 0);
		
		wr_en_b : in std_logic;
		addr_b : in std_logic_vector(RAM_ADDR_WIDTH -1 downto 0);
		din_b : in std_logic_vector(RAM_WIDTH -1 downto 0);
		dout_b : out std_logic_vector(RAM_WIDTH -1 downto 0)
		
	);
end entity picoblaze_BRAM;


architecture rtl of picoblaze_BRAM is
  type rom_mem is array (0 to RAM_DEPTH-1) of bit_vector(RAM_WIDTH-1 downto 0);

  impure function read_mem_file(File_name: string) return rom_mem is
    -- Read a .mem or .hex file as produced by KCPSM3 and KCPSM6 assemblers
    
-- synthesis translate_off

    file fh       : text open read_mode is File_name;
    variable ln   : line;
    variable word : std_logic_vector(RAM_WIDTH-1 downto 0);

-- synthesis translate_on

    variable rom  : rom_mem;

    procedure read_hex(ln : inout line; hex : out std_logic_vector) is
      -- The hread() procedure doesn't work well when the target bit vector
      -- is not a multiple of four. This wrapper provides better behavior.
      variable hex4 : std_logic_vector(((hex'length + 3) / 4) * 4 - 1 downto 0);
    begin
      hread(ln, hex4);
      hex := hex4(hex'length-1 downto 0); -- Trim upper bits
    end procedure;

    -- Convert a string to lower case
    function to_lower( source : string ) return string is
      variable r : string(source'range) := source;
    begin
      for c in r'range loop
        if character'pos(r(c)) >= character'pos('A')
            or character'pos(r(c)) <= character'pos('Z') then

          -- This would work except that XST has regressed into not supporting
          -- character'val. Presumably this is "fixed" in Vivado and will never get
          -- corrected in poor old XST.
          r(c) := character'val(character'pos(r(c)) + 16#20#);
        end if;
      end loop;

      return r;
    end function;
  begin

-- synthesis translate_off

    -- Can't call to_lower() for case-insensitive comparison because of XST limitation
    --if to_lower(File_name(File_name'length-3 to File_name'length)) = ".mem" then
    if File_name(File_name'length-3 to File_name'length) = ".mem" then
      -- Read the first address line of a .mem file and discard it
      -- Assume memory starts at 0
      readline(fh, ln);
    end if;


    -- XST isn't happy with a while loop because of its low default iteration limit setting
    -- so we have to use a for loop.
    for addr in 0 to RAM_DEPTH-1 loop
      if endfile(fh) then
        exit;
      end if;

      readline(fh, ln);

      read_hex(ln, word); -- Convert hex string to bits
      rom(addr) := to_bitvector(word);

    end loop;

-- synthesis translate_on

    return rom;
  end function;

  -- Initialize ROM with file contents
  signal pb_rom : rom_mem := read_mem_file(ROM_FILE);
  
  --extra regs on the the b side to help timing (extra latency not critical as this is a slow control path).
  signal b_reg_in :std_logic_vector(RAM_WIDTH -1 downto 0);
  signal b_reg_out :std_logic_vector(RAM_WIDTH -1 downto 0);

  attribute RAM_STYLE : string;
  attribute RAM_STYLE of pb_rom : signal is STYLE;
begin



  -- Infer ROM with synchronous enable and dual read port
  rd: process(clk_a)
  begin
    if rising_edge(clk_a) then
      if en_a = '1' then
        -- Read port 1
        dout_a  <= to_stdlogicvector(pb_rom(to_integer(unsigned(addr_a))));

        -- Read/write port 2
        b_reg_out <= to_stdlogicvector(pb_rom(to_integer(unsigned(addr_b))));
        dout_b <= b_reg_out;
        b_reg_in <= din_b;
        if wr_en_b = '1' then
          pb_rom(to_integer(unsigned(addr_b))) <= to_bitvector(b_reg_in);
        end if;
      end if;
    end if;
  end process;

end architecture;

-- architecture RTL of picoblaze_BRAM is
-- 	
-- 
-- signal  address_a : std_logic_vector(13 downto 0);
-- signal  data_in_a : std_logic_vector(17 downto 0);
-- signal data_out_a : std_logic_vector(17 downto 0);
-- signal  address_b : std_logic_vector(13 downto 0);
-- signal  data_in_b : std_logic_vector(17 downto 0);
-- signal data_out_b : std_logic_vector(17 downto 0);
-- signal   enable_b : std_logic;
-- 
-- signal       we_b : std_logic_vector(3 downto 0);
-- 
-- begin
-- 
--  address_a <= addr_a(9 downto 0) & "1111";
--  address_b <= addr_b(9 downto 0) & "1111";
--  we_b <= "1111" when wr_en_b  = '1' else "0000";
-- 	
--   kcpsm6_rom: RAMB18E1
--   generic map ( READ_WIDTH_A => 18,
--                 WRITE_WIDTH_A => 18,
--                 DOA_REG => 0,
--                 INIT_A => "000000000000000000",
--                 RSTREG_PRIORITY_A => "REGCE",
--                 SRVAL_A => X"000000000000000000",
--                 WRITE_MODE_A => "WRITE_FIRST",
--                 READ_WIDTH_B => 18,
--                 WRITE_WIDTH_B => 18,
--                 DOB_REG => 0,
--                 INIT_B => X"000000000000000000",
--                 RSTREG_PRIORITY_B => "REGCE",
--                 SRVAL_B => X"000000000000000000",
--                 WRITE_MODE_B => "WRITE_FIRST",
--                 INIT_FILE => "NONE",
--                 SIM_COLLISION_CHECK => "ALL",
--                 RAM_MODE => "TDP",
--                 RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
--                 SIM_DEVICE => "7SERIES",
--                INIT_00 => X"F012F011F0101006F0051020F0041010F0031008F0021004F0011002F0001001",
--                 INIT_01 => X"C0A0A080380F8800006010202042C70090106031C790170116001900F014F013",
--                 INIT_02 => X"D731C61001801110D0301000D030E81001601110C8100160112049704A006031",
--                 INIT_03 => X"A100C31001001110C310016011201307A0100160111069702042C70090112042",
--                 INIT_04 => X"00000000000000000000000000000000000020132015D72047061601D9316A10",
--                 INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
--                 INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
--                INITP_00 => X"00000000000000000000000000002C58249010C2A48A4903004C300AA8888888",
--                INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
--                INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")
--   port map(   ADDRARDADDR => address_a,
--                   ENARDEN => en_a,
--                 CLKARDCLK => clk_a,
--                     DOADO => dout_a(15 downto 0),
--                   DOPADOP => dout_a(17 downto 16), 
--                     DIADI => (others => '0'),
--                   DIPADIP => (others => '0'), 
--                       WEA => "00",
--               REGCEAREGCE => '0',
--             RSTRAMARSTRAM => '0',
--             RSTREGARSTREG => '0',
--               ADDRBWRADDR => address_b,
--                   ENBWREN => en_b,
--                 CLKBWRCLK => clk_b,
--                     DOBDO => dout_b(15 downto 0),
--                   DOPBDOP => dout_b(17 downto 16), 
--                     DIBDI => din_b(15 downto 0),
--                   DIPBDIP => din_b(17 downto 16), 
--                     WEBWE => we_b,
--                    REGCEB => '0',
--                   RSTRAMB => '0',
--                   RSTREGB => '0');
-- 
-- 
-- 
-- end architecture RTL;
