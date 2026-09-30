# "עוד סבב": style guide v4 (the approved detailed look + the UI kit, in Israel's blue and white, the flag's layout)

**Artifact:** `style-guide` (+ `ui-artwork`, `wordmark`, `key-art`). **Owner:** 2D Artist.
**Status:** v4 (2026-09-30, Bar: "more Israel theme and palette"; §2.4) on v3 (2026-09-29, palette only: Bar, "the design should be more in Israel's palette, with blue and white"; §2.3) on v2, which supersedes the creative-pack v1 where they differ. Bar approved the look (the cast in
`creative-pack/od-sevev/art/showcase/out/`); v2 codifies it and adds the UI.
**Consumers:** Technical Artist, Game Developer, UX Designer, Animator, Audio Director (key-art pairing).
**v1:** `gamestudio/output/artifacts/creative-pack/od-sevev/art/style-guide.md`. Sections v2 does not
restate stay in force from there (lineage §1, caricature grid §7, era moods §8).

**Rebuild everything:** `cd art/od-sevev/src && python3 build_all.py`. That writes every PNG at 1x,
`ui-kit.json`, the key art and every proof. Every rule below is executable in `src/`.

| Deliverable | File |
|---|---|
| UI kit, 261 pieces (wave 9, 2026-09-30: 2, the envelope flap `sheet_modal_body` + `sheet_modal_flap`; mobile-first wave 7, 2026-09-29: 13 + the 4 lanes redrawn; leader select 2026-09-29: 30; wave 1: 89, wave 2: 96, wave 3: 6, wave 4: 6 Dubi strips, wave 5: 5 + the 15 spin icons redrawn, wave 6: 7 + `icon_close` redrawn, wave 6 polish: the 3 no-photo stand-in pieces + `trophy_moon`, `sheet_modal` redrawn), 1x art px | `out/ui/<group>/*.png` (groups: chat, controls, meters, widgets, events, props, share, key; wave 2: sheet, ticker, cards, spins, trophies, ftue, stage, ceremony) |
| 9-slice / frame / pivot manifest | `ui-kit.json` |
| Wordmark (rim, no rim, mono, small) | `out/ui/key/wordmark*.png` |
| App icon 1024 + 60 | `out/key/icon-1024.png`, `out/key/icon-60.png` (master `icon-128-art.png` = 64 art px at d 2) |
| OG image 1200x630 | `out/key/og-1200x630.jpg` (203 KB at q 82 4:4:4 since the lineup, WhatsApp needs ≤ 300 KB) + `.png`; shipped as `game/web/og.jpg` |
| Graphic-tier palette | `out/palette-v4.gpl`, `out/palette-v4.png`, source `src/palette.py` |
| Colour map for code (v2 → v4) | `palette-v4-map.json` (with `perFile` roles), applied by `tools/apply_palette_map.py` (§2.4) |
| Election material culture (wave 8) | `out/ui/meters/hemicycle_{track,fill}.png`, `out/ui/picker/booth_frame.png`, `out/ui/props/envelope_blue.png` (§2.4) |
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
| Palette | **One locked palette per character**, ≤ 48 colours (measured 44-57 incl. props), locked from the rest pose so frames never flicker | The **66-swatch graphic palette** (§2); nothing off-list |
| Rendering | Dense painterly shading from the ref, no dithering added | 3-band cel (light / base / shadow) + an extra glint or deep band where it earns it (§4) |
| Outline | Near-black, from the ref (measured `#000000`–`#0e0f13`) | `outline` `#0b0a12`, 1 art px |
| Rim | Pale `#d6ccec` on the Magician and his props | `rim` `#d6ccec` on stage-touchables (§3) |

