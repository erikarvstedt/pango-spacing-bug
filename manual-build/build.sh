#!/usr/bin/env bash
set -euo pipefail

cd "${BASH_SOURCE[0]%/*}"
mkdir -p build
cd build
meson --buildtype=release ../pango && ninja
