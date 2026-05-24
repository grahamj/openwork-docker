#!/bin/sh
set -eu

if [ ! -d /app/.git ]; then
  echo "[openwork-web] Cloning OpenWork source..."
  git clone --depth 1 --branch "${OPENWORK_GIT_REF:-dev}" \
    "${OPENWORK_REPO:-https://github.com/different-ai/openwork.git}" /app
fi

# Patch every source file in the web app that hardcodes localhost:11434 or the default model
OLLAMA_BASE_URL="${OLLAMA_BASE_URL:?OLLAMA_BASE_URL must be set in .env}"
OLLAMA_DEFAULT_MODEL="${OLLAMA_MODEL:?OLLAMA_MODEL must be set in .env}"

echo "[openwork-web] Scanning for hardcoded localhost:11434 in source..."
MATCHES=$(grep -rl "localhost:11434" /app/apps/app/src/ 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
  echo "$MATCHES" | while IFS= read -r f; do
    sed -i "s|http://localhost:11434|${OLLAMA_BASE_URL%/}|g" "$f"
    echo "[openwork-web] Patched $f"
  done
else
  echo "[openwork-web] No additional files with localhost:11434 found"
fi

# Also fix the default model name in the known config file
EXT_FILE="/app/apps/app/src/react-app/domains/settings/openai-image-extension.ts"
if [ -f "$EXT_FILE" ]; then
  sed -i "s|defaultModelId: \"qwen2.5-coder:7b\"|defaultModelId: \"${OLLAMA_DEFAULT_MODEL}\"|g" "$EXT_FILE"
fi

echo "[openwork-web] Post-patch occurrences of localhost:11434:"
grep -rn "localhost:11434" /app/apps/app/src/ 2>/dev/null || echo "  (none — all clear)"

# Bust Vite's pre-bundle cache so it recompiles the patched source
rm -rf /app/apps/app/node_modules/.vite /app/node_modules/.vite
echo "[openwork-web] Vite cache cleared"

if [ ! -d /app/node_modules ]; then
  echo "[openwork-web] Installing dependencies..."
  pnpm install --frozen-lockfile --filter @openwork/app...
fi

TOKEN_FILE="/data/.openwork-env-${OPENWORK_DEV_ID:-default}"
if [ -f "$TOKEN_FILE" ]; then
  # shellcheck disable=SC1090
  . "$TOKEN_FILE"
fi

export VITE_OPENWORK_TOKEN="${OPENWORK_TOKEN:-${VITE_OPENWORK_TOKEN:-}}"
export VITE_OPENWORK_URL="http://${OPENWORK_PUBLIC_HOST:-localhost}:${OPENWORK_PORT:-8787}"
export VITE_OPENWORK_PORT="${OPENWORK_PORT:-8787}"
export VITE_OPENWORK_PUBLISHER_BASE_URL="http://${OPENWORK_PUBLIC_HOST:-localhost}:${SHARE_PORT:-3006}"
export VITE_ALLOWED_HOSTS="all"
export HOST="0.0.0.0"
export PORT="5173"
export OPENWORK_DEV_MODE="${OPENWORK_DEV_MODE:-1}"

printf '%s\n' \
  "============================================" \
  " OpenWork web UI" \
  " URL: http://${OPENWORK_PUBLIC_HOST:-localhost}:${WEB_PORT:-5173}" \
  " Backend: ${VITE_OPENWORK_URL}" \
  "============================================"

exec pnpm --filter @openwork/app exec vite \
  --host 0.0.0.0 \
  --port 5173 \
  --strictPort
