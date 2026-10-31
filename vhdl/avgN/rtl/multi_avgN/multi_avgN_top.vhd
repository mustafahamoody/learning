-- Multiple (parallel) Avg N top

library ieee;
use ieee.std_logic_1164.all;
use work.types_pkg.all; -- to incluce slv array

entity multi_avgN_top is
    generic (
        DATA_WIDTH : positive := 8; -- Bits per sample
        LOG2_SAMPLES : positive := 2; -- samples = 2^LOG2_SAMPLES
        CHANNELS : positive := 5 -- avgN blocks to generate
    );
    port (
        clk, rst_n : in std_logic;
        start : in std_logic;
        din : in slv_array(CHANNELS-1 downto 0)(DATA_WIDTH-1 downto 0);
        valid : out std_logic;
        avg_out : out slv_array(CHANNELS-1 downto 0)(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of multi_avgN_top is
    signal rst_n_sync, clr, running, last_sample : std_logic;
    signal last_sample_vec : STD_LOGIC_VECTOR(CHANNELS-1 downto 0);
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
        port map (
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
    
    datapath : for channel in 0 to CHANNELS-1 generate
        avg_unit : entity work.avgN_datapath
                generic map (
                    DATA_WIDTH => DATA_WIDTH,
                    LOG2_SAMPLES => LOG2_SAMPLES
                )
                port map(
                    -- inputs
                    clk => clk,
                    clr => clr,
                    din => din(channel),
                    running => running,
                    
                    -- outputs
                    last_sample => last_sample_vec(channel),
                    avg_out => avg_out(channel)  
                );
    end generate;

        -- Assign first avg_units last_sample from datapath to control (control only takes one but datapath gives Channels #) 
        last_sample <= last_sample_vec(0);
end architecture;