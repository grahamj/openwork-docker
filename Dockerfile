FROM node:22-bookworm-slim

ARG OPENWORK_ORCHESTRATOR_VERSION=0.13.12

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    tar \
    unzip \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g "openwork-orchestrator@${OPENWORK_ORCHESTRATOR_VERSION}"

ENV OPENWORK_DATA_DIR=/data/openwork-orchestrator
ENV OPENWORK_SIDECAR_DIR=/data/sidecars
ENV OPENWORK_WORKSPACE=/workspace

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8787 4096 3005

VOLUME ["/workspace", "/data"]

HEALTHCHECK --interval=10s --timeout=5s --start-period=90s --retries=30 \
  CMD curl -fsS "http://127.0.0.1:${OPENWORK_PORT:-8787}/health" >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
