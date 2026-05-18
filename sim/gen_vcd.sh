#!/bin/bash
# gen_vcd.sh — Build and run VCD generation for all AES phases.
#
# Produces one VCD per (phase × topology) pair using the frozen combined_v
# snapshots from synthesis/combined_v/, so each dump reflects exactly the
# RTL that was synthesised for that phase.
#
# Output VCDs:
#   baseline_fsm.vcd                 Phase 01 — pre-xtime, FSM topology
#   baseline_pipeline.vcd            Phase 04a — pipeline baseline (no CE gating)
#   phase02_fsm.vcd                  Phase 02 — post-xtime, FSM
#   phase02_pipeline.vcd             Phase 02 — post-xtime, pipeline
#   phase03_fsm.vcd                  Phase 03 — post-CE-FSM, FSM
#   phase03_pipeline.vcd             Phase 03 — post-CE-FSM, pipeline
#   phase05_fsm.vcd                  Phase 05 — post-pipeline-CE, FSM
#   phase05_pipeline.vcd             Phase 05 — post-pipeline-CE, pipeline
#   phase06_fsm.vcd                  Phase 06 — post-fine-CG, FSM
#   phase06_pipeline.vcd             Phase 06 — post-fine-CG, pipeline
#
# Note: Phase 07 (unified enc/dec FSM) is excluded — it belongs to the
#       LUT-reduction study, not the clock-gating switching-activity analysis.
#
# Usage (from repo root):
#   BASEDIR=$(pwd) bash sim/gen_vcd.sh
#
# Optional env vars:
#   OUTDIR    — directory to write VCD files (default: sim/vcd)
#   MAXTIME   — max simulation time in ps (default: 500000)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASEDIR="${BASEDIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
OUTDIR="${OUTDIR:-$BASEDIR/sim/vcd}"
MAXTIME="${MAXTIME:-500000}"

VERILATOR="${VERILATOR:-verilator}"
if ! command -v "$VERILATOR" &>/dev/null; then
  VERILATOR=/Users/parasarya/Developer/verilator-v4.224/bin/verilator
fi

RTL_DIR="$BASEDIR/rtl"
SIM_DIR="$BASEDIR/sim"
COMB_DIR="$BASEDIR/synthesis/combined_v"

echo "============================================================"
echo " AES VCD Generator"
echo "  BASEDIR  : $BASEDIR"
echo "  OUTDIR   : $OUTDIR"
echo "  COMB_DIR : $COMB_DIR"
echo "  MAXTIME  : $MAXTIME ps"
echo "  Verilator: $VERILATOR"
echo "============================================================"

mkdir -p "$OUTDIR"

# ---- Write the C++ harness for a given top module name ------------------
write_cpp_harness() {
  local DEST="$1"
  local TOPNAME="$2"
  printf '%s\n' \
    '#include <stdlib.h>' \
    '#include <iostream>' \
    '#include <cstdlib>' \
    '#include <verilated.h>' \
    '#include <verilated_vcd_c.h>' \
    "#include \"V${TOPNAME}.h\"" \
    '' \
    'vluint64_t sim_time = 0;' \
    '' \
    'int main(int argc, char** argv, char** env)' \
    '{' \
    '  vluint64_t max_sim_time = 500000;' \
    '  const char *filename = "dump.vcd";' \
    '  if (argc >= 2) max_sim_time = atoll(argv[1]);' \
    '  if (argc >= 3) filename = argv[2];' \
    '  Verilated::commandArgs(argc, argv);' \
    "  V${TOPNAME} *dut = new V${TOPNAME};" \
    '#if VM_TRACE' \
    '  Verilated::traceEverOn(true);' \
    '  VerilatedVcdC *trace = new VerilatedVcdC;' \
    '  dut->trace(trace, 0);' \
    '  trace->open(filename);' \
    '#endif' \
    '  bool finished = false;' \
    '  while (sim_time < max_sim_time) {' \
    '    dut->rst = (sim_time < 10) ? 0 : 1;' \
    '    dut->clk ^= 1;' \
    '    dut->eval();' \
    '#if VM_TRACE' \
    '    trace->dump(sim_time);' \
    '#endif' \
    '    sim_time++;' \
    '    if (Verilated::gotFinish()) { finished = true; break; }' \
    '  }' \
    '  if (!finished) {' \
    '    std::cerr << "\033[33mWARNING: hit time limit before $finish (increase MAXTIME)\033[0m" << std::endl;' \
    '  } else {' \
    '    std::cout << "VCD written: " << filename << "  (finished @" << sim_time << " ps)" << std::endl;' \
    '  }' \
    '#if VM_TRACE' \
    '  trace->close();' \
    '#endif' \
    '  delete dut;' \
    '  return finished ? 0 : 1;' \
    '}' \
    > "$DEST"
}

# ---- Helper: build and run one variant ----------------------------------
# Args:
#   VARIANT       — unique slug used for work dir and binary name
#   ENABLE_PIPE   — 1 = pipeline (instantiates `aes`), 0 = FSM (instantiates `aes_state`)
#   COMBINED_V    — path to the frozen combined_v snapshot for this phase/topology
#   VCD_NAME      — output filename under $OUTDIR
build_and_run() {
  local VARIANT="$1"
  local ENABLE_PIPE="$2"
  local COMBINED_V="$3"
  local VCD_NAME="$4"

  if [ ! -f "$COMBINED_V" ]; then
    echo "ERROR: combined_v not found: $COMBINED_V" >&2
    exit 1
  fi

  local TOPNAME="top_${VARIANT}"
  local WORK="$SIM_DIR/vcd_work_$VARIANT"

  echo ""
  echo "------------------------------------------------------------"
  echo " Building: $VARIANT  (enable_pipeline=$ENABLE_PIPE)"
  echo "   combined_v: $(basename $COMBINED_V)"
  echo "------------------------------------------------------------"

  rm -rf "$WORK"
  mkdir -p "$WORK"

  # Wrapper SV that pins enable_pipeline and ties in the testbench
  cat > "$WORK/${TOPNAME}.sv" << SVEOF
import aes_const::*;
import aes_wire::*;
module ${TOPNAME}(input logic rst, input logic clk);
  timeunit 1ns; timeprecision 1ps;
  aes_vcd_tb #(.enable_pipeline(${ENABLE_PIPE})) dut(.rst(rst), .clk(clk));
endmodule
SVEOF

  # File list: SV packages + testbench + frozen combined_v (replaces individual RTL files)
  # combined_v already contains all sub-modules inlined — do not also list rtl/*.sv
  cat > "$WORK/files.f" << FEOF
$RTL_DIR/aes_const.sv
$RTL_DIR/aes_wire.sv
$COMBINED_V
$SIM_DIR/aes_vcd_tb.sv
$WORK/${TOPNAME}.sv
FEOF

  write_cpp_harness "$WORK/main.cpp" "$TOPNAME"

  "$VERILATOR" --cc -Wno-UNOPTFLAT -Wno-LATCH -Wno-REDEFMACRO \
    --trace -trace-max-array 128 \
    -f "$WORK/files.f" \
    --top-module "$TOPNAME" \
    --exe "$WORK/main.cpp" \
    -I"$RTL_DIR" \
    -o "gen_vcd_$VARIANT" \
    -Mdir "$WORK/obj_dir" \
    2>&1 | grep -v "^$" | grep -v "^%" || true

  make -s -j -C "$WORK/obj_dir" -f "V${TOPNAME}.mk" "gen_vcd_$VARIANT"

  local VCD_PATH="$OUTDIR/$VCD_NAME"
  "$WORK/obj_dir/gen_vcd_$VARIANT" "$MAXTIME" "$VCD_PATH"

  if [ -f "$VCD_PATH" ]; then
    local SIZE
    SIZE=$(du -h "$VCD_PATH" | cut -f1)
    echo " -> $VCD_PATH  ($SIZE)"
  else
    echo "ERROR: VCD not created for $VARIANT" >&2
    exit 1
  fi

  rm -rf "$WORK"
}

