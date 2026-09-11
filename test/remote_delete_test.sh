# shellcheck shell=bash
# clippush deletes on the server in two places — pruning and --clean. Both must
# only ever remove what clippush itself created: timestamped batch folders and
# the `latest` symlink. CLIPPUSH_DIR can point at a folder that holds other data.

test_prune_leaves_folders_clippush_did_not_create() {
  mkdir -p "$REMOTE/shared/2023" "$REMOTE/shared/2024-taxes"
  echo keep > "$REMOTE/shared/2023/report.pdf"
  touch -t 202301010000 "$REMOTE/shared/2023" "$REMOTE/shared/2024-taxes"
  old_batch "$REMOTE/shared" 202001010000
  clip_files "$(mkfile a.txt)"
  CLIPPUSH_DIR=shared CLIPPUSH_KEEP=1 clippush
  assert_status 0
  assert_exists "$REMOTE/shared/2023/report.pdf"
  assert_exists "$REMOTE/shared/2024-taxes"
  assert_missing "$REMOTE/shared/20200101-000000"
  assert_exists "$(latest_batch "$REMOTE/shared")/a.txt"
}

test_clean_removes_batches_but_keeps_other_files_in_the_folder() {
  mkdir -p "$REMOTE/shared/2024"
  echo keep > "$REMOTE/shared/notes.txt"
  clip_files "$(mkfile a.txt)"
  CLIPPUSH_DIR=shared clippush
  batch="$(latest_batch "$REMOTE/shared")"
  CLIPPUSH_DIR=shared clippush --clean
  assert_status 0
  assert_missing "$batch"
  assert_missing "$REMOTE/shared/latest"
  assert_exists "$REMOTE/shared/notes.txt"
  assert_exists "$REMOTE/shared/2024"
  assert_contains "$SANDBOX/out" "kept"
}

test_clean_with_CLIPPUSH_DIR_set_to_home_does_not_wipe_home() {
  echo precious > "$REMOTE/notes.txt"
  mkdir -p "$REMOTE/project"
  CLIPPUSH_DIR=. clippush --clean
  assert_status 0
  assert_exists "$REMOTE/notes.txt"
  assert_exists "$REMOTE/project"
}

test_clean_keeps_a_regular_file_named_latest() {
  mkdir -p "$REMOTE/shared"
  echo mine > "$REMOTE/shared/latest"
  CLIPPUSH_DIR=shared clippush --clean
  assert_status 0
  assert_exists "$REMOTE/shared/latest"
}

test_invalid_CLIPPUSH_KEEP_is_rejected_before_connecting() {
  clip_files "$(mkfile a.txt)"
  for keep in 0 -1 ten 1.5; do
    : > "$CLIPPUSH_TEST_LOG"
    CLIPPUSH_KEEP="$keep" clippush
    assert_status 1
    assert_contains "$SANDBOX/err" "CLIPPUSH_KEEP"
    assert_not_contains "$CLIPPUSH_TEST_LOG" "ssh "
  done
  assert_missing "$REMOTE/.clippush"
}

test_CLIPPUSH_KEEP_with_a_leading_zero_is_decimal() {
  inbox="$REMOTE/.clippush"
  for day in 01 02 03 04 05 06 07 08 09; do old_batch "$inbox" "202001${day}0000"; done
  clip_files "$(mkfile a.txt)"
  CLIPPUSH_KEEP=08 clippush
  assert_status 0
  set -- "$inbox"/20*-*
  assert_eq "$#" 8 "batches kept"
  assert_exists "$PASTEBOARD"
}
