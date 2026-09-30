# "עוד סבב" (Another Round): style guide

**Artifact:** `style-guide`. **Owner:** 2D Artist. **Status:** v1, the pre-build creative pack.
**Consumers:** Animator, Technical Artist, UX Designer, Game Developer, Audio Director (key-art pairing).
**Source of truth:** every rule below is executable. `art/src/` rebuilds every image and proof
from pixel grids plus `palette.py`. Run `python3 art/src/build_all.py`.

| Deliverable | File |
|---|---|
| Character line-up | `art/lineup.png` |
| Four eras | `art/locations.png` |
| Title screen | `art/title.png` |
| App icon (1024 px) | `art/icon.png` |
| App icon at 60 px | `art/icon-60.png` |
| Palette card | `art/palette.png` |
| Palette file | `art/palette.gpl` |

The proofs referenced in this guide live in `art/proofs/`.

---

## 0. Principles

1. **One stage, one star.** The Magician is always the brightest, most detailed thing in the
   frame, under his own follow-spot. Everything else, from the scenery to the partners to the
   Suitcase, is a supporting act at a lower detail level.
2. **Caricature from 2-3 traits, never from a face.** Every figure is drawn from a written
   trait list. Nothing is traced, and nothing is referenced from a photo. The joke is a
   politician's hair, props and price tag, never their body, faith or community.
3. **Colour means something.**
   - Three colours are reserved, so the eye learns them in the first minute:
     - maroon = the Suitcase;
     - gold = money;
     - flag blue = the Magician and his mouthpiece.
   - Every other hue is local colour.
4. **Hebrew first.** Every piece of in-art text is our own pixel glyphs, set right-to-left, and
   checked in visual order as ASCII (see §9), never by eye.

## 1. Lineage

| Reference | What we take | What we don't |
|---|---|---|
| *Game Dev Story* and the Kairosoft office sims | 2-heads-tall chibi office people in suits; one sprite body, identity carried by the head; how legible a crowded roster is at mobile scale | Their soft pastel palette and 1-px-eye blandness: our faces get brows, noses and jowls |
| *Papers, Please* (Lucas Pope) | Political satire delivered deadpan in pixels; a restrained, meaningful palette; bureaucratic props as jokes (our stamp, files, tally) | The oppressive monochrome: we're a late-night comedy show, not a border post |
| *EarthBound* / *Mother* | Adults and politicians rendered cute-absurd; a big head carries all the caricature; everyday props as character | The SNES-era dither-heavy backgrounds |
| *Not Tonight* (PanicBarn, 2018) | Proof that current-events political satire in pixel art lands with a general audience | Its grittier, darker tone |

**Anti-references (we are NOT this):**
- *Spitting Image*-style grotesque rubber caricature: we mock the deal, not the body.
- Photo-traced or AI-realistic faces: a red line in the brief.
- Vector idle clickers (*AdVenture Capitalist*): we must read as hand-made and local.

**Differentiation axis vs Eretz Nehederet** (spirit reference only): they are live-action
impression, and we are pixel puppetry. None of their current bits appear.

## 2. Palette

- **Cardinality:** 45 swatches in 15 hue families. That is inside the style-guide DOG's ≤24-hue
  cap. The plan asked for ~40 swatches; the extras are:
  - the plum stage ramp and the teal courtroom ramp, which each era needs to own its mood;
  - `navy_hi`, the light plane of the Magician's navy suit (added in the likeness pass).
- **Source of truth:** `art/src/palette.py`, exported to `art/palette.gpl` (Aseprite/GIMP) and
  `art/palette.png`.
- **Per character:** ≤16 swatches including the outline and prop, and ≤4 hue families in the
  costume (character-design DOG). Measured range: Sara 8, Bennett 15.

