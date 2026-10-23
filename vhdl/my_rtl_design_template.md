# The RTL Design Template

## Design

**Step 1: Interface.** From the spec, list the ports: inputs, outputs, widths.

**Step 2: Timing.** A cycle-by-cycle table in plain words, using only port names. Pin down vague specs here (e.g. do samples arrive with `start` or after it?). The phases you find become FSM states.

**Step 3: Storage.** Ask "what must be remembered between cycles?" Each answer is a register. Give each a width (bit growth: add → +1 bit, N×M → N+M bits, sum of K values → +⌈log₂K⌉ bits).

**Step 4: Change rules.** For each register, list every way it can change, and when, in plain words. Always end with "otherwise: hold." Each register's rules become its mux chain (first rule = mux closest to the FF).

**Step 5: Classify each "when."** This is where signals are born:
- Depends on **data** (a comparison, a count reaching a value)? → a **status** signal from the datapath
- Depends on **which phase** you're in (starting, collecting, finished)? → a **control** signal from the FSM
- Two conditions mean the same thing? → reuse one signal

Tip: if a rule can't be written in plain words, the spec isn't pinned down yet → go back to Step 2.

**Step 6: FSM.** The phases from Step 2 become states. For each state, list which control signals are '1' and which status signals cause transitions.

**Step 7: Hardware check.** Sketch it and sanity-check widths and costs (Lesson 7).
- Datapath: widths, cost of each block, conflicts (can two controls fire together?), reset.
- FSM: flops = ⌈log₂ states⌉; each output Moore or Mealy; no Mealy output leaves the module; size of the next-state logic.
- Any flag that says "result ready" → check the result's registers have actually been written by then.

## Timing

**Step 8: Estimate the critical path.**
1. List end points: every register and every output port.
2. For each end point, write out every chain (work backwards from the end point). At every mux, follow both data AND select. (Test: if this signal changes, can D change? Then it's on a path.)
3. Price each block in logic levels (table below), then combine:
   - **Series → add.** Blocks one after another in the same cycle: add their levels.
   - **Merge → max.** When paths meet at a gate or mux, the output is ready when the slowest input is. Keep the max.
4. Tags: a chain starting at an input port → **+in** (outside delay unknown). Ending at an output port → **+out** (continues into the next block).
5. Rank. The top flop→flop row is the critical path. Keep +in / +out rows on a watch list (they're "at least" that long).

| RTL | Logic levels |
|---|---|
| Cast, slice, resize, concat, constant shift | 0 (wires) |
| 2:1 mux (each if/else) | 1 |
| if/elsif chain, k branches | k |
| case, N choices | ⌈log₂N⌉ |
| AND/OR of n inputs | ⌈log₂n⌉ |
| n-bit `=` | 1 + ⌈log₂n⌉ |
| n-bit `+ − < >`, `+1` (n = input width; carry out is free) | n |
| Variable shift, n bits | ⌈log₂n⌉ |
| N×M multiply | N + M |

Hook: **arithmetic costs its width; everything else costs a log.** (Ripple-carry, pessimistic on purpose. Fast adders ≈ 2·log₂(width).)

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

After pipelining:
- Re-check the new path costs (Step 8 on the new stages).
- Redo Step 2 (each register adds 1 cycle), then Steps 4–8 for anything that crossed the line, including valid/done.
- Pipeline registers that feed control decisions need a reset/clear (simulation starts at U).

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

**Step 11: Code.** Ports from Step 1, registers from Step 3, signals from Step 5, FSM from Step 6, pipeline registers from Steps 9–10. Nothing new should appear here. Check each line against the spec.
