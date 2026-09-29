# pipeline-conventions — Monkey Bananas

Owner: Technical Artist. Binding on the Game Developer (runtime use) and on the 2D Artist (source authoring).
Files: [`texture-baker.ts`](texture-baker.ts) · [`pixel-font.ts`](pixel-font.ts) · [`fx-data.json`](fx-data.json) · [`verify-pipeline.mjs`](verify-pipeline.mjs) · [`harness/`](harness/index.html)

**Definition of done for this pipeline.** The whole game draws from one generated texture in **≤ 20 WebGL draw calls per frame** (the harness measures **1**). Every texel is a palette colour with alpha 0 or 255. Every sprite renders at an integer scale, snapped to its own texel grid. Adding a sprite, a glyph or an FX is a data edit plus a reload, with no code change.

---

## 1. Keys (the `atlas-key-contract`)

| Thing | Key | Example |
|---|---|---|
| The atlas texture | `ATLAS_KEY` = `"mb_atlas"` | `scene.add.image(x, y, ATLAS_KEY, frameKey("icon_intern"))` |
| A sprite frame | `` `${spriteId}/${frameIndex}` ``, from `frameKey(id, i = 0)` | `critter_intern/1`, `bigBanana/4`, `ui_button/2` |
| A font glyph block | `font_<variant>/0` (reserved `font_` prefix) | `font_outline/0` |
| BitmapText fonts | `FONT_KEYS.plain` = `"mb_font"`, `.outline` = `"mb_font_outline"`, `.crit` = `"mb_font_crit"` | |
| Pipeline-owned frames | `fx_*` ids | `fx_px/0` (white mask), `fx_confetti/0-1`, `fx_poof/0-2`, `fx_dust/0-1` |

- There are no aliases: `icon_intern` alone is **not** a frame name. Always go through `frameKey`.
- Frame indices are the array order in `SPRITES[id].frames`. Never hard-code frame counts. Use `frameCountOf(id)` or `animFrames(id)` (the 2D Artist adds frames without warning you). For example: `scene.anims.create({ key: "critter_intern", frames: animFrames("critter_intern"), frameRate: 2, repeat: -1 })`.
- Sprite ids must not contain `/`. The baker throws if one does.

## 2. Pipeline stages

```
art/tools/build-sprites.mjs ──node──▶ art/sprites.ts        (palette-indexed string grids, PURE DATA)
pipeline/pixel-font.ts                                        (5×7 glyph grids, PURE DATA)
                 │  boot: bakeAll(scene, { palette, sprites, meta, font })
                 ▼
planAtlas()  →  rasterizeAtlas()  →  canvas → scene.textures.addCanvas("mb_atlas")
 (pure)          (pure, RGBA8)        + texture.add(frameKey, …) per frame
                                      + cache.bitmapFont.add(FONT_KEYS[v], …) × 3
```

- **Zero image files.** The atlas exists only in memory. It is rebuilt deterministically at every boot in about 25 ms (measured in the harness on desktop; budget 100 ms on min-spec mobile), and the same input always gives the same layout.
- `planAtlas` and `rasterizeAtlas` do no DOM work, so `verify-pipeline.mjs` runs them in Node and checks the actual pixels.
- **Colour space.** The palette's sRGB hex values go straight into RGBA8 bytes with no conversion. Canvas colour management never touches them, because the baker writes with `putImageData` rather than `fillStyle`. Alpha is binary, so premultiplied alpha cannot change the result.
- **Boot wiring (Game Developer):**
  ```ts
  import { PALETTE, SPRITES, SPRITE_META } from "../art/sprites";
  import * as PIXEL_FONT from "../pipeline/pixel-font";
  import { bakeAll } from "../pipeline/texture-baker";
  // Boot scene create(), before any other scene starts:
  const report = bakeAll(this, { palette: PALETTE, sprites: SPRITES, meta: SPRITE_META, font: PIXEL_FONT });
  ```
  `bakeAll` can be called again safely (hot reload): it replaces the texture and the fonts.

## 3. Render rules

**Game config:** `pixelArt: true`, `roundPixels: true`, `antialias: false`, `type: Phaser.WEBGL`, `scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH }`, 720×1280. The baker also sets the atlas filter to NEAREST explicitly (`setFilter(1)`).

**Integer scales only.** One art px is 4 logical px unless the table says otherwise. Fractional scale is allowed only for the transients under 180 ms listed in `motion/motion-spec.yaml` `_globals`.

| Asset | Scale | Snap grid g (logical px) |
|---|---|---|
| Big Banana, `bigBanana_halo` | ×5 | 5 (rest position on the 20-px grid) |
| Golden Banana, critters, env, `ui_*` 9-slices, glyph sprites, `fx_*` | ×4 | 4 |
| Shop and upgrade icons in rows | ×3 (style guide) | 3 |
| Pixel text | ×2 / ×3 / ×4 / ×6 / ×8 | = the text scale |
| Particles | per emitter `pixelSnap` = its `scale` (fx-data.json; all ×4 today) | same |

