#!/usr/bin/env bash
set -euo pipefail

# --- sanity checks ---
if [[ -z "${DISPLAY:-}" ]]; then
  echo "Error: DISPLAY not set (are you on Xorg?)."
  exit 1
fi
if ! command -v xrandr >/dev/null 2>&1; then
  echo "Error: xrandr not found."
  exit 1
fi

# --- helpers ---
die() { echo "Error: $*" >&2; exit 1; }

apply_mode() {
  local out="$1" mode="$2" rate="$3"
  xrandr --output "$out" --off
  if [[ -n "$rate" ]]; then
    xrandr --fb "$mode" --output "$out" --mode "$mode" --rate "$rate" --pos 0x0
  else
    xrandr --fb "$mode" --output "$out" --mode "$mode" --pos 0x0
  fi
}

# get current mode and rate for an output
current_mode_rate() {
  local out="$1"
  xrandr --query | awk -v o="$out" '
    substr($0, 1, length(o)+1) == o" " { inout=1; next }
    inout && $0 ~ "^[^ ]" { inout=0 }
    inout && /\*/ {
      for (i=1;i<=NF;i++) if ($i ~ /^[0-9]+(\.[0-9]+)?\*[+!]?$/) {
        rate=$i; sub(/\*.*$/, "", rate)
      }
      print $1, rate
      exit
    }
  '
}

# --- initialise variables so set -u never fires ---
RATE=""
CUR_MODE=""
CUR_RATE=""

# --- list outputs (connected only) ---
mapfile -t outputs < <(xrandr --query | awk '/ connected/ {print $1}')
(( ${#outputs[@]} )) || die "No connected outputs found."

echo "Select output:"
select OUT in "${outputs[@]}"; do
  [[ -n "${OUT:-}" ]] && break
done

# --- build list of resolutions for OUT ---
mapfile -t modes < <(xrandr --query | awk -v o="$OUT" '
  substr($0, 1, length(o)+1) == o" " { inout=1; next }
  inout && $0 ~ "^[^ ]" { inout=0 }
  inout && /^[[:space:]]+[0-9]/ { print $1 }' | uniq)
(( ${#modes[@]} )) || die "No modes found for $OUT."

echo
echo "Select resolution for $OUT:"
select MODE in "${modes[@]}"; do
  [[ -n "${MODE:-}" ]] && break
done

# --- list refresh rates for the chosen MODE ---
mapfile -t rates < <(xrandr --query | awk -v o="$OUT" -v m="$MODE" '
  substr($0, 1, length(o)+1) == o" " { inout=1; next }
  inout && $0 ~ "^[^ ]" { inout=0 }
  inout && $1==m {
    for (i=2;i<=NF;i++) {
      r=$i
      gsub(/[*+!]/, "", r)
      if (r ~ /^[0-9]+(\.[0-9]+)?$/) print r
    }
  }' | uniq)

if (( ${#rates[@]} == 0 )); then
  echo
  echo "No explicit refresh list; will apply resolution only."
else
  echo
  echo "Select refresh rate for $OUT ($MODE):"
  select RATE in "${rates[@]}"; do
    [[ -n "${RATE:-}" ]] && break
  done
fi

# --- capture current for rollback ---
read -r CUR_MODE CUR_RATE < <(current_mode_rate "$OUT") || true
CUR_MODE="${CUR_MODE:-}"
CUR_RATE="${CUR_RATE:-}"

echo
echo "About to apply:"
if [[ -n "$RATE" ]]; then
  echo "  xrandr --fb $MODE --output $OUT --mode $MODE --rate $RATE --pos 0x0"
else
  echo "  xrandr --fb $MODE --output $OUT --mode $MODE --pos 0x0"
fi
echo "Current: ${CUR_MODE:-unknown} @ ${CUR_RATE:-unknown} Hz"
echo
echo "Note: display will go dark briefly while switching."
echo

# --- apply new setting ---
if ! apply_mode "$OUT" "$MODE" "$RATE"; then
  die "Failed to apply mode/rate."
fi

# --- confirm with timeout and rollback ---
TIMEOUT=10
echo -n "Is the display OK? (y/N) auto-revert in ${TIMEOUT}s: "
read -r -t "$TIMEOUT" ANS || ANS=""

if [[ "${ANS,,}" != "y" && "${ANS,,}" != "yes" ]]; then
  echo
  echo "Reverting to ${CUR_MODE:-unknown} @ ${CUR_RATE:-unknown}..."
  if [[ -n "$CUR_MODE" && -n "$CUR_RATE" ]]; then
    xrandr --output "$OUT" --off
    xrandr --fb "$CUR_MODE" --output "$OUT" --mode "$CUR_MODE" --rate "$CUR_RATE" --pos 0x0 || true
  elif [[ -n "$CUR_MODE" ]]; then
    xrandr --output "$OUT" --off
    xrandr --fb "$CUR_MODE" --output "$OUT" --mode "$CUR_MODE" --pos 0x0 || true
  fi
  echo "Reverted."
else
  echo
  echo "Confirmed."
fi

echo "Done."
