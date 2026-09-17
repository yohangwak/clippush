# shellcheck shell=bash
# Two copied files with the same name must both arrive, whatever the name.

test_names_starting_with_a_dash_are_deduplicated() {
  clip_files "$(mkfile a/-draft.txt A)" "$(mkfile b/-draft.txt B)"
  clippush
  assert_status 0
  batch="$(latest_batch)"
  assert_eq "$(cat "$batch/-draft.txt")"   A "-draft.txt"
  assert_eq "$(cat "$batch/-draft-2.txt")" B "-draft-2.txt"
  assert_not_contains "$SANDBOX/err" "grep"
}

test_dotfiles_keep_their_leading_dot_when_renamed() {
  clip_files "$(mkfile a/.env A)" "$(mkfile b/.env B)" \
             "$(mkfile a/.bashrc.bak C)" "$(mkfile b/.bashrc.bak D)"
  clippush
  assert_status 0
  batch="$(latest_batch)"
  assert_eq "$(cat "$batch/.env")"          A ".env"
  assert_eq "$(cat "$batch/.env-2")"        B ".env-2"
  assert_eq "$(cat "$batch/.bashrc.bak")"   C ".bashrc.bak"
  assert_eq "$(cat "$batch/.bashrc-2.bak")" D ".bashrc-2.bak"
}
