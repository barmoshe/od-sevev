# diorama motion: the 8 money sources (idles, set pieces, the taxpayer's walk-on)

**Owner:** Animator. **Consumers:**
- the orchestrator and Technical Artist, who render the strips (see [`render-requests.md`](render-requests.md));
- the Game Designer, who owns the values in `content.json` `producers[]`;
- the Game Developer (`game/scripts/ui/diorama.gd`).

Global rules are in [`README.md`](README.md).

**Size:** 40 art px tall (the TA's objection, accepted), drawn at ×4 (`artScale`). The front-row pitch is 20 ap.

**Engine contract (STATUS, "engine content fields"):**
- `idleFrameMs`: a 2-frame idle with equal holds;
- `wander`;
- `setPiece`: one of `lob`, `launch`, `blink`, `bob`, `absent`.

## 1. The 2-frame idle: the answer per source

**Rules for every source:**
- **f0 is the rest pose.** It is also the shop-icon and silhouette crop.
- **f1 differs from f0 by 1-2 ap only.** It reads as *alive*, not as *moving*. With up to 24 instances on stage, bigger
  toggles turn the diorama into noise, and the Magician must stay the most-moving object on the stage (UX first-minute
  §2.2).
- **Every f1 is a single rig operation on the same ref.** No hand-drawn frame is needed. If a source's landmark is
  missing, its fallback is **bob**: `shift_above(waist, +1 ap)`, the breath.

| # | id | Kind | f1 = (the rig recipe) | Why it is this source's idle | `idleFrameMs` | `setPiece` | `wander` |
|---|---|---|---|---|---|---|---|
| 1 | `taxpayer` (משלם המסים) | **bob: the sigh** | body `shift_above(waist, +1 ap)` + head +1 ap + `eyelids 0.5` | "משלם, נאנח, משלם." (pays, sighs, pays). The slump *is* the character, drawn with sympathy. | 700 | **`lob`**, retargeted at the Magician's hat (§2) | false |
| 2 | `hitech` (ההייטקיסט) | **source-specific: typing** | hands/laptop region shifted +1 ap down + the screen's 1-px glint on | Funds half the country, laptop open. It stays on the work, never on leaving (deck note: the joke is the policy). | 300 | `absent` | false |
| 3 | `vat` (המע״מ) | **source-specific: the tag swings** | the "18%" tag region `rotate_region` +8° about its string (a 1-ap tip shift) | A price tag that hangs on everything | 600 | `absent` | false |
| 4 | `cigars` (החבר הנדיב) | **source-specific: smoke** | the cigar-smoke wisp pixels shifted −1 ap up; the champagne bubble px on | Cigars and pink champagne, the crate's two props | 500 | `absent` | false |
| 5 | `submarine` (הצוללת) | **bob: on the water** | hull `shift_above(waterline, +1 ap)` **with the periscope held level**, so it rises 1 ap relative to the hull | "The periscope sees everything": the boat bobs, the periscope doesn't | 800 | `bob` | false |
| 6 | `qatari` (היועצים הקטאריים) | **source-specific: the glance** | the pupils shifted 1 ap sideways + the phone hand +1 ap | The shifty adviser ("אתה לא מכיר אותו. עדיין.") | 1000 | **`blink`**: flickers and reappears. Now you see him, now you don't know him. | false |
| 7 | `poison` (מכונת הרעל) | **blink: lights** | the LED rows' lit pixels alternate (the odd rows lit in f0, the even rows in f1) | 10,000 accounts, one opinion: a machine humming | 400 (2.5 Hz, under the 3 Hz ceiling; a small area, not a luminance flash) | `absent` | false |
| 8 | `washington` (פנקס הצ׳קים הזהוב) | **source-specific: glint** | a 2-px glint on the gold edge + the top page corner lifted 1 ap | Gold that shines, signed with the thickest marker | 700 | `absent` | false |

**Per-instance desync.** It is required, because up to 3 copies per source (1st, 10th and 25th owned) plus 8 sources
would otherwise toggle in lockstep like a strobe.
- Each instance starts on a random frame.
- Its first toggle comes after `U(0, idleFrameMs)`.
- Its own period is `idleFrameMs × U(0.9, 1.1)`, fixed at spawn.

**Reduced motion:** frozen on f0 (the legacy critter rule, ux settings §4). Set pieces are off, and the walk-on is a
fade.

**Content hand-off:**
- The `idleFrameMs` / `setPiece` / `wander` values above go into `design/content.json` `producers[]`. The Game Designer
  owns that file, so this is a request, filed in STATUS.
- Every entry is `wander: false`. Hopping sources would fight the Magician for attention, and the fork's wander hops
  belonged to monkeys, not payers.

**Purchase plop (the 2nd and later instance of any source, and every non-taxpayer first).** Legacy object-motion §3 is
kept:
- the source drops in 32 logical px above its slot;
- it lands on **its own f1 for 100 ms** (the sigh, the typing crouch and so on double as the landing squash);
- 2 `dustPuff`s, then idle.

---

## 2. The `lob` set piece (taxpayer): passive income, shown on the stage

This is UX first-minute §2.3: "the passive income shows *on the stage* before any number does".

| Property | Spec |
|---|---|
| Who | Each taxpayer instance, every `U(8000, 14000)` ms. There is **at most one lob in flight at a time**, globally, and at most one per 3000 ms. |
| From | The taxpayer's `hand` landmark (render request). The fallback is frame top-centre + (−4, +12) ap. |
| To | The Magician's current `hatMouth` in world space, **re-read every frame**, so the coin homes onto a moving hat. During court day the target is the **hat prop's** mouth. It works the same, because the hat keeps earning. |
| Path | x Linear. y is a parabola with its apex 16 ap above `max(start, target)`. 550 ms. Snap 4. The coin spins `coin0..3` at 16 fps. |
| Into the hat | For its last 100 ms the coin is drawn **behind** the Magician (or the hat prop), so it drops *into* the hat. |
| Arrival | One `prop_spark` frame at the mouth for 67 ms. **Nothing is credited:** income accrues continuously anyway, and this is its picture. |
| Suppressed | While the body is in `anticipate`, `trick` or `bow` (the election); while the stage is covered; and under reduced motion. |
| Audio | Proposed: `coin` variant `b` at arrival, or `null`. It is not in the AD's list. |

---

## 3. The taxpayer's walk-on (FTUE beat R1: the first money source ever bought)

**f0** = the commit of the first `taxpayer` purchase (`owned_total` 0 → 1).
- This instance does **not** plop.
- There is no walk cycle: the walk is a transform plus the source's own 2-frame idle toggled at the **step** cadence,
  with a 1-ap step-bob. The result reads as a weary trudge, which is in character ("pays, sighs, pays").

**Geometry, in stage art px** (sprites.json: `magicianFeet` (94, 219), Magician frame 81 wide):
- **start:** x 192, which is fully off the stage's right edge. RTL entry: a Hebrew reader's eye starts right.
- **stopMark:** x 150, on the Magician's floor line (y 219). That is clear of his body and inside the stage.
- The taxpayer's sprite faces left (toward the Magician). The engine flips it when he walks right.

| t (ms) | Motion | Notes |
|---|---|---|
| 0 | appears at start (fully off-screen) | — |
| 0-1400 | **walk:** x 192 → 150, Linear, 30 ap/s. **Steps every 175 ms (8 steps):** each step toggles f0/f1, and on the f0 steps y is −1 ap (Stepped). Snap 4. | A constant pace, because the eye reads a trudge from a steady cadence |
| 1400 | stops on **f1 (the sigh)**, held 350 ms | The beat before paying |
| 1750 | back to f0; **the coin toss:** a `lob` (§2) from his hand to the hat | The first coin into the hat |
| 2300 | the coin lands: spark at `hatMouth` | UX's "drops coins into the hat" |
| 2300-… | he walks to his diorama slot at the same pace and cadence (duration = distance / 30 ap/s, minimum 300 ms), flipping if the slot is to his right | If his slot *is* the stopMark, skip this |
| arrival | the 2-frame idle (desynced as §1) | The scene has visibly filled |

**Interrupts:**
- Taps keep registering, and he is not a tap target.
- A second taxpayer bought during the walk-on plops at its own slot.
- A tall tab or overlay covering the stage cuts him straight to his slot, idle, and the pending coin is dropped.

**Reduced motion:** he fades in at his slot (150 ms). The coin appears at `hatMouth` as a coin peek: it rises 5 ap and
sinks (250 ms total), with no arc.

**Audio:** the steps are `null`. At the coin's arrival, proposed `coin` (variant `a`), or `null`. This is flagged to the
AD.
