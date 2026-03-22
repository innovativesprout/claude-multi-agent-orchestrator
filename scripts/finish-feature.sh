#!/usr/bin/env bash
set -e
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEATURES_DIR="$ROOT_DIR/features"
LATEST_FILE="$FEATURES_DIR/latest.txt"
LAST_RUN_FILE="$ROOT_DIR/outputs/last-run.md"
find_latest_by_status() {
  local wanted="$1"
  local latest=""
  local latest_num=0
  shopt -s nullglob
  for dir in "$FEATURES_DIR"/*/; do
    [ -f "$dir/status.txt" ] || continue
    status="$(tr -d '\r\n' < "$dir/status.txt")"
    [ "$status" = "$wanted" ] || continue
    base="$(basename "$dir")"
    num="$(echo "$base" | sed -E 's/^([0-9]+)-.*$/\1/')"
    if [[ "$num" =~ ^[0-9]+$ ]] && [ $((10#$num)) -gt "$latest_num" ]; then
      latest_num=$((10#$num))
      latest="$base"
    fi
  done
  echo "$latest"
}
FEATURE_ID="$1"
if [ -z "$FEATURE_ID" ]; then
  FEATURE_ID="$(find_latest_by_status running)"
  if [ -z "$FEATURE_ID" ]; then
    FEATURE_ID="$(find_latest_by_status draft)"
  fi
fi
if [ -z "$FEATURE_ID" ]; then
  echo "No running or draft feature found."
  exit 1
fi
FEATURE_DIR="$FEATURES_DIR/$FEATURE_ID"
STATUS_FILE="$FEATURE_DIR/status.txt"
[ -d "$FEATURE_DIR" ] || { echo "Feature folder not found: $FEATURE_DIR"; exit 1; }
echo "$FEATURE_ID" > "$LATEST_FILE"
echo "completed" > "$STATUS_FILE"
cat > "$LAST_RUN_FILE" <<EOT
# Last Run

## Feature
$FEATURE_ID

## Status
Completed

## Feature Folder
$FEATURE_DIR
EOT
echo "$FEATURE_ID"
