# shellcheck shell=bash
# Core behaviour: push, --share, pruning, --last, --setup, --init-remote, --clean.

test_push_uploads_files_into_a_timestamped_batch() {
  a="$(mkfile rates.xlsx)"; b="$(mkfile error.png)"
  clip_files "$a" "$b"
  clippush
  assert_status 0
  batch="$(latest_batch)"
  case "$batch" in
    "$REMOTE/.clippush/"20[0-9][0-9][01][0-9][0-3][0-9]-[0-2][0-9][0-5][0-9][0-5][0-9]) ;;
    *) fail "unexpected batch path: $batch" ;;
  esac
  assert_same_file "$a" "$batch/rates.xlsx"
  assert_same_file "$b" "$batch/error.png"
  assert_contains "$SANDBOX/out" "✅ 2 file(s) → testhost"
}

test_push_copies_a_ready_to_paste_instruction() {
  clip_files "$(mkfile rates.xlsx)" "$(mkfile "my report.pdf")"
  clippush
  assert_status 0
  batch="$(latest_batch)"
  printf 'Read these files and continue with my request:\n%s\n%s\n' \
    "$batch/rates.xlsx" "$batch/my report.pdf" > "$SANDBOX/expected"
  assert_same_file "$SANDBOX/expected" "$PASTEBOARD"
  assert_exists "$batch/my report.pdf"
}

test_push_closes_the_ssh_control_master() {
  clip_files "$(mkfile a.txt)"
  clippush
  assert_status 0
  assert_contains "$CLIPPUSH_TEST_LOG" "-O exit testhost"
}

test_host_argument_wins_over_CLIPPUSH_HOST() {
  clip_files "$(mkfile a.txt)"
  clippush otherhost
  assert_status 0
  assert_contains "$SANDBOX/out" "→ otherhost"
  assert_not_contains "$CLIPPUSH_TEST_LOG" "testhost"
}

test_no_host_is_an_error() {
  unset CLIPPUSH_HOST
  clip_files "$(mkfile a.txt)"
  clippush
  assert_status 1
  assert_contains "$SANDBOX/err" "no target host"
}

test_unknown_option_is_an_error() {
  clippush --bogus
  assert_status 1
  assert_contains "$SANDBOX/err" "unknown option: --bogus"
}

test_help_and_version() {
  clippush --help
  assert_status 0
  assert_contains "$SANDBOX/out" "Usage:"
  clippush --version
  assert_status 0
  assert_contains "$SANDBOX/out" "clippush "
}

test_duplicate_basenames_are_renamed_not_overwritten() {
  clip_files "$(mkfile a/notes.txt A)" "$(mkfile b/notes.txt B)" "$(mkfile c/notes.txt C)" \
             "$(mkfile a/Makefile MA)" "$(mkfile b/Makefile MB)"
  clippush
  assert_status 0
  batch="$(latest_batch)"
  assert_eq "$(cat "$batch/notes.txt")"   A  notes.txt
  assert_eq "$(cat "$batch/notes-2.txt")" B  notes-2.txt
  assert_eq "$(cat "$batch/notes-3.txt")" C  notes-3.txt
  assert_eq "$(cat "$batch/Makefile")"    MA Makefile
  assert_eq "$(cat "$batch/Makefile-2")"  MB Makefile-2
}

test_copied_folder_is_uploaded_recursively() {
  mkfile project/src/main.c >/dev/null
  mkfile project/README >/dev/null
  clip_files "$SANDBOX/src/project"
  clippush
  assert_status 0
  batch="$(latest_batch)"
  assert_same_file "$SANDBOX/src/project/src/main.c" "$batch/project/src/main.c"
  assert_same_file "$SANDBOX/src/project/README" "$batch/project/README"
}

test_screenshot_is_pushed_when_no_files_are_copied() {
  clip_image
  clippush
  assert_status 0
  batch="$(latest_batch)"
  set -- "$batch"/clipboard-*.png
  assert_eq "$#" 1 "uploaded screenshots"
  assert_same_file "$SANDBOX/src/shot.png" "$1"
  set -- "$TMPDIR"/clipboard-*.png
  assert_missing "$1"   # local temp PNG cleaned up
}

test_empty_clipboard_is_an_error() {
  clippush
  assert_status 1
  assert_contains "$SANDBOX/err" "clipboard has no files and no image"
}

