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
echo "One-time setup:"
echo "  export CLIPPUSH_HOST=\"user@your-server\"   (add to ~/.zshrc to keep it)"
echo ""
echo "To send files to your remote agent (any time):"
echo "  1. Copy file(s) in Finder with Cmd+C (or a screenshot: Ctrl+Shift+Cmd+4)"
echo "  2. Run 'clippush'. It uploads them over SSH and copies a"
echo "     'read these files' note to your clipboard."
echo "  3. In your agent, press Cmd+V then Enter."
echo ""
echo "Using Claude Code? Add an optional '/clip' shortcut on the server:"
echo "  clippush --init-remote"
