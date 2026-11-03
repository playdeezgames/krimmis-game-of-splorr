#!/usr/bin/env bash
# Runs the native tests of the game package.
set -euo pipefail
cd "$(dirname "$0")/.."
ODIN=${ODIN:-odin}
"$ODIN" test src/game -define:ODIN_TEST_THREADS=1
"$ODIN" test src/ui -collection:krimmis=src -define:ODIN_TEST_THREADS=1
rm -f game ui # the test run can leave stray binaries
