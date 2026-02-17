#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

echo "=== Deploying Minnetonka ==="

# Pull latest config
git pull --ff-only

# Pull latest images
docker compose pull

# Restart services
docker compose up -d

echo "=== Deploy complete ==="
docker compose ps
