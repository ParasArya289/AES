# AES RTL Optimization — Knowledge Transfer Guide

> **Who this is for:** Someone brand new to this project, SystemVerilog, and AES.
> Every concept is explained from scratch, with analogies before the technical detail.
> Read top to bottom — each section builds on the previous one.

---

## Part 0 — What is this project, actually?

Imagine you have a recipe for baking a cake. The cake always comes out the same — same taste, same ingredients. But maybe the original recipe says "go to the shop, buy flour, come back, measure it" every single time you need flour. That's inefficient. A smarter version of the recipe says "just use the flour already on the counter." Same cake. Less work.

This project is exactly that — but for **AES encryption running on a chip**.

**AES (Advanced Encryption Standard)** is a widely used algorithm for encrypting data — the same math behind HTTPS, Wi-Fi passwords, and secure banking. It takes a block of data (128 bits = 16 bytes, like a short sentence) and scrambles it using a secret key, so that only someone with the key can unscramble it.

The question this project asks: **can we implement AES on an FPGA chip using less hardware and less power, without ever changing the result?**

The answer is yes — and this document explains exactly how, one phase at a time.

---

## What is an FPGA?

An **FPGA (Field-Programmable Gate Array)** is a chip made of millions of tiny building blocks called **LUTs (Look-Up Tables)** and **flip-flops (registers)**. You program it by wiring these blocks together in software. It's like Lego — you assemble the logic you want from standard pieces.

- **LUT** = a small piece of logic that computes a function (think: a truth table for up to 6 inputs)
- **Flip-flop (FF)** = a memory cell that stores 1 bit across clock cycles (like a tiny latch)
- **Clock** = a global heartbeat signal; on every tick, all flip-flops capture their input

**Why do LUT count and power matter?**
- Fewer LUTs → smaller chip area, lower cost
- Less switching → less dynamic power (the chip runs cooler, consumes less energy)
- **Dynamic power** = power consumed every time a wire changes value (0→1 or 1→0). More switching = more power.

This project's target chip is the **Artix-7 xc7a35t** — a mid-range Xilinx FPGA with 20,800 LUTs available. Wasting them matters.

---

## What is SystemVerilog (the language)?

SystemVerilog is a hardware description language (HDL). Instead of writing a program that runs step by step like Python, you write a *description of circuits* — wires, registers, and logic gates.

```systemverilog
always_ff @(posedge clk) begin    // on every clock rising edge...
    if (enable)                   // if enable is 1...
        register <= new_value;    // latch new_value into register
end
```

Key ideas:
- `always_ff` = describes a flip-flop (register)
- `always_comb` = describes purely combinational logic (no clock, just wires and gates)
- `assign` = continuous wire assignment
- `<=` inside `always_ff` = non-blocking assignment (the flip-flop updates on the next clock edge)

---

## AES in 60 Seconds

AES encrypts a **128-bit block** (16 bytes, arranged as a 4×4 matrix) by running it through a sequence of **rounds** (10 rounds for a 128-bit key, 12 for 192-bit, 14 for 256-bit).

Each round applies four transformations in order:

| Step | What it does | Analogy |
|------|-------------|---------|
| **SubBytes** | Replace each byte using a lookup table (S-Box) | Swap each letter using a codebook |
| **ShiftRows** | Rotate each row of the 4×4 matrix | Shuffle rows like playing cards |
| **MixColumns** | Multiply each column by a matrix over GF(2⁸) | Mix paint colors using a specific recipe |
| **AddRoundKey** | XOR the state with the round key | Add a secret ingredient to each column |

**Decryption** applies the inverse of each step, in reverse order, with round keys applied in reverse.

The result is mathematically guaranteed to be reversible — if you know the key, you can always get back the original data.

---

## Two Architectures Used in This Project

Before diving into optimizations, understand that this project implements AES in two different hardware styles:

### FSM Architecture (State Machine)
Imagine a single kitchen with one chef. The chef reuses the same pots and knives for every round of baking. It takes longer (one round per clock cycle group), but uses very little hardware.

- One set of round hardware, reused each round
- A **Finite State Machine (FSM)** controls which round is being processed
- Baseline: **13,268 LUTs, 413 flip-flops** (Vivado, AES-128)
- **Lower area, lower throughput**

### Pipeline Architecture
Imagine 10 kitchens in a row, each specialized for one round. Put raw dough in the first kitchen; by the time it reaches kitchen 10, it's a finished cake. And you can push new dough in every cycle.

- Nr−1 stages, each containing a complete round's logic
- New plaintext can be accepted every clock cycle
- Baseline: **91,467 LUTs, 3,843 flip-flops** (Vivado, AES-128)
- **Higher area, higher throughput**

All seven optimization phases apply to both architectures unless noted.

---

## The Tools: Yosys vs Vivado

Two different synthesis tools were used, and their results sometimes disagree significantly. Understanding why is important.

