# style-guide — Monkey Bananas (pixel art, 100% procedural)

Owner: 2D Artist. Consumers: Animator, Technical Artist, UX Designer, Game Developer, Audio Director (marketing coordination).
Source of truth for pixels: [`sprites.ts`](sprites.ts), generated from [`tools/build-sprites.mjs`](tools/build-sprites.mjs). Edit the generator, not the output. Check the result with `node art/verify-sprites.mjs` and look at [`contact-sheet.html`](contact-sheet.html). The contact sheet includes a scene mock shown normal, in greyscale, and under deuteranopia and protanopia simulation.
> **v1.1 (bright UI) is current.** §11 defines the UI and HUD visual language: bright, rounded and toy-like. It supersedes the v1.0 dark-plum UI rules, which are marked ~~superseded~~ where they appear below (§2 `p` row, §3 UI rows and UX pair table, §7 UI 9-slice set and text colours). Stage art (bananas, critters, environment) is unchanged except for the sunnier sky bands.

Foundations are referenced, not restated here: the studio skills `style-definition-and-guide/references/color-theory-foundations.md`, `character-design/references/shape-language-archetypes.md`, `environments-and-props/references/value-separation.md` and `ui-visual-design/references/wcag-contrast.md`.

## 0. Principles
1. **The banana is the brightest thing in the stage band (y 160–664).** Banana yellow is the highest-value, most saturated mass there, and the sky never gets lighter than the fill it frames. *v1.1:* the cream UI panels (L 0.91) are lighter than the banana, but they live outside the stage. The only UI inside the stage is the transient buff chip and banner, which are smaller than the banana and sit above it.
2. **Yellow means bananas.** Banana yellow (`h` `Y` `y`) is used only on bananas and on the banana currency. Golden amber (`O` `o`) is used only on the Golden Banana. A player never has to learn another meaning for either hue.
3. **Chunky, round, sincere.** Silhouettes are round and blobby (friendly shape language). The monkeys take bananas deadly seriously, and the absurdity comes from props such as lanyards, neckties and goggles, not from grotesque faces.

## 1. Lineage
- **Stardew Valley** (16×16 icon craft): chunky 1-px dark outlines and 2-tone shading plus a highlight on every 16-px item. We take its icon legibility at 1×.
- **Kenney "Tiny" packs / Pico-8 cart art**: small palette, and every pixel earns its place. We take the palette discipline: ≤ 24 core colours for stage art, plus 14 v1.1 UI colours (§11.2), with a 40-colour ceiling and no one-off hues.
- **Cookie Clicker**: one big friendly clickable centrepiece over a quiet background. We take the figure/ground hierarchy.
- **Anti-reference.** We are not Hyper Light Drifter-style moody pixel art: no low-key value structure and no desaturated palette. This is an idle game, looked at for hours, so it stays warm and high-key on the figure layer.

## 2. Palette (38 colours: 24 core + 14 v1.1 UI, see §11.2; `.` = transparent; `@` is reserved by the pipeline as the tint mask)

| Char | Hex | Role | Usage rule |
|---|---|---|---|
| `k` | #2b1b24 | ink | All figure outlines, eyes, mouths. Warm plum-black; never pure #000 |
| `w` | #fff8ec | warm white | Glints, badge, hard hat, glove, UI glyphs, UI text, floaters. **Golden Banana halo** |
| `h` | #fff3a0 | banana highlight | **Bananas only** |
| `Y` | #ffd23a | banana yellow | **Bananas and banana currency only** |
| `y` | #d9a21c | banana shade | **Bananas only** |
| `O` | #ff8f1f | golden amber | **Golden Banana only** (and its radar blip and gold particle) |
| `o` | #b8481a | golden shade | **Golden Banana only** |
| `B` | #8b5a35 | fur / wood | Monkey fur, trunk, catapult, ladder, dirt |
| `b` | #56331f | fur shade / wood dark | Shade of `B`; banana stem and tip |
| `W` | #cf9255 | fur highlight / light wood | Top-left highlight on fur and wood; burlap |
| `F` | #f0c090 | face | Monkey face masks and palms |
| `f` | #c7875a | face shade | Shade of `F`; nose |
| `L` | #a8d85a | leaf highlight | Leaves, grass tips, button hover face |
| `G` | #4f9f3a | leaf | Foliage, grass, buy-button face |
| `g` | #2a6334 | leaf shade | Foliage shade **and foliage outline** (environment ink) |
| `R` | #d8433a | red accent | Necktie, sweatband, stamp ink, fuel can, flags, Big Banana cheeks, "off" slashes |
| `r` | #8e2a36 | red shade | Shade of `R` |
| `A` | #3f7fd6 | blue accent | Intern lanyard and badge photo only |
| `s` | #bdb4c2 | light metal | Metal, shade of white objects, cloud underside |
| `S` | #6f5f73 | dark metal | Metal shade, panel rim, **disabled button face** |
| `p` | #452c3e | ~~UI panel~~ legacy dark panel | ~~Panel fill (HUD and overlays)~~ superseded by §11. Kept for the pipeline's plain-tint checks and as a fallback dark card |
| `D` | #1c55a3 | sky top | Sky band 1. *v1.1:* was #1f4766, now a saturated royal blue |
| `T` | #2773cc | sky mid | Sky band 2. *v1.1:* was #347896, now a sunny azure |
| `t` | #2c845e | canopy haze | Sky band 3, the far-jungle haze behind the diorama. *v1.1:* was #3b8574, now a lush green |

**Hue-shift rule.** Shadows shift warm-to-dark (yellow → ochre, fur → brown-plum). Highlights shift toward warm cream. Nothing shades to grey or black.
**Golden ≠ Big Banana.** Big Banana hues sit at 42–53° and the Golden Banana at 18–29°. The Golden Banana is also ≤ 0.35× the Big Banana's size (16 vs 48 px at the same art scale), is a horizontal smile crescent rather than an upright one, has no face, and wears an exclusive `w` halo plus a sparkle. `verify-sprites.mjs` asserts that neither sprite uses the other's colours.

