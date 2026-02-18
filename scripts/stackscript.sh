#!/bin/bash
# <UDF name="ANTHROPIC_API_KEY" label="Anthropic API Key" />
# <UDF name="TELEGRAM_BOT_TOKEN" label="Telegram Bot Token" />
# <UDF name="TAILSCALE_AUTH_KEY" label="Tailscale Auth Key" default="" />
# <UDF name="SERVER_HOSTNAME" label="Server Hostname" default="openclaw" />

set -euo pipefail

# Log everything for debugging
exec &> >(tee -a /var/log/stackscript.log)
echo "=== OpenClaw StackScript started at $(date -u) ==="

# System update
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y

# Install Node.js 22+
echo "Installing Node.js 22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
echo "Node version: $(node --version)"

# Install OpenClaw
echo "Installing OpenClaw..."
curl -fsSL https://openclaw.ai/install.sh | bash
echo "OpenClaw version: $(openclaw --version)"

# Write OpenClaw config with all secrets baked in
echo "Writing OpenClaw config..."
mkdir -p ~/.openclaw
cat > ~/.openclaw/openclaw.json << OCEOF
{
  // Gateway settings
  gateway: {
    port: 18789,
    bind: "lan",
  },

  // Auth
  auth: {
    profiles: {
      anthropic: {
        apiKey: "${ANTHROPIC_API_KEY}",
      },
    },
  },

  // Telegram channel
  channels: {
    telegram: {
      enabled: true,
      botToken: "${TELEGRAM_BOT_TOKEN}",
      dmPolicy: "pairing",
      groups: {
        "*": { requireMention: true },
      },
    },
  },

  // Agent defaults
  agents: {
    defaults: {
      model: { primary: "sonnet" },
    },
  },
}
OCEOF

# Install and start gateway as systemd service
echo "Installing gateway service..."
loginctl enable-linger root
openclaw gateway install
systemctl --user enable --now openclaw-gateway.service
sleep 3
echo "Gateway status:"
openclaw gateway status || true

# Install Tailscale
echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

if [ -n "${TAILSCALE_AUTH_KEY:-}" ]; then
  echo "Joining Tailscale network..."
  tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="$SERVER_HOSTNAME"
fi

echo ""
echo "=== OpenClaw StackScript completed at $(date -u) ==="
echo "OPENCLAW_READY" > /var/log/stackscript-complete
