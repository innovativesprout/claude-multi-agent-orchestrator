#!/usr/bin/env bash

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEATURES_DIR="$ROOT_DIR/features"
TEMPLATE_FILE="$ROOT_DIR/prompts/run-feature.txt"
LAST_RUN_FILE="$ROOT_DIR/outputs/last-run.md"

resolve_feature_id() {
  if [ -n "$1" ]; then
    echo "$1"
    return
  fi

  local candidate=""
  for dir in "$FEATURES_DIR"/*/; do
    [ -d "$dir" ] || continue
    local status_file="$dir/status.txt"
    if [ -f "$status_file" ] && [ "$(tr -d '\r\n' < "$status_file")" = "draft" ]; then
      candidate="$(basename "$dir")"
    fi
  done
  echo "$candidate"
}

FEATURE_ID="$(resolve_feature_id "$1")"

if [ -z "$FEATURE_ID" ]; then
  echo "No draft feature found."
  exit 1
fi

FEATURE_DIR="$FEATURES_DIR/$FEATURE_ID"
REQUEST_FILE="$FEATURE_DIR/request.txt"
FINAL_PROMPT_FILE="$FEATURE_DIR/prompt.final.txt"
RAW_OUTPUT_FILE="$FEATURE_DIR/raw-output.md"
STATUS_FILE="$FEATURE_DIR/status.txt"

if [ ! -f "$REQUEST_FILE" ]; then
  echo "Missing request file: $REQUEST_FILE"
  exit 1
fi

python3 - <<PY
from pathlib import Path

template = Path(r"$TEMPLATE_FILE").read_text(encoding="utf-8")
request = Path(r"$REQUEST_FILE").read_text(encoding="utf-8")
final_prompt = template.replace("{{FEATURE_REQUEST}}", request)
Path(r"$FINAL_PROMPT_FILE").write_text(final_prompt, encoding="utf-8")
PY

echo "running" > "$STATUS_FILE"

echo "Generated final prompt:"
echo "  $FINAL_PROMPT_FILE"
echo

if command -v claude >/dev/null 2>&1; then
  if claude < "$FINAL_PROMPT_FILE" > "$RAW_OUTPUT_FILE"; then
    python3 "$ROOT_DIR/scripts/split_output.py" "$FEATURE_DIR"

    cat > "$LAST_RUN_FILE" <<EOF2
# Last Run

## Feature
$FEATURE_ID

## Status
Prompt executed successfully and output was split

## Prompt File
$FINAL_PROMPT_FILE

## Raw Output File
$RAW_OUTPUT_FILE
EOF2

    echo "Claude output saved and split for:"
    echo "  $FEATURE_ID"
  else
    cat > "$LAST_RUN_FILE" <<EOF2
# Last Run

## Feature
$FEATURE_ID

## Status
Claude execution failed

## Prompt File
$FINAL_PROMPT_FILE
EOF2

    echo "Claude execution failed."
    echo "Paste this manually into claude: $FINAL_PROMPT_FILE"
    exit 1
  fi
else
  cat > "$LAST_RUN_FILE" <<EOF2
# Last Run

## Feature
$FEATURE_ID

## Status
Claude CLI not found

## Prompt File
$FINAL_PROMPT_FILE
EOF2

  echo "Claude CLI not found. Paste this manually into claude: $FINAL_PROMPT_FILE"
  exit 1
fi
