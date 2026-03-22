#!/usr/bin/env bash

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEATURES_DIR="$ROOT_DIR/features"

resolve_feature_id() {
  if [ -n "$1" ]; then
    echo "$1"
    return
  fi

  local candidate=""

  for dir in "$FEATURES_DIR"/*/; do
    [ -d "$dir" ] || continue
    local status_file="$dir/status.txt"
    if [ -f "$status_file" ] && [ "$(tr -d '\r\n' < "$status_file")" = "running" ]; then
      candidate="$(basename "$dir")"
    fi
  done

  if [ -z "$candidate" ]; then
    for dir in "$FEATURES_DIR"/*/; do
      [ -d "$dir" ] || continue
      local status_file="$dir/status.txt"
      if [ -f "$status_file" ] && [ "$(tr -d '\r\n' < "$status_file")" = "draft" ]; then
        candidate="$(basename "$dir")"
      fi
    done
  fi

  echo "$candidate"
}

FEATURE_ID="$(resolve_feature_id "$1")"

if [ -z "$FEATURE_ID" ]; then
  echo "No draft or running feature found."
  exit 1
fi

FEATURE_DIR="$FEATURES_DIR/$FEATURE_ID"
python3 "$ROOT_DIR/scripts/split_output.py" "$FEATURE_DIR"