- **Rule:** a thing goes to the cast tier when its read is a *face or a body*; it stays graphic when its
  read is a *shape, a word or a number*. That is why the Suitcase (read: a 4-letter sticker) is hand-drawn
  and Dubi (read: a parrot's face) is a ChatGPT request.
- **Never mix pixel scales in one frame.** One integer scale per image (x4 in game, x5 on share cards and
  OG, x16 on the icon). The cast pastes 1:1 onto every one of them.

## 2. Palette (graphic tier)

- **66 swatches in 19 families** = v1's 45 + 17 v2 additions + 2 v3 additions (`ui_mute`, `ui_rule`) + 2 v4 additions
  (`ui_dim`, `alert_lt`); v3 re-values 7 ids in place (§2.3), v4 re-values 6 more (§2.4). Well inside the ≤ 24-family cap.
- Source: `src/palette.py`; export `out/palette-v4.gpl` / `.png`. v1's table (§2 there) still describes
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
| `flag` (+ `flag_dk`) | The Magician's tie/pin, Dubi's tie, THE primary button; **v3: also the chrome's national frame** (flat title bands, the stripes) | One `button_primary` per screen (raised, lipped: the shape tells it from a flat band). Seats use `sky`, never `flag`. **Never flag-blue text on navy** (1.6-1.8:1). |
| `navy_hi` | The Magician's suit light plane | Not used anywhere in the UI. |
| `stamp` violet | Bureaucracy (v2) | Stamps, the pinned-bar edge, the pin head, the "filed" mark on the תיקים icon. |
| `red` ramp | Danger | Ultimatum, thermometer, court tint, count badge, "מבזק" plate. Always paired with a shape (hatch, clock, icon, number). |

### 2.3 v3: Israel's blue and white (2026-09-29)

**Direction (Bar):** "the design should be more in Israel's palette, with blue and white". **Scope (orchestrator):** the
chrome goes blue and white on a navy base, with white panels or white text on blue, like a flag or an official notice:
the HUD, cards and panels, the tab bar, modals, sheets, the picker tiles, the ticker, toasts, the chat chrome, the share
cards, settings, the title, the app icon background, the OG frame, and the HTML shell (the gate, About, the phone frame,
`theme-color`). **Stays:** gold = money (the buy pill is the one warm call to action), red = alerts only (the flash
badge, ultimatums, the court), the stages' identity, and the cast (no re-render: a full render reports 0 drift).

**Re-valued in place (ids stable, every sprite legend and grid keeps working):**

| Swatch | v2 | v3 | Role in v3 | L (v2 → v3) |
|---|---|---|---|---|
| `ui_scrim` | `#140c24` | `#061029` | Deep navy: HUD Row A/B, wells, the deepest surface, the shell pages | .005 → .006 |
| `ui_panel` | `#1e1636` | `#0a1a42` | Navy: panels, headers, the tab bar, the sheet body | .011 → .012 |
| `night` | `#2a2340` | `#0f2350` | Navy night: Balfour's sky, text plates, the shop pane, the shell page | .021 → .019 |
| `ui_bubble` | `#2e2250` | `#112a64` | Raised navy: cards, picker tiles, incoming bubbles, secondary buttons | .023 → .027 |
| `ui_bub_hi` | `#4a3c7c` | `#26499c` | The raised bevel light; the ✕ face | .061 → .076 |
| `plum` | `#4a2552` | `#16357a` | Velvet blue: the curtain (title, OG, icon), Balfour's mid sky | .034 → .041 |
| `plum_hi` | `#7a3a7d` | `#2a57a6` | The curtain's fold light, Balfour's horizon | .086 → .101 |

**Added:** `ui_mute` `#a3b3d3` (secondary labels on navy: the picker's party line, idle tab labels; replaces UX's
lavender `#9e99ad`), `ui_rule` `#1c3876` (dividers on navy; the phone-frame bezel). **Unchanged on purpose:** `flag`,
`flag_hi`, `flag_dk`, `sky`, `white`, the cream `#fff8ec` / `#fff4e0`, the gold ramp, the red ramp, `ink` and `outline`
(the stages share them, so a shift would drift all four), `rim` (baked into the cast), `stamp` / `stamp_lt` (rubber-stamp
violet is the real ink of Israeli bureaucracy and a satirical prop, not chrome).

Every v3 value keeps its v2 luminance within ±.015, so every §11.4 label contrast holds (the table is regenerated:
`proofs/contrast-table.md`, 0 fails). `night`, `plum`, `plum_hi` move in the creative pack's `art/src/palette.py` too:
Balfour's night sky is navy (`stage_balfour`), Washington's 1-row lower rule follows (`stage_washington`), and Knesset and
the courthouse do not move.

**Drawn (the white in blue and white):** the white-over-flag stripe pair is the chrome's national frame: the tab bar's
top edge, the ticker's top (was red: red is alerts only), the chat header's bottom, the gate's and About's heading
rule. `sheet_modal`'s title band is flat `flag` with a `flag_hi` light and a white stripe under it (the title white on
flag 8.5:1): an official notice's header. Pink accents move to the blue family: the spin card's stripe (`flag_hi` + a
`sky` edge), the spins tab's arcs and spin slot G's arcs (`sky` / `flag_hi`), the s14 play glyph (`flag_hi` / `flag`).
The fork's cream `ui_card` modal (settings) becomes the "white panel": its letters move grape → navy, violet → flag,
lavender → pale blue and pink → sky / flag_dk (`art/sprites.ts` → `game/data/art.json`), so it reads as a white notice
with a blue frame and blue section heads.

**Code (superseded by §2.4's `palette-v4-map.json`; v3's map was never applied):** the colours the scripts hard-code were mapped in `palette-v3-map.json` (17 pairs, roles, the colours left alone,
the file:line sites); `tools/apply_palette_map.py` applies it (dry run by default). The shell is applied; `game/scripts/**`
is applied by the orchestrator after the mobile-first merge.

**Rules (v3):**
- **Blue-on-navy is never text.** `flag` on navy is 1.6-1.8:1 and `flag_hi` on `ui_scrim` 4.4:1: blue text goes on white
  or cream (`flag` on cream 8.5:1), text on navy is white, `silver`, `grey`, `ui_mute` or `sky` (10.0:1 on `ui_scrim`).
  Blue on navy is for shapes (stripes, bevels, fills that also carry a shape).
- **Gold stays the one warm thing.** The buy pill on a navy card is 10.4:1 (gold vs `ui_panel`) and the only warm hue in
  the chrome; a flag-blue pill would sit at 1.5:1 on `ui_bubble` and vanish (tested; §16 F10). Gold on white is 1.48:1:
  a gold control on a white panel must keep its `outline` edge (17.9:1).
- **Party neutrality.** Blue and white here is the national flag's, never a party's: no white-Hebrew-on-blue wordmark
  (the wordmark stays gold, extruded, with the rim), no party logo shapes (no כחול לבן / Likud / Yesh Atid letterforms,
  arcs or boxes), no star of David and no flag as an object or a joke element, least of all on a character. The colours
  are the frame (bands, stripes, the stage), never the punchline.
- **Colour-blind redundancy holds** without the old hue split: under deuteranopia and protanopia navy and flag stay blue
  (the axis both keep), gold stays yellow, red goes olive but keeps its hatch, clock, badge number and word; the
  flag-blue title band vs the navy body differs by the white stripe as well as by value (1.8:1).

### 2.4 v4: the flag's layout and Israeli election material culture (2026-09-30)

**Direction (Bar, on the v3 before/after):** "More Israel theme and palette". v3 read as "navy instead of plum". v4 makes
it unmistakably Israeli in two ways: the flag's *layout* (much more white and flag blue, navy only as the deepest base),
and the material culture of an Israeli election day as the UI's language (the ballot slip, the blue envelope, the
cardboard booth, the 120-seat hemicycle, the news strip, the printed notice). Stones and light are Jerusalem's.

**The main screen as the flag's layout (kit + `palette-v4-map.json`):**

| Band (top to bottom) | v4 | Why |
|---|---|---|
| HUD (Row A/B) | **flag blue** band (`#0038b8`, main.gd per-file) | The flag's top stripe. Gold bank 6.4:1, green income 5.7:1, white labels 8.5:1, the navy seats well sunk in it |
| Stage | the approved art (navy night at Balfour) on **Jerusalem stone** lanes and plaza | Navy only behind the stage; the stage stays the star |
| Ticker | the **news strip**: `ui_panel` deep flag blue, a white rule over a flag rule | An Israeli channel's lower third; red only on the "מבזק" plate |
| Card pane | the **white field** (`#f7f4ec`, main.gd per-file) | The flag's white; the cards sit on it like blue envelopes (edge 7.5:1) |
| Cards | **flag blue** (`ui_bubble` `#1045b5`), white text 7.5:1, gold pills 5.1:1, the icon on a **white ballot slip** (`card_plate`) | White text on blue: no per-view text flip needed |
| Tab bar | deep flag blue with the white-over-flag stripe | The flag's bottom stripe |

