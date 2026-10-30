# The RTL Design Template

## Design

**Step 1: Interface.** From the spec, list the ports: inputs, outputs, widths.

**Step 2: Timing.** A cycle-by-cycle table in plain words, using only port names. Pin down vague specs here (e.g. do samples arrive with `start` or after it?). The phases you find become FSM states.
- **Note: signals from another clock domain** (pins, buttons, other clocks): synchronize with 2 FFs before use. Valid 2–3 cycles after it changes. Never read the raw signal.
  - One synchronizer per signal; share its output.
  - Single bits only. Buses → handshake (hold the data, synchronize a valid flag) or async FIFO.
  - Pulses must last longer than the receiving clock's period (fast → slow: stretch it or use a handshake).
  - No counter needed: logic just waits on the synchronized signal. If two things must line up to the exact cycle, they must be in the same clock domain.
- **Note: after reset is released**, the design ignores inputs for 2–3 cycles (reset synchronizer). Whatever drives the inputs (incl. the testbench) waits ≥ 3 cycles.
- **Note: say when each input is accepted** (e.g. "`start` only in IDLE; ignored in RUN/DONE") and whether inputs may pause (if yes → add a `din_valid`). Tests will ask these questions anyway.

**Step 3: Storage.** Ask "what must be remembered between cycles?" Each answer is a register. Give each a width (bit growth: add → +1 bit, N×M → N+M bits, sum of K values → +⌈log₂K⌉ bits).
- VHDL sizes `+` from its inputs, not the target: `resize` the inputs first or the carry is lost.
- Give every integer a range (no range = 32 bits).

**Step 4: Change rules.** For each register, list every way it can change, and when, in plain words. Always end with "otherwise: hold." Each register's rules become its mux chain (first rule = mux closest to the FF).
- "Otherwise: hold" = an enable. Registers written this way are clock-gate-ready (Step 11 power check).

**Step 5: Classify each "when."** This is where signals are born:
- Depends on **data** (a comparison, a count reaching a value)? → a **status** signal from the datapath
- Depends on **which phase** you're in (starting, collecting, finished)? → a **control** signal from the FSM
- Two conditions mean the same thing? → reuse one signal

Tip: if a rule can't be written in plain words, the spec isn't pinned down yet → go back to Step 2.

**Step 6: FSM.** The phases from Step 2 become states. For each state, list which control signals are '1' and which status signals cause transitions.

**Step 7: Hardware check.** Sketch it and sanity-check widths and costs (Lesson 7).
- Datapath: widths, cost of each block, conflicts (can two controls fire together?).
- FSM: flops = ⌈log₂ states⌉; each output Moore or Mealy; no Mealy output leaves the module; size of the next-state logic.
- Any flag that says "result ready" → check the result's registers have actually been written by then.
- **Reset:** only control needs a reset (FSM, valid/done, pipeline regs feeding control); the datapath gets cleared by `clr`. **ASIC:** add a reset synchronizer module at the top (async assert, sync deassert), one per clock domain. Every block's reset uses its output.

## Timing

