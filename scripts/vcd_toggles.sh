#!/usr/bin/env bash
# scripts/vcd_toggles.sh  —  generate VCDs and count toggles at specified boundary
#
# Usage: bash scripts/vcd_toggles.sh <commit> <label>
#   commit = git commit hash for the boundary
#   label  = short name appended to toggle_results.txt entries
#
# Runs KEY_LENGTH=0, 1, 2 simulations sequentially (not parallel — Verilator
# writes to sim/work/aes.vcd each time; parallel would conflict).
# Appends results to scripts/toggle_results.txt via toggle_count.py.

set -euo pipefail

COMMIT="${1:?Usage: $0 <commit> <label>}"
LABEL="${2:?Usage: $0 <commit> <label>}"

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
VERILATOR="/Users/parasarya/Developer/verilator-v4.224/bin/verilator"

# Checkout boundary RTL
git -C "$BASEDIR" checkout "$COMMIT" -- rtl/ sim/files.f

for KL in 0 1 2; do
  echo "[vcd_toggles] commit=$COMMIT label=$LABEL kl=$KL"

  cd "$BASEDIR"
  export BASEDIR KEY_LENGTH="$KL" CASE_NUMBER=1 WAVE=on VERILATOR
  bash rtl/initialize.sh

  # Run simulation — produces sim/work/aes.vcd
  bash sim/run.sh

  VCD="$BASEDIR/sim/work/aes.vcd"
  if [ ! -f "$VCD" ]; then
    echo "[vcd_toggles] ERROR: $VCD not produced for kl=$KL" >&2
    continue
  fi

  ENTRY_LABEL="${LABEL}_kl${KL}"
  python3 "$BASEDIR/scripts/toggle_count.py" "$VCD" "$ENTRY_LABEL"
done

# Restore HEAD RTL
git -C "$BASEDIR" checkout HEAD -- rtl/ sim/files.f
cd "$BASEDIR"
export KEY_LENGTH=0 CASE_NUMBER=1 WAVE=""
bash rtl/initialize.sh

echo "[vcd_toggles] done — results appended to scripts/toggle_results.txt"