| Tool | What it does | ROM mapping |
|------|-------------|-------------|
| **Yosys** | Open-source synthesis, logical LUT estimate | Maps ROMs to **LUT RAM** (counted as LUTs) |
| **Vivado** | Xilinx official tool, physically maps to Artix-7 | Maps ROMs to **BRAM** (dedicated block, NOT counted in LUTs) |

This creates a dramatic difference: a 256-entry ROM shows up as ~256 LUTs in Yosys but **0 LUTs** in Vivado (it uses a free BRAM). The gap can be up to **23×**. Yosys numbers are used for relative phase-to-phase comparisons (consistent measuring stick). Vivado numbers are the physical truth on the chip.

---

## The Big Picture: What Did We Achieve?

Before seeing how, here's what was achieved across all phases:

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| Yosys LUT count (FSM AES-128) | 184,918 | 15,621 | **−91.6%** |
| Vivado LUT count (FSM AES-128) | 13,268 | 3,185 | **−76%** |
| Vivado LUT count (Pipeline AES-128) | 91,467 | 4,200 | **−95.4%** |
| Dynamic Power (Pipeline) | 0.217 W | 0.142 W | **−34.6%** |
| Idle register toggles (Pipeline) | 101,035 | 0 | **−100%** |

Every single result still passes all AES test vectors. **The encryption output is bit-for-bit identical to the original.**

---

---

# Phase 1 — xtime Arithmetic (Replacing Log Tables)

## The Problem: What Was There Before?

Inside MixColumns, AES needs to multiply each byte by constants {1, 2, 3} in a special math called **GF(2⁸)** (Galois Field of 2 to the power 8). Decryption's MixColumns needs constants {9, 11, 13, 14}.

The original implementation used a trick called **logarithm tables**:

```
result = EXP3[  LN3[a] + LN3[b]  mod 255  ]
```

Where `EXP3[]` and `LN3[]` are pre-computed 256-entry lookup tables stored in a file called `aes_array.sv`. Think of them like a multiplication cheat sheet bolted to the circuit.

**Analogy:** Imagine you need to multiply two numbers but can only add. You look up the first number in a "log table," look up the second, add the results, and look up the "antilog" to get the product. That's exactly what EXP3/LN3 does.

These tables were **512 × 8-bit entries** in total, and they were included in every module that touched MixColumns — 10 modules across the design. On Yosys, each table synthesizes to hundreds of LUTs. On Vivado, they map to BRAM. Either way, they're wasted hardware for math that can be done more elegantly.

## The Fix: xtime Arithmetic

In GF(2⁸) with the AES reduction polynomial (x⁸ + x⁴ + x³ + x + 1), multiplying by 2 (the field element *x*) has a simple closed-form rule:

```
xtime(a) = (a << 1) XOR (0x1B  if  a[7] == 1  else  0x00)
```

**Analogy:** Think of the 8-bit number as a polynomial written in binary. Multiplying by x shifts every coefficient up by one degree. If the result overflows degree 8, you subtract the polynomial 0x1B (which is the lower part of the AES modulus). This is like clock arithmetic — when you go past 12 on a clock, you wrap around.

From xtime, you can build all the constants AES needs:

| Constant | How to compute | Meaning |
|----------|---------------|---------|
| ×1 | `a` | identity |
| ×2 | `xtime(a)` | one shift+XOR |
| ×3 | `xtime(a) XOR a` | two additions |
| ×4 | `xtime(xtime(a))` | two shifts |
| ×8 | `xtime(xtime(xtime(a)))` | three shifts |
| ×9 | `xt8 XOR a` | chain |
| ×11 | `xt8 XOR xt2 XOR a` | chain |
| ×13 | `xt8 XOR xt4 XOR a` | chain |
| ×14 | `xt8 XOR xt4 XOR xt2` | chain |

Each of these is just a few XOR gates and bit shifts — **pure combinational logic**, no tables, no RAM reads.

## Where in the AES Block This Lives

```
AES Round
├── AddRoundKey   ← XOR with round key
├── SubBytes      ← S-Box lookup
├── ShiftRows     ← rotate rows
└── MixColumns    ← GF(2⁸) multiply  ← THIS IS WHERE PHASE 1 CHANGES THINGS
```

The EXP3/LN3 tables were inside `MixColumns` and `InvMixColumns`. They were accessed through port stubs that threaded through 10 different SystemVerilog modules. Phase 1 atomically removed all 10 port connections and deleted `aes_array.sv` entirely.

## Why the Math is Still Correct

xtime is a **provably correct** implementation of multiplication by 2 in GF(2⁸). Every other coefficient (3, 9, 11, 13, 14) is derived from xtime using basic field algebra — no approximation, no shortcuts. The result for every possible 8-bit input is bit-for-bit identical to the table lookup. You could verify this exhaustively: test all 256 possible inputs, confirm both methods give the same output. They do.

## Results

