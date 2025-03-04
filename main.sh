#!/usr/bin/env bash
set -euo pipefail

: ${ETC_FONT_DIR:=etc-fonts}

fcenv() {
    env -i PATH="$PATH" bwrap \
        --bind $PWD $PWD \
        --proc /proc \
        --dev /dev \
        --tmpfs /tmp \
        --bind /nix /nix \
        --ro-bind-try /usr /usr \
        --ro-bind "$ETC_FONT_DIR" /etc/fonts \
        -- "$@"
}

renderText() {
    pango_view=$1
    font=$2
    outname_suffix=$3
    outname=${font}-${outname_suffix}
    fcenv "$pango_view" --font="$font" -t "The quickbrownfoxjumps over the lazy dog" -q -o "$outname.png"
}

renderVersion() {
    version=$1
    font=$2
    renderText "${!version}"/bin/pango-view "$font" "$version"
}

echo $pangoVersions
for version in $pangoVersions; do
    renderVersion $version "SF Pro Display 12"
    renderVersion $version "System Font 12"
done

if [[ -v pango_good && -v pango_1_50_9 ]]; then
    renderVersion pango_good "SF Pro Display 30"
    renderVersion pango_1_50_9 "SF Pro Display 30"
fi

# renderVersion pango_1_50_9 "System Font 12"
# renderVersion pango_1_50_9 "SF Pro Display 12"

# list fonts
# fcenv fc-list
