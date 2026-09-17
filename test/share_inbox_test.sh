# shellcheck shell=bash
# The --share inbox lives in /var/tmp, which every account can write to. Another
# account could plant /var/tmp/clippush-<you> first; clippush must not chmod,
# fill, or later `--clean` whatever that entry points at.

test_share_refuses_a_symlink_planted_at_the_inbox_path() {
  mkdir -p "$REMOTE/.ssh"; chmod 700 "$REMOTE/.ssh"
  ln -s "$REMOTE/.ssh" "$CLIPPUSH_TEST_VARTMP/clippush-$(id -un)"
  clip_files "$(mkfile a.txt)"
  clippush --share
  assert_status 1
  assert_contains "$SANDBOX/err" "refusing"
  assert_eq "$(mode "$REMOTE/.ssh")" drwx------ ".ssh mode"
  assert_eq "$(ls -A "$REMOTE/.ssh")" "" ".ssh contents"
  assert_not_contains "$CLIPPUSH_TEST_LOG" "scp "
}

test_share_clean_refuses_a_planted_symlink_too() {
  mkdir -p "$REMOTE/work"; echo keep > "$REMOTE/work/file"
  ln -s "$REMOTE/work" "$CLIPPUSH_TEST_VARTMP/clippush-$(id -un)"
  clippush --share --clean
  assert_status 1
  assert_exists "$REMOTE/work/file"
}

test_share_reuses_its_own_inbox() {
  clip_files "$(mkfile a.txt)"
  clippush --share
  assert_status 0
  clippush --share
  assert_status 0
  inbox="$CLIPPUSH_TEST_VARTMP/clippush-$(id -un)"
  [ ! -L "$inbox" ] || fail "inbox became a symlink"
  assert_exists "$(latest_batch "$inbox")/a.txt"
}