**Snapping.** A rendered position is `snap(v, g) = Math.round(v / g) * g`, which the baker exports. Keep float positions for simulation and snap only the rendered value. When the origin is 0.5 and the frame is odd-sized, snap the **top-left** instead (`snap(x − hw, g) + hw`, where hw is half the scaled width) so the texels land on the grid. The snapped particle class and the flipbook player already do this.

**Rotation.** Never rotate pixel art by anything other than multiples of 90°: rotated pixels crawl. The Golden Banana tilt is drawn as frames. `ui_pointer` may rotate by 90°.

## 4. Batching and the draw-call budget (target ≤ 20, measured 1)

In Phaser 4.2.1, `Image`/`Sprite`, `BitmapText`, `NineSlice` and `ParticleEmitter` all submit through the same `BatchHandlerQuad` render node (verified in `renderer/webgl/renderNodes/defaults/*`). They share one texture here, so the whole scene is one batch. **Keep it that way.** Every item below costs at least one extra draw call wherever it sits in the display list:

| Batch breaker | Why | Use instead |
|---|---|---|
| `Graphics` (fillRect, strokes) | a different render node (`BatchHandlerTriFlat`) | `addSolidRect(scene, x, y, w, h, colour, alpha)`: a tinted, stretched `fx_px/0` image. Use it for sky bands, scrims, progress fills, dividers, row flashes and the Evolve white card |
| `TileSprite` | its own node (`BatchHandlerTileSprite`) | repeat plain `Image`s. The ground is about 12 grass plus about 24 dirt images, which is nothing for the batch |
| Phaser `Text` (canvas) | a new texture per object | the baked BitmapText fonts. The ROTATE hint is DOM, which is fine |
| Blend modes other than NORMAL | a state change | NORMAL everywhere. fx-data has no ADD |
| Masks / filters / `RenderTexture` | render-target passes | clip the shop list with a **second camera** whose viewport is the list rect (824–1272). That costs about 1 extra call; do not use a mask filter |
| A second texture | a texture swap | put new art in `art/sprites.ts`; it lands in the same atlas |

**Sky bands.** Draw them as `addSolidRect` bands from `SKY_BANDS`: `y0 = stageTop + snap(from × stageH, 4)`. Do not bake them into a texture, which would waste VRAM on flat colour, and do not use `Graphics`, which breaks the batch.

**Budget.** The draw-call ceiling is 20. The expected total is 2–4 (main camera plus shop camera, plus overlays). The atlas is **256×512 RGBA8 = 512 KiB VRAM** with no mips, at 49% occupancy today. Packing is automatic: the planner picks the smallest power-of-two size up to 2048×2048 and throws if it outgrows that (then split into pages by scene; not needed at this content size).

## 5. Text (the `bitmap-font`)

Font strategy: **BitmapText from a baked 5×7 grid font**. MSDF gains nothing for a pixel font drawn at integer scales, and canvas `Text` breaks the batch and blurs.

| Variant | Colours | Use |
|---|---|---|
| `plain` (`mb_font`) | pure-white mask, **always tinted** (the helper defaults to `w`) | text on panels: labels `w`, bank and costs `Y`, can't-afford `s`, button labels in `k` where `SPRITE_META` says "label k", disabled labels at 50% alpha |
| `outline` (`mb_font_outline`) | `w` fill, 1-px `k` ring, 8-connected | floaters, "CATCH IT!", and every other text drawn over the stage; a `w` label on the green face |
| `crit` (`mb_font_crit`) | `Y` fill, 1-px `r` ring | crit floaters "+N!" and Tap Frenzy floaters |

- `addPixelText(scene, x, y, text, { scale, variant, tint, align })` puts the **glyph-box top-left** at (x, y). It sets `fontSize = 7 × scale`, so the scale is exact, uppercases the text and applies aliases (curly quotes, ✕ → ×, unknown characters → `?`). The ring spills 1 font px outside the box, and the advance is unchanged.
- The width of n chars at scale s is `6·s·n − s`, from `measureText(text, s)`, which matches `ux/hud-layout.md` §0. The font is monospace, so layout never has to measure a rendered object.
- Measured contrast (`verify-pipeline.mjs`): outline `w`/`k` 15.48:1, crit `Y`/`r` 5.73:1, plain `w`/`p` 11.82:1, `Y`/`p` 8.64:1, `s`/`p` 6.22:1.
- **Adding a glyph or locale range** is a content task. Add a `FONT_GLYPHS` entry (7 rows × 5 chars), run the verifier (it fails if any `ux/ui-strings.json` character has no glyph), and reload. Nothing gets re-rasterized by hand. Glyph count only moves the atlas when it crosses a shelf: 97 glyphs × 3 variants currently cost about 23 k texels.

## 6. 9-slice (`ui_panel`, `ui_button`, `ui_pill`, `ui_toggle`, `ui_tab`, `ui_button_danger`, `ui_badge`, `ui_bar_*`, `ui_focus`)

```ts
const btn = addPixelNineSlice(scene, x, y, "ui_button", 0, widthPx, heightPx /*, scale = 4 */);
btn.setFrame(frameKey("ui_button", 1)); // pressed: Phaser re-slices on frame change
```

