-- Max of 8 control

library ieee;
use ieee.std_logic_1164.all;

entity max8_control is
    port(
        clk, rst_n, start : in std_logic;
        last_sample : in std_logic;
        clr, running, valid : out std_logic
    );
end entity;

architecture rtl of max8_control is
    type state_t is (IDLE, RUN, DONE);
    signal current_state, next_state : state_t;

begin

    -- State Reg
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- next state & output logic
    process(all)
    begin
        next_state <= current_state;
        clr <= '0';
        running <= '0';
        valid <= '0';

        case current_state is
            when IDLE =>
                if start = '1' then 
                    next_state <= RUN;
                    clr <= '1';
                end if;
            when RUN =>
                running <= '1';
                if last_sample = '1' then
                    next_state <= DONE;
                end if;
            when DONE =>
                valid <= '1';
                next_state <= IDLE;
        end case;
    end process;

end architecture;