**Step 8: Estimate the critical path.**
1. List end points: every register and every output port.
2. For each end point, write out every chain (work backwards from the end point). At every mux, follow both data AND select. (Test: if this signal changes, can D change? Then it's on a path.)
   - A path = a start point + an end point. Same block, different start → separate paths (fine to write on one line if every start is listed).
   - STA assumes every start point might change every cycle, whether or not it really does.
3. Price each block in logic levels (table below), then combine:
   - **Series → add.** Blocks one after another in the same cycle: add their levels.
   - **Merge → max.** When paths meet at a gate or mux, the output is ready when the slowest input is. Keep the max.
4. Tags: a chain starting at an input port → **+in** (outside delay unknown). Ending at an output port → **+out** (continues into the next block).
5. Rank. The top flop→flop row is the critical path. Keep +in / +out rows on a watch list (they're "at least" that long; register inputs if you can't trust the outside).

| RTL | Logic levels |
|---|---|
| Cast, slice, resize, concat, constant shift | 0 (wires) |
| 2:1 mux (each if/else) | 1 |
| if/elsif chain, k branches | k |
| case, N choices | ⌈log₂N⌉ |
| AND/OR of n inputs | ⌈log₂n⌉ |
| n-bit `=` against a constant | ⌈log₂n⌉ |
| n-bit `=` | 1 + ⌈log₂n⌉ |
| n-bit `< > <= >=` against a constant | 2·⌈log₂n⌉ |
| n-bit `+ − < >`, `+1` (n = input width; carry out is free) | n |
| Variable shift, n bits | ⌈log₂n⌉ |
| N×M multiply | N + M |

Hook: **arithmetic costs its width; everything else costs a log.** (Ripple-carry, pessimistic on purpose. Fast adders ≈ 2·log₂(width).)

- A compare against a constant (literal, `constant`, or generic) is cheaper because synthesis always folds the constant in; the ripple price only applies when both sides are signals.
- An `if/else` choosing between '1' and '0' is just the condition's output (no mux).
- An AND/mux per bit across a bus = N gates of area but only 1 level.

Tip: do a rough Step 8 early (right after Step 4) so a pipelining decision doesn't surprise you.

**Step 9: Pipelining (feed-forward paths)**

Characterising pipelines:
- Period = longest stage + flop overhead (~2 logic levels)
- Latency (one result) = number of stages × period → always the same or worse
- N results = latency + (N − 1) × period → this is where pipelining wins
- Pipeline a **stream** that's **over budget**. It doesn't pay when: one item at a time, the next input needs this output (loop), the path isn't critical, stages are already short, or the cut is unbalanced.

Which paths to pipeline: compare every chain from Step 8 against L_max (most logic levels one stage can hold) and classify each as:
- **OK** ≤ 80% · **Borderline** 80–100% (STA decides) · **Over** > 100%
- The 20% margin covers wires and fanout (ignored by levels).
- Mark loop rows (start = end) → Step 10. Never pipeline those.
- To raise the clock, every path above the new target must get shorter, not just the top one (fix ties together).

Where to add registers (3 rules, in priority):
1. **Balance the stages:** aim for each stage ≈ (total logic levels of the path) ÷ (number of stages). The slowest stage sets the period. Cut at a block boundary (after the multiplier, before the adder). Cutting inside an adder is possible, but leave that to the tools (retiming).
2. **Narrowest bus (tie-breaker):** if several cuts give the same period, cut where the bus is narrowest. You pay one flop per bit crossing the cut.
3. **The cut must split the slow block:** a register in front of or after the long block, without splitting it, leaves the long stage the same length.

**Vertical Line Rule (Latency Matching):** draw a vertical line through the design at the new reg. Every wire crossing the line needs a FF too, so the cycles stay aligned.
- Never draw the line through a loop (a reg feeding back to itself, like a counter or accumulator). A FF in a loop breaks the logic.
- Every path into the same endpoint (except loops) must cross the same number of new registers, including control signals like valid/done.
- Where you cut along a wire doesn't matter. Cutting before a split costs 1 FF; cutting after it costs 1 FF per branch.
- Constants don't cross (they're just tied-off wires).
- A delay is always a FF, never a chain of gates.

After pipelining:
- Each pipeline register adds 1 cycle to every path that crosses it.
- Re-check the new path costs (Step 8 on the new stages).
- Redo Step 2, then Steps 4–8 for anything that crossed the line, including valid/done.
- Pipeline registers that feed control decisions need a reset/clear (simulation starts at U; silicon starts random).

**Step 10: Pipelining loops**

A loop sets a hard floor on the period: period ≥ loop logic levels + flop overhead. Pipelining can't change this. A path that runs into a loop's logic is stuck with the loop's length too.
1. Identify loops from Step 8 (any row where start = end: `sum` Q → … → `sum` D).
2. Fix loops if possible:
   - **Move operations out of the loop.** For `sum <= sum + a*b`, only the adder must be in the loop. The multiplier can be moved out (registered) and then pipelined. Watch `:=` vs `<=`: a variable can fold the multiply back into the loop's cycle.
   - **Make the loop logic faster** (e.g. a fast adder like CLA instead of ripple). Synthesis does this automatically when timing is tight, but note where it should and confirm it does.
   - **Make the loop narrower** (rare if sized right, but a good check):
     - Register is bigger than it needs to be (`signal cnt : integer` with no range = 32 bits when it only counts 0–9 = 4 bits).
     - You can accept less precision (drop low bits before the loop; changes the result, only if the spec allows).
   - **Interleave** (advanced, accelerator track).

## Power

**Step 11: Power check.** Dynamic power only burns when things flip. For each block, ask: is it often idle, and does its clock or its input keep moving while idle?
- **Clock gating (stops the clock):** wide register banks that share an enable and sit idle → write them as enable RTL (`if en then reg <= d; end if;`, no else) and synthesis swaps the hold muxes for one ICG.
  - Not worth it for single flops, registers that load every cycle, or small FSMs.
  - A whole idle block → one coarse ICG via a `clock_gate` wrapper (also stops its clock-tree branch). Never `clk and en`.
  - Check in the flow that the ICGs were actually inserted (F3).
    Steps:
  i) Registers holding their value while idle (and their size = #FFs)
  ii) "en" signal to gate register with (If none, that reg can't be gated - Or an enable signal should be added if appropereate)
  iii) Worth Gating? (More than a few flops, or free from gating other regs with same signal)
