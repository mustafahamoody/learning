-- Max of 8 top

library ieee;
use ieee.std_logic_1164.all;

entity max8_top is
    port(
        clk, rst_n, start: in std_logic;
        sample_in : in std_logic_vector(7 downto 0);
        valid : out std_logic;
        max_out : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of max8_top is
    signal clr, running, last_sample : std_logic;
begin
    control : entity work.max8_control
        port map(
            -- inputs
            clk => clk,
            rst_n => rst_n,
            start => start,
            last_sample => last_sample,
            -- outputs
            clr => clr,
            valid => valid,
            running => running
        );

    datapath : entity work.max8_datapath
        port map(
            -- inputs
            clk => clk, 
            clr => clr,
            sample_in => sample_in,
            running => running,
            -- outputs
            last_sample => last_sample,
            max_out => max_out
        );

end architecture;


