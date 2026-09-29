# "עוד סבב": style guide v2 (the approved detailed look + the UI kit)

**Artifact:** `style-guide` (+ `ui-artwork`, `wordmark`, `key-art`). **Owner:** 2D Artist.
**Status:** v2, supersedes the creative-pack v1 where they differ. Bar approved the look (the cast in
`creative-pack/od-sevev/art/showcase/out/`); v2 codifies it and adds the UI.
**Consumers:** Technical Artist, Game Developer, UX Designer, Animator, Audio Director (key-art pairing).
**v1:** `gamestudio/output/artifacts/creative-pack/od-sevev/art/style-guide.md`. Sections v2 does not
restate stay in force from there (lineage §1, caricature grid §7, era moods §8).

**Rebuild everything:** `cd art/od-sevev/src && python3 build_all.py`. That writes every PNG at 1x,
`ui-kit.json`, the key art and every proof. Every rule below is executable in `src/`.

| Deliverable | File |
|---|---|
| UI kit, 209 pieces (wave 1: 89, wave 2: 96, wave 3: 6, wave 4: 6 Dubi strips, wave 5: 5 + the 15 spin icons redrawn, wave 6: 7 + `icon_close` redrawn), 1x art px | `out/ui/<group>/*.png` (groups: chat, controls, meters, widgets, events, props, share, key; wave 2: sheet, ticker, cards, spins, trophies, ftue, stage, ceremony) |
| 9-slice / frame / pivot manifest | `ui-kit.json` |
| Wordmark (rim, no rim, mono, small) | `out/ui/key/wordmark*.png` |
| App icon 1024 + 60 | `out/key/icon-1024.png`, `out/key/icon-60.png` (source `icon-64-art.png`) |
| OG image 1200x630 | `out/key/og-1200x630.jpg` (115 KB, WhatsApp needs ≤ 300 KB) + `.png` |
| Graphic-tier palette | `out/palette-v2.gpl`, `out/palette-v2.png`, source `src/palette.py` |
| Proofs | `proofs/` (see §15) |

---

## 0. Principles (v2)

1. **One stage, one star.** Unchanged. The Magician is the most detailed, most saturated thing on screen.
   UI chrome is flatter than any character and never out-renders him.
2. **Two tiers, one outline.** The cast is painterly and dense; the graphic tier (UI, wordmark, props I
   draw) is flat and clean. What ties them together is the **near-black outline** on everything and the
   **pale rim** on what you touch (§3).
3. **Colour means something.** The v1 reservations stand and are extended to the UI (§2.2):
   maroon = the Suitcase, gold = money, flag blue = the Magician and *the* primary button. v2 adds:
   violet = bureaucracy (stamps), red = danger, and it always travels with a shape.
4. **Hebrew first, RTL always.** Fills grow from the right, icons lead on the right, tails point right
   for incoming speech. In-art text is our pixel cut; verify it by ASCII visual order, never by eye.
5. **Every state is a shape.** No UI state is carried by colour alone (§11.3).

## 1. The two tiers

| | **Cast tier** | **Graphic tier** |
|---|---|---|
| What | The Magician, partners, opposition, Dubi, critters, photobombers | UI kit, wordmark, icons, the Suitcase, stamps, stages, props with text |
| Made by | ChatGPT reference → `showcase/src/rig.py` render-down (orchestrator + Bar) | Hand-authored char-grids and primitives in `art/od-sevev/src/` |
| Height | 96 art px (the partner idle); avatars 32x32 | Per piece, on the 1x grid |
| Palette | **One locked palette per character**, ≤ 48 colours (measured 44-57 incl. props), locked from the rest pose so frames never flicker | The **62-swatch graphic palette** (§2); nothing off-list |
| Rendering | Dense painterly shading from the ref, no dithering added | 3-band cel (light / base / shadow) + an extra glint or deep band where it earns it (§4) |
| Outline | Near-black, from the ref (measured `#000000`–`#0e0f13`) | `outline` `#0b0a12`, 1 art px |
| Rim | Pale `#d6ccec` on the Magician and his props | `rim` `#d6ccec` on stage-touchables (§3) |

- **Rule:** a thing goes to the cast tier when its read is a *face or a body*; it stays graphic when its
  read is a *shape, a word or a number*. That is why the Suitcase (read: a 4-letter sticker) is hand-drawn
  and Dubi (read: a parrot's face) is a ChatGPT request.
- **Never mix pixel scales in one frame.** One integer scale per image (x4 in game, x5 on share cards and
  OG, x16 on the icon). The cast pastes 1:1 onto every one of them.

## 2. Palette (graphic tier)

- **62 swatches in 19 families** = v1's 45 unchanged + 17 v2 additions. Well inside the ≤ 24-family cap.
- Source: `src/palette.py`; export `out/palette-v2.gpl` / `.png`. v1's table (§2 there) still describes
  the first 45.

### 2.1 v2 additions

| Swatch | Hex | Role |
|---|---|---|
| `outline` | `#0b0a12` | Outer silhouette of every graphic-tier sprite and UI piece. Matches the cast's near-black. `ink` (`#1b1426`) stays for inner lines and text. **Also the modal scrim** at 60% engine alpha (§11.2). |
| `rim` | `#d6ccec` | The pale 1 px rim outside the outline on stage-touchables (§3). Same value the cast's hat/rabbit use. |
| `ui_scrim` | `#140c24` | HUD row A (UX's scrim), meter wells, the deepest UI surface |
| `ui_panel` | `#1e1636` | Panels, header, tab bar, card bodies |
| `ui_bubble` | `#2e2250` | Incoming chat bubble (UX value), secondary button, cards |
| `ui_bub_hi` | `#4a3c7c` | Top/left bevel light on the two above |
| `ui_out` / `ui_out_hi` | `#4a3a10` / `#72601f` | The player's own bubble (UX: dark gold, because the player pays) and its bevel |
| `gold_dk` | `#7d5412` | Gold lip; the dim "not payable yet" fill (white on it 6.1:1) |
| `flag_dk` | `#00237a` | Primary-button lip and pressed face. Reserved with `flag`. |
| `red_hi` / `red_dk` | `#f86b5d` / `#8f1d22` | Danger light plane (and the "אולטימטום" label, 5.0:1) / danger shadow. `red_dk` is hue 357, never used on a case shape, so it can't read as maroon. |
| `stamp` / `stamp_lt` | `#5b3b9e` / `#b9a0ef` | Rubber-stamp ink on paper / on dark surfaces |
| `receipt`, `receipt_sh`, `receipt_ink` | `#f4f1e8`, `#d8d1bf`, `#1a1a1a` | Thermal receipt (UX 5.1 values, 15.4:1). `receipt_ink` is used on the receipt only. |

### 2.2 Reservations (v1 + v2; a violation fails review)

| Swatch | Reserved for | In the UI this means |
|---|---|---|
| `maroon`, `maroon_dk` | The Suitcase (**+ one waiver:** the Qatari aides' folder, source `qatari`, orchestrator decision 2026-09-29: maroon is Qatar's colour, the same Qatar thread as the DOHA Suitcase, so it reinforces the joke. The waiver covers that folder only; it is a folder, never a case shape, and never catchable) | No maroon UI, rings, badges or tints. **Open flag:** the showcase avatars `ben-gvir_avatar` and `gotliv_avatar` have a maroon ring (`build.py` 'jab' ring `(138,21,56)`); recolour it to `red` `#d02a36` (§16). |
| `gold` ramp | Money, reward moments, the wordmark | Pay pills, the price pill, the "עוד סבב!" button, the ≥ 61 seats frame, the transfer banner (it is about money: "כולל דמי אחזקה"). **Not** tab underlines, focus rings or decoration. |
| `flag` (+ `flag_dk`) | The Magician's tie/pin, Dubi's tie, THE primary button | One `button_primary` per screen. Seats use `sky`, never `flag`. |
| `navy_hi` | The Magician's suit light plane | Not used anywhere in the UI. |
| `stamp` violet | Bureaucracy (v2) | Stamps, the pinned-bar edge, the pin head, the "filed" mark on the תיקים icon. |
| `red` ramp | Danger | Ultimatum, thermometer, court tint, count badge, "מבזק" plate. Always paired with a shape (hatch, clock, icon, number). |

## 3. Outline and rim (v2)

- **Outline:** exactly 1 art px of `outline` around every graphic-tier silhouette. UI pieces draw it
  *inside* their bounds (`kit.outline_inplace`), so a piece's PNG size is its visual size.
- **Inner lines:** the local shadow swatch, never `outline` (the v1 rule). Exceptions: text, icons at
  ≤ 15 px (their 1 px strokes may be ink or `outline`), the hazard hatch.
- **Rim:** a 1 px `rim` ring *outside* the outline marks **things the player touches on the stage**:
  the Magician (baked in the cast render-down), his hat and rabbit (they ride with him), **the Suitcase**.
  - v1 said "the catch rim = catchable only". The approved cast put the same rim on the Magician and his
    props, so v2 widens it to "on-stage touchables". Decorative props (the departure board, the cottage
    cup, the brawl) never get it. UI chrome never gets it (it has its own pressable language, §11.3).
  - The Suitcase's edge with the rim: ≥ 8:1 on every stage (maroon alone is 1.3-1.6:1 on night/plum/teal).
- **No anti-aliasing, no semi-transparent pixels.** Alpha is 0 or 255 in every PNG here. Opacity effects
  (UX's 60% chip, the 50% cup) are engine alpha on the node, not baked.

## 4. Rendering level (graphic tier)

- **Three bands**, key light top-left: light plane (top and left edges), base, shadow (bottom and right
  edges). A fourth band only where it earns it: a `white` glint on gold, metal and glass; a deep band on
  the wordmark extrusion.
- **Bevel grammar for UI:** 1 px light top+left, 1 px dark bottom+right. A **2-row lip** under a face
  means "raised, pressable". An **inner shadow** (dark top row) means "sunk".
- **Dithering:** a 50% checker only on soft glows (card backgrounds, the icon's spot field). Never on UI
  controls, never on text plates.
- **Texture:** stamps get ink speckle (alpha holes, ~10% on the border, ~3.5% in the text) and one
  ink-starved corner. That is the only "texture" in the UI.

## 5. The cast (render-down tier)

- Approved and locked: `showcase/out/` (Bibi, Sara, Bennett, Ben Gvir, Deri, Goldknopf, Gotliv, Levin,
  Regev + avatars, props, four stages). Frame data in `showcase/out/atlas.json`.
- Every new character or critter comes through `asset-requests/REQUESTS.md` in the same style: satirical
  full-body caricature, slightly big head, transparent background, no logos, no text.
- v1 §7's caricature rules still bind the *prompts*: 2-3 traits, never faith or body as the joke, kippot
  and beards drawn as individual traits, one skin approach for everyone, the public drawn sympathetically.
- Red lines (brief): no party logos or party colours as emblems, no state emblem or Knesset Menorah, no
  uniforms, no children.

## 6. Stages

- The four approved stages are `showcase/out/stage_*.png` (180x320), built from v1 `locations.py`.
  v1 §8 (skeleton bands, the empty slot at x 66-114 / y 150-216, the follow-spot, "never draw") stands.
- The departure board (§12.5) is a stage-background prop; place it in a landmark band, never in the slot.

## 7. Hebrew pixel text ("Sevev 5x9")

- The cut is v1's (`src/hebfont.py`): 5x9 cell, advance = width + 1, line height 11 (10 in tight UI).
  v2 adds `*` (raised footnote star, for the receipt) and fixes the proof bidi so `58/61`, `+38` and
  `27.10` stay whole. The **engine does real bidi** (Godot TextServer; UX 3.5); `visual_order()` is for
  proofs only.
- **Capacity at x4 in the 720 canvas:** a full-width 180 art px line holds **28 glyphs** (6 px advance);
  a 176 px card, **27**; a chat bubble text column (104 px), **17**; the receipt's print column (152 px on
  the x5 card), **25**. Every 9-slice here grows vertically, so long strings **wrap** rather than shrink.
- **Readability measured** (`proofs/phone-390css-read.png`): at 390 CSS px the body is ~11 CSS px tall:
  fine for labels, chat, the ticker, card lines.
- Label colours and their contrast: §11.4.

## 8. The wordmark "עוד סבב" (v2)

- **Construction:** custom lettering on a parametric Hebrew block skeleton (`src/letters.py`): cap 22 art
  px, stroke 4. The letter logic is the UI cut's (ב's tail sticks out right, ד's roof overhangs right,
  ע's base kicks left, ס has a square top-left). The same skeleton sets the event banners (cap 11,
  stroke 2), so title and events are one family.
- **Treatment (the detailed look):** `gold_hi` on top/left stroke edges, `gold` body, `gold_sh` on
  bottom/right edges, a `white` glint at each stroke's top-left corner, a 3 px extrusion down-right
  (`orange_sh` near, `wood_dk` far), a 1 px `outline`, and a 1 px `rim`.
- **Sizes:** `wordmark.png` 143x29 (x4 = 572x116 logical: sits in the title band with 74 px margins);
  `wordmark_small` 66x16 (share cards); `wordmark_norim` for light grounds; `wordmark_mono` for the
  one-colour test (it holds).
- **Rejected (v1, still rejected):** the loop arrowhead on the ס. The "again" loop lives on the icon.

## 9. Icon and OG image

**Icon** (`out/key/icon-1024.png`, 64x64 art x16; `icon-60.png` is the real LANCZOS downsample):
- **What:** the approved Magician (idle frame 0, pasted 1:1: finger up, the top hat spinning on it)
  inside one clockwise gold "again" loop, on a plum stage with a follow-spot.
- **Why this replaced v1's ballot box + hat:** the approved cast *is* the brand now. The face reads at
  60 px and still at 29 px (`proofs/icon-60-zoomed.png`, `icon-29-zoomed.png`), and the loop keeps "עוד
  סבב" in a textless mark. The election signifier moves to the wordmark and the title copy
  ("סבב בחירות"), where it is words, not a glyph.
- **Safe area:** everything load-bearing (face, hat, loop arrowhead) inside the central ~85%. Opaque,
  square, no rounded corners (the OS masks).
- **Excluded:** flags, emblems, party colours, ballot slips with letters.

**OG** (`out/key/og-1200x630.jpg`, 240x126 art x5):
- The wordmark over a curtained stage, the Magician in the TAP pose with the hat high and shekels and
  a bill leaping out, the DOHA Suitcase flying through upper-left with a rim-coloured speed trail. It
  matches UX's `og:image:alt`.
- **Square-crop safe:** the wordmark, the Magician and the Suitcase all sit inside the centre 630x630
  (`proofs/og-square-crop-200.png`).

## 10. Do / don't (v2 additions to v1 §11)

| # | DO | DON'T |
|---|---|---|
| 7 | Seats fill in `sky`, growing from the right | A `flag`-blue or gold seats bar (steals the Magician's colour or money's) |
| 8 | Stamps in violet, axis-aligned, with speckle | Red stamps (reads as danger), or a rotated stamp (smears the pixels) |
| 9 | The active tab = raised plate + pale underline + white label + the only coloured icon | A gold underline (gold = money) |
| 10 | Can't-afford = a sunken well with a dim gold fill and a white label | The same raised pill in grey (colour-only state change) |
| 11 | Hand-draw anything whose read is a word or a number (the Suitcase's DOHA) | Render-down a sticker at 24 px |
| 12 | A long string wraps inside a taller 9-slice | Shrinking the font, or a second pixel scale for text |

## 11. UI: the kit

### 11.1 Grid, scale and files

- **1 art px = 4 logical px** in the 720x1280 game (180x320 art). Every PNG in `out/ui/` is 1x. The
  engine scales x4 with nearest filtering, snapped to the 4-px grid.
- **9-slice:** `ui-kit.json` gives `slice = [left, top, right, bottom]` in art px = Godot NinePatchRect
  `patch_margin_*` (x4 if the node isn't itself scaled), `mode` = `stretch` or `tile` (`axis_stretch`
  STRETCH / TILE_FIT), `content` = the text-safe box, `label` = the label swatch that clears 4.5:1.
  `proofs/kit-*.png` shows each piece at 1x and stretched, rendered with the same 9-slice math.
- **Multi-frame pieces** are horizontal strips with `frames` + `frameW` (the cast's `atlas.json`
  convention). **States** are separate files, `<id>_<state>.png`.
- **Hit areas are not art.** A visual may be smaller than its hit area; UX's hit sizes stand
  (44 CSS = 20 art px).

### 11.2 Surfaces

| Surface | Swatch | Used by |
|---|---|---|
| Deepest (wells, row A) | `ui_scrim` | Meter wells, HUD row A/B, the pinned bar, the composer well |
| Panel | `ui_panel` | Header, tab bar, ticker, transfer card, countdown chip |
| Raised | `ui_bubble` + `ui_bub_hi` bevel | Incoming bubbles, cards, secondary buttons, the active tab |
| Player's | `ui_out` + `ui_out_hi` | The player's bubbles only |
| Neutral system | `suit_dk` + `suit` | System pills; every *disabled* control |
| Court | `wood` frame + `teal_dk` body + a steady `red` inner line | The court card and chip |
| **Modal scrim** (engine, not art) | `outline` `#0b0a12` at **60%** node alpha (UX R15, rtl-map §7.1 D23). Never the fork's grape `#3a1e72`: a scrim only darkens, and grape at 60% lifts `ui_scrim` to `#2b1753` (fog). | Under every modal, sheet and card overlay; the shop's can't-afford dim and the spin tag plate share the swatch (`uiTheme.scrim`) |

### 11.3 State language (every state is a shape)

| State | Shape | Colour | Label |
|---|---|---|---|
| default / payable | Raised: light bevel + 2-row lip | Variant face | Variant label |
| pressed | Face drops 2 px into the lip; inner shadow on top | Darker face | Moves +2 px with the face |
| disabled | Sunk, flat, no light bevel | `suit_dk` for every variant | `grey` (5.5:1) |
| can't afford (pills) | Sunken well; a dim gold fill grows from the right | `ui_scrim` + `gold_dk` | White "חסר {n} ₪" |
| ultimatum | A 3 px red/black hazard band around the bubble | Red | "אולטימטום" + the clock chip |
| paid | The pill is replaced by a stamp impression | Violet | "שולם" |
| active tab | Raised plate + 2 px pale underline; the only coloured icon | `ui_bubble` + `rim` | White (idle: grey, dimmed icon) |
| ≥ 61 seats | A 4 px gold ring outside the bar | Gold | The numeral |

The grayscale proof (`proofs/cvd-deut-prot-and-squint-x2.png`, right two panels) is the falsification
test: every row above stays distinguishable with colour removed.

### 11.4 Label contrast (all pass; `proofs/contrast-table.md` is regenerated by the build)

| Label on surface | Contrast |
|---|---|
| `white` on `ui_bubble` / `ui_out` / `ui_panel` / `ui_scrim` | 13.1 / 10.0 / 15.6 / 17.3:1 |
| `white` on `flag` / `flag_dk` / `red` / `teal_dk` / `wood` / `gold_dk` | 8.5 / 12.6 / 4.7 / 11.1 / 5.5 / 6.1:1 |
| `ink` on `gold` / `gold_sh` (pressed) | 11.0 / 6.0:1 |
| `grey` on `suit_dk` / `ui_scrim` | 5.5 / 8.1:1 |
| `stamp` on paper / receipt; `stamp_lt` on `ui_bubble` / `ui_out` / `ui_scrim` | 5.6 / 7.3; 6.4 / 4.9 / 8.4:1 |
| `red_hi` ("אולטימטום") on `ui_bubble` | 5.0:1 |
| Non-text (≥ 3:1): seats fill `sky` vs its well; thermometer `red` vs its well / the hatch's black | 7.9; 3.7 / 3.8:1 |
| `white` on `red_dk` (`button_danger` pressed); the ✕ `white` on `ui_bub_hi` | 8.1; 8.6:1 |
| **On the scrim** (outline at 60% takes `ui_scrim` to `#0f0b19`, the brightest possible ground `#ffffff` to `#6d6c71`): white text on the scrimmed dark / the scrimmed brightest ground; the spin tag plate (scrim at 85% on `ui_bubble` = `#100e1b`) under white; the fork's cream card vs the scrimmed dark | 17.7 / 4.7; 17.4; 17.8:1 |
| Edges on the scrim (non-text): the dark sheet body `ui_panel` / title band `ui_bubble` / its `ui_bub_hi` bevel vs the scrimmed dark ground | 1.1 / 1.4 / 2.1:1 (**open**, §16 F9) |

### 11.5 Icons

- **Shop icons 24x24** (money sources and, since wave 5, spins): they fill `card_plate` (26x26) edge to edge.
  Spins are built from outlined parts back to front (`src/icons24.py`), no rim (UI, not a stage touchable).
- **Tab icons 15x15** (active + idle): מקורות = a faucet dripping a shekel (what you tap); ספינים = Dubi's
  microphone broadcasting two pink arcs; קואליציה = a chat bubble that says 61; תיקים = a manila case file
  with a violet "filed" mark. Four different silhouettes, four different dominant hues; idle collapses
  to a 3-step slate ramp.
- **9x9 inline icons** (one text cell tall): lock, pin, mute, chevron, clock (4 hand states), calendar,
  gavel, trash (wave 6). UX's 🔒 📌 ⏱ are these, never emoji.
- **11x11 meter icons:** magnifier (< 75% suspicion) → gavel (≥ 75% and the court card).
- **The ✕ (16x16, wave 6):** one round ✕ for every card, sheet and modal (`icon_close`, drawn x4 = the 64x64 visual of
  rtl-map §7.1). Its silhouette and ✕ are the modals' round ✕ pixel for pixel, in kit swatches: `rim`-lit top arc,
  `ui_bub_hi` face, `ui_bubble` shadow, `white` ✕ (8.6:1). The face is one step above `ui_bubble`, so it holds on a
  title band as well as on the court card's wood, the dark sheet body and a cream card.

### 11.6 Piece reference (the full table with every margin is `ui-kit.json`)

| Group | Pieces | Notes |
|---|---|---|
| **chat** | `chat_bubble_in` [3,6,8,3], `chat_bubble_out` [8,6,3,3], `chat_bubble_ultimatum` [8,8,13,8] tile, `chat_system_pill` [4,3,4,3], `chat_header` 180x26, `chat_pinned` 180x14, `chat_composer_disabled` 180x22, `pay_pill_default` / `_pressed` / `_track` 24x17, `pay_pill_fill`, `icon_clock` x4, `chat_icon_*` | Square-cornered, no WhatsApp green, no ticks (UX 4.3). Tails sit in the corner patch, so they never stretch. The pay pill ships at 78x17 (UX 170x36 CSS). |
| **controls** | `button_{primary,secondary,gold,danger}_{default,pressed,disabled}` 24x20 [3,3,3,4] / [3,5,3,2], `tabbar` 180x26, `tab_active` 45x26, `badge_count` 11x11, `tabicon_*`, `card_row` / `card_row_locked` 32x30 [4,4,4,4], `card_plate` 26x26 | Buttons at 20 art px tall = 80 logical = the 44 CSS target. |
| **meters** | `seats_track` [2,2,2,2] (ship 106x9), `seats_fill`, `seats_tick`, `seats_goal_frame` [5,5,5,5]; `thermo_tube` 14x88 (+ `liquid` box), `thermo_fill`, `thermo_meniscus`, `thermo_floor_hatch` (tile), `thermo_icon_*`, `thermo_bubble` x3; `chip_countdown`, `chip_ultimatum` [4,3,13,3], `chip_icon_calendar` | Seats: horizontal, from the right, a notch every 10. Suspicion: vertical, bottom-up, the carried-over floor as red/black hatch. Two different shapes on purpose. |
| **widgets** | `cottage_cup` 16x18 x8, `cottage_pixel`, `depboard` 72x48 x4 | §12 |
| **events** | `stamp_tool_up/down`, `stamp_{pardon,postponed,paid,blackout}_{paper,dark}`, `stamp_frame_{paper,dark}` (tile), `brawl_cloud` 52x40 x4, `transfer_banner` 180x30, `transfer_card`, `court_frame` 40x36 [6,20,6,6], `chip_court`, `chip_icon_gavel` | §12 |
| **props** | `suitcase` 26x20 (24x18 + rim), `suitcase_norim`, `dubi_placeholder_avatar` 32x32, `dubi_placeholder_body` 64x100 | The Dubi placeholders are grey and dashed on purpose: they must never ship looking finished. |
| **share** | `share_receipt_bg` / `share_result_frame` 216x270 (x5 = 1080x1350), `receipt_top` / `_body` / `_bottom` / `_rule`, `stamp_camera` | §13 |
| **key** | `wordmark`, `wordmark_norim`, `wordmark_mono`, `wordmark_small` | §8 |

## 12. Widgets and events

1. **Cottage Index cup** (16x18, **13 states** since wave 2). A white tub, a blue band (no brand, no text), lumpy curds
   with their own shadows ("cottage", not yoghurt), a foil lid leaning back. Frame *k* = the *k*-th x10
   of lifetime treasury (1,000 ₪ … 10^14 ₪). Cumulative missing pixels **0, 1, 3, 6, 10, 16, 24, 34, 46,
   62, 82, 106** of 131, then frame 12 = every pixel gone, drawn as a dotted `slate` ghost of the outline
   (trophy "מדד הקוטג׳: 0"). Frame 1 loses exactly **one** pixel, in the dead centre of the white tub, so the
   ticker line "הקוטג' איבד פיקסל" is literally true; then it inflates. Holes are true alpha.
2. **Ben Gurion departures** (72x48, 4 frames = 0-3 departures shown). A split-flap board, header
   "המראות" with a plane, amber (`orange`, never gold) destinations ליסבון · ברלין · אתונה with times and
   a lit lamp. Cities, never people: the joke is on the policy.
3. **Stamps.** Violet, axis-aligned, double border, speckled. Baked: "נדרשים מסמכים / נוספים" (pardon),
   "נדחה" (court), "שולם" (chat), "חסוי עד 27.10" (row B blackout), each in a paper ink and a dark-surface
   ink. The other seven pardon lines use `stamp_frame_*` + engine text in the same ink. The rubber stamp
   itself has two key poses (up / down); its motion is the Animator's.
4. **Brawl** (52x40, 4-frame loop). A dust cloud of shaded puffs with suit sleeves, fists and shoes
   ray-cast out of its edge, a flying page and an impact star. No faces, no kippot, no weapons. Frame 0
   is the reduced-motion still.
5. **"חלון העברות"** (180x30). A black broadcast strip, gold display lettering from the wordmark's
   skeleton, gold speed-stripes at both ends; `transfer_card` under it for the name and
   "{from} ← {to} · כולל דמי אחזקה".
6. **Court day.** A wooden-framed card with a teal body and a steady red inner line (no strobe, UX), a
   header plate for "יום משפט" + the gavel; `chip_court` for the collapsed state.

## 13. Share cards

- **Grid:** 216x270 art at **x5** = exactly 1080x1350. One pixel grid per card, like the game. The cast
  pastes 1:1. The key content stays inside y 27-242 (the 1080x1080 square).
- **Receipt:** thermal paper (`receipt` / `receipt_ink`, 15.4:1) with torn top and bottom edges and a
  drop shadow, on a dark card. Print column x 32-183 = **25 glyphs**, y 22-247 = **22 lines** (10 px pitch; a dashed rule costs 9).
  UX's fit (`ux/string-budgets.json` receipt boxes, adopted after UX's objection) is **19 text lines + 3
  dashed rules**, and it always ends with the full two-line disclaimer ("…לא קשור לאף מפלגה / או מועמד.")
  and the URL line: iOS WhatsApp drops the share text when an image is attached, so the image is the only
  carrier of the link. `proofs/share-receipt-sample-1080.png` sets exactly that fit.
- **Result card:** a curtained stage under a follow-spot, `wordmark_small` at the top, a headline plate
  (2 headline lines + the sub-line "והציבור? נרגש."), the Magician at `castAnchor` (108, 198), a stat strip,
  and a footer band with two rows: RESULT_FOOT **with the URL** and the full RESULT_DISC. No seat numbers,
  ever (UX 5).
- **📸:** `stamp_camera` for the rare both-photobombers card.

## 14. Pipeline notes (for the Technical Artist)

- **Sources** are code in `art/od-sevev/src/`. Do not edit the PNGs. `build_all.py` rebuilds everything
  deterministically (seeded speckle and erosion).
- **Export 1x from `out/ui/`.** Every pixel is a `palette-v2` swatch with alpha 0/255, so they index
  cleanly into an atlas. The `share/` and `key/` images are *composites* and are not atlased.
- **Pivots** are in `ui-kit.json` where they matter (thermometer bottom, stamp tool, suitcase centre,
  brawl, cup, Dubi placeholder feet line).
- **Fonts:** the 5x9 cut in `src/hebfont.py` is my draft source; the runtime font is yours. Glyphs added
  in v2: `*`. UX's still-missing list (engine review F4) is otherwise covered by the draft (K M B T + −
  … ־ ״ ׳ ← ×).
- **Provenance:** every graphic-tier pixel is authored here. The cast is the approved render-down of
  ChatGPT references generated for this project (the orchestrator tracks those in `REQUESTS.md`).
  There is no third-party art in this folder, so nothing is added to `LICENSES.md` from here.

## 15. Proofs (all regenerated by the build)

| Proof | What it checks |
|---|---|
| `kit-*.png` | Every piece at 1x-as-shipped and 9-sliced, per group |
| `game-scale-hud-chat-overlays-x2.png`, `game-scale-hud-x4.png`, `game-scale-chat-x4.png` | The kit assembled on the 180x320 grid with the approved cast and stage: HUD, chat, transfer + court overlays |
| `phone-390css-read.png` | The same three screens downsampled to a 390-CSS phone: the real read |
| `cvd-deut-prot-and-squint-x2.png` | Deuteranopia + protanopia (Machado 2009) and a greyscale squint of HUD and chat |
| `contrast-table.md` | Every promised label/fill pair against its minimum; the build prints the fail count (0) |
| `icon-60-zoomed.png`, `icon-29-zoomed.png`, `og-square-crop-200.png` | Icon at real size; OG square crop |
| `share-cards-x2.png`, `share-*-sample-1080.png` | Share cards with sample text at capacity |

**Critique at game scale (from those proofs):** the Magician stays the brightest, busiest thing on the
HUD; the chrome reads as one family with the cast because of the shared near-black outline. Under
deuteranopia and protanopia the reds go olive, but the hazard band, clock, badge number, thermometer
shape and gavel carry every red state, and gold vs olive stays separable by shape (pill vs chip). In the
squint the Magician, the seats bar, the pay pills and the active tab are the top four values: the right
hierarchy.

## 16. Negotiations and flags

| # | To | Flag | My proposal |
|---|---|---|---|
| F1 | UX | "Gold underline" on the active tab collides with gold = money | Pale `rim` underline + raised plate (shipped). |
| F2 | UX | The countdown chip string "27.10 · עוד 29 ימים" is 81 art px at the 5x9 cut; UX's 92 CSS = 42 art | Either a ~99 px chip in the ticker, or the chip shows "27.10" and the ticker carries "עוד 29 ימים" once a day. |
| F3 | UX | The receipt holds 25 glyphs x 22 rows | **Resolved (wave 2):** UX's fit, 19 lines + 3 rules, full disclaimer + URL on both cards (UX objection accepted). |
| F4 | UX | Several strings exceed one line at 180 art px (court body 38 glyphs, the group-created system line) | Wrap: every 9-slice here grows vertically. Budget 28 glyphs per full-width line, 17 per bubble line. |
| F5 | UX / TA | UX's chat avatar is 24 CSS (~11 art px); the approved avatars are 32 art px (69 CSS) | Use the 32 px avatars in the chat (proof shows it reads and fits a 120 px bubble); an 11 px face loses every caricature trait. |
| F6 | TA / orchestrator | `ben-gvir_avatar.png` and `gotliv_avatar.png` have a **maroon** ring (reserved for the Suitcase) | In `showcase/src/build.py`, change the 'jab' ring `(138,21,56)` to `red` `(208,42,54)`. |
| F7 | Orchestrator | The `suitcase` ChatGPT row | Not needed in-game: hand-drawn (`props/suitcase.png`); keep it only for a large key-art version. |
| F8 | Animator | Stamp tool, brawl, cottage pixel drop, bubbles, clock hand, seats pulse | Key poses / frames are here; timing, easing and the reduced-motion behaviour are yours. |
| F9 | Views / UX | On the outline scrim a dark kit sheet's edge nearly vanishes over a dark stage (`ui_panel` 1.1:1, `ui_bubble` 1.4:1, the `ui_bub_hi` bevel 2.1:1 vs `#0f0b19`); the cream fork cards are unaffected (17.8:1) | When the modals move to `sheet_modal` (UX R7/R8), give the sheet's top and side edges a 1 px `suit_hi` line **outside** the outline (3.6:1 on the scrimmed dark; `ui_bub_hi` would be only 2.1:1, `slate` 5.2:1 reads as a grey frame). The modal then reads as lifted, not cut out. I'll redraw `sheet_modal` / `sheet_plain` that way when the views developer adopts them for the modals; the scrim stays the outline. Not a WCAG failure (a dialog's region is not a control), a figure/ground one. |

