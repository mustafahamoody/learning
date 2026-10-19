-- Max of 8 datapath

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity max8_datapath is
    port(
        clk, clr, running : in std_logic;
        sample_in : in std_logic_vector(7 downto 0);
        last_sample : out std_logic;
        max_out : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of max8_datapath is
    signal is_greater : std_logic;
    signal max_reg : std_logic_vector(7 downto 0);
    signal cnt_reg : unsigned(2 downto 0);

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if clr = '1' then
                max_reg <= (others => '0');
                cnt_reg <= (others => '0');
            elsif running = '1' then
                if is_greater = '1' then
                    max_reg <= sample_in;
                end if;
                cnt_reg <= cnt_reg + 1;
            end if;
        end if;
    end process;

    is_greater <= '1' when unsigned(sample_in) > unsigned(max_reg) else '0';
    last_sample <= '1' when cnt_reg = 7 else '0';
    max_out <= max_reg;

end architecture;