**Re-valued (ids stable):**

| Swatch | v2 | v3 | v4 | Role in v4 |
|---|---|---|---|---|
| `ui_panel` | `#1e1636` | `#0a1a42` | `#072a7a` | Deep flag blue: panels, the chat thread, the tab bar, the sheet body (the blue envelope); white 11.8:1 |
| `ui_bubble` | `#2e2250` | `#112a64` | `#1045b5` | Flag blue, raised: cards, picker tiles, incoming bubbles, secondary buttons; white 7.5:1 |
| `ui_bub_hi` | `#4a3c7c` | `#26499c` | `#4f82e8` | The raised bevel light |
| `ui_mute` | (UX `#9e99ad`) | `#a3b3d3` | `#c9d6f2` | Secondary text on blue (party lines, names, idle tabs): 5.7:1 on `ui_bubble`, 8.9 on `ui_panel` |
| `ui_rule` | (`#2e2548`) | `#1c3876` | `#2a5cc4` | Dividers on the blue panels |
| `stamp_lt` | `#b9a0ef` | = | `#d8ccff` | The stamp on blue surfaces: 5.5:1 on `ui_bubble` |
| `ui_dim` (new) | | | `#b4c3e8` | Tertiary text on blue (the code's slate text): 4.7:1 on `ui_bubble` |
| `alert_lt` (new) | | | `#ffaa9f` | Alert TEXT on blue ("אולטימטום", the last seconds): 4.5:1 on `ui_bubble` (`red_hi` is 2.9:1 there); always with its hazard band and clock |

Unchanged from v3: `ui_scrim` `#061029` and `night` `#0f2350` (the navy base: wells, the pinned bar, the composer, behind
the stage, the picker's scrim), `plum` / `plum_hi` (the velvet-blue curtain, Balfour's sky), and everything v3 kept (flag,
flag_hi, flag_dk, sky, white, cream, gold, red, ink, outline, rim, stamp).

**Drawn (the material culture):**
- **The ballot slip (פתק):** `card_plate` is a blank white slip with a fold (the icon lies on it; outline vs white 17.4:1);
  `pick_random` was already a folded slip. Blank or "?" only: never a real party's ballot letters (מחל, פה, …).
- **The blue envelope (המעטפה הכחולה):** `sheet_modal`'s title band is the envelope's flap, pointed 2 rows deeper at
  the centre with the white stripe following it; the body is the v4 `ui_panel` blue. Wave 9 (§17.2) splits it into
  `sheet_modal_body` + the 3-frame `sheet_modal_flap` (sealed V → lifting → the band), so a modal opens like one. `envelope_blue` (14x10, new) is the
  envelope as a prop; the OG's confetti mixes blank envelopes into the white slips.
- **The cardboard booth (קלפי):** `booth_frame` (40x40, new, 9-slice [6, 10, 6, 4]) is the picker grid's frame: off-white
  cardboard, the two side wings folded back, a blank flag-blue header strip. For UX / the engine to adopt.
- **The 120-seat hemicycle:** `hemicycle_track` / `hemicycle_fill` (72x38, new): a white half-disc plate, 120 seats on six
  rows, the majority tick at the top centre; `seats` lists the seat rects in RTL fill order, `goal` 61. Taken seats are
  flag blue (8.5:1 on the plate), empty ones silver (6.4:1 vs taken, and a different corner). A new widget beside the
  horizontal bar (which stays); UX decides where it lives (Row B, the ≥ 61 moment, the result card).
- **The news strip:** the ticker (above). **The printed notice:** the settings card (the fork's cream card with the
  v3 letters: flag-blue heads, a blue frame) and, in the HTML shell, the gate and About as white notices ruled in
  flag blue on the flag-blue page (navy text 13.9:1). The look of a notice, never an institution's name or emblem.
- **The primary button** gets a white light edge (it would otherwise merge with the blue cards, 1.1:1); the round
  close ✕ has a deep-blue face (white ✕ 11.8:1).

**Place:** the lanes (`lane_<era>`) and plazas (`plaza_<era>`) are **warm Jerusalem limestone**: `stone_sh` slabs with
pale mortar in Balfour's lamp light, sunlit `stone` at the Knesset, polished `paper` limestone tiles in the courthouse;
Washington is not Jerusalem, so it gets pale concrete panels. The Suitcase keeps its edge by its outline (13.3:1 on
stone) and maroon body (≥ 3.6:1), not its rim (the lane assertion changed accordingly). The OG stands the lineup on a
stone floor with a flag-blue-over-white apron trim and a white-over-flag rule under the valance; the icon's disc is flag
blue in a white ring. The wings keep their olive tree (Knesset); the stages keep their own light (Balfour's warm lamps,
the Knesset's sun on stone): v4 repaints no stage and the cast is untouched (full render: 0 drift).

**Chosen with evidence (and the rejected alternatives):**
- **Light cards (white slips with navy text) — rejected**, tested as a simulation (`shots/palette-v4/main-before-after.png`,
  4th panel): text reads either way (navy on white 13.9, white on blue 7.5), but (1) the gold buy pill on a white card
  drops to 1.48:1 and keeps only its outline, so the one warm call to action stops popping; (2) the white slip plate
  merges into a white card; (3) the code draws the card and chat labels white (`Art.col("w")`, per-view constants), so
  light cards need a per-view text flip in the Game Developer's views, not a colour map. **Chosen:** blue cards on a
  white field (the same flag layout, inverted where the text is).
- **"Blue/white on navy" (v3) — rejected:** it read as "navy instead of plum" (Bar).
- **A white HUD band — rejected:** the gold bank is 1.5:1 on white; the HUD is the flag's top blue stripe instead.
- **Blue buy pills / a ballot-slip pill — rejected:** a flag pill is 1.1:1 on the v4 cards; a white slip pill loses the
  warm CTA. Gold stays (5.1:1 on the card, the only warm hue). The ballot slip carries the icon instead.
- **The whole desktop page as the flag (white field, two stripes, the phone in the middle) — rejected:** it would put
  the game where the Star of David sits. The page is plain flag blue; the stripes are on the notices and the chrome.

**Rules (v4, extending §2.3):**
- **Kit and code map land together.** Without the map, the scripts' text colours sit on the v4 blues at 2.2-3.5:1 (the
  party line `#9e99ad` 3.0, grey 3.5, slate 2.2, red_hi 2.9). Merge the v4 kit only with `tools/apply_palette_map.py
  --write` in the same step (after the mobile-first merge).
- **Never text straight on the white pane**; if a pane label is needed, give it a `ui_panel` plate or draw it in
  `ui_bubble` blue (7.5:1).
- **No blue text on navy, no gold text on white.**
- **Party neutrality (unchanged, sharpened):** no party ballot letters, no party logo shapes or wordmarks, no Likud-blue
  logo mimicry, no "כחול לבן" wordmark; no state emblem or menorah; no star of David or flag as an object, least of all on
  a character. The flag's colours and stripes are the frame; the booth, the envelope, the slip and the hemicycle are
  blank civic objects. No October 7 imagery (do/don't 13).

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
- **Sevev 9 @2 (2026-09-29, Bar's "sharper text"):** the reading cut. Every glyph redrawn on a 2× grid
  (`pipeline/od-sevev/font/sevev9@2.glyphs`) and drawn at half the scale, so it covers **the same box**
  with every metric exactly 2× Sevev 9's (the build checks it). It is not a smaller font and not a second
  text size: it is the same letters at twice the pixel density.
  - **Stroke model:** the Hebrew square script's contrast. Horizontals (roofs, bases, bars) are 2 @2 px,
    Sevev 9's weight; vertical stems are 1 @2 px; diagonals are 2 px per row, stepping 1. Round corners
    get a 1-px chamfer, square corners stay square. Dots and commas stay 2×2.
  - **Letter logic, sharpened:** ב square with its base tail past the stem vs כ rounded with no tail;
    ד's roof overhangs vs ר/ך rounded (ך descends); ה's left leg detached (2-row gap) and inset vs ח
    attached vs ת inset with a 2-row foot; ו hook + stem vs ז bar over a stem vs ן descending; ס rounded
    vs ם square; ע's base kicks left vs צ's crossed top on a full base; ׳ and ״ are raised tapered ticks.
  - **Where:** reading text (chat, toasts, card descriptions, the ticker crawl, settings, modal bodies,
    About). Display text stays the chunky Sevev 9: the counter, prices, titles, tab labels, the ticker
    tag, chips, buttons, badges and anything dimmed or over art (CONTRACT §6.1 has the list and the
    crispness rule: @2 only when a Sevev 9 px is an even number of device px).
  - **Pictograms (wave 6):** all 12 now hand-drawn on the @2 grid (11 redrawn, ⬅ was) in the same stroke model (2-px horizontals, 1-px
    walls, 2-px diagonals, chamfered rings); they were an EPX pass of Sevev 9 (blobby, every stroke 2 px). Each
    ink box is exactly 2 x its Sevev 9 twin's, so a pictogram sits where Sevev 9's does.
  - **Proof:** `pipeline/od-sevev/proofs/font-density2.png` (×4 on a k 4 device: 4-dp vs 2-dp px).

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

**Leader select (Bar, 2026-09-29): the key art is the lineup of the 8 launch leaders**, replacing the Bibi-with-hat
icon and OG (the game is no longer "the Bibi game"; design/leader-select-spec.md §10.3, STATUS). The rule for both:
**nobody is the winner.** The order is Hebrew-alphabetical by the picker's name, read right to left: אייזנקוט, ביבי,
בן גביר, בנט, גולן, דרעי, ליברמן, סמוטריץ׳ (`keyart.LINEUP`). Eight is even, so nobody stands in the middle; every
figure is the approved idle frame 0, the same height, on the same floor line, under the same spot.

**Icon** (`out/key/icon-1024.png`, 64x64 art x16; `icon-60.png` is the real LANCZOS downsample):
- **What:** the eight heads in a ring around the gold clockwise "again" loop, on a stage (v3: velvet blue, the re-valued `plum`) with one follow-spot.
  A rotation (סבב) in a mark with no text: the loop is the brand, the ring is the roster. The ring starts 22.5° right
  of 12 o'clock and runs clockwise in the lineup order, so no head sits at the top or in the middle.
- **Heads:** `showcase/out/<c>_avatar_pick.png`, the 32x32 chat-avatar render-down (the same head box and palette as
  the chat avatar) on one neutral `rim` ring for everyone (the chat avatars' react-coloured rings read as party or
  bloc colours); the same heads are the picker tiles' (`avatar_pick_<c>`, `avatar24_pick_<c>`).
  Pasted 1:1 on the 128x128 fine grid (2 px per art px, d 2), so each head is 16 art px with 32 px of detail; the
  whole scales x8 (the master the pipeline imports is `icon-128-art.png`).
- **Reads at:** 1024 (eight caricatures), 60 px (a ring of faces around a gold loop), 29 px (a ring and the loop)
  (`proofs/icon-60-zoomed.png`, `icon-29-zoomed.png`). Individual faces at 29 px are not a goal: no 8-person mark can
  do that, and a single face would pick a winner.
- **Safe area:** the ring's outer edge is at radius 31 of 32: inside the iOS squircle and the full-bleed square; on
  Android's circular mask the ring's outer rim may clip slightly (the heads' centres stay at radius 23). Opaque,
  square, no rounded corners (the OS masks).
- **Excluded:** flags, emblems, party colours or logos, ballot slips with letters, any leader bigger or central.

**OG** (`out/key/og-1200x630.jpg`, **400x210 art x3** since leader select, d 3 at 1 output px per sprite px; it was
200x105 x6 with Bibi alone, but eight full figures need the width):
- The wordmark (cap 32, stroke 6) over a curtained stage (v3: the velvet-blue curtain), ballot slips (no letters) and coins raining, Dubi
  (the office's parrot, everyone's spokesman) flying across, and the eight leaders standing shoulder to shoulder on
  the floor line, each on the same spot pool. The seam between the 4th and 5th leader (Bennett | Golan) is the canvas
  centre (`keyart.lineup_positions` packs each half on its own): nobody is centred.
- **Props:** a leader's loose tap prop (`ui` `prop_*`) is drawn at their `propMouth` only where it covers no
  neighbour (a prop on someone else's chest reads as theirs). In this lineup that drops all four loose props; Bibi's
  hat, Smotrich's calculator and Deri's cup are in their renders.
- **Square-crop safe:** the wordmark and the middle four (בן גביר, בנט, גולן, דרעי) sit inside the centre 630x630
  (`proofs/og-square-crop-200.png`).
- Nothing that echoes October 7 (do/don't 13): no ribbon, poster, portrait grid, empty chair at a table, uniform or
  siren; the only text is the wordmark. **→ UX:** `OG_IMAGE_ALT` / the web shell's alt still describe Bibi pulling
  shekels from a hat; suggested: "שמונה ראשי רשימות בפיקסלים עומדים בשורה על במה, מעליהם הכיתוב עוד סבב."

## 10. Do / don't (v2 additions to v1 §11)

| # | DO | DON'T |
|---|---|---|
| 7 | Seats fill in `sky`, growing from the right | A `flag`-blue or gold seats bar (steals the Magician's colour or money's) |
| 8 | Stamps in violet, axis-aligned, with speckle | Red stamps (reads as danger), or a rotated stamp (smears the pixels) |
| 9 | The active tab = raised plate + pale underline + white label + the only coloured icon | A gold underline (gold = money) |
| 10 | Can't-afford = a sunken well with a dim gold fill and a white label | The same raised pill in grey (colour-only state change) |
| 11 | Hand-draw anything whose read is a word or a number (the Suitcase's DOHA) | Render-down a sticker at 24 px |
| 12 | A long string wraps inside a taller 9-slice | Shrinking the font, or a second pixel scale for text (Sevev 9 @2 is not one: same box, same metrics, a 2× grid; §7) |
| 13 | A committee, a delay, a freeze drawn as its objects: a binder, a stamp, frost, a cobweb, a clock | Anything that can echo October 7 (Bar, 2026-09-29; `design/redlines.json` `oct7-hostages`, visual echoes included): empty chairs at a table or an empty set table, a yellow ribbon or yellow pin, missing-person posters or portrait grids, a day counter, sirens, rockets, uniforms or army green, a border fence. Yellow stays gold (money) and never becomes a ribbon or a loop pinned to a chest. |

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

### 11.4 Label contrast (all pass; `proofs/contrast-table.md` is regenerated by the build and holds the v4 values; the table below is v3, §2.4 has the v4 surfaces)

| Label on surface | Contrast |
|---|---|
| `white` on `ui_bubble` / `ui_out` / `ui_panel` / `ui_scrim` | 12.4 / 10.0 / 15.4 / 17.2:1 (v2: 13.1 / 10.0 / 15.6 / 17.3) |
| `white` on `flag` / `flag_dk` / `red` / `teal_dk` / `wood` / `gold_dk` | 8.5 / 12.6 / 4.7 / 11.1 / 5.5 / 6.1:1 |
| `ink` on `gold` / `gold_sh` (pressed) | 11.0 / 6.0:1 |
| `grey` on `suit_dk` / `ui_scrim` | 5.5 / 8.1:1 |
| `stamp` on paper / receipt; `stamp_lt` on `ui_bubble` / `ui_out` / `ui_scrim` | 5.6 / 7.3; 6.1 / 4.9 / 8.4:1 |
| `red_hi` ("אולטימטום") on `ui_bubble` | 4.7:1 (v2 5.0) |
| Non-text (≥ 3:1): seats fill `sky` vs its well; thermometer `red` vs its well / the hatch's black | 10.0; 3.7 / 3.8:1 |
| `white` on `red_dk` (`button_danger` pressed); the ✕ `white` on `ui_bub_hi` | 8.1; 7.6:1 |
| **v3** labels: `ui_mute` on `ui_bubble` / `ui_panel`; `grey` on `ui_bubble`; `sky` on `ui_scrim`; `white` on `flag` / `night` / `plum` / `plum_hi`; `flag` on cream `#fff4e0` | 6.5 / 8.0; 5.8; 10.0; 8.5 / 13.9 / 10.5 / 6.3; 8.5:1 |
| **On the scrim** (outline at 60% takes `ui_scrim` to `#0f0b19`, the brightest possible ground `#ffffff` to `#6d6c71`): white text on the scrimmed dark / the scrimmed brightest ground; the spin tag plate (scrim at 85% on `ui_bubble` = `#100e1b`) under white; the fork's cream card vs the scrimmed dark | 17.7 / 4.7; 17.4; 17.8:1 |
| Edges on the scrim (non-text): the dark sheet body `ui_panel` / title band `ui_bubble` / its `ui_bub_hi` bevel vs the scrimmed dark ground; `sheet_modal`'s `suit_hi` edge (wave 6, F9) | 1.1 / 1.4 / 2.1:1; **3.6:1** (F9 closed) |

### 11.5 Icons

- **Shop icons 24x24** (money sources and, since wave 5, spins): they fill `card_plate` (26x26) edge to edge.
  Spins are built from outlined parts back to front (`src/icons24.py`), no rim (UI, not a stage touchable).
- **Tab icons 15x15** (active + idle): מקורות = a faucet dripping a shekel (what you tap); ספינים = Dubi's
  microphone broadcasting two pink arcs; קואליציה = two chat bubbles, the front one with three dots (wave 10; it said "61" until UX review 2 U8: a number in a bubble reads as an unread count); תיקים = a manila case file
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
- **Export 1x from `out/ui/`.** Every pixel is a `palette-v3` swatch with alpha 0/255, so they index
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
| F10 | Orchestrator / UX | **v3 tested: the buy pill stays gold.** Bar's blue-white direction invites a blue pill; a flag pill on a `ui_bubble` card is 1.47:1 and would stop reading as the call to action, and gold vs `ui_panel` is 10.4:1 and the chrome's only warm hue | Keep gold (shipped). No objection raised. |
| F11 | UX / engine | v3 primary (`flag`) and secondary (`ui_bubble`) buttons differ by value 1.47:1 (v2 had a hue split too); shape, the `flag_hi` bevel (3.2:1 vs `ui_bubble`) and the white label carry it | **Resolved (wave 10, UX review 2 U2 found them 1.13:1 in v4):** `button_white_*`, a white primary with a flag label (8.5:1) and a flag-blue lip; 7.5:1 vs the secondary. New ids: the engine switches `kit_primary` to them. |
| F12 | Views (cast) | The chat avatars' blue react ring (`flag_hi`) now sits on navy chrome (3.9:1 vs `ui_panel`, was a hue contrast on violet) | Holds ≥ 3:1; if it reads as chrome, the TA can move the blue ring to `sky` in `showcase/src/build.py` (a cast-ring recolour, not a re-render). |
| F13 | Key art | The OG and icon curtain (`plum`, now velvet blue) vs the cast's navy suits is 1.15:1 by value (v2 was 1.06:1, carried by hue) | The outlines, white shirts, lit faces and the spot pool carry every figure at 1200 and at the 630 square; if a thumbnail reads muddy, lift the curtain body to `plum_hi` (a keyart.py change, no cast change). |
| F14 | Orchestrator / engine | **v4 sequencing:** the v4 kit without the code map leaves script text at 2.2-3.5:1 on the new blues | Apply `palette-v4-map.json` in the same merge as the kit (after the mobile-first merge); `--check` must report 0 before shipping. |
| F15 | UX / engine | New v4 pieces need a home: `hemicycle_*` (seats), `booth_frame` (picker), `envelope_blue` | UX places them; the kit is ready (manifest data: `seats`, `goal`, the booth's 9-slice and content box). |
| F9 | Views / UX | **Closed (wave 6 polish): `sheet_modal` carries the 1 px `suit_hi` edge outside its outline (38x38, margins +1).** On the outline scrim a dark kit sheet's edge nearly vanishes over a dark stage (`ui_panel` 1.1:1, `ui_bubble` 1.4:1, the `ui_bub_hi` bevel 2.1:1 vs `#0f0b19`); the cream fork cards are unaffected (17.8:1) | When the modals move to `sheet_modal` (UX R7/R8), give the sheet's top and side edges a 1 px `suit_hi` line **outside** the outline (3.6:1 on the scrimmed dark; `ui_bub_hi` would be only 2.1:1, `slate` 5.2:1 reads as a grey frame). The modal then reads as lifted, not cut out. I'll redraw `sheet_modal` / `sheet_plain` that way when the views developer adopts them for the modals; the scrim stays the outline. Not a WCAG failure (a dialog's region is not a control), a figure/ground one. |

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
    gift-wrapped; a laundry sack with a sock out and a luggage tag; the rabbit's carrot mic; the committee's fat binder
    ("ועדה"-shaped label) frosted with icicles, an idle gavel on top, a cobweb and a snowflake (redrawn 2026-09-29, it was
    three empty chairs at a table: see do/don't 13); the friendly couch with a heart mug; 999 views and 1 like; two armchairs and a cigar. Content ids and
    kit ids now agree through `upgrades[].icon` (the engine's default `icon_<id>` never existed).
  - `thermo_tube_short` 14x58: the full tube with 30 rows of column removed (bulb, neck, glint, ticks identical;
    40 rows of travel). `thermo_tube` is bit-identical to wave 1.
  - `lane_<era>` 2x28 tiles: the Suitcase lane's floor. **Amends v1 §8's "y 230-320 flat":** the band stays one
    colour family and extendable, but may carry HORIZONTAL-ONLY structure (the lip, the shadow it casts, course seams
    at 4-5-6-7 rows toward the viewer) because the lane is now open stage, not under a UX panel. Horizontal-only means
    the engine tiles it across the full canvas width (the side bands match), no vertical edge ever sits behind the
    flying Suitcase, and every lane swatch is at least as dark as the era's apron, so the Suitcase rim keeps its
    contrast. `stages[era].padBottom` is now the apron colour (was the 1-row bottom rule, wrong in all four eras).
- **The curtain is plum (v3: the id `plum` is velvet blue), not maroon.** The Animator asked for "ticker maroon"; maroon is the Suitcase's
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

- **Wave 6 polish** (`src/wave6.py`, `src/icons15.py`, `src/wave2.py`, `src/keyart.py`; proof `proofs/kit-w6-polish.png`):
  - **The no-photo stand-in** (`out/ui/nophoto/`): `avatar_nophoto` 32x32 and `avatar24_nophoto` 24x24 (the
    render-down avatars' construction: a 2 px ring, the disc inside; a `slate` ring on a `silver` disc, a featureless
    head over a shoulder arc) and `nophoto_idle` 40x97 at d 1, anchor [20, 96] (a featureless figure in a suit: head
    and hands on the slate ramp, the suit on `suit_hi`, shoes on `suit_dk`, one outline ring, inner lines in the
    local shadow). For any partner with no ChatGPT ref (today Almog Cohen): **never a likeness of a real person
    without a ref.** The pipeline joins it as the hand-drawn character `nophoto` and aliases every content partner
    without a character to it, so the chat avatar, the partner card and the ultimatum cameo draw it, not the "?".
    The refs still wanted: `asset-requests/REQUESTS.md` `almog`, `aide`, `mk-generic`.
  - **`trophy_moon`:** the star beside the crescent (it read as an emblem) is two white z's rising right: a nap.
  - **`sheet_modal` (F9):** the 1 px `suit_hi` edge outside the outline, following the chamfer (§16 F9).

- **Leader select (2026-09-29, `src/leaders.py`; proof `proofs/kit-leaders.png`), design/leader-select-spec.md §9.2:**
  - **Tap props** `prop_pen` (Bennett), `prop_phone` (Ben Gvir), `prop_chair` (Liberman), `prop_ruler` (Eisenkot),
    `prop_calculator` (Smotrich), `prop_coffee` (Deri), `prop_stapler` (Golan): d 1, ≤ 20x20 incl. outline + rim (they
    ride with the leader like the hat, so they carry the touchable rim), 2 frames rest + squash (x1.12 / y0.88 about the
    grip). `pivot` = the grip, drawn on the leader's `propMouth` (the TA's track); `points.mouth` per frame = the coin
    origin. The phone's screen is plain with a curved forward arrow (RTL: it points left), no app marks. The chair is
    one office swivel chair standing on the floor, never at a table (do/don't 13). Smotrich's calculator and Deri's cup
    are in their refs, so those two props are UI-only (chips, the ☕ buff).
  - **Generic sources** `source_donor` (a faceless figure in a suit, a plain envelope and a pen; f1 the flap lifts) and
    `source_funds` (a fat steel lever-arch binder with a blank tab, coins spilling from the top; f1 a coin hops), 40 ap
    with outline + rim like the hand-drawn three, + 24x24 icons and silhouettes by the same rule. `source_advisers`
    (t6) is the TA's slate recolour of the qatari render.
  - **`suitcase_plain`** (+ `_norim`): the Suitcase pixel for pixel without the DOHA sticker (`props.suitcase(sticker=
    False)`), for every round but Bibi's. Still maroon: it is still the Suitcase.
  - **`spin_slot_A…I`** (A-E, G-I; F keeps `spin_s12`), 24x24 like the spin icons: A a coin with a plus badge, B a
    stopwatch, C a crescent moon over a coin stack (no star beside it: the `trophy_moon` lesson), D a thermometer low
    beside a down arrow, E a 4-point sparkle (never a 5- or 6-point star), G the mic with the spins tab's pink arcs, H a
    rising arrow over a "x1.5" tag, I a rival's steel card with a plus.
  - **Picker kit (UX rtl-map §8.3-8.4):** `pick_tile_{idle,pressed,focus,selected}`, a 32x32 9-slice [4,4,4,5] (focus
    and selected 34x34 [5,5,5,6]: grow the rect 1 art px): a raised `ui_bubble` card for the round avatar, the name
    (`white` 13.6:1) and the party (UX's #9e99ad: **5.2:1** on the face, ≥ 4.5 confirmed). Every state has a shape:
    pressed = 1 art px down into the lip, focus = a dashed white ring, selected = a solid 1-px pale `rim` ring.
    `pick_random` (the הפתעה tile: a folded paper slip with a violet "?", no letters, never going into a box).
  - **Picker avatars** `avatar_pick_<c>` 32 / `avatar24_pick_<c>` 24 (TA render-down): the chat avatars' heads on one
    neutral `rim` ring. The chat avatars' rings are coloured by react type (red, gold, blue, grey) and would read as
    party or bloc colours on the picker (UX: "never a party colour or a bloc colour"). The app icon uses the same heads.
  - **Press skin icons (UX §4.3):** `thermo_icon_press` 11x11 and `chip_icon_press` 9x9, a folded newspaper (masthead
    bar, columns), so the press has its own non-colour sign; the gavel stays the court's (Bibi's).

### 17.1 Wave 7: the mobile-first layout (`src/wave7.py`, `ux/mobile-first-layout.md` §10, 2026-09-29)

The stages stay the approved 180x320 art; nothing repaints them. The phones' extra columns and rows get art that is
drawn *around* (wings) and *over* (lane, plaza) the stage on its own x4 grid. Proof: `proofs/kit-w7-mobile.png`
(every era at 215 and 260 columns), `proofs/kit-w7-brawl-cue.png`.

| Need (UX) | Pieces | Rules |
|---|---|---|
| A1 the lane | `lane_<era>` redrawn **32x28** (same ids) | The lip, its dither and the course seams stay; added running-bond joints (8-px slabs far, 16 near), a lit top-left pixel per slab, the press cable (every era: the TV crews are always there), a flyer / spike-tape X / dropped page / carpet weave. Every swatch ≥ 4.5:1 against `rim` (asserted), so the flying Suitcase keeps its edge. |
| A1 the plaza | `plaza_<era>` **128x96** tile | The floor from art row 258 to the screen bottom. The apron's own base with one-value-step texture: 12-row courses (nearer than the lane's 4-7), slabs 32 wide, broken lit edges, 50 % checker scuffs, sparse litter, the cable meandering off. 128 wide so a phone shows under two copies across and the litter never reads as wallpaper. **No barrier or fence** in it (a fence repeated down the screen would read as a border fence: do/don't 13), no gold, no text. |
| A2 the wings | `wing_<era>_l` / `_r`, W x 230 | Each era's rows 0-229 continued past the art's edges, tileable with period W = a multiple of the era's rhythm (Balfour 20: wall panels every 10; Knesset 22: the lawn's specks every 11; courthouse 60: panels 30, tubes 60; Washington 36: specks every 9). Drawn in art coordinates on a canvas that wraps x mod W, so an element crossing the art's edge (Balfour's tree and protester, the courthouse benches, Washington's blossom trees) continues exactly and repeats every W; wing-native elements (more protesters with blank signs, an olive tree, an aisle between benches) never cross the wing's own edges. Balfour's protesters are the art's own seeded crowd; its barrier posts go every 10 (the art's are 9 apart, which does not tile). |
| A3 the XL picker heads | `avatar_pick_<c>_d3` 96, `_d2` 64 (TA render-down, `showcase/src/build.py` `avatar_pick_xl`) | First-generation crops from the ref (never an upscale of the 32), the leader's locked d 3 palette, binary alpha, the same neutral `rim` ring (4 px: 8 logical at the picker's 2 logical per px, the 32's weight at x4) and cream disc. |
| Animator: brawl cue | `brawl_cloud_cue` 26x20 x 4 | `brawl_cloud`'s loop redrawn at half size so the stage cue draws at x4 (the grid) instead of x2: the same puffs, shading bands, sleeves with cuffs and fists, shoes, the flying page and star; limbs keep their fist inside the frame. |
| Animator: court echo | `court_window` `spots` (data) | Moved out of the sky band (the phones crop art rows < ~110 under Row A and the toast dock) to the right side, clear of the leader: Balfour (167, 167) behind the wall, right of the lamp; Knesset (158, 166) on the lawn at the colonnade's end; Washington (162, 152) in the horizon band right of the mansion. |

### 17.2 Wave 9: the envelope flap (`src/wave9.py`, the Animator's wave-B ask, 2026-09-30)

`sheet_modal`'s title band is the v4 envelope's flap, baked into a 9-slice, so nothing could move it. Wave 9 splits
it into a body and a flap layer; `sheet_modal` itself does not change. Proof: `proofs/kit-w9-flap.png` (per row: the
body, f0, f1, f2 over the body, today's `sheet_modal`; at 38x38, 158x64 and 158x120 art px).

| Piece | Size | What |
|---|---|---|
| `sheet_modal_body` | 38x38, 9-slice [7, 23, 7, 7] | The envelope without its flap: the same edge, outline, bevels, body and content box. Never drawn alone. |
| `sheet_modal_flap` | 38x24 x 3, 3-slice [7, 0, 7, 0] | f0 **sealed**: the flap as a V from the corners down to the point, like the back of a closed envelope. f1 **lifting**: the sides at mid-band. f2 **open**: the flap lifted flat into the title band where the title is printed = sheet_modal's band, pixel for pixel. Transparent below the flap. |

**Rules:**
- **Body + f2 = `sheet_modal`, every pixel.** `wave9.py` asserts it, so the rest look is the approved v4 look.
- **The V lives in the stretched centre only.** The fixed 7-column margins stay flat, and the V is one even
  staircase across the centre columns (point at the middle two). So it stretches into a clean, symmetric V at any
  modal width, not a bent one. The white edge stays one connected line on the steep frame, with its shadow under it.
- **"Open" is the band, not a flap pointing up.** The Animator's sketch had the open flap pointing up. But the rest
  frame has to be the approved band (the title sits in it), and 24 rows have no room above the hinge. So the motion
  is the envelope's V flap unfolding into the band: sealed → lifting → open. At 40 ms a frame it reads as "the
  envelope opens", and it lands on the look Bar approved.
- **24 rows:** the flap's shadow at the point is on art row 23, the first row of `sheet_modal`'s stretched centre.
  In the 9-slice that row stretches into a dark slab under the point (visible in the proof's right column). In the
  flap strip it stays one art row, so the flap path also fixes that slab. Flagged for the developer: moving every
  modal to body + flap f2 removes it everywhere.
- **Blank:** no seal, no emblem, no text, no party mark. It is a civic object (§2.4).

### 17.3 Wave 10: UX build review 2 (`src/wave10.py`, `ux/review-2026-09-30.md`, 2026-09-30)

New ids only, except the coalition tab icon (same ids, redrawn) and `sheet_modal`'s slice (pixels unchanged). Proof:
`proofs/kit-w10-review2.png` (before | after in context, at the game's x4).

| UX | Piece | What |
|---|---|---|
| U2 / A4 | `button_white_{default,pressed,disabled}` 24x20, [3,3,3,4] / [3,5,3,2] | The v4 primary: the flag's white on its blue. A white face, a silver bottom/right shade, a 2-row lip in `flag` over `flag_dk` (the key's side), the outline. Label `flag` 8.46:1; pressed = a silver face down 2 into the lip (the blue side goes), 6.40:1; disabled = the shared sunk slate. White vs the secondary's `ui_bubble` 7.52:1 (was 1.13:1). Same size, slices and content box as `button_primary_*`: a drop-in. |
| U2 | (none) | O3's `ELECT_GO` takes `button_gold_*`, which already is the "עוד סבב!" CTA's skin at full width (the ticker, 704x80): no new id. UX's `ui_button_evolve` is the fork's blue diamond in `art.json`, not the gold CTA. |
| U7 | `card_row_silhouette` 32x30 [4,4,4,4] | A not-yet-revealed row on the white pane as a blank pale slip: `ui_mute` face, 1 px `ui_rule` edge (5.58:1 on the pane; the face is 1.33:1), sunk 1 px, no ink outline. Name in `ui_panel` 8.87:1. The icon is `<silhouette>_pale` (pipeline): `ui_dim` mask, `ui_rule` edge. |
| U7 | `chat_system_pill_navy` 20x13 [4,3,4,3] | T3's system pill on the v4 thread: a flat `ui_scrim` well, a `ui_rule` edge, label `ui_mute` 12.91:1. `chat_system_pill` stays (the picker's chip). |
| U8 | `tabicon_coalition_{active,idle}` (same ids) | Two bubbles, the front one with three `ui_bubble` dots, the back one `ui_mute`. No digits. The badge (top-left) sits over the back bubble; its rounded corner leaves the first dot whole. |
| U10 | `notice_frame` 40x40 [3,7,3,5] | EVOLVE_TX as the gate's printed notice: a white card ruled edge to edge in flag blue (top 3 + gap + 1, bottom 1 + gap + 1), outline, for the flag-blue page. Data `colors` = page `flag`, title `flag` (8.46:1), text `night` (13.88:1). **A card, not full bleed:** a white screen with a blue stripe at its top and bottom is the flag's layout with the text where the star sits (§2.4's rejected "whole page as the flag"). |
| A5 | `booth_frame_tall` 40x46 [6,16,6,4] | `booth_frame` with a 12-row flag header; `titleBox` [6, 2, w-12, 9] for the title, white on flag 8.46:1. The opening and wings are `booth_frame`'s, 6 rows lower. |
| U1 / T1 | `sheet_modal` slice [7,23,7,7] → **[7,24,7,7]**, content y 24 | Rows 0-23 (the band, the flap point and its shadow row) are fixed, so the stretched centre is plain body: no slab under the point on a modal that still draws `sheet_modal` alone (the kit says to keep it where the flap does not animate). Body + flap needs nothing. |

## 18. Foundations (referenced, not paraphrased)

v1 §15's list stands (colour theory, palette construction, squint test, colour-blindness redundancy,
shape language, silhouette test, value separation, prop interactivity class, WCAG contrast, icon design
at small sizes, wordmark thumbnail legibility), under `gamestudio/.claude/skills/`.
