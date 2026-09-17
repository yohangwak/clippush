# shellcheck shell=bash
# Sandbox and assertions shared by test/*_test.sh. Sourced by test/run.sh.
#
# Every test runs in a subshell with its own sandbox:
#   $SANDBOX/local    local $HOME (cache, Raycast script)
#   $SANDBOX/remote   the "server" $HOME — test/stubs/ssh and scp act on it
#   $SANDBOX/vartmp   stands in for the server's /var/tmp (--share)
#   $SANDBOX/src      files to put on the fake clipboard
#   $PASTEBOARD       what pbcopy received

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIPPUSH_BIN="${CLIPPUSH_BIN:-$TEST_ROOT/bin/clippush}"
TEST_BASH="${TEST_BASH:-bash}"

sandbox() {
  # -P: macOS TMPDIR sits under the /var → /private/var symlink, and the
  # remote `pwd` would otherwise disagree with the paths the tests build
  SANDBOX="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/clippush-test.XXXXXX")" && pwd -P)"
  [ -n "${KEEP_SANDBOX:-}" ] || trap 'rm -rf "$SANDBOX"' EXIT
  mkdir -p "$SANDBOX/local" "$SANDBOX/remote" "$SANDBOX/vartmp" "$SANDBOX/tmp" "$SANDBOX/src"

  unset XDG_CACHE_HOME CLIPPUSH_DIR CLIPPUSH_KEEP CLIPPUSH_SHARE \
        CLIPPUSH_TEST_CLIP_FILES CLIPPUSH_TEST_CLIP_IMAGE CLIPPUSH_TEST_SSH_FAIL
  export HOME="$SANDBOX/local"
  export TMPDIR="$SANDBOX/tmp"
  export CLIPPUSH_HOST="testhost"
  export CLIPPUSH_TEST_REMOTE_HOME="$SANDBOX/remote"
  export CLIPPUSH_TEST_VARTMP="$SANDBOX/vartmp"
  export CLIPPUSH_TEST_PASTEBOARD="$SANDBOX/pasteboard"
  export CLIPPUSH_TEST_LOG="$SANDBOX/calls.log"
  export PATH="$TEST_ROOT/test/stubs:$PATH"
  : > "$CLIPPUSH_TEST_LOG"

  REMOTE="$SANDBOX/remote"
  PASTEBOARD="$CLIPPUSH_TEST_PASTEBOARD"
}

# run bin/clippush; sets $STATUS, output in $SANDBOX/out and $SANDBOX/err
clippush() {
  "$TEST_BASH" "$CLIPPUSH_BIN" "$@" > "$SANDBOX/out" 2> "$SANDBOX/err"
  STATUS=$?
}

# create $SANDBOX/src/<relpath> (optional content) and print its path
mkfile() {
  local p="$SANDBOX/src/$1"
  mkdir -p "$(dirname "$p")"
  printf '%s\n' "${2:-content of $1}" > "$p"
  printf '%s' "$p"
}

# "Cmd+C in Finder" on the given paths
clip_files() { local IFS=$'\n'; export CLIPPUSH_TEST_CLIP_FILES="$*"; }

# "a screenshot on the clipboard"
clip_image() {
  printf '\211PNG\r\n\032\nfake image bytes' > "$SANDBOX/src/shot.png"
  export CLIPPUSH_TEST_CLIP_IMAGE="$SANDBOX/src/shot.png"
}

# the batch directory the remote `latest` symlink points at
latest_batch() { readlink "${1:-$REMOTE/.clippush}/latest"; }

# drwx------ style mode string
mode() { ls -ld "$1" | cut -c1-10; }

# an old batch dir, as if pushed at <YYYYMMDDhhmm>
old_batch() { mkdir -p "$1/${2%????}-000000" && touch -t "$2" "$1/${2%????}-000000"; }

# ---------- assertions: the first failure ends the test ----------------------
fail() {
  echo "$*"
  printf -- '--- stdout ---\n%s\n--- stderr ---\n%s\n' \
    "$(cat "$SANDBOX/out" 2>/dev/null)" "$(cat "$SANDBOX/err" 2>/dev/null)"
  exit 1
}
assert_status()       { [ "$STATUS" = "$1" ] || fail "exit status $STATUS, expected $1"; }
assert_eq()           { [ "$1" = "$2" ] || fail "${3:-value}: got '$1', expected '$2'"; }
assert_contains()     { grep -qF -- "$2" "$1" || fail "$(basename "$1") does not contain: $2"; }
assert_not_contains() { ! grep -qF -- "$2" "$1" || fail "$(basename "$1") should not contain: $2"; }
assert_exists()       { [ -e "$1" ] || fail "missing: $1"; }
assert_missing()      { [ ! -e "$1" ] && [ ! -L "$1" ] || fail "should not exist: $1"; }
assert_same_file()    { cmp -s "$1" "$2" || fail "$2 differs from $1 (or is missing)"; }
