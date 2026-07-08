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
echo "  1. export CLIPPUSH_HOST=\"user@your-server\"   # your SSH target; also add it to ~/.zshrc"
echo "  2. clippush --init-remote                     # installs the /clip command on the server"
echo ""
echo "Then, any time you want to send files to your remote agent:"
echo "  3. Copy file(s) in Finder (Cmd+C), or take a screenshot (Ctrl+Shift+Cmd+4)"
echo "  4. Run:  clippush"
echo "           uploads them over SSH, and copies a 'read these files' note to your clipboard"
echo "  5. In your agent on the server (Claude Code, Codex, aider...), press Cmd+V then Enter"
echo "           — or, in Claude Code, just type /clip"
