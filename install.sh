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
echo "  1. Point clippush at your server (this terminal only):"
echo "       export CLIPPUSH_HOST=\"user@your-server\""
echo "     Add that same line to ~/.zshrc so it sticks in new terminals."
echo "  2. Install the /clip command on the server:"
echo "       clippush --init-remote"
echo ""
echo "To send files to your remote agent (any time):"
echo "  3. Copy file(s) in Finder with Cmd+C (or a screenshot: Ctrl+Shift+Cmd+4)"
echo "  4. Run 'clippush'. It uploads them over SSH and copies a"
echo "     'read these files' note to your clipboard."
echo "  5. In your agent, press Cmd+V then Enter."
echo "     (In Claude Code you can just type /clip instead.)"
