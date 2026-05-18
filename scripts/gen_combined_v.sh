#!/usr/bin/env bash
# scripts/gen_combined_v.sh
#
# Generate one flat combined.v per phase boundary using sv2v.
# Output directory: synthesis/combined_v/
#
# Each file is named:
#   <phase_label>_<top>_kl<key_length>.v
# where top is "fsm" or "pipeline" and key_length is 0/1/2.
#
# Usage:
#   bash scripts/gen_combined_v.sh              # all phases, all tops, all key sizes
#   bash scripts/gen_combined_v.sh --dry-run    # print what would be generated, no git ops
#   bash scripts/gen_combined_v.sh --phase 3    # single phase (1-indexed)
#   bash scripts/gen_combined_v.sh --top fsm    # fsm or pipeline only
#   bash scripts/gen_combined_v.sh --kl 0       # single key length only
#
# Phase boundary commits (from Phase 8 research, verified 2026-04-27):
#   1  baseline_pre_xtime      ef268b9   FSM only (no pipeline baseline at this commit)
#   2  post_xtime              6d7bc44   FSM + Pipeline
#   3  post_ce_fsm             8d571b9   FSM + Pipeline
#   4a pipeline_baseline       a9da249   Pipeline only (pre-CFA; FSM same as row 3)
#   4b post_cfa_sbox           6464897   FSM + Pipeline
#   5  post_pipeline_ce        4460baa   FSM + Pipeline
#   6  post_fine_cg            c5fc13f   FSM + Pipeline
#   7  post_unified_fsm        f183705   FSM only (unified enc/dec; pipeline unchanged)

set -euo pipefail

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTDIR="$BASEDIR/synthesis/combined_v"

# ── Phase definitions ────────────────────────────────────────────────────────
# Format: "label commit fsm_top pipeline_top"
# fsm_top / pipeline_top = module name, or "-" if this architecture doesn't
# apply at this boundary.
declare -a PHASES=(
  "01_baseline_pre_xtime   ef268b9  aes_state  -"
  "02_post_xtime           6d7bc44  aes_state  aes"
  "03_post_ce_fsm          8d571b9  aes_state  aes"
  "04a_pipeline_baseline   a9da249  -          aes"
  "04b_post_cfa_sbox       6464897  aes_state  aes"
  "05_post_pipeline_ce     4460baa  aes_state  aes"
  "06_post_fine_cg         c5fc13f  aes_state  aes"
  "07_post_unified_fsm     e71e684  aes_state  -"
)

# ── Argument parsing ─────────────────────────────────────────────────────────
DRY_RUN=false
FILTER_PHASE=""
FILTER_TOP=""
FILTER_KL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)  DRY_RUN=true ;;
    --phase)    FILTER_PHASE="$2"; shift ;;
    --top)      FILTER_TOP="$2"; shift ;;
    --kl)       FILTER_KL="$2"; shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
  shift
done

# ── Helpers ──────────────────────────────────────────────────────────────────
log()  { echo "[gen_combined_v] $*"; }
skip() { echo "[gen_combined_v] SKIP $*"; }

# Save working branch/HEAD before any checkouts
ORIG_HEAD=$(git -C "$BASEDIR" rev-parse HEAD)
ORIG_BRANCH=$(git -C "$BASEDIR" symbolic-ref --short HEAD 2>/dev/null || echo "detached")

restore_head() {
  log "Restoring HEAD: $ORIG_BRANCH ($ORIG_HEAD)"
  git -C "$BASEDIR" checkout HEAD -- rtl/ sim/files.f 2>/dev/null || true
  # Remove files added by a boundary checkout that don't exist at HEAD
  EXTRA=$(git -C "$BASEDIR" status --short rtl/ 2>/dev/null | awk '/^A /{print $2}')
  if [ -n "$EXTRA" ]; then
    git -C "$BASEDIR" rm --cached $EXTRA 2>/dev/null || true
    echo "$EXTRA" | sed "s|^|$BASEDIR/|" | xargs rm -f 2>/dev/null || true
  fi
  cd "$BASEDIR"
  export BASEDIR KEY_LENGTH=0 CASE_NUMBER=1
  bash rtl/initialize.sh > /dev/null 2>&1
  log "Restore complete."
}

# Ensure restore always runs on exit, even on error
trap restore_head EXIT

# ── Main loop ────────────────────────────────────────────────────────────────
mkdir -p "$OUTDIR"

PHASE_IDX=0
GENERATED=0
SKIPPED=0