test_default_push_is_private() {
  mkfile folder/inner.txt >/dev/null
  clip_files "$(mkfile secret.txt)" "$SANDBOX/src/folder"
  clippush
  assert_status 0
  batch="$(latest_batch)"
  assert_eq "$(mode "$batch")" drwx------ "batch dir mode"
  assert_eq "$(mode "$batch/secret.txt")" -rw------- "file mode"
  assert_eq "$(mode "$batch/folder")" drwx------ "copied folder mode"
  assert_eq "$(mode "$batch/folder/inner.txt")" -rw------- "nested file mode"
}

test_share_pushes_world_readable_into_var_tmp() {
  clip_files "$(mkfile shot.txt)"
  clippush --share
  assert_status 0
  inbox="$CLIPPUSH_TEST_VARTMP/clippush-$(id -un)"
  batch="$(latest_batch "$inbox")"
  assert_same_file "$SANDBOX/src/shot.txt" "$batch/shot.txt"
  assert_eq "$(mode "$inbox")" drwxr-xr-x "inbox mode"
  assert_eq "$(mode "$batch")" drwxr-xr-x "batch dir mode"
  assert_eq "$(mode "$batch/shot.txt")" -rw-r--r-- "file mode"
  assert_missing "$REMOTE/.clippush"
}

test_CLIPPUSH_SHARE_env_enables_share_mode() {
  clip_files "$(mkfile a.txt)"
  CLIPPUSH_SHARE=1 clippush
  assert_status 0
  assert_exists "$CLIPPUSH_TEST_VARTMP/clippush-$(id -un)/latest/a.txt"
}

test_CLIPPUSH_DIR_moves_the_inbox() {
  clip_files "$(mkfile a.txt)"
  CLIPPUSH_DIR="inbox dir" clippush
  assert_status 0
  assert_exists "$REMOTE/inbox dir/latest/a.txt"
}

test_old_batches_are_pruned_to_CLIPPUSH_KEEP() {
  inbox="$REMOTE/.clippush"
  old_batch "$inbox" 202001010000
  old_batch "$inbox" 202001020000
  old_batch "$inbox" 202001030000
  clip_files "$(mkfile a.txt)"
  CLIPPUSH_KEEP=2 clippush
  assert_status 0
  assert_exists "$(latest_batch)/a.txt"
  assert_exists "$inbox/20200103-000000"
  assert_missing "$inbox/20200102-000000"
  assert_missing "$inbox/20200101-000000"
}

test_last_recopies_the_previous_instruction() {
  clippush --last
  assert_status 1
  assert_contains "$SANDBOX/err" "nothing pushed yet"

  clip_files "$(mkfile a.txt)"
  clippush
  cp "$PASTEBOARD" "$SANDBOX/first"
  : > "$PASTEBOARD"
  clippush --last
  assert_status 0
  assert_same_file "$SANDBOX/first" "$PASTEBOARD"
}

test_share_hint_is_shown_once_per_host() {
  clip_files "$(mkfile a.txt)"
  clippush
  assert_contains "$SANDBOX/out" "💡 first push to testhost"
  clippush
  assert_not_contains "$SANDBOX/out" "💡"
  clippush otherhost
  assert_contains "$SANDBOX/out" "💡 first push to otherhost"
}

test_setup_writes_a_raycast_script_with_config_baked_in() {
  CLIPPUSH_DIR=/data/inbox clippush --share --setup
  assert_status 0
  f="$HOME/.config/raycast/scripts/clippush.sh"
  [ -x "$f" ] || fail "not executable: $f"
  assert_contains "$f" "@raycast.title Push clipboard to server"
  assert_contains "$f" 'export CLIPPUSH_HOST="testhost"'
  assert_contains "$f" 'export CLIPPUSH_DIR="/data/inbox"'
  assert_contains "$f" 'export CLIPPUSH_SHARE=1'
  assert_contains "$f" "exec \"$CLIPPUSH_BIN\""
}

test_init_remote_installs_the_clip_command() {
  clippush --init-remote
  assert_status 0
  assert_same_file "$TEST_ROOT/remote/clip.md" "$REMOTE/.claude/commands/clip.md"
}

test_clean_removes_the_inbox() {
  clip_files "$(mkfile a.txt)"
  clippush
  assert_exists "$REMOTE/.clippush/latest"
  clippush --clean
  assert_status 0
  assert_missing "$REMOTE/.clippush"
  assert_contains "$SANDBOX/out" "🧹 removed testhost:$REMOTE/.clippush"
}

test_unreachable_host_fails() {
  clip_files "$(mkfile a.txt)"
  CLIPPUSH_TEST_SSH_FAIL=1 clippush
  [ "$STATUS" -ne 0 ] || fail "expected a non-zero exit"
  assert_contains "$SANDBOX/err" "Connection refused"
  assert_missing "$PASTEBOARD"
}
