-- Avg N Control

library ieee;
use ieee.std_logic_1164.all;

entity avgN_control is
    port(
        clk, rst_n : in std_logic;
        start : in std_logic;
        last_sample : in std_logic;
        valid : out std_logic;
        clr, running : out std_logic
    );
end entity;

architecture rtl of avgN_control is
    type state_t is (IDLE, RUN, DONE);
    signal current_state, next_state : state_t;

begin
    -- state reg (clocked)
    State_Reg : process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;


    -- next state and output logic (combinational)
    next_state_logic : process(all)
    begin
        next_state <= current_state;
        clr <= '0';
        running <= '0';
        valid <= '0';

        case current_state is
            when IDLE =>
                if start = '1' then
                    clr <= '1';
                    next_state <= RUN;
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