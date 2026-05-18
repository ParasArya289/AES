#!/usr/bin/env bash
# scripts/synth_all.sh  —  run all synthesis jobs across phase boundaries
#
# Boundaries synthesized (LUT/FF-changing rows only):
#   Row 1: ef268b9  baseline_pre_xtime  both tops
#   Row 2: 6d7bc44  post_xtime          both tops
#   Row 4a: a9da249 pipeline_baseline   pipeline top only (SYNTH-04)
#   Row 4b: ff63f33 post_cfa            both tops
#   Row 6: c5fc13f  post_fine_cg        both tops
#
# Rows 3 (post_ce_fsm) and 5 (post_pipeline_ce) are CE-only; LUT/FF = same as
# row 2 and row 4b respectively. These are NOT synthesized here; marked in
# PHASE-COMPARISON.md as "= row above".
#
# Row 7 (post_unified_fsm): commit TBD — Phase 7 not yet executed; skipped.
#
# Parallelism: launch all three key-size jobs for each (commit, top) pair
# as background processes, then wait. Reduces serial 144-min total to ~50 min.
#
# Usage: bash scripts/synth_all.sh

set -euo pipefail

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$BASEDIR/scripts/synth_one.sh"

# Delete stale combined.v snapshot before any synthesis
rm -f "$BASEDIR/sim/combined.v"

# Initialize results file header
RESULTS="$BASEDIR/scripts/synth_results.txt"
echo "label,top,key_length,lut,ff,ldce" > "$RESULTS"

run_all_kl() {
  local COMMIT="$1" LABEL="$2" TOP="$3"
  # Run AES-128, 192, 256 in parallel background processes
  bash "$SCRIPT" "$COMMIT" "$LABEL" "$TOP" 0 &
  bash "$SCRIPT" "$COMMIT" "$LABEL" "$TOP" 1 &
  bash "$SCRIPT" "$COMMIT" "$LABEL" "$TOP" 2 &
  wait   # wait for all three key-size jobs to finish before next boundary
}

echo "=== Phase 8 synthesis run starting ==="
echo "Logs will be written to: $BASEDIR/scripts/logs/"
echo "Results will be written to: $RESULTS"

# Row 1: Baseline pre-xtime
run_all_kl ef268b9 baseline_pre_xtime aes_state
run_all_kl ef268b9 baseline_pre_xtime aes

# Row 2: Post-xtime + EXP3/LN3 removal
run_all_kl 6d7bc44 post_xtime aes_state
run_all_kl 6d7bc44 post_xtime aes

# Row 4a: Pre-v2.0 pipeline baseline (SYNTH-04 — pipeline only)
run_all_kl a9da249 pipeline_baseline aes

# Row 4b: Post-CFA S-Box
run_all_kl ff63f33 post_cfa aes_state
run_all_kl ff63f33 post_cfa aes

# Row 6: Post-fine-grained CG (current HEAD area)
run_all_kl c5fc13f post_fine_cg aes_state
run_all_kl c5fc13f post_fine_cg aes

echo "=== All synthesis jobs complete ==="
echo "Results file: $RESULTS"
echo "Log count: $(ls $BASEDIR/scripts/logs/yosys_*.log 2>/dev/null | wc -l | tr -d ' ')"