| Swatch | Hex | Family | L (WCAG) | Role / usage rule |
|---|---|---|---|---|
| `ink` | `#1b1426` | ink | 0.01 | Outline for every sprite and glyph. Darkest value; never pure black. |
| `night` | `#2a2340` | ink | 0.02 | Night sky base, deepest background, text plates. |
| `suit_dk` | `#2f3042` | neutral | 0.03 | Dark-suit shadow; interior lines on suits. |
| `suit` | `#454a60` | neutral | 0.07 | Dark-suit base (the Magician, most politicians). |
| `suit_hi` | `#636a86` | neutral | 0.15 | Dark-suit light plane (top-left). |
| `slate` | `#7d8398` | neutral | 0.23 | Mid grey: grey hair shadow, stone shadow at night. |
| `grey` | `#a4a9b8` | neutral | 0.40 | Grey hair / beards / stubble. |
| `silver` | `#d3d6df` | neutral | 0.67 | Silver hair (the Magician, Lapid); metal highlights. |
| `white` | `#f7f4ec` | neutral | 0.91 | Shirts, text, highlights. Warm white, never #fff. |
| `paper` | `#ddd5c0` | neutral | 0.67 | White-cloth shadow, paper. |
| `skin_hi` | `#f7cfa6` | skin | 0.67 | Skin light plane (forehead, nose tip). |
| `skin` | `#e3a97c` | skin | 0.46 | Skin base. |
| `skin_sh` | `#c27f58` | skin | 0.27 | Skin shadow (right side, under brows, under chin). |
| `skin_dk` | `#8e5440` | skin | 0.12 | Mouth line, nostril, deepest skin shadow. |
| `hair_dk` | `#2b2124` | hair | 0.02 | Dark hair and dark beards. |
| `hair_br` | `#5a3d30` | hair | 0.06 | Dark-hair light plane, brown hair. |
| `blonde` | `#efe2b4` | hair | 0.76 | Platinum blonde (Sara). |
| `blonde_sh` | `#c9b27a` | hair | 0.46 | Platinum blonde shadow. |
| `navy` | `#1f2b63` | blue | 0.03 | Navy suits (Bennett), Washington night, UI panel base. |
| `navy_hi` | `#34498f` | blue | 0.07 | RESERVED: the Magician's navy suit light plane (his suit = navy / navy_hi / night). |
| `flag` | `#0038b8` | blue | 0.06 | RESERVED: the Magician's tie, flag pin, primary UI button. |
| `flag_hi` | `#3f74e6` | blue | 0.19 | Flag-blue light plane; UI button hover. |
| `sky` | `#8fc0ff` | blue | 0.51 | Day sky (Knesset, Washington). |
| `maroon` | `#8a1538` | maroon | 0.06 | RESERVED: the Suitcase only. Nothing else on screen may be maroon. |
| `maroon_dk` | `#560b24` | maroon | 0.02 | RESERVED: Suitcase shadow. |
| `red` | `#d02a36` | red | 0.15 | Danger (court meter, quit threats), the news-flash label, Smotrich's tie. White on red = 4.70:1. Always paired with a shape cue. |
| `pink` | `#f07fad` | pink | 0.37 | Sara's blazer, Gotliv's top. (Not the protest signs: kraft since B14, 2026-09-30.) |
| `pink_sh` | `#c4507f` | pink | 0.19 | Pink shadow. |
| `orange` | `#f5871f` | orange | 0.37 | Carrot, street lamps, Gotliv's loud jacket. |
| `orange_sh` | `#b85a17` | orange | 0.18 | Orange shadow. |
| `gold` | `#f5c542` | gold | 0.60 | RESERVED: money (shekels), the wordmark, reward moments. |
| `gold_sh` | `#c68a2b` | gold | 0.30 | Gold shadow / coin rim. |
| `gold_hi` | `#fff1a6` | gold | 0.87 | Gold glint; lamp glow core. |
| `green` | `#3fae4a` | green | 0.32 | Dubi the parrot; carrot leaves; lawns. |
| `green_sh` | `#1f7a3d` | green | 0.15 | Green shadow; olive-tree canopy. |
| `lime` | `#a3d84a` | green | 0.57 | Dubi's head highlight; lawn light. |
| `teal_dk` | `#1e3a37` | teal | 0.04 | Courthouse deep shadow. |
| `teal` | `#3a655e` | teal | 0.11 | Courthouse walls. |
| `teal_hi` | `#79a597` | teal | 0.33 | Courthouse fluorescent-lit planes. |
| `stone` | `#e4d3a8` | stone | 0.66 | Jerusalem stone (Knesset), Balfour walls in lamp light, Balfour's kraft protest signs (with `stone_sh`). |
| `stone_sh` | `#b39d72` | stone | 0.35 | Stone shadow. |
| `wood` | `#8a5632` | wood | 0.12 | Court benches, the Balfour gate, podium. |
| `wood_dk` | `#55331f` | wood | 0.04 | Wood shadow. |
| `plum` | `#4a2552` | plum | 0.03 | Stage curtain base (title screen). |
| `plum_hi` | `#7a3a7d` | plum | 0.09 | Curtain fold light plane. |

**Reservations** (a violation fails review; see `proofs/do-dont.png` pair 1):