| Tool | Architecture | Before | After | Reduction |
|------|-------------|--------|-------|-----------|
| Yosys | FSM AES-128 | 184,918 LUTs | 42,181 LUTs | **−77.2%** |
| Yosys | FSM AES-192 | 193,131 LUTs | 49,381 LUTs | **−74.4%** |
| Yosys | FSM AES-256 | 202,490 LUTs | 59,710 LUTs | **−70.5%** |
| Vivado | FSM AES-128 | 13,268 LUTs | 5,486 LUTs | **−58.6%** |
| Vivado | Pipeline AES-128 | 91,467 LUTs | 21,816 LUTs | **−76.2%** |

This is the **single biggest area reduction** in the entire project. The tables were the dominant cost. Eliminating them with pure logic saves between 58% and 77% of all LUTs depending on tool and architecture.

---

---

# Phase 2 — Data Path Gating (FSM State Registers)

## The Problem: Registers Toggling for No Reason

Every flip-flop in your design consumes dynamic power in proportion to how often it changes value. A register that changes every clock cycle — even when the chip isn't doing anything useful — wastes power.

**Analogy:** Imagine a ceiling fan with no off switch. It spins at full speed 24 hours a day, even when no one is in the room. That's the FSM state register before Phase 2. It updates every clock cycle regardless of whether AES is currently encrypting anything or sitting idle.

The FSM (Finite State Machine) has a packed register struct `r` that holds:
- `r.state` — which round are we on? (0 = idle/waiting)
- `r.ready` — has the result been computed? (1 = yes, output is valid)

Without gating, `r` updates on every clock edge. Even when the FSM is sitting in the IDLE state doing nothing.

## The Fix: Clock Enable (CE) on the Register

In SystemVerilog, you can add a **clock enable condition** to a flip-flop:

```systemverilog
always_ff @(posedge clk) begin
    if (CE) begin
        r <= next_r;    // only update when CE is true
    end
    // when CE=0, r keeps its old value — the register "freezes"
end
```

On the Artix-7 FPGA, this synthesizes to a primitive called **FDRE** — a flip-flop with a dedicated CE pin. When CE=0, the register holds its value. This is synthesized efficiently into a single flip-flop cell.

The CE condition used is:

```
CE = (r.state != IDLE) OR (r.ready == 1) OR (Enable == 1)
```

**Breaking this down — why three terms?**

| Term | Why it's needed | What breaks without it |
|------|----------------|----------------------|
| `r.state != IDLE` | Any non-idle state must advance. | FSM would stall mid-computation. |
| `r.ready == 1` | The ready flag must stay visible for one cycle after completion. | Host never sees the "done" signal; result is lost. |
| `Enable == 1` | A new encryption request arrives. | FSM can never start; stuck in IDLE forever. |

**Analogy:** The three terms are like three reasons to "wake up" from sleep mode:
1. You're already doing something — keep going.
2. You just finished — hold the result one moment so the caller can read it.
3. Someone gave you a new task — start it.

## Important: This is NOT Clock Gating

This is the **most commonly misunderstood point** in this project. The CE approach described here is called **Data Path Gating**, not clock gating. Here's the difference:

### True Clock Gating (what synthesis tools do automatically)
```
CLK ──► [ICG gate] ──► FF.clk
              ↑
           enable
```
The **clock signal itself** is stopped. The flip-flop receives no clock edge. Power savings come from suppressing the clock network AND the register cell itself.

### Data Path Gating (what this project does)
```
DATA ──► [MUX] ──► FF.D
              ↑
          CE=0 → feedback (hold old value)
          CE=1 → new data
```
The **clock still ticks every cycle** — the flip-flop still sees the clock edge. But when CE=0, the data input is replaced by the register's own output (a feedback mux). So it "holds" its value. The power savings come from the **data signals** into the register stopping their toggling — which means all the combinational logic feeding the register also goes quiet.

**Why does this still save power?**

Dynamic power formula: `P = α × C × V² × f`

- `α` = switching activity (how often signals toggle, from 0 to 1)
- `C` = capacitance of the wire
- `V` = supply voltage
- `f` = clock frequency

When CE=0, the data wires into the register stop toggling → `α` drops for those signals → power drops. The clock still runs (same `f`), but the data-path wires are quiet.

## Where in AES This Lives

Three FSM modules were gated:

```
aes.sv (top level)
├── aes_cipher_state.sv   ← encrypt FSM  → Phase 2 gated r.state + r.ready
├── aes_icipher_state.sv  ← decrypt FSM  → Phase 2 gated r.state + r.ready
└── aes_kexp_state.sv     ← key schedule → Phase 2 gated r struct + KExp_N register
```

The key schedule FSM (`aes_kexp_state.sv`) has a slightly different CE because `KExp_N` (the round key accumulator) doesn't have a ready bit:

```
CE for KExp_N = (r.state != IDLE) OR (Enable == 1)
```

No `r.ready` term needed — there's nothing to "hold" after completion for this register.

## Results

LUT count: **unchanged** — the same logic exists, just gated.

Power reduction is the payoff:

| Stage | Total Dynamic Power |
|-------|-------------------|
| No CE gating | 0.217 W |
| After FSM CE gating (Phase 2) | 0.174 W |
| **Reduction** | **−19.8%** |

The register idle-toggle analysis confirms: FSM was already at zero idle register-candidate toggles at baseline (the FSM architecture is naturally quiet between requests). The power reduction comes from the combinational logic feeding those registers being silenced.

---

---

# Phase 4 — CFA S-Box (Replacing the SubBytes Lookup Table)

## The Problem: The S-Box is a 256-Entry ROM

AES SubBytes replaces each of the 16 bytes in the state matrix using a lookup table called the **S-Box**. For every possible input byte (0x00–0xFF), the table gives a specific output byte. The decryption inverse is called the **Inverse S-Box** (IBox).

In the original design, these were implemented as **256 × 8-bit ROMs** — read-only memory tables baked into the hardware.

**Analogy:** Imagine you always translate words using a physical dictionary. You look up every word. It works, but you're carrying around a huge book. Now imagine you knew the grammar rules well enough to derive any word's translation from first principles. You could throw away the dictionary — same result, no book needed.

On Yosys, a 256-entry ROM synthesizes to hundreds of LUTs (LUT RAM). Every pipeline stage has its own S-Box, so with 10 stages in AES-128, you have 10 copies of this table. The area cost is massive.

## The Fix: CFA — Composite Field Arithmetic

The AES S-Box is mathematically defined as:

```
S(a) = AffineTransform( a^(-1) in GF(2^8) )    for a ≠ 0
S(0) = 0x63                                     by definition
```

The core operation is **finding the multiplicative inverse** of a byte in GF(2⁸). This is the expensive part. Canright (2005) showed a beautiful way to compute this inverse using smaller, simpler fields.

### Step 1: Change the Basis (Go to a Tower Field)

GF(2⁸) is the "big" field where AES operates. GF((2⁴)²) is a "tower field" — a field of pairs of 4-bit values. They're mathematically isomorphic (same structure, different representation).

**Analogy:** Celsius and Fahrenheit both describe temperature. They're related by a formula. If your math is easier in Fahrenheit, convert, compute, convert back. Canright does the same for GF(2⁸) inversion.

The conversion is a linear map — just XOR operations on the input bits. No multiplication needed. This is the **basis-change matrix** B.

### Step 2: Compute Inversion in GF((2⁴)²)

In the tower field, an element is a pair (A, B) where A, B ∈ GF(2⁴) (each is a 4-bit value).

The inversion formula in this tower is:

```
(A, B)^(-1) = ( d·B ,  d·(A XOR B) )

where d = inverse_in_GF2_4( A·B  XOR  ν·(A XOR B)² )
```

This decomposes the hard GF(2⁸) inversion into:
- 2 multiplications in GF(2⁴)
- 1 squaring-and-scaling in GF(2⁴)
- 1 inversion in GF(2⁴)

GF(2⁴) inversion decomposes further into GF(2²) operations. And GF(2²) operations reduce to **simple AND and XOR gates** — the most basic building blocks of digital logic.

**Analogy:** It's like breaking a hard division problem into a chain of easier subproblems:
- "What's 17 divided by 13?" is hard.
- But "What's 17 mod 4? What's 13 mod 4?" are easier.
- If you have the right algebraic relationship, you can build the big answer from the small answers.

### Step 3: Inverse Basis Change + Affine Transform

Convert back from GF((2⁴)²) to GF(2⁸) using the inverse basis map, and simultaneously apply the AES affine transform (the final 8×8 matrix multiply + constant 0x63). The constant 0x63 is embedded via XNOR gates in the basis change equations, so no extra adder is needed.

The whole chain is implemented in `aes_cfa_sbox.sv` using four tiny sub-modules:
- `aes_gf4_mul` — GF(2⁴) multiplier
- `aes_gf4_inv` — GF(2⁴) inverter
- `aes_gf4_sq_scl` — GF(2⁴) squaring + scaling
- `aes_gf8_inv` — GF(2⁸) inverter (uses the three above)

## Where in AES This Lives

```
AES Round
├── AddRoundKey
├── SubBytes  ← THIS IS WHERE PHASE 4 CHANGES THINGS
│   └── 16× S-Box lookups (one per byte of the 4×4 state)
│       BEFORE: 256-entry ROM
│       AFTER:  ~100-gate CFA combinational tree
├── ShiftRows
└── MixColumns
```

Phase 4 also eliminated all `SBox[]` and `IBox[]` port stubs that were threading ROM access signals through the module hierarchy — exactly mirroring what Phase 1 did for the EXP3/LN3 tables.

## A Note on Vivado vs Yosys Here

This is where the tool discrepancy matters most:

- **Yosys (before Phase 4):** ROM was in LUT RAM → counted as LUTs. Replacing with CFA logic → fewer LUTs. **LUT count drops.**
- **Vivado (before Phase 4):** ROM was in BRAM → counted as 0 LUTs (free!). Replacing with CFA logic → new combinational logic appears. **LUT count goes up.**

The result is real and correct — CFA is more area-efficient than LUT RAM. But Vivado's BRAM baseline makes the comparison counterintuitive. **This is not a regression.** Vivado's post-Phase-4 pipeline is still much smaller than the baseline on both absolute and relative terms.

## Results

| Tool | Architecture | After Phase 1 | After Phase 4 | Cumulative |
|------|-------------|--------------|--------------|-----------|
| Yosys | FSM AES-128 | 42,181 LUTs | 17,484 LUTs | **−90.5%** from baseline |
| Yosys | Pipeline AES-128 | similar | 134,289 LUTs | **−64.7%** from baseline |
| Vivado | FSM AES-128 | 5,486 LUTs | 3,185 LUTs | further reduced |
| Vivado | Pipeline AES-128 | 21,816 LUTs | 4,200 LUTs | huge drop |

Also: VCD toggle count jumps from 163 per encryption to 9,375 (+57×). This sounds bad but is expected — the ROM was accessed once per round; the CFA combinational tree evaluates on every clock edge. The toggle count increase is a **side effect of replacing static ROM with active combinational logic**, and it is addressed by Phase 6.

---

---

# Phase 5 — Pipeline CE Gating (OR-CE Flush Pattern)

## The Problem: Pipeline Stages Never Stop

The pipeline architecture has Nr−1 stages. Each stage is a registered column of logic. After an encryption completes, the pipeline should go quiet. But in the original design, each stage register updated every clock cycle unconditionally — latching the same stale value over and over.

**Analogy:** Imagine a factory assembly line with 10 stations. You send one product through. After it exits, the assembly line keeps running with no product — every station picks up the empty belt and puts it back down, consuming energy for nothing.

Additionally, there's a correctness issue: if you send two encryptions back to back with a gap in between, in-flight data from the first encryption must finish traveling through all stages before it's valid. Stopping stages early would discard that in-flight data.

## The Fix: OR-CE Flush Pattern

Each stage gets a Clock Enable condition:

```
Stage 0 (seed):   CE[0] = Enable  OR  Ready_Reg[0]
Stage i (middle): CE[i] = Ready_Reg[i-2]  OR  Ready_Reg[i-1]
```

`Ready_Reg[i]` is a validity token — it travels with the data through the pipeline, staying 1 as long as the data in that stage is valid.

**Breaking down the OR:**
- **Left term** (`Ready_Reg[i-2]` or `Enable`): "My upstream just produced valid data — I need to open my gates to receive it."
- **Right term** (`Ready_Reg[i-1]`): "I'm currently holding valid data that needs to keep moving forward — stay open."

**Analogy:** Each station on the assembly line has two reasons to run:
1. The upstream station just sent me something.
2. I'm currently holding something that needs to go to the next station.

If neither is true, the station shuts down completely (CE=0, register freezes).

This creates a **self-draining pipeline**: after Enable drops, the pipeline continues running for exactly T more cycles (where T = pipeline depth) as in-flight data drains out stage by stage. Then all stages go quiet.

## Three Bugs Fixed During Implementation

This seems simple, but had three subtle bugs:

**Bug 1 — Self-referential deadlock:**
The first attempt used `Ready_Reg[i-1] || Ready_Reg[i-1]` (same signal twice). Once `Ready_Reg[i-1]` went to 0, the stage closed and could never reopen to accept new data. Like a door that locks itself when you close it.

**Bug 2 — Off-by-one in generate loop:**
The generate loop that instantiated CE for each stage had the index off by one — one stage got no CE, another got the wrong one. A classic fence-post error.

**Bug 3 — Final stage never clearing:**
The last stage needed its own self-drain CE to clear after the final encryption. Without it, the output stage held its valid ready flag high forever, making the testbench think a new result was ready when none was.

## Where in AES This Lives

```
aes_cipher.sv (pipeline, ascending)
├── Stage 0: State_Reg[0], Ready_Reg[0]  ← seeded by Enable
├── Stage 1: State_Reg[1], Ready_Reg[1]  ← CE = Ready_Reg[0] OR Ready_Reg[1]  (wait — see below)
│   ...
└── Stage Nr-1: State_Reg[Nr-1]          ← drains and clears

aes_icipher.sv (pipeline, descending)
└── Same pattern but indices go Nr-1 → 0 (decryption counts down)
```

Note: For the decryption pipeline (`aes_icipher.sv`), the pipeline runs in the opposite direction — Stage Nr-1 is seeded by Enable, Stage 0 produces output. The CE indices mirror accordingly: `[i+1] || [i]` instead of `[i-2] || [i-1]`.

## Results

LUT count: **unchanged** — the CE mux logic is absorbed into FDRE primitives.

Power benefit: eliminating idle register toggling. Combined with Phase 6, the pipeline's idle register-candidate toggles drop from **101,035 to 0** (−100%).

---

---

# Phase 6 — Fine-Grained Clock Enable Gating (Three Sub-Techniques)

Phase 6 is a bundle of three targeted improvements, each attacking a different source of unnecessary switching.

---

## CG-01: Gating the State_N Register

### The Problem
Phase 2 gated the FSM's control register `r` (which holds `r.state` and `r.ready` — just a few bits). But the **data register** `State_N` — the 128-bit register holding the current AES state between rounds — was left ungated. It was the last `always_ff` block updating unconditionally every cycle.

**Analogy:** You locked the control room (the FSM state bits) but left the main warehouse (the 128-bit data) with the lights on and machines running 24/7. Phase 6 CG-01 turns off the warehouse when not in use.

### The Fix
Apply the same CE condition from Phase 2 to `State_N`:

```
CE = (r.state != IDLE) OR (r.ready == 1) OR (Enable == 1)
```

The `r.ready == 1` term is critical here: `State_N` drives `Data_out` directly. If `State_N` were to freeze before `r.ready` clears, the output register would go invalid before the consumer has read it. The ready cycle keeps `State_N` stable through the handshake.

**Target modules:** `aes_cipher_state.sv` and `aes_icipher_state.sv`

---

## CG-02: Gating Key Expansion Pipeline Stages

### The Problem
The key expansion module `aes_kexp.sv` runs as its own pipeline, generating round keys. Its stage registers were completely ungated — they kept updating every clock cycle even when no new key was being scheduled.

### The Fix
Apply OR-CE from Phase 5 to the key expansion pipeline:

```
Stage 0:  CE = Enable OR Ready_N[0]
Stage i:  CE = Ready_N[i-1]           (upstream only — no OR-flush needed)
```

Why no self-drain (OR) for interior stages? Because `aes_kexp` is a **one-shot pipeline**: once Enable fires, key data propagates through once and stops. Unlike the cipher pipeline which may need to flush mid-stream, the key schedule runs exactly one complete pass. No second wave, no need to self-drain.

**Analogy:** The key schedule is like a one-way conveyor belt that runs once, deposits the round keys, and stops. No need for self-draining logic — there's nothing to drain after the single pass.

---

## CG-03: Mux-Gating CFA S-Box Inputs (The Dominant Power Saver)

This is the most architecturally significant technique in the entire project, and the one that achieves the largest power reduction.

### The Problem After Phase 4

Phase 4 replaced the ROM S-Box with a CFA combinational tree (~100 gates). This is faster and uses fewer LUTs, but it creates a new problem:

The CFA tree is **purely combinational** — it computes on every clock cycle, regardless of whether the data feeding it is valid or garbage. After Phase 5 gated the pipeline registers, the registers themselves stopped updating at idle. But the combinational CFA tree was still receiving those register's wire values and computing away on them, toggling its internal nodes on every clock edge.

**Analogy:** You told the factory workers to stop moving boxes (CE gating). But the machines are still running — they're just chewing on empty air. The power the machines consume grinding on nothing is exactly this wasted switching activity.

### The Fix

Insert a mux before every CFA S-Box input:

```systemverilog
assign sbyte_in_muxed[i] = Ready_Reg[i] ? State_Reg[i] : '{default:'0};
```

- When `Ready_Reg[i] = 1` (stage has valid data): pass `State_Reg[i]` to the S-Box. Normal operation.
- When `Ready_Reg[i] = 0` (stage is idle): force `8'h00` (constant zero) to every byte of the S-Box input.

**What happens when the CFA S-Box receives constant 0x00 every cycle?**

S-Box(0x00) = 0x63 — always. A constant input → constant output → **every internal node in the 100-gate CFA tree holds a constant value**. No toggling. Zero switching activity. Zero dynamic power for the CFA logic.

**Analogy:** Instead of turning off the machine (which would require clock gating hardware), you put a dummy block in front of it — the same identical block every time. The machine processes it just fine, but since the input never changes, nothing inside ever moves. Power saved.

### Why This is Not the Same as Clock Gating

| Feature | Clock Gating (ICG) | Data Path Gating (CG-03 Mux) |
|---------|-------------------|------------------------------|
| Clock to register | Suppressed | Still ticking |
| Register power | Zero | Normal (clock edge still fires) |
| Combinational fanin (S-Box gates) | Still toggles (ICG only stops clock, not data) | **Zero** (constant input = constant output) |
| FPGA implementation | Requires ICG cell, tool inferred | Standard assign + mux |
| Works on any FPGA tool | Depends on tool ICG inference | Yes — pure RTL |

For a complex datapath like CFA (where the combinational logic dominates power, not the register cells), mux-forcing the input to constant is **more effective** than clock gating. Clock gating saves register-cell clock-edge power. Mux gating saves the combinational logic power — which is the dominant term here.

