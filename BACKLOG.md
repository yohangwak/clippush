# Backlog

Known issues and open questions not fixed yet. Found in the 2026-11-06 review;
none of them is urgent. Line numbers are as of that review.

## Small fixes

- **`--setup` doesn't escape its values.** `bin/clippush` writes `CLIPPUSH_HOST`
  and `CLIPPUSH_DIR` into the Raycast script inside plain `"…"`. A value
  containing `"`, `$` or a backtick produces a broken (or surprising) script.
  Fix: quote with `printf %q`. The values come from your own config, so the risk
  is low.
- **Pruning globs outside `sh -c`.** The prune step after a push runs its batch
  glob directly in the login shell, unlike `--clean`. The batch just pushed
  always matches, so zsh's no-match abort can't trigger today. Still, it breaks
  the rule in `CLAUDE.md`; route it through `sh -c` like `--clean`.
- **The default inbox is created without `umask 077`.** `mkdir -p` for
  `~/.clippush` uses the server's umask. With 022 the folder is 0755, so other
  accounts can list batch names. The batches themselves are 0700, so their
  contents stay private.
- **`/clip` hint with a spaced `CLIPPUSH_DIR`.** The `ls -laR` path in the
  pasted instruction isn't quoted, so an inbox path with a space breaks it.
- **Several positional arguments.** `clippush a b` silently uses `b`. Reject
  more than one host instead.

## Housekeeping

- **`VERSION` is still `0.1.0`** after 21 commits of changes. Decide whether to
  bump it, and whether to tag releases.
- **`.github/workflows/pullfrog.yml`.** The workflow is disabled on GitHub, the
  repository has no secrets, and its 8 runs (2026-09-11) all failed. It pins
  third-party actions by tag only (`pullfrog/pullfrog@v0`) and grants them
  write access to the OIDC ID token. Deleting it (and its `CLAUDE.md` row, along with the
  "no CI" note) is waiting on the owner's decision.
