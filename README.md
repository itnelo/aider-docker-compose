
## aider-docker-compose

Dockerized, isolated [Aider](https://aider.chat/) runner for editing repositories with local LLMs (Ollama).

Layout:

- **`docker-compose.dev.yml.dist`**: stable compose template
- **`.env-template`**: documented variables (copy to `.env`)
- **`./data/*`**: runtime bind mounts (workspaces, Aider home)
- **`bin/agent`**: thin wrapper so callers do not hard-code `docker compose run …` details (see comments at the top of that file for raw compose examples)

## Quick start

```bash
cp .env-template .env
cp docker-compose.dev.yml.dist docker-compose.yml
docker compose up -d
```

## Run Aider on a repo (`bin/agent`)

From anywhere (script resolves the compose repo via its own path):

```bash
/path/to/aider-docker-compose/bin/agent \
  --workdir ./data/agent/workspaces/default/demo \
  "Update README.md: add a second line 'edited by aider'."
```

- **`--workdir`**: host path or container path `/workspaces/...` — see comments inside `bin/agent` and `AIDER_WORKSPACES_PATH` in `.env-template`.
- **`--model`**: optional override (`provider/model` string).
- **`--commit`**: optional; force Aider auto-commits for this run (overrides `.env` including `AIDER_AUTO_COMMITS=false`). Without it, `bin/agent` passes `AIDER_AUTO_COMMITS=false` for that run only (overrides `.env` if it says `true`).
- **`--thinking`**: optional; if `.env` has `AIDER_THINKING_TOKENS=0` (or invalid), forces a positive thinking-token budget for this run only; also disables stripping of THINKING…ANSWER banners in the non-`--debug` output filter (see `bin/agent` / `.env-template`).
- **`--no-previous-context`**: optional; omits Aider **`--restore-chat-history`** for this run so prior chat is not loaded for the same repo path; sidecar history env paths are unchanged.
- **`--debug`**: optional, not listed in `bin/agent --help`; prints wrapper diagnostics and disables stdout/stderr filtering (raw `docker compose run` stream).

Raw `docker compose run … agent …` does **not** apply the wrapper rules; it follows `.env` (`AIDER_AUTO_COMMITS`, commit prompt, etc.).

Chat history files live under `AIDER_HOME_PATH` in a per-repo hash sidecar (see `bin/agent`). By default the wrapper passes **`--restore-chat-history`** so a later run with the same repo path continues the conversation when those files exist.

## How `.env` affects Aider → Ollama

- Variables from `.env` are injected into the `agent` container.
- The image entrypoint writes `${HOME}/.aider.model.settings.yml` (Ollama `extra_params` such as `num_ctx`, `temperature`, `num_predict`, `keep_alive`).
- Optional **`AIDER_LINT_CMD`** is expanded into multiple `--lint-cmd` flags in the entrypoint (see `.env-template`).

Upstream: [Ollama | aider](https://aider.chat/docs/llms/ollama.html).

## Basic checks

### 1) Ollama reachable from the host

```bash
curl -sS -X POST "http://127.0.0.1:11434/api/generate" -d '{
  "model": "YOUR_OLLAMA_MODEL_NAME",
  "prompt": "ping",
  "stream": false,
  "options": { "num_ctx": 2048, "num_predict": 16, "temperature": 0.0 }
}' | jq
```

### 2) Aider starts inside Docker

```bash
docker compose run --rm agent --help
```

### 3) One-shot edit (raw compose; prefer `bin/agent` in daily use)

```bash
mkdir -p ./data/agent/workspaces/default/demo && cd ./data/agent/workspaces/default/demo
git init
printf "demo\n" > README.md
git add README.md && git commit -m "init"
cd - >/dev/null

docker compose run --rm --workdir /workspaces/default/demo agent \
  --model "${AIDER_OLLAMA_PROVIDER}/${AIDER_OLLAMA_MODEL}" \
  --yes --restore-chat-history \
  --message "Update README.md: add a second line 'edited by aider'." \
  /workspaces/default/demo
```