- **Operand isolation (stops the data):** expensive logic (multipliers, wide adders) whose inputs keep moving while idle → freeze its inputs:
  - an enabled input register (often already there → free, and it's clock-gated too)
  - AND the inputs with the enable (N gates of area, +1 logic level, no extra cycle) → re-price that path in Step 8, including the block after the AND
  - at the source (don't drive a bus or read memory when nobody needs it)
  - Not worth it for cheap logic, or logic whose inputs already sit still.
- **Pipelines:** give each stage its own enable = valid delayed to that stage (one flop per stage).
  - Each stage's enable is a control signal crossing the line: it follows the Vertical Line Rule (Step 9), or it's off by one.
  - Those valid flops need a reset.
- **Other habits:** don't update rarely-read registers every cycle · narrower widths · only reset what needs it · Gray code for constantly-ticking, high-fanout counters.
- **When:** architecture choices (data movement, memory reads, widths, voltage) first; these habits always; fine-tune only after measuring (power report).

## Code

**Step 12: Code.** Ports from Step 1, registers from Step 3, signals from Step 5, FSM from Step 6, pipeline registers from Steps 9–10, enables and isolation from Step 11. Nothing new should appear here. Check each line against the spec.
- Variables in a clocked process: write before read, on every path, or they become flops.

## Verification

**Step 13: Testbench.** Test the spec, not the code.

Structure:
- No ports. Clock: `clk <= not clk after 5 ns;` (start it at '0'). Initialize inputs, not outputs.
- Pass the generics down from the testbench (one source of truth for sizes).
- Reset, then wait ≥ 3 cycles after release before driving anything.
- One **procedure** per kind of test, so each test is one line. Shared procedures go in a package (`tb_pkg`), with the signals passed in as `signal` parameters.
- A few extra cycles before `std.env.finish` so the waveform shows the end.

Timing:
- Drive inputs right after an edge; read outputs ~1 ns after an edge.
- End each test in a legal state for the next one (e.g. wait for the edge back to IDLE).

Self-checking:
- `assert … report … severity failure`, printing expected vs actual.
- An **independent** reference model (e.g. integer math, not the design's shift).
- A timeout on every wait for the design (`wait until valid = '1' for … ns`).
- Checks on the testbench itself ("TB ERROR: test list has the wrong length").
- `PASS` per test (at the end of the procedure) and `ALL TESTS PASSED` at the end.

What to test (derive it from the template):

| Step | Tests |
|---|---|
| 1. Interface | min, max, and middle values on every input |
| 2. Timing | outputs on the exact cycle; back-to-back; gaps; inputs at the wrong time (does the design ignore them?) |
| 3. Storage | values that push each register to its max (overflow) |
| 4. Change rules | each condition true and false; two at once (priority) |
| 5. Status signals | each threshold exactly, one below, one above |
| 6. FSM | every transition; every input in every state |
| 7. Hardware check | reset in the middle of an operation, then a clean run; result valid exactly when the flag says so |
| 9–10. Pipelines | full throughput, bubbles (gaps), draining |
| 11. Power | enables lined up with data |
| Generics | smallest, default, and a large configuration |

- **Values:** boundaries (0, 1, max − 1, max); distinct values per channel/stage/sample so swaps show; bit patterns (all ones, `1010…`, walking 1); random against the reference model.
- **Check more than the answer:** when it arrives, how long flags last (`valid` exactly 1 cycle), the result holds, nothing changes while idle, invariants.
- **Done when:** every spec line, change rule, FSM transition, and boundary has a test; every planted bug is caught; every spec hole a test raised is answered in Step 2 (and tested).

Debugging:
- **Testbench bug or design bug? The spec decides.** Check the inputs first (does the testbench drive what Step 2 says, on the right cycle?), then the outputs against Step 2, then the expected value by hand, then when the testbench reads.
- Waveform: `ghdl -r --std=08 tb --wave=x.ghw`, then `gtkwave x.ghw`. Walk back from the failure time: wrong output → its register → its controls → the FSM state.
- GHDL: `ghdl -i --std=08 *.vhd` (once, or when files are added) → `ghdl -m --std=08 tb` → `ghdl -r --std=08 tb`. `-m` and `-r` take the testbench's name.
