# -------------------------------
# 🔧 Stage 1: Builder
# -------------------------------
FROM alpine:3.20 AS builder

ARG VAULT_RADAR_VERSION=0.30.0
# Provided by buildx, defaulted for classic builds
ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache curl unzip

WORKDIR /build

# HashiCorp standard release URL pattern:
# https://releases.hashicorp.com/vault-radar/<version>/vault-radar_<version>_<os>_<arch>.zip
RUN set -eux; \
    file="vault-radar_${VAULT_RADAR_VERSION}_${TARGETOS}_${TARGETARCH}.zip"; \
    url="https://releases.hashicorp.com/vault-radar/${VAULT_RADAR_VERSION}/${file}"; \
    echo "Downloading ${url}"; \
    curl -fsSL -o "${file}" "${url}"; \
    unzip -q "${file}"; \
    chmod +x vault-radar; \
    rm -f "${file}"

# -------------------------------
# 🚀 Stage 2: Runtime
# -------------------------------
FROM alpine:3.20

ARG VAULT_RADAR_VERSION=0.30.0
ARG USER=vault

# Minimal runtime deps + git for remediation flows
RUN apk add --no-cache ca-certificates bash tzdata git openssh-client && \
    update-ca-certificates

# Create non-root user
RUN adduser -u 1001 -D -s /bin/bash "${USER}"

# Put binary in PATH
COPY --from=builder /build/vault-radar /usr/local/bin/vault-radar

# GitHub token credential helper and entrypoint
COPY gh-token-helper.sh /usr/local/bin/gh-token-helper.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/gh-token-helper.sh /usr/local/bin/entrypoint.sh

# Prepare a writable logs dir
RUN mkdir -p /var/log/vault-radar && chown -R ${USER}:${USER} /var/log/vault-radar

USER ${USER}

# Helpful labels
LABEL org.opencontainers.image.title="vault-radar-cli" \
      org.opencontainers.image.description="Containerized CLI for HCP Vault Radar" \
      org.opencontainers.image.version="${VAULT_RADAR_VERSION}" \
      org.opencontainers.image.source="https://developer.hashicorp.com/hcp/docs/vault-radar/cli"

# Basic health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD vault-radar version || exit 1

# Use an entrypoint that wires git auth, then execs vault-radar
ENTRYPOINT ["entrypoint.sh"]
CMD ["--help"]
