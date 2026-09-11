# shellcheck shell=bash
# /clip reads <inbox>/latest. With CLIPPUSH_DIR set, the installed command has to
# look there — otherwise it reads a stale ~/.clippush, or nothing.

test_init_remote_points_clip_at_an_absolute_CLIPPUSH_DIR() {
  CLIPPUSH_DIR="$SANDBOX/inbox" clippush --init-remote
  assert_status 0
  md="$REMOTE/.claude/commands/clip.md"
  assert_contains "$md" "ls -laR $SANDBOX/inbox/latest/"
  assert_not_contains "$md" "~/.clippush"
}

test_init_remote_resolves_a_relative_CLIPPUSH_DIR() {
  CLIPPUSH_DIR=inbox clippush --init-remote
  assert_status 0
  assert_contains "$REMOTE/.claude/commands/clip.md" "$REMOTE/inbox/latest/"
}

test_clip_reads_the_batch_clippush_just_pushed() {
  mkdir -p "$REMOTE/.clippush/20200101-000000"
  ln -s "$REMOTE/.clippush/20200101-000000" "$REMOTE/.clippush/latest"   # stale default inbox
  clip_files "$(mkfile fresh.txt)"
  CLIPPUSH_DIR=inbox clippush
  CLIPPUSH_DIR=inbox clippush --init-remote
  listing="$(grep -o 'ls -laR [^ ]*' "$REMOTE/.claude/commands/clip.md" | head -1 | cut -d' ' -f3)"
  assert_exists "$listing/fresh.txt"
}

test_init_remote_takes_special_characters_in_CLIPPUSH_DIR_literally() {
  CLIPPUSH_DIR='a&b\n' clippush --init-remote
  assert_status 0
  assert_contains "$REMOTE/.claude/commands/clip.md" "ls -laR $REMOTE/a&b\\n/latest/"
}
