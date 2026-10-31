-- ICG Cell for course clock gating

library ieee;
use ieee.std_logic_1164.all;

entity icg_cell is
    port (
        clk : in std_logic;
        en : in std_logic;
        gated_clk : out std_logic
    );
end entity;

architecture rtl of icg_cell is
    signal latched_en : std_logic;
begin
    -- Delibrate Latch (captures on low)
    process(all)
    begin
        if clk = '0' then
            latched_en <= en; 
        end if;
    end process;

    gated_clk <= clk and latched_en;

end architecture;