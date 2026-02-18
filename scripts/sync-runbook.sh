#!/usr/bin/env bash
set -euo pipefail

# Fetches tracked files from the openclaw-runbook repo and shows what changed.
# Run periodically or via cron to catch upstream updates.

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="$REPO_DIR/.runbook-cache"
RAW_BASE="https://raw.githubusercontent.com/digitalknk/openclaw-runbook/main"

# Files we track from the runbook
TRACKED_FILES=(
  "examples/config-example-guide.md"
  "examples/sanitized-config.json"
  "examples/security-hardening.md"
  "examples/security-quickstart.md"
  "examples/agent-prompts.md"
  "examples/spawning-patterns.md"
  "guide.md"
)

mkdir -p "$CACHE_DIR/prev" "$CACHE_DIR/latest"

changed=0
errors=0

echo "=== Syncing openclaw-runbook ==="
echo ""

for file in "${TRACKED_FILES[@]}"; do
  filename="$(basename "$file")"
  prev="$CACHE_DIR/prev/$filename"
  latest="$CACHE_DIR/latest/$filename"

  # Fetch latest version
  if ! curl -sfL "$RAW_BASE/$file" -o "$latest" 2>/dev/null; then
    echo "WARN: Failed to fetch $file (may have been renamed/removed)"
    ((errors++)) || true
    continue
  fi

  # Compare against cached version
  if [ -f "$prev" ]; then
    if ! diff -q "$prev" "$latest" >/dev/null 2>&1; then
      echo "CHANGED: $file"
      diff --color=auto -u "$prev" "$latest" | head -40 || true
      echo ""
      ((changed++)) || true
    fi
  else
    echo "NEW: $file (first sync)"
    ((changed++)) || true
  fi

  # Update cache
  cp "$latest" "$prev"
done

echo "---"
if [ "$changed" -gt 0 ]; then
  echo "$changed file(s) changed. Review diffs above and update config/openclaw.json as needed."
elif [ "$errors" -gt 0 ]; then
  echo "No changes detected, but $errors file(s) failed to fetch."
else
  echo "All tracked files are up to date."
fi
