# Render requests from motion (for the orchestrator's render-down rig and the TA's pipeline)

**Owner:** Animator. **For:** the orchestrator (`art/showcase/src/build.py` + `cast.py`) and the Technical Artist
(`pipeline/od-sevev/`, `sprites.json`).

These are the strips and landmarks that motion needs and that do not exist yet. Each row gives:
- frames and fps;
- loop;
- `events` (atlas key: frame);
- the rig recipe (operations already in `rig.py`).

**Conventions for every strip:**
- **f0 = the rest pose** = `idle.f0`, pixel for pixel. The last frame of every one-shot returns to it too. The engine
  enters actions at f1 (the seam rule measured on the approved cast).
- The anchor is the feet, bottom centre.
- **No frame may touch the frame edge.** The TA's build check applies.

## A. Dubi (full specs: [`state-graph-dubi.md`](state-graph-dubi.md) §1)

| Strip | Size | Frames @ fps | Loop | Events | Recipe |
|---|---|---|---|---|---|
| `dubi.idle` | 18 tall | 16 @ 8 | yes | — | breath f4-f11; neck −1 ap on f6-f7 (the nod); blink f12-f13; raised wing sways ±3° |
| `dubi.talk` | 18 | 2 @ 16 | no | — | f1 = lower mandible +20° about the beak hinge |
| `dubi.squawk` | 18 | 4 @ 12 | no | `squawk: 1` | f1 neck −1 ap, sy 1.06, beak +30°, wing +15°; f2 beak +10°; f3 = rest |
| `dubi.fly` | 18 | 4 @ 12 | yes | `flap: 2` | sx 1.04 sy 0.96; wing +35°, +10°, −30°, +10°. **f0 = land.f0** |
| `dubi.land` | 18 | 3 @ 12 | no | `touch: 1` | f0 wing +35° sy 1.05; f1 sx 1.08 sy 0.92 wing +10°; f2 = rest (reversed = takeoff) |
| `dubi.peck` | 18 | 6 @ 12 | no | `peck: 2` | f1 neck +1 back −1 up; f2 −2 forward +2 down; f3 = f2 + sx 1.04 sy 0.96; f4 halfway; f5 = rest |
| `dubi_mic.idle` | 96 | 20 @ 10 | yes | — | the cast standard (breath, blink f9-f11, mic hand ±3°) |
| `dubi_mic.talk` | 96 | 2 @ 16 | no | — | f0 = beak **closed** (mandible rotated shut); f1 = the ref's open beak |

**Landmarks needed in `cast.py`** for both figures:
- the beak hinge, with the lower-mandible region;
- the wing region, with its shoulder pivot;
- the neck and waist cuts;
- the eyes.

**Facing:** screen-left.

## B. The Magician: the sweat (full spec: [`state-graph-magician.md`](state-graph-magician.md) §8)

| Asset | Spec |
|---|---|
| `prop_sweat` | 3×4 ap, **2 frames**: f0 a round bead, f1 stretched while falling. Light blue, 1 white highlight px, a 1-ap dark outline. It is hand-drawn, a 2D Artist prop. |
| `temple` landmark | Per frame for `bibi.idle`, `tap` and `crit`, in `sprites.json` next to `hatMouth`. It is the first transparent px outside the head outline on the **screen-right** side, level with the top of the screen-right eye. |

**No new Magician strips** are needed for court day or the celebration. They are built from `tap` and `crit` frames
plus transforms (state-graph-magician §5).

## C. The 8 money sources, 40 tall (full spec: [`diorama-motion.md`](diorama-motion.md) §1)

| Strip | Frames | f1 recipe | Landmark to add in `cast.py` |
|---|---|---|---|
| `taxpayer.idle` | 2 | `shift_above(waist, +1)` + head +1 + `eyelids 0.5` (the sigh) | waist, neck, eyes; **`hand`** (the lob origin) |
| `hitech.idle` | 2 | hands/laptop region +1 ap down + screen glint px | the hands/laptop box; the screen px |
| `vat.idle` | 2 | the tag region `rotate_region` +8° about its string | the tag box + pivot |
| `cigars.idle` | 2 | smoke-wisp px −1 ap; champagne bubble px on | the wisp box; the bubble px |
| `submarine.idle` | 2 | hull `shift_above(waterline, +1)`, periscope held level | the waterline cut; the periscope box |
| `qatari.idle` | 2 | pupils 1 ap sideways + phone hand +1 ap | the eyes; the hand box |
| `poison.idle` | 2 | the LED rows' lit px alternate | the LED rows box |
| `washington.idle` | 2 | 2-px glint on the gold edge + page corner +1 ap | the edge px; the corner box |

**Fps and loop:** 2 frames, loop, and **no fps in the atlas**. The period is `producers[].idleFrameMs` (700 / 300 / 600 /
500 / 800 / 1000 / 400 / 700), which the engine reads.

**Fallback per source:** the bob (`shift_above(waist, +1)`) whenever a landmark is missing.

**No walk strip for the taxpayer.** The walk-on is transform plus idle toggle (`diorama-motion.md` §3).

## D. Already delivered (no action)

- `prop_hat_glow`
- `ballotConfetti`, `dustPuff`, `inkSpecks`
- Bibi padded to 81 wide
- exact `hatMouth` tables
- `avatar24_<char>`
