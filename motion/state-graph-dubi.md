# state-graph-spec: Dubi, the spokes-parrot ("דובי")

**Owner:** Animator. **Consumers:**
- the orchestrator and Technical Artist, who render the strips (see [`render-requests.md`](render-requests.md));
- the Game Developer, for wiring;
- the Audio Director, who owns the `dubiSquawk`, `dubiBlip` and `dubiFlash` cues (`audio/od/cue-spec.md` §4).

**Runtime:** `godot-animatedsprite2d`, cuts only. Global rules are in [`README.md`](README.md).

**Dubi only repeats** (pitch §2.12). His motion is a news anchor's: perched, still, and loud only when he is fed a line.
He moves in exactly three situations:
- the FTUE demonstration (UX `ftue.md` P0 F1: he flies in and pecks the hat);
- the buy nudge (P1 F1: he hops onto the card);
- his hop from the stage to the ticker on the first tap.

Everything else happens on his **ticker perch**.

## 1. Strips (render requests)

**Two figures.** Both come from the ChatGPT refs in `asset-requests/REQUESTS.md`: the `dubi` row and the `dubi-mic` row.

| Figure | Render height | Where | Why this size |
|---|---|---|---|
| **`dubi`** (small, full body) | **18 art px** tall, drawn at ×4 (`artScale`) = 72 logical | Ticker anchor, stage (the hat, the cards) | UX rtl-map §5 boxes him at 16×16 ×4 in the 84-px ticker row. At 16 px the suit, tie and beak collapse into a blob, while 18 px keeps a 2-ap beak that can open and still clears the row (72 ≤ 84). **UX: please widen the box to about 20×18.** |
| **`dubi-mic`** (large, second pose) | **96** tall, like the cast | The O3b Dubi flash card | The news-frame close-up |

**Conventions for both:**
- He **faces screen-left**: on the ticker he looks along the crawl toward the stage. The engine uses `flip_h` when he flies right.
- The anchor is the feet, bottom centre.
- **f0 of every action strip is pixel-identical to `idle.f0`**, and so is the last frame of every one-shot. This is the
  same seam rule as the cast. The engine enters each action at **f1**.
- The rig operations named in the recipes (`shift_above`, `rotate_region`, `squash`, `eyelids`) are the ones already in
  `art/showcase/src/rig.py`.
- The render needs these landmarks in `cast.py`:
  - the **beak hinge**, with a lower-mandible region;
  - the **wing** region and its shoulder pivot;
  - the neck and waist cuts;
  - the eyes.

```yaml
dubi:                       # 18 art px tall
  idle:   { frames: 16, fps: 8,  loop: true,  events: {},          recipe: "breath (waist cut) f4-f11; the parrot nod: neck cut -1 ap on f6-f7; blink f12-f13 (eyelids 0.5, 1.0); raised wing sways ±3° (sin, 1 cycle/loop)" }
  talk:   { frames: 2,  fps: 16, loop: false, events: {},          recipe: "f0 = idle.f0; f1 = lower mandible rotate_region +20° about the beak hinge (beak open ≈ 2 ap)", note: "NOT fps-driven: the engine sets the frame per dubiBlip (§3)" }
  squawk: { frames: 4,  fps: 12, loop: false, events: { squawk: 1 }, recipe: "f0 = idle.f0; f1 neck shift_above -1 ap + squash sx 0.96 sy 1.06 + beak +30° + wing +15° (the squawk); f2 beak +10°, sy 1.02; f3 = idle.f0" }
  fly:    { frames: 4,  fps: 12, loop: true,  events: { flap: 2 }, recipe: "whole body squash sx 1.04 sy 0.96 (lean into flight); wing rotate +35° (f0), +10° (f1), -30° (f2 downstroke), +10° (f3). f0 MUST equal land.f0" }
  land:   { frames: 3,  fps: 12, loop: false, events: { touch: 1 }, recipe: "f0 wing +35°, sy 1.05 (flare); f1 squash sx 1.08 sy 0.92, wing +10° (touch-down); f2 = idle.f0", note: "played backwards = takeoff (f2 → f1 → f0 → fly.f0, seamless)" }
  peck:   { frames: 6,  fps: 12, loop: false, events: { peck: 2 }, recipe: "f0 = idle.f0; f1 wind-up: neck shift +1 ap back, -1 ap up; f2 strike: neck shift -2 ap forward, +2 ap down; f3 = f2 + squash sx 1.04 sy 0.96 (contact); f4 halfway back; f5 = idle.f0" }
dubi_mic:                   # 96 art px tall (the O3b flash card)
  idle:   { frames: 20, fps: 10, loop: true,  events: {}, recipe: "the cast standard: breath, blink f9-f11, the mic hand sways ±3°" }
  talk:   { frames: 2,  fps: 16, loop: false, events: {}, recipe: "f0 = idle.f0 with the beak CLOSED (lower mandible rotated shut about the hinge; the ref's open beak becomes f1); f1 = the ref's open beak", note: "driven by dubiBlip like the small one" }
```

