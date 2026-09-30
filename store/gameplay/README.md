# Gameplay reel: Ben Gvir's round, hosted by Mordechai David

Two cuts of the same take, 1080x1920, 68 s, each with its cover (the last frame, also frames 0-1):

- `od-sevev-gameplay-iphone.mp4` (v4, the one to post): the game on a drawn iPhone over a blurred copy
  of the footage, iOS "show touches" at every real tap, camera push-ins, captions in the top band.
- `od-sevev-gameplay.mp4` (v3): the bare screen on velvet.

Mordechai David is an easter egg in both: two short peeks, one of them on the cover.

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
   The iPhone cut: `python3 src/gameplay_iphone.py <take>` (`--stills` for a contact sheet,
   `--one <sec>` for one frame). The taps are rebuilt from the plan plus the take's log (`take1.log`
   next to the take folder: the buy rows) and the pay pills found on the frames; the camera keys,
   captions and peeks are data at the top of the file.

## Why the iPhone cut looks the way it does (research, Sep 2026)

- Reels covers the bottom ~320 px (caption, audio) and the right ~120 px (buttons), and the top
  ~108 px: captions sit in the top band, the phone in the middle.
- Mobile-game ads: gameplay in the first frame, the core loop in 3 s, burned-in captions (sound-off),
  phone-in-hand framing beats a flat trailer. So: open tight on the game, pull back to the phone, sway.
- App promo craft (and the workshop's `video-tutorial` kit): push in for the action, pull back for
  context; tap disc + ripple; push ~0.9 s on a soft ease.
- The tab bar unlocks ~15 s into a real round; the hook uses late-game footage so the whole screen
  is there from the first frame.

