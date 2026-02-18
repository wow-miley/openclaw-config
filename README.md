# OpenClaw on Linode

OpenClaw gateway running on a Linode server with Telegram as a chat channel.

## Overview

- **Host**: Linode VPS
- **Networking**: Tailscale for secure access
- **Chat channel**: Telegram bot (built-in OpenClaw channel)
- **Gateway port**: 18789

## Quick Start (Automated)

Provision a fully configured instance from your local machine:

1. Install the Linode CLI: `pip3 install linode-cli`
2. Copy `.env.example` to `.env` and fill in your values
3. Run `scripts/provision.sh` — creates a Linode, installs everything, starts OpenClaw
4. Message your Telegram bot to start chatting
5. To tear down: `scripts/teardown.sh <label>`

## Quick Start (Manual)

Set up on an existing server via SSH:

1. Copy `.env.example` to `.env` and fill in your values
2. Run `scripts/setup.sh` on a fresh Linode instance
3. Run `scripts/deploy.sh` to sync config and restart the gateway

## How Provisioning Works

`provision.sh` uploads `stackscript.sh` to Linode as a StackScript, then creates an instance that runs it on first boot. Secrets (API keys, bot token) are passed as StackScript parameters — they never touch git. The StackScript installs Node.js, OpenClaw, and Tailscale, writes the full config with tokens, and starts the gateway. No interactive steps.

## Directory Structure

```
config/
  openclaw.json     — OpenClaw config reference (channels, agents, gateway)
scripts/
  provision.sh      — LOCAL: create a new Linode with OpenClaw configured
  teardown.sh       — LOCAL: destroy a Linode instance
  stackscript.sh    — Linode StackScript (runs on first boot, non-interactive)
  setup.sh          — Manual server bootstrap (interactive)
  deploy.sh         — Sync config to a running server
```

## Configuration

The main config file is `config/openclaw.json` (JSON5 format). For manual deployments, `deploy.sh` copies it to `~/.openclaw/openclaw.json` on the server. For automated provisioning, the StackScript writes the config directly with secrets included.

See the [configuration reference](https://docs.openclaw.ai/gateway/configuration-reference.md) for all available options.

## Telegram Setup

1. Message [@BotFather](https://t.me/BotFather) on Telegram and run `/newbot`
2. Save the bot token to `TELEGRAM_BOT_TOKEN` in `.env`
3. After provisioning, the bot is ready — message it to start a pairing request
4. To use in groups: disable privacy mode via `/setprivacy` in BotFather, or make the bot a group admin
