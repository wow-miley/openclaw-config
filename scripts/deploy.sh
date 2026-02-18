#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

echo "=== Deploying OpenClaw ==="

# Pull latest config
git pull --ff-only

# Copy config to OpenClaw home with locked-down permissions
mkdir -p ~/.openclaw
cp config/openclaw.json ~/.openclaw/openclaw.json
chmod 700 ~/.openclaw
chmod 600 ~/.openclaw/openclaw.json

# Restart the gateway via systemd
echo "Restarting gateway..."
systemctl --user restart openclaw-gateway.service
sleep 3

echo "=== Deploy complete ==="
openclaw gateway status
