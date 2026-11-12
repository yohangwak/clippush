# Backlog

Known issues and open questions not fixed yet. Found in the 2026-11-06 review;
none of them is urgent.

## Known limitations

- **Apostrophes in remote inbox paths on Bash 3.2.** With an apostrophe in
  `CLIPPUSH_DIR`, remote directory resolution fails with an unmatched shell
  quote. Reproduced in both the original 0.1.0 code and the 0.1.1 maintenance
  work; the shared `shq` helper needs a separate compatibility fix.

## Housekeeping

- **`.github/workflows/pullfrog.yml`.** The workflow is disabled on GitHub, the
  repository has no secrets, and its 8 runs (2026-09-11) all failed. It pins
  third-party actions by tag only (`pullfrog/pullfrog@v0`) and grants them
  write access to the OIDC ID token. Deleting it (and its `CLAUDE.md` row, along with the
  "no CI" note) is waiting on the owner's decision.
