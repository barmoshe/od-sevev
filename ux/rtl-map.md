# "עוד סבב": RTL map of the fork's views (`localization-layout-spec` + `hud-layout`, engine-concrete)

**Owner:** UX Designer · **Consumers:** Game Developer (implements from this), 2D Artist (kit fit), Animator (motion directions and placements) · **Date:** 2026-09-28 · **Rev 2:** resolves the 2D Artist's flags F1-F5 (`art/od-sevev/style-guide.md` §16) and the Animator's crawl objection and placement questions (`motion/state-graph-cast.md`); see §12. **Rev 3 (2026-09-29, build review `ux/review-2026-09-29.md`):** §0.2 large-text step-down, §4 toast box + chat toast + Dubi's bubble, §5.1 the engine's anchor ratified, §6.1 S08/S10, §6.3 partner rows + ceremony, §6.4 court phases + depth, §7.1 scrim + history, §9 About; D20-D25. **Rev 4 (2026-09-29, leader select: `design/leader-select-spec.md`, Bar's decisions in `STATUS.md`):** §8 is now `LEADER_PICK`, which replaces the title state; §4.3 per-leader stage and HUD; §5.1 the press chip; §6.3 Liberman's pill and the T4 leader rows; §6.4 the press card; §7.2 the leader card; D26-D35.

**Above this file:** `gamestudio/output/artifacts/creative-pack/od-sevev/ux/first-minute.md` (approved). This file restates its §1, §3, §4, §7 on the fork's real node tree, the 720-logical canvas and the 2D Artist's kit (`art/od-sevev/ui-kit.json`). Where they disagree on a number, this file wins (it is the engine-concrete one); every deviation is in §12.

**Supersedes** the fork's `ux/hud-layout.md` and the layout parts of `screen-graph.md` and `settings-and-a11y.md`.

---

## 0. Units, grid, text

| Rule | Value |
|---|---|
| Design canvas | 720 logical px wide (`L.W`), aspect `expand`, every value on the 4-px grid |
| **Art grid** | **1 art px = 4 logical px** (the kit's 180×320 grid). Kit piece sizes below are given as `art` and converted ×4. |
| CSS → logical | ×(720 / viewport CSS width): ×1.846 at 390 wide, ×2.0 at 360 wide |
| **Touch-target floor** | **88 logical** (22 art) both axes = 44 CSS at the narrowest width (360). Hit areas are not art: a visual may be smaller than its hit. |
| **Widths** | Every budget is measured with the shipping font `game/assets/fonts/sevev9.fnt` (the sum of its `xadvance` values, as TextServer does; ₪ is 8 wide) against the formatters' real extremes (`worstCasePlaceholders`: "8.88mm" for costs and rates, "8.888mm" for totals, "8,888,888" on the receipt). `tools/lint_text.sh` and `ux/tools/gen_strings.py` agree. |
| **Text scale** | Pixel font `Sevev 5x9` at **×4**, on the art grid: cell 36 logical, glyph body 20 logical = **10.8 CSS** at 390. Line pitch 44 (40 in tight UI, the kit's "10 rows"). **Large-text mode = ×5** (a deliberate accessibility exception to the grid). Capacity at ×4: a full-width line holds ≈ 28 glyphs, a chat-bubble line ≈ 17. |
| Counter numerals | The Row A counter and the modal big numbers use a **7-row numeral cut** (digits . , + − K M B T ₪) at ×4: body 28 logical, 1.4× the Hebrew body, so the counter leads the hierarchy without leaving the grid (Technical Artist builds the cut; the fork's 5x7 digits are the base). |
| Hebrew route | `Label` / `RichTextLabel` with the bitmap `FontFile`, `text_direction = RTL`, `horizontal_alignment = RIGHT` unless the row says centre. TextServer does the bidi. |
| `PxText` route | Only strings with no Hebrew letters and no ₪ (`58/61`, `×14`, `0:45`, `27.10`). The 11 such keys are `surface: "pxtext"` in `string-budgets.json`. |
| Bidi in data | `ui-strings.json` is logical order with LRI…PDI already around numeric runs and U+00A0 before ₪. Code never adds, strips or pre-reorders. |

### 0.2 Large text: the step-down rule (2026-09-29, review R6)

Large text is ×5 **only where a string fits its box at ×5**. Every key whose `string-budgets.json` entry says `largeText: "step-down"` (57 today) is drawn per instance:

```
scale = 5 if large_text and lines_at(text, box.widthPx, 5) <= box.linesLarge else 4
```

measured on the **filled** string (the real price, name, timer), so a short price stays ×5 and a long one steps down. A step-down key is never ellipsised and never clipped. Rows that hold wrapping text (settings rows with captions, chat bubbles, the court card, modal bodies) grow to their measured line count at the scale actually drawn; nothing is positioned from a fixed row height when text can wrap. The ticker tag follows the same rule, so it stays ×4 (110 px at ×5 > its 88 box) and the crawl keeps its 324 px.

### 0.1 Mirroring (the fork's views are `Node2D` + absolute `Rect2`s from `L`, so mirroring is explicit data: `x' = 720 − x − w`)

| Category | Behaviour | Examples |
|---|---|---|
| `mirror` | Position and direction flip | Row reading order, bar fills, scrollbars, button order, crawl direction, card internals, switch ON side, keyboard ←/→ |
| `mirror-glyph` | Flip and swap the glyph | `→` becomes `←` (EVO_MULT, transfer line); `›` = back/collapse; `‹` = forward |
| `keep` | Never flip | Clocks and timers, the thermometer, gear, speaker, magnifier, gavel, lock, trash, coin, wordmark, every sprite of a person or prop |

Leading icons sit to the **right** of their label; trailing icons (lock after a title, status after a name) to the **left**.

---

## 1. Sections and vertical budget (`MainController._relayout`)

| Section | Node | Height | Flexible |
|---|---|---|---|
| Top inset | `_fills["top"]` (scrim) | `top_inset` | from `window.mbSafeArea` |
| **Row A** | `TopBar` (rebuilt) | **96** (24 art) | fixed |
| **Row B** | `TopBar.seats` | **84** (21 art) | fixed |
| **Stage** | `_stage` | `S` | **flex** |
| **Ticker** | `Ticker` in `_lower` | **84** | fixed |
| **Panel** | `Shop` list | `P` | **flex** |
| **Tabs** | `Shop` tab bar (moved to the bottom) | **104** (kit `tabbar` 26 art) | fixed |
| Bottom inset | `_fills["shop"]` | `bottom_inset` | from `window.mbSafeArea` |

Fixed = 368. `R = vs.y − top_inset − bottom_inset − 368`.

```
STAGE_PREF = 640   STAGE_MIN = 460   LIST_MIN = 240  (two card pitches of 120)
if R >= 1018: S = 640 + floor4(0.4 * (R - 1018))
else:         S = clamp(floor4(R - LIST_MIN), STAGE_MIN, STAGE_PREF)
P = R - S
```

| Viewport (CSS) | Arises from | `vs` | Insets | R | **S** | **P** |
|---|---|---|---|---|---|---|
| 390×844 | Home-screen app | 720×1558 | 108 / 64 | 1018 | **640** | **378** |
| 390×664 | **Safari with toolbars (the WhatsApp-link entry)** | 720×1226 | 0 / 0 | 858 | **616** | **242** |
| 360×640 | Android Chrome on a 360×740 phone | 720×1280 | 0 / 0 | 912 | **640** | **272** |
| 375×548 | iPhone SE Safari with toolbars (floor) | 720×1052 | 0 / 0 | 684 | **460** | **224** |

The fork's 40/60 rule overflows by 54 px at 390×664 and would cut off the tab bar, which now sits at the bottom. Under this rule Row A, Row B, the ticker and the tabs never shrink.

Positions (screen y): `top_y = floor4(top_inset)`; Row A `top_y`; Row B `top_y + 96`; stage top `st = top_y + 180`; stage bottom `sb = st + S`; ticker `sb`; panel `sb + 84`; tabs `sb + 84 + P`. `_lower.position.y = sb`. Wide screens centre the 720 column (`_ox`) as the fork does; desktop caps the canvas at a 390-CSS phone frame in `shell.html`.

---

## 2. Row A: `TopBar`, y 0-96 in `_top`

The fork's stat window, banana icon, thumbs line, Evolve button and badge are **removed**. Reading order right → left: **Cottage Index · counter · mute · settings**.

| Element | Node | Rect | Content |
|---|---|---|---|
| Cottage Index | `TopBar.cottage` | hit `Rect2(624, 4, 88, 88)`; kit `cottage_cup` 16×18 art = 64×72 at (636, 12) | Tooltip `HUD_COTTAGE_TIP` as a toast. 50% opacity, 100% for 3 s on a pixel drop. Hidden until `ui.cottageRevealed`. |
| Counter | `TopBar.bank` (`Label`, numeral cut) | box x 196-524, y 8, **centred** | `HUD_BANK`, gold (money), never fades |
| Rate line | `TopBar.bps` (`Label`) | box x 188-532, y 52, centred | `HUD_BPS` (frenzy: `HUD_BPS_FRENZY` in the frenzy tint). 100% for 3 s after a change, then 60%. Hidden until `ui.rateRevealed`. |
| Mute | `TopBar.mute` (`PxButton`) | hit `Rect2(100, 4, 88, 88)`, icon 9×9 art = 36×36 at (126, 30) | a11y `HUD_MUTE` / `HUD_UNMUTE`; muted = slash shape |
| Settings | `TopBar.gear` | hit `Rect2(8, 4, 88, 88)`, icon at (34, 30) | a11y `HUD_SETTINGS` (mirrored from the fork's right corner) |

---

## 3. Row B: seats bar, y 96-180 in `_top`

One node group `TopBar.seats`. **The whole row is one target**, hit `Rect2(0, 96, 720, 88)` (4 px into the stage to clear the floor), opening T3. Hidden until `ui.seatsRevealed`.

| Element | Rect (in `_top`) | Content |
|---|---|---|
| Label | box x 576-704, y 120, right-aligned | `HUD_SEATS` "מנדטים" |
| Track | kit `seats_track` shipped 106×9 art = `Rect2(144, 120, 424, 36)` | fill `sky`, **anchored at x 568, grows left** (`mirror`); a notch every 10 seats from the right |
| Numeral | box x 16-136, y 120, `PxText` | `HUD_SEATS_VALUE` "58/61" |
| Blackout (23.10 00:00 → 27.10 22:00) | baked stamp `stamp_blackout_dark` in `Rect2(16, 104, 288, 72)`; track shortens to `Rect2(316, 120, 252, 36)` | The numeral node is **removed**. `HUD_SEATS_BLACKOUT` is the stamp's a11y text and fallback. |
| ≥ 61 | kit `seats_goal_frame`: a 4-art-px gold ring (money = the reward moment) | 1 Hz pulse; static ring under reduced motion |

Seat pips fly from the paid pill to the **fill head** (the left end of the filled part).

---

## 4. Stage: `_stage`, height `S`, stage-local y

Bottom-anchored: Magician, Suitcase band, thermometer. Top-anchored: toasts. The right column (x 568-720) holds the ultimatum cameo or Sara (§4.2).

| Element | Node | Rect (stage-local) | Notes |
|---|---|---|---|
| Backdrop | `Diorama` | full stage, extends to the screen top | Era backdrops 180×320 ×4, symmetric |
| **Leader** (was the Magician; §4.3) | `BigBanana` (rename allowed) | hit `Rect2(172, S−556, 376, 416)` at art ×4; **art ×3 and hit `Rect2(208, S−452, 304, 312)` when `S < 560`** | Feet at (360, S−156). Hit bottom S−140: ≥ 20 px clear of the Suitcase hit. The same rects for every leader: the hit is the whole figure, never the prop. |
| **Suitcase band** | `GoldenView` | `Rect2(0, S−116, 720, 112)` | §4.1 |
| **Thermometer** | new `Thermo` | hit `Rect2(12, S−544, 120, 404)`; kit `thermo_tube` 14×88 art = 56×352 at x 44-100, bottom at S−140, icon 11×11 art above at S−544 | Fills bottom → up (`keep`). The kit's magnifier/gavel icon sits above the tube; the state word (`HUD_SUSP`, `HUD_SUSP_HOT`, `HUD_SUSP_BOIL`) sits under the bulb at S−136, centred on x 72 (box x 12-132). Floor = red/black hatch (`thermo_floor_hatch`). Tap → T4. **When `S < 560`** use `thermo_tube_short` (request to the 2D Artist, 14×58 art) with hit `Rect2(12, S−452, 120, 312)`. |
| Toast dock | `Toasts` in `_ui` | `Rect2(16, 8, 688, 88)` one line; `Rect2(16, 8, 688, 132)` two lines | **Text box x 32-676, right-aligned at 676** (rev 2026-09-29: the kit `toast` content box ends 6 art px = 24 logical before the plate's right edge 704, where the accent stripe is; text at 688 touched it). **Chat toast** (C1 and every later ping): the 16×16 avatar crop (64×64) at x 612-676, inside the accent; line 1 `TOAST_CHAT_HEAD` "{name} · בקבוצה", line 2 the message preview, one line, ellipsised; both right-aligned at 596 (box x 32-596). Always two lines (132). |
| Dubi's bubble | `Toasts.say` | the kit `chat_bubble_in`, above the anchor | **Text white** (`w` #fff8ec, 13.6:1 on the bubble's #2e2250; the shipped #1b1426 is 1.24:1); the kit note says "white on ui_bubble 13.1:1". |
| Floaters | `Floaters` | clamp x 24-696, y 8 … S−120 | Rise straight up |
| Buff chip | `BuffViews` | `Rect2(160, 104, 400, 56)` | Timer bar drains left → right (`mirror`) |
| Catch banner | `BuffViews` | `Rect2(96, 168, 528, 72)` | Centred |
| Book / perk plates | `_book_btn`, `_perk_btn` | **removed** | Book = T4, perks = the coalition agreement (§7.3) |

The court chip is **not** on the stage any more: during court day it takes the ticker's date-chip slot (§5.1), as the 2D Artist's proof shows.

### 4.1 Suitcase (`GoldenView` repurposed)

| Property | Value |
|---|---|
| Sprite | kit `suitcase` 26×20 art = 104×80 |
| Hit | `Rect2` 136×120 centred on the sprite (replaces the fork's hit circle and the E6 overlap rule) |
| Path | centre y S−60, ±8 bob (none under reduced motion). **First flight enters at x 760, exits at x −104 (right → left), 6.0 s.** Later flights alternate; 3.5-4.5 s; floor 3.0 s. |
| Spawn guard | Band unobstructed: no tall tab, no overlay, no toast over the band, no expanded court card reaching the stage (floor viewport only, §6.4), **no undo chip (§8.6)**, not in `LEADER_PICK` |
| Keyboard | `S` catches while `on_screen()` |

### 4.2 Right column: the ultimatum cameo and Sara (answers to the Animator)

**Stage cameo during an ultimatum: accepted**, because an ultimatum is the game's only gameplay-critical timer and a player with the chat closed otherwise sees only a badge. Constraints:

| Rule | Value |
|---|---|
| Slot | feet at (644, S−140), partner art scale = Magician scale − 1 (×3, or ×2 at `S < 560`); must fit between the toast dock bottom (y 140) and S−140, else the cameo is skipped |
| Hit | `Rect2(568, S−140−h, 152, h)`: tap opens T3 scrolled to the ultimatum. 20 px clear of the Magician's hit (x 548). |
| Timer | kit `chip_ultimatum` (clock icon + `CHAT_ULT_TIMER` "0:45") centred above the head, box 128. It is the non-colour channel; the cameo alone is not a readable timer. |
| Count | at most one (the newest ultimatum); hidden while a tall tab or overlay covers the stage |
| Never | inside the Suitcase band, the Magician's hit, the toast dock, or during the first-minute FTUE (U1 gates it anyway) |

**Sara's mark (Balfour era only):** the same right column, feet at (652, S−140), art ×2 (a depth cue: she is behind the Magician's plane), not a tap target. When a cameo enters she fades out (150 ms) and returns after it leaves. Hidden in eras 2-4.

**Idle coin-peek invite (the Magician, main mode): accepted only while `evolutions == 0 and owned_total < 3`**, i.e. while tapping is still the main income. After that tapping is optional (accessibility §7.3 of first-minute), and a recurring peek would read as a nag. Reduced motion as the Animator specifies.

### 4.3 Per-leader stage and HUD (rev 4, leader select)

Everything in §1-§7 is shared by all leaders: every rect, every flex rule and every reveal. Leaders differ only in the words and art below (spec D5).

**The tap object and the P0 prompt.**
- **Hit:** tapping means tapping the **leader's hit** (§4 row), for every leader. The prop is never the target, because a d 1 prop (≤ 20 art) is 80 logical, under the 88 floor.
- **The object:**
  - **Bibi** keeps the hat: his `tap` anim, with coins from `hatMouth`.
  - **Every other leader** plays idle, and a tap squashes their **prop** at `propMouth` (pen, phone, chair…; spec §5.2), with coins from the prop's mouth.
- **P0's emphasis** (`ftue.md` §3) moves to that object: the 1 Hz brightness pulse is on the prop, Dubi's F1 peck targets the prop, and F2's hand points at the leader's hit centre.
- **The prompt stays textless for every leader.**

**Where the leader's name shows:**

| Place | Key | When |
|---|---|---|
| The pick tiles and the again button | `leaders[].short` + `party`, `LEADER_PICK_AGAIN` | `LEADER_PICK` |
| The round's lower third (toast 1) | `LEADER_PICK_PLATE` "{short} · {party}" | every round start (§8.6) |
| T4 header status line | `DOS_STATUS_LEADER` "{short} · {party}" (box `tall.status`, x 32-616) | always, once T4 is revealed |
| T4 "ראשי רשימה" section | `DOS_LEADERS`, `DOS_LEADER_ROUNDS_*`, `DOS_LEADER_TAPS` (§6.3) | after a second leader has been played |
| O3 election card | `ELECT_LEADER` under `ELECT_TITLE` | every election |
| Share cards (O4 / O5) | the round's leader art + `short` (views, spec §10.1) | — |
| Chat | the system lines are **second person** ("יצרת את הקבוצה…", "ניקית את הצ׳אט…"), as a chat app words them for the group's creator: the player *is* this round's leader (D32) | — |

**No persistent HUD label** (a principled omission, not an oversight):
- **The figure is the identity:** it is the largest sprite on screen.
- **Row A is money and Row B is seats.** A name beside the seat numeral ("בנט · 58/61") reads as a poll, which is exactly the red line.
- **The stage has no free slot:** the toast dock is at the top, the leader's hit is in the middle, the Suitcase band is at the bottom, the thermometer is on the left and the cameo/Sara on the right.

**Hazard skin: the court (Bibi) vs the press (everyone else).** The meter, the numbers, the phases and the card geometry (§6.4) are all shared; only the words and two icons change.

| Surface | Court (Bibi) | Press (every other leader) |
|---|---|---|
| Thermometer word (§4) | `HUD_SUSP` / `_HOT` / `_BOIL` "חשד / מבעבע / רותח!" | `PRESS_SUSP` / `_HOT` / `_BOIL` "כותרות / חם / רותח" (all fit 120: widest 116) |
| Thermometer icon | magnifier; gavel on court day | magnifier; **no gavel** (it means the court). **2D ask:** `thermo_icon_press` 11×11 and `chip_icon_press` 9×9 (a folded newspaper), so press has its own non-colour sign. Interim: magnifier, and a text-only chip. |
| K2 toast | `TOAST_DOSSIER` "נפתח לך תיק." | `PRESS_REVEAL` "נפתח עליך תחקיר." |
| Ticker chip (§5.1) | `COURT_CHIP_SUMMONS` "זימון" / `COURT_CHIP_TITLE` "יום משפט" | `PRESS_CHIP_SUMMONS` "תחקיר" / `PRESS_CHIP_TITLE` "יום תחקיר" (168 px: the chip widens to 220, §5.1) |
| Card title | `COURT_SUMMONS_TITLE` / `COURT_TITLE` | `PRESS_SUMMONS_TITLE` "תחקיר בדרך" / `PRESS_TITLE` "יום תחקיר" |
| Card body | `COURT_SUMMONS_BODY` / `COURT_BODY` (they name Bibi) | `PRESS_SUMMONS_BODY` / `PRESS_BODY_M` / `_F` "{short} מגיב לתחקיר…" (by `leaders[].g`) |
| Effect, timer | `COURT_SUMMONS_EFFECT` / `COURT_EFFECT`, `COURT_SUMMONS_TIMER` / `COURT_TIMER` | `PRESS_SUMMONS_EFFECT` / `PRESS_EFFECT`, `PRESS_SUMMONS_TIMER` / `PRESS_TIMER` |
| Primary button line 1 | `COURT_POSTPONE_VERB` "התייעצות ביטחונית" | `kit.hazard.postponeVerb` (content; linted ≤ 384, widest 272) |
| Secondary button | `COURT_TESTIFY` "להעיד" | `PRESS_TESTIFY` "להגיב" |
| After a postponement | `COURT_POSTPONED_PREFIX` + the court excuse ladder | `kit.hazard.postponePrefix` + `kit.hazard.excuses` (the card grows upward, as it does for Bibi) |
| End toast | `TOAST_COURT_END` | `PRESS_END` "התגובה פורסמה. הקצב חזר." |
| T4 rows | `DOS_COURT_DAYS`, `DOS_SUSP_FLOOR` | `PRESS_DAYS` (needs a press-day stat in the sim), `PRESS_SUSP_FLOOR`. Lifetime rows show only when > 0. |

**Bibi-only surfaces are hidden, not disabled, in every other round:**
- the aide button on the card (`AIDE_BTN`, and its confirm);
- the aide's card line (`AIDE_HOLDS`);
- T4's `PARDON_ROW` (and so O15);
- Sara's mark (§4.2) and the DOHA sticker (`suitcase_plain`);
- spins s07, s09, s10, s14 and s15 (so `HUD_BPS_POUR` can only occur in his round).

"Hidden" means no greyed row that invites a question the round can't answer.

**Per-leader words in shared chrome** (the `_LEADER` keys; the engine switches to them when the picker ships, for Bibi too, whose kit words equal today's):

| Pre-picker key | Leader key |
|---|---|
| `BUFF_CHIP_TAPFRENZY` | `BUFF_CHIP_TAPFRENZY_LEADER` "{verb} ×{mult} · {s} שנ׳" |
| `BANNER_FRENZY` | `BANNER_FRENZY_LEADER` "{banner} ×{mult}" |
| `upgradeEffects` s01, s02, s11 | `SPIN_EFFECT_S01_LEADER`, `SPIN_EFFECT_S02_LEADER`, `SPIN_EFFECT_S11_LEADER` |
| — | `ST_TAPS` / `ST_CRITS` are now neutral lifetime words ("הקשות", "הברקות"); a leader's own row uses the kit's `verbPlural` / `critPlural` |

**`EVOLVE_TX` and the stage** (D30): the old leader walks out screen-right on the fade (Animator §9.3.4), and the stage stays empty through the O3b flash and the picker. The new leader walks in on the pick (§8.6), not inside the transition, because the pick comes after it.

---

## 5. Ticker row: `Ticker` in `_lower`, y 0-84

### 5.1 Layout

**Rev 2026-09-29 (the engine's §5.1 objection): accepted as built.** The anchor is sized from its contents, right → left, in `Ticker.anchor_layout` (one data table, `L.TICKER`). The numbers below are the ratified ones at ×4:

| Element | Rect (`_lower`-local) | Content |
|---|---|---|
| Tag plate | `Rect2(604, 18, 104, 48)`: the measured tag + 8 px each side | red "מבזק" plate, `TICKER_TAG` right-aligned at x 700, y 24. **Always ×4**, also under large text (§0.2: 110 px at ×5 does not fit its 88 box), so the plate and everything left of it never move. |
| Dubi | the whole small Dubi (20×23 art = 80×92) at ×4, frame x 520-600, feet on the row floor (y 84), anchor [10, 22] | 4 px left of the plate. His head stands **8 px above the row, over the Suitcase lane's floor**: accepted, see below. Not a tap target (the row hit takes the tap). |
| Crawl clip | `_clip` x 192-516 (324), text y 24 | pool of `Label`s; ends 4 px before Dubi's frame. The clip's right edge is **always** `anchor_layout().clipX1` (516), including on court day. |

**Dubi above the row (8 px):** accepted, no crop. A head-only 16×16 Dubi would give the crawl 16 px back but lose the full-body presenter the 2D Artist drew; 324 px already equals the court-day width the spec accepted. The 8 px poke is harmless because (1) the Suitcase's sprite never reaches it: its centre is S−60 ± 8 bob and it is 80 tall, so its lowest pixel is S−12, 4 px above Dubi's head top at S−8; (2) Dubi is not a target, and the Suitcase hit (136×120, reaching S) keeps priority over anything under it; (3) depth: the ticker (`_lower`) draws above the stage, so the head reads as a presenter standing in front of the set, never behind the lane's floor. If a future Dubi anim grows taller than 23 art rows, the rule is: his frame may rise at most 8 px above the row.
| **Date chip** | kit `chip_countdown`, `Rect2(8, 12, 176, 60)` | calendar icon 9×9 art at the chip's right; `HUD_COUNTDOWN_DATE` "27.10" (`PxText`) left of it. On 27.10: `HUD_COUNTDOWN_TODAY`. After 27.10: handshake icon + `HUD_COUNTDOWN_AFTER` "יום {n}". 60% opacity; 100% on the first view of a new day. **The day count ("עוד 29 ימים") is not in the chip** (flag F2): it lives in the title state and in the daily ticker line T24, which jumps the queue on the first open of each day. |
| **Court-day chip** (replaces the date chip while a summons or court runs) | kit `chip_court`, `Rect2(8, 2, 212, 80)` (wider when its title needs it); the clip becomes x 228-516 (288): its **left** edge moves to the chip's right + 8, its right edge stays at Dubi − 4 | gavel icon right; line 1 `COURT_CHIP_SUMMONS` "זימון" during a summons, `COURT_CHIP_TITLE` "יום משפט" during testimony; line 2 `COURT_CHIP_TIMER` (40 + 36). Tap → expands the court card. |
| **Press-day chip** (rev 4: every leader but Bibi, §4.3) | the same kit `chip_court` at `Rect2(8, 2, 220, 80)`: `PRESS_CHIP_TITLE` "יום תחקיר" is 168 px (box `ticker.chipWide`), 8 over the 160 box, so the chip grows by 8 and the clip becomes **x 236-516 (280)**; reduced-motion pages at 280 (258 at ×5) | no gavel (interim: text only; the 2D ask is `chip_icon_press`); line 1 `PRESS_CHIP_SUMMONS` "תחקיר" during the summons, `PRESS_CHIP_TITLE` during the response; line 2 `COURT_CHIP_TIMER`. Tap → expands the press card. |
| Row hit | `Rect2(0, 0, 720, 88)` minus the chip | tap → O6 headline card while a headline is showing |

### 5.2 Crawl (`mirror`; speed per the Animator's objection, accepted)

A line starts fully left of the clip and slides **right**, so its first word enters first.

```
start:     x = −line_w                      (clip-local)
step:      x += 4 · text_scale / 4  → one art pixel (4 logical at ×4, 5 at ×5) every 3 frames at 60 Hz
speed:     20 art px/s = 80 logical/s at ×4 (43 CSS/s), 100 at ×5: the same glyphs per second at both scales
done:      x > clip_w          next line when: last.x ≥ tickerGapPx
```

One step per 3 frames gives an even cadence (the old 74 px/s snapped to 3 gave 2-3-2-3 frame steps). Reduced motion: one right-aligned `Label`; pages broken by measured width ≤ **the live clip width** (324 at ×4, 302 at ×5; 288 / 266 on court day); dwell max(4 s, 60 ms × chars); 200 ms cross-fade; tap for the next page.

### 5.3 Election CTA

When `Coalition.gate_open(s)`: a kit `button_gold` `PxButton`, hit `Rect2(0, 0, 720, 88)`, visual `Rect2(8, 2, 704, 80)`, `HUD_CTA_ELECTION` "עוד סבב!" centred. The chip and anchor hide; the crawl pauses with its queue intact. Opens O3.

---

## 6. Panel and tabs: `Shop` in `_lower`

### 6.1 Cards (y 84 … 84+P), pitch 120 (kit `card_row` 30 art)

List clip `Rect2(16, 84, 688, P)`; scroll track **left**, `Rect2(4, 84, 4, P)`.

| Part | Fork (LTR) | **od-sevev (RTL), card-local** | Content |
|---|---|---|---|
| Card | `Rect2(16, 0, 688, 96)` | `Rect2(16, 0, 688, 120)` (kit `card_row` 9-slice) | — |
| **Hit** | row | **the whole card**, commit on release, 10-px move = scroll | first-minute §3.1 |
| Plate + icon | `plateX 24` | kit `card_plate` 26×26 art = `Rect2(588, 8, 104, 104)`, icon 24×24 art = 96×96 at (592, 12) | Shady sources (4-7): the 11×11 magnifier badge at the plate's top-left (584, 4) is the non-colour channel; its a11y text is `CARD_SHADY_TAG`. |
| Name | `nameX 112` left | box x 220-580, **right-aligned**, y 16 | name from `design/content.json` (`producers[].name`), or `ROW_LOCKED_NAME` |
| Line 2 | `line2Dy 52` | box x 220-568, right-aligned, y 64 | `ROW_OWNED_BPS` (yield); locked: `CARD_LOCKED_CAP` (box x 220-580) |
| Owned | inside line 2 | **a badge on the plate's bottom-left corner**: dark chip `Rect2(572, 72, 104, 44)`, `PxText` centred | `CARD_OWNED` "×14"; hidden at 0. Moved off line 2 because late-game yields ("+8.88mm ₪ לשנייה", 308 px) need the whole line. |
| Price pill | `pillX 520` right | **`Rect2(28, 16, 184, 88)` left**: kit `pay_pill_*` 9-slice stretched to 46×22 art | line 1 `CARD_VERB_FIRST` / `CARD_VERB_MORE` / `ROW_BUY_N` (y 22), line 2 `CARD_PRICE` (y 58), both centred (box 168). Can't afford: the kit's sunken well with the dim gold fill **growing from the right**. |

The pill is 46 art wide, not the kit note's 54: a 54-art pill would leave too little room for the names. The widest price is a late-game "8.88mm ₪" (164 px); the kit's 9-slice stretches either way.

**Buy-mode row** (revealed at 10 of any source): list row 0 of T1, `Rect2(16, 0, 688, 104)`: `BUYMODE_LABEL` right-aligned at x 580; a kit `button_secondary` visual `Rect2(28, 12, 184, 80)`, hit `Rect2(16, 0, 212, 104)`, cycling `BUYMODE_1` / `BUYMODE_10` / `BUYMODE_MAX`. Scrolls with the list.

**Spin card** (T2): same geometry; pill verb `SPIN_VERB`; fatigue = the `SPIN_FATIGUE` stamp over the plate's bottom edge; timed spins show `SPIN_ACTIVE` on line 2 (wide box). The engine's reading is ratified: a line's level tag ("1/5") in the owned-badge slot on the plate's bottom edge (`Shop.SPIN_TAG`), and S08's split bar as a 2-art-px track under line 2 (`Shop.SPIN_BARS`, public from the right). **S08 at level ≥ 1:** line 2 reads `SPIN_BARS_LINE` "ערוץ ידידותי: {pct}%" (`{pct}` = `bars.friendly`) instead of the effect label; the number names the part of the bar that grows. The two parts' accessible names are `SPIN_BAR_PUBLIC` / `SPIN_BAR_FRIENDLY`. Labels on the bar itself do not fit: at ×4 one word is 104-120 px and the friendly part starts at 72 px (20%). **S10:** each flight catch floats `FLOATER_FLIGHT` "+{pct}% להכנסה" (the round's running bonus) over the Suitcase.

### 6.2 Tab bar (kit `tabbar` 180×26 art = 720×104), at the bottom

Slots of 180, **reading order right → left**, slot `i` at `x = 540 − 180·i`: 1 מקורות (540-720), 2 ספינים (360-540), 3 קואליציה (180-360), 4 תיקים (0-180).

Per slot: hit `Rect2(0, 0, 180, 104)`; tab icon 15×15 art = 60×60 at (60, 8); label centred at y 64 (box 164). **Active tab: kit `tab_active` raised plate + 2-art-px pale `rim` underline + white label + the only coloured icon** (flag F1: gold is money-only). Idle: no plate, grey label, dimmed icon. Badge: kit `badge_count` 11×11 art = 44×44 at (44, 0), the icon's **top-left** (RTL trailing corner; the kit note says top-right, which is the LTR position).

Progressive reveal keeps slots fixed (empty until revealed): slots 1 + 3 at C1, 2 at K3, 4 at K2. Keyboard 1-4 = slots 1-4.

### 6.3 Tall tabs (T3 coalition, T4 dossier)

Cover the stage and the ticker: screen y `top_y + 180` to the tab bar, `H_T = S + 84 + P` (1102 at ref, 942 at 390×664, 768 at the floor). Rows A and B stay visible. One history entry. While open: Magician input off, Suitcase spawn off, cameo hidden.

**T3 "קואליציה 61"** (kit `chat_*`), tall-local:

| Part | Rect | Content |
|---|---|---|
| Header | kit `chat_header` 180×26 art = `Rect2(0, 0, 720, 104)` | Chevron › hit `Rect2(632, 8, 88, 88)`. Title `CHAT_TITLE` right-aligned at x 616, y 16; lock icon left of it. Status right-aligned at x 616, y 56, box x 32-616: `CHAT_MEMBERS_*` / `CHAT_TYPING_*` / `CHAT_THREATS_*`. |
| Pinned bar | kit `chat_pinned` 180×14 art = visual `Rect2(0, 104, 720, 56)`; **hit `Rect2(0, 104, 720, 88)`** once it is a button | Pin icon right (x 676); `CHAT_PINNED` right-aligned at x 660, y 114. After the first election the bar opens the coalition agreement (§7.3); the `!` badge sits at (16, 110). |
| Thread | `Rect2(0, 160, 720, H_T − 248)` | newest at the bottom; scrollbar x 4 |
| Incoming bubble | **avatar 32×32 art = 128×128 at x 576-704** (flag F5); bubble (kit `chat_bubble_in`) right edge x 568, width ≤ 480 (x ≥ 88), text column 416 (17 glyphs) | Sender name (`chat.name` box) + text, right-aligned. **Run grouping:** avatar and name only on the first bubble of a run from one sender; later bubbles keep the indent. **Tap the avatar or the name** (name hit 416×88) → the partner card (answer to the Animator: the entry point). |
| Forwarded threat | `CHAT_FORWARDED` above the text, muted, forward-arrow icon (`mirror`, points left) | — |
| Pay pill | kit `pay_pill_*` stretched to 82×17 art = 328×68, right-aligned at the bubble's inner right edge; hit 352×88 | `CHAT_PAY` / `CHAT_PAY_SHORT` (the fill grows from the right) |
| **Decline pill** (rev 4: Liberman's round only, spec §5.1 `declineDemand`) | a second pill **under** the pay pill, the same 328×68 visual, right-aligned with it, 8 px gap; hit 352×88. Kit `button_secondary` look (never gold: it costs nothing). Only on an open **member** demand, never on an ultimatum or a join demand. | `CHAT_PILL_DECLINE` "לא יושב"; during the 90 s cooldown, disabled, `CHAT_PILL_DECLINE_CD` "לא יושב · 60 שנ׳" (on every such pill at once). A press closes the demand and posts `CHAT_SYS_DECLINED` "הדרישה של {name} נדחתה · לא יושב". |
| Ultimatum | kit `chat_bubble_ultimatum` (red/black hazard band) | `CHAT_ULTIMATUM` right-aligned; kit `chip_ultimatum` (clock) at the bubble's left with `CHAT_ULT_TIMER` |
| Player reply | kit `chat_bubble_out`, left-aligned at x 16, width ≤ 480 | `CHAT_REPLY_1..3` |
| System pill | kit `chat_system_pill`, centred, width ≤ 600, ≤ 2 lines | `CHAT_SYS_*`. A "left" line carries `CHAT_SYS_REJOIN` under it; a "removed" line with `payable = poach` carries `CHAT_SYS_POACH` (both visual 512×68, hit 536×88, centred). |
| Transfer | kit `transfer_banner` 720×120 full bleed + `transfer_card` under it | name (large), `CHAT_TRANSFER_LINE` (wraps to 2) |
| **Brawl** | `CHAT_SYS_BRAWL` pill, then **the brawl-cloud slot inline in the thread, 208×160 centred (x 256-464)** (answer to the Animator), then the `CHAT_BRAWL_BTN` button visual 312×80, hit 336×88, centred | then `CHAT_BRAWL_AFTER` + `CHAT_CORRIDOR_COUNT` |
| Composer | kit `chat_composer_disabled` 180×22 art = `Rect2(0, H_T − 88, 720, 88)` | `CHAT_COMPOSER`, right-aligned, disabled |

**Partner card** (from the avatar/name): a modal card over T3 (depth 2), 624 wide, the figure idling at integer scale, name, seats, upkeep, and the partner's open demand pill if any. ✕ top-left + `SYS_CLOSE`. A partner who left shows greyed at f0 (the Animator's `gone` state). **Rows** (rev 2026-09-29): label right-aligned at the card's right − 32 (`HUD_SEATS`, `PARTNER_UPKEEP` "דמי אחזקה מההכנסה"); the value sits **16 px left of its label**, right-aligned there, not at the card's far left (500 px away the eye cannot pair them); value colour = the body colour, not the note purple. The pill is the same pill as in the thread (`CHAT_CEREMONY` for a ceremony). A pay that starts a ceremony ribbon keeps the card open and fills the card's own pill.

**Ceremony demand (Regev, `kind: ceremony`, price 0):** the pill reads `CHAT_CEREMONY` "לגזור סרט ✂" in the gold affordable state; a tap starts the 3 s ribbon fill (from the right) and the label becomes `CHAT_CEREMONY_CUTTING` "גוזרים…" until the stamp. Never "סגרנו · 0 ₪".

**T4 "תיקים"**: the same header (`DOS_TITLE`), then 88-px rows (labels right-aligned at x 688), full-width buttons (hit 688×88) `SHARE_RECEIPT_TITLE`, `SHARE_RESULT_BTN`, `PARDON_ROW`, `BOOK_STORY`, then the `BOOK_TROPHIES` section.

**T4, rev 4 (leader select):**
- **Header status:** the header's status line (the T3 status slot, x 32-616, y 56) shows `DOS_STATUS_LEADER` "{short} · {party}".
- **`PARDON_ROW`:** Bibi's round only (§4.3).
- **A "ראשי רשימה" section after the stats** (`DOS_LEADERS`), shown once two leaders have been played. It has one 2-line row per played leader:
  - line 1: `DOS_LEADER_ROUNDS_ONE/_TWO/_OTHER` "{short} · ⟦n⟧ סבבי בחירות";
  - line 2, muted: `DOS_LEADER_TAPS` "{verbPlural}: n · {critPlural}: c";
  - the leader's `avatar24` at ×2 on the right.
- **Row order:** first-played. Never sort by a count: a leaderboard of politicians is a ranking.
- **Hazard rows:** `DOS_COURT_DAYS` and `PRESS_DAYS` each show only when > 0; the floor row is the current skin's (`DOS_SUSP_FLOOR` / `PRESS_SUSP_FLOOR`).

### 6.4 Court card (O2, non-modal) over the panel

Kit `court_frame` 9-slice, `Rect2(16, y0, 688, 356)`, bottom-anchored to the tab bar. When `P < 356` it extends up over the ticker, and at the floor viewport 48 px into the stage (then the Suitcase spawn guard counts it). Card-local: ✕ hit `Rect2(0, 0, 88, 88)`; the header plate `COURT_TITLE` + gavel right-aligned, y 24; `COURT_BODY` y 96, `COURT_EFFECT` y 140, `COURT_TIMER` y 184 (right-aligned at x 656); button row y 236: **primary on the left** kit `button_primary` `Rect2(16, 236, 416, 104)` with `COURT_POSTPONE_VERB` over `CARD_PRICE` (two lines), **secondary on the right** `Rect2(448, 236, 224, 104)` `COURT_TESTIFY`. After a postponement the baked `stamp_postponed` sits over the body and the excuse ladder (copy deck §H) replaces `COURT_BODY` under `COURT_POSTPONED_PREFIX` (the card grows upward). Collapse → the ticker's court chip (§5.1).

**Two phases, two texts** (rev 2026-09-29). The card shows the phase it is in; the same words for both told the player "income is slowed" and "testimony: 0:20" while nothing was slowed yet, then the timer jumped to 0:30.

| Phase | Title | Body | Effect line | Timer |
|---|---|---|---|---|
| `summons` (the choice) | `COURT_SUMMONS_TITLE` "זימון לעדות" | `COURT_SUMMONS_BODY` | `COURT_SUMMONS_EFFECT` "בזמן העדות: כל ההכנסות ×0.5" | `COURT_SUMMONS_TIMER` "העדות מתחילה בעוד m:ss" |
| `court` (testimony) | `COURT_TITLE` "יום משפט" | `COURT_BODY` | `COURT_EFFECT` | `COURT_TIMER` "עדות: m:ss" |

The card rebuilds on the phase edge. **Depth:** the court card (non-modal) draws above the tall tabs T3/T4 and below every modal; while it is expanded over a tall tab, that tab's list gets bottom padding equal to the card's height so its last rows can scroll clear. **Esc / back** with the card expanded collapses it to the chip (one history entry while expanded), before any other layer rule.

**The press card** (rev 4: every leader but Bibi): the same frame, rects, phases, buttons and rebuild. The words come from §4.3's table. The header icon is the press icon (interim: none; never the gavel). **Hidden on the press card:** the aide button and the pardon row. The body keys are gendered by `leaders[].g` (`PRESS_BODY_M` / `_F`); every launch leader is `m`.

---

## 7. Overlays (`OverlayManager`, `Overlay`, `Overlays.*`) in `_modal`

### 7.1 Common rules

| Rule | od-sevev |
|---|---|
| ✕ | **top-left**: visual `Rect2(panel.x + 16, panel.y + 16, 64, 64)`, hit `Rect2(panel.x, panel.y, 104, 104)` |
| Bottom "סגור" | every **sheet** also has a full-width `SYS_CLOSE`, hit `Rect2(24, h − 112, 672, 88)`, fixed (does not scroll) |
| Two buttons | **side by side when both labels fit 224 px**: cancel right `Rect2(376, y, 256, 96)`, commit left `Rect2(88, y, 256, 96)`. **Otherwise stacked**, full width `Rect2(88, y, 544, 96)`: commit on top, cancel below. Stacked cards at ×4: election (O3), aide-drop confirm. Focus starts on cancel for destructive modals. |
| Text | `Label`, body right-aligned at panel.right − 32, titles centred in a 432 box (clear of ✕); cards grow vertically (the kit's 9-slices) |
| Backdrop | closes, except O10 reset and the aide-drop confirm |
| **Scrim** (rev 2026-09-29) | **the kit's outline swatch `#0b0a12` at 60%** (`Tune backdropAlpha` 0.6), not the fork's grape `U #3a1e72`. A scrim must only darken: grape at 60% *lifts* the game's dark base (#140c24 → #2b1753, the measured result), which reads as fog and flattens the dark sheets' edges against it; the outline swatch takes #140c24 to #0d0a17 and the Balfour wall to 40%. The kit's own modal note already says "outline swatch at 60% (UX)". The spin tag plate that shares `uiTheme.scrim` gets the same colour (white "שחוק" on it rises to ≥ 17:1). |
| Keyboard | ← next, → previous (`mirror`); Tab / Shift-Tab in reading order |
| History | one `pushState` per layer (first-minute §1.2): every overlay, the partner card, T3/T4, and the expanded court card. `popstate` closes the top layer exactly as ✕/Esc does. With no layer open, back leaves the page as a browser expects (the save is flushed on `pagehide`); the root is never trapped. |

Modal card: `Rect2(48, y, 624, h)` centred. Sheet: `Rect2(0, vs.y − bottom_inset − h, 720, h + bottom_inset)`, bottom-anchored.

### 7.2 Overlay map

| Fork class (`id`) | od-sevev | Form | Keys |
|---|---|---|---|
| `SettingsOverlay` | O7 settings | sheet, `h = min(content, floor4(0.70 · vs.y))`, body scrolls beyond | §7.4 |
| `ResetOverlay` | O10 reset | modal, side-by-side buttons | `RST_*` |
| `EvolutionOverlay` | O3 election card | modal, **stacked** buttons | `ELECT_*`, `TITLE_ROUND`, `MOOD_*`, `EVO_MULT` |
| `OfflineOverlay` | O1 return | modal, one full button | `RET_*`, `OFF_AMOUNT` |
| `ConfirmOverlay` | aide-drop confirm | modal, **stacked** | `AIDE_CONFIRM_*` |
| `PerksOverlay` | the coalition agreement | sheet | `PERKS_*`, `PERK_*` |
| `BookOverlay` | replaced by T4 | — | `BOOK_*` = T4 section names |
| `StoryOverlay` | O3b Dubi flash; archive from T4 | modal: `FLASH_NEXT` full width, `FLASH_SKIP` secondary under it | `FLASH_*`, `STORY_*` |
| `EvolveTx` | election transition | full screen | `EVOTX_LINE` + `ELECT_TITLE` |
| new | O4 receipt, O5 result | sheet 0.8 · vs.y | `SHARE_*` |
| new | O6 headline | modal | `HEADLINE_*` |
| new | O11 blackout, O12 election night | modal | `BLK_*`, `NIGHT_*` |
| new | O15 pardon desk (launch as text) | modal; the baked `stamp_pardon` + `stamp_frame_*` for the other lines | `PARDON_*` |
| new | partner card (§6.3), opposition card, leaked chat | modal / read-only thread | `OPP_*`, `LEAK_*` |
| new | **leader card** (§8.7), over `LEADER_PICK` | modal, depth 1 | `LEADER_PICK_CARD_*` + the leader's content |

### 7.3 The coalition agreement (perks)

Home: the T3 pinned bar. Inert text before the first election; after it, a button (depth 2) with a `!` badge whenever a clause is affordable.

### 7.4 Settings sheet (O7)

Title `SET_TITLE` centred y 24; ✕ top-left. Labels right-aligned at x 656 (box x 296-656); captions under their label, wrapping.

| Row | Height | Label | Control |
|---|---|---|---|
| Group | 48 | `SET_GROUP_SOUND` | — |
| Toggle | 88 | `SET_SFX` | switch |
| Toggle | 88 | `SET_MUSIC` | switch |
| Group | 48 | `SET_GROUP_A11Y` | — |
| Toggle + caption | 144 | `SET_REDUCED_MOTION` + `SET_MOTION_CAP` | switch |
| Toggle | 88 | `SET_HAPTICS` (hidden without `navigator.vibrate`) | switch |
| Toggle + caption | 144 | `SET_LARGE` + `SET_LARGE_CAP` | switch |
| Group | 48 | `SET_GROUP_GAME` | — |
| Row | 88 | `SET_ABOUT` (‹ at the left, `mirror-glyph`) | opens O8 |
| Danger row | 88 | `SET_RESET` + trash icon (leading, right) | opens O10 |
| Close | 112 | `SYS_CLOSE` | — |

Content = 1072 at ×4, so the sheet is 70% of `vs.y` (1088 at ref, no scroll; at 390×664 it scrolls). **Switch:** visual `Rect2(40, row.y + 14, 120, 60)`; state text `SET_ON` / `SET_OFF` at x 176; **ON = knob left** + fill (`mirror`). Whole row is the hit `Rect2(24, row.y, 672, row.h)`.

**Live preview, corrected:** the ticker is *under* the sheet (it was in first-minute too), so the reduced-motion preview is what stays visible above the sheet top: the sky's drifting clouds and the leader's idle (Bibi's hat) stop at once, and the switch's own knob moves without easing.

Not shown (first-minute §7.2 has seven items): notation, fullscreen, save code. `SET_KEYS` may show as a desktop-only footnote under the danger row.

---

## 8. `LEADER_PICK`: the leader picker (replaces the title state; rev 4, 2026-09-29)

**Why it exists:** every round the player heads a different list (Bar, 2026-09-29; `design/leader-select-spec.md` D1-D11). The picker comes **before the first tap and replaces the title**, and **picking a face is the audio-unlock gesture**, so it costs 0 extra taps. The navigation contract is in `screen-graph.md` §0; the FTUE seams are in `ftue.md` §8.

**What it is:** a mode of the stage (`mode == "pick"`), as the title state was, not an overlay. While it shows:
- Rows A/B, the ticker, the panel and the tabs are **hidden**, in both variants. The picker shows no numbers but the fresh-face chip: no ₪ counter, no seats, no poll (§8.8).
- The era backdrop stays behind the modal scrim (`#0b0a12` at 60%, §7.1). The stage is **empty**: at first launch no leader has been picked, and after an election the old leader walked out in `EVOLVE_TX` (D30).
- The economy is frozen: `playtimeSec` does not tick, the Suitcase timer is paused, and nothing spawns. Away credit still follows the O1 rule.

**Old keys:** `TitleView`'s lines are gone. The wordmark moves into the picker header. `TITLE_TAGLINE` and the countdown line are no longer drawn (D26). The day count stays in the ticker's daily line T24 and in the O11/O12 notices.

### 8.1 Variants and entries

| Entry | Variant | Before it | After the pick |
|---|---|---|---|
| First launch (no save), after the N1 hand-off | **first** | N1 → [the hand-off bar] | the pre-tap stage (P0, `ftue.md` §8) |
| After RESET (O10) | first | O10 | the pre-tap stage |
| **After every election** | **after** | O3 → `EVOLVE_TX` → O3b flash (when a beat is due; else straight from `EVOLVE_TX`) | round N+1, live |
| Load with `leaderPickPending` | `evolutions == 0` → first, else after | N0 (O1, if any, is queued **after** the pick) | as above |
| Load of a migrated v3 save | none until the next election (spec §6.3) | — | — |
| The undo chip (§8.6) | the variant of the pick it undoes, **same order** | the stage | as above |

### 8.2 Vertical layout

Screen-logical: `top = top_y` (the safe top), `bot = vs.y − bottom_inset`, `H = bot − top`. Blocks top → bottom; **the header is pinned to the top, the strip and the foot to the bottom** (thumb zone), and the grid is centred in what is left.

| Block | First launch | After an election |
|---|---|---|
| **Header** | The kit `wordmark` (143×29 art = 572×116) when `H ≥ 1280`, else `wordmark_small` (66×16 art = 264×64), centred, at `top + 12`. `LEADER_PICK_TITLE` sits 12 below it, centred (box `pick.title` 656). **Height** `12 + WM + 12 + T + 12`. | `LEADER_PICK_TITLE_AFTER` centred at `top + 12`. Then the **fresh chip** 8 below it: kit `chat_system_pill` 9-slice, 56 tall, width = text + 32 (≤ 592), centred, `LEADER_PICK_FRESH_CHIP` (§8.8). **Height** `12 + T + 8 + 56 + 12`. |
| **Grid** | §8.3, centred vertically in `grid_avail` | same |
| **Caption strip** | Box x 32-688 (656), 2 lines, centred, the reading cut (`PxText.reading`), 12 above and below. **Height** 112 at ×4 (134 at ×5). Its content is set in §8.4. | same |
| **Foot** | 16 (margin) | The **again** button: kit `button_primary`, visual `Rect2(24, bot − 100, 672, 80)`, hit `Rect2(16, bot − 104, 688, 88)`. Its content is a group centred on x 360: the last leader's `avatar24_<art>` at ×2 (48×48) as the leading icon on the right, 16 gap, `LEADER_PICK_AGAIN` "עוד סבב עם {short}" (box `pick.again` 560). **Height** `12 + 88 + 16 = 116`. |

`T` = the title's lines × the line pitch (44 at ×4, 55 at ×5). `grid_avail = H − header − strip − foot`.

### 8.3 The grid

Let `n` be the number of roster leaders whose kit passes `leaderSelect.shipRule`.

| `n` | Form | Columns (screen x, reading order right → left) | Where הפתעה goes |
|---|---|---|---|
| 4 (wave 1: 2 per side) | 2 × 2 leader tiles + the הפתעה bar under them | tile 336 wide: x 368-704, 16-352 (gap 16) | a full-width bar, `Rect2(16, y, 688, 96)` |
| 6 (while wave 2 lands in pairs) | 3 × 3 with the middle row's side cells empty | tile 216 wide: x 488-704, 252-468, 16-232 (gap 20) | the centre cell |
| 8 (launch roster: 4 per side) | 3 × 3 | as above | **the centre cell** |

Row gap: 12. **The centre belongs to no leader**, so the most prominent cell never ranks anyone.

**Tile heights.** `A` is the avatar size and `ts` the text scale.
- 3 × 3 tile: `12 + A + 8 + 1 name line + 2 party lines (pitch 40) + 12` = **156 + A** at ×4.
- 2 × 2 tile: the widest party (248) fits one line in 312, so the tile is **120 + A**.
- **Grid height:** 3 × 3 = `3 · tile + 24`; 2 × 2 = `2 · tile + 12 + 96 + 12`.

**Avatar sizes.** Each is whole device px per sprite px at every k (`display.gd` crisp k). 32 at ×3 is not used: it is 4.5 dp at k 6.

| Size | Sprite | Logical |
|---|---|---|
| L | `avatar_<art>` 32 at ×4 | 128 |
| M | `avatar24_<art>` 24 at ×4 | 96 |
| S | `avatar_<art>` 32 at ×2 | 64 |

**Choice rule** (deterministic; recomputed on relayout, large text or device-scale change):

```
for ts in ([5, 4] if large_text else [4]):          # tile labels at x5 only if the whole grid still fits
    for A in [128, 96, 64]:
        if grid_h(A, ts) <= grid_avail(ts): return (A, ts)
return (64, 4) and the grid scrolls inside grid_avail  # header, strip and foot stay; unreachable on the supported matrix
```

**Resolved** (×4 text, 3 × 3 at `n = 8`; wave 1's 2 × 2 is L everywhere, 616 tall):

| Viewport (CSS) | H | First launch: header / grid_avail / A | After an election: grid_avail / A |
|---|---|---|---|
| 390×844 home-screen app | 1386 | 196 / 1062 / **L** (876) | 1026 / **L** |
| 360×640 Android Chrome | 1280 | 196 / 956 / **L** | 920 / **L** |
| 390×664 Safari (the WhatsApp-link entry) | 1226 | 144 / 954 / **L** | 866 / **M** (780) |
| 375×548 floor | 1052 | 144 / 780 / **M** (780) | 692 / **S** (684) |

Large text at the floor, first launch: at ×5 the header is 155, the strip 134 and `grid_avail` 747. S at ×5 is 777, which does not fit, so the tile labels step down to ×4 and the grid is S at 684. The title and the strip stay ×5 (§0.2, per string).

**Tile internals** (tile-local; 3 × 3 width 216, [2 × 2 width 336]):

| Part | Rect | Content |
|---|---|---|
| Plate | the whole tile. Kit `pick_tile` 9-slice (2D Artist ask, spec §9.2.5); interim: kit `card_row`. | States: idle, pressed, focus, selected (§8.4) |
| Avatar | `A × A`, centred at x `(w − A) / 2`, y 12 | `avatar_<art>` (L, S) or `avatar24_<art>` (M) of `leaders[].art`. **Never** a party logo, a party colour or a bloc colour. |
| Name | box x 12 … w − 12 (192 [312]), y `12 + A + 8`, centred, 1 line | `leaders[].short`, colour `w` #fff8ec |
| Party | same box, y name + 44 (×4) / + 55 (×5), centred, ≤ 2 lines at pitch 40 [1 line] | `leaders[].party`, in the idle-tab label colour #9e99ad (4.9:1 on #1e1636, review). **2D Artist:** confirm ≥ 4.5:1 on the `pick_tile` fill. |
| Hit | the whole tile; the gaps are dead | — |

**Not on a tile** (D27):
- the blurb (it goes to the strip);
- the rule (it goes to the leader card);
- any number, bloc label, bloc colour, "last round" marker or lock.

**The random tile.** In the 3 × 3 centre cell: the same plate, the icon `pick_random` 24 art at ×4 = 96, or ×2 = 48 when A = S (interim: Dubi's `dubi_small_idle` f0, 20×23 art at ×4), centred in the avatar slot, with `LEADER_PICK_RANDOM` in the name line and an empty party line. The **wave-1 bar** holds the icon at ×2 and the label, centred as a group, with the icon on the right.

#### 8.3.1 Order: shuffled, balanced, no left/right cue

1. **When the order is drawn.** It is drawn with a fresh random each time the picker opens from an entry in §8.1 (D10), not from the round seed. **An undo reopen keeps the order** it had, because the player remembers "the one next to him".
2. **Blocs by column.** The leaders are placed by bloc (`leaders[].side`) so that **the right column and the left column hold the same mix of blocs**, and every row with two or more leaders holds both blocs:
   - **2 × 2 (2 + 2):** the blocs sit on the diagonals. A coin flip picks which bloc takes top-right and bottom-left; each bloc's two leaders are shuffled between its two cells.
   - **3 × 3 (4 + 4):** the blocs sit on a checkerboard. A coin flip gives one bloc the 4 corners and the other the 4 edge cells (above, right of, below and left of the centre); each bloc is shuffled within its cells. The right column (corner, edge, corner) then has exactly the left column's mix.
   - **3 + 3:** the 4 corners plus the top and bottom centre. Each side column takes one leader of each bloc, and the top and bottom centre take one of each.
   - **Anything else (an unbalanced roster):** shuffle, and reject any draw where a side column holds one bloc only. **Ask to the Game Designer:** release wave-2 kits in bloc pairs, so this never ships.
3. **הפתעה** has a fixed place (the centre or the bar). It belongs to no leader, and a fixed place keeps it findable.
4. **The last round's leader** shuffles like everyone else; the "again" button is the repeat path.
5. **No bloc is named or coloured** anywhere on the screen. The balance rule is an invariant for the players who know the blocs, not a pattern for anyone to read. (In RTL the right column is read first, and "right-wing on the right" is exactly the cue Bar ruled out.)

### 8.4 Interaction, feedback and the strip

| Input | Result |
|---|---|
| Pointer down on a tile | The pressed state (kit pressed: 1 art px down). The strip shows that tile's `pick.blurb` (הפתעה: `LEADER_PICK_RANDOM_CAP`). No sound. |
| Release on the same tile within 600 ms | **Commit** (below). The release is the pick: pointerup/touchend is the gesture that unlocks WebAudio (iOS needs touchend), so the pick sting sounds on it. |
| Slide off the tile before release | Cancel, and the strip returns to its default. This lets a player press, read the blurb and slide off without picking. |
| Hold ≥ 600 ms, moving < 10 px | Opens the **leader card** (§8.7); the release does not pick |
| Mouse hover (fine pointer) | The focus state; the strip shows the blurb |
| The again button | Commits the last round's leader |
| The title, chip, strip or gaps | Nothing |

**The strip's default line** (nothing pressed, focused or hovered):
- `F9_PICK` on the first picker after election 1 (`ftue.md` LP);
- otherwise `LEADER_PICK_DISCLAIMER` "כולם מקבלים אותו משחק. אף אחד לא מנצח.".

**Commit feedback:**
1. The tile goes to the selected state: kit `pick_tile` selected, a 1-art-px pale rim, which is the non-colour channel.
2. It pops for 120 ms (Animator).
3. Every other tile and the again button fade to 40% over 150 ms.
4. A 250 ms hold.
5. The picker fades out over 250 ms: **≈ 520 ms from commit to stage.**

Input locks on the commit frame (idempotent, like EVOLVE!). The `leaderPick` sting fires on that frame, and it is now **the game's first sound** (Audio Director). Under "בשקט" it follows the SFX setting as every cue does.

### 8.5 Keyboard, focus, reduced motion, large text

| Need | Rule |
|---|---|
| **Initial focus** | First launch: **הפתעה**. No leader starts focused, because a pre-focused face is a default and so a ranking. After an election: the **again** button. |
| Tab / Shift-Tab | Reading order: the tiles right → left, top → bottom (in the 3 × 3 the centre is 5th), then the again button |
| ← / → | The next / previous cell in the row (`mirror`: ← is forward in RTL). ↑ / ↓ move between rows, and ↓ from the bottom row goes to the again button. No wrap. |
| Enter / Space | Commit the focused cell, on key-up, as a release does |
| `I` (physical key, layout-independent) | The leader card of the focused tile |
| Esc | After an election = the again button (same leader). First launch: nothing. |
| Host back | After an election the picker holds **one history entry**, pushed when it opens; `popstate` = again. At first launch it is the root, as the title state was: back leaves the page, and nothing is lost. |
| Focus | The kit focus ring (as elsewhere); the strip shows the focused tile's blurb |
| **Reduced motion** | Static avatars (the tile idle of spec §9.3 is off); no pop and no fades (the selected rim for 250 ms, then a 150 ms cross-fade); Dubi and the leader appear instead of flying and walking; the undo chip has no timer bar |
| **Large text** | Tile labels follow the §8.3 choice rule. The title, chip, strip, again button and undo chip follow §0.2 per string (`LEADER_PICK_FRESH_CHIP`, `F9_PICK` and `LEADER_PICK_UNDO` are `step-down`). Nothing is ellipsised. |
| Colour | Every state has a non-colour channel: pressed = a 1-art-px offset, focus = the ring, selected = the rim + the pop + the dimmed others |
| Screen readers | The canvas is not readable (first-minute §7.3). For a future bridge the tile names are "{short}, {party}". |

### 8.6 After the pick: the name, Dubi, the undo and the bonus

| t from commit | What |
|---|---|
| 0 | Commit. Input locks, the sting plays, and `leader`, `leaderHistory`, `seatDeal`, the fresh-face bonus and `leaderSwitches` are written (spec §6.3). |
| 0.52 s | The picker is gone. The leader walks in to the feet point (≤ 600 ms, Animator; reduced motion: appears). **`Ftue.handoff_ms` is set here**: every FTUE clock starts at the pick, not at the HTML hand-off, so a player reading tiles is never counted as idle. |
| 0.52 s | Toast 1, the round's lower third: `LEADER_PICK_PLATE` "{short} · {party}" (≥ 3 s). **The undo chip appears.** |
| ≈ 0.9 s | Dubi arrives (`fly` / `land`; appears under reduced motion) at the right column, feet (644, S−140), which is free at round start. He says `DUBI_LEARNED` (after הפתעה: `LEADER_PICK_RANDOM_LINE`) for 1.6 s. If this leader has been played before (`leaders[id].taps > 0`), he then says their `pick.line` for 1.6 s; a first-timer's line waits for their first tap (D31, `ftue.md` H1L). |
| ≈ 4.5 s | Toast 2, **on a switch only:** `LEADER_PICK_FRESH` "פנים חדשות: +10% לבסיס בסבב הבחירות הזה" |
| 5.52 s, or the first tap or buy | The undo chip goes |

**What follows:** at first launch the stage is in the **pre-tap state**, the title state without its lines (Rows, ticker, panel and tabs hidden; P0 runs). After an election the HUD is already revealed (the `ui` flags persist), card 1 shows at once (`ftue.md` §4), and the round is live.

**The undo chip:**

| Property | Value |
|---|---|
| Where | Stage-local, at the left end of the Suitcase band: visual `Rect2(16, S−96, 392, 80)`, hit `Rect2(8, S−100, 408, 88)`. It is below the leader's hit and the thermometer's hit (both end at S−140) and under the thermometer's state word (it ends at S−100), and in the thumb zone. |
| Look | Kit `button_secondary`, `LEADER_PICK_UNDO` "להחליף ראש רשימה" centred (box `pick.undo` 352), and a 2-art-px (8 logical) timer bar along the chip's bottom inner edge that drains left → right over `undoSec` (`mirror`, as the buff chip does). Reduced motion: no bar. |
| When | From 0.52 s, for `leaderSelect.pick.undoSec` (5 s) of wall time, only while `runTaps == 0` and nothing has been bought. **After every pick**, not only the first one (D29). |
| Tap / `U` | Reopens `LEADER_PICK` (the same variant and order, with focus on the tile just picked) and reverts the pick: `leader`, the fresh bonus, `leaderSwitches` and the `leaderHistory` append. `seatDeal` keeps its seed (spec L4). The leader walks out (reduced motion: disappears). |
| Blocks | The Suitcase (§4.1 spawn guard) |
| Repeats | Every re-pick gets a new 5 s chip, until the first tap |

### 8.7 The leader card (long-press or `I`)

A modal card over the picker at depth 1, following the partner card's pattern (§6.3): `Rect2(48, y, 624, h)` centred, kit `sheet_modal`, and the card grows.

| Part | Card-local | Content |
|---|---|---|
| ✕ | hit `Rect2(0, 0, 104, 104)` | a11y `SYS_CLOSE` |
| Face | `avatar_<art>` 32 at ×4 = 128², at (464, 32) | — |
| Name | box x 32-448, right-aligned at 448, y 40 (`modal.title`) | `leaders[].name` (the full name) |
| Party | box x 32-448, y 88 | `leaders[].party` |
| Blurb | box x 32-592 (560), y 176, grows (`modal.body`, reading cut) | `pick.blurb` |
| Rule | 16 below: `LEADER_PICK_CARD_RULE` "הכלל המיוחד: {rule}", then `rule.text` (box `pick.card` 560, ≤ 6 lines at ×4; the widest today is 5) | Hidden for a leader without a `rule` (Bibi). **Ask to the Game Designer:** a one-line `rule` for Bibi (the court: postpone, testify, the pardon desk) so every card has the same shape. |
| Button | full width, the stacked rule of §7.1: `Rect2(32, h − 120, 560, 96)` | `LEADER_PICK_CARD_GO` "לשחק בתור {short}", which commits that leader. It says "play as", never "לבחור ב…", which reads as "elect X". |

**Exits:** ✕, the backdrop, Esc or back return to the picker, with focus on that tile.

### 8.8 What carries over, and the +10%

| Carries (the player keeps) | Resets |
|---|---|
| The base (הבסיס), the all-time total, the round count, trophies, the agreement clauses, stats, settings, the album, and the aide drop's −3% | Everything O3 already lists (`ELECT_RESET`), **plus the leader** |

Where the player is told:
- O3's `ELECT_KEEP` / `ELECT_RESET` (unchanged), plus the new `ELECT_LEADER` "{short} · {party}" line under `ELECT_TITLE` (D33);
- `F9_PICK` once, on the first picker after election 1;
- the fresh chip on every after-election picker;
- the fresh toast after a switch.

**Fresh face (D9, +10%, `leaderSelect.pick.freshFaceBasePct`):**
- It applies when the committed leader ≠ `leaderHistory[-1]`. It never applies on a save's first pick (the history is empty) or through "again".
- הפתעה earns it when the draw lands on a different leader, and the toast says so.
- An undo reverts it.

**The chip's place (D28):** the +10% is shown **once, as the chip under the title, never on a tile**. A percent beside a politician's face reads as a poll swing (Bar: no seat numbers as predictions and no ranking). It is also the only number on the picker, and it is a game value, so the blackout rule is unaffected: no seat number appears anywhere on the picker.

---

## 9. HTML surfaces (`game/web/shell.html`)

`<html lang="he" dir="rtl">`. N1: body right-aligned, system font 16 px, line-height 1.5, max-width 358 CSS.

**O8 About** (rev 2026-09-29, review R3): the page is public, so it prints only public text.

| Rule | Value |
|---|---|
| Which facts | only `design/facts.json` facts **without** `notUsed` (44 of 51 today; the 7 with `notUsed` are post-launch, bench-only or dropped) |
| Which text | a Hebrew public field, **`aboutHe`** (the Game Designer writes it: one sentence, the claim as the game uses it, no production notes). Never `text`, which is the English research note ("NOT USED at launch.", "GAP…", "Bench only.", "The joke is on the policy…", "The game never names the reason."). Until a fact has `aboutHe`, it is left out; the build prints the count left out. |
| List | `<ul dir="rtl">`, items right-aligned, bullets on the right; `outlet · date` under the sentence; the link `ABOUT_SOURCE_LINK` "למקור" |
| Link colour | `#9fc3ff` on the page's `#140c24` (10.6:1; the browser default `#0000ee` there, as shipped, is 2.0:1), underlined; visited the same |
| Leaving | `ABOUT_BACK` sticks to the top-left of the viewport (48 CSS tall), not only at the end of a 51-item list; Esc and back close it (already one history entry) | Buttons: one row of two equal halves ≥ 48 CSS tall, **"עם סאונד" right**, **"בשקט" left** with its caption; neither preferred. The hand-off bar fills **right → left**. Numbers in `<bdi dir="ltr">` (or the LRI/PDI already in the strings). Strings with `surface: "html"` are templated into `shell.html` at export, `<noscript>` included.

---

## 10. Thumb zone and touch targets (390×844, CSS y)

| Zone (right hand) | CSS y | Holds |
|---|---|---|
| Easy | 480-810 | Suitcase band, ticker / CTA, cards, tabs |
| OK | 260-480 | Magician, cameo |
| Stretch | < 260, bottom-left | Row A/B (read-only, rare controls, tab shortcuts) |

Hits (logical, floor 88): ⚙ 🔊 cottage 88×88 · Row B 720×88 · Magician 376×416 (304×312) · Suitcase 136×120 · thermometer 120×404 · toast 688×88 · cameo 152×h · date/court chip 176-212×80 → **hit grown to 88 tall** · ticker/CTA 720×88 · card 688×120 · buy-mode 212×104 · tab 180×104 · pay/rejoin pills 352-536×88 · brawl button 336×88 · chat avatar 128×128, name 416×88 · pinned bar 720×88 · chevron 88×88 · ✕ 104×104 · settings rows 672×88+ · modal buttons 256×96 or 544×96. **Rev 4:** pick tile 216×(220-284) or 336×(184-248) · הפתעה bar 688×96 · again 688×88 · undo chip 408×88 · decline pill 352×88 · leader-card ✕ 104×104.

---

## 11. Screenshots the developer should take

1. 390×664: tabs whole, 2 cards, Suitcase band ≥ 20 px clear of the Magician.
2. 375×548 (floor): Magician ×3, `thermo_tube_short`, 1.9 cards.
3. Large text (×5) at 390×664: every key marked `largeText: "step-down"` in `string-budgets.json` falls back to ×4 without truncation.
4. Blackout forced (a dev flag): numeral node absent, baked stamp present, fill still moves.
5. T3 with a run of three Ben Gvir bubbles: one avatar, one name.
6. `LEADER_PICK` at 375×548, first launch and after an election, with 8 tiles: avatar M, then S; nothing clipped; the again button whole.
7. `LEADER_PICK` with large text at 375×548: the tile labels step down to ×4 and the strip stays ×5.
8. Ten opens of the 3 × 3: the right and left columns always hold the same bloc mix, and הפתעה is centred.
9. The press card and chip in Bennett's round: no gavel, no aide button, chip 220 wide, crawl 280.

---

## 12. Deviations from first-minute.md, and the Rev 2 resolutions

| # | first-minute / proposal | This file | Reason |
|---|---|---|---|
| D1 | 44 CSS = 81 logical | floor **88** logical | 81 holds only at 390 wide; at 360 wide 44 CSS = 88 |
| D2 | layout for 844 tall | flex rule §1 | the WhatsApp-link entry opens with toolbars (390×664); the fork cut the tab bar |
| D3 | pill "לקנות · 15 ₪" on one line | pill 46×22 art, verb over price | a one-line pill cannot fit beside a 17-letter name |
| D4 | "×14" between name and pill | **a badge on the plate's bottom-left corner** (`Rect2(572, 72, 104, 44)`, rev of 2026-09-29 width lint) | frees the name line and all of line 2 for late-game yields (308 px) |
| D5 | tab badge top-right (wireframe, kit note) | **top-left** | the trailing corner in RTL |
| D6 | pinned bar 30 CSS, display only | kit 56 visual / 88 hit, the agreement button after round 1 | a home for the fork's perks at depth 2 |
| D8 | — | buy-mode control as list row 0 | the old top tab strip is gone |
| D10 | O3b buttons side by side | stacked | "לסבב הבחירות הבא" does not fit a half button |
| **D11 (F4)** | body text ×3 (engine review U13) | **×4 base, ×5 large text** | one pixel grid with the kit, and a 10.8-CSS glyph body instead of 8.1 for an audience that includes older family-group players. Every budget re-linted at ×4 (0 errors). |
| **D12 (F1)** | gold underline on the active tab | kit plate + pale `rim` underline | gold is reserved for money (style guide §2.2) |
| **D13 (F2)** | chip "27.10 · עוד 29 ימים" | chip "27.10" + calendar icon; the day count lives in the title state and the daily ticker line | at ×4 the two-line chip would cut the crawl to 13 glyphs; the date is the chip's job, the count is a daily beat |
| **D14 (F3)** | 45-glyph receipt lines, ~27 lines | 25 glyphs × 22 lines (`string-budgets.json` receipt boxes): the head wraps, the total joins "החודש", column headers, "(בוטל ב־2013)", the 800-million note and the payment-method line are cut | fits the x5 card. **Counter to the kit's sample:** the disclaimer keeps "או מועמד" (the legal half) and the **URL stays on both cards**, because iOS WhatsApp drops the share text when an image is attached (first-minute §5.1): an image without the URL is a dead end. The sample proofs drop both. |
| **D15 (F5)** | chat avatar 24 CSS | 32×32 art = 128 logical, with run grouping | an 11-art-px face loses the caricature; grouping pays back the height |
| **D16 (Animator)** | crawl 74 px/s snapped to 3 | one art px every 3 frames: 80 logical/s at ×4 | an even step cadence; same glyph rate at ×5 |
| **D17** | court chip on the stage | court chip replaces the date chip in the ticker | follows the kit proof; keeps the stage top (the hat) free of targets |
| **D18** | settings sheet 62%, ticker preview | 70%, sky/hat preview | ×4 content is 1072 px; the ticker was always covered by the sheet |
| **D19 (Animator)** | cameo, Sara, brawl slot, partner card, idle invite: open | §4.2 and §6.3 | answered there |
| **D20 (engine objection, 2026-09-29)** | ticker anchor 160 wide: tag at 700 + a 16×16 Dubi head at (576, 10), crawl 192-552 | the anchor sized from its contents: plate 604-708, the full small Dubi 520-600 (8 px above the row), crawl 192-516 (324) | 88 + 16 + 80 px do not fit in 160; the full-body Dubi is the 2D Artist's shipped art. §5.1 |
| **D21** | large text = ×5 everywhere | ×5 where the filled string fits its box, else ×4 (§0.2) | the build drew ×5 with no step-down: prices ellipsised to "....50K", captions cut, tab labels ran together |
| **D22** | toast text x 32-688 | x 32-676; chat toast = avatar + `TOAST_CHAT_HEAD` + one-line preview | the kit toast's content box ends at 680; the C1 toast shipped with no avatar and no sender |
| **D23** | scrim: unspecified in rtl-map (the fork's grape) | outline `#0b0a12` at 60% (§7.1) | a scrim must darken; grape lifts the dark base |
| **D24** | one court text for both phases | summons and testimony texts (§6.4) | the summons card claimed a slowdown and a testimony timer that had not started |
| **D25** | About lists `facts.json` `text` | only facts without `notUsed`, Hebrew `aboutHe` (§9) | the public page printed English research notes and internal flags |
| **D26** (Bar, leader select) | the title state: wordmark, round + mood, the countdown | `LEADER_PICK` replaces it (§8). The wordmark moves to the picker header; the round and mood line and the countdown are dropped. | Bar: the picker comes before the first tap and replaces the title. At 375×548 the countdown line costs the grid its M avatars; the day count keeps its daily ticker line T24 and the O11/O12 notices. |
| **D27** | spec §3.2: a tile shows the avatar, `short`, `party` **and the blurb** | the blurb is in the caption strip for the pressed, focused or hovered tile (§8.4); the tile shows the avatar, name and party only | At ×4 a blurb is 788-928 px, 5 lines in the 192-px tile box. Nine blurbs would be a wall of text before first agency (first-minute: zero instruction text), and the whole 3 × 3 would not fit 375×548. |
| **D28** | fresh face shown after the pick only (spec §3.3) | also ONE chip under the after-election title, never on a tile (§8.8) | A percent beside a face reads as a poll swing, so the bonus is shown once and attached to no face. |
| **D29** | undo "להחליף", first launch only (spec §3.1) | `LEADER_PICK_UNDO` "להחליף ראש רשימה", after **every** pick, until the first tap (§8.6) | A bare verb at the bottom of the stage does not say what changes. A mis-tap after an election is as likely as on first launch. |
| **D30** | spec §3.1: `EVOLVE_TX` → `LEADER_PICK`; Animator §9.3.4: the swap happens inside `EVOLVE_TX` | `EVOLVE_TX` → O3b flash → `LEADER_PICK`; the walk-out is in `EVOLVE_TX` and the walk-in at the pick (§4.3, §8.6) | The flash is the beat of the leader *just played* (spec §5.10), so it closes that round. The new leader is unknown during the transition, so it cannot walk in there. |
| **D31** | spec §3.3: at the pick Dubi says `dubiLearned` and then the leader's `pick.line` (their firsttap squawk) | at the pick: `DUBI_LEARNED` only; the leader's firsttap squawk waits for their first tap (`ftue.md` H1L). An already-played leader gets `pick.line` at the pick. | The game's first laugh is the squawk *while coins pour* ("אין כלום!" over a coin spray). Spent on a quiet stage it is a line, not a joke. |
| **D32** | spec §9.4: `CHAT_SYS_CREATED` names the leader (`{name}`) | second person: "יצרת את הקבוצה…", "ניקית את הצ׳אט…" | A chat app writes the creator's own line in the second person, and the player *is* this round's leader. It needs no parameter and no gender form, so it is right in today's Bibi-only build and after the picker. |
| **D33** | spec §9.4: `ELECT_TITLE` gains "· {short}" | `ELECT_TITLE` stays; `ELECT_LEADER` "{short} · {party}" is a line under it | "סבב בחירות מס׳ 999 · סמוטריץ׳" is 536 px, over the 432 title box (1 line). `EVOLVE_TX` also uses `ELECT_TITLE`, and there the next leader is not known yet. |
| **D34** | spec §9.4.2: 2 × 3 at wave 1 with the again button as a cell | again is a full-width button in the foot, not a grid cell; הפתעה is the centre cell (3 × 3) or a bar (2 × 2) | The again button is a different action (repeat, no bonus, the Esc/back default) and belongs in the thumb zone. A grid cell would give one leader a second, larger face on the grid. |
| **D35** | spec §10.3: `{name}` / `{verb}` placeholders in shared keys | parameter-free neutral text where it reads well (applied now); new `_LEADER` keys where the leader's noun is the joke; `_NEXT` keys for copy that describes the picker or the lineup art | Today's engine calls these keys without the new parameters, and `Strings.s` leaves an unfilled `{verb}` on screen. Copy about an unshipped feature must not go live. |
