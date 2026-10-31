-- TB for avgN

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_avgN is
    generic (
        DATA_WIDTH : positive := 8; -- Bits per sample
        LOG2_SAMPLES : positive := 2 -- samples = 2^LOG2_SAMPLES
    );
end entity;

architecture sim of tb_avgN is
    -- Inputs (Driven by Sim: Initialized)
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal start : std_logic := '0';
    signal din : std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Outputs (Driven by DUT: Uninitialized)
    signal valid : std_logic;
    signal avg_out : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    -- Clock (flips every 5ns: 10 ns period)
    clk <= not clk after 5 ns;

    -- DUT
    dut : entity work.avgN_top
    generic map(
        DATA_WIDTH => DATA_WIDTH,
        LOG2_SAMPLES => LOG2_SAMPLES
    )
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

    -- Stimulus: test(s) that run
    stimulus : process
        type int_arr is array (natural range <>) of integer;
        
        -- Procedure is like a function, so you can resue test easilty w. diff vals
        procedure run_avg(samples : in int_arr) is
            variable sum : integer := 0;
            variable expected : integer;
        begin
            -- start rst logic goes in stimulus (on startup), not procedure
            -- Check samples inputed in tb match hardware expected samples
            assert samples'length = 2**LOG2_SAMPLES
                report "TB ERROR: test list has " & integer'image(samples'length) &
                        " samples, the design expects " & integer'image(2**LOG2_SAMPLES)
                severity failure;

            -- Pulse Start for 1 cycle
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';

            -- Drive one input (on din) per clk cycle
            for i in samples'range loop
                din <= std_logic_vector(to_unsigned(samples(i), DATA_WIDTH));
                sum := sum + samples(i);
                wait until rising_edge(clk);
                
                -- -- Test pulse start while running
                -- start <= '1';
                -- wait until rising_edge(clk);
                -- start <= '0';
            end loop;

            -- Wait for valid, and report if hangs
            wait until valid = '1' for 100 ns;
            assert valid = '1'
                report "FAIL: valid never rose (timeout after 100 ns)"
                severity FAILURE;

            wait for 1 ns; -- Always wait for 1 ns before read

            -- Check avg_out matches expected and report if not
            expected := (sum / samples'length);
            assert to_integer(unsigned(avg_out)) = expected
                report "FAIL: avg_out doesen't match expected. " &
                "Expected: " & integer'image(expected) &
                ", Actual: " & integer'image(to_integer(unsigned(avg_out)))
                severity FAILURE;

            -- Pass for this procedure run
            report "PASS: average = " & integer'image(expected);

            wait until rising_edge(clk);      -- So start for next procedure dosen't pulse until FSM goes to IDLE (after done)
            
            -- Check valid is only high for one cycle and avg_out result is held
            wait for 1 ns;
            assert valid = '0'
                report "FAIL: valid stayed high for more than one cycle"
                severity failure;
            
            assert to_integer(unsigned(avg_out)) = expected
                report "FAIL: avg_out didn't hold after valid"
                severity failure;
        
        end procedure;

    -- start stimuus (drives procedue)
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

        -- Run tests using procedure
        run_avg((10, 20, 30, 40));
        run_avg((255, 255, 255, 255));
        run_avg((1, 2, 3, 4));

        -- Reset in between runs
        rst_n <= '0';
        wait until rising_edge(clk);
        rst_n <= '1';

        -- Wait 3 cycles for rst_n to be deasseted (2-3 cycle delay from synchronizer)
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        run_avg((0, 0, 255, 0));
        run_avg((0, 0, 0, 0));

        -- Report tests passed and stop simulation
        report "ALL TESTS PASSED";
        for i in 1 to 3 loop              -- add few extra cycles for waveform
            wait until rising_edge(clk);
        end loop;
        std.env.finish; 
    end process;
end architecture;










