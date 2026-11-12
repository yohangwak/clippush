# shellcheck shell=bash
# The clipboard is read before any SSH connection is opened: nothing to push
# should fail at once, without a network round trip or an SSH-agent prompt.

test_multiple_hosts_are_rejected_before_clipboard_or_network() {
  for cmd in push --setup; do
    : > "$CLIPPUSH_TEST_LOG"
    if [ "$cmd" = push ]; then clippush first second
    else clippush first second "$cmd"; fi
    assert_status 1
    assert_not_contains "$CLIPPUSH_TEST_LOG" 'osascript read'
    assert_not_contains "$CLIPPUSH_TEST_LOG" 'ssh '
  done
  assert_missing "$HOME/.config/raycast/scripts/clippush.sh"
}

test_empty_clipboard_fails_without_connecting() {
  clippush
  assert_status 1
  assert_contains "$SANDBOX/err" "clipboard has no files and no image"
  assert_not_contains "$CLIPPUSH_TEST_LOG" "ssh "
  assert_missing "$REMOTE/.clippush"
}

test_empty_clipboard_is_reported_even_when_the_host_is_down() {
  CLIPPUSH_TEST_SSH_FAIL=1 clippush
  assert_status 1
  assert_contains "$SANDBOX/err" "clipboard has no files and no image"
  assert_not_contains "$SANDBOX/err" "Connection refused"
}

test_screenshot_temp_file_is_removed_when_the_host_is_down() {
  clip_image
  CLIPPUSH_TEST_SSH_FAIL=1 clippush
  [ "$STATUS" -ne 0 ] || fail "expected a non-zero exit"
  assert_contains "$SANDBOX/err" "Connection refused"
  set -- "$TMPDIR"/clipboard-*.png
  assert_missing "$1"
}

test_clean_and_init_remote_do_not_read_the_clipboard() {
  clippush --clean
  assert_status 0
  clippush --init-remote
  assert_status 0
  assert_not_contains "$CLIPPUSH_TEST_LOG" "osascript read"
}