### Sky gradient bands (the developer draws these procedurally, as flat bands with no dithering)

| Band | Colour | Fraction of diorama height (top → bottom) |
|---|---|---|
| 1 | `D` #1c55a3 | 0.00–0.22 |
| 2 | `T` #2773cc | 0.22–0.50 |
| 3 | `t` #2c845e | 0.50–0.72, then the ground (`env_grass` over `env_ground`) |

*v1.1 sky rule:* the bands became more saturated (reading as sunnier) while each band's luminance was **held** inside the window that keeps both the banana fill `Y` and its `k` ink at ≥ 3:1. For `T` and `t` that window is 0.142 ≤ L ≤ 0.193. A lighter, pastel sky was rejected: `Y` against #4aa8e0 is 2.0:1.

Band edges snap to whole art pixels (multiples of 4 logical px). They are also exported as `SKY_BANDS` in `sprites.ts`.

## 3. Value structure (squint test)
| Layer | Colours | Relative luminance |
|---|---|---|
| Sky / haze (background) | `D` `T` `t` | 0.05–0.19 |
| Environment props | `g` `G` `B` `W` | 0.05–0.27, grouped with the background |
| Figure: Big Banana, Golden Banana, critters | `Y` `h` `O` `w` `F` | 0.41–0.90 |
| ~~UI panels~~ | ~~`p` fill with `w`/`Y` text~~ | superseded: v1.1 values in §11.6 |

The Big Banana's fill (`Y`, 0.68) is ≥ 3:1 against every background band. The greyscale scene mock in the contact sheet shows the banana as the lightest mass on screen.

### Contrast table (from `node art/verify-sprites.mjs`; stage rows updated for the v1.1 sky)
| Pair | Ratio | Verdict |
|---|---|---|
| Big Banana `Y` vs sky top `D` / sky mid `T` / haze `t` / foliage `g` | 5.05 / 3.29 / 3.18 / 4.95 | ≥ 3:1 graphical object, passes against every band |
| Ink `k` vs `T` / `t` | 3.43 / 3.56 | every figure outline ≥ 3:1 against the sky |
| Golden halo `w` vs `T` / `t` | 4.51 / 4.35 | passes |
| Golden fill `O` vs `T` | 2.09 | fill alone fails, **so the halo plus the `k` ink carry the Golden Banana**. This is why the halo exists |
| ~~UI text `w` on panel `p` / banana count `Y` on `p`~~ | — | superseded by §11.6 |
| ~~Raised-control label `k` on face `L`~~ | — | superseded by §11.6 |
| ~~Raised face `L` vs panel `p` / sunken rim `s` vs `p`~~ | — | superseded by §11.6 |
| Floater `w`+`k` / crit floater `Y`+`k` | 15.48 / 11.31 | passes |

**Colour-blind check.** Under deuteranopia and protanopia simulation (the contact-sheet scene mock), Golden amber and Big Banana yellow converge. They stay distinct through size (0.33×), silhouette, the halo and the sparkle, so colour is redundant. Button, pill, toggle and tab states are carried by geometry (raised with lip versus sunken well; open versus closed tab with underline) and by value (light `L` face versus dark `p`/`k` well), not by hue. The sound and music "off" states add a red ✕ or slash **and** change shape.

### ~~UX contrast pairs C1–C11, N1–N7 (v1.0 dark UI)~~ — superseded by §11.6
The v1.0 table below is kept for history. Its UI pairs no longer describe the game: `node art/verify-sprites.mjs` now computes the v1.1 pairs from `UI_THEME`.

Computed live by `node art/verify-sprites.mjs`, which fails the build on any miss. Text ≥ 4.5:1; C1/C5 target 7:1; non-text ≥ 3:1.

| ID | Foreground / background (palette chars) | Ratio | Result |
|---|---|---|---|
| C1 | bank `Y` / top-bar panel `p` | 8.64 | pass (≥ 7 target) |
| C2 | bps and Thumbs `w` / `p` · Frenzy gold bps `O` / `p` | 11.82 · 5.47 | pass |
| C3 | Evolve enabled `k` / raised `L` · disabled readout `w` / sunken well `p` | 9.83 · 11.82 | pass (**was a fail** with `w` on `G` = 3.13; fixed by the `L` face) |
| C4 | row name `w` / `p` · line 2 `s` / `p` · can't-afford row (`ui_panel[1]`, `k` fill) `w`/`k` · `s`/`k` | 11.82 · 6.22 · 15.48 · 8.15 | pass |
| C5 | BUY pill `k` / `L` · NEED pill `w` / `p` | 9.83 · 11.82 | pass (≥ 7 target) |
| C6 | selected tab `w` / `p` · unselected `s` / `k` · badge digit `k` / `L` | 11.82 · 8.15 · 9.83 | pass |
| C7 | ticker `w` / `p` · "NEWS" `k` / tag chip `L` | 11.82 · 9.83 | pass |
| C8 | floater and "CATCH IT!" `w` / outline `k` · crit `Y` / outline `r` | 15.48 · 5.73 | pass |
| C9 | banner `Y` / `p` · buff chip text `w` / `p` | 8.64 · 11.82 | pass |
| C10 | overlay text `w` / `p` · group labels `s` / `p` · toggle ON and button labels `k` / `L` · toggle OFF `w` / `p` · RESET `w` / `r` | 11.82 · 6.22 · 9.83 · 11.82 · 7.85 | pass (plain `w` on `R` would be 4.16 and fail, hence the dark `r` face) |
| C11 | EVOLVE_TX `k` on white card `w` · reduced motion `w` on `p` | 15.48 · 11.82 | pass |
| N1 | raised face `L` / `p` · sunken, tab, toggle-OFF and destructive rim `s` / `p` | 7.51 · 6.22 | pass |
| N2 | progress fill `L` / track `k` (thin bars: lower row `G` / `k`) · golden buff fill `O` / `k` | 9.83 (4.94) · 7.16 | pass |
| N3 | focus ring (`ui_focus`) outer `w` / panel `p` and sky `D` · inner `k` / raised face `L`, sunken or destructive rim `s` | 11.82, 9.25 · 9.83, 8.15 | pass. The ring hugs the control's outer edge, so the destructive `r` face never touches it (`k`/`r` would be 1.97) |
| N4 | Big Banana outline `k` / sky `T`, haze `t`, grass `G` (the sprite's bottom 13 px dip below the ground line at y523) | 3.33 · 3.73 · 4.94 | pass. Worst case is `T` (the banana starts at y296, below the `D` band's end at y271); the Frenzy halo behind it only raises contrast |
| N5 | Golden halo `w` / sky `D`, `T`, `t`, ticker `p` | 9.25 · 4.65 · 4.15 · 11.82 | pass **via the halo**. The `k` outline alone fails over `D` (1.67). The hue differs: Golden 18–29° vs Big Banana 42–53° |
| N6 | silhouette rim `s` (`sil_*`) / row panel `p` | 6.22 | pass (was a would-be fail: a `k` silhouette on `p` is 1.31) |
| N7 | pointer `k` outline / sky `T` · `w` fill / panel `p`, sky `D` | 3.33 · 11.82 · 9.25 | pass. For any background, either the `w` fill or the `k` outline clears 3:1: both failing would need 0.28 < L < 0.14, which is impossible |