- The insets are read from `SPRITE_META[id].nineSlice`. They are currently **2 art px** for the panel, button, pill, toggle, tab, danger, badge and focus pieces, and 1 for the `ui_bar_*` pieces. Do not hard-code them. (This matches style-guide §7: 2-px insets, `k` labels on raised faces, controls never outlined. SPRITE_META stays canonical because it is generated with the pixels.)
- The helper builds the NineSlice at art-pixel size and applies an integer `setScale`, so corners never scale fractionally. `widthPx` and `heightPx` must be multiples of the scale (the UX layout is already on a 4-px grid), and the helper throws otherwise. The minimum is left+right by top+bottom art px.
- 9-slice frames are extruded like every other frame, so there are no seams at the slice joins. Never trim them (the pipeline never trims anything).

## 7. FX (`fx-data`)

```ts
import FX from "../pipeline/fx-data.json";
const fx = createFxPlayer(scene, FX, { Particle: Phaser.GameObjects.Particles.Particle, tuning: TUNING, reducedMotion,
  depthFor: (layer) => (layer === "ui" ? DEPTH.uiFx : DEPTH.stageFx) });
fx.play("tapChips", pointer.worldX, pointer.worldY);
fx.play("purchaseConfetti", iconX, iconY, isBulk ? "bulk" : undefined);
fx.setReducedMotion(settings.reducedMotion);
```

- The JSON import needs `"resolveJsonModule": true` in tsconfig (Vite bundles JSON natively). The baker's `FxData` types accept the imported JSON as-is (type-checked with TS 5.6 and 7.0).
- FX ids: `tapChips`, `critBurst`, `goldenCatch`, `purchaseConfetti` (variants `bulk`, `upgrade`), `evolvePoof` (a flipbook; the caller schedules the 0–180 ms stagger per critter), `critterSpawnDust`.
- **Tunables stay in `tuning.ts`.** Emitter `bindings` read `tapChipCount`, `tapChipSpeed`, `critChipCount`, `goldenBurstCount` and the rest from the tuning object you pass in. The numbers in the JSON are only fallbacks. (This also satisfies "every tunable is read by code".)
- `play()` **does not** fire audio or shake. Those stay on the gameplay wiring from `motion/event-markers.md`. The `events` entries are cross-references marked `fireFromFx: false`, so nothing double-fires.
- Emitters are created once at (0, 0) and pooled (`reserve` = `maxAliveParticles`), so gameplay allocates nothing. Positions are pixel-snapped by a `Particle` subclass (`makeSnappedParticleClass`).
- **Mobile cap:** the gameplay emitters' `maxAliveParticles` sum to **160**. No FX exceeds 24 particles in one burst (the studio caps are 100 per emitter and 200 per FX), and the fill rate is below 0.01 Mpx per frame. The worst case measured in the harness was 94 alive particles in 1 draw call.
- **Reduced motion:** chip and sparkle counts × `reducedMotionChipFactor` (0.5). The evolve poof and the landing dust are off, matching the Animator's reduced paths.
- If you would rather write your own loader, `resolveEmitter(fx, emitterDef, { tuning, reducedMotion, variant })` returns the plain Phaser `ParticleEmitterConfig` plus the burst count.

## 8. Adding content (content tasks, not code tasks)

| Add… | Steps |
|---|---|
| **A sprite or a frame** | 1. Edit `art/tools/build-sprites.mjs` (the 2D Artist's generator). 2. `node art/tools/build-sprites.mjs` regenerates `art/sprites.ts`. 3. `node art/verify-sprites.mjs && node pipeline/verify-pipeline.mjs`. 4. Reload. The new frames exist as `frameKey(id, i)`. Code changes only where you *use* the new id |
| **A glyph** | Add it to `FONT_GLYPHS` in `pixel-font.ts`, verify, reload |
| **An FX** | Add an entry to `fx-data.json` using existing frames (or add a sprite first), verify, then `fx.play(newId, x, y)` |
| **A pipeline mask/FX frame** | Add it to `PIPELINE_SPRITES` in `texture-baker.ts`. If the 2D Artist later draws the same id in `sprites.ts`, the artist's version wins automatically |

The baker fails loudly on any convention violation: a wrong row length, a character not in `PALETTE`, a `/` in an id, or an atlas over 2048. Nothing breaks silently.

## 9. Verification

- `node pipeline/verify-pipeline.mjs` (Node ≥ 22.18; it imports the `.ts` data directly) runs 1,585 checks. They cover font shape and distinctness, coverage of every `ui-strings.json` character, atlas fit and overlaps, a lossless pixel round-trip of every frame and glyph (outlines closed), the palette-only and binary-alpha rules, font contrast, 9-slice insets, and fx-data frames, tunable names, caps and hue reservations.
- `node pipeline/harness/build.mjs`, then open `pipeline/harness/index.html` (from `file://` or any static server). It loads Phaser 4.2.1 from jsDelivr, bakes, renders the HUD, stage, shop, all fonts and all FX, counts WebGL draw calls per frame, and shows the baked atlas. Rebuild `harness-data.js` after art changes. The harness is a review tool and is not shipped.
