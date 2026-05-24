# OpenWork Docker

Docker Compose stack for [OpenWork](https://github.com/different-ai/openwork) with MySQL and all core components. By default it uses an **external Ollama** instance on your LAN (not a container).

## Services

| Service | Port | Description |
|---------|------|-------------|
| **openwork-host** | 8787 | Orchestrator + OpenCode + openwork-server + opencode-router |
| **openwork-web** | 5173 | Web UI (Vite) |
| **share** | 3006 | Share/publish service |
| **mysql** | 3306 | Persistent database |

The host also serves a built-in UI at `http://localhost:8787/ui`.

## Quick start

```bash
cp env.example .env
# Set OLLAMA_BASE_URL and OLLAMA_MODEL for your Ollama host

docker compose up --build
```

Open:

- Web UI: http://localhost:5173
- Host UI: http://localhost:8787/ui
- Health: http://localhost:8787/health

In the UI, pick provider **ollama** and the model name from your `.env` (`OLLAMA_MODEL`).

Check logs for auto-generated `OPENWORK_TOKEN` and `OPENWORK_HOST_TOKEN` if you left them blank in `.env`.

If you previously started the stack with a different model, set `OPENCODE_CONFIG_FORCE=1` once in `.env` (or delete `workspace/.config/opencode/opencode.json`) so the Ollama config is regenerated.

## External Ollama

OpenWork’s Ollama extension hardcodes `http://localhost:11434` upstream. This stack patches it at web startup to use `OLLAMA_BASE_URL` from `.env`.

The OpenCode engine config is written separately to `workspace/.config/opencode/opencode.json` by `openwork-host`. If you previously installed the extension with localhost, set `OPENCODE_CONFIG_FORCE=1` once (or delete that file).

Set `OLLAMA_BASE_URL` and `OLLAMA_MODEL` in `.env` (see `env.example`). Containers and your browser must both be able to reach that URL. Do not use `localhost` unless Ollama runs on the same machine as your browser.

## Components

Inside **openwork-host**, the orchestrator manages:

- **opencode** — agent engine (internal, proxied via openwork-server)
- **openwork-server** — API and `/ui` surface
- **opencode-router** — optional multi-workspace router (enabled by default)

Ollama is wired via `workspace/.config/opencode/opencode.json` using `OLLAMA_BASE_URL` and `OLLAMA_MODEL`.
