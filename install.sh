#!/usr/bin/env bash
# clippush installer (macOS)
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
SHARE_DIR="$HOME/.local/share/clippush"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing clippush..."

mkdir -p "$BIN_DIR" "$SHARE_DIR/remote"
cp "$SRC_DIR/bin/clippush" "$BIN_DIR/clippush"
cp "$SRC_DIR/remote/clip.md" "$SHARE_DIR/remote/clip.md"
chmod +x "$BIN_DIR/clippush"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo ""
     echo "⚠ $BIN_DIR is not in your PATH. Add this to your shell profile:"
     echo '   export PATH="$HOME/.local/bin:$PATH"' ;;
esac

echo ""
echo "✅ installed: $BIN_DIR/clippush"
echo ""
echo "Next steps:"
echo "  1. export CLIPPUSH_HOST=\"user@your-server\"   # add to ~/.zshrc"
echo "  2. clippush --init-remote                     # installs /clip on the server"
echo "  3. Copy a file (Cmd+C) or screenshot (Ctrl+Shift+Cmd+4), run: clippush"
