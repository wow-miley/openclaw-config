# OpenClaw on Linode

OpenClaw instance running on a Linode server with Telegram bot integration.

## Overview

- **Host**: Linode VPS
- **Networking**: Tailscale for secure access
- **Bot**: Telegram bot triggers OpenClaw workflows
- **Runtime**: Docker Compose

## Architecture

```
Telegram Bot → OpenClaw Agent → Configured Workflows
                    ↑
              Linode VPS (Docker)
```

## Quick Start

1. Copy `.env.example` to `.env` and fill in your values
2. Run `scripts/setup.sh` on a fresh Linode instance
3. Run `scripts/deploy.sh` to start services

## Directory Structure

```
config/
  agents/       — Agent definitions
  workflows/    — Workflow trigger configurations
scripts/
  setup.sh      — Server bootstrap (deps, Tailscale, Docker)
  deploy.sh     — Pull latest config and restart services
```

## Configuration

Agent definitions live in `config/agents/`. Workflow triggers (including Telegram commands) are defined in `config/workflows/`.

See `.env.example` for required environment variables.
