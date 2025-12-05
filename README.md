# OpenCode Sandbox

Isolated, reproducible environment for running the
[OpenCode](https://github.com/OpenCode-ai/opencode) CLI against a single
project directory.

The goal is to give the AI agent:

- Access **only** to the project files you point it at
- The **same permissions** as your current user
- Persistent **state / history / cache** in a sandboxed directory
- Your existing `~/.config/opencode/opencode.json` settings, read‑only

All of this runs inside a lightweight Ubuntu 24.04 Docker container.

---

## How it works

This repo contains three main pieces:

- `Dockerfile` – builds an Ubuntu 24.04 image, installs Node.js + `opencode-ai`,
  and sets up a simple entrypoint that runs `opencode` inside `/workspace`.
- `entrypoint.sh` – minimal wrapper that:
  - trusts the UID/GID passed via `docker run --user`
  - ensures `HOME` points at `/home/sandbox`
  - starts `opencode` as the container process.
- `opencode-sandbox` – host-side wrapper script that:
  - builds and runs the container image
  - mounts a **single project directory** at `/workspace`
  - maps sandboxed OpenCode dirs to `~/.opencode-sandbox/*` on the host
  - overlays your real `~/.config/opencode/opencode.json` as read‑only

Inside the container, OpenCode sees:

- `/workspace` – the project directory you passed on the host
- `/home/sandbox/.config/opencode` – backed by `~/.opencode-sandbox/config`
- `/home/sandbox/.local/share/opencode` – backed by `~/.opencode-sandbox/share`
- `/home/sandbox/.local/state/opencode` – backed by `~/.opencode-sandbox/state`
- `/home/sandbox/.cache/opencode` – backed by `~/.opencode-sandbox/cache`
- `/home/sandbox/.config/opencode/opencode.json` – a **read‑only** bind mount
  of your real host config at `~/.config/opencode/opencode.json` if present

The container runs as your current user (`--user "$(id -u):$(id -g)"`),
so file permissions inside `/workspace` match what you can do on the host.

---

## Prerequisites

- Docker (or compatible runtime) installed and working

---

## Setup

From the root of this repository:

```bash
chmod +x setup.sh
./setup.sh
```

What `setup.sh` does:

1. Builds the Docker image as `opencode-sandbox:latest`.
2. Ensures `~/bin` exists.
3. Creates/refreshes a symlink:

   ```text
   ~/bin/opencode-sandbox -> /path/to/this/repo/opencode-sandbox
   ```

4. Reminds you to add `~/bin` to your `PATH` if it isn’t already.

After running `setup.sh`, either:

- Open a new shell, or
- Add to your shell config (if needed):

  ```bash
  export PATH="$HOME/bin:$PATH"
  ```

---

## Usage

You run opencode-sandbox just like the regular `opencode` CLI. All arguments will be forwarded to `opencode`. Only the project directory will be redirected to `/workspace` inside the container.

From any project directory on the host:

```bash
opencode-sandbox
```

or point it to another directory explicitly:

```bash
opencode-sandbox /path/to/project
```

This will:

- Start a container from `opencode-sandbox:latest`
- Mount the chosen project as `/workspace`
- Run `opencode` inside the container, in `/workspace`, with:

  ```bash
  HOME=/home/sandbox
  TERM=$TERM
  user = your current uid:gid
  ```

Your OpenCode state (conversation history, last model, etc.) is stored
under `~/.opencode-sandbox` on the host, not inside the project.

### Example

```bash
cd ~/code/my-app
opencode-sandbox .
```

Once OpenCode starts, interact with it as usual. It will only see:

- The files under `~/code/my-app` (mounted at `/workspace`)
- Its own home directory under `/home/sandbox`
- Your OpenCode configuration (read‑only)

---

## Files and directories

### On the host

- `~/bin/opencode-sandbox` – symlink created by `setup.sh`.
- `~/.opencode-sandbox/` – sandboxed OpenCode data:
  - `config/` → mapped to `/home/sandbox/.config/opencode`
  - `share/`  → mapped to `/home/sandbox/.local/share/opencode`
  - `state/`  → mapped to `/home/sandbox/.local/state/opencode`
  - `cache/`  → mapped to `/home/sandbox/.cache/opencode`

Your real OpenCode config remains at:

- `~/.config/opencode/opencode.json` (mounted read‑only into the container).

### In the container

- `/workspace` – the project directory (single mount).
- `/home/sandbox` – the sandbox “home.”
- `opencode` – the CLI installed globally via `npm install -g opencode-ai`.

---

## Security and isolation

This setup is meant to be **project‑scoped** and **unprivileged**:

- The container runs as your user (no extra privileges).
- Only the project directory and the sandboxed OpenCode directories are mounted.
- Your real OpenCode config file is mounted **read‑only**.
- No access is given to the rest of your home directory or arbitrary paths.

You can further harden the container (optional, not done by default):

- Add `--read-only` to `docker run` and a `tmpfs` for `/tmp`.
- Add `--cap-drop=ALL` if no extra capabilities are needed.

---

## Updating

To update to a newer `opencode-ai` version:

1. Edit `Dockerfile` if you want a specific version, for example:

   ```dockerfile
   RUN npm install -g opencode-ai@1.0.133
   ```

   or leave it unpinned to always get the latest.

2. Rebuild the image:

   ```bash
   ./setup.sh
   ```

   (This will rebuild the image and refresh the symlink again.)

---

## Troubleshooting

- **`opencode-sandbox` not found**

  Make sure `~/bin` is in your `PATH`:

  ```bash
  echo "$PATH" | tr ':' '\n' | grep -Fx "$HOME/bin" || \
    echo 'Add export PATH="$HOME/bin:$PATH" to your shell config'
  ```

- **Permission errors on project files**

  Confirm you’re running `opencode-sandbox` as the same user who owns the
  project directory.
