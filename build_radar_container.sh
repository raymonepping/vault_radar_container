#!/usr/bin/env bash
set -euo pipefail

VERSION_FILE=".image_version"
IMAGE_NAME="repping/vault-radar-cli"

# Load version variables from file
if [[ -f "$VERSION_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$VERSION_FILE"
else
  echo "❌ Version file '$VERSION_FILE' not found."
  exit 1
fi

# Sanity check
if [[ -z "${VAULT_RADAR:-}" ]]; then
  echo "❌ VAULT_RADAR not set in $VERSION_FILE"
  exit 1
fi

echo "📦 Building Docker image for Vault Radar CLI:"
echo "    ➤ App Version: $VERSION"
echo "    ➤ Vault Radar: $VAULT_RADAR"

docker buildx create --use --name vault_radar_builder 2>/dev/null || docker buildx use vault_radar_builder

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg VAULT_RADAR_VERSION="$VAULT_RADAR" \
  -t "${IMAGE_NAME}:${VERSION}" \
  -t "${IMAGE_NAME}:latest" \
  --push \
  .

echo "✅ Build complete: ${IMAGE_NAME}:${VERSION}"

# Print image size
echo "📏 Image size:"
docker image inspect "${IMAGE_NAME}:${VERSION}" --format='{{.Size}}' | \
  awk '{ byte=$1/1024/1024; printf "   ➤ %.2f MB\n", byte }'
