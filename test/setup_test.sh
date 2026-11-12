# shellcheck shell=bash
# --setup bakes the environment into the Raycast script, because Raycast runs it
# in a bare shell. Anything left out silently falls back to its default there.

prepare_launcher_probe() {
  mkdir -p "$SANDBOX/launcher bin"
  CLIPPUSH_BIN="$SANDBOX/launcher bin/clippush"
  cp "$TEST_ROOT/bin/clippush" "$CLIPPUSH_BIN"
}

run_launcher_probe() {
  # Replace only the sandbox copy after --setup so executing the generated
  # launcher observes its environment and executable path without any upload.
  cat > "$CLIPPUSH_BIN" <<'EOF'
#!/bin/bash
printf 'host=%s\ndir=%s\nshare=%s\nkeep=%s\npath=%s\n' \
  "${CLIPPUSH_HOST-unset}" "${CLIPPUSH_DIR-unset}" \
  "${CLIPPUSH_SHARE-unset}" "${CLIPPUSH_KEEP-unset}" "$PATH"
EOF
  chmod +x "$CLIPPUSH_BIN"
  (unset CLIPPUSH_HOST CLIPPUSH_DIR CLIPPUSH_SHARE CLIPPUSH_KEEP
   /bin/bash "$HOME/.config/raycast/scripts/clippush.sh") > "$SANDBOX/launcher-env" 2> "$SANDBOX/err"
  STATUS=$?
  assert_status 0
}

test_setup_bakes_CLIPPUSH_KEEP() {
  prepare_launcher_probe
  CLIPPUSH_KEEP=50 clippush --setup
  assert_status 0
  run_launcher_probe
  assert_contains "$SANDBOX/launcher-env" 'keep=50'
}

test_setup_leaves_CLIPPUSH_KEEP_out_when_unset() {
  prepare_launcher_probe
  clippush --setup
  assert_status 0
  run_launcher_probe
  assert_contains "$SANDBOX/launcher-env" 'keep=unset'
}

test_setup_preserves_literal_config_and_executable_path() {
  prepare_launcher_probe
  special='space "quote" '\''single $HOME `printf changed` back\slash'
  bin_dir="$SANDBOX/$special"
  mkdir -p "$bin_dir"
  mv "$CLIPPUSH_BIN" "$bin_dir/clippush"
  CLIPPUSH_BIN="$bin_dir/clippush"
  CLIPPUSH_HOST="$special" CLIPPUSH_DIR="$special" clippush --setup
  assert_status 0
  run_launcher_probe
  assert_contains "$SANDBOX/launcher-env" "host=$special"
  assert_contains "$SANDBOX/launcher-env" "dir=$special"
  assert_contains "$SANDBOX/launcher-env" "path=$bin_dir:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
}
