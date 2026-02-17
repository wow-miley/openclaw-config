#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== OpenClaw Server Setup ==="

# Load .env if present
if [ -f "$REPO_DIR/.env" ]; then
  set -a
  source "$REPO_DIR/.env"
  set +a
fi

# Update system
sudo apt-get update && sudo apt-get -o Dpkg::Options::="--force-confold" upgrade -y

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

# Run onboarding (interactive — authenticates and configures the gateway)
echo ""
echo "Running OpenClaw onboarding wizard..."
echo "This is interactive — follow the prompts to authenticate and configure."
echo ""
openclaw onboard --install-daemon

# Deploy repo config before starting the gateway
echo "Deploying config from repo..."
mkdir -p ~/.openclaw
cp "$REPO_DIR/config/openclaw.json" ~/.openclaw/openclaw.json

# Install as systemd service for persistence across reboots
echo "Installing gateway as systemd service..."
openclaw gateway install
sudo loginctl enable-linger "$USER"
systemctl --user enable --now openclaw-gateway.service
sleep 3

# Configure Telegram channel
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
  echo ""
  echo "No TELEGRAM_BOT_TOKEN found in .env."
  echo "Get one from @BotFather on Telegram (/newbot), then paste it here."
  echo ""
  read -rp "Telegram bot token (or press Enter to skip): " TELEGRAM_BOT_TOKEN
fi

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
  echo "Adding Telegram channel..."
  openclaw channels add --channel telegram --token "$TELEGRAM_BOT_TOKEN"
  systemctl --user restart openclaw-gateway.service
  sleep 3
else
  echo "Skipping Telegram setup. Run this later:"
  echo "  openclaw channels add --channel telegram --token \"<your-token>\""
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

echo ""
echo "=== Setup complete ==="
echo ""
openclaw gateway status
openclaw channels status --probe
