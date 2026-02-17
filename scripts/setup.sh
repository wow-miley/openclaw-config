#!/usr/bin/env bash
set -euo pipefail

echo "=== OpenClaw Server Setup ==="

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  echo "Docker installed. You may need to log out and back in for group changes."
fi

# Install Docker Compose plugin
if ! docker compose version &> /dev/null; then
  echo "Installing Docker Compose plugin..."
  sudo apt-get install -y docker-compose-plugin
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
echo "Next: copy .env.example to .env, fill in values, then run scripts/deploy.sh"
