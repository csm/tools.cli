#!/bin/sh
# Run the tools.cli test suite under cljrs (https://github.com/csm/clojurust)
# in both interpreter and AOT-compiled modes. Exits non-zero on any failure.
#
# Source paths for the interpreter come from cljrs.edn (:paths). The AOT
# compiler does not read cljrs.edn, so it is given the main source path
# explicitly; the test directory is supplied via --test.
set -e

MAIN=src/main/clojure
TEST=src/test/clojure
BIN=target/cljrs-test

# A run "passed" only if cljrs exits 0 AND the summary reports no failures or
# errors. The grep guards against a runner that prints a summary but exits 0.
check_summary() {
  grep -Eq "0 failed, 0 errors" "$1" || {
    echo "Test summary did not report a clean run:"
    cat "$1"
    return 1
  }
}

echo ""
echo "Running cljrs tests (interpreter mode)..."
cljrs test 2>&1 | tee /tmp/cljrs-interp.log
check_summary /tmp/cljrs-interp.log

echo ""
echo "Running cljrs tests (AOT compiled mode)..."
mkdir -p target
cljrs compile --test "$TEST" --src-path "$MAIN" -o "$BIN"
"./$BIN" 2>&1 | tee /tmp/cljrs-aot.log
check_summary /tmp/cljrs-aot.log

echo ""
echo "All cljrs tests passed (interpreter and AOT)."
