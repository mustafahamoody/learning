-- rst_n_synchronizer: async assert, sync deassert

library ieee;
use ieee.std_logic_1164.all;

entity rst_n_synchronizer is
    Port(
        rst_n_async : in std_logic;
        clk : in std_logic;
        rst_n_sync : out std_logic
    );
end entity;

architecture rtl of rst_n_synchronizer is
    signal rst_ff1, rst_ff2 : std_logic;
begin
    process(clk, rst_n_async)
    begin
        if rst_n_async = '0' then
            rst_ff1 <= '0';
            rst_ff2 <= '0';
        elsif rising_edge(clk) then
            rst_ff1 <= '1';
            rst_ff2 <= rst_ff1;
        end if;
    end process;

    rst_n_sync <= rst_ff2;
end architecture;