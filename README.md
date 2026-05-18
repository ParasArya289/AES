# AES Hardware Optimization

Hardware and software implementation of the AES algorithm (FIPS-197), targeting the Artix-7 xc7a35t FPGA. The RTL is written in SystemVerilog and covers 128/192/256-bit key lengths with both FSM and pipelined architectures.

The project goal is not to change what AES computes, but to reduce LUT area, flip-flop toggle activity, and dynamic power — without altering cryptographic semantics.

---

## Architectures

| Architecture | Description | Trade-off |
|---|---|---|
| **FSM** | Single datapath, reused each round via state machine | Small area, lower throughput |
| **Pipeline** | Nr−1 staged datapaths, one per round | High throughput, larger area |

Both architectures include key expansion, encryption, and decryption for all three key sizes.

---

## Optimization Phases

### Phase 1 — xtime Arithmetic and Table Elimination

Replaced GF(2⁸) multiplication using `EXP3[]`/`LN3[]` log tables with direct xtime combinational arithmetic (`shift + conditional XOR`). Removed 512×8-bit ROM entries and all port stubs across 10 modules.

### Phase 2 — Clock Enable Gating v1 (FSM State Registers)

Wrapped FSM state registers with a clock enable condition:
```
CE = (r.state != IDLE) OR (r.ready == 1) OR (Enable == 1)
```
Idle registers stop toggling, cascading power savings through their fanout cones. This is **data path gating**, not hardware clock gating — the clock still arrives at every flip-flop.

### Phase 4 — CFA S-Box (Composite Field Arithmetic)

Replaced the 256×8-bit S-Box ROM with a fully combinational implementation based on Canright's composite-field inversion in GF((2⁴)²). Eliminated the `SBox[]`/`IBox[]` port hierarchy across all modules.

### Phase 5 — Pipeline Clock Enable (OR-CE Flush Pattern)

Introduced the OR-CE flush pattern to allow in-flight pipeline data to drain correctly when Enable de-asserts:
```
CE[i] = Ready_Reg[i-2] OR Ready_Reg[i-1]
```

### Phase 6 — Fine-Grained Clock Enable Gating

Three sub-techniques:
- **CG-01**: CE on the FSM `State_N` next-state register
- **CG-02**: OR-CE applied to key expansion pipeline stages
- **CG-03**: Mux-gating CFA S-Box inputs — forces `8'h00` to S-Box when a pipeline stage is idle, making all internal S-Box nodes constant and reducing toggle activity to zero

### Phase 7 — Unified Enc/Dec FSM

Merged `aes_cipher_state.sv` and `aes_icipher_state.sv` into a single `aes_unified_state.sv` using a `direction_r` register. Decrypt key traversal is handled by inverting the round counter index (`Nr - round_counter`) rather than duplicating control logic.

---

## Cumulative Results

### LUT Count — Yosys (AES-128 FSM)

| Phase Boundary | LUT Count | Reduction |
|---|---|---|
| Baseline | 7,886 | — |
| After xtime + table elimination | ~1,800 | −77% |
| After CFA S-Box | ~1,100 | −86% |
| After fine-grained CE + unified FSM | ~660 | **−91.6%** |

### Resource Utilization — Vivado (Artix-7 xc7a35t)

#### FSM Version

| Key Length | 128  | 192  | 256  |
|:-----------|:----:|:----:|:----:|
| LUT        | 6794 | 8857 | 7866 |
| FF         | 412  | 469  | 543  |

#### Pipelined Version

| Key Length | 128   | 192   | 256   |
|:-----------|:-----:|:-----:|:-----:|
| LUT        | 38766 | 47945 | 55001 |
| FF         | 2763  | 3227  | 3691  |

### Dynamic Power — Vivado (AES-128 Pipeline, SAIF-annotated)

| Condition | Dynamic Power |
|---|---|
| No CE gating | 0.217 W |
| Full CE + mux gating | 0.142 W |
| **Reduction** | **−34.6%** |

---

## Data Path Gating vs Clock Gating

This project implements **data path gating**, not hardware clock gating (ICG cells). The distinction:

| Feature | Clock Gating (ICG) | Data Path Gating (CE/Mux) |
|---|---|---|
| Clock net | Suppressed | Still active |
| Register power | Zero (no clock edge) | Normal |
| Combinational fanin | May still toggle | Frozen (constant input → constant output) |
| FPGA primitive | Requires ICG IP | Standard FDRE CE pin |
| Portability | Tool/technology specific | Purely RTL |

For complex datapaths like the CFA S-Box (~100 gates), the combinational logic dominates total power. Forcing a constant input via mux achieves zero toggle activity across all internal nodes — equivalent in practical effect to clock gating that logic, but without requiring tool-inserted ICG cells.

---

