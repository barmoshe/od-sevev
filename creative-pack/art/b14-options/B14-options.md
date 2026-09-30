# B14: the Balfour protest signs, options

**Owner:** the 2D Artist. **Decision:** Bar's.
**Date:** 2026-09-30.
**Base:** `restore-s4` @ `eb14e83`, rendered in a detached scratch worktree. The repo's working tree was not touched.

**Files:**
- `options-sheet.png`: the current state plus A, A', B, C, D and D', side by side. It has five rows:
  1. 3× with the leader composited (Bibi idle frame 0 at the manifest's feet point);
  2. gameplay scale (the stage at 390 CSS px wide);
  3. 1× native;
  4. a squint view (greyscale and blurred);
  5. a deuteranopia approximation.
- `options-detail-6x.png`: the sign band only (art rows 166-217) at 6×, one row per option. Use it to judge the pixels.
- `b14-<opt>-stage-1x.png`, `b14-<opt>-stage-3x.png` and `b14-<opt>-leader-3x.png`, one set per option. `<opt>` is `current`, `A`, `A2`, `B`, `C`, `D` or `D2`.
- `b14-metrics.json`: the sign pixels by swatch per option, and each swatch's WCAG contrast against the wall (`slate`).
- `mock_signs.py`: the reproducible mock. It execs `locations.balfour()` with only the sign block swapped, and asserts that the original block is still present.

## 1. What the signs are today

The signs are procedural pixels, not a sprite. They are drawn in two places:

| Where | Code | Asset |
|---|---|---|
| The stage | `creative-pack/art/src/locations.py` `balfour()`, lines 110-128. Each even-indexed protester gets a 10×8 board at `(sx-2, top-14)` on a `wood` stick, `pink`/`pink_sh` or `white`/`paper` alternating in pairs. That makes 8 boards: 4 pink and 4 white. | `stage_balfour.png` (180×320). The render has 0 px drift from `game/assets/sprites/stage_balfour.png` and from the approved showcase `out/`. |
| The wide-phone wings | `art/od-sevev/src/wave7.py` `_protester(..., pink=True)` and `wing_balfour()`. The seam protesters replay the art's seeded crowd; the wing-native protesters are `(x, h, sign_x, pink)` tuples. | `wing_balfour_l.png` and `wing_balfour_r.png` |

There is no legible text on the signs: the style guide says "blank signs", and the stage row's don'ts are real protest slogans, flags as emblems and identifiable protesters. `palette.py` still gives `pink` the role "the protest's signs". v4 left `pink` out of the chrome, so on the main screen these 8 boards (and Sara's and Gotliv's costumes) are the only pink left. That is why they now read as a v2 leftover (`ux/manual-test-2026-09-30/fixes/dev2-pretap-390x844.png`).

Geometry: the boards sit on the lamp-lit perimeter wall (`slate` `#7d8398`). They are at hip-to-waist height beside the leader's follow-spot, between x 0-60 and x 120-180, and never inside the leader's slot.

## 2. References (described and linked, no images copied)

| # | Source | What it shows, and what we take from it |
|---|---|---|
| R1 | [Wikipedia: 2020-2021 protests against Benjamin Netanyahu](https://en.wikipedia.org/wiki/2020%E2%80%932021_protests_against_Benjamin_Netanyahu) | The Balfour / Paris Square protests were also called the "Black Flag Protests". Black flags were hung from balconies, windows and cars. Individual costumes and performances grew over the summer of 2020 ("Bibistille", 14 July 2020), and there were pink submarine balloons. |
| R2 | [Ynet: "At anti-Netanyahu protests in Israel, pink is the new black"](https://www.ynetnews.com/magazine/article/rkmreDaeO) (also [Rappler](https://www.rappler.com/life-and-style/arts-culture/anti-netanyahu-protests-in-israel-pink-new-black/)) | The Pink Front (הפינק פרונט): fluorescent pink bandanas, flags and shirts, pink face paint and makeshift drums. It was mostly artists and performers. Other groups at the same protests wore black. |
| R3 | [Haaretz: "How Pink Became the Color of the anti-Netanyahu Protests"](https://www.haaretz.com/israel-news/2020-10-16/ty-article-magazine/.premium/how-pink-became-the-color-of-the-anti-netanyahu-protests/0000017f-e326-d804-ad7f-f3fe2d6d0000) (paywalled, headline only) | Confirms that pink was *the* 2020 colour at Balfour. |
| R4 | [Galit Barak: Pink Front](https://www.galitbarak.com/pink-front) | Large, carriable illustrations in bright pink with bold contour strokes, and short catchphrases. The Pink Front's look was a designed graphic identity, not ad-hoc. |
| R5 | [Al-Monitor: Israel's Black Flag protest gathers momentum (2020)](https://www.al-monitor.com/originals/2020/04/israel-benjamin-netanyahu-benny-gantz-knesset-black-flag.html); [Swarthmore NV database: Black Flags protest 2016-2021](https://nvdatabase.swarthmore.edu/node/5087) | The black flag was the movement's single emblem, pinned to cars and homes, a plain black cloth. |
| R6 | [New Israel Fund: "The View from Balfour Street"](https://nif.org/blog/the-view-from-balfour-street-jerusalem/); [Washington Post opinion, 27 Jul 2020](https://www.washingtonpost.com/opinions/2020/07/27/is-this-beginning-an-israeli-spring/) | There were hundreds of **handmade signs** at Paris Square, hand-scrawled in Hebrew, Arabic, Amharic, Russian, English and emoji, plus long banners. Handmade cardboard was the common ground of every group at Balfour. |
| R7 | [+972: "The problem with 'reclaiming' the Israeli flag"](https://www.972mag.com/problem-israeli-flag-protests/) | Kaplan 2023: a movement "totally dominated" by the Israeli flag. Mass-produced flags on bamboo sticks were handed out from boxes every week. The organisers had to ask people to lower the flags so drones could shoot the banners. The piece also notes that 2020-21 was the black-flag cycle. |
| R8 | [Wikipedia: 2023 Israeli judicial reform protests](https://en.wikipedia.org/wiki/2023_Israeli_judicial_reform_protests); [Wikipedia: Kaplan Street](https://en.wikipedia.org/wiki/Kaplan_Street); [UnXeptable](https://en.wikipedia.org/wiki/UnXeptable) | Kaplan was the weekly site from 14 Jan 2023. Besides the flags: red *Handmaid's Tale* robes, flares and torches, and a pink chuppah at the civil-wedding protest. |
| R9 | [Times of Israel: weekly anti-government protests after the end of the hostage rallies (2025)](https://www.timesofisrael.com/weekly-anti-government-protests-take-center-stage-after-end-of-weekly-hostage-rallies/); [ToI: Habima, state-commission rally, 6 Dec 2025](https://www.timesofisrael.com/protesters-in-tel-aviv-including-opposition-leaders-demand-oct-7-state-commission-of-inquiry/) | In 2025-26 the Habima and Kaplan crowd is "awash in Israeli flags", with printed banners. The theme is now bound to the October 7 inquiry and the hostages, with yellow as the hostage colour. **Guardrail:** nothing in 2025-26 visual culture beyond blue-and-white is safe to quote. No yellow and no ribbons (style guide do/don't 13, `redlines.json` `oct7-hostages`). |

Summary of the references: **2020 Balfour = black flags + Pink Front pink + handmade cardboard; 2023 Kaplan = a sea of blue-and-white flags; 2025-26 = flags again, but now tied to Oct 7 (off-limits).** Handmade cardboard is the one element common to all three.

## 3. The options

All options keep the approved sign geometry (a 10×8 board on a stick, 8 on the stage) or swap it for a cloth flag on a taller pole. They stay on the 45-swatch master palette. None has letters, stars, logos or faces. The cast, the stage, the crowd bodies, the barrier and the leader are untouched. Contrast figures are WCAG ratios against the wall (`slate` `#7d8398`).

### Current state (v2)
- **Palette:** `pink` `#f07fad` / `pink_sh` `#c4507f` and `white` `#f7f4ec` / `paper` `#ddd5c0`, 4 and 4, on `wood` `#8a5632` sticks.
- **Readability:** white is 3.43:1 and pink 1.5:1. Pink is weak in value but is the only saturated pink on the v4 screen, so it pops by hue. Under deuteranopia, pink becomes a lavender close to the v4 blues.
- **Problem:** the pink is orphaned in v4. It reads as an old UI accent, not as Balfour.

### A: blue and white boards (v4 aligned)
- **Palette:** `white` / `paper` and `sky` `#8fc0ff` / `flag_hi` `#3f74e6` (shade row), alternating. Colour only: no stripes and no star, so the board is not a flag object.
- **Ties to:** R7 and R9. It is the flag's colours without the flag, the same rule the v4 chrome follows (§2.3: "the colours are the frame").
- **Readability:** sky is 2.0:1 and white 3.43:1. It holds in the squint view: sky reads as a mid-light value, not as a hole. A deep blue board (`flag_hi` or `flag`) would be 1.15:1 on the wall and vanish, which is why A uses sky.
- **Risk:** low as a political reading; it is the national palette. But blue and white at the PM's residence reads "2023+", not 2020 Balfour, which is an anachronism for era 1. It also clashes with the v4 UI in the other direction: the stage's crowd becomes the same sky as the seat pips and links, so the diorama starts to look like chrome. The boards look designed, not handmade.

### A': Kaplan flags (needs a style-guide waiver)
- **Palette:** white cloth with two `flag_hi` stripes (no star), 8×6, on tall `paper` bamboo poles, flown **above** the boards so they don't overlap. The fly end sags 1 px. Alternating with white boards.
- **Ties to:** R7 most literally, the bamboo-stick flag.
- **Readability:** the highest-signal option. The stripes read as "Israeli flag" even without the star, at 390 px.
- **Risk: high.** It breaks style guide §2.3 ("no star of David and no flag as an object or a joke element") and the creative-pack stage row's don't ("flags as emblems"). It also reserves the national flag for one side of a protest, the move R7 critiques. The `flag` swatch is reserved, so the stripes use `flag_hi`, which is lighter than the real flag. **I don't recommend it. It is shown because the brief asked for "flags and signs".**

### B: one Pink Front accent, the rest blue and white
- **Palette:** per side, 1 `pink`/`pink_sh` board, and the rest `white`/`paper` and `sky`/`flag_hi`. Total: 2 pink, 4 white, 2 sky.
- **Ties to:** R2, R3 and R4. It keeps the authentic 2020 Balfour colour as a quote, not a field.
- **Readability:** the same as A, plus two hue accents. Under deuteranopia, pink and sky become almost the same lavender, so the "pink quote" is invisible to about 5% of men. That is acceptable only because the signs carry no meaning.
- **Risk: medium.** The Pink Front is a specific anti-Netanyahu movement. The Balfour stage is era 1 for *every* leader (the reference screenshot has Ben Gvir at Balfour), so a movement colour pins the crowd to one side. Two isolated warm-pink pixels blocks also pull the eye more per pixel than eight uniform ones.

### C: black flags and plain white cardboard
- **Palette:** `ink` `#1b1426` cloth, 8×6, flown high on `grey` poles with a 2-px `suit_dk` sheen, and `white`/`paper` boards. 2 flags and 2 boards per side.
- **Ties to:** R1 and R5, the literal 2020 emblem.
- **Readability:** the highest contrast on the stage: ink is 4.74:1 on the wall. It reads as dark notches at gameplay scale. It is value-quiet next to the lamps, but the blobs are the darkest things beside the leader apart from his own suit.
- **Risk: highest after A'.** Black flags are one movement's emblem, and the style guide forbids flags as objects. In 2026, black cloth in a crowd can also read as mourning, and do/don't 13 bars anything that can echo October 7. It does not clash with the v4 UI.

### D: handmade kraft cardboard with marker lines
- **Palette:** `stone` `#e4d3a8` / `stone_sh` `#b39d72` board faces (shade rows `stone_sh` / `wood`), alternating, each with one knocked-out corner (hand-cut). The marker is one colour per board, from `ink`, `flag_hi` and `red` `#d02a36`.
- **Marker lines:** two straight 1-px rows, **right-aligned like Hebrew handwriting**: a long line with one off-centre word gap over a shorter line. The pattern rules out legibility and faces. A straight 1-px row can't form a letter. The gap is never centred and the lower line never centred, because a centred "– –" over "–" reads as a face. My first draft did read as smileys, and this rule is the fix.
- **Ties to:** R6. It is what every Balfour group shared, and it is Kaplan's handmade layer too.
- **Readability:** `stone` is 2.55:1 and `stone_sh` 1.43:1 on the wall. The marker is 12:1 on the board (ink on stone), so the "writing" reads first, then the board shape. It is the quietest option in the squint view; the signs sit in the wall's value band. `stone` is v4's own Jerusalem-stone plaza material, so the stage and the plaza under it share a warm family.
- **Risk:** the lowest political reading. It is generic, belongs to no movement, and uses no flag. The one catch is `red`, which is the alert colour (the court meter and the news flash). D' removes it.

### D' (recommended): D with an ink and flag-blue marker only
- **Palette:** as D, but the marker colours are `ink` and `flag_hi` only, one per board. All other pixels are identical to D.
- **Ties to:** R6 for the material. The blue marker is a quiet nod to the v4 national palette (R7/R9) without making a flag.

## 4. Recommendation: D'

It is judged against the `environments-and-props` DOG: the backdrop establishes mood and place without competing with gameplay, and props are unambiguously decorative.

1. **Competes least with the leader.** It is the only option where no sign swatch is lighter than the wall by more than 2.55:1 and none is a saturated accent. The loudest pixels are 1-px marker rows, which read as texture. In the squint row, the eye goes lamp, then leader, then gate; the signs don't register as separate spots. The current, A, A', B and C all put white (3.43:1) or ink (4.74:1) blocks beside his hips. In the 390-px row, D' still reads as "a crowd holding signs": the stick-above-head silhouette carries it, as it does today.
2. **Clearly decorative.** Nothing on the stage is interactive at that height. Kraft, with no hue coding, cannot be mistaken for a UI element. Sky boards (A and B) share a swatch with the seat pips and links.
3. **True to Balfour.** It is the one visual that every 2020 Balfour group shared (R6), and it is not anachronistic for era 1 the way Kaplan's flags are.
4. **Neutral across leaders.** It carries no movement colour (pink, black) and no national-flag object, so it holds for any leader standing at Balfour. It passes §2.3, do/don't 13 and the "blank signs" rule, with no waiver.
5. **v4 coherent.** The warm stone echoes the v4 plaza, and the blue marker echoes the chrome. Pink leaves the stage (the cast keeps its own pink).

**Second choice: A** if Bar wants the stage visibly blue-and-white. It passes all rules, but reads as 2023 and edges toward chrome.
**If Bar wants the Pink Front quote:** B. Take it knowing that the pink is invisible under deuteranopia and that it tints the crowd as anti-Netanyahu.
**A' and C need a written waiver of style guide §2.3.** I would object to either as shipped (flag as object; C's mourning read against do/don't 13).

## 5. Implementation (for the chosen option; not done, the build is untouched)

**Source edits:**
1. `creative-pack/art/src/locations.py` `balfour()`: replace the 4-line sign block (lines 120-124) with the option's painter. For D', that is `opt_d2` from `mock_signs.py`, which uses the same seeded `sx`, so the crowd layout is identical. Keep the call inside the `if i % 2 == 0` branch, so `r.choice` consumption and the seeded crowd don't shift.
2. `art/od-sevev/src/wave7.py`: replace the board lines in `_protester()` with the same painter, and replace the `pink` flag in `_balfour_crowd` / `native` with the option's index. The seam protesters must use the same `(k, side)` as the art, or a board changes colour across the seam. Also update the docstring's "blank sign".
3. Docs:
   - `palette.py`: the `pink` role loses "the protest's signs" (it becomes "Sara's blazer, Gotliv's top").
   - `creative-pack/art/style-guide.md`: the Balfour row's palette changes from `pink` / `white` signs to `stone` / `stone_sh` kraft with an `ink`/`flag_hi` marker.
   - `art/od-sevev/style-guide.md`: a §2.4 line, plus the marker rule (right-aligned straight rows, never a centred gap).

**Re-render scope:**
- `stage_balfour.png` (1 file; for D', 624 px change, all inside art rows 177-188 (the board faces; the sticks are identical)).
- `wing_balfour_l.png` and `wing_balfour_r.png`.
- The overview `creative-pack/art/locations.png` and its proofs.
- Nothing else. The other three stages, the cast, the key art, the icon and the OG image don't use the signs.

**Pipeline:**
1. The drift check will FAIL on `stage_balfour.png`, by design: the approved look changes. Update the approved `creative-pack/art/showcase/out/stage_balfour.png` from the new render as the Bar-approved change (the README's rule), or run `build.py --allow-drift` once on Bar's approval.
2. Run `art/od-sevev/src/build_all.py` for the wings.
3. Re-import `game/assets/sprites/`.

The texture size and atlas are unchanged, so there is no engine or code change.