# ============================================================
# Phase matrix
# Naming convention: {phase}_{topology}.vcd
# combined_v key: kl0 = AES-128 (always used here)
# ============================================================

# ---- Baseline ---------------------------------------------------
# FSM baseline  = Phase 01 (pre-xtime, iterative state machine)
# Pipeline baseline = Phase 04a (pipeline topology before any CE gating)
build_and_run "baseline_fsm"      0 "$COMB_DIR/01_baseline_pre_xtime_fsm_kl0.v"        "baseline_fsm.vcd"

build_and_run "baseline_pipeline" 1 "$COMB_DIR/04a_pipeline_baseline_pipeline_kl0.v"   "baseline_pipeline.vcd"

# ---- Phase 02: post-xtime optimisation --------------------------
build_and_run "phase02_fsm"       0 "$COMB_DIR/02_post_xtime_fsm_kl0.v"                "phase02_fsm.vcd"

build_and_run "phase02_pipeline"  1 "$COMB_DIR/02_post_xtime_pipeline_kl0.v"           "phase02_pipeline.vcd"

# ---- Phase 03: CE-based FSM gating ------------------------------
build_and_run "phase03_fsm"       0 "$COMB_DIR/03_post_ce_fsm_fsm_kl0.v"               "phase03_fsm.vcd"

build_and_run "phase03_pipeline"  1 "$COMB_DIR/03_post_ce_fsm_pipeline_kl0.v"          "phase03_pipeline.vcd"

# ---- Phase 05: pipeline CE gating -------------------------------
build_and_run "phase05_fsm"       0 "$COMB_DIR/05_post_pipeline_ce_fsm_kl0.v"          "phase05_fsm.vcd"

build_and_run "phase05_pipeline"  1 "$COMB_DIR/05_post_pipeline_ce_pipeline_kl0.v"     "phase05_pipeline.vcd"

# ---- Phase 06: fine-grained clock gating ------------------------
build_and_run "phase06_fsm"       0 "$COMB_DIR/06_post_fine_cg_fsm_kl0.v"              "phase06_fsm.vcd"

build_and_run "phase06_pipeline"  1 "$COMB_DIR/06_post_fine_cg_pipeline_kl0.v"         "phase06_pipeline.vcd"

# ============================================================
echo ""
echo "============================================================"
echo " All VCD files written to: $OUTDIR"
ls -lh "$OUTDIR"/*.vcd
echo ""
echo " Switching-activity summary (transitions / sim-duration ps):"
python3 - "$OUTDIR" << 'PYEOF'
import os, re, sys

vcd_dir = sys.argv[1]
files = sorted(f for f in os.listdir(vcd_dir) if f.endswith(".vcd"))

print(f"\n  {'VCD file':<35} {'Window':>14}  {'Transitions':>12}  {'Toggles/ps':>11}")
print("  " + "-" * 78)
for fname in files:
    path = os.path.join(vcd_dir, fname)
    timestamps, transitions, in_header = [], 0, True
    with open(path, "r", errors="replace") as f:
        for line in f:
            line = line.rstrip()
            if line.startswith("$end"):
                in_header = False
            elif line.startswith("#"):
                timestamps.append(int(line[1:]))
            elif not in_header:
                if re.match(r'^[01xXzZ]\S', line):
                    transitions += 1
                elif re.match(r'^[bBrR]', line):
                    transitions += 1
    t0, t1 = min(timestamps, default=0), max(timestamps, default=0)
    dur = t1 - t0
    tps = transitions / dur if dur > 0 else 0
    print(f"  {fname:<35} {t0}..{t1} ps  {transitions:>12,}  {tps:>11.1f}")
print()
PYEOF

echo " Vivado workflow:"
echo "   1. Synthesise baseline netlist  →  Report Power → Load baseline_fsm.vcd or"
echo "      baseline_pipeline.vcd"
echo "   2. Repeat with each phase netlist using the matching topology VCD"
echo "   3. Clock period = 10 ns (100 MHz, Basys-3 W5)"
echo "   4. Compare Dynamic / Logic / Signals / Clock columns"
echo "============================================================"
