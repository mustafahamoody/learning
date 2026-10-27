-- TB for avg 4

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_avg4 is
end entity;

architecture sim of tb_avg4 is
    -- Inputs (Driven by Sim: Initialized)
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal start : std_logic := '0';
    signal din : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Outputs (Driven by DUT: Uninitialized)
    signal valid : std_logic;
    signal avg_out : std_logic_vector(7 downto 0);

begin 

    -- Clock (flips every 5 ns, so the period is 10 ns)
    clk <= not clk after 5 ns;

    -- DUT
    dut : entity work.avgN_top
    port map (
        -- inputs
        clk => clk,
        rst_n => rst_n,
        start => start,
        din => din,

        -- outputs
        valid => valid,
        avg_out => avg_out
    );

    --- Stimulus: runs top to bottom, like software
    stimulus : process
    variable a : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(10, 8));
    variable b : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(20, 8));
    variable c : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(30, 8));
    variable d : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(40, 8));
    variable expected : integer := 0; -- What avg_out should be
    begin
        -- Hold reset for 2 clock cycles (20 ns)
        rst_n <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        rst_n <= '1';

        -- Wait 3 cycles for rst_n to be deasseted (2-3 cycle delay from synchronizer)
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Pulse Start for 1 cycle
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';
        
        -- Drive a, b, c, d on din, one per clock
        din <= a;
        wait until rising_edge(clk);
        din <= b;
        wait until rising_edge(clk);
        din <= c;
        wait until rising_edge(clk);
        din <= d;
        wait until rising_edge(clk);

        -- Wait for valid, and report if hangs
        wait until valid = '1' for 100 ns;
        assert valid = '1'
            report "FAIL: valid never rose (timeout after 100 ns)"
            severity FAILURE;

        wait for 1 ns; -- Always wait for 1 ns before read

        -- Check avg_out matches expected and report if not
        expected := ((to_integer(unsigned(a)) + to_integer(unsigned(b)) + to_integer(unsigned(c)) + to_integer(unsigned(d))) / 4);
        assert to_integer(unsigned(avg_out)) = expected
            report "FAIL: avg_out doesen't match expected. " &
            "Expected: " & integer'image(expected) &
            ", Actual: " & integer'image(to_integer(unsigned(avg_out)))
            severity FAILURE;
        
        -- Report tests passed and stop simulation
        report "ALL TESTS PASSED";
        for i in 1 to 3 loop              -- a few extra cycles for the waveform
            wait until rising_edge(clk);
        end loop;
        std.env.finish; 
    end process;
end architecture;
