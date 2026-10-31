library ieee;
use ieee.std_logic_1164.all;

entity latch_test is
    port (enable, data_in : in std_logic; data_out : out std_logic);
end entity;

architecture rtl of latch_test is
begin
    process(all)
    begin
        if enable = '1' then
            data_out <= data_in;   -- no else, no default: a latch
        end if;
    end process;
end architecture;