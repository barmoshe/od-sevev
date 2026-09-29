> **Superseded for "עוד סבב" (2026-09-28):** this is the Monkey Bananas v2 record the fork inherited. Implement from rtl-map.md (layout) and ftue.md (prompts). Kept for engine history only.

# hud-layout — Monkey Bananas

Owner: UX Designer. Consumers: Game Developer (implement literally), 2D Artist (piece sizes), Animator (state-change motion).
Canvas: **720×1280 logical px**, portrait, `Scale.FIT`, `pixelArt/roundPixels: true`. **Every coordinate and size below is in logical px and is a multiple of 4.** Rects are written `x,y,w,h` (top-left origin) unless noted. Text positions give the **top-left of the glyph box**. Centred text: `x = floor4((regionW − textW)/2) + regionX`, where `floor4(v) = 4·floor(v/4)`.

## 0. Pixel-font metrics (5×7 glyph, 1-px spacing, uppercase-only)

| Scale | Glyph h | Advance / char | Width of n chars | Line pitch | Use |
|---|---|---|---|---|---|
| ×2 | 14 | 12 | 12n − 2 | 20 | **Tertiary only** (version line). At 0.5× the glyph is 7 CSS px tall, below the legibility floor |
| ×3 | 21 | 18 | 18n − 3 | 28 | **Body minimum** for anything the player must read |
| ×4 | 28 | 24 | 24n − 4 | 36 | Numbers, titles, buttons, normal floaters (feel-spec 28 px) |
| ×6 | 42 | 36 | 36n − 6 | 52 | Crit floater only (see OBJ-3) |
| ×8 | 56 | 48 | 48n − 8 | 72 | Title wordmark fallback |

Rule: **gameplay-critical text is ≥ ×3.** Text drawn over the stage (anything not on a panel) gets a 1-font-px dark outline (see `settings-and-a11y.md` C8). ×3 text sits off the 4-px art grid: 3-px font pixels do not line up with 4-px art pixels. This is accepted for text only; the density is needed to fit 22-character names beside a cost pill.

## 1. Touch-target policy (resolves the 0.5× problem)

- **Every interactive hit area is at least 104×104 logical px.** Visuals may be smaller; the hit area is what gets audited.
- 104 logical = **44 CSS px at scale 0.423**. `Scale.FIT` scale = `min(vw/720, vh/1280)`, so any visible viewport of at least **305 × 542 CSS px** gives ≥ 44 CSS px targets. That covers 320×568 (0.444 → 46 px), 360×640 (0.5 → 52 px), iPhone SE in Safari with toolbars at 375×553 (0.432 → 45 px), and every larger phone.
- Where visuals sit closer together than 104, the hit areas **tile edge-to-edge** with no dead gaps (shop rows use the full 104 pitch, and the tab/toggle hits meet at their midlines). No two hit areas overlap.
- Below scale 0.423 (landscape phones, about 0.25×), targets drop to about 26 CSS px, which is still ≥ WCAG 2.5.8's 24 px. The `ROTATE` hint covers this case (screen-graph).

| Viewport (CSS) | Scale | 104-px target | ×3 glyph height | ×4 glyph height |
|---|---|---|---|---|
| 320×568 | 0.444 | 46 px | 9.3 px | 12.4 px |
| 375×553 (SE + Safari bars) | 0.432 | 45 px | 9.1 px | 12.1 px |
| 360×640 | 0.500 | 52 px | 10.5 px | 14.0 px |
| 390×664 (iPhone 14 Safari) | 0.519 | 54 px | 10.9 px | 14.5 px |
| 412×839 (Pixel 7 Chrome) | 0.572 | 60 px | 12.0 px | 16.0 px |
| 768×1024 (iPad) | 0.800 | 83 px | 16.8 px | 22.4 px |
| 1440×900 (desktop) | 0.703 | 73 px | 14.8 px | 19.7 px |

**Safe area.** `Scale.FIT` letterboxes the canvas, so the canvas never touches a notch or home indicator provided the page does **not** set `viewport-fit=cover`. Required: `<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">` (no `viewport-fit`), and the body background set to the palette's letterbox colour. Inside the canvas, no content comes within 16 px of the canvas edge, and no text within 24 px of it (hit areas may extend to 8 px from the edge). Because of FIT, the whole 720×1280 layout is always fully visible; the smallest-viewport risk is physical size, which the table above covers, never cropping.

## 2. Y-bands

| Band | y range | h | Contents |
|---|---|---|---|
| Top bar | 0–160 | 160 | bank, bps, Thumbs chip, Evolve button, gear (solid panel) |
| Stage | 160–664 | 504 | Big Banana, diorama, Golden, floaters, buff chip and banner (the play field) |
| Ticker | 664–712 | 48 | news ticker (solid panel) |
| Shop | 712–1280 | 568 | tab header 716–820 (hit) and the list viewport 824–1272 (solid panel) |

## 3. ASCII wireframe (1 char ≈ 16 px wide, 1 row ≈ 32 px tall)

```
x: 0        160       320       480       640   720
0  ┌─────────────────────────────────────────────┐
   │[🍌] 123,456             ┌──────────┐ ┌────┐ │  bank ×4 @ (64,28)
   │     4.86K PER SEC ×5    │👍 EVOLVE │ │ ⚙  │ │  bps ×3 @ (64,72); Evolve 384,20 216×96
   │[👍] 12  ×2.2            │▓▓▓░░ 6/10│ └────┘ │  thumbs ×3 @ (64,112); gear hit 608,16 104×104
160├─────────────────────────────────────────────┤
   │ 🚀 🚀 🚀 ⏱ ┌ FRENZY ×5 12S ┐ 🌙 🌙 🌙  │  sky critter row y168; buff chip 184,176 352×48
   │            └▓▓▓▓▓▓▓▓░░░░░░┘             │
   │     ╔══ BANANA FRENZY ×5! ══╗          ✦ │  banner 96,232 528×64 (transient); Golden (✦) anywhere in the safe zone
   │               ┌──────────┐              │
   │               │          │              │  Big Banana sprite 240,296 240×240
   │   ✦           │  BIG     │              │  hit 224,280 272×272
   │               │  BANANA  │              │
   │               │          │              │
   │   🌴 🌴 🐒 👷 🐒 👔 🌴 │  back critter row y536 (feet 600)
   │ 🏰 👔 👷 🐒 🐒 👷 👔 🏰 │  front critter row y584 (feet 648)
664├─────────────────────────────────────────────┤
   │[NEWS] ◄ Troop declares 100 bananas "a lot."   │  ticker text ×3 y676, clip x112–704
712╞═════════════════════════════════════════════╡
   │┌─ PRODUCERS ─┐ ┌ UPGRADES [3] ┐ ┌ BUY ×10 ┐│  tabs 16/272 w248; toggle 536 w168; visual y728–808
820│└─────────────┘ └──────────────┘ └─────────┘│
824│┌───────────────────────────────────────────┐│  row 0 visual y828–924
   ││[icon] INTERN MONKEY          ┌  BUY     ┐ ││  name ×3 (112,+24); pill 520 w168
   ││       OWNED 23               └  1.24K   ┘ ││  line2 ×3 (112,+52)
   │└───────────────────────────────────────────┘│
   │  row 1 y932 · row 2 y1036 · row 3 y1140       ▐│  scroll thumb x708 w4
   │  row 4 y1244 (28-px peek = scroll affordance) ▐│
1272│                                              │
1280└─────────────────────────────────────────────┘
```

## 4. Element table (placement, criticality, update, taxonomy)

Criticality: **C** = critical (the verb or a time-limited decision), **I** = informational (strategy), **P** = peripheral (ambient). Update: **cont** = every frame, **evt** = on change, **low** = rare. Taxonomy (Fagerholt & Lorentzon): D = diegetic, N = non-diegetic, S = spatial, M = meta.

| # | Element | Rect / position | Text | Crit | Update | Tax. | Why this taxonomy (one line) |
|---|---|---|---|---|---|---|---|
| 1 | Top-bar panel | `ui_topbar` 0,0,720,160 (bottom border 152–160) | — | — | static | N | A solid scrim guarantees contrast over any diorama state |
| 1b | Stat window (v1.1) | `ui_chip` (0 normal / 1 Frenzy) **8,8,372,140**. The 9-slice insets (L3 R3 T4 B3 art = 12/12/16/12 px) leave a clear content box of x20–368, y24–136, which contains every stat glyph and icon below | — | — | evt (Frenzy frame swap) | N | A dark window so coloured numerals clear 5.7–9:1 on the pink bar |
| 2 | Bank icon (banana, 16×16 ×2) | 24,24,32,32 | — | I | static | N | Currency glyph; single currency, so the icon is a label only |
| 3 | Bank value | text @ 64,28 | ×4, ≤ 7 chars (≤ 164 w) | I | cont (redraw only when the string changes) | N | The core number of the genre must be readable at a glance, outside the world |
| 4 | bps line | text @ 64,72 | ×3, ≤ 17 chars (≤ 303 w, ends ≤ 368) | I | evt (recompute on buy/buff; the string changes rarely) | N | Strategy number; the Frenzy state adds a gold colour **and** a "×5" suffix |
| 5 | Thumbs chip | icon 24,**104**,32,32 (v1.1: was 108, moved to clear the stat window's bottom inset); text @ 64,112 | ×3, ≤ 13 chars (≤ 231 w) | I | low | N | Meta currency; **hidden until `thumbsOwned ≥ 1`** |
| 6 | Evolve button | visual 384,20,216,96; hit 384,16,216,104 | line1 ×3; line2 ×3 | I | evt | N | Meta decision; states in §6 |
| 7 | Gear (16×16 ×4) | visual 624,36,64,64; hit 608,16,104,104 | — | P | static | N | Low-frequency; a corner is correct for low-criticality chrome |
| 8 | Big Banana | sprite 240,296,240,240; pivot bottom-centre (360,536); hit 224,280,272,272 (sprite + 16 pad) | — | **C** | evt (tap juice) | D | It *is* the button; teaching through the world object |
| 9 | Diorama critters (≤ 24) | slot table §5 | — | P | low (on owned thresholds); 2-frame idle | D | Ambient proof of progress; carries no decision info |
| 10 | Golden Banana | centre in the safe zone §7; hit radius 56 | — | **C** | cont (drift) | D | A world object you catch; time-limited |
| 11 | Floaters "+N" / crit "+N!" | spawn at pointer (Space: banana centre ±24 x); clamp origin to x∈[24,696], y∈[176,648] | ×4 / ×6, outlined | I | evt | S | Anchored to the tap point; spatial ties the reward to the act |
| 12 | Buff chip | 184,176,352,48; text @ 200,184; bar 200,212,320,8 | ×3, ≤ 18 chars | I | cont (bar) | N | Timed state with a text countdown ("12S") so the bar is not the sole channel |
| 13 | Buff banner | 96,232,528,64; text @ centred, y=248 | ×4, ≤ 20 chars | I | evt (1.6 s hold) | N | A one-shot announcement |
| 14 | Frenzy edge glow | full-canvas edge, 8 px inset band inside the stage only (y160–664) | — | P | cont (pulse) | M | Mood, not information; redundant with the chip |
| 15 | Ticker panel + text | panel 0,664,720,48; tag `ui_badge` 16,672,88,32 with "NEWS" ×3 @ 24,676; scroll text ×3 @ y=676, clip rect 112,664,592,48 (v1.1) | ×3 | P | cont (scroll) | M | In-fiction news voice presented as overlay; carries FTUE lines |
| 16 | Shop panel | 0,712,720,568 (top border 712–720) | — | — | static | N | — |
| 17 | Tab PRODUCERS | visual 16,728,248,80; hit 16,716,252,104 | ×3 "PRODUCERS" @ 60,756 | I | evt | N | Facet switch |
| 18 | Tab UPGRADES + badge | visual 272,728,248,80; hit 268,716,260,104; label ×3 @ 300,756; badge 448,752,40,32 with a ×3 digit centred @ y756 (single digit). For the 2-character "9+" it widens to **444,752,48,32** about the same centre x468, so "9+" (33 px) clears the ink ring; the label still ends at 441 | ×3 | I | evt | N | The badge = count of **affordable** upgrades (text number, not a dot) |
| 19 | Buy-mode toggle | visual 536,728,168,80; hit 528,716,184,104; label ×3 centred @ y756 | "BUY ×1" / "BUY ×10" / "BUY MAX" | I | evt | N | **Hidden until any producer owned ≥ 10 or `evolutions ≥ 1`** (persist `ui.buyModeRevealed`) |
| 20 | List viewport | clip 16,824,688,448 | — | — | — | N | 4 full rows + a 28-px peek of row 5 = the scroll affordance |
| 21 | Shop rows | §8 | ×3 | **C** (afford state) | evt | N | The decision surface |
| 22 | Scroll thumb | track 708,824,4,448; thumb height `max(48, 448·448/contentH)` | — | P | evt | N | 100% alpha while dragging or wheeling, 40% within 1 s of idle (peripheral fade) |
| 23 | FTUE pointer hand (16×16 ×4) | per prompt, `ftue-flow.md` | — | I | evt | N | Transient, state-driven |

**Criticality budget per region:** Top bar: 0 C / 4 I (bank, bps, thumbs, evolve) / 1 P. Stage: 2 C (Big Banana, Golden) / 3 I (floaters, chip, banner) / 2 P. Ticker: 1 P. Shop: 1 C (rows) / 3 I (tabs, toggle) / 1 P. Everything is within ≤ 2 C and ≤ 4 I per region.

**Corner defence.** No critical element sits in a corner. The Big Banana is at dead centre of the stage, and shop rows span the full width in the thumb zone. The bank sits top-left because that is the F-pattern entry point, and it is **informational, not critical**: affordability is read from each row's BUY/NEED state, never by comparing the bank with a cost.

**Peripheral fade predicates.**
- Ticker: shows text only while a headline is queued. It is empty between ambient items (`ambientIntervalSec` = 20), leaving only the "NEWS" tag.
- Diorama: changes only on owned thresholds. It is world art rather than overlay, so it is exempt from the fade rule.
- Gear: static chrome, the one allowed constant.
- Scroll thumb: 40% alpha when idle.
- Edge glow: exists only during Frenzy.

**Z-order (low → high).** 0 background · 10 diorama · 20 Big Banana · 25 buff chip and banner · 30 floaters and chips · 50 HUD panels (top bar, ticker, shop) · **60 Golden** (above the ticker it may drift over) · 70 FTUE pointers and callouts · 90 overlay scrim (black, 60%) · 100 overlay panels · 200 `EVOLVE_TX`.

## 5. Diorama: cap and arrangement rule

- **Cap: 24 critters, at most 3 per producer tier.** Slot *n* of a tier appears when `owned[tier] ≥ [1, 10, 25][n]`. The slot-2 threshold (10) is the same number that unlocks that tier's ×2 upgrade, so the new critter and the new upgrade land together.
- Each tier owns fixed slots, so the same critter always stands in the same place (a stable spatial memory). All critters leave on Evolve.
- Critter art is 16×16 at ×4 = 64×64. Positions below are the **top-left**. Feet sit at y+64. The front row draws above the back row.
- 2-frame idle: the phase offset is `slotIndex × (period/8)` so critters never bob in lock-step. The Animator owns the period. Reduced motion freezes every critter on frame 0.

| Row | y | Slot x positions (top-left) |
|---|---|---|
| Sky **S0–S8** | 168 | 40, 112, 184, 256, 328, 400, 472, 544, 616 |
| Back **B0–B6** | 536 | 88, 168, 248, 328, 408, 488, 568 |
| Front **F0–F7** | 584 | 48, 128, 208, 288, 368, 448, 528, 608 |

| Tier | Slot 1 (≥1) | Slot 2 (≥10) | Slot 3 (≥25) |
|---|---|---|---|
| intern | F4 (368,584) | F3 (288,584) | B3 (328,536) |
| tree | B1 (168,536) | B6 (568,536) | B0 (88,536) |
| hardhat | F2 (208,584) | F5 (448,584) | B2 (248,536) |
| bureaucrat | F6 (528,584) | F1 (128,584) | B4 (408,536) |
| catapult | F7 (608,584) | F0 (48,584) | B5 (488,536) |
| rocket | S1 (112,168) | S0 (40,168) | S2 (184,168) |
| timechimp | S4 (328,168) | S3 (256,168) | S5 (400,168) |
| moon | S7 (544,168) | S8 (616,168) | S6 (472,168) |

The first intern lands at F4, directly under the banana (x 368–432), so the player's first purchase appears where they are already looking. The 2D Artist may retune composition **within the same row y and ±16 px of x**; any larger change comes back to UX, because the Golden safe zone and floater clamps assume these rows.

## 6. Evolve button states

| State | Condition | Visual | Line 1 (×3) | Line 2 | Tap |
|---|---|---|---|---|---|
| hidden | `allTimeBananas < 250,000` (and never reached) | nothing; hit disabled | — | — | — |
| revealing | first frame at ≥ 250K | Animator pop-in (reduced motion: 200 ms fade) | — | — | — |
| disabled | `pending < needed`, where `needed = max(10, thumbsOwned)` | **sunken** panel, no drop shadow | thumb icon ×2 @ (416,32) + "EVOLVE" @ (456,36) | progress bar 400,68,184,8 (fill = pending/needed, clamped to 1; fill vs track ≥ 3:1) + ×3 "6/10" centred @ y80 | opens `EVOLUTION` in `preview` |
| enabled | `pending ≥ needed` | **raised** panel with a 4-px drop shadow, a highlight edge, and a slow glint (reduced motion: none) | thumb icon @ (408,32) + "EVOLVE!" @ (448,36) | ×3 "+12" centred @ y80 (bar hidden) | opens `EVOLUTION` in `ready` |

Non-colour channels: raised vs sunken (shape), "!" and the "+N" text (label), and the bar present or absent. The line-2 budget is ≤ 11 chars (≤ 195 px inside 200 px of inner width).

## 7. Golden Banana safe zone

- **Spawn and drift area (Golden centre; fractional feel-spec bounds, so the Golden is exempt from 4-px snapping while it moves):** x ∈ [0.12 W, 0.88 W] = [86, 634]; y ∈ [0.20 H, **0.50 H**] = [256, **640**].
  - The top bound keeps the hit circle (r 56) at y ≥ 200, below the top bar at 160.
  - The bottom bound keeps it at y ≤ 696, above the shop at 712. It may overlap the non-interactive ticker, and it draws above it (z 60).
  - x keeps it ≥ 30 px from the canvas edges.
- **Exclusion:** the centre must be ≥ **0.25 W = 180 px** from the Big Banana centre (360,416). That value keeps the Golden's visual (≤ 84 px, radius 42) clear of the banana sprite on-axis: 120 + 42 < 180.
- **Drift reflects** off the area rectangle **and** off the exclusion circle (reflect the velocity about the circle normal). With 18 px/s × 10 s = 180 px of travel, the Golden can otherwise drift onto the banana.
- **Spawn sampling:** rejection-sample uniformly in the rectangle until the exclusion test passes (at most 20 tries, then use the nearest corner of the rect, (86,256) or (634,256), whichever is farther from the last spawn).
- **Hit-test where the areas overlap (Game Designer rule, adopted):** a tap goes to the Golden only if it lands inside the Golden's drawn 64×64 bounds; otherwise it goes to the Big Banana.
- Accepted in round 2: feel-spec `goldenSpawnYMax` 0.62 → 0.50 and `goldenBigBananaExclusion` 0.20 → 0.25 (both within their declared ranges). See **OBJ-1**. At 0.62 H the hit circle reaches y = 850, over the tabs and row 0, so Golden taps and buy taps would compete.

## 8. Shop rows (both tabs share one template)

Row *k* (0-based) in content space: **visual** `16, 828+104k, 688, 96`; **hit** `16, 824+104k, 688, 104`, clipped to the viewport. The **whole row** is the buy target (Fitts), not only the pill. All offsets below are relative to the row's visual top (`ry`).

| Part | Rect / pos | Text | Budget |
|---|---|---|---|
| Icon plate (v1.1) | `ui_plate` [0–7 producer, 8 upgrade, 9 silhouette] 24, ry+8, 80, 80. It clears the row's 1-art-px ink (x16–20) and its ≤ 2-row bottom lip; the plate itself stays at 100% in both states | — | — |
| Icon (16×16 ×4) | 32, ry+16, 64, 64 (centred on the plate) | — | — |
| Name | @ 112, ry+24 | ×3 | ≤ 22 chars (≤ 393 px, ends ≤ 505; the pill starts at 520) |
| Line 2 | @ 112, ry+52 | ×3 | ≤ 22 chars. Producers: "OWNED 23". Upgrades: effect string (number-and-copy §4) |
| Cost pill | 520, ry+8, 168, 80 | — | — |
| Pill line 1 (verb) | centred in the pill, y = ry+24 | ×3 | ≤ 8 chars (≤ 141 px of 152 inner) |
| Pill line 2 (cost) | centred in the pill, y = ry+52 | ×3 | ≤ 6 chars (≤ 105 px) |

**Can-afford vs can't: five channels, and colour is only one of them.**

| Channel | Can afford | Can't afford |
|---|---|---|
| Pill line 1 (text) | "BUY" · "BUY ×10" · "BUY ×23" (MAX quantity) | "NEED" |
| Pill shape | `ui_pill` frame 0 (raised face, **dark** label) | `ui_pill` frame 1 (sunken well, **white** label). Frame 2 = pressed (buy press state) |
| Icon luminance | 100% | 50% brightness (multiply) |
| Row panel (v1.1) | `ui_panel` 0 / 2 cream / mint, alternating by row index % 2 | `ui_panel` 1 / 3 lilac-grey. **This is a weak channel** (1.15–1.22:1 against the afford fills); the label, bevel and icon carry the state |
| Motion | affordability glint when the state flips (feel-spec; cooldown 5 s; off under reduced motion) | none |

Grayscale test (falsifiable): with saturation at 0, afford and can't must be distinguishable by label and bevel alone.

**MAX mode with 0 affordable:** line 1 "NEED", line 2 = the cost of 1 unit (mechanic rule 4). **×10 mode unaffordable:** "NEED" plus the cost of 10 (the toggle in the header states the quantity). **Upgrades** ignore buy mode: their line 1 is always "BUY" or "NEED".

**Silhouette "???" row** (producers tab, always the last row until all 8 are revealed):
- Icon: the next tier's icon mask filled with a flat dark colour, plus a 1-art-px light outline (≥ 3:1 against the row).
- Name "???", line 2 empty.
- Pill: "NEED" plus the full cost (sunken).
- Tap: can't-afford shake plus the dull SFX (feel-spec). It can never be bought, because reveal (0.5 × cost) always comes before affordability.

**Ordering.**
- Producers: tier order, ascending cost (stable; rows never reorder).
- Upgrades: available upgrades sorted by cost ascending. Stable order, so a row never jumps when it becomes affordable. A bought upgrade is removed and the rows below reflow up (feel-spec `shelfReflowMs`).
- Upgrades empty state: centred ×3 "NO UPGRADES YET" @ y=900 and ×3 "KEEP HARVESTING" @ y=928, both in the viewport.

**Scroll behaviour.**
- Content height = 104 × rowCount. The producers tab has at most 9 rows (936 px, max scroll 488). The upgrades tab has at most 15 rows.
- Drag: vertical drag-scroll. If the pointer moves more than 10 px (feel-spec `buyDragCancelPx`) before release, the pending buy is cancelled and the drag scrolls. Release keeps momentum (velocity × 0.92 per frame, stop at < 0.1 px/frame). Clamp hard at the bounds (no rubber-band). Hold-to-repeat (feel-spec) is also cancelled by a drag over 10 px.
- Mouse wheel: 1 notch = 104 px, eased over 120 ms (reduced motion: instant).
- **No scroll snapping.** Each tab keeps its own scroll position, and switching tabs is instant.
- **Reveal auto-scroll:** when a new producer row (or the silhouette) appears *below* the viewport, **and** no pointer is down in the list, **and** the last list interaction was more than 2 s ago, scroll so the new row's bottom meets the viewport bottom (250 ms ease-out; reduced motion: skip the auto-scroll, since content jumping under a finger is worse than no scroll). Otherwise, do nothing; the tab badge or row peek carries the news.
- The list viewport clips drawing **and** input to 16,824,688,448.

## 9. Text-size summary

| Text | Scale |
|---|---|
| Bank, all modal titles, modal buttons, banner, normal floaters, offline amount, ×multiplier line | ×4 |
| bps, Thumbs chip, Evolve lines, tabs, toggle, row name, row line 2, pill lines, ticker, buff chip, modal body, settings rows, callouts | ×3 |
| Crit floater | ×6 |
| Title wordmark (fallback if the 2D Artist's wordmark is absent) | ×8 |
| Version line only | ×2 |

## 10. TITLE state layout (same scene; HUD, ticker and shop hidden)

| Element | Rect / pos |
|---|---|
| Wordmark region (2D Artist key-art) | 72,56,576,144. Fallback: ×8 "MONKEY" @ (220,64) and "BANANAS" @ (196,136) |
| Tagline ×3 "BUILD A BANANA CIVILIZATION." (28 ch, 501 w) | @ 108,224 |
| Big Banana | same as Main: sprite 240,296,240,240 (so the target never moves between states) |
| CTA ×4 "TAP THE BANANA" (14 ch, 332 w) | @ 192,584. Alpha pulse 100% ↔ 80% at ≤ 1 Hz (reduced motion: static) |
| Hint ×3 "OR PRESS SPACE" (14 ch, 249 w) | @ 232,632. Shown only if `matchMedia('(pointer: fine)')` |
| Footer ×3 "PROGRESS SAVES ON THIS DEVICE" (29 ch, 519 w) | @ 100,1180 |
| Diorama and ground | drawn with no critters |

On start, the title elements fade out and the HUD, ticker and shop fade in. The Animator owns the curves (≤ 300 ms; reduced motion: 150 ms crossfade). The Big Banana never moves.

## 11. Overlay layouts

Scrim: black at 60% alpha over the full canvas. Panels are the 9-slice panel. Inner text width = panel w − 64 (32-px padding): a 624-wide panel gives **560 px = 31 chars ×3 / 23 chars ×4**. Every close ✕ is a 16×16 ×4 glyph with a 104×104 hit.

**SETTINGS**: panel 48,192,624,880 (the fullscreen row exists) or 48,192,624,776 (no fullscreen API).

| Element | Rect / pos |
|---|---|
| Title ×4 "SETTINGS" | @ 264,224 |
| ✕ | visual 592,220,64,64; hit 568,200,104,104 |
| Group label ×3 "SOUND" | @ 80,312 |
| Row SOUND EFFECTS | hit 64,340,592,104 (the **whole row** toggles); label ×3 @ 80,380; toggle visual 496,352,144,80 (= 36×20 art px), text ×3 at y380, **centred inside `SPRITE_META.ui_toggle.labelRegionArtPx[frame]`**: ON region art px 2–18 → "ON" @ x516; OFF region 18–34 → "OFF" @ x572. The same offsets from toggle x apply to every toggle row (+20 / +76) |
| Row MUSIC | hit 64,444,592,104; label @ 80,484; toggle 496,456,144,80 |
| Group label ×3 "ACCESSIBILITY" | @ 80,572 |
| Row REDUCED MOTION | hit 64,600,592,104; label @ 80,640; toggle 496,612,144,80 |
| Group label ×3 "GAME" | @ 80,728 |
| Row FULLSCREEN (only if `document.fullscreenEnabled`) | hit 64,756,592,104; label @ 80,796; toggle 496,768,144,80 |
| Row RESET SAVE | hit 64,860,592,104; label @ 80,900; button visual 496,872,144,80, "RESET" ×3 (destructive style). Without fullscreen: hit 64,756; label @ 80,796; button 496,768 |
| Hint ×3 "KEYS: SPACE = TAP, ESC = MENU" | @ 100,988 (no fullscreen: @ 100,884) |
| Version ×2 | centred @ y1032 (no fullscreen: y928) |

**RESET_CONFIRM**: panel 80,400,560,448, inner 496 px = 27 chars ×3.

| Element | Rect / pos |
|---|---|
| Title ×4 "RESET SAVE?" | @ 228,440 |
| Body ×3 (3 lines) | centred @ y512, 540, 568 |
| Note ×3 | centred @ y616 |
| CANCEL | visual 112,720,232,96; hit 112,716,232,104; ×4 label. **Default focus** |
| RESET | visual 376,720,232,96; hit 376,716,232,104; ×4 label, destructive style (label + colour) |

**EVOLUTION**: panel 48,160,624,952.

| Element | `ready` state | `preview` state |
|---|---|---|
| Title ×4 "EVOLUTION" @ 252,200; ✕ visual 592,176,64,64, hit 568,168,104,104 | same | same |
| ×3 "NEXT SPECIES" centred @ y264 | same | same |
| Species name ×3 (≤ 26 ch) centred @ y296 | `speciesTitles[min(evolutions+1,7)]` | same |
| Thumb icon ×4 + ×4 text, group centred; icon y352–416, text @ y370 | "+12 THUMBS" | "6/10 THUMBS" |
| Progress bar 112,432,496,16 | hidden | fill = pending/needed |
| Label ×3 centred @ y472 | "BANANA BONUS" | "BONUS WHEN READY" |
| Multiplier ×4 centred @ y504 | "×1.0 → ×2.2" = now → after (owned + pending) | "×1.0 → ×2.0" = now → at gate (owned + needed) |
| Divider 80,560,560,4 | | |
| Column heads ×3 @ (80,584) "RESETS" and (376,584) "KEEPS" | | |
| Items ×3 @ y624, 652, 680, 708 (x 80 / 376; ≤ 15 ch per column) | RESETS: BANANAS · PRODUCERS · UPGRADES · ACTIVE BUFFS. KEEPS: THUMBS · ALL-TIME TOTAL · LIFETIME STATS · SETTINGS | same |
| Divider 80,752,560,4 | | |
| Rule ×3 centred @ y776 | "NEED 10 NEW THUMBS TO EVOLVE" | same |
| Rule ×3 @ y812, 840 | "EACH EVOLUTION MUST AT LEAST" / "DOUBLE YOUR THUMBS." | same |
| ×3 centred @ y880 | "THUMBS GROW AS YOU HARVEST." | same |
| BACK: visual 80,984,264,96; hit 80,980,264,104; ×4 | enabled | enabled (**default focus** in preview) |
| EVOLVE!: visual 376,984,264,96; hit 376,980,264,104 | raised, ×4 "EVOLVE!" (**default focus** in ready) | sunken, not interactive, ×3 "NOT READY" |

**OFFLINE**: panel 48,320,624,528.

| Element | Rect / pos |
|---|---|
| Title ×4 "WELCOME BACK!" | @ 204,360 |
| ×3 away line | centred @ y424 |
| ×3 "YOUR TROOP HARVESTED" | centred @ y476 |
| Banana icon 16×16 ×4 + amount ×4, group centred. Cold load: shows "+0" until COLLECT, then rolls 0 → award over 800 ms. In-session return: rolls on open (screen-graph §5) | icon y520–584; text @ y538 |
| Note ×3 (2 lines) | centred @ y624, 652 |
| COLLECT | visual 212,720,296,96; hit 212,716,296,104; ×4. **Default focus** |

**EVOLVE_TX card** (full canvas):
- Background: white. Under reduced motion it is a 200 ms crossfade to the palette's darkest panel colour instead of a flash to white.
- ×3 "YOUR TROOP EVOLVED INTO" centred @ y588; species ×4 (≤ 26 ch, ≤ 620 w) centred @ y628.
- Text colour ≥ 4.5:1 against the card.

## 12. Sprite map (2D Artist ids; v1.1 additions at the end)

Label rule (v1.1, style-guide §11.7): **every control label is ink `k`**, except the Evolve-ready label (`w` on grape). The v1.0 rule "white on sunken wells" is retired. Colours are wired through `UI_THEME` in `art/sprites.ts`.

| UI part in this spec | Sprite id / frame |
|---|---|
| Shop row panel (can afford / can't) | `ui_panel` 0 / 1 |
| Cost pill (BUY / NEED / pressed) | `ui_pill` 0 / 1 / 2 |
| Tabs (selected raised / unselected sunken) | `ui_tab` |
| Settings ON/OFF toggle | `ui_toggle` |
| RESET buttons (settings row and confirm) | `ui_button_danger` |
| Progress bars (Evolve button, Evolution overlay, buff chip) | `ui_bar_track` + `ui_bar_fill` |
| UPGRADES count badge, Evolve "!" badge | `ui_badge` |
| Keyboard focus ring | `ui_focus` |
| "???" silhouette icon | `sil_<producerId>` |
| Gear | `ui_gear16` (×4) |
| Close ✕ | `ui_close16` (×4) |
| FTUE hand | `ui_pointer` 0 (up) / 1 (up-left), per the ftue-flow §5 table |
| Top bar / stat window | `ui_topbar` 0 / `ui_chip` 0 normal, 1 Frenzy |
| Ticker panel **and** both occluders | `ui_ticker` 0 |
| Shop tray | `ui_tray` 0 |
| Modal cards | `ui_card` 0 over a `U` @ 0.6 scrim |
| Buff banner | `ui_banner` 0 |
| Icon plates | `ui_plate` 0–9 |
| Evolve ready / EVOLUTION confirm | `ui_button_evolve` 0/1/2 (not-ready = `ui_button` 2) |
| Primary buttons (COLLECT, CANCEL, BACK, buy mode) | `ui_button` 0/1/2/3 |
| NEWS tag | `ui_badge` (capsule) |
