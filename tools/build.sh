#!/usr/bin/env bash
# Builds the wasm game into build/web, ready to serve or zip.
# Usage: tools/build.sh   (OPT=size for the shipping build; default is speed)
set -euo pipefail
cd "$(dirname "$0")/.."
ODIN=${ODIN:-odin}
OUT=build/web
mkdir -p "$OUT"
"$ODIN" build src/web -collection:krimmis=src -target:js_wasm32 -out:"$OUT/game.wasm" -o:"${OPT:-speed}" "$@"
cp web/index.html "$OUT/"
cp "$("$ODIN" root)/core/sys/wasm/js/odin.js" "$OUT/"
cp assets/tileset.png assets/krimmis.png assets/dinobyte/dbyte_1x.png "$OUT/"
mkdir -p "$OUT/sfx"
cp assets/sfx/*.wav "$OUT/sfx/"