~~**Rule adopted from this pass:** on the dark panel `p`, a control's edge is never its `k` outline.~~ *Superseded (v1.1): on the light grounds every control's edge **is** its 1-px `k` ink (≥ 6.76:1 on every v1.1 ground, §11.6).* Old text: It is either the light `L` face (raised) or a 1-art-px `s` rim (sunken / tab / destructive).
**Golden amber, extended meaning:** `O`/`o` may also colour text and bar fills of **buffs granted by the Golden Banana** (Frenzy bps, buff-chip bar). It still never appears on anything that isn't the Golden Banana or its effect.

## 4. Lighting model
**Cel-shaded, 3 bands: highlight, base, shade.** The key light is from the top-left.
- The shade band sits on the bottom and right about 25–35% of the form. The highlight is a 1–3 px band on the upper-left curve. Specular glints (`w`, 1–3 px) appear only on the Big Banana and the Golden Banana.
- There is no ambient occlusion, no dithering, no gradients inside sprites and no time of day. Sky gradients are flat bands.

## 5. Line and edge treatment
- **Figure sprites** (bananas, critters, icons, UI glyphs) get a **1-px `k` outline**, 4-connected, on the outside of the silhouette. The generator's outline pass applies it uniformly. Interior lines appear only for features (eyes, mouth, finger splits), also in `k`.
- **Environment sprites** get a tonal outline in the darkest tone of their own ramp (`g` for foliage), or none (trunk, cloud, tiles). This lets them recede behind the figure layer.
- **Particles** have no outline (2–5 px).
- No anti-aliasing. Every pixel is one palette colour, and nothing is blended. `pixelArt: true`, `roundPixels: true`.

