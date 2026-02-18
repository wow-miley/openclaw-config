#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== OpenClaw Linode Provisioning ==="

# Load .env if present
if [ -f "$REPO_DIR/.env" ]; then
  set -a
  source "$REPO_DIR/.env"
  set +a
fi

# Check prerequisites — find linode-cli even if pip bin dir isn't on PATH
if command -v linode-cli &> /dev/null; then
  LINODE_CLI="linode-cli"
else
  LINODE_CLI=""
  for PIP_BIN in \
    "$(python3 -c "import site,os; print(os.path.join(site.getusersitepackages().rsplit('/lib/',1)[0],'bin'))" 2>/dev/null)" \
    "$(python3 -c "import sysconfig; print(sysconfig.get_path('scripts'))" 2>/dev/null)"; do
    if [ -n "$PIP_BIN" ] && [ -x "$PIP_BIN/linode-cli" ]; then
      LINODE_CLI="$PIP_BIN/linode-cli"
      break
    fi
  done
  if [ -z "$LINODE_CLI" ]; then
    echo "Error: linode-cli not found. Install it: pip3 install linode-cli"
    exit 1
  fi
fi

if [ -z "${LINODE_CLI_TOKEN:-}" ]; then
  echo "Error: LINODE_CLI_TOKEN not set. Add it to .env or export it."
  exit 1
fi

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "Error: ANTHROPIC_API_KEY not set. Add it to .env."
  exit 1
fi

if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
  echo "Error: TELEGRAM_BOT_TOKEN not set. Add it to .env."
  exit 1
fi

# Defaults
LINODE_REGION="${LINODE_REGION:-us-east}"
LINODE_TYPE="${LINODE_TYPE:-g6-nanode-1}"
LINODE_IMAGE="${LINODE_IMAGE:-linode/ubuntu24.04}"
LABEL="${SERVER_HOSTNAME:-openclaw}-$(date +%s)"
ROOT_PASSWORD="${ROOT_PASSWORD:-$(openssl rand -base64 24)}"

# Detect SSH public key
SSH_KEY=""
for keyfile in ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub; do
  if [ -f "$keyfile" ]; then
    SSH_KEY=$(cat "$keyfile")
    echo "Using SSH key: $keyfile"
    break
  fi
done

if [ -z "$SSH_KEY" ]; then
  echo "Warning: No SSH public key found. You'll need the root password to SSH in."
fi

# Create or update the StackScript
echo "Syncing StackScript to Linode..."
STACKSCRIPT_CONTENT=$(cat "$REPO_DIR/scripts/stackscript.sh")

EXISTING_SS=$($LINODE_CLI stackscripts list --is_public false --json 2>/dev/null \
  | python3 -c "import sys,json; scripts=json.load(sys.stdin); matches=[s['id'] for s in scripts if s['label']=='openclaw-setup']; print(matches[0] if matches else '')" 2>/dev/null || echo "")

if [ -n "$EXISTING_SS" ]; then
  echo "Updating existing StackScript (ID: $EXISTING_SS)..."
  $LINODE_CLI stackscripts update "$EXISTING_SS" \
    --script "$STACKSCRIPT_CONTENT" \
    --images "$LINODE_IMAGE" > /dev/null
  STACKSCRIPT_ID="$EXISTING_SS"
else
  echo "Creating new StackScript..."
  STACKSCRIPT_ID=$($LINODE_CLI stackscripts create \
    --label "openclaw-setup" \
    --images "$LINODE_IMAGE" \
    --script "$STACKSCRIPT_CONTENT" \
    --description "Automated OpenClaw + Telegram setup" \
    --json \
    | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")
  echo "Created StackScript (ID: $STACKSCRIPT_ID)"
fi

# Build the create command
echo "Creating Linode instance: $LABEL ($LINODE_TYPE in $LINODE_REGION)..."

CREATE_ARGS=(
  linodes create
  --label "$LABEL"
  --region "$LINODE_REGION"
  --type "$LINODE_TYPE"
  --image "$LINODE_IMAGE"
  --root_pass "$ROOT_PASSWORD"
  --stackscript_id "$STACKSCRIPT_ID"
  --stackscript_data "{\"ANTHROPIC_API_KEY\": \"$ANTHROPIC_API_KEY\", \"TELEGRAM_BOT_TOKEN\": \"$TELEGRAM_BOT_TOKEN\", \"TAILSCALE_AUTH_KEY\": \"${TAILSCALE_AUTH_KEY:-}\", \"SERVER_HOSTNAME\": \"${SERVER_HOSTNAME:-openclaw}\"}"
  --booted true
  --json
)

if [ -n "$SSH_KEY" ]; then
  CREATE_ARGS+=(--authorized_keys "$SSH_KEY")
fi

INSTANCE_JSON=$($LINODE_CLI "${CREATE_ARGS[@]}")

INSTANCE_ID=$(echo "$INSTANCE_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")
echo "Instance created (ID: $INSTANCE_ID)"

# Wait for instance to boot
echo "Waiting for instance to boot..."
for i in $(seq 1 60); do
  STATUS=$($LINODE_CLI linodes view "$INSTANCE_ID" --json \
    | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['status'])")
  if [ "$STATUS" = "running" ]; then
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "Error: Timed out waiting for instance to boot."
    exit 1
  fi
  sleep 5
done

IP=$($LINODE_CLI linodes view "$INSTANCE_ID" --json \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['ipv4'][0])")
echo "Instance running at $IP"

# Wait for StackScript to complete
echo "Waiting for OpenClaw setup to complete (this takes a few minutes)..."
SETUP_DONE=false
for i in $(seq 1 60); do
  if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
    root@"$IP" "cat /var/log/stackscript-complete 2>/dev/null" 2>/dev/null | grep -q "OPENCLAW_READY"; then
    SETUP_DONE=true
    break
  fi
  sleep 10
done

if [ "$SETUP_DONE" = false ]; then
  echo ""
  echo "Warning: Timed out waiting for setup to complete."
  echo "The StackScript may still be running. Check progress with:"
  echo "  ssh root@$IP 'tail -f /var/log/stackscript.log'"
fi

# Save instance metadata
mkdir -p "$REPO_DIR/.instances"
cat > "$REPO_DIR/.instances/$LABEL.json" << EOF
{
  "id": $INSTANCE_ID,
  "label": "$LABEL",
  "ip": "$IP",
  "region": "$LINODE_REGION",
  "type": "$LINODE_TYPE",
  "stackscript_id": $STACKSCRIPT_ID,
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo ""
echo "=== OpenClaw Instance Ready ==="
echo "  Label:    $LABEL"
echo "  ID:       $INSTANCE_ID"
echo "  IP:       $IP"
echo "  Region:   $LINODE_REGION"
echo "  SSH:      ssh root@$IP"
echo "  Logs:     ssh root@$IP 'cat /var/log/stackscript.log'"
echo ""
echo "  Teardown: scripts/teardown.sh $LABEL"
echo ""
if [ "$SETUP_DONE" = true ]; then
  echo "  OpenClaw is running. Message your Telegram bot to start chatting."
fi
