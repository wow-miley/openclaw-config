# OpenClaw on Linode

OpenClaw gateway running on a Linode server with Telegram as a chat channel.

## Overview

- **Host**: Linode VPS
- **Networking**: Tailscale for secure access
- **Chat channel**: Telegram bot (built-in OpenClaw channel)
- **Gateway port**: 18789

## Quick Start

1. Copy `.env.example` to `.env` and fill in your values
2. Run `scripts/setup.sh` on a fresh Linode instance
3. Run `scripts/deploy.sh` to sync config and restart the gateway

## Setup Details

The setup script installs:
- Node.js 22+ (required by OpenClaw)
- OpenClaw (via official install script)
- Tailscale (for secure remote access)

After setup, it runs `openclaw onboard --install-daemon` to authenticate and configure the gateway, then adds your Telegram bot token as a channel.

## Directory Structure

```
config/
  openclaw.json   — Main OpenClaw config (channels, agents, gateway settings)
scripts/
  setup.sh        — Server bootstrap (Node, OpenClaw, Tailscale, onboarding)
  deploy.sh       — Sync config to ~/.openclaw/ and restart gateway
```

## Configuration

The main config file is `config/openclaw.json` (JSON5 format). This gets deployed to `~/.openclaw/openclaw.json` on the server.

Telegram is configured as a channel within that file. See the [Telegram channel docs](https://docs.openclaw.ai/channels/telegram.md) and the [configuration reference](https://docs.openclaw.ai/gateway/configuration-reference.md) for all available options.

## Telegram Setup

1. Message [@BotFather](https://t.me/BotFather) on Telegram and run `/newbot`
2. Save the bot token to `TELEGRAM_BOT_TOKEN` in `.env`
3. After deploying, approve your first DM: `openclaw pairing approve telegram <CODE>`
4. To use in groups: disable privacy mode via `/setprivacy` in BotFather, or make the bot a group admin
