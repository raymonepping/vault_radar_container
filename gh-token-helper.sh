#!/usr/bin/env bash
set -euo pipefail

# Git credential helper protocol.
# https://git-scm.com/docs/git-credential
# We only implement "get". We read key=value lines from stdin.

action="${1:-get}"

# slurp stdin into vars
protocol=""
host=""
while IFS='=' read -r key val; do
  case "$key" in
    protocol) protocol="$val" ;;
    host) host="$val" ;;
  esac
done

if [ "$action" = "get" ] && [ "${protocol}" = "https" ] && [ "${host}" = "github.com" ]; then
  # Do not echo the token in logs. Only output the credential pair to stdout for git to consume.
  if [ -n "${VAULT_RADAR_GIT_TOKEN:-}" ]; then
    printf 'username=%s\n' "x-oauth-basic"
    printf 'password=%s\n' "${VAULT_RADAR_GIT_TOKEN}"
    exit 0
  fi
fi

# No credentials
exit 0