| Swatch | Reserved for | Nothing else may use it |
|---|---|---|
| `maroon` / `maroon_dk` | The Suitcase | No maroon ties, curtains or cars. The running gag must be findable in one glance. |
| `gold` ramp | Money: shekels, reward bursts, the wordmark | No gold furniture, beaks or buttons |
| `flag` | The Magician's tie and pin, Dubi's tie (he's the mouthpiece), the primary UI button | Other characters get `slate`, `red`, `suit_dk` or `white` ties |
| `navy_hi` (with `navy` / `night`) | The Magician's navy suit. Blue on blue (a bright `flag` tie on a navy suit) is part of his read | Bennett's navy suit uses `flag_hi` for its light plane, never `navy_hi` |

**Hue-shift rule.**
- Shadows step one swatch down *within the family*, and every family's dark end leans violet:
  - suits → `suit_dk`;
  - skin → `skin_sh`, a warmer, redder brown;
  - ink is violet-black, never pure black.
- Highlights lean warm: `skin_hi`, `gold_hi`, `white` (itself a warm white).
- No swatch is ever pure `#000` or `#fff`.

**Colour-blindness pass:** Machado 2009 simulation, severity 1.0.

| Image | Deuteranopia | Protanopia |
|---|---|---|
| Line-up | `proofs/lineup-deuteranopia.png` | `proofs/lineup-protanopia.png` |
| Title | `proofs/title-deuteranopia.png` | `proofs/title-protanopia.png` |

Findings:
- The Suitcase turns olive-brown, but it stays unique. It is carried by the white catch rim,
  the DOHA sticker and its silhouette, not by its hue.
- The news-flash `red` becomes olive; it is carried by position and the white label text.
- Dubi's orange beak merges into his green head. He stays identifiable by the parrot
  silhouette.
- Danger (court meter, quit threats) must always carry a shape cue (an icon, a shake or a
  meter fill) alongside `red`. Colour is never the only channel.

## 3. Value structure

Luminance is the WCAG relative luminance L, taken from `palette.py`.

| Bin | L range | Who lives here |
|---|---|---|
| Ink | 0.00-0.04 | Outlines, night sky, lower UI band, suits' deep shadow |
| Figure dark | 0.06-0.15 | Suits, the hat, beards, wood |
| Figure light | 0.27-0.67 | Faces (the recognition zone), hair, shirts |
| Scene mid | 0.30-0.55 | Walls, stone, lawns, the follow-spot cone |
| Scene light | 0.60-0.90 | Day sky, marble, paper, highlights |

- **Rule:** a character's head sits in the *figure light* bin and its suit in *figure dark*.
- The stage slot behind the Magician must sit in *scene mid*, so both halves of him separate.
- In night and indoor eras that isn't natural, so **the follow-spot is mandatory** (§8).
- **Measured** (`src/squint.py`, the Magician in each era's slot):

| Era | Outline edge ≥3:1 (WCAG 1.4.11) | Suit mass vs backdrop |
|---|---|---|
| Balfour (night) | 100% of perimeter, median 4.7:1 | 3.05:1 |
| Knesset (day) | 100%, median 12.1:1 | 4.97:1 |
| Courthouse (indoor) | 100%, median 6.5:1 | 3.57:1 |
| Washington (day) | 100%, median 12.2:1 | 5.94:1 |

- **Targets:**
  - edge ≥3:1 on ≥90% of the perimeter;
  - suit mass ≥2.5:1 against a 6 px halo;
  - before the follow-spot existed, Balfour sat at 1.90:1 and the courthouse at 1.54:1.
- These numbers are measured on the final v2 Magician: tap pose, navy suit.
- **Greyscale proofs:**
  - `proofs/locations-squint-greyscale.png`;
  - `proofs/title-squint-greyscale.png`.

## 4. Lighting model

- **Flat two-band cel:** base plus one shadow band.
- **A third band** (highlight) only on hair, metal, gold and the Magician's face.
- **Key light:** top-left, frontal stage light. Shadow planes sit on the right and underneath.
- **No runtime lighting and no shaders:** era mood comes from each scene's swatch subset (§8).
  The follow-spot is baked into the background as a one-step "value lift" (the `LIFT` map in
  `locations.py`), so there is no shader cost for the Technical Artist to confirm.

## 5. Line and edge treatment

- **Outline:** exactly 1 art px of `ink` (#1b1426) around every sprite's external silhouette,
  generated by `Layer.outlined()` using 4-neighbour contact.
  - **Head and body** are outlined separately, then composited, so the chin always draws a
    line over the collar.
  - **Props** are outlined separately from the hand holding them.
- **Inner lines:** these use the local ramp's shadow swatch, never `ink`.
  - **The exceptions:** eyes, glasses frames, open mouths and the hat. These are the only
    places ink appears inside a figure.
- **Anti-aliasing:** none. No semi-transparent pixels anywhere, and no sub-pixel positioning of
  art. Integer nearest-neighbour upscale only.
- **Dithering:**
  - **Characters:** never, except as texture for stubble and buzz-cut (Ben Gvir, Eisenkot,
    Levin).
  - **Backgrounds:** a 50% checker only, in three places:
    - at gradient band seams (1 row);
    - in lamp cones;
    - on the follow-spot's outer edge.
- **The catch rim:**
  - **What:** catchable props (the Suitcase today; Kaia's cucumber and any future catchable)
    get a second 1 px `white` ring outside their ink outline.
  - **Why:** maroon on plum, night or teal is only 1.34-1.59:1. With the rim, the edge rises to
    ≥8:1.
  - **Scope:** decorative props never get a rim. The rim *is* the "interactive" class marker
    (environments DOG: interactive vs decorative is unambiguous).

## 6. Construction: the chibi and the star

- **The pixel grid:** the game is authored on one **180×320 art-px** portrait canvas. Every
  sprite, background and glyph lives on this grid, and the engine applies **one integer scale**
  per device.
  - There is never a second scale in the same frame. That would be mixels; see
    `proofs/do-dont.png` pair 4.
  - **Amendment:** the plan's "Magician at ×5, chibis at ×4" is replaced by "Magician is 48×64
    art px, chibis are 24×32 art px, same scale". He is big because he has more pixels, not
    because his pixels are bigger (see §10).

**Chibi (the cast):**
- **Frame budget:** 24×32 including the outline. The drawn sprites measure 20×27 to 24×31, and
  the slack is for hair volume and props.
- **Head fill:** 16×16, which becomes 18×18 with its outline.
- **Body fill:** 22×14, from five shared templates (`suit`, `heavy`, `skirt`, `tee`, `hoodie`)
  recoloured per character.
- **Face grid** (fixed across the whole cast, so caricature cannot drift; the Magician's chibi
  follows its own v2 grid):

| Face row | What sits there |
|---|---|
| 0-6 | Hair and headwear: **caricature zone 1** |
| 7 | Brows (a heavy 3-px brow reads older and sterner) |
| 8-9 | Eyes, 1×2 ink, cols 5 and 10; glasses frame rows 8-11: **caricature zone 2** |
| 10 | Nose, col 8, which is one step into the shadow side |
| 11-15 | Mouth (row 12), beards, jowls, stubble: **caricature zone 3** |
| chin | Overlaps the collar by 2 rows |

- **Deliberate breaks of the proportion lock** (each one *is* the trait):
  - Gantz: +2 leg rows, because tall.
  - Liberman: the `heavy` 24-wide body.
  - Gotliv: 22-wide hair.
  - Lapid: an 18-row head, because of the quiff.
  - Gafni: the beard runs 5 rows onto the chest.

**The Magician (the star):**
- **Size:** 48×64 art px fill, 50×66 outlined.
- **Head:** 32×30 fill, deliberately about half his height. That is a bigger head ratio than
  the cast, because he is the caricature the whole game sells.
- **Two key poses**, both in `src/bibi.py` and `proofs/bibi-v2.png`:

| Pose | What happens | Where it ships |
|---|---|---|
| **IDLE, "the lecture"** | Contrapposto. His raised index finger sits beside the face; the other hand is in his trouser pocket; the top hat waits upside-down at his feet | `lineup.png` |
| **TAP, "the trick"** | The hat is raised high in one hand, opening up, and shekels and ballot slips leap out of it; the wand is in the other hand | `title.png`, the era proofs |

- **The hat is never worn in either pose,** because the head silhouette is recognition anchor #1.
- **Pose seam:** the Animator derives the in-betweens: finger-wag, squash on the hat catch,
  stretch on the raise. See §14.

**The likeness** (v2 is the shipping version):
- **Sources:** the client's trait notes plus an inspiration image, used as trait reference only.
  Nothing was traced or sampled. The sprite is our construction, our scale and our palette.
- **The anchors,** in priority order at every scale:
  1. **The dome, not a cap:** a high, mostly bald crown and a big exposed forehead with two
     wrinkle lines. Only a few thin swept-back silver strands run over the top.
  2. **Silver wings:** the hair volume is on the *sides and back*. Wings puff out above and
     behind the ears, lit `white` on the light side and `slate` on the shadow side.
  3. **Big protruding ears:** carved free of the jaw by the outline, with a deep inner curl.
     This is the #1 small-scale anchor.
  4. **Side-eye:** both pupils cut to one side. One heavy dark brow is raised and arched; the
     other is low and heavy.
  5. **Nose:** big and fleshy with a round tip, modelled with light and nostril wings.
  6. **Lower face:**
     - a closed smirk, one corner up;
     - deep nose-to-mouth folds and bags;
     - a pear-shaped jaw with a double-chin crease.
  7. **Wardrobe:** a **navy** suit (`navy` / `navy_hi` / `night`), a crisp white shirt, a
     bright `flag` tie and the flag pin.
- **The 16×16 chibi read** (`bibi.CHIBI_V2`, the "הקוסם, צ'יבי" in the line-up) keeps, in
  order: dome + wings, ears, raised brow + side-eye, nose, smirk.
- **History:**
  - `proofs/bibi-variants.png` shows v1 (A faithful / B pushed / C lecture / D chibi).
  - The client rejected all four ("the hair is a cap; no ears; generic old man").
  - They are kept as the record of what fails.

**Originals:**

| Figure | Design |
|---|---|
| Dubi | A green parrot in the boss's suit and flag-blue tie, holding a mic, drawn in profile so the hooked beak is the silhouette |
| The rabbit | A round grey loaf, one ear up and one folded, half-lidded smug eyes, the carrot hoisted like a trophy. **Deliberately not Bugs:** no white muzzle, gloves, buck teeth or lanky pose |
| The Suitcase | 26×16 maroon, a slate handle and corner guards, straps, a white "DOHA" label in a 3×5 Latin micro-font, and the catch rim |

## 7. Caricature: 2-3 traits, and the differentiation grid

- **Rule:** each figure is identified by its **primary trait**, which no other cast member
  shares, backed by one or two secondary traits.
- **Faith and ethnicity:**
  - **Religious markers** (kippot, beards) are drawn as individual traits, exactly like
    glasses. They are never exaggerated, never the punchline, and never shared as a "group
    look". The three kippot are three different objects:
    - white knitted, large (Ben Gvir);
    - navy knitted (Smotrich);
    - tiny (Bennett).

    Deri's and Gafni's are black.
  - **Skin** uses one ramp for the whole cast: skin is not a caricature channel.
- **The public:** the taxpayer and the high-tech worker are drawn sympathetically. They are
  tired, not stupid, and the joke is on where their money goes.
- **Silhouette test** (`proofs/cast-silhouettes.png`):
  - **Silhouette-unique (8 of 19):** Sara, Gotliv, Lapid, Liberman, Gantz, the high-tech worker,
    Dubi and the Magician.
  - **The other 11** share the suited-chibi silhouette and are unique by value-level head
    traits. That is the nature of a cast of men in suits.
  - **Mitigation:** in-game, every coalition card carries a Hebrew name tag (§9), and no
    mechanic ever asks a player to tell two partners apart by silhouette alone.

| Figure | Primary (unique) | Secondary | Read confidence |
|---|---|---|---|
| The Magician | Bald dome with silver side wings + big ears | Side-eye with raised brow, big nose, smirk, navy suit + bright blue tie, the lecturing finger | High (v2, client-directed) |
| Sara | Platinum long hair | Pink blazer and skirt | High |
| Ben Gvir | Large white knitted kippah | Rectangular black glasses, grey stubble | High |
| Smotrich | Full dark trimmed beard | Red tie, navy kippah | High |
| Deri | Trimmed grey beard *under a bald crown* | Small black kippah, grey temples | Medium: close to Gafni at 1× |
| Gafni-style elder | Long grey beard onto the chest | Round glasses, black kippah, black suit | Medium-high |
| Levin | Fully bald + a gavel | Heavy dark brows, stubble shadow | **Low** (traits unverified; the gavel carries him) |
| Regev | Dark bob + red lips | Silver earrings, sky-blue outfit | Medium (traits unverified) |
| Gotliv | Huge dark hair mass | Mid-shout mouth, orange-and-pink outfit | High |
| Lapid | Tall silver pompadour | All black, TV-anchor smile | High |
| Bennett | Round cheerful face + small kippah | Bald crown, navy suit, the signed pledge sheet | Medium-high |
| Liberman | Heavy build + grey goatee | Bald crown, heavy lids, flat mouth | Medium-high |
| Eisenkot | Grey buzz-cut texture | Open collar, no tie | Medium |
| Gantz | Tall | Neat grey side part, hourglass (the rotation that never came) | Medium |
| Golan | Wire glasses on a white rolled-sleeve shirt | Grey receding hair | **Low** (traits unverified) |
| Taxpayer | Turned-out empty pockets | Tired eye bags, sweat drop, cheap blue shirt | High |
| High-tech worker | Headphones + laptop | Green hoodie | High |
| The Grey Shirt (nickname only) | Grey tee | Generic face on purpose | High (by design) |
| The White Glasses (nickname only) | All white + big white shades | Slicked hair | High |

## 8. Era colour moods (the four stages)

Every stage shares one skeleton, so the HUD and the Magician never move (`src/locations.py`):

| Band | y range | Content |
|---|---|---|
| HUD sky | 0-40 | Flat and low-detail |
| Landmark | 40-150 | The era's one landmark silhouette |
| **Stage slot** | 150-216, x 66-114 | **Always empty.** The Magician lives here |
| Floor | 216-230 | Floor line and spot pool |
| Lower band | 230-320 | Flat and dark: UX panels sit on it |

Every night or indoor stage bakes in the **follow-spot**: a cone from y 40 onto the slot that
lifts whatever is behind it one swatch up its ramp (full lift in the core, a 50% checker at the
edge).

| Era | Mood (one line) | Swatch subset | Backdrop L at the slot | Landmark | Never draw |
|---|---|---|---|---|---|
| 1 · בלפור | Late night, warm lamps, the street is awake | `night`, `plum`, `plum_hi`, `slate`, `grey`, `orange`, `gold_hi` (lamp cores), `stone` / `stone_sh` kraft signs with an `ink` / `flag_hi` marker | 0.33 | A stone villa behind a wall and gate; a generic protest crowd behind barriers with **handmade kraft** signs whose marker rows never form a letter or a face (B14 D', `locations.kraft_sign`) | Real protest slogans, flags as emblems, identifiable protesters |
| 2 · הכנסת | Midday, warm stone, a little too orderly | `sky`, `white`, `stone`, `stone_sh`, `green`, `lime`, `teal_hi` (hills) | 0.53 | The flat roof slab and square colonnade; olive trees | **The Knesset Menorah (it is the state emblem)**, flags, party banners |
| 3 · בית המשפט | Cold fluorescent green; time dragging | `teal_dk`, `teal`, `teal_hi`, `wood`, `wood_dk`, `paper` | 0.38 | Three empty judges' chairs, a raised bench, a clock where an emblem would hang, the case files labelled 1000 / 2000 / 4000 | **The state emblem above the bench** (the panel stays blank, always), judges' faces |
| 4 · וושינגטון | Shiny white marble, blossom-pink, the big stage | `sky`, `white`, `paper`, `pink`, `pink_sh`, `green`, `navy` (the plane) | 0.65 | A *generic* columned white mansion, the obelisk, cherry blossoms, the small "Wing of Zion" plane, a laundry bag by the path | The US seal and eagle, an exact White House replica |

- **Cross-era rule:** saturation peaks in Washington and bottoms out in the courthouse. The
  colour script tells the story arc: a warm home, an official day, cold consequence, a candy
  stage abroad.
- **Atmospheric depth:** far elements, such as the Knesset hills and the Washington obelisk,
  sit one value step toward the sky.

## 9. Hebrew pixel text: "Sevev 5×9"

**Cell:** 5 wide × 9 tall.

| Band | Rows |
|---|---|
| Ascender (only ל and raised geresh/gershayim) | 2 |
| Body | 5 |
| Descender (ך ן ף ץ ק and the comma) | 2 |

**Metrics:**
- **Advance:** glyph width + 1, so 6 for full letters.
- **Narrow letters are proportional:** ו י ן 2 px; ז נ ג 3 px; the space 3 px.
- **Line height:** 11.
- **Baseline:** body row 4.
- **Source:** `src/hebfont.py`. The specimen is `proofs/font-specimen.png`.

**Pair separation at this size:**
- **ו / ז / ן:** hook + stem, a centred 3-wide head, and ו with a 2-row descender.
- **ה / ח / ת:**
  - ה's left leg is *detached* from the roof by a one-row gap;
  - ח is attached;
  - ת is inset one column with a foot kicking left.
- **ב / כ:** ב's square base sticks out past its stem; כ is round, with no tail.
- **ד / ר:** ד's roof overhangs right; ר's corner is rounded.
- **ס / ם:** ם is square at all corners; ס is round at the bottom and top-right.
- **ע / צ:** ע has two converging arms and a left-kicking tail; צ has a crossed top and a full
  base.
- **' vs י:** the geresh is raised into the ascender band, so "מס'" never reads "מסי".

**Direction and bidi:**
- Text is set **right-to-left**.
- Runs of digits (with inner `.`, `,`, `:`) keep LTR order, and brackets mirror (`visual_order()`).
- Sentence punctuation lands on the **left** end.
- **Verify by ASCII dump, never by eye.** A reviewer's reading of Hebrew in an image
  auto-normalises direction; we caught this during authoring. See `proofs/do-dont.png` pair 5.

**How text sits in the frame:**

| Element | Treatment |
|---|---|
| Name tags | A `night` plate, 2 px side padding, a 1 px `ink` foot, `white` text (13.5:1). Adjacent tags on a crowded row are **staggered** by 12 px on a leader line. Long names break onto two centred lines ("משלם / המסים"); tags are never truncated |
| Body text on scenes | Always on a plate (`ink` or `night`), never raw over art. Option: a 1 px `ink` drop shadow |
| Maximum line length at 180 art px | 28 full-width glyphs with 6 px margins. The one-line disclaimer "סאטירה. לא מטעם אף מפלגה." is 126 px |

**Contrast pairs** (WCAG 1.4.3, normal text, ≥4.5:1):

| Pair | Contrast |
|---|---|
| `white` on `night` | 13.52:1 |
| `white` on `flag` (the button) | 8.46:1 |
| `silver` on `ink` (the ticker) | 12.30:1 |
| `grey` on `ink` (the disclaimer) | 7.62:1 |
| `white` on `red` (the news-flash label) | 4.70:1 |

The red swatch was darkened from `#d8323f` (4.30:1, a fail) to `#d02a36` in this pass.

**Legibility at real phone size (flag to UX):**
- 180 art px across a 360-430 CSS-px phone is roughly ×2.
- The 5-px letter body is then ~10-11 CSS px tall, about a 14-15 px system font. That is fine
  for tags, the ticker and labels.
- It is borderline for the numbers a player must read at arm's length.
- **Recommendation:** add a second hand-drawn cut, "Sevev 7×13" (body 7, same letter logic),
  for HUD numbers and button labels. Do **not** upscale the 5×9 by 2: that would mix pixel
  grids.

**The wordmark "עוד סבב":**
- **Construction:** custom lettering at an 18 art-px cap height, 3 px strokes, built on the
  same letter logic as the UI font (ב's tail, ד's overhang, ע's left kick).
- **Treatment:** `gold` fill, a `gold_hi` gloss band, `gold_sh` inner edges, a 2 px `orange_sh`
  extrusion and an `ink` outline. It is 102×28 with effects.
- **Proofs:** `proofs/wordmark.png` and `proofs/wordmark-mono.png` (the monochrome test).
- **Tried and rejected:** a loop arrowhead on the ס. It read as a drip at ×4.

## 10. Title screen and icon

**Title** (`title.png`, 180×320 at ×4): focal hierarchy in three tiers.
1. **The wordmark.**
2. **The Magician** under the follow-spot in the TAP pose, hat raised high, a fountain of
   shekels *and ballot slips* rising up and to the left.
3. **The props:**
   - the ballot box "קלפי" at stage right, whose carton carries a **tally of 5 + 1 rounds**;
   - the subtitle "סבב בחירות מס' 6. הציבור נרגש." (the 6 is live: the player's round count);
   - the Suitcase drifting through with its catch rim;
   - Dubi at stage left;
   - the flag-blue tap button "לגעת בכובע" with a chevron up to the hat;
   - Dubi's "מבזק" ticker;
   - the disclaimer strip.

**Rules:**
- **The election signifier:** "סבב" alone reads as a round of fighting in Israeli Hebrew (Game
  Designer note, accepted). So the title always pairs it with the ballot box and the words
  "סבב בחירות" in full.
- **The ballot box stays apart from the magic.** Slips fly *away* from it. Nothing may read as
  ballot-stuffing, which is an invented allegation (`proofs/do-dont.png` pair 6).
- **Microcopy:** the tap copy uses the gender-neutral infinitive. The UX Designer owns the final
  microcopy and the disclaimer wording.

**Icon** (`icon.png` 1024, from a 64×64 source at ×16):
- **What it shows:** a ballot box wearing the Magician's top hat, inside one clockwise gold
  loop.
- **Why each shape:**
  - **The ballot box** says elections, not conflict. The slip carries a generic check mark,
    never a party letter.
  - **The hat** says the Magician and the show.
  - **The loop** says "עוד סבב": another round, forever. It runs *clockwise* ("again"), not
    counter-clockwise ("undo").
- **Three values:** a dark hat, a white box and a gold ring, on a plum stage field.
- **Excluded:** no flag, emblem or party colour, and nothing siren-, fire- or military-like.
- **Why not the plan's "top hat + ₪ on flag blue":**
  - it no longer says the title;
  - a blue-and-white field reads as an official state or elections-committee app;
  - an Israeli ballot slip's party letters would be an emblem, so we use a check.
- **Proofs:**
  - `icon-60.png` is the real 60 px LANCZOS downsample;
  - `proofs/icon-60-zoomed.png` and `proofs/icon-29-zoomed.png` show that the ring + box + hat
    read survives at 29 px.
- **Format:** opaque, square, no rounded corners (the OS applies the mask). All content sits
  inside the central ~85%.

## 11. Do / don't exemplars

`proofs/do-dont.png` shows six same-subject pairs, each marked with a check or a cross. The
mark is a shape as well as a colour.

| # | Rule | DO | DON'T |
|---|---|---|---|
| 1 | Palette violation | Smotrich's tie in `red` next to the Suitcase | A `maroon` tie: a second "catchable" on screen |
| 2 | Value collision | The courtroom with the follow-spot: suit ≥3:1 | No spot: the dark suit sinks into the dark floor |
| 3 | Line-treatment drift | 1 px ink outline: Gafni holds on a busy striped wall | No outline: beard and suit dissolve into it |
| 4 | Scale mismatch | Bennett and Lapid at the same art-px size | Bennett upscaled ×2 beside a ×1 Lapid: mixels |
| 5 | Hebrew direction | RTL visual order, "6" kept whole | Logical order drawn LTR: reads backwards |
| 6 | Motif violation | Slips fly up and away: "he calls another round" | Slips arc into the ballot box: reads as ballot-stuffing |

**Also don't** (no image needed):
- party logos or party colour-blocks as emblems;
- the state emblem or the Knesset Menorah;
- IDF uniforms;
- children;
- anything photographic, traced or AI-realistic;
- a group look standing in for a person;
- a kippah or beard exaggerated for laughs.

## 12. Production-cost band

| Asset | Authoring time | Why |
|---|---|---|
| New chibi | 0.5-1 h | A head grid on a shared body template |
| Prop | 0.25-0.5 h | Small grid plus outline |
| Era background (180×320) | 3-5 h | Primitives plus hand detail |
| The Magician, per new key pose | 2-3 h | The v2 head is locked in `bibi.py`; poses reuse `_torso` / `_legs` / `_hat` |

- The rendering level (flat two-band cel, no AA, minimal dithering) is sustainable across the
  ~25-character roster in brief round 2 plus the cosmetics.
- The cost of a new coalition partner is dominated by trait research, not pixels.

## 13. Pipeline notes (for the Technical Artist)

- **Sources** are code-as-grids in `art/src/`:
  - characters: `characters.py`, `bibi.py`;
  - scenes: `locations.py`;
  - UI: `title.py`, `hebfont.py`, `wordmark.py`.
- Every sprite is built at 1× on transparent. PNGs are ×N nearest-neighbour previews.
- **The TA should export 1× frames straight from `Layer.to_image(1)`,** not by downscaling
  the previews.
- **Pivots:**
  - chibis: bottom-centre of the 32×36 cell (the feet line);
  - the Magician: the bottom-centre of the 50×66 sprite sits at slot (90, 216).
- **The catch rim** is part of the Suitcase sprite, not a runtime effect.
- **The follow-spot** is baked into each era background; there is no shader.
- **Provenance:** every pixel was authored here, and no sourced or third-party art is used.
  There is nothing to add to `LICENSES.md` from the art side. The one system font appears only
  in caption strips *outside* the art (`palette.png`, `proofs/do-dont.png`) and ships nowhere.

## 14. Negotiations and deferrals

- **Scale (amendment to the plan):**
  - The plan had the Magician at ×5 and the chibis at ×4.
  - It now uses one scale, with the Magician at 48×64 art px. Mixed scales in one frame are
    mixels.
  - **Game Developer:** one integer scale per device, applied to the whole 180×320 canvas.
- **Head size:** the plan's "16×16 head" is the fill; it is 18×18 outlined. The Magician's head
  is pushed to 32×30 (the likeness notes).
- **Likeness, two client rounds:**
  - **v1:** swept-back wave, variants A-D. Rejected by the client.
  - **v2:** dome + wings + ears + side-eye + navy suit. It ships. The suit moved from grey to
    navy, which added one swatch (`navy_hi`).
- **Palette size:** ~40 in the plan, 45 in practice (+ the plum and teal ramps, + `navy_hi`).
  That is still inside the 24-hue cap.
- **Game Designer (accepted):**
  - "סבב" is always paired with an election signifier, on the title and the icon.
  - The cap cosmetic is now "הכל בסדר". It is not drawn in this pass (no cosmetics drawn yet).
- **UX Designer (flags):**
  - the "Sevev 7×13" large cut for numbers and buttons (§9);
  - a 28-glyph line cap at 180 px;
  - the disclaimer and tap-prompt wording are placeholders for UX to own;
  - the ticker copy on `title.png` is a placeholder for the Game Designer's copy deck.
- **Animator:**
  - The key poses are **IDLE** (the lecture) and **TAP** (the trick). Squash and stretch, the
    finger-wag and the hat catch are derived from them.
  - The rabbit's pop and the Suitcase's drift are motion, and yours.
- **Unverified traits:** Levin, Regev and Golan were drawn from general knowledge, not the
  plan's trait list. They are flagged Low/Medium in §7, and the brief says to check them
  against a photo before final art.
- **Deferred:** pose sheets and turnarounds (next pass), Kaia, the Pink Front drum line,
  cosmetics, the share receipt, the coalition-chat avatars (use variant D and the chibi heads).

## 15. Foundations (referenced, not paraphrased)

- **Colour theory:** [`color-theory-foundations.md`](../../../../../.claude/skills/style-definition-and-guide/references/color-theory-foundations.md)
- **Palette construction:** [`palette-construction.md`](../../../../../.claude/skills/style-definition-and-guide/references/palette-construction.md)
- **Squint test:** [`value-grouping-and-squint-test.md`](../../../../../.claude/skills/style-definition-and-guide/references/value-grouping-and-squint-test.md)
- **Colour-blindness redundancy:** [`color-blindness-rule-of-redundancy.md`](../../../../../.claude/skills/style-definition-and-guide/references/color-blindness-rule-of-redundancy.md)
- **Shape language:** [`shape-language-archetypes.md`](../../../../../.claude/skills/character-design/references/shape-language-archetypes.md)
- **Silhouette test:** [`silhouette-test.md`](../../../../../.claude/skills/character-design/references/silhouette-test.md)
- **Value separation:** [`value-separation.md`](../../../../../.claude/skills/environments-and-props/references/value-separation.md)
- **Prop interactivity class:** [`prop-interactivity-class.md`](../../../../../.claude/skills/environments-and-props/references/prop-interactivity-class.md)
- **WCAG contrast:** [`wcag-contrast.md`](../../../../../.claude/skills/ui-visual-design/references/wcag-contrast.md)
- **Icon design at small sizes:** [`icon-design-at-small-sizes.md`](../../../../../.claude/skills/ui-visual-design/references/icon-design-at-small-sizes.md)
- **Wordmark at thumbnail size:** [`wordmark-thumbnail-legibility.md`](../../../../../.claude/skills/key-art-and-marketing/references/wordmark-thumbnail-legibility.md)
