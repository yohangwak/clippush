---
description: Read the file(s) most recently pushed from my local machine via clippush
allowed-tools: Bash(ls:*), Read
---

Files pushed from my local machine land in `~/.clippush/`, and `~/.clippush/latest` is a symlink to the most recent batch. Pushes made with `clippush --share` land in `/var/tmp/clippush-<user>/` instead — that mode exists for when you are running as a different user than the one I push from, so my home directory is unreadable to you.

1. Run `ls -laR ~/.clippush/latest/ /var/tmp/clippush-*/latest/ 2>/dev/null` to see what was just pushed (a batch may contain folders as well as files). If both exist, use the one with the newest timestamp.
2. Read every file in that directory tree with the Read tool, including files inside any subfolders (images will render visually; text/data files as content).
3. If a file type can't be read directly (e.g. .xlsx), inspect it with an appropriate shell tool or ask me how to proceed.
4. Then continue with my request: $ARGUMENTS
