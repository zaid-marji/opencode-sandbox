#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="opencode-sandbox:latest"
TARGET_BIN_DIR="$HOME/bin"
TARGET_LINK="$TARGET_BIN_DIR/opencode-sandbox"

echo "==> Building Docker image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" "$PROJECT_DIR"

echo "==> Ensuring $TARGET_BIN_DIR exists"
mkdir -p "$TARGET_BIN_DIR"

echo "==> Creating/refreshing symlink: $TARGET_LINK -> $PROJECT_DIR/opencode-sandbox"
ln -sf "$PROJECT_DIR/opencode-sandbox" "$TARGET_LINK"
chmod +x "$PROJECT_DIR/opencode-sandbox"

# Optionally ensure ~/bin is on PATH for current shell
case ":$PATH:" in
  *":$TARGET_BIN_DIR:"*) ;;
  *)
    echo
    echo "NOTE: $TARGET_BIN_DIR is not in your PATH."
    echo "Add this line to your shell config (e.g. ~/.bashrc or ~/.zshrc):"
    echo "  export PATH=\"\$HOME/bin:\$PATH\""
    ;;
esac

echo "==> Done."
echo "You can now run: opencode-sandbox <project-dir>"