## 6. Rendering level and scale
- One art pixel is 4 logical px by default (the README's pixel conventions). Scales are integers only. The Big Banana renders at ×5 (240 px). Icons render at ×3 (48 px) in shop rows, and critters at ×3 or ×4 in the diorama. The Golden Banana **must use the same scale as the Big Banana, or smaller**, to keep the 0.35× rule.
- Production cost band (for re-authoring): a 16×16 icon takes about 15–25 min, a critter with 2 frames about 30 min, and the Big Banana is procedural (parameters `BB` in the generator).
- Squash: the Big Banana is **never scaled at runtime**. The Animator's quantized driver (`motion/object-motion.md` §1.4) swaps between 5 authored frames, so the pixel grid never shimmers.

## 7. Components and states

**Big Banana `bigBanana` (48×49 ×5).** Every frame shares the bottom baseline: the ink sits on row 48 and row 0 is spare, so the stretch fits. The pivot is bottom-centre. The widths follow X ≈ 2 − Y.

| Frame | Pose | Visible W×H (art px, incl. ink) | Height ratio | Face |
|---|---|---|---|---|
| 0 | rest | 28×45 | 1.000 | open eyes |
| 1 | squash 0.94 | 28×42 | 0.933 | open eyes |
| 2 | squash 0.88 | 30×39 | 0.867 | happy squint ^ ^ |
| 3 | deep squash 0.84 / crit | 32×38 | 0.844 | squeeze > < |
| 4 | stretch 1.02 (overshoot) | 26×46 | 1.022 | open eyes |

Each ratio sits inside the Animator's quantize band (§1.1), and `verify-sprites.mjs` asserts this. The hit area is the **rest** bounds (`SPRITE_META.bigBanana.restBounds`) + 16 px and never follows the frame. The ratios are measured on the 45-row rest, not on 48: the 1-px ink doesn't scale. A dev-mode drift check should compare against `SPRITE_META.bigBanana.heightRatio`.

**Big Banana halo `bigBanana_halo` (44×56).** A soft pixel oval in `h`: a solid core plus two dithered rings (50% checker, then 25%). It is drawn **behind** the banana at the same ×5 scale, with origin (0.5, 0.5), centred on the banana's rest-bbox centre (`SPRITE_META.bigBanana_halo.alignTo.canvasPx` = [24, 26.5] from the banana canvas top-left). Code sets the alpha: 0.3 on hover, 0.35–0.85 for the Tap Frenzy pulse. It never follows the squash frames.

**Golden Banana `goldenBanana` (16×16 ×4).** Frames: 0 idle (upright, sparkle), 1 sparkle flare, 2 tilt −8° (counter-clockwise, the right tip rises), 3 tilt +8° (clockwise, the stem side rises). The tilts are hand-cleaned nearest-neighbour rotations, not flipX, because the crescent is asymmetric. They replace runtime rotation. All four frames keep the halo, and the idle sparkle stays in place so the tilt loop doesn't add a shimmer. The pivot is centre.

**Critters `critter_<id>` (16×16 ×2).** Frame 0 is the rest pose. Frame 1 has the head down 1 px, the tail flicks, and the prop acts: the pickaxe drops, the stamp comes down, the goggle swirl turns, the clock ticks, the intern blinks, the fronds sway, the catapult arm dips, the rocket flame flickers, the moon's flag waves and a star twinkles. Each monkey has one unique primary feature: the intern a blue lanyard and badge, the hard-hat crew a white hard hat and pickaxe, the bureaucrat a white collar, red tie, stern brows and banana stamp, and the time chimp green goggles and a clock.

**Icons `icon_<id>` (16×16).** They are legible at ×3 (48 px) on the `p` panel. Every icon has a `k` outline, so it also reads on any background.

~~**UI 9-slice set (8×8 sources, 2-px borders).**~~ **Superseded by §11.3–§11.5** (rounded sources; insets measured, up to 8 art px, 17 for the toggle). The v1.0 description below is history. leftWidth = rightWidth = topHeight = bottomHeight = **2 art px**. The 4×4 centre is flat colour; every stretch band is flat along its axis, and `verify-sprites.mjs` checks this. The minimum render size is 4×4 art px. Never trim. The progress-bar pieces are 4×4 with 1-px borders.

Two states carry the whole system:
- **Raised** (available / on / BUY): `k` outline, `w` top highlight, `L` face, `G` lip. Labels are `k`.
- **Sunken** (unavailable / off / NEED): `s` rim, `k` inner shadow top and left, `p` well. Labels are `w`.

| Sprite | Frames |
|---|---|
| `ui_panel` | 0 normal (`p` fill, `S` rim) · 1 dim: a shop row that can't be afforded (`k` fill). This replaces the "−20% luminance" rule, which on `p` is a near-invisible change and isn't a palette colour |
| `ui_button` | 0 default (raised) · 1 pressed (inset top shadow; **label +1 art px down**) · 2 disabled/sunken (e.g. EVOLVE "NOT READY", label `w`) · 3 hover (mouse only: `w` inner rim) |
| `ui_pill` (price button, BUY vs NEED channel) | 0 BUY raised · 1 NEED sunken · 2 pressed |
| `ui_toggle` | 0 ON raised ("ON" `k`) · 1 OFF sunken ("OFF" `w`) |
| `ui_tab` | 0 selected (`p` face joins the shop panel, open bottom, `L` underline on row 6, label `w`) · 1 unselected (recessed `k` face, 1 px lower, closed bottom, label `s`) |
| `ui_button_danger` | 0 default (`s` rim, `R` light edge, `r` face, label `w`) · 1 pressed · 2 hover |
| `ui_badge` | 0 `L` chip with a `k` digit. Also the ticker "NEWS" tag chip |
| `ui_bar_track` | 0 `S` rim, `k` well. For 2-art-px bars (Evolve button, buff chip) draw flat `k` rows |
| `ui_bar_fill` | 0 progress (`L` over `G`) · 1 Golden-buff (`O` over `o`). For 2-art-px bars: row 0 `L`/`O`, row 1 `G`/`o` |
| `ui_focus` | 0 keyboard focus ring: `w` outer + `k` inner, transparent centre, drawn 2 art px outside the control |

**Glyphs.** 8×8 (`w` on a `k` outline): `ui_lock`, `ui_sound_on/off`, `ui_music_on/off`, `ui_gear`, `ui_close`, `ui_arrow_up`. 16×16 for overlays at ×4 (64 px, 104×104 hit): `ui_gear16`, `ui_close16`.

**FTUE pointer `ui_pointer` (16×16 ×2).** A white cartoon glove with a `k` outline. Frame 0 points **up**: rotate 90/180/270° for → ↓ ←. Frame 1 points **up-left** (↖): flipX for ↗, flipY for ↙. The fingertip hotspots are in `SPRITE_META` ([6,1] and [1,1]). Two frames are needed because an up-left hand rotated in 90° steps only ever yields diagonals.

**Silhouette "???" rows `sil_<producerId>` (16×16).** The producer icon's outer contour becomes an `s` rim and everything else is `S`, so no interior feature leaks identity. `sil_<next producer>` replaces the icon in the silhouette row.

**Text colours** (the Technical Artist bakes the font; these are the colour tokens). *v1.1:* the floater, crit and "CATCH IT!" rows below still hold. The panel and control rows are superseded by `UI_THEME` (§11.4):
- Normal floater "+N": `w` fill with a 1-art-px `k` outline.
- **Crit floater "+N!" and Tap Frenzy floaters: `Y` fill with a 1-art-px `r` outline**, larger (44 px) and with "!". It differs from the normal floater in hue, value, size and glyph.
- **Labels on controls are never outlined:** `k` on raised faces (`L`), `w` on sunken wells (`p`) and on the destructive face (`r`). The outlined font variants are only for text drawn over the stage (floaters, "CATCH IT!").
- Bank and cost numbers: `Y` on `p`. Labels: `w` on `p`. A can't-afford cost is `s` on `p` (6.22:1), which is a value change, not red.

**Environment.** `env_grass` tiles in x and `env_ground` in x and y. `env_palm_trunk` tiles in y (a 4-row ring rhythm) with `env_palm_crown` on top. `env_foliage_a`/`env_foliage_b` are decorative clumps along the ground line, and `env_cloud` drifts on band 1 or 2. **Decorative palms carry no bananas**: yellow in the diorama always means a producer or the hero. All environment art is decorative and never interactive.

**Particles.** `particle_chip` (2×2, the feel-spec tap chips), `particle_chunk` (4×4 banana chunk, bigger bursts), `particle_sparkle` (3×3 ×2, generic sparkle), `particle_gold` (3×3, the Golden catch burst only), `particle_leaf` (5×5 ×2, ambient or leaf fall).

## 8. Do / Don't
1. **Palette violation.** Do draw a hard hat in `w`/`s`. Don't draw it in banana yellow, because yellow then stops meaning "banana". This is why `icon_glove` and the hard hat are white.
2. **Value collision.** Do keep the sky at relative luminance ≤ 0.19 behind the banana. Don't use a pale mint or cream horizon behind it: an earlier draft's `t` = #6fb3a0 gave only 1.66:1 against `Y` and merged under squint, and it was darkened to #3b8574.
3. **Line-treatment drift.** Do put a 1-px `k` outline on every figure sprite through the generator pass. Don't hand-draw 2-px or black (#000) outlines on some sprites, and don't use a `k` outline on environment art, which would pull it forward onto the figure layer.
4. **Scale mismatch.** Do render the Golden Banana at the Big Banana's art scale or smaller. Don't upscale the Golden Banana to ×6 "so it's easier to tap". Use the 56 px hit radius instead, because size is one of its distinguishing channels.
5. **Motif violation (hue reservation).** Do use `O`/`o` only on the Golden Banana. Don't use amber for rocket flames, UI highlights or warnings. Flames are `R`/`w`.
6. **Face-feature drift.** Do give monkeys a 2×2 eye with a top-left `w` glint and a small `u` smile. Don't use a wide flat mouth line: at 16 px it reads as a mustache (caught and fixed in this pass).

## 9. Source-of-truth links
- Palette and sprites: `art/sprites.ts` (exports `PALETTE`, `SPRITES`, `SKY_BANDS`, `SPRITE_META`, and in v1.1 `UI_THEME`)
- Authoring: `art/tools/build-sprites.mjs` → `node art/tools/build-sprites.mjs`
- Verification: `node art/verify-sprites.mjs` (dimensions, palette keys, required ids from `design/content.json`, the 0.35× rule, hue reservation, and the contrast table)
- Visual check: `art/contact-sheet.html`, which opens from file://. v1.1 adds the HUD mock (main, greyscale, deuteranopia), a SETTINGS modal mock and a control-states strip at use size, all rendered with the TA's real 5×7 font

## 10. Negotiations and deferrals
- **UX Designer**, round 2: placement resolved (Big Banana 240,296 240×240, centre y≈416, inside sky bands 2–3). Every UI piece requested in `hud-layout.md` has been delivered, and all C1–C11 / N1–N7 pairs pass (table in §3).
- **Animator** owns timing. The poses are fixed here: 2 critter frames, 5 Big Banana frames (the quantized squash set, delivered per `motion/object-motion.md` §6), the halo, and 4 Golden frames (2 tilts).
- **Technical Artist** owns baking, atlasing and the 5×7 pixel font. Constraints on the TA: no trimming on the `ui_*` 9-slice textures, nearest-neighbour filtering, and the font needs outlined variants for text over the stage only (`w` fill + `k` outline, and `Y` fill + `r` outline for crits). Panel and control labels use the plain font: `k` on raised faces, `w` on sunken wells.
- **Deviation from the design `visualHook`s:** the glove and hard hat are white rather than yellow, to protect the banana-yellow reservation (the Objection was accepted by the Game Designer, round 2). All other hooks are drawn as specified.

## 11. v1.1 bright UI ("sunny toy box")

The v1.0 UI was dark plum panels with muted controls, and it read as moody. v1.1 keeps pixel art and the procedural rule (every pixel is still in code, in `tools/build-sprites.mjs`) and changes the UI and HUD language to **bright, saturated, rounded and chunky**, like toy blocks. Stage art is unchanged.

### 11.1 Lineage
- **Brawl Stars / Clash Royale menus**: chunky capsule buttons with a heavy dark outline, a bright face, a top gloss and a darker bottom lip that works as the extrusion. We take the press grammar: raised = lip, pressed = face drops 1 px and the lip disappears.
- **Kirby / Animal Crossing pastel UI**: cream cards with candy-coloured frames. We take the cream card with a coloured ring.
- **Arcade scoreboards**: bright numerals in a dark window. We take the single stat window on the pink banner.
- **Anti-reference.** We are not flat material UI (no hierarchy of elevation) and not neon-on-black (the stat window is the only dark ground in the HUD, apart from the 48-px marquee).

### 11.2 Palette additions (14; total 38 ≤ 40)
| Char | Hex | Role | Rule |
|---|---|---|---|
| `c` | #fff4e0 | cream | Panel, card, row and selected-tab fill. Chroma is too low to read as yellow; never use it as a banana |
| `m` | #d8f6e1 | mint | Alternate shop row (rows alternate `c` / `m`) |
| `i` | #e4dcef | lilac-grey | Can't-afford row fill; the soft lip under cream panels; knob shade |
| `I` | #b8a5dd | lavender | **Unavailable**: NEED pill, OFF toggle, disabled button, silhouette plate. Always sunken |
| `j` | #b98ff2 | lilac | Unselected tab, stat-window bezel, grape gloss, bureaucrat plate |
| `v` | #8fe052 | lime | **Available / go**: BUY pill, ON toggle, primary button, bps numerals, progress fill |
| `q` | #ff78bf | hot pink | Top bar, marquee trim, badges, card ring, focus ring inner, `juiceGain` |
| `Q` | #c42a7e | deep pink | Pink lip, focus ring outer, Evolve drop shadow, `juiceGainOnLight` |
| `e` | #4ccbf5 | sky cyan | Shop tray, thumbs numerals, intern plate |
| `E` | #1f7fc6 | deep cyan | Rocket plate |
| `u` | #7c44d6 | grape | Evolve face, close disc, settings group labels, moon plate, silhouette rim |
| `U` | #3a1e72 | deep grape | The dark ground: stat window, marquee, banner, bar track, scrim, line-2 text, letterbox |
| `x` | #ff705f | coral | Destructive button face, hardhat plate |
| `a` | #3ee2c1 | turquoise | Timechimp plate |

**Hue reservations survive.** No v1.1 colour sits in the banana band (42–53°) or the golden band (18–29°), except the near-neutral cream. *Sunny orange was considered and rejected:* any saturated orange lands on top of Golden amber `O` (29°) and would break "amber = Golden". Coral (6°) takes its place. `verify-sprites.mjs` now fails any `ui_*` frame that uses `Y`/`y`/`h`. `O`/`o` are allowed only in Golden-buff frames (the Frenzy stat-window bezel and the golden bar fill).

### 11.3 Shape language
- **Every UI shape is rounded and procedural.** Corner arcs are transpose-symmetric pixel tables: r4 `[3,1,1,0]` (panels, tabs, chips, plates, focus ring), r6 `[4,2,1,1,0,0]` (modal card) and r8 `[6,4,3,2,1,1,0,0]` (capsule controls: on a 20-art-px control, r8 reads as a pill). Circles use quadrant tables: Ø8 for badges and Ø16 for the toggle knob and close disc.
- **Anatomy of a control, outside → in:** 1-px `k` ink → optional 1–2-px coloured ring → face → 1-row `w` gloss that hugs the top arc → 1–2-row lip in the face's shade that hugs the bottom arc. The lip is the toy "drop shadow". It lives inside the visual rect, so no layout rect grows.
- **States by geometry first, then value, then hue:**
  - Raised (lime, lip) means available.
  - Pressed: the face drops 1 art px, the lip goes and the gloss becomes a shade row. The label drops 1 art px.
  - Sunken (lavender `I` well, `u` inner shadow on top, no lip, no gloss) means unavailable.
  - Hover: a `w` inner rim.
- **9-slice insets are measured, not typed.** The generator builds each shape on a large canvas, and `crop9()` crops it to the smallest source whose centre bands are exactly 2 px and flat in every frame. The toggle is the exception: it has a fixed 36×20 source with hand-set insets 17/17/9/9, so the knob never sits in a stretch band. `SPRITE_META[id].cornerArtPx` records each radius.
- **The retired rule "9-slice border ≤ 2 art px"** is replaced by three falsifiable checks in `verify-sprites.mjs`:
  - insets fit the smallest rect the layout draws each sprite at (`MIN_RENDER_ART`);
  - each corner slice is ≤ (rest size − 2)/2 on squishable controls (the Animator's `ui-juice.yaml` squish budget, `SQUISH`);
  - no inset exceeds 17.

### 11.4 Surface map (the developer wires every colour through `UI_THEME`)
| Surface | Sprite / frame | Colours | Text |
|---|---|---|---|
| Top bar | `ui_topbar` 0 (flat top bleeds off canvas, rounded bottom corners, `Q` lip + `k` = the 152–160 border) | `q` | — |
| Stat window (bank, bps, thumbs) | `ui_chip` 0 (normal), 1 (Frenzy: amber bezel). Rect 8,8,372,140 (UX-agreed; content box x20–368, y24–136; Thumbs icon y104) | `U` fill, `j`/`O` bezel, `u` glass gloss | bank `Y`, Golden roll `O`, bps `v`, Frenzy bps `O`, thumbs `e` |
| Evolve ready | `ui_button_evolve` 0/1/2, drop shadow `Q` | `u` face, `j` gloss, `U` lip | `w` |
| Evolve not ready | `ui_button` 2 | `I` well | `k`; bar track `U`, fill `v`/`G` |
| Evolve "!" badge, UPGRADES badge, NEWS tag | `ui_badge` 0 (circle at 8×8, capsule when wider) | `q` | `k` |
| Gear / close | `ui_gear16` (w, `i` shade, grape hub) / `ui_close16` (grape disc, white X) | | |
| Buff chip | `ui_panel` 0 | `c` | `k`; bar `U` track, `O`/`o` fill |
| Buff banner | `ui_banner` 0 | `U` fill, `q` ring, `Q` lip | `Y` |
| Ticker | `ui_ticker` 0 (panel **and** both occluders) | `U` marquee, `q` trim rows | `w`; milestone flash `juiceGain` `q` |
| Shop tray | `ui_tray` 0 (k + w top border, 712–720) | `e` | empty state `k`; scroll thumb `U` |
| Tabs | `ui_tab` 0 selected (cream, pink underline lip) / 1 unselected (sunken lilac, 1 px lower) | | `k` both |
| Buy-mode toggle | `ui_button` 0/1/3 | `v` | `k` |
| Shop rows | `ui_panel` 0/2 afford (by row index % 2), 1/3 can't afford | `c` / `m`; `i` | name `k`, line 2 `U` |
| Icon plates | `ui_plate` 0–7 per producer, 8 global upgrade, 9 silhouette; suggested rect row-relative 24,ry+8,80,80 | producer accents (`UI_THEME.producerAccent`) | — |
| Cost pill | `ui_pill` 0 BUY (lime, 1-row lip) / 1 NEED (lavender well) / 2 pressed | | `k` both |
| "???" row | `ui_panel` 1 + `ui_plate` 9 + `sil_<id>` (`U` mass, `u` rim) + NEED pill | | `k` |
| Overlay scrim | solid rect | `U` @ 0.6 | — |
| Modal card | `ui_card` 0 (r6, 2-px `q` ring, `Q` lip) | `c` | title/body `k`, group labels `u`, notes/version `U`, dividers `I` |
| Primary button (COLLECT, CANCEL, BACK) | `ui_button` 0/1/2/3 | `v` | `k` |
| Destructive (RESET) | `ui_button_danger` 0/1/2 | `x` face, `R` lip | `k` |
| Toggle | `ui_toggle` 0 ON (knob right) / 1 OFF (knob left) | `v` / `I` | `k`, centred in `labelRegionArtPx[frame]` |
| Focus ring | `ui_focus` 0, 2 art px outside the control | `Q` outer, `q` inner | — |
| EVOLVE_TX | solid card | `w`; reduced motion `U` | `k`; reduced motion `w` |
| Floaters / crit / "CATCH IT!" | outline font | unchanged (`w`+`k`, `Y`+`r`) | |
| Letterbox (page body) | — | `U` | — |

`UI_THEME` also carries `juiceGain` (`q`: valid on the `U` grounds only, 5.40:1) and `juiceGainOnLight` (`Q`: valid on cream and mint, 4.84 / 4.57:1). **Never** flash `q` text on cream, where it is 2.22:1.

### 11.5 Sprite reference and changes vs v1.0 (indices the code uses are unchanged)
| Sprite | Frames (index: meaning) | Insets L/R/T/B | r | Change vs v1.0 |
|---|---|---|---|---|
| `ui_panel` | 0 row A afford / buff chip · 1 row A can't · **2 row B afford (new)** · **3 row B can't (new)** | 3/3/4/5 | 4 | 0 and 1 keep their meaning. 2 and 3 are appended. Source 8×11 (was 8×8) |
| `ui_button` | 0 default · 1 pressed · 2 disabled · 3 hover | 6/6/8/8 | 8 | same indices; disabled label `w`→`k` |
| `ui_pill` | 0 BUY · 1 NEED · 2 pressed | 6/6/8/7 | 8 | same indices; NEED label `w`→`k` |
| `ui_toggle` | 0 ON · 1 OFF | 17/17/9/9 | 8 | same indices; fixed 36×20 with a knob; OFF label `w`→`k`; **label must centre in `labelRegionArtPx`** |
| `ui_tab` | 0 selected · 1 unselected | 3/3/5/3 | 4 | same indices; unselected label `s`→`k` |
| `ui_button_danger` | 0 default · 1 pressed · 2 hover | 6/6/8/8 | 8 | same indices; label `w`→`k` |
| `ui_badge` | 0 | 2/2/2/2 | circle | same |
| `ui_bar_track` / `ui_bar_fill` | 0 / 0 progress, 1 golden | 1/1/1/1 | 1 | same; track `k`→`U`, fill `L`→`v` |
| `ui_focus` | 0 | 3/3/3/3 | 4 | same; colours `w`/`k`→`Q`/`q` |
| glyphs, `ui_pointer`, `sil_*` | unchanged ids and frames | | | redrawn softer; pointer has a pink cuff; silhouettes `U`/`u` |
| **new** `ui_topbar`, `ui_tray`, `ui_ticker`, `ui_card`, `ui_banner` | 0 | 3/3/1/4 · 1/1/2/1 · 1/1/2/2 · 4/4/5/6 · 3/3/3/4 | 4·0·0·6·4 | new surfaces |
| **new** `ui_chip` | 0 stat window · 1 Frenzy | 3/3/4/3 | 4 | new |
| **new** `ui_plate` | 0–7 producers (content.json order) · 8 global upgrade · 9 silhouette | 3/3/4/3 | 4 | new |
| **new** `ui_button_evolve` | 0 default · 1 pressed · 2 hover | 6/6/8/8 | 8 | new; Evolve ready and the EVOLUTION confirm |

**Animator squish budget (accepted, `motion/ui-juice.yaml`):** delivered corner slices are 8/7 on the 20-art-px pill (budget ≤ 9), 8 on the 20-px buy-mode button, 9 on the toggle (budget ≤ 9, exactly), 5/3 on tabs, 8 on the 24-px Evolve (budget ≤ 11), 3/4 on the 16-px banner (budget ≤ 7) and 4/5 on the 12-px buff chip. Badges and knobs only grow, so they are true circles.

### 11.6 Contrast (computed by `node art/verify-sprites.mjs` from `UI_THEME`; text ≥ 4.5, C1/C5 target 7, non-text ≥ 3)
| ID | Pair | Ratio |
|---|---|---|
| C1 | bank `Y` / stat window `U` · Golden roll `O` / `U` | 9.03 · 5.72 |
| C2 | bps `v` · Frenzy `O` · thumbs `e` / `U` | 8.05 · 5.72 · 6.94 |
| C3 | Evolve ready `w` / `u` · not ready `k` / `I` | **5.44** · 7.37 |
| C4 | row name `k` / `c`, `m`, `i` · line 2 `U` / `c`, `m`, `i` | 15.00, 14.16, 12.28 · 11.98, 11.31, 9.81 |
| C5 | pill `k` / BUY `v` · NEED `I` | 10.08 · 7.37 |
| C6 | tab `k` / `c` · `k` / `j` · badge `k` / `q` | 15.00 · 6.44 · 6.76 |
| C7 | ticker `w` / `U` · NEWS `k` / `q` · milestone `q` / `U` | 12.36 · 6.76 · **5.40** |
| C8 | floater `w`/`k` · crit `Y`/`r` | 15.48 · 5.73 |
| C9 | banner `Y` / `U` · buff chip `k` / `c` | 9.03 · 15.00 |
| C10 | card `k` / `c` · group label `u` / `c` · note `U` / `c` · button `k` / `v` · disabled `k` / `I` · toggle ON `k` / `v`, OFF `k` / `I` · RESET `k` / `x` | 15.00 · **5.27** · 11.98 · 10.08 · 7.37 · 10.08, 7.37 · 6.02 |
| C11 | EVOLVE_TX `k` / `w` · reduced `w` / `U` | 15.48 · 12.36 |
| C12 | `juiceGain` `q` / `U` · `juiceGainOnLight` `Q` / `c`, `m` · empty state `k` / `e` | 5.40 · **4.84, 4.57** · 8.69 |
| N1 | control ink `k` / `c`, `m`, `i`, top bar `q`, tray `e` | 15.00, 14.16, 12.28, **6.76**, 8.69 |
| N2 | fill `v` / track `U` · lower `G` / `U` · golden `O` / `U` · track `U` / card `c`, well `I` | 8.05 · **3.95** · 5.72 · 11.98, 5.88 |
| N3 | focus outer `Q` / card `c` · inner `q` / control ink `k` | 4.84 · 6.76 |
| N4 | Big Banana `k` / `T`, `t`, `G` · `Y` / `T`, `t` | 3.43, 3.56, 4.94 · 3.29, **3.18** |
| N5 | Golden halo `w` / `D`, `T`, `t`, marquee `U` | 6.91, 4.51, **4.35**, 12.36 |
| N6 | silhouette `U` / can't-afford row `i` · lavender plate `I` | 9.81 · 5.88 |
| N7 | pointer `k` / `T` · `w` / `D` · `k` / `c` | 3.43 · 6.91 · 15.00 |
| N8 | marquee ink `k` / trim `q` · close X `w` / disc `u` | 6.76 · 5.44 |

**Worst cases.** Text: `Q` on mint 4.57 (juiceGainOnLight), `Q` on cream 4.84, `u` group labels on cream 5.27, `q` on `U` 5.40, Evolve `w` on grape 5.44. Non-text: `Y` vs canopy haze 3.18 (stage) and the lower progress row `G` vs `U` 3.95 (the upper row `v` carries it at 8.05).
**Colour-blind check** (contact-sheet deuteranopia mock): lime turns khaki and lavender turns grey-violet, and BUY and NEED stay apart by label, raised vs sunken geometry and value (0.60 vs 0.42). Pink and grape converge towards violet, which is safe because no state depends on pink vs grape.
**Squint (greyscale mock):** every afford/can't pair differs by label and bevel. Row fills differ in value (cream 0.91 / mint 0.86 vs lilac-grey 0.74), and the dim icon (50%) is the strongest channel.

### 11.7 Rules
1. **Labels are ink.** Every control label is `k`, except Evolve ready (`w` on grape). Text over the stage keeps the outline font. The v1.0 rule "white labels on sunken wells" is retired.
2. **On light grounds a control's edge is its `k` ink** (≥ 6.76:1 on every v1.1 ground). The face colour is never the only edge.
3. **Lime means go, lavender means not yet, coral means destructive, grape means Evolve.** These meanings are never reused for another state.
4. **Yellow is only ever banana numerals and banana art.** No UI chrome is yellow, and no panel is gold. Amber appears only on Golden-granted buff chrome: the Frenzy bezel, the buff bar and the edge glow.
5. **The dark ground is `U`, and only in small doses:** the stat window, the 48-px marquee, the banner, the scrim and the letterbox. Everything else is light or saturated.

### 11.8 Do / Don't (v1.1)
1. **Do** put coloured numerals in the dark stat window. **Don't** put `Y` bank text on cream (1.33:1) or on the pink bar (1.7:1). This is why the window exists.
2. **Do** give every capsule a 1-px `k` ink. **Don't** rely on lime vs cream (1.49:1) or lime vs lavender (1.37:1) to show the edge or the state.
3. **Do** keep text labels inside the flat face rows. **Don't** add gloss to the 8-art-px badge: its 6 interior rows are all needed by the ×3 digit (caught in this pass, gloss removed).
4. **Don't** stack three separate 8-art-px stat chips. An ink + ring edge leaves 16 px for 21-px text, so the text rode on the ring. This was tried in this pass and replaced by one window.
5. **Don't** use orange anywhere in the UI (Golden reservation). Use coral for warmth.

### 11.9 Integration notes (for the Game Developer and Technical Artist)
- **Must land together with this art: the ticker occluders.** `ticker.ts` draws its right occluder with `ui_panel` at **16×48** logical, which is 4 art px wide. `ui_panel`'s new insets (3+3 = 6) exceed that, so `addPixelNineSlice` **throws at boot**. The rounded corners would also show scrolling text through the transparent corner pixels. Switch the ticker panel **and** both occluders to `ui_ticker` (insets 1/1, square ends, butts seamlessly). `verify-sprites.mjs` sizes `ui_panel` for its v1.1 uses only (smallest: buff chip 88×12 art px).
- Evolve ready → `ui_button_evolve` (not `ui_button` 0). The hover-rim glint overlay can use `ui_button_evolve` 2.
- The toggle label must centre in `SPRITE_META.ui_toggle.labelRegionArtPx[frame]` (art-px x range within the 36-px toggle). Centring it on the full visual puts "ON" under the knob.
- New layout elements with suggested rects await UX sign-off: the stat window (agreed: 8,8,372,140) and the icon plates (row-relative 24,ry+8,80,80).
- The initial focus-ring size stays 32×32 logical (the ring's insets are 3).
- TA: `pipeline/verify-pipeline.mjs` still checks the plain tint on `p`, which passes because `p` is kept. Moving those checks onto `UI_THEME` pairs would track the live UI. Regenerate the pipeline harness data from the new `sprites.ts`.
