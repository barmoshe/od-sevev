# Gameplay reel: Ben Gvir's round, hosted by Mordechai David

`od-sevev-gameplay.mp4` (1080x1920, 68 s) and its cover `od-sevev-gameplay-cover.png`.

## How it is made

1. **Capture the real game** with Godot's Movie Maker (every frame at a fixed 30 fps, full
   resolution, however slow the render). A temporary `game/override.cfg` sets the window and loads
   the dev-only driver `game/tests/dev/gameplay_capture.gd`, which plays the scripted round in
   `plan-bengvir.json` through the real UI (pick Ben Gvir, taps, purchases, the Mordechai David
   event, the coalition chat, the election). Delete the override after; it must never ship.

   ```
   printf '[display]\nwindow/size/window_width_override=1080\nwindow/size/window_height_override=2338\n[autoload]\nCapture="*res://tests/dev/gameplay_capture.gd"\n' > game/override.cfg
   HOME=<fresh dir> xvfb-run -a -s "-screen 0 1200x2500x24" <Godot 4.7.2> --path game \
     --rendering-driver opengl3 --write-movie <take>/f.png --fixed-fps 30 --quit-after 2100 \
     -- --plan=store/gameplay/plan-bengvir.json
   rm game/override.cfg
   ```
   About 12 minutes on the container (software GL). A fresh `HOME` gives a fresh save (the picker).

2. **Cut it** to `music/soundtrack.wav` (Bar's track, 98.4 BPM): `python3 src/gameplay.py <take>`.
   The clip list, captions and the host's lines are data at the top of `src/gameplay.py`.
