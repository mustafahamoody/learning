-- Avg N datapath

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avgN_datapath is
    generic(
            DATA_WIDTH : positive := 8; -- Bits per sample (default 8)
            LOG2_SAMPLES : positive := 2 -- samples = 2^LOG2_SAMPLES (= 4). Forces # smaples to be power of 2
    );
    port(
        clk : in std_logic;
        clr, running : in std_logic;
        din : in std_logic_vector(DATA_WIDTH-1 downto 0);
        last_sample : out std_logic;
        avg_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of avgN_datapath is
    constant ACC_WIDTH : positive := DATA_WIDTH + LOG2_SAMPLES; -- With adder carry, max bit size of result is N + log2(K)
        -- constant LAST_SAMPLE_NUM : positive := 2**LOG2_SAMPLES; -- Purpose Mistake to use waveform to debug (last sample num=4, which should be 3 in 2 bin counter)
    constant LAST_SAMPLE_NUM : positive := 2**LOG2_SAMPLES - 1;
    
    signal acc_reg : unsigned(ACC_WIDTH-1 downto 0);
    signal cnt_reg : unsigned(LOG2_SAMPLES-1 downto 0);
begin
    -- Reg updates
    Reg_updates : process(clk)
    begin
        if rising_edge(clk) then
            if clr = '1' then
                acc_reg <= (others => '0');
                cnt_reg <= (others => '0');
            elsif running = '1' then
                acc_reg <= acc_reg + unsigned(din); -- Adder
                cnt_reg <= cnt_reg + 1;
            end if;
        end if;
    end process;

    -- Combinational flags
    last_sample <= '1' when cnt_reg = LAST_SAMPLE_NUM else '0'; -- Const comparator
    avg_out <= std_logic_vector(resize(shift_right(acc_reg, LOG2_SAMPLES), DATA_WIDTH)); -- Const divison by 2^LOG2_SAMPLES = shift right LOG2_SAMPLES bits, then needs to rezise acc_reg to DATA_WIDTH (match avg_out width)
    
end architecture;
