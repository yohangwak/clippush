# clippush

**Copy any file on your Mac → hand it to an AI coding agent running on a remote server over SSH.**

Works with **Claude Code, Codex, opencode, Gemini CLI, aider** — anything that can read a file by path. Screenshots, spreadsheets, PDFs, CSVs, logs — multiple files at once. One command bridges your local clipboard and your remote SSH session.

```
┌─ Local Mac ────────────────┐        ┌─ Remote server (SSH) ──────────┐
│                            │        │                                │
│  Cmd+C in Finder           │        │  ~/.clippush/                  │
│  (or Ctrl+Shift+Cmd+4      │  scp   │    └── 20260706-143210/        │
│   for a screenshot)        │ ─────▶ │          ├── rates.xlsx        │
│                            │        │          └── error.png         │
│  $ clippush                │        │    └── latest → (symlink)      │
│                            │        │                                │
│  📋 remote paths now on    │        │  Your agent:                   │
│     your clipboard         │ ─────▶ │  Cmd+V, or /clip (Claude Code) │
└────────────────────────────┘        └────────────────────────────────┘
```

## Why

Running Claude Code (or Codex, opencode, aider...) on a remote server over SSH is great — until you need to show it something from your local machine. The remote terminal can't see your local clipboard. Pasting an image fails because the server has no display server, and there's simply no such thing as "pasting" an `.xlsx` into a terminal.

Existing tools ([clipssh](https://github.com/samuellawrentz/clipssh), [cc-clip](https://github.com/ShunmeiCho/cc-clip)) solve this for **screenshots only**. clippush handles **any file, and multiple files at once** — because half the time what you need to show your agent isn't a screenshot, it's a spreadsheet someone emailed you.

## Install

```bash
git clone https://github.com/yohangwak/clippush.git
cd clippush && ./install.sh
```

Then configure your default host and install the `/clip` command on your server:

```bash
export CLIPPUSH_HOST="user@your-server"   # add to ~/.zshrc
clippush --init-remote
```

## Use

1. **Copy** — select files in Finder and hit `Cmd+C`, or grab a screenshot with `Ctrl+Shift+Cmd+4`
2. **Push** — run `clippush` in any terminal
3. **Paste** — in your remote agent, press `Cmd+V` then Enter (your clipboard holds a ready-made "read these files" instruction, so the agent reads them right away). In **Claude Code** you can also just type `/clip`.

```
$ clippush
✅ 2 file(s) → myserver
   /home/me/.clippush/20260706-143210/rates.xlsx
   /home/me/.clippush/20260706-143210/error.png
📋 copied as a ready-to-paste instruction — Cmd+V into your agent, or /clip in Claude Code
```

## One-tap hotkey (optional)

Typing `clippush` after every copy gets old. `clippush --setup` writes a [Raycast](https://raycast.com) script command so you can push with a **global hotkey** instead:

```bash
clippush --setup
```

It bakes your current `CLIPPUSH_HOST` and `PATH` into `~/.config/raycast/scripts/clippush.sh` (Raycast runs it in a bare shell that wouldn't otherwise see them — re-run `--setup` if your host changes). Two one-time steps in Raycast:

1. Settings → Extensions → Script Commands → **Add Directories** → choose `~/.config/raycast/scripts`
2. Find **Push clipboard to server** and set its hotkey to **`Ctrl+Cmd+P`** (Raycast stores hotkeys internally, so this step is manual)

Then the whole flow is: **`Cmd+C` → `Ctrl+Cmd+P` → (remote) `Cmd+V`**.

**Prefer Alfred, Automator, Karabiner, or another launcher?** The generated `clippush.sh` is just a plain shell script — bind it to any hotkey in the tool you already use.

## Commands

| Command | What it does |
|---|---|
| `clippush` | Push clipboard content (files or screenshot) to `$CLIPPUSH_HOST` |
| `clippush user@host` | Push to a specific host |
| `clippush --last` | Put the last pushed remote paths back on your clipboard |
| `clippush --init-remote` | Install the `/clip` slash command on the server |
| `clippush --setup` | Install a Raycast push hotkey (writes a script command) |
| `clippush --clean` | Wipe the remote inbox |

Config: `CLIPPUSH_HOST` (default target), `CLIPPUSH_DIR` (remote inbox, default `~/.clippush`), `CLIPPUSH_KEEP` (batches to retain on the server, default `10`).

## How it works

- **File detection**: reads `NSPasteboard` via JXA to get file URLs Finder placed on the clipboard — this is what enables arbitrary files and multi-select, and it's the part screenshot-only tools skip.
- **Screenshot fallback**: if no files are on the clipboard, extracts the image natively via `NSPasteboard`/`NSImage` (same JXA path as file detection) — no external dependency.
- **One SSH connection**: opens a temporary `ControlMaster` socket, so pushing 5 files doesn't open 5 SSH sessions. No changes to your `~/.ssh/config` needed.
- **Tidy & private**: each push lands in its own timestamped folder with `0600` permissions (other users on the server can't read your files), and `latest` always points to the newest batch — which is what `/clip` reads.
- **`/clip`**: a [Claude Code custom command](https://docs.claude.com/en/docs/claude-code) (a markdown file in `~/.claude/commands/`) that lists `~/.clippush/latest/` and reads every file in it. Zero pasting required.

## FAQ

**Why not paste the file itself with Cmd+V?**
Over SSH a remote terminal's `Cmd+V` can only transmit text, not binary — and Claude Code's image paste reads the OS clipboard directly, which a headless server doesn't have. So a binary file can't be "pasted" into a remote session at all; it has to exist on the remote disk and be referenced by path. clippush does the next best thing: after pushing, your clipboard holds a `Read these files: …` instruction, so `Cmd+V` + Enter (or `/clip`) makes the agent read them with one step.

**Does it work with tools other than Claude Code?**
Yes — clippush just puts files on the remote disk and an instruction on your clipboard, so it's tool-agnostic. Only the `/clip` shortcut is Claude Code-specific; everywhere else you paste the instruction or use the tool's own "add file" command:

- **Codex / opencode / Gemini CLI** — `Cmd+V` + Enter; the pasted instruction includes the paths, so the agent reads them.
- **aider** — `/read ~/.clippush/latest/<file>` (or `/add`), or just `Cmd+V` the paths.
- **plain shell** — the files are simply there: `cat ~/.clippush/latest/*`, no AI tool needed.

**Linux/Windows local machine?**
macOS only for now. PRs welcome — the clipboard-reading section is the only platform-specific part.

## Requirements

- macOS with `ssh`/`scp` (built in) — no other dependencies
- SSH key auth to your server (no password prompts)

## License

MIT
