-- Make paked array for each channel (Still systhesises to one big bus, but cleaner to write)

library ieee;
use ieee.std_logic_1164.all;


package types_pkg is
    type slv_array is array (natural range <>) of std_logic_vector; -- width left open to set using generics
end package; -- FORAMT: name: slv_array(how many)(width of ea.) 