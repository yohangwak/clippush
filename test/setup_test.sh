# shellcheck shell=bash
# --setup bakes the environment into the Raycast script, because Raycast runs it
# in a bare shell. Anything left out silently falls back to its default there.

test_setup_bakes_CLIPPUSH_KEEP() {
  CLIPPUSH_KEEP=50 clippush --setup
  assert_status 0
  assert_contains "$HOME/.config/raycast/scripts/clippush.sh" 'export CLIPPUSH_KEEP="50"'
}

test_setup_leaves_CLIPPUSH_KEEP_out_when_unset() {
  clippush --setup
  assert_status 0
  assert_not_contains "$HOME/.config/raycast/scripts/clippush.sh" "CLIPPUSH_KEEP"
}
