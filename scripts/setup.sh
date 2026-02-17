#!/usr/bin/env bash
set -euo pipefail

echo "=== OpenClaw Server Setup ==="

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Node.js 22+ (required by OpenClaw)
if ! command -v node &> /dev/null || [ "$(node --version | cut -d. -f1 | tr -d v)" -lt 22 ]; then
  echo "Installing Node.js 22..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

echo "Node version: $(node --version)"

# Install OpenClaw
if ! command -v openclaw &> /dev/null; then
  echo "Installing OpenClaw..."
  curl -fsSL https://openclaw.ai/install.sh | bash
fi

echo "OpenClaw version: $(openclaw --version)"

# Run onboarding (auth, gateway config, daemon install)
echo "Running OpenClaw onboarding..."
openclaw onboard --install-daemon

# Add Telegram channel if token is set
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
  echo "Adding Telegram channel..."
  openclaw channels add --channel telegram --token "$TELEGRAM_BOT_TOKEN"
fi

# Install Tailscale
if ! command -v tailscale &> /dev/null; then
  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# Bring up Tailscale
if [ -n "${TAILSCALE_AUTH_KEY:-}" ]; then
  sudo tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="${SERVER_HOSTNAME:-openclaw}"
else
  echo "Set TAILSCALE_AUTH_KEY in .env to auto-join Tailscale, or run: sudo tailscale up"
fi

echo "=== Setup complete ==="
echo "Gateway status:"
openclaw gateway status
