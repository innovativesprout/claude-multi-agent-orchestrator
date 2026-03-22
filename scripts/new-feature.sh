#!/usr/bin/env bash
set -e
if [ -z "$1" ]; then
  echo "Usage: bash scripts/new-feature.sh \"Feature Title\""
  exit 1
fi
TITLE="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEATURES_DIR="$ROOT_DIR/features"
LATEST_FILE="$FEATURES_DIR/latest.txt"
mkdir -p "$FEATURES_DIR"
slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g'
}
get_next_number() {
  if [ -f "$LATEST_FILE" ] && [ -s "$LATEST_FILE" ]; then
    LAST="$(tr -d '\r\n' < "$LATEST_FILE")"
    LAST_NUM="$(echo "$LAST" | sed -E 's/^([0-9]+)-.*$/\1/')"
    if [[ "$LAST_NUM" =~ ^[0-9]+$ ]]; then
      echo $((10#$LAST_NUM + 1))
      return
    fi
  fi
  HIGHEST=0
  shopt -s nullglob
  for dir in "$FEATURES_DIR"/*/; do
    base="$(basename "$dir")"
    num="$(echo "$base" | sed -E 's/^([0-9]+)-.*$/\1/')"
    if [[ "$num" =~ ^[0-9]+$ ]] && [ $((10#$num)) -gt "$HIGHEST" ]; then
      HIGHEST=$((10#$num))
    fi
  done
  echo $((HIGHEST + 1))
}
NEXT_NUM="$(get_next_number)"
PADDED_NUM="$(printf "%03d" "$NEXT_NUM")"
SLUG="$(slugify "$TITLE")"
FEATURE_ID="${PADDED_NUM}-${SLUG}"
FEATURE_DIR="$FEATURES_DIR/$FEATURE_ID"
mkdir -p "$FEATURE_DIR"
cat > "$FEATURE_DIR/request.txt" <<EOT
Title: $TITLE

Describe the feature request here.

Requirements:
- 
- 
- 
EOT
: > "$FEATURE_DIR/plan.md"
: > "$FEATURE_DIR/execution.md"
: > "$FEATURE_DIR/qa.md"
: > "$FEATURE_DIR/docs.md"
: > "$FEATURE_DIR/raw-output.md"
: > "$FEATURE_DIR/prompt.final.txt"
echo "draft" > "$FEATURE_DIR/status.txt"
echo "$FEATURE_ID"
