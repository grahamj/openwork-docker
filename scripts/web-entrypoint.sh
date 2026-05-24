#!/bin/sh
set -eu

export BUN_INSTALL="/root/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

if [ ! -d /app/.git ]; then
  echo "[openwork-web] Cloning OpenWork source..."
  git clone --depth 1 --branch "${OPENWORK_GIT_REF:-dev}" \
    "${OPENWORK_REPO:-https://github.com/different-ai/openwork.git}" /app
fi

if ! command -v bun >/dev/null 2>&1; then
  curl -fsSL https://bun.sh/install | bash
fi

corepack enable && corepack prepare pnpm@10.27.0 --activate

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
