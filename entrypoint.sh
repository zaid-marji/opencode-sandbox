#!/usr/bin/env bash
set -e

# Docker --user already set the UID/GID; we do not chown anything here.
# We only ensure HOME is where our mounts are.
export HOME=${HOME:-/home/sandbox}
export PATH="$HOME/.bun/bin:/usr/local/bin:$PATH"

exec opencode "$@"
