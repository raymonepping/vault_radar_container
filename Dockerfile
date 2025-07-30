# -------------------------------
# 🔧 Stage 1: Builder
# -------------------------------
FROM alpine:3.20 AS builder

ARG VAULT_RADAR_VERSION=0.29.0

# Pin build dependencies
RUN apk add --no-cache \
    curl=8.12.1-r0 \
    unzip=6.0-r14

WORKDIR /build

# Download and extract only the vault-radar binary
RUN curl -sSL https://releases.hashicorp.com/vault-radar/${VAULT_RADAR_VERSION}/vault-radar_${VAULT_RADAR_VERSION}_linux_amd64.zip \
  -o vault-radar.zip \
  && unzip vault-radar.zip \
  && chmod +x vault-radar \
  && rm -f ./*.zip ./*.txt

# -------------------------------
# 🚀 Stage 2: Runtime
# -------------------------------
FROM alpine:3.20

ARG VAULT_RADAR_VERSION=0.29.0
ENV USER=vault

# Labels with dynamic version
LABEL org.opencontainers.image.title="vault-radar-cli" \
      org.opencontainers.image.description="Containerized CLI for Vault Radar with scan automation support" \
      org.opencontainers.image.version="${VAULT_RADAR_VERSION}" \
      org.opencontainers.image.licenses="MPL-2.0" \
      org.opencontainers.image.source="https://github.com/raymonepping/homebrew-radar-love-cli"

# Runtime dependencies
# TODO: CVE-2025-46394, CVE-2024-58251 - all low severity in busybox; will monitor for upstream Alpine fix
RUN apk add --no-cache \
    bash=5.2.26-r0 \
    jq=1.7.1-r0 \
    git=2.45.4-r0 \
    ca-certificates=20250619-r0 \
  && adduser -u 1001 -D -s /bin/bash $USER \
  && chmod +x /usr/local/bin/vault-radar

# Install binary
COPY --from=builder /build/vault-radar /usr/local/bin/vault-radar

# Switch to non-root user
USER $USER

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
  CMD vault-radar version || exit 1

# Default entrypoint
ENTRYPOINT ["vault-radar"]
