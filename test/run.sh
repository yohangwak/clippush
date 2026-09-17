#!/usr/bin/env bash
# clippush test suite. No SSH server, clipboard, or Mac needed: ssh, scp,
# osascript and pbcopy are replaced by the doubles in test/stubs/.
#
#   ./test/run.sh                    run everything
#   ./test/run.sh share              only tests whose name contains "share"
#   TEST_BASH=/bin/bash ./test/run.sh   run clippush under macOS's stock bash 3.2
#   KEEP_SANDBOX=1 ./test/run.sh     keep each test's temp dir for inspection
set -u
cd "$(dirname "$0")/.." || exit 1

. test/lib.sh
for f in test/*_test.sh; do . "$f"; done

filter="${1:-}"
passed=0; failed=0; failed_names=""
for t in $(compgen -A function test_); do
  case "$t" in *"$filter"*) ;; *) continue ;; esac
  if msg="$( (sandbox && "$t") 2>&1 )"; then
    passed=$((passed + 1)); echo "  ✓ $t"
  else
    failed=$((failed + 1)); failed_names="$failed_names $t"
    echo "  ✗ $t"; printf '%s\n' "$msg" | sed 's/^/      /'
  fi
done

echo
echo "$passed passed, $failed failed  (clippush run with: $("$TEST_BASH" -c 'echo "bash $BASH_VERSION"'))"
[ "$failed" -eq 0 ] || { echo "failed:$failed_names"; exit 1; }
[ "$passed" -gt 0 ] || { echo "no tests matched '$filter'"; exit 1; }