## 17. Wave 2 (the flat UI the TA found missing + the Animator's art needs)

| Need | Pieces | Notes |
|---|---|---|
| Sheet / modal | `sheet_modal` [6,22,6,6] (title band), `sheet_plain`, `icon_close` | Settings, About, return card, the election modal, the round card |
| Ticker | `ticker_bar` 180x20 (red top rule = TV lower third), `ticker_flash_plate` (+ `_text`, "מבזק" baked) | Slanted leading edge faces the crawl |
| Source card | `card_source_{unaffordable,affordable,locked}` 32x30, `chip_owned`, `plate_silhouette` | Affordable adds a gold edge; the pill (`pay_pill_*`) carries the state |
| Spins | `card_spin` (pink stripe = talking point), `card_spin_locked`, `tag_worn` "שחוק", `spin_s01`…`spin_s15` | **15** icons: content.json has s01-s15 (s15 "ביקור ממלכתי" was added after the 14 in the brief). **Wave 5:** redrawn at 24x24 (the shop icon size) and wired through `upgrades[].icon` |
| Opposition | `card_opposition` [6,17,6,6], `card_opposition_back` (tile) + `card_back_mark`, `opp_timer_fill` | Neutral riveted steel: never a party colour, never the coalition's violet |
| Trophies | `trophy_<icon>` + `_locked` for all **17** icon ids in content.json, `trophy_plate_{earned,locked,secret}` | The brief said 5; the achievements list uses 17 ids, so all 17 are drawn |
| Controls | `icon_gear`, `icon_sound_on`, `icon_sound_off` | 15x15; off = a red x (shape, not colour) |
| FTUE | `ftue_hand` (2 frames, the Magician's own finger, rim), `ftue_tap_ring`, `toast`, `icon_coin9` | Hand pivot = fingertip |
| Diegetic echo | `court_window` (dark / lit), `court_window_glow` (checker halo), `sweat_drop` | Suggested placements in the manifest notes |
| Animator asks | `stamp_*_rot` (8 pre-rotated impressions), `cottage_cup` 13 states, `laundry_{shirt,sock,towel,shorts,bag}`, `curtain_{panel,hem,valance}` | Stamps are rotated by the three-shear method (`kit.rotate_shear`): every ink pixel moves, none is invented or smeared |

- **Wave 3, object money sources** (`out/ui/sources/`, `src/sources.py`): `source_submarine` (48x40, porthole eyes,
  cash out of the hatch; f1 = the hull 1 ap up with the periscope and water held), `source_poison` (32x40, a rack of 12
  phones with blank avatars and tiny hearts, lime antennas; f1 = the LED column swaps), `source_checkbook` (40x40, gold
  open chequebook, thick black marker, ribbon; f1 = a 2-px glint + the page corner lifts). Hand-drawn at the rendered
  critters' density (dark outline, pale rim, 40 ap incl. rim, pivot bottom-centre); `*_icon` = 24x24 crops of f0 at 1:1.
- **Wave 4, small Dubi** (`out/ui/dubi/dubi_small_{idle,talk,squawk,fly,land,peck}.png`, `src/dubi_small.py`): the
  18-ap parrot hand-drawn as layered grids (lower body, suit, near wing at 3 angles, head with 3 eyelid states, hooked
  upper beak, jaw closed / open 2 ap), composited from `motion/state-graph-dubi.md` §1: 16 + 2 + 4 + 4 + 3 + 6 = 35
  frames, 20x23, anchor [10, 22], the TA's fps / loop / events unchanged. talk.f1 now differs from idle.f0 by a 2-ap
  open jaw with a red mouth. Seams are asserted by the build (every action f0 and one-shot end = idle.f0; fly.f0 =
  land.f0). Deviations, forced by whole pixels: the ±3° idle sway is below 1 ap (carried by nothing); peck strikes −1
  forward / +2 down (−2 forward reaches the frame edge); every rig squash is the waist cut moving 1 ap.
- **Wave 5, the reported art gaps** (`src/wave5.py`, `src/icons24.py`, `src/ui_meters.py`):
  - `spin_s01`…`s15` at 24x24, each with its joke's second beat: the deposit tag reads "0.30"; the pistachio drips; the
    baby monitor wears the top hat; the empty bubble is stamped "0" (violet, axis-aligned); the net is empty mid-swing;
    the jet has one lit window seat; one finger in a Spartan helmet; the remote's one big button; the pager is
    gift-wrapped; a laundry sack with a sock out and a luggage tag; the rabbit's carrot mic; three empty chairs, a gavel
    and a cobweb; the friendly couch with a heart mug; 999 views and 1 like; two armchairs and a cigar. Content ids and
    kit ids now agree through `upgrades[].icon` (the engine's default `icon_<id>` never existed).
  - `thermo_tube_short` 14x58: the full tube with 30 rows of column removed (bulb, neck, glint, ticks identical;
    40 rows of travel). `thermo_tube` is bit-identical to wave 1.
  - `lane_<era>` 2x28 tiles: the Suitcase lane's floor. **Amends v1 §8's "y 230-320 flat":** the band stays one
    colour family and extendable, but may carry HORIZONTAL-ONLY structure (the lip, the shadow it casts, course seams
    at 4-5-6-7 rows toward the viewer) because the lane is now open stage, not under a UX panel. Horizontal-only means
    the engine tiles it across the full canvas width (the side bands match), no vertical edge ever sits behind the
    flying Suitcase, and every lane swatch is at least as dark as the era's apron, so the Suitcase rim keeps its
    contrast. `stages[era].padBottom` is now the apron colour (was the 1-row bottom rule, wrong in all four eras).
- **The curtain is plum, not maroon.** The Animator asked for "ticker maroon"; maroon is the Suitcase's
  alone (§2.2), and plum is already the game's stage-curtain ramp. The valance carries the election
  signifier: a row of ballot-box lids with their slots (never a slip going in, v1 do/don't 6).
- **Pictograms in Sevev 9** (`pipeline/od-sevev/font/sevev9.glyphs`, TA-approved write): 📺 ⬅ ☕ ⭐ ⏳ ⚖ ✂ 🔥
  👻 📈 🔇 💸, 1-colour, 7 rows (rows 1-7 of the cell), 5-9 px wide. ⬅ is a filled arrow so it never
  collapses into the thin ←. The pipeline's content warning went from 23 missing characters to 11 after the
  glyphs, and to 0 once the remaining ones were reworded in `design/content.json`.
- **Proof font:** `src/hebfont.py` now merges the shipping Sevev 9 glyphs it lacks (Latin, pictograms), so
  proofs render with the real font; the proof bidi keeps `58/61`, `+38`, dates and URLs whole.

- **Wave 6, the UX build review's art items** (`ux/review-2026-09-29.md`; `src/ui_controls.py`, `src/wave2.py`,
  `src/sources.py`, proof `src/wave6.py` → `proofs/kit-w6.png`):
  - **R7 `button_danger_{default,pressed,disabled}`:** the destructive commit ("למחוק הכול" in O10), built exactly like
    `button_primary` on the red ramp (`red` face, `red_hi` light, `red_dk` shadow, lip and pressed face; the shared
    disabled). Label `white`: 4.7:1 default, 8.1:1 pressed. The shape that travels with the red is the word, on the
    LEFT beside the focused `button_secondary` cancel on the right, plus `icon_trash` leading it where the row has room.
    One per screen, never on a non-destructive action.
  - **R26 `icon_trash`** 9x9 (the settings danger row, leading `SET_RESET` on the right; never mirrored) and the
    **round `icon_close`** 16x16 (same id, redrawn from the thin 9x9 X; §11.5). The court card reads `icon_close`
    already; the modals read `uiTheme.close` and switch to the same kit id (one line, engine).
  - **R18:** the hand-drawn sources' `source_{submarine,poison,checkbook}_icon_sil` (their ids were in `sprites.json`
    but never shipped, so the locked shop card drew the "?"), by the rendered sources' rule (`suit` mask, `rim` edge;
    it reproduces the five rendered silhouettes pixel for pixel).
  - **R15:** the scrim is `outline` at 60% (§11.2); its contrasts are in §11.4. The engine owns `uiTheme.scrim`.

## 18. Foundations (referenced, not paraphrased)

v1 §15's list stands (colour theory, palette construction, squint test, colour-blindness redundancy,
shape language, silhouette test, value separation, prop interactivity class, WCAG contrast, icon design
at small sizes, wordmark thumbnail legibility), under `gamestudio/.claude/skills/`.
