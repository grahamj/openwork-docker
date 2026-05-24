#!/bin/sh
set -eu

OPENWORK_WORKSPACE="${OPENWORK_WORKSPACE:-/workspace}"
OPENWORK_DATA_DIR="${OPENWORK_DATA_DIR:-/data/openwork-orchestrator}"
OPENWORK_SIDECAR_DIR="${OPENWORK_SIDECAR_DIR:-/data/sidecars}"
OPENWORK_PORT="${OPENWORK_PORT:-8787}"
OPENWORK_OPENCODE_PORT="${OPENWORK_OPENCODE_PORT:-4096}"
OPENWORK_APPROVAL_MODE="${OPENWORK_APPROVAL_MODE:-auto}"
OPENWORK_CORS_ORIGINS="${OPENWORK_CORS_ORIGINS:-*}"
OPENWORK_CONNECT_HOST="${OPENWORK_CONNECT_HOST:-localhost}"
OLLAMA_BASE_URL="${OLLAMA_BASE_URL:?OLLAMA_BASE_URL must be set in .env}"
OLLAMA_MODEL="${OLLAMA_MODEL:?OLLAMA_MODEL must be set in .env}"
OPENWORK_ENABLE_OPENCODE_ROUTER="${OPENWORK_ENABLE_OPENCODE_ROUTER:-1}"

mkdir -p "$OPENWORK_WORKSPACE" "$OPENWORK_DATA_DIR" "$OPENWORK_SIDECAR_DIR"

if [ -z "${OPENWORK_TOKEN:-}" ]; then
  OPENWORK_TOKEN="$(cat /proc/sys/kernel/random/uuid)"
  export OPENWORK_TOKEN
fi

if [ -z "${OPENWORK_HOST_TOKEN:-}" ]; then
  OPENWORK_HOST_TOKEN="$(cat /proc/sys/kernel/random/uuid)"
  export OPENWORK_HOST_TOKEN
fi

TOKEN_FILE="/data/.openwork-env-${OPENWORK_DEV_ID:-default}"
mkdir -p "$(dirname "$TOKEN_FILE")"
printf 'OPENWORK_TOKEN=%s\nOPENWORK_HOST_TOKEN=%s\n' \
  "$OPENWORK_TOKEN" "$OPENWORK_HOST_TOKEN" > "$TOKEN_FILE"

CONFIG_DIR="${OPENWORK_WORKSPACE}/.config/opencode"
mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_DIR/opencode.json" ] || [ "${OPENCODE_CONFIG_FORCE:-0}" = "1" ]; then
  cat > "$CONFIG_DIR/opencode.json" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama",
      "options": {
        "baseURL": "${OLLAMA_BASE_URL}/v1"
      },
      "models": {
        "${OLLAMA_MODEL}": {
          "name": "${OLLAMA_MODEL}"
        }
      }
    }
  }
}
EOF
fi

if [ "${OPENWORK_WAIT_FOR_OLLAMA:-1}" = "1" ]; then
  echo "[openwork-host] Waiting for Ollama at ${OLLAMA_BASE_URL}..."
  until curl -sf "${OLLAMA_BASE_URL}/api/tags" >/dev/null 2>&1; do
    sleep 2
  done
  echo "[openwork-host] Ollama is ready."
fi

printf '%s\n' \
  "============================================" \
  " OpenWork host" \
  " Server:  http://${OPENWORK_CONNECT_HOST}:${OPENWORK_PORT}" \
  " UI:      http://${OPENWORK_CONNECT_HOST}:${OPENWORK_PORT}/ui" \
  " Health:  http://${OPENWORK_CONNECT_HOST}:${OPENWORK_PORT}/health" \
  " Token:   ${OPENWORK_TOKEN}" \
  " Host:    ${OPENWORK_HOST_TOKEN}" \
  " Model:   ollama/${OLLAMA_MODEL}" \
  "============================================"

ROUTER_ARGS=""
if [ "$OPENWORK_ENABLE_OPENCODE_ROUTER" != "1" ]; then
  ROUTER_ARGS="--no-opencode-router"
fi

exec openwork serve \
  --workspace "$OPENWORK_WORKSPACE" \
  --remote-access \
  --openwork-port "$OPENWORK_PORT" \
  --opencode-host 127.0.0.1 \
  --opencode-port "$OPENWORK_OPENCODE_PORT" \
  --openwork-token "$OPENWORK_TOKEN" \
  --openwork-host-token "$OPENWORK_HOST_TOKEN" \
  --approval "$OPENWORK_APPROVAL_MODE" \
  --cors "$OPENWORK_CORS_ORIGINS" \
  --connect-host "$OPENWORK_CONNECT_HOST" \
  $ROUTER_ARGS
