# motion/: "עוד סבב"

**Owner:** Animator. **Consumers:**
- Game Developer, who wires it in Godot 4.7.
- Audio Director, for cue alignment.
- Technical Artist, for fx-data and atlas.
- UX Designer, whose flow this motion serves.

## Canonical files (od-sevev)

| File | Typed artifact | What it covers |
|---|---|---|
| [`state-graph-magician.md`](state-graph-magician.md) | `state-graph-spec` | The Magician on stage: idle, tap, crit, the court-day exit and return, the hat left on stage, and the election celebration. Also tap buffering and coins. |
| [`state-graph-cast.md`](state-graph-cast.md) | `state-graph-spec` | The partners: in-thread avatar echoes, full-body card or cameo, leaving and returning the group. Also Sara (offended), Bennett (pledge flip, ping-pong) and the opposition card template. |
| [`motion-spec.yaml`](motion-spec.yaml) | `motion-spec` (UI) | Chat, events, court day, rewards, the title-to-play hand-off, and the ticker. It also lists what carries over from the fork. Every entry has a reduced-motion variant. |
| [`event-markers.md`](event-markers.md) | `hit-frame-data` / `event-marker` | The frame and ms at which every cue or dev hook fires. **Reconciled** (wave 2) against the Audio Director's `audio/od/` cue list. |
| [`state-graph-dubi.md`](state-graph-dubi.md) | `state-graph-spec` | Dubi: perches, flight, squawk and talk driven by the AD's cues, the FTUE fly-in and peck, and his strip spec. |
| [`diorama-motion.md`](diorama-motion.md) | ad hoc: `object-motion` | The 8 money sources: the 2-frame idle per source, the `lob` set piece, and the taxpayer's walk-on. |
| [`render-requests.md`](render-requests.md) | ad hoc: render list | Every strip, prop and landmark motion needs rendered: frames, fps, events, rig recipes. |

## Legacy (Monkey Bananas v2.1.0, kept for the port)

These are in `legacy/`. Comments in `game/scripts/**`, `pipeline/**` and `art/**` still point at the old paths
(`motion/motion-spec.yaml`, `motion/object-motion.md`, `motion/ui-juice.yaml`, `motion/event-markers.md`,
`motion/state-graph-spec.md`). Read them as `motion/legacy/<name>.monkey-bananas.<ext>`.

`motion-spec.yaml` §0 (`_carryover`) names each legacy motion as one of:
- **KEEP:** unchanged, and it still binds.
- **ADAPT:** re-specified in the new file.
- **RETIRE:** the Big Banana, the Golden Banana, evolve and the critters are gone.

A legacy motion that is not named there does not bind.

## Global rules (every file here)

1. **Framerate.** The reference is 60 Hz render, so fN = N × 16.67 ms. Sprite strips play at their authored fps
   (`atlas.json`) through `AnimatedSprite2D` + `SpriteFrames`. Durations are **ms** and easings are **named**. Timelines are
   time-based, so on 120 Hz displays the ms hold and the frame numbers double.
2. **Units.** `ap` = one art pixel of the element being moved.
   - A character drawn at integer render scale `S` moves in multiples of `S` logical px.
   - UI moves on the fork's 4-px logical grid unless stated otherwise.
   - Positions are snapped **after** easing: `snap(v, g) = round(v / g) * g` (as in the legacy `_globals`).
   - Runtime rotation and non-integer scale of pixel art are banned. The one exception is a transient of 180 ms or
     less (legacy rule).
3. **Easing names → Godot.**
   - `Quad.Out` = `TRANS_QUAD, EASE_OUT`
   - `Quad.In` = `TRANS_QUAD, EASE_IN`
   - `Quad.InOut` = `TRANS_QUAD, EASE_IN_OUT`
   - `Cubic.Out` = `TRANS_CUBIC, EASE_OUT`
   - `Expo.Out` = `TRANS_EXPO, EASE_OUT`
   - `Back.Out` = `TRANS_BACK, EASE_OUT`. Godot's overshoot is fixed at 1.70158. Where a spec says `Back.Out(s)` with another
     `s`, use `PropertyTweener.set_custom_interpolator`.
   - `Back.In` = `TRANS_BACK, EASE_IN`
   - `Sine.InOut` = `TRANS_SINE, EASE_IN_OUT`
   - `Linear` = `TRANS_LINEAR`. It is used only for progress bars, timers and constant-speed traversal the player must
     predict (the Suitcase).
   - `Stepped(n)`: Godot has no stepped transition. Tween the value linearly and floor it to n steps in the setter.
     **Never** use yoyo on it.
4. **Sprite events.** A marker fires from `AnimatedSprite2D.frame_changed` when `frame == marker`, and state exits fire
   from `animation_finished`. Never sample progress in `_process`, and never use `create_timer` for a strip's own beats
   (runtime-animation-wiring DOG).
5. **Reduced motion.** Every entry is marked `keep`, `reduce` or `disable`:
   - `settings.reducedMotion` is the OS `prefers-reduced-motion` value or the in-game toggle (UX §7.2: "בלי טיקר רץ,
     בלי רעידות, בלי קפיצות").
   - It changes **parameters inside states, never the routing**, so a graph traced with RM on reaches the same states.
   - Screen shake is **0**, and the ticker is **paged**.
   - No flash is faster than 3 Hz, anywhere.
6. **Scene time.** All motion timers run on scene time and pause while the page is hidden. Resuming continues the same
   state at the same frame. No transition fires on `visibilitychange`.
