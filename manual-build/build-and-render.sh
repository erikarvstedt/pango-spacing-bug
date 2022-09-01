#!/usr/bin/env bash
set -euo pipefail

cd "${BASH_SOURCE[0]%/*}"

./build.sh

outfile=${1:-out.png}
renderText() {
    font="System Font 12"
    env -i PATH="$PATH" bwrap \
        --bind $PWD $PWD \
        --proc /proc \
        --dev /dev \
        --tmpfs /tmp \
        --ro-bind-try /nix /nix \
        --ro-bind-try /usr /usr \
        --ro-bind ../etc-fonts /etc/fonts \
        -- ./build/utils/pango-view --font="$font" -t "The quickbrownfoxjumps over the lazy dog" -q -o "$outfile"
    echo "Wrote $outfile"
}
renderText
