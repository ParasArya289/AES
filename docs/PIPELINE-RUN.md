# Running AES in Pipeline Mode

## Overview

This project implements two AES hardware architectures: a pipelined datapath (`aes.sv`) and a finite state machine datapath (`aes_state.sv`). The testbench (`rtl/aes_tb.sv`) selects between them via a single `parameter enable_pipeline`. The pipeline architecture achieves higher throughput by completing one round per clock cycle at the cost of roughly 6x more LUTs than the FSM variant. The FSM reuses a single combinational datapath across multiple clock cycles, trading throughput for area efficiency.

---

## Prerequisites

**Python dependency** — the test vector generator uses PyCryptodome:

```bash
pip3 install --user pycryptodome
```

**Verilator** — the simulation flow expects Verilator at:

```
/opt/verilator/bin/verilator
```

Override with `VERILATOR=/path/to/verilator` on the make command line if your installation differs.

---

## Step 1 — Enable Pipeline Mode

Open `rtl/aes_tb.sv` and change line 12:

```systemverilog
// Before (default — FSM mode):
parameter enable_pipeline = 0;

// After (pipeline mode):
parameter enable_pipeline = 1;
```

This is the only source change required. The generate block at lines 133-157 of `aes_tb.sv` instantiates either `aes` (pipeline, `aes.sv`) or `aes_state` (FSM, `aes_state.sv`) depending on this parameter value.

> **Note:** The project default is `enable_pipeline = 0` (FSM mode). After finishing pipeline runs, restore the file to `enable_pipeline = 0` before committing or switching back to FSM testing.

---

## Step 2 — Run the Simulation

### Simplest command

```bash
make simulate
```

Runs only the Verilator simulation step using whatever test vectors already exist in the working directory.

### Full flow (recommended for first run)

```bash
make all
```

Runs all four stages in sequence:

| Stage | Target | What it does |
|-------|--------|--------------|
| 1 | `generate` | Calls `py/generate.py` to produce test vectors |
| 2 | `compile` | Compiles the C++ reference implementation (`cpp/main`) |
| 3 | `run` | Runs the C++ reference to verify test vectors are correct |
| 4 | `simulate` | Runs Verilator simulation, prints pass/fail |

### Overriding Makefile variables

Append variable assignments to any make command:

```bash
# AES-192 with 4 test vectors
make simulate KEY_LENGTH=1 CASE_NUMBER=4

# AES-256, full flow, generate waveform
make all KEY_LENGTH=2 WAVE=on

# AES-128 with custom timeout
make simulate MAXTIME=5000000000
```

**KEY_LENGTH values:**

| KEY_LENGTH | AES Variant | Key bits |
|------------|-------------|----------|
| 0 (default) | AES-128 | 128 |
| 1 | AES-192 | 192 |
| 2 | AES-256 | 256 |

---

## Reading the Output

A successful simulation run for one test vector prints:

```
KEY:     2b7e151628aed2a6abf7158809cf4f3c
DATA:    6bc1bee22e409f96e93d7e117393172a
ENCRYPT: 3ad77bb40d7a3660a89ecaf32466ef97   <- ciphertext from DUT
CORRECT: 3ad77bb40d7a3660a89ecaf32466ef97   <- expected value from encrypt.txt
TEST SUCCEEDED                               <- green: encrypt matches
DECRYPT: 6bc1bee22e409f96e93d7e117393172a   <- decrypted result from DUT
CORRECT: 6bc1bee22e409f96e93d7e117393172a   <- expected value from data.txt
TEST SUCCEEDED                               <- green: decrypt round-trip matches
Execution time was 2 seconds.
simulation finished @48500ps
```

**Status messages:**

| Message | Color | Meaning |
|---------|-------|---------|
| `TEST SUCCEEDED` | green | DUT output matches reference |
| `TEST FAILED` | red | DUT output does not match reference |
| `TEST STOPPED` | yellow | Simulation hit `MAXTIME` before `$finish` |

### TEST STOPPED — what to do

`TEST STOPPED` means the Verilator simulation reached the `MAXTIME` timeout (default `1000000000 ps`) before the testbench completed. The pipeline DUT can take longer to simulate than the FSM depending on key length and case count. Increase the timeout:

```bash
make simulate MAXTIME=5000000000
```

Try doubling or tripling the default value until `TEST SUCCEEDED` or `TEST FAILED` appears.

---

## Step 3 — Restore FSM Mode

After pipeline runs, restore the default so commits and subsequent runs use the FSM:

```bash
# Edit rtl/aes_tb.sv line 12 back to:
parameter enable_pipeline = 0;
```

Or use sed (verify the line number matches your file):

```bash
sed -i '' 's/parameter enable_pipeline = 1;/parameter enable_pipeline = 0;/' rtl/aes_tb.sv
```

---

## Quick Reference — Makefile Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KEY_LENGTH` | `0` | AES key size: 0=128-bit, 1=192-bit, 2=256-bit |
| `CASE_NUMBER` | `1` | Number of test vectors to generate and run |
| `MAXTIME` | `1000000000` | Simulation timeout in picoseconds |
| `WAVE` | `off` | Set to `on` to generate `aes.vcd` waveform dump |
| `VERILATOR` | `/opt/verilator/bin/verilator` | Path to Verilator binary |

---

## Make Targets Summary

| Target | Command | Description |
|--------|---------|-------------|
| Full flow | `make all` | generate + compile + run + simulate |
| Vectors only | `make generate` | Generate test vectors via `py/generate.py` |
| C++ compile | `make compile` | Compile C++ reference (`cpp/main`) |
| C++ verify | `make run` | Run C++ reference against test vectors |
| Simulate only | `make simulate` | Run Verilator simulation (no regeneration) |
