-- Data and Clock Gating using ICG's and Aligning with cycle for correct result
process(clk)
begin
  if rising_edge(clk) then
    in_valid_ff1 <= in_valid; -- 1 cycle dleay for prod_reg (so it uses valid data)
    in_valid_ff2 <= in_valid_ff1; ---- 2 cycle dleay for acc_reg (so it uses valid data)
    
    if in_valid = '1' then -- Becomes ICG cell (gates both ff clk pins and idle data chnaging)
        a_reg    <= a_in;
        b_reg    <= b_in;
    end if;

    if in_valid_ff1 = '1' then
        prod_reg <= a_reg * b_reg;
    end if;

    if in_valid_ff2 = '1' then
        acc_reg  <= acc_reg + prod_reg; 
    end if;

  end if;
end process;