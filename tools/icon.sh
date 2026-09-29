#!/usr/bin/env bash
# RETIRED in od-sevev. The fork generated its banana icons here; the app icons in
# game/assets/icon/ now come from the 2D Artist's master (art/od-sevev/out/key/icon-64-art.png)
# through the Technical Artist's pipeline (python3 pipeline/od-sevev/build.py). Running the fork's
# generator would overwrite them with the banana, so this script refuses.
echo "tools/icon.sh is retired: the icons come from pipeline/od-sevev/build.py (Technical Artist)." >&2
exit 2
