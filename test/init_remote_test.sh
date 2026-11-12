# shellcheck shell=bash
# /clip reads <inbox>/latest. With CLIPPUSH_DIR set, the installed command has to
# look there — otherwise it reads a stale ~/.clippush, or nothing.

run_installed_clip_listing() {
  local cmd
  cmd="$(sed -n 's/.*`\(ls [^`]*\)`.*/\1/p' "$REMOTE/.claude/commands/clip.md")"
  [ -n "$cmd" ] || fail "installed /clip has no listing command"
  # The optional share inbox may not exist; check the listing's contents.
  (cd "$REMOTE" && HOME="$REMOTE" sh -c "$cmd") > "$SANDBOX/listing" || true
}

test_init_remote_points_clip_at_an_absolute_CLIPPUSH_DIR() {
  mkdir -p "$SANDBOX/inbox/latest"
  touch "$SANDBOX/inbox/latest/fresh.txt"
  CLIPPUSH_DIR="$SANDBOX/inbox" clippush --init-remote
  assert_status 0
  md="$REMOTE/.claude/commands/clip.md"
  run_installed_clip_listing
  assert_contains "$SANDBOX/listing" 'fresh.txt'
  assert_not_contains "$md" "~/.clippush"
}

test_init_remote_resolves_a_relative_CLIPPUSH_DIR() {
  mkdir -p "$REMOTE/inbox/latest"
  touch "$REMOTE/inbox/latest/fresh.txt"
  CLIPPUSH_DIR=inbox clippush --init-remote
  assert_status 0
  run_installed_clip_listing
  assert_contains "$SANDBOX/listing" 'fresh.txt'
}

test_clip_reads_the_batch_clippush_just_pushed() {
  mkdir -p "$REMOTE/.clippush/20200101-000000"
  ln -s "$REMOTE/.clippush/20200101-000000" "$REMOTE/.clippush/latest"   # stale default inbox
  clip_files "$(mkfile fresh.txt)"
  CLIPPUSH_DIR='inbox with spaces' clippush
  assert_status 0
  CLIPPUSH_DIR='inbox with spaces' clippush --init-remote
  assert_status 0
  run_installed_clip_listing
  assert_contains "$SANDBOX/listing" 'fresh.txt'
}

test_init_remote_takes_special_characters_in_CLIPPUSH_DIR_literally() {
  special='a&b\n'
  mkdir -p "$REMOTE/$special/latest"
  touch "$REMOTE/$special/latest/fresh.txt"
  CLIPPUSH_DIR="$special" clippush --init-remote
  assert_status 0
  run_installed_clip_listing
  assert_contains "$SANDBOX/listing" 'fresh.txt'
}
