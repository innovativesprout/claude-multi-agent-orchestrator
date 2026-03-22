#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
  echo "Usage: bash scripts/start-feature.sh <feature-id>"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEATURE_ID="$1"
FEATURE_DIR="$ROOT_DIR/features/$FEATURE_ID"

if [ -d "$FEATURE_DIR" ]; then
  echo "Feature already exists: $FEATURE_DIR"
  exit 1
fi

mkdir -p "$FEATURE_DIR"
cp "$ROOT_DIR/templates/implementation-plan-template.md" "$FEATURE_DIR/plan.md"
cp "$ROOT_DIR/templates/execution-template.md" "$FEATURE_DIR/execution.md"
cp "$ROOT_DIR/templates/qa-report-template.md" "$FEATURE_DIR/qa.md"
cp "$ROOT_DIR/templates/feature-doc-template.md" "$FEATURE_DIR/docs.md"
cp "$ROOT_DIR/templates/feature-request-template.txt" "$FEATURE_DIR/request.txt"
echo "draft" > "$FEATURE_DIR/status.txt"

echo "Created feature scaffold: $FEATURE_ID"
echo "Edit: features/$FEATURE_ID/request.txt"
