nix develop ..#manual-build-env

git clone https://gitlab.gnome.org/GNOME/pango

buildrev() {
    revName=$1
    outFile=${2:-$revName.png}
    rev=${!revName}
    git -C pango checkout $rev
    ./build-and-render.sh $outFile
}

# build pango (src: ./pango) to ./build
./build.sh
# build pango and render text
./build-and-render.sh out.png

good=1.48.10
bad_final=1.50.7

buildrev good


git -C pango checkout tags/$bad_final
git -C pango checkout tags/$good

mkdir build
(cd build; meson  --buildtype=release ../pango)
(cd build; ninja)

git -C pango checkout $good
env --chdir pango ../bisect-cmd.sh reference.png

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# rebase fns
createBisectReferenceImg() {
    git -C pango checkout $1
    rm -f reference.png
    ./build-and-render.sh reference.png
}

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# bisect 1 (diff: slight change in image height)

createBisectReferenceImg $good
git -C pango bisect start $bad_final $good
git -C pango bisect run ../bisect-cmd.sh

bad1=047bfaf6012207df2803f51617a165beced7612f
Author: Matthias Clasen <mclasen@redhat.com>
Date:   Tue Oct 19 15:12:56 2021 -0400

047bfaf * bad Use harfbuzz metrics for cairo fonts
6b260a6 * good-6b260a686b2c46237cb2673f23de163b252192bc cairo: fix hinting of metrics

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# bisect 2 (diff: slightly more spacing)

createBisectReferenceImg $bad1
git -C pango bisect start $bad_final $bad1
git -C pango bisect run ../bisect-cmd.sh

bad2=ccb651dd2a876a4f4a4cb9351f05332173e709ba
commit ccb651dd2a876a4f4a4cb9351f05332173e709ba
Author: Matthias Clasen <mclasen@redhat.com>
Date:   Fri Nov 5 06:57:44 2021 -0400
Fix advance widths with transforms

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# bisect 3 (diff: much more spacing)

createBisectReferenceImg $bad2
git -C pango bisect start $bad_final $bad2
git -C pango bisect run ../bisect-cmd.sh

bad3=4e9463108773bb9d45187efd61c6c395e0122187
Author: Matthias Clasen <mclasen@redhat.com>
Date:   Mon Nov 8 20:06:47 2021 -0500
Call hb_font_set_ptem when creating fonts

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# bisect 4 (diff: slight change in image height)

createBisectReferenceImg $bad3
git -C pango bisect start $bad_final $bad3
git -C pango bisect run ../bisect-cmd.sh

bad4=303f79e14047d60c3ca41c24931c8cb6115433ae
Author: Sebastian Keller <skeller@gnome.org>
Date:   Mon Nov 22 01:54:15 2021 +0100
Calculate hinted font height based on the hinted extents

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# bisect 5 (final, bad5=bad_final, diff: slightly less spacing)

createBisectReferenceImg $bad4
git -C pango bisect start $bad_final $bad4
git -C pango bisect run ../bisect-cmd.sh

bad5=22f8df579d82f342909b629c0e94b8ff7c5452fd
Author: Matthias Clasen <mclasen@redhat.com>
Date:   Fri Dec 17 14:24:17 2021 -0500
Revert "Fix advance widths with transforms"
This reverts commit ccb651dd2a876a4f4a4cb9351f05332173e709ba

buildrev bad5
cmp bad5.png bad_final.png

#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
v1_50_9=1.50.9
v1_49_3=1.49.3
buildrev v1_50_9
buildrev v1_49_3
buildrev bad1
buildrev bad2
buildrev bad3
buildrev bad4
buildrev bad5
#―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

git -C pango merge-base --is-ancestor $bad1 tags/1.49.3
git -C pango merge-base --is-ancestor $bad2 tags/1.49.3
git -C pango merge-base --is-ancestor $bad3 tags/1.49.4
git -C pango merge-base --is-ancestor $bad4 tags/1.49.4
git -C pango merge-base --is-ancestor $bad5 tags/1.50.3
git -C pango merge-base --is-ancestor aae5fa3d34f021a3dcf8663d55f4fec19e9f7aff tags/1.49.4

cleanup() {
    rf -f *.png
}
cleanup
