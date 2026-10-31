-- Avg N top

library ieee;
use ieee.std_logic_1164.all;

entity avgN_top is
    generic(
        DATA_WIDTH : positive := 8; -- Bits per sample
        LOG2_SAMPLES : positive := 2 -- samples = 2^LOG2_SAMPLES
    );
    port(
        clk, rst_n : in std_logic;
        start : in std_logic;
        din : in std_logic_vector(DATA_WIDTH-1 downto 0);
        valid : out std_logic;
        avg_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
    end entity;

architecture rtl of avgN_top is 
    signal rst_n_sync, clr, running, last_sample : std_logic;

begin
    reset : entity work.rst_n_synchronizer
        port map(
            --inputs
            rst_n_async => rst_n,
            clk => clk,

            -- outputs
            rst_n_sync => rst_n_sync
        );
    control : entity work.avgN_control
        port map(
            -- inputs
            clk => clk,
            rst_n => rst_n_sync,
            start => start,
            last_sample => last_sample,

            -- outputs
            valid => valid,
            clr => clr,
            running => running
        );

    datapath : entity work.avgN_datapath
            generic map(
                DATA_WIDTH => DATA_WIDTH,
                LOG2_SAMPLES => LOG2_SAMPLES
            )
            port map(
                -- inputs
                clk => clk,
                din => din,
                clr => clr,
                running => running,
                
                -- outputs
                last_sample => last_sample,
                avg_out => avg_out
            );

end architecture;