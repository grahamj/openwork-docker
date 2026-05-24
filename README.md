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
cp vars.example .env
# OLLAMA_BASE_URL and OLLAMA_MODEL are pre-set for a LAN Ollama host

docker compose up --build
```

Open:

- Web UI: http://localhost:5173
- Host UI: http://localhost:8787/ui
- Health: http://localhost:8787/health

In the UI, pick provider **ollama** and model **`gemma4-e4b-it-q4_K_M-98k`**.

Check logs for auto-generated `OPENWORK_TOKEN` and `OPENWORK_HOST_TOKEN` if you left them blank in `.env`.

If you previously started the stack with a different model, set `OPENCODE_CONFIG_FORCE=1` once in `.env` (or delete `workspace/.config/opencode/opencode.json`) so the Ollama config is regenerated.

## External Ollama

Containers call your host at `OLLAMA_BASE_URL` (default `http://192.168.50.202:11434`). Use the machine’s LAN IP, not `localhost` — that would point at the container itself.

Ensure Ollama on that host listens on the network interface (e.g. `OLLAMA_HOST=0.0.0.0:11434`) and that your firewall allows port 11434 from the Docker host.

## Components

Inside **openwork-host**, the orchestrator manages:

- **opencode** — agent engine (internal, proxied via openwork-server)
- **openwork-server** — API and `/ui` surface
- **opencode-router** — optional multi-workspace router (enabled by default)

Ollama is wired via `workspace/.config/opencode/opencode.json` using `OLLAMA_BASE_URL` and `OLLAMA_MODEL`.
