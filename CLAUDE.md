# clippush — notes for coding agents and contributors

📏 **이 파일은 모든 AI 대화에 통째로 실린다 — 본문엔 모든 작업에 필요한 규칙·판정식·한 줄 이유와 «작업 → 문서» 목록만 둔다.** 경위·실측·날짜별 정정은 `docs/claude/<주제>.md`(원문은 `docs/claude/history/`), 폴더 한정 규칙은 그 폴더 `CLAUDE.md`, 변경 이력은 PR 본문 — 날짜 절을 쌓지 않는다. 32,000바이트를 넘기며 커지는 커밋은 막힌다(맥 전역 pre-commit 훅).

Copy files or a screenshot on a Mac → `clippush` uploads them over SSH → the
remote paths come back on the clipboard as a "Read these files" instruction for
an agent running on the server. README.md has the user-facing story.

## Layout

| Path | What |
|---|---|
| `bin/clippush` | The whole tool — one Bash script. Its `# ----------` headers mark the stages: arg parsing, `--setup`, reading the clipboard, the SSH connection, subcommands, upload, handing paths back |
| `remote/clip.md` | The `/clip` Claude Code command; `--init-remote` copies it to `~/.claude/commands/` on the server |
| `install.sh` | Copies `bin/clippush` → `~/.local/bin/` and `clip.md` → `~/.local/share/clippush/remote/` |
| `test/` | Test suite; `ssh`, `scp`, `osascript`, `pbcopy`, `open` are replaced by stand-ins in `test/stubs/` |
| `.github/workflows/pullfrog.yml` | Generated Pullfrog agent workflow (manual dispatch only) — don't edit |

## Commands

```bash
./test/run.sh                        # full suite, no server or clipboard needed
TEST_BASH=/bin/bash ./test/run.sh    # same, with clippush under macOS's bash 3.2
CLIPPUSH_TEST_REMOTE_SHELL=zsh ./test/run.sh   # same, with a zsh login shell on the server
bash -n bin/clippush install.sh      # syntax check
shellcheck bin/clippush install.sh   # if installed
```

There is no build step, no dependency manifest, and no CI.

## Constraints the code doesn't spell out

- **bash 3.2.** On a stock Mac `#!/usr/bin/env bash` is `/bin/bash` 3.2. No
  `mapfile`, `declare -A`, `${var,,}`, `|&`; `"${arr[@]}"` on an *empty* array
  aborts under `set -u`. Run the suite with `TEST_BASH=/bin/bash` before sending
  a change.
- **Local is macOS, remote is any Unix.** Commands sent through `rsh` run in the
  server's login shell: keep them POSIX `sh`, no bash-isms, no GNU-only flags.
  That shell can be zsh, which aborts a command on a glob with no matches — wrap
  anything that globs in `sh -c` (see `--clean`) and check it with
  `CLIPPUSH_TEST_REMOTE_SHELL=zsh ./test/run.sh`.
- **Clipboard before network.** A push reads the clipboard before opening SSH,
  so an empty clipboard fails without a connection. The `cleanup` trap runs
  under `set -e`: a failing command there ends it early, so guard anything that
  can fail with `|| true`.
- **Two quoting rules.** Anything interpolated into an `rsh` command goes
  through `shq`. `scp` destinations must *not* be quoted: since OpenSSH 9 scp
  speaks SFTP and takes the remote path literally, so quotes become part of the
  filename.
- **JXA bridging.** Pass ObjC arrays as `$([...])` — a bare JS array bridges to
  an empty object and `readObjectsForClassesOptions` fails.
- **Private by default.** Pushes use `umask 077` and `chmod go=`. Only `--share`
  loosens permissions, and it stays opt-in per push. Its default inbox in
  `/var/tmp` is world-writable territory: it is used only if it is a real
  directory owned by the pushing account.
- **Deleting on the server.** `--clean` and pruning must only remove what
  clippush created (timestamped batch folders and the `latest` symlink):
  `CLIPPUSH_DIR` can point at a folder that holds other data.
- **No dependencies** beyond what macOS ships (`ssh`, `scp`, `osascript`,
  `pbcopy`). Don't add pngpaste, jq, Python, etc.

## Release

There is nothing to deploy. Users `git clone` and run `./install.sh`, so a merge
to `main` is the release. `VERSION` in `bin/clippush` is informational.

- 할 일 목록(`BACKLOG.md`)에는 **해야 할 일만** 둔다 — 끝난 행은 `[x]` 로 닫고 원문 그대로 `docs/archive/todo/YYYY-MM.md` 로 옮긴다(요한님 맥: `python3 ~/Repos/yohangwak/ai-assistant/bin/todo-archive.py apply --todo BACKLOG.md --archive-dir docs/archive/todo` — 잃는 줄 0 검사. 손으로 옮길 때는 열린 하위 행이 있는 행은 남긴다). 행은 무엇 + 근거 위치 한 줄(경위·대화 인용·PR 해시는 PR 본문·`docs/`). 남은 판정 예약(⏰)·요한님 결정(🙋)은 비서 `TODO.md` 에도 행으로(이유: 목록이 일지가 되면 할 일이 묻힌다).
