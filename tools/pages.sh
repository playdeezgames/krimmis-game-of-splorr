#!/usr/bin/env bash
# Builds the GitHub Pages site: tests, a size-optimised web build, copied into docs/. Never commits, never pushes.
# Usage: tools/pages.sh   (then commit docs/ and, when told to, git push)
set -euo pipefail
cd "$(dirname "$0")/.."
tools/test.sh
OPT=size tools/build.sh
rm -rf docs
mkdir docs
cp -r build/web/. docs/
touch docs/.nojekyll
echo "docs/ ready ($(du -sh docs | cut -f1))."