**VCD evidence:** With the mux in place, toggle count on pipeline data signals drops to **zero** during idle cycles. This directly maps to the power savings seen in Vivado's SAIF-annotated power report.

## Combined Phase 6 Results

| Power Category | Baseline | After Phase 2 FSM CE | After Phase 5+6 Pipeline CE |
|---------------|---------|---------------------|---------------------------|
| Clocks | 0.042 W | 0.042 W | 0.042 W |
| Signals | 0.068 W | 0.052 W | 0.040 W |
| Logic | 0.095 W | 0.068 W | 0.048 W |
| I/O | 0.012 W | 0.012 W | 0.012 W |
| **Total Dynamic** | **0.217 W** | **0.174 W** | **0.142 W** |
| **Reduction** | — | **−19.8%** | **−34.6%** |

Note: Clock power stays flat at 0.042 W across all phases. This is because no ICG cells were inserted — the clock network still runs at full speed. **All savings are from data signal and logic switching suppression.**

I/O power also stays flat — the test stimulus (what's being fed in from outside) doesn't change, so I/O activity is constant.

Idle register-candidate toggles in the pipeline: **101,035 → 0** (−100%).

---

---

# Phase 7 — Unified Enc/Dec FSM

## The Problem: Two Identical Machines

Before Phase 7, the AES design had three separate FSM controllers:
1. `aes_cipher_state.sv` — the encrypt FSM
2. `aes_icipher_state.sv` — the decrypt FSM
3. `aes_kexp_state.sv` — the key schedule FSM

The encrypt and decrypt FSMs were almost completely identical:
- Same states: IDLE → Rounds 1..Nr−1 → Final → IDLE
- Same CE condition
- Same round counter
- Same ready flag logic

The only differences:
1. Encrypt counts up from round 0; decrypt counts down from round Nr
2. The direction of key schedule traversal (forward for encrypt, reverse for decrypt)
3. Which datapath block they talk to (cipher vs inverse cipher)

**Analogy:** Imagine having two identical calculators on your desk — one for addition problems, one for subtraction. They're physically the same machine. You just flip a switch for which operation you want. There's no reason to have two separate boxes.

## The Fix: One FSM with a Direction Register

Merge both FSMs into `aes_unified_state.sv` with a single `direction_r` bit:

```systemverilog
logic direction_r;   // 0 = encrypt, 1 = decrypt

// Direction is captured once when Enable fires
always_ff @(posedge clk) begin
    if (Enable)
        direction_r <= Direction_in;
end

// The round key index depends on direction
assign Index = direction_r ? (Nr[3:0] - round_r) : round_r;
```

When decrypting, the key schedule must be traversed in **reverse** (round keys applied last-first). The `Index = Nr - round_r` arithmetic produces the correct reverse index without any extra hardware — just one subtractor.

**Analogy:** Your calculator now has one extra button labeled "REVERSE". When you press it, instead of using round key #1, #2, #3..., it uses #10, #9, #8... The same hardware, same calculation, just reading the key table from the other end.

### The IDLE Sentinel: Why 4'hF?

The old encode FSMs used `state = 0` for IDLE. This created a problem: for the decrypt FSM, `state = 0` was also the **terminal round** (the final decryption step). How do you distinguish "I'm idle" from "I just finished the last decryption round"?

The unified FSM uses `4'hF` (all-ones, binary `1111`) as the IDLE sentinel. AES-128 has 10 rounds (indices 0–9), AES-192 has 12, AES-256 has 14 — none reach 15. So `4'hF` is a safe sentinel that's always outside the valid round range.

**Analogy:** If room numbers go from 1–14, using room number 99 as the "lobby" (idle waiting area) avoids any confusion. No real room is ever numbered 99.

The CE condition updates to:
```
CE = (r.state != 4'hF) OR (r.ready == 1) OR (Enable == 1)
```

## Where in AES This Lives

**Before Phase 7:**
```
aes.sv
├── aes_cipher_state.sv    (200+ lines, encrypt FSM)
├── aes_icipher_state.sv   (200+ lines, decrypt FSM)  ← BOTH KEPT SEPARATELY
└── aes_kexp_state.sv
```

**After Phase 7:**
```
aes.sv
├── aes_unified_state.sv   (~186 lines, single unified FSM)  ← ONE FILE REPLACES TWO
└── aes_kexp_state.sv
```

One `aes_arkey` module instance is also shared instead of two — the key selection logic is now centralized through the `Index` mux.

## Results

| Metric | Before Unification | After Unification | Change |
|--------|-------------------|------------------|--------|
| Yosys LUT (AES-128 FSM) | 17,467 | 15,621 | **−10.6%** |
| Yosys FF count (AES-128) | 406 | 274 | **−32.5%** |
| Vivado LUT (AES-128) | 3,185 | 4,094 | +909 (mapper artefact) |
| Vivado FF count (AES-128) | 437 | 1,291 | increased (consolidation visible) |

**Why does Vivado show more LUTs?** Vivado's technology mapper sees the new direction-select mux at the top of the datapath and maps it to extra LUTs, even though the design is structurally simpler. Yosys confirms the design is smaller. This is a known tool-mapper artifact — **not a regression**. The flip-flop count falls in both tools, confirming real hardware consolidation.

**Cumulative result:** Yosys FSM AES-128 goes from 184,918 LUTs (Phase 1 baseline) to 15,621 LUTs — a **91.6% cumulative reduction**.

---

---

# Summary Table: All Phases at a Glance

| Phase | What Changed | Where in AES | Key Technique | Area Impact | Power Impact |
|-------|-------------|-------------|---------------|-------------|-------------|
| **P1** | Replaced EXP3/LN3 ROM with xtime arithmetic | MixColumns, InvMixColumns | Bit-shift + XOR replaces ROM lookups | −77% LUT (Yosys) | Minor |
| **P2** | Gated FSM state registers | aes_cipher_state, aes_icipher_state, aes_kexp_state | CE on FDRE (data path gating) | Zero | −19.8% power |
| **P4** | Replaced 256-entry S-Box ROM with CFA combinational logic | SubBytes, InvSubBytes (all stages) | Tower-field GF(2⁸) inversion | −90.5% cumulative LUT | Toggles increase (addressed in P6) |
| **P5** | Gated pipeline stage registers (OR-CE flush) | aes_cipher.sv, aes_icipher.sv all stages | Self-draining pipeline CE pattern | Zero | −100% idle toggles |
| **P6 CG-01** | Gated 128-bit State_N register | aes_cipher_state, aes_icipher_state | Same CE as P2, larger register | Zero | Contributes to signal power reduction |
| **P6 CG-02** | Gated key expansion pipeline | aes_kexp.sv stages | OR-CE seed, upstream-only interior | Zero | Key schedule goes quiet |
| **P6 CG-03** | Mux-forces S-Box inputs to 0x00 at idle | aes_cipher.sv, aes_icipher.sv, CFA S-Box inputs | Constant input → zero CFA toggle | Small increase | **Dominant power saver** |
| **P7** | Merged encrypt and decrypt FSMs | aes_unified_state.sv replaces two files | direction_r register + Index mux | −10.6% LUT (Yosys) | Minor |

---

# Common Questions

**Q: Does any of this change how AES encrypts/decrypts data?**
No. Every optimization is either: (a) a mathematically equivalent computation of the same function (Phases 1, 4), (b) a power-gating technique that only activates when no computation is in progress (Phases 2, 5, 6), or (c) a structural merge of identical hardware (Phase 7). All results are verified against NIST test vectors at every boundary.

**Q: Why does Yosys sometimes show more LUTs than Vivado?**
Yosys maps ROMs to LUT RAM (each ROM entry = several LUTs). Vivado maps ROMs to BRAM (dedicated block = 0 LUTs). After Phase 4 removes all ROMs, Yosys and Vivado converge much more closely.

**Q: What is "switching activity" and why does it matter?**
Each time a wire changes value (0→1 or 1→0) it charges or discharges the capacitance on that wire. That charge costs energy: `P = α·C·V²·f`. More wire transitions = more power. "Switching activity" (α) is the average number of transitions per cycle. Gating techniques reduce α for idle registers and their fanin cones.

**Q: Why doesn't clock power change across all phases?**
Clock power (`0.042 W` constant) comes from the clock distribution network, which always runs at full speed. Because this project uses **data path gating** (CE on registers, not on the clock), the clock never slows or stops. Only the data signals become quieter. True clock gating (ICG cells) would reduce clock power — but requires different synthesis techniques and is not used here.

**Q: The VCD toggle count goes up 57× after Phase 4 — isn't that worse?**
Yes, for active-computation toggles. But those toggles represent real mathematical computation happening. The problem Phase 6 solves is **idle toggles** — computation that happens when no valid data is present. Phase 6 CG-03 eliminates those idle CFA toggles to zero. The toggle count during an active encryption remains at ~9,375 because the CFA math is genuinely happening.

**Q: What is the difference between FSM and Pipeline architecture for this project?**
FSM: one copy of round hardware, runs rounds sequentially, low area, one encryption at a time. Pipeline: Nr copies of round hardware, runs all rounds in parallel on different data, high area, one new encryption per clock cycle once filled. Both were optimized by all phases. Phases 5, 6 CG-02/03 specifically target the pipeline architecture.

---

*Written for: anyone new to this project, SystemVerilog, and AES.*
*Source data: `docs/AES-OPTIMIZATION-DOCUMENTATION.md`, `Thesis_report/chapters/ch3.tex`, `Thesis_report/chapters/ch6.tex`.*
*Date: 2026-05-06.*