There are 35 small frames and 22 large ones.

**Durations from entry at f1:**
- `squawk`: 250 ms.
- `peck`: 417 ms, with the peck contact at +83 ms.
- `land`: 167 ms, with the touch at 0 ms (f1).
- Takeoff (f1 → f0): 167 ms.

---

## 2. Perches and flight

| Perch | Feet position | Tracks |
|---|---|---|
| `anchor` | The ticker's Dubi box (rtl-map §5.1, the right end, `Rect2(560, 0, 160, 84)`): feet at ticker-local (676, 80) | The ticker row. It moves with the ticker dock and is hidden when a tall tab hides the ticker. |
| `cta` | The same spot, on top of the "עוד סבב!" button's right end once it replaces the ticker | The button |
| `hat` | The Magician's **hat top**: `hatMouth.idle[frame] - (0, 2)`, in world space (sprites.json; state-graph-magician.md) | **Every frame.** He rides the idle sway (≤ 2 ap). |
| `card` | The top edge of the P1 source card, above the price pill (the pill is on the card's **left**, the trailing end in RTL) | The card's scroll position |
| `offRight` | x = 720 + 40 logical, at the destination's y | — |

**Flight:**
- The path is a quadratic Bezier:
  - `p0` = the current feet position;
  - `p2` = the destination perch;
  - the control point is `((p0.x + p2.x) / 2, min(p0.y, p2.y) - 160)`.
- **Duration:** `clamp(distance_px / 1.2, 350, 800)` ms, with `Quad.InOut` on the path parameter (a traversal between two
  rests), snapped to 4.
- `flip_h = p2.x > p0.x`.
- The fly strip loops throughout.
- Dubi has **no hit area**, so he never steals a tap from the hat or a card.

---

## 3. Speech (the audio drives the beak)

**Squawk.** On the frame the engine plays `dubiSquawk`, the body enters `squawk.f1`:
- `up` before a ticker headline;
- `down` before a canned line or a flash.

**Babble.** On each `dubiBlip` onset, set `talk.f1`. Hold it 60 ms, then set `talk.f0` until the next blip.
- The AD's babble is 8 blips a second and is capped at 1.6 s. That gives a 60/65 ms open/closed flap.
- When the speech ends, cut to `idle.f0`. The speech bubble motion is `dubi-squawk-bubble` in `motion-spec.yaml`, and
  it is anchored to the same `dubiSquawk` event.

**No speech in flight.** The AD's voice queue holds a line until he is perched. Motion adds nothing.

**The first tap.** The AD plays `motif` *instead of* `tap` on the first tap, and Dubi's "אין כלום! אין כלום!" starts
when the motif ends. That is 4138 ms in D (cue-spec §2.6).
- UX's first-minute beat wants the squawk *as the coins spray* (Laugh 1).
- Motion follows the cue event, whichever way UX and the Audio Director settle it. That seam is flagged to both in
  STATUS.

---

## 4. The graph

```yaml
graph:
  id: dubi
  runtime: godot-animatedsprite2d
  default_state: hidden
  context: { perch: "anchor | hat | card | cta", dest: "a perch or offRight" }
  composite_states:
    - id: perched
      children: [idle, squawk, talk, peck]
      default_child: idle
      inherited_transitions:
        - { to: takeoff, on: goTo,    type: cut, note: "dest set; any speech in progress finishes first (the AD queue): goTo waits for speechEnd" }
        - { to: takeoff, on: startle, type: cut, note: "immediate, even mid-speech (the speech is cut; only the first-tap startle uses it)" }
        - { to: perched, on: cover,   type: cut, note: "the perch is covered (a tall tab or modal): cut to perch = anchor (visible with the ticker)" }
  states:
    - { id: hidden,  animation_key: dubi.idle@f0, loop: false, interrupt_priority: low, on_entry: [ { visible: false } ] }
    - { id: idle,    animation_key: dubi.idle,  loop: true,  interrupt_priority: low, on_entry: [ { frame: "0 on the ticker; randi() % 16 elsewhere" } ], note: "on the ticker: between loops, hold f0 for U(0, 3000) ms (a peripheral element, so the 2 s loop never metronomes)" }
    - { id: squawk,  animation_key: dubi.squawk, loop: false, interrupt_priority: medium, on_entry: [ { frame: 1 } ], markers: { squawk: 1 } }
    - { id: talk,    animation_key: dubi.talk,  loop: false, interrupt_priority: medium, note: "frames set by dubiBlip" }
    - { id: peck,    animation_key: dubi.peck,  loop: false, interrupt_priority: medium, on_entry: [ { frame: 1 } ], markers: { peck: 2 } }
    - { id: takeoff, animation_key: dubi.land (reversed from f1), loop: false, interrupt_priority: high }
    - { id: flying,  animation_key: dubi.fly,   loop: true,  interrupt_priority: high, on_entry: [ { tween: "Bezier to dest (§2)" } ] }
    - { id: landing, animation_key: dubi.land,  loop: false, interrupt_priority: high, on_entry: [ { frame: 0 } ], markers: { touch: 1 } }
  transitions:
    - { from: hidden,  to: flying,  on: enterFrom,  type: cut, note: "starts at offRight, fly strip" }
    - { from: hidden,  to: idle,    on: showAnchor, type: cut, note: "rides in with the ticker dock" }
    - { from: idle,    to: squawk,  on: dubiSquawk, type: cut }
    - { from: squawk,  to: talk,    on: dubiBlip,   type: cut }
    - { from: squawk,  to: idle,    on: animEnd,    type: cut, note: "a squawk with no babble after it" }
    - { from: talk,    to: talk,    on: dubiBlip,   type: cut, note: "f1 for 60 ms, then f0" }
    - { from: talk,    to: idle,    on: speechEnd,  type: cut }
    - { from: idle,    to: peck,    on: peckCue,    type: cut, condition: "perch == hat" }
    - { from: peck,    to: idle,    on: animEnd,    type: cut }
    - { from: takeoff, to: flying,  on: animEnd,    type: cut }
    - { from: flying,  to: landing, on: arrived,    type: cut, condition: "dest != offRight" }
    - { from: flying,  to: hidden,  on: arrived,    type: cut, condition: "dest == offRight" }
    - { from: landing, to: idle,    on: animEnd,    type: cut, note: "perch = dest" }
    - { from: [flying, takeoff, landing], to: perched, on: cover, type: cut, note: "cut to the anchor perch (idle)" }
    - { from: any,     to: hidden,  on: tickerHidden, type: cut, condition: "perch in [anchor, cta]" }
    - { from: hidden,  to: idle,    on: tickerShown,  type: cut, condition: "perch in [anchor, cta]" }
```

| state \ event | goTo | startle | dubiSquawk | dubiBlip | speechEnd | peckCue | animEnd | arrived | cover | tickerHidden / Shown |
|---|---|---|---|---|---|---|---|---|---|---|
| hidden | ignore | ignore | ignore (the AD holds it) | ignore | ignore | ignore | n/a | n/a | ignore | → idle on Shown (anchor perch) |
| idle | → takeoff | → takeoff | → squawk | → talk | ignore | → peck (hat only) | n/a (loop) | n/a | → anchor | → hidden (anchor perch) |
| squawk | wait for speechEnd | → takeoff | ignore | → talk | → idle | ignore | → idle | n/a | → anchor | → hidden |
| talk | wait for speechEnd | → takeoff | ignore | f1 60 ms | → idle | ignore | n/a | n/a | → anchor | → hidden |
| peck | after animEnd | → takeoff | wait (queued) | ignore | ignore | ignore | → idle | n/a | → anchor | ignore (not on the ticker) |
| takeoff | ignore | ignore | ignore | ignore | ignore | ignore | → flying | n/a | → anchor | ignore |
| flying | retarget (a new Bezier from the current position) | ignore | ignore | ignore | ignore | ignore | n/a (loop) | → landing / hidden | → anchor | ignore |
| landing | queue | ignore | ignore | ignore | ignore | ignore | → idle | n/a | → anchor | ignore |

---

## 5. The FTUE beats (UX `ftue.md`)

| Beat | Sequence |
|---|---|
| **P0 F1** (title state, idle ≥ 3 s; the ticker does not exist yet) | 1. `enterFrom` off-right at hat height, then fly to `hat` (≈ 600 ms), then land (167).<br>2. At +200, `peckCue` fires. At `peck: 2` a **demo coin** pops from `hatMouth`: it rises 8 ap (200 ms Quad.Out), then arcs 16 ap down and right (300 ms Quad.In), with a "+1 ₪" floater in the muted demo colour. It is **not credited** and the counter does not move.<br>3. A second peck follows 600 ms later.<br>4. He stays perched, pecking again every 5000 ms while P0 lasts. The F2 hand appears beside him. |
| **First tap** (H1) | **If Dubi is on the hat:** the tap's f0 sends `startle` → takeoff (167) → fly to the anchor's **docked** position (the ticker docks at +150-400, `title-to-play`). He lands around +700. **If he was not on stage:** `showAnchor`, and he rides in on the ticker dock. Then the "אין כלום!" squawk and babble, on the AD's cue. |
| **P1 F1** (the buy nudge) | 1. `goTo(card)`, land, squawk plus "לקנות! לקנות!" (canned contour).<br>2. He stays perched on the card, tracking it.<br>3. At the buy commit (or when P1 retires): `goTo(anchor)`. |
| **E1 fallback**, **the miss follow-up**, **the aide drop**, **ticker headlines** | Speech at the current perch (`anchor` / `cta`), with no flight. |
| **O3b Dubi flash** | `dubi_mic` on the card: idle, plus talk from the `dubiFlash` stinger's babble or blips. The small Dubi stays on the ticker under the backdrop. |
| **Court day, election** | He stays on the ticker perch. When the election curtain covers him, `cover` has no effect, because he is already on `anchor`. |

**Reduced motion** (UX `ftue.md`: "Dubi flies → appears"):
- Every flight becomes a 120 ms fade-out at the origin, then a 120 ms fade-in at the destination. There is no takeoff or
  landing.
- Pecks, squawks and talk are **kept**, because they are in place and the peck *is* the demonstration.
- The demo coin rises straight 6 ap and fades, with no arc.
- The ticker idle is kept (1 ap, peripheral).

**Audio.**
- The motion is driven by `dubiSquawk`, `dubiBlip` and `dubiFlash`.
- Proposed, and not in the AD's cue list: the demo coin could play `coin` (variant `a`), or nothing, because it is not
  a payout. The AD decides.
- `flap` and `touch` are `null`.
