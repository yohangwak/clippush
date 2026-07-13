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
echo "Setup (one time) — tell clippush which server to push to:"
echo ""
echo "    export CLIPPUSH_HOST=\"user@your-server\""
echo ""
echo "That is the whole setup. Add that same line to ~/.zshrc so it also"
echo "works in new terminals."
echo ""
echo "Then, any time you want to send something:"
echo ""
echo "  1. Copy files or an image (Cmd+C)."
echo "  2. Run:  clippush"
echo "     It sends them to your server. Your clipboard is now ready to paste."
echo "  3. Paste into your agent on the server:  Cmd+V, then Enter."
