#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

echo "=== Deploying OpenClaw ==="

# Pull latest config
git pull --ff-only

# Copy config to OpenClaw home
mkdir -p ~/.openclaw
cp config/openclaw.json ~/.openclaw/openclaw.json

# Restart the gateway
echo "Restarting gateway..."
openclaw gateway stop 2>/dev/null || true
openclaw gateway --port 18789 &
disown

echo "=== Deploy complete ==="
openclaw gateway status
