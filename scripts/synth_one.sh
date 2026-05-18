#!/usr/bin/env bash
# scripts/synth_one.sh  —  single-boundary Yosys synthesis wrapper
#
# Usage: bash scripts/synth_one.sh <commit> <label> <top> <key_length>
#   commit     = git commit hash (e.g. ef268b9)
#   label      = short name for log files (e.g. baseline_pre_xtime)
#   top        = aes_state (FSM) or aes (pipeline)
#   key_length = 0 (AES-128), 1 (AES-192), 2 (AES-256)
#
# Produces: scripts/logs/yosys_<label>_<top>_kl<key_length>.log
# Extracts LUT/FF/LDCE counts and appends to scripts/synth_results.txt

set -euo pipefail

COMMIT="$1"
LABEL="$2"
TOP="$3"
KL="$4"

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$BASEDIR/scripts/logs"
mkdir -p "$LOGDIR"

LOGFILE="$LOGDIR/yosys_${LABEL}_${TOP}_kl${KL}.log"
RESULTS="$BASEDIR/scripts/synth_results.txt"

echo "[synth_one] commit=$COMMIT label=$LABEL top=$TOP kl=$KL"

# 1. Partial checkout — only rtl/ and sim/files.f
git -C "$BASEDIR" checkout "$COMMIT" -- rtl/ sim/files.f

# 2. Regenerate aes_const.sv for this key length
cd "$BASEDIR"
export BASEDIR KEY_LENGTH="$KL" CASE_NUMBER=1
bash rtl/initialize.sh

# 3. Build file list: sv2v needs absolute paths; strip the ../../ prefix
#    sim/files.f uses paths like ../../rtl/foo.sv relative to sim/work/
#    We run sv2v from BASEDIR so rewrite to rtl/foo.sv
SV_FILES=$(grep '\.sv$' "$BASEDIR/sim/files.f" | grep -v '_tb\.sv' | sed 's|../../||' | sed "s|^|$BASEDIR/|")

# 4. Convert to Verilog-2005
FLAT_V="/tmp/aes_flat_${LABEL}_${TOP}_kl${KL}.v"
sv2v $SV_FILES > "$FLAT_V"

# 5. Run Yosys synthesis
yosys -p "
  read_verilog $FLAT_V
  hierarchy -check -top $TOP
  synth_xilinx -top $TOP -family xc7
  stat -tech xilinx
" 2>&1 | tee "$LOGFILE"

# 6. Extract numbers from the LAST stat block in the log.
#    Yosys stat -tech xilinx output format: "<count>   <CELL_NAME>"
#    The log contains per-module sub-blocks plus one final total block.
#    Strategy: find the last "Estimated number of LCs" line; extract the
#    30 lines before it which contain the total design LUT/FF/LDCE counts.
LAST_LC_LINE=$(grep -n "Estimated number of LCs:" "$LOGFILE" | tail -1 | cut -d: -f1)
STAT_START=$((LAST_LC_LINE - 30))
LUT=$(sed -n "${STAT_START},${LAST_LC_LINE}p" "$LOGFILE" | grep -E '^\s+[0-9]+\s+LUT[1-6]$' | awk '{sum += $1} END {print sum}')
FF=$(sed -n "${STAT_START},${LAST_LC_LINE}p" "$LOGFILE" | grep -E '^\s+[0-9]+\s+(FDRE|FDSE)$' | awk '{sum += $1} END {print sum}')
LDCE=$(sed -n "${STAT_START},${LAST_LC_LINE}p" "$LOGFILE" | grep -E '^\s+[0-9]+\s+LDCE$' | awk '{print $1}')
LDCE="${LDCE:-0}"

echo "[synth_one] RESULT: label=$LABEL top=$TOP kl=$KL LUT=$LUT FF=$FF LDCE=$LDCE"

# 7. Append CSV to results file
echo "${LABEL},${TOP},${KL},${LUT},${FF},${LDCE}" >> "$RESULTS"

# 8. Restore HEAD rtl/ and sim/files.f
#    Step A: restore files tracked at HEAD
git -C "$BASEDIR" checkout HEAD -- rtl/ sim/files.f
#    Step B: remove any files that the boundary checkout added but HEAD doesn't track.
#    These appear as staged "new file" entries (A prefix in git status --short).
#    Example: c5fc13f has aes_cipher_state.sv; HEAD has aes_unified_state.sv instead.
EXTRA_FILES=$(git -C "$BASEDIR" status --short rtl/ | awk '/^A /{print $2}')
if [ -n "$EXTRA_FILES" ]; then
  echo "[synth_one] removing extra files not at HEAD: $EXTRA_FILES"
  git -C "$BASEDIR" rm --cached $EXTRA_FILES
  rm -f $(echo "$EXTRA_FILES" | sed "s|^|$BASEDIR/|")
fi
cd "$BASEDIR"
export KEY_LENGTH=0 CASE_NUMBER=1
bash rtl/initialize.sh   # restore aes_const.sv to HEAD state (AES-128 default)

echo "[synth_one] done — log: $LOGFILE"
