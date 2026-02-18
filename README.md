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
  sync-runbook.sh — Fetch latest runbook guidance and diff against local
```

## Configuration

The main config file is `config/openclaw.json` (JSON5 format). This gets deployed to `~/.openclaw/openclaw.json` on the server.

Telegram is configured as a channel within that file. See the [Telegram channel docs](https://docs.openclaw.ai/channels/telegram.md) and the [configuration reference](https://docs.openclaw.ai/gateway/configuration-reference.md) for all available options.

## Telegram Setup

1. Message [@BotFather](https://t.me/BotFather) on Telegram and run `/newbot`
2. Save the bot token to `TELEGRAM_BOT_TOKEN` in `.env`
3. After deploying, approve your first DM: `openclaw pairing approve telegram <CODE>`
4. To use in groups: disable privacy mode via `/setprivacy` in BotFather, or make the bot a group admin

## Runbook References

This config follows patterns from the [OpenClaw Runbook (Non-Hype Edition)](https://github.com/digitalknk/openclaw-runbook). Sections used:

| Config area | Runbook source |
|---|---|
| Model routing (cheap defaults, scoped fallbacks) | [config-example-guide.md § Model Configuration](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/config-example-guide.md#model-configuration-agentsdefaultsmodel) |
| Memory search (cheap embeddings) | [config-example-guide.md § Memory Search](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/config-example-guide.md#memory-search-memorysearch) |
| Context pruning (cache-ttl) | [config-example-guide.md § Context Pruning](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/config-example-guide.md#context-pruning-contextpruning) |
| Compaction / memory flush | [config-example-guide.md § Compaction](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/config-example-guide.md#compaction-compactionmemoryflush) |
| Heartbeat model | [config-example-guide.md § Heartbeat Model](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/config-example-guide.md#heartbeat-model-heartbeatmodel) |
| Concurrency limits | [config-example-guide.md § Concurrency Limits](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/config-example-guide.md#concurrency-limits) |
| Gateway auth + binding | [config-example-guide.md § Security: Gateway Binding](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/config-example-guide.md#security-gateway-binding) |
| Log redaction | [config-example-guide.md § Logging](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/config-example-guide.md#logging-redactsensitive) |
| Tool policies (default-deny) | [security-hardening.md](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/security-hardening.md) |
| File permissions | [security-hardening.md](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/security-hardening.md) |
| Agent roles (main/monitor/researcher) | [agent-prompts.md](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/agent-prompts.md) |
| Full sanitized reference config | [sanitized-config.json](https://github.com/digitalknk/openclaw-runbook/blob/main/examples/sanitized-config.json) |

Run `scripts/sync-runbook.sh` to check for upstream changes to these files.