for PHASE_DEF in "${PHASES[@]}"; do
  PHASE_IDX=$((PHASE_IDX + 1))

  read -r LABEL COMMIT FSM_TOP PIPE_TOP <<< "$PHASE_DEF"

  # Phase filter
  if [ -n "$FILTER_PHASE" ] && [ "$PHASE_IDX" != "$FILTER_PHASE" ]; then
    continue
  fi

  # Determine which tops to generate for this phase
  declare -a TOPS=()
  if [ "$FSM_TOP" != "-" ]; then
    [ -z "$FILTER_TOP" ] || [ "$FILTER_TOP" = "fsm" ] && TOPS+=("fsm:$FSM_TOP")
  fi
  if [ "$PIPE_TOP" != "-" ]; then
    [ -z "$FILTER_TOP" ] || [ "$FILTER_TOP" = "pipeline" ] && TOPS+=("pipeline:$PIPE_TOP")
  fi

  if [ ${#TOPS[@]} -eq 0 ]; then
    skip "phase $LABEL — no matching top for filter '$FILTER_TOP'"
    continue
  fi

  log "─────────────────────────────────────────────────"
  log "Phase $PHASE_IDX: $LABEL  commit=$COMMIT"

  if $DRY_RUN; then
    for TOP_PAIR in "${TOPS[@]}"; do
      TOP_NAME="${TOP_PAIR%%:*}"
      for KL in 0 1 2; do
        [ -n "$FILTER_KL" ] && [ "$KL" != "$FILTER_KL" ] && continue
        OUT="$OUTDIR/${LABEL}_${TOP_NAME}_kl${KL}.v"
        echo "  [dry-run] would write: $OUT"
      done
    done
    TOPS=()
    continue
  fi

  # Partial checkout — only rtl/ and sim/files.f at this boundary
  log "Checking out rtl/ and sim/files.f at $COMMIT"
  git -C "$BASEDIR" checkout "$COMMIT" -- rtl/ sim/files.f

  for TOP_PAIR in "${TOPS[@]}"; do
    TOP_NAME="${TOP_PAIR%%:*}"
    TOP_MODULE="${TOP_PAIR##*:}"

    for KL in 0 1 2; do
      [ -n "$FILTER_KL" ] && [ "$KL" != "$FILTER_KL" ] && continue

      OUT="$OUTDIR/${LABEL}_${TOP_NAME}_kl${KL}.v"

      if [ -f "$OUT" ]; then
        skip "$OUT (already exists — delete to regenerate)"
        SKIPPED=$((SKIPPED + 1))
        continue
      fi

      log "Generating: ${LABEL}_${TOP_NAME}_kl${KL}.v  (top=$TOP_MODULE)"

      # Regenerate aes_const.sv for this key length
      cd "$BASEDIR"
      export BASEDIR KEY_LENGTH="$KL" CASE_NUMBER=1
      bash rtl/initialize.sh > /dev/null 2>&1

      # Build file list: strip the ../../ prefix that sim/files.f uses,
      # resolve to absolute paths, exclude testbench
      SV_FILES=$(grep '\.sv$' "$BASEDIR/sim/files.f" \
                   | grep -v '_tb\.sv' \
                   | sed 's|../../||' \
                   | sed "s|^|$BASEDIR/|")

      # Convert to flat Verilog-2005
      sv2v $SV_FILES > "$OUT"

      # Strip the other architecture's top-level module so that the FSM file
      # contains only aes_state (not aes) and vice versa.  Both live in the
      # same RTL tree at every boundary where sv2v processes all source files
      # together, so without this step the two combined_v files are identical.
      if [ "$TOP_NAME" = "fsm" ] && grep -q '^module aes (' "$OUT"; then
        python3 - "$OUT" "aes" <<'PYEOF'
import sys, re

path, strip = sys.argv[1], sys.argv[2]
mod_start = re.compile(r'^module\s+' + re.escape(strip) + r'\b')
mod_any   = re.compile(r'^module\s+')
end_any   = re.compile(r'^endmodule\b')
with open(path) as f:
    lines = f.readlines()

out, depth, stripping = [], 0, False
for line in lines:
    if not stripping and mod_start.match(line):
        stripping = True
        depth = 1
        continue
    if stripping:
        if mod_any.match(line):
            depth += 1
        elif end_any.match(line):
            depth -= 1
            if depth <= 0:
                stripping = False
        continue
    out.append(line)

with open(path, 'w') as f:
    f.writelines(out)
PYEOF
        log "  Stripped module 'aes' (pipeline top) from FSM combined_v"
      elif [ "$TOP_NAME" = "pipeline" ] && grep -q '^module aes_state (' "$OUT"; then
        python3 - "$OUT" "aes_state" <<'PYEOF'
import sys, re

path, strip = sys.argv[1], sys.argv[2]
mod_start = re.compile(r'^module\s+' + re.escape(strip) + r'\b')
mod_any   = re.compile(r'^module\s+')
end_any   = re.compile(r'^endmodule\b')
with open(path) as f:
    lines = f.readlines()

out, depth, stripping = [], 0, False
for line in lines:
    if not stripping and mod_start.match(line):
        stripping = True
        depth = 1
        continue
    if stripping:
        if mod_any.match(line):
            depth += 1
        elif end_any.match(line):
            depth -= 1
            if depth <= 0:
                stripping = False
        continue
    out.append(line)

with open(path, 'w') as f:
    f.writelines(out)
PYEOF
        log "  Stripped module 'aes_state' (FSM top) from pipeline combined_v"
      fi

      LINES=$(wc -l < "$OUT")
      log "  Written: $OUT  ($LINES lines)"
      GENERATED=$((GENERATED + 1))
    done
  done

  # Restore rtl/ and sim/files.f to HEAD between phases so the next checkout
  # starts from a clean base (avoids "already exists" conflicts when a later
  # phase adds new files that weren't present at an earlier commit).
  git -C "$BASEDIR" checkout HEAD -- rtl/ sim/files.f 2>/dev/null || true
  EXTRA=$(git -C "$BASEDIR" status --short rtl/ 2>/dev/null | awk '/^A /{print $2}')
  if [ -n "$EXTRA" ]; then
    git -C "$BASEDIR" rm --cached $EXTRA 2>/dev/null || true
    echo "$EXTRA" | sed "s|^|$BASEDIR/|" | xargs rm -f 2>/dev/null || true
  fi
  cd "$BASEDIR"
  export KEY_LENGTH=0 CASE_NUMBER=1
  bash rtl/initialize.sh > /dev/null 2>&1

done

log "═════════════════════════════════════════════════"
log "Done. Generated=$GENERATED  Skipped=$SKIPPED"
log "Output directory: $OUTDIR"
ls -lh "$OUTDIR" 2>/dev/null || true
