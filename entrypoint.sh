#!/usr/bin/env bash
set -euo pipefail

# enable logging to file
LOG_FILE="/var/log/vault-radar/vault-radar.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Ensure HOME exists and is writable for git configs
export HOME="${HOME:-/home/vault}"
mkdir -p "$HOME"

# Minimal git identity, avoid noisy prompts
git config --global user.name  "vault-radar-bot"
git config --global user.email "vault-radar-bot@local"
git config --global credential.helper "/usr/local/bin/gh-token-helper.sh"

# Optional, quiet host key prompts for https->ssh transitions if any happen
git config --global advice.detachedHead false

# Validate critical envs for the agent
for req in HCP_CLIENT_ID HCP_CLIENT_SECRET HCP_PROJECT_ID HCP_RADAR_AGENT_POOL_ID VAULT_ADDR VAULT_TOKEN; do
  if [ -z "${!req:-}" ]; then
    echo "Missing required env: $req" >&2
    exit 2
  fi
done

exec vault-radar "$@" 2>&1 | tee -a "$LOG_FILE"
