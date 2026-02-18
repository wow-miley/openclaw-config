#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Load .env for LINODE_CLI_TOKEN
if [ -f "$REPO_DIR/.env" ]; then
  set -a
  source "$REPO_DIR/.env"
  set +a
fi

if [ -z "${LINODE_CLI_TOKEN:-}" ]; then
  echo "Error: LINODE_CLI_TOKEN not set. Add it to .env or export it."
  exit 1
fi

# Show usage if no argument
if [ -z "${1:-}" ]; then
  echo "Usage: scripts/teardown.sh <instance-id-or-label>"
  echo ""
  echo "Active instances:"
  if [ -d "$REPO_DIR/.instances" ] && ls "$REPO_DIR/.instances"/*.json &>/dev/null; then
    for f in "$REPO_DIR/.instances"/*.json; do
      INST_LABEL=$(python3 -c "import json; print(json.load(open('$f'))['label'])")
      INST_IP=$(python3 -c "import json; print(json.load(open('$f'))['ip'])")
      INST_ID=$(python3 -c "import json; print(json.load(open('$f'))['id'])")
      echo "  $INST_LABEL  (ID: $INST_ID, IP: $INST_IP)"
    done
  else
    echo "  (none)"
  fi
  exit 1
fi

TARGET="$1"

# Resolve label to ID if not numeric
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
  INSTANCE_ID="$TARGET"
  LABEL=""
  # Try to find matching metadata file
  if [ -d "$REPO_DIR/.instances" ]; then
    for f in "$REPO_DIR/.instances"/*.json; do
      [ -f "$f" ] || continue
      FILE_ID=$(python3 -c "import json; print(json.load(open('$f'))['id'])")
      if [ "$FILE_ID" = "$INSTANCE_ID" ]; then
        LABEL=$(python3 -c "import json; print(json.load(open('$f'))['label'])")
        break
      fi
    done
  fi
else
  LABEL="$TARGET"
  if [ -f "$REPO_DIR/.instances/$LABEL.json" ]; then
    INSTANCE_ID=$(python3 -c "import json; print(json.load(open('$REPO_DIR/.instances/$LABEL.json'))['id'])")
  else
    echo "Error: No saved instance with label '$LABEL'."
    echo "Pass a numeric Linode instance ID instead, or check: scripts/teardown.sh"
    exit 1
  fi
fi

# Find linode-cli even if pip bin dir isn't on PATH
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

echo "Deleting Linode instance $INSTANCE_ID${LABEL:+ ($LABEL)}..."
$LINODE_CLI linodes delete "$INSTANCE_ID"
echo "Instance deleted."

# Clean up local metadata
if [ -n "$LABEL" ] && [ -f "$REPO_DIR/.instances/$LABEL.json" ]; then
  rm "$REPO_DIR/.instances/$LABEL.json"
  echo "Removed local metadata."
fi
