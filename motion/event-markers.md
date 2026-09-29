# event-markers (`hit-frame-data`): "עוד סבב"

**Owner:** Animator. **Consumers:** Audio Director (cue alignment) and Game Developer (event wiring).

**Status: RECONCILED (wave 2) against the Audio Director's od-sevev cue list.**
- **The list checked:** `audio/od/cue-spec.md`, `audio/od/cues.json` (the recipes, with every layer's `delay`) and
  `game/assets/audio/od/od_manifest.json` (the stinger lengths). All three are dated 2026-09-28.
- **Not yet logged:** the Audio Director has not posted a STATUS.md log line for it yet. If the recipes change, re-run
  §6.
- **Cue ids below are the AD's.**
  - `CONFIRMED`: a motion beat that already sat on the audio onset.
  - `RETIMED`: motion moved to the audio. Audio is the anchor wherever the two meet.
  - `OPEN`: needs an AD answer.
  - `null (unassigned)`: a motion beat the AD's list has no cue for. The engine ignores the event until `cues.json` names
    one.

## Conventions

- **f0** is the frame the trigger is processed on:
  - pointer-down for the Magician, the hat and the Suitcase;
  - pointer-up inside bounds for a button commit;
  - a state edge for everything else.
- Times are ms from f0 at the 60 Hz reference.
- **Strip markers** are atlas frame indices. Every action strip is **entered at f1**, so a marker at frame `m` fires
  `(m − 1) × 1000 / fps` ms after entry.
  - The dev fires them from `AnimatedSprite2D.frame_changed`, never from a timer.
- **SFX `play()` goes out on the trigger frame** (AD cue-spec §1, A14). The web output buffer adds about 50 ms on top,
  so tap feel comes from the squash on the same frame.
- **Where a motion beat is placed on an onset *inside* a cue**, the onset is the recipe's layer `delay` in `cues.json`.
  - These are the Suitcase catch, the ultimatum's zero, the transfer whistle and the gavel.
  - If the AD changes a `delay`, the matching motion beat moves with it.

---

## 1. The Magician (`state-graph-magician.md`)

```yaml
sequence: firstTap                   # the first registered tap ever (audio unlock)
events:
  - { t: 0, cue: "motif (stinger, INSTEAD of tap; D 4138 ms)", status: CONFIRMED, motion: "tap.f1 + coins at +133; title-to-play" }
  - { t: "motif end", cue: "dubiSquawk down + dubiBlip babble ('אין כלום! אין כלום!', canned contour doubled)", status: "OPEN (seam UX ↔ AD: UX first-minute puts the squawk at f0 'as the coins spray'; the AD after the motif). Motion is anchored to the dubiSquawk event either way", motion: "Dubi squawk strip + bubble" }
```

```yaml
sequence: tap                        # every later registered tap; dropped (over-cap) taps have no marker at all
events:
  - { t: 0,   cue: "tap (walk and wrap s<n>, d25/d12 alternate; poly 4, steal oldest)", status: CONFIRMED, motion: "tap.f1 on the input frame", dev: "award; counter snap; tap-floater" }
  - { t: 133, strip_frame: "tap.3 (coins)", cue: "null (the AD's 'coin' is scoped to the settings preview and explicit payout bursts)", motion: "coin-burst min(3 + batch − 1, 6) at hatMouth.tap[3]" }
batching: "the body batches taps (state graph §1.2); the tap cue fires on EVERY registered tap's f0. Poly 4 with steal-oldest covers 16 taps/s"
```

```yaml
sequence: tapCrit                    # includes the scripted tap-7 rabbit (×4)
events:
  - { t: 0,   cue: "tap", status: "OPEN (recommended: the crit's f0 still plays tap, so the hijaz walk never skips a step; the AD's table doesn't say)", motion: "crit.f1 on the input frame; crit-floater" }
  - { t: 167, strip_frame: "crit.3 (coins)", cue: null, motion: "crit coin burst; the rabbit's ears first show" }
  - { t: 250, strip_frame: "crit.4 (rabbit)", cue: "rabbitCrit (round-robin s120 → s150 → s180; priority 5, never stolen)", status: "RETIMED: fire it on the rabbit marker, not the tap. Its boing (0-200) spans the pop-out; the 16th-note head (s120: +250/+325/+400 → 500-680 after entry) lands inside the wink hold (f5-f9 = 333-750)" }
  - { t: 333, strip_frame: "crit.5 (sting)", cue: null, motion: "the full wink. The engine already emits 'sting' on f5 (dev STATUS); it stays unassigned, because rabbitCrit covers it" }
reduced_motion: "RM clip (crit.f1 → cut to f7 at +83): rabbitCrit moves to +83"
```

```yaml
sequence: hatTap / hatHush / hatCrit # court day: the hat alone on stage; every keyed cue uses the G files
events:
  - { t: 0,  cue: "tap (G)", status: CONFIRMED, only: "hatTap (courtPausesTaps = false)" }
  - { t: 0,  cue: "null (unassigned; proposed: tap's cloth 'fff' layer alone, i.e. a variant with no blip)", only: "hatHush (courtPausesTaps = true)" }
  - { t: 0,  cue: "rabbitCrit (G)", only: "hatCrit: the rabbit starts rising at f0" }
```

```yaml
sequence: courtSummons / courtExit   # f0 = the court card opening
events:
  - { t: 0,    cue: "gavel (a/b/c; knocks at 0 and 180 ms per cues.json)", status: CONFIRMED, motion: "summons: the flinch (land from tap.f1). Straight into testimony: exitStartle tap.f1" }
  - { t: 180,  cue: "(gavel's 2nd knock)", status: CONFIRMED, motion: "tap.f2 stretch + lean; card jolt" }
  - { t: "next bar line", cue: "courtIn stinger (G) + the 400 ms crossfade to the Courthouse track, L2 forced off", status: "CONFIRMED (not frame-synced: motion never waits for a bar)" }
  - { t: 330,  cue: "null (unassigned; proposed zip whoosh, NOI-S, no glide over 200 ms)", motion: "the zip starts; dust" }
  - { t: 780,  cue: null, motion: "the hat zips in" }
note: "courtStart that comes AFTER a summons (testimony begins later) plays no gavel: the startle is silent"
```

```yaml
sequence: courtReturn                # f0 = courtEnd
events:
  - { t: 0,   cue: "postponed: gavelWeak is on this same frame (the 'נדחה' stamp impact). testified: null", status: CONFIRMED, motion: "the hat zips out" }
  - { t: "next bar line", cue: "courtOut (in the key returned to) + the crossfade back", status: CONFIRMED }
  - { t: 300, cue: "null (unassigned: zip whoosh)", motion: "the Magician zips in" }
  - { t: 520, cue: "null (unassigned: land thud)", motion: "tap.f1 squash + dust" }
```

```yaml
sequence: sweat
events: [ { t: "each drop", cue: "null by design (a visual-only echo; suspicion has no sound in the AD's list)" } ]
```

---

## 2. Dubi (`state-graph-dubi.md`)

| Beat | Cue | Status |
|---|---|---|
| `squawk.f1` entered on the cue frame | `dubiSquawk` (`up` before a headline, `down` before a canned line or flash; 85 ms chirp) | CONFIRMED: the strip is driven by the cue |
| `talk.f1` for 60 ms on each blip | `dubiBlip` (8/s, capped at 1.6 s, degree × octave) | CONFIRMED |
| Dubi flash card talk | `dubiFlash` stinger (2069 ms in D) + blips | CONFIRMED |
| `peck: 2` (the demo coin pops) | proposed `coin` `a`, or `null` (it is not a payout) | OPEN |
| `flap: 2`, `touch: 1` | `null` | by design |
| Chat pings while Dubi speaks | the AD queues `chatPing` until 300 ms after Dubi stops | CONFIRMED (motion adds nothing) |

---

## 3. The cast (`state-graph-cast.md`; ms from the action's f1 entry)

| Figure / strip | Marker (frame → ms) | Motion beat | Cue |
|---|---|---|---|
| Ben Gvir, Gotliv: `react` (jab) @14 | `shout: 2` → 71 | The arm jab | `null` (unassigned). Their voice is the per-partner `chatPing` variant. |
| Levin: `react` (bang) @14 | `bang: 4` → 214, `bang2: 8` → 500 | The fist comes down | `null` (unassigned) |
| Deri, Goldknopf, Regev: `react` (hop) @14 | `land: 6` → 357 | Feet land | `null` |
| Sara: `offended` @12 | `huff: 2` → 83 (233 after the S01 commit) | The huff | `null` (unassigned) |
| Bennett: `flip` @12, forward or reverse | `whoosh: 3` → 167 forward, 250 reverse; textSwap → 250 | The turn | `null` (unassigned) |
| Money sources (`diorama-motion.md`) | the taxpayer's lob arrival | Coin into the hat | proposed `coin`, or `null` (OPEN) |

---

## 4. Chat (`motion-spec.yaml`)

```yaml
sequence: partnerMessage
events:
  - { t: -1200, cue: null, motion: "typing telegraph" }
  - { t: "landing (+180) with the chat open / chat-toast enter f0 with it closed", cue: "chatPing (variant = partner id: benGvir's is 3 notes at 0/75/150; others 2 at 0/75; ≤ 1 per 700 ms, 'burst' coalesces)", status: CONFIRMED }
```

```yaml
sequence: pay                        # f0 = pill commit
events:
  - { t: 90,  cue: "OPEN: the AD's list has no cue for paying a partner ('stamp' is Herzog's desk; 'buy' is sources and spins). Proposed: 'stamp' (its thump is at its 0 ms = our impact)", motion: "'שולם' impact; pips launch" }
  - { t: 790, cue: "null (unassigned: seats gain)", motion: "the last pip lands" }
```

```yaml
sequence: ultimatum
events:
  - { t: "each displayed second", cue: "ultimatumTick (tick/tock alternate; no duck)", status: CONFIRMED, motion: "≤ 10 s: pill nudge on the SAME tick event" }
  - { t: "last 3 s, twice per second", cue: "ultimatumTick ×2 rate, L2 forced off", status: CONFIRMED, motion: "2 Hz nudge + hatch march" }
  - { t: 0,   cue: "ultimatumZero: deflate 0-200 ms", status: "RETIMED", motion: "the bubble sags in 2 steps (0, 100)" }
  - { t: 320, cue: "(ultimatumZero's 'left' ping, 320 and 395)", status: "RETIMED (was +250)", motion: "the system line LANDS here (its arrival starts at 140)" }
  - { t: 510, cue: "(ultimatumZero's door click)", status: "RETIMED", motion: "avatars grey; header count rolls; seats un-fill; partner-body leaves" }
```

```yaml
sequence: transferWindow            # AUDIO-ANCHORED to transferWhistle's layers (every variant): 0 / 160 / 320 (long note to 720)
events:
  - { t: 0,   cue: "transferWhistle (w26 / w28 / w30 random)", status: CONFIRMED, motion: "black strip enters" }
  - { t: 160, cue: "(2nd short)", status: "RETIMED (was 180)", motion: "gold title wipes in" }
  - { t: 320, cue: "(the long note)", status: "RETIMED (was 360)", motion: "the name drops; Gotliv jabs (shout at +391)" }
```

```yaml
sequence: brawl
events: [ { t: 0, cue: "null (unassigned; the AD's list has no brawl cue. Any future one must obey the no-gunfire rule)" } ]
```

## 5. Court day, Herzog, rewards

| Sequence | t | Cue | Status |
|---|---|---|---|
| Postpone: the 'נדחה' stamp impact | +90 from commit | `gavelWeak` | CONFIRMED. The 'נדחה' slam lands on the weak gavel alone, because `stamp` belongs to Herzog. |
| Herzog's pardon desk stamp impact | +90 from each submit | `stamp` (`bell` on every 5th; otherwise identical) | CONFIRMED: the impact frame = the thump at 0 ms |
| Suitcase spawn | the entry frame | `suitcaseSpawn` (g25/g28/g31; panned at spawn) | CONFIRMED |
| Suitcase catch | f0 → **burst at +130** | `suitcaseCatch`: the reversed zipper 0/30/61, the "cha" at 130, the "ching" + tick at 200 | **RETIMED** (the burst was +120): it sits on the "cha" |
| Suitcase miss | the exit frame | `suitcaseMiss` | CONFIRMED |
| Coin flight arrivals | per coin | `coin` a/b alternate, **≤ 6 per event**: on arrivals 1, 3, 5, 7, 9, 10 | CONFIRMED against the deadpan rule and poly 3 |
| O1 return card | enter f0 | `returnAway` | CONFIRMED |
| Milestone headline | the flash f0 | `milestone` stinger | CONFIRMED |
| Buy (a source or spin) | commit f0 | `buy` | CONFIRMED |
| Refused buy | commit f0 | `cantAfford` | CONFIRMED |
| UI press | commit | `uiClick` | CONFIRMED |
| Receipt feed / tear; cottage pixel; election CTA unlock; opposition card enter | — | `null` (unassigned) | open to the AD, no motion change |

```yaml
sequence: electionCeremony          # AUDIO-ANCHORED to the fanfare stinger (od_manifest stingers.fanfare)
clock: "fanfareStart = the NEXT BAR LINE after the confirm (AD cue-spec §2.4: the bed stops with a 30 ms fade, then the fanfare)"
derived_markers: "T0 = musicalSeconds(0 tags): D 4138, E 3636, F 3333, G 5455. rollEnd = T0/2; tagOnsets[i] = T0 + (i − 1)·T0/4; fanfareEnd = musicalSeconds(<tags>)"
events:
  - { t: "confirm",       cue: null, motion: "card exits; anticipate crouch (the wait for the bar line is absorbed here)" }
  - { t: 0,               cue: "fanfare (incoming key, <tags> file)", status: "CONFIRMED as the clock; OBJECTION O-M3 on WHEN it starts" }
  - { t: "rollEnd − 333", cue: null, motion: "crit.f1 (the trick)" }
  - { t: "rollEnd − 83",  cue: "null: NO rabbitCrit here; the fanfare is the sound", motion: "the rabbit" }
  - { t: "rollEnd",       cue: "(inside the fanfare: the motif head)", status: "RETIMED to the derived marker", motion: "IMPACT" }
  - { t: "tagOnsets[i]",  cue: "(the half-bar ta-da tags)", motion: "the round number hops" }
  - { t: "fanfareEnd",    cue: "(the incoming era starts at bar 1: the resolution)", motion: "the uncover completes; input unlocks" }
```

---

## 6. Checklist (the wave-2 run, and what stays open)

| # | Item | Result |
|---|---|---|
| 1 | Tap id; does a crit's f0 play `tap`? | `tap` CONFIRMED. The crit's f0 is **OPEN** (recommend yes). |
| 2 | `rabbitCrit` fires at `crit.rabbit` (+250) | RETIMED on the motion side. The AD's table says "a crit" without a frame, so **OPEN** until the AD acknowledges it. |
| 3 | The fanfare starts on the confirm and publishes markers | Markers: **derived** from the manifest, so no AD action is needed. Start: the AD bar-quantizes it, see **OBJECTION O-M3**. |
| 4 | The Suitcase catch zipper length | Resolved from the recipe: the burst is at +130. |
| 5 | The transfer whistle onsets | 0 / 160 / 320: RETIMED |
| 6 | The postponement impact | `gavelWeak` alone: CONFIRMED |
| 7 | The "proposed" cues | All `null (unassigned)` in the AD's list. Still offered: zip, land, seats gain, receipt feed and tear, cottage, CTA, Levin, Bennett, brawl, Dubi's peck, the taxpayer's lob, the pay commit (**OPEN**: paying a partner has no sound at all today). |
| 8 | Polyphony at 16 taps/s | `tap` poly 4, steal oldest: CONFIRMED |
| 9 | New in the AD list | `motif` on the first tap (the Dubi squawk seam is **OPEN**, UX ↔ AD); `courtIn`/`courtOut` on bar lines (no motion sync needed); `returnAway`, `milestone` |
