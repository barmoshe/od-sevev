// The fork's texture baker. Owner: Technical Artist. Consumer: Game Developer (Boot scene).
//
// Turns the palette-indexed string grids (art/sprites.ts) and the 5×7 pixel font
// (pipeline/pixel-font.ts) into ONE Phaser texture at boot, plus three BitmapText fonts that
// live inside that same texture. One texture + the quad batch = sprites, 9-slices, particles
// and text all draw in a single WebGL batch (see pipeline/pipeline-conventions.md §4).
//
// Dependency-free: the only import is Phaser *types* (erased at build time). All data is
// passed in, so this file does not care where art/ or pipeline/ live:
//
//   import { PALETTE, SPRITES, SPRITE_META } from '../art/sprites';
//   import * as PIXEL_FONT from '../pipeline/pixel-font';
//   import { bakeAll } from '../pipeline/texture-baker';
//   bakeAll(this, { palette: PALETTE, sprites: SPRITES, meta: SPRITE_META, font: PIXEL_FONT });
//
// Phaser 4.2.1 APIs used (verified against node_modules/phaser@4.2.1 types + source):
//   scene.textures.addCanvas(key, canvas)          -> Phaser.Textures.CanvasTexture
//   texture.add(name, sourceIndex, x, y, w, h)     -> Phaser.Textures.Frame
//   texture.setFilter(1)                           (Phaser.Textures.FilterMode.NEAREST === 1)
//   scene.textures.exists / remove, scene.textures.getFrame
//   scene.cache.bitmapFont.add(key, { data, texture, frame, fromAtlas: true })
//     (the same entry shape BitmapText.ParseFromAtlas writes; glyph uv math mirrors
//      ParseXMLBitmapFont: u = (frame.cutX + gx) / sourceW, v = 1 - (frame.cutY + gy) / sourceH)
//   scene.add.bitmapText(x, y, font, text, size)
//   scene.add.nineslice(x, y, texture, frame, w, h, left, right, top, bottom)
//   scene.add.image(...).setDisplaySize().setTint()
//   scene.add.particles(x, y, texture, config) / emitter.explode(count, x, y)
//   Particle.fire(x, y) / Particle.update(delta, step, processors)   (snapped subclass)

import type Phaser from "phaser";

// ---------------------------------------------------------------------------------------------
// Keys (the atlas-key-contract; pipeline-conventions.md §1)
// ---------------------------------------------------------------------------------------------

/** The single generated atlas texture. */
export const ATLAS_KEY = "mb_atlas";

/** BitmapText cache keys, one per baked font variant. */
export const FONT_KEYS = {
  plain: "mb_font",
  outline: "mb_font_outline",
  crit: "mb_font_crit",
} as const;
export type FontVariant = keyof typeof FONT_KEYS;

/** Frame key for frame `frame` of sprite `id`: `"critter_intern/1"`. Always this form, no aliases. */
export function frameKey(id: string, frame = 0): string {
  return `${id}/${frame}`;
}

/** The atlas frame holding a font variant's glyph block (reserved `font_` prefix). */
export function fontFrameKey(variant: FontVariant): string {
  return frameKey(`font_${variant}`, 0);
}

/** Pipeline mask colour: pure white, only ever used tinted (white × tint = exact tint). */
export const MASK_CHAR = "@";
export const MASK_COLOR = "#ffffff";

/** Edge-extrusion per side for sprite frames (kills sampling bleed at tile seams and 9-slice joins). */
export const EXTRUDE = 1;

/** Largest atlas side the planner may produce (WebGL1 minimum guaranteed MAX_TEXTURE_SIZE is 2048+). */
export const MAX_ATLAS_SIDE = 2048;

// ---------------------------------------------------------------------------------------------
// Pipeline-owned sprites. Masks and FX frames the 2D Artist has not drawn. Same authoring format
// as art/sprites.ts. If art/sprites.ts ever defines the same id, the artist's version wins.
// ---------------------------------------------------------------------------------------------

export interface SpriteDef {
  w: number;
  h: number;
  frames: readonly (readonly string[])[];
}

export const PIPELINE_SPRITES: Record<string, SpriteDef> = {
  // 1×1 white mask. Stretch + tint for every solid rect (sky bands, scrim, bars, flashes).
  fx_px: { w: 1, h: 1, frames: [["@"]] },
  // Confetti mask, 2 orientations; tinted per particle from palette chars in fx-data.json.
  fx_confetti: {
    w: 2,
    h: 2,
    frames: [
      ["@@", ".."],
      ["@.", "@."],
    ],
  },
  // Evolve poof: 3-frame flipbook, 60 ms/frame (motion-spec evolve-ceremony). w lit top-left, s shade.
  fx_poof: {
    w: 16,
    h: 16,
    frames: [
      [
        "................",
        "................",
        "................",
        "................",
        "......wwww......",
        ".....wwwwww.....",
        "....wwwwwwww....",
        "....wwwwwwww....",
        "....wwwwwwws....",
        "....swwwwwss....",
        ".....ssssss.....",
        "......ssss......",
        "................",
        "................",
        "................",
        "................",
      ],
      [
        "................",
        "......ww.ww.....",
        "....wwwwwwwww...",
        "...wwws...wwws..",
        "..wwws.....wwss.",
        "..wws.......wss.",
        "..ww.........ss.",
        "...w.........s..",
        "..ww.........ss.",
        "..wws.......sss.",
        "..wwws.....ssss.",
        "...wwss...ssss..",
        "....wsssssss....",
        "......ss.ss.....",
        "................",
        "................",
      ],
      [
        "................",
        "..ww........ww..",
        ".www........wws.",
        "..ws........ss..",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "..ws........ss..",
        ".wss........sss.",
        "..ss........ss..",
        "................",
      ],
    ],
  },
  // Critter landing dust puff, 2 frames.
  fx_dust: {
    w: 6,
    h: 5,
    frames: [
      ["..ww..", ".wwws.", "wwwwss", ".wsss.", "......"],
      ["......", ".w..w.", "w.ws.s", "..s.s.", "......"],
    ],
  },
};

// ---------------------------------------------------------------------------------------------
// Input types
// ---------------------------------------------------------------------------------------------

/** Shape of `import * as PIXEL_FONT from './pixel-font'`. */
export interface PixelFontData {
  FONT_GLYPHS: Record<string, readonly string[]>;
  FONT_METRICS: {
    glyphW: number;
    glyphH: number;
    advance: number;
    letterSpacing: number;
    lineHeight: number;
    size: number;
  };
  FONT_OUTLINE: { px: number; connectivity: number; cellW: number; cellH: number; xOffset: number; yOffset: number };
  FONT_VARIANTS: Record<FontVariant, { fill: string; outline: string | null }>;
  FONT_ALIASES: Record<string, string>;
  FONT_FALLBACK: string;
}

export interface BakeInput {
  palette: Record<string, string>;
  sprites: Record<string, SpriteDef>;
  /** SPRITE_META from art/sprites.ts (9-slice insets are read from it). Optional. */
  meta?: Record<string, Record<string, unknown>>;
  font: PixelFontData;
}

// ---------------------------------------------------------------------------------------------
// Pure planning (no DOM, no Phaser): runs in Node for verify-pipeline.mjs
// ---------------------------------------------------------------------------------------------

export interface PlannedFrame {
  /** Frame key, e.g. "magicianStandIn/3". */
  key: string;
  sprite: string;
  index: number;
  /** Frame rect in the atlas (the un-extruded pixels). */
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface PlannedGlyph {
  char: string;
  code: number;
  /** Relative to the font block frame. */
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface PlannedFont {
  variant: FontVariant;
  frame: PlannedFrame;
  cellW: number;
  cellH: number;
  xOffset: number;
  yOffset: number;
  glyphs: PlannedGlyph[];
}

export interface AtlasPlan {
  width: number;
  height: number;
  frames: PlannedFrame[];
  fonts: PlannedFont[];
  /** Fraction of atlas area covered by packed rects (incl. gutters). */
  occupancy: number;
  /** Merged sprite table actually baked (pipeline sprites + art sprites, art wins). */
  sprites: Record<string, SpriteDef>;
}

interface PackItem {
  key: string;
  w: number; // packed size incl. gutter
  h: number;
  pad: number; // gutter per side
  place: (x: number, y: number) => void;
}

const FONT_COLS = 16;

function fail(msg: string): never {
  throw new Error(`[texture-baker] ${msg}`);
}

/** Validates a sprite table against the palette; throws loudly on any convention violation. */
export function validateSprites(sprites: Record<string, SpriteDef>, palette: Record<string, string>): void {
  for (const [id, s] of Object.entries(sprites)) {
    if (id.includes("/")) fail(`sprite id "${id}" must not contain "/" (reserved for frame keys)`);
    if (!Number.isInteger(s.w) || !Number.isInteger(s.h) || s.w < 1 || s.h < 1) fail(`sprite ${id}: bad size ${s.w}x${s.h}`);
    if (!s.frames.length) fail(`sprite ${id}: no frames`);
    s.frames.forEach((rows, f) => {
      if (rows.length !== s.h) fail(`sprite ${id} frame ${f}: ${rows.length} rows, expected ${s.h}`);
      rows.forEach((row, y) => {
        if (row.length !== s.w) fail(`sprite ${id} frame ${f} row ${y}: ${row.length} chars, expected ${s.w}`);
        for (const c of row) {
          if (c !== "." && c !== MASK_CHAR && !(c in palette)) fail(`sprite ${id} frame ${f} row ${y}: char "${c}" not in PALETTE`);
        }
      });
    });
  }
}

function glyphCharsSorted(font: PixelFontData): string[] {
  return Object.keys(font.FONT_GLYPHS).sort((a, b) => a.codePointAt(0)! - b.codePointAt(0)!);
}

/**
 * Packs every sprite frame and the three font blocks into the smallest power-of-two atlas.
 * Deterministic: same input, same layout. Shelf packing, items sorted tallest-first.
 */
export function planAtlas(input: BakeInput): AtlasPlan {
  const sprites: Record<string, SpriteDef> = { ...PIPELINE_SPRITES, ...input.sprites };
  validateSprites(sprites, input.palette);

  const frames: PlannedFrame[] = [];
  const fonts: PlannedFont[] = [];
  const items: PackItem[] = [];

  for (const id of Object.keys(sprites).sort()) {
    const s = sprites[id];
    s.frames.forEach((_rows, index) => {
      const fr: PlannedFrame = { key: frameKey(id, index), sprite: id, index, x: 0, y: 0, w: s.w, h: s.h };
      frames.push(fr);
      items.push({
        key: fr.key,
        w: s.w + EXTRUDE * 2,
        h: s.h + EXTRUDE * 2,
        pad: EXTRUDE,
        place: (x, y) => {
          fr.x = x + EXTRUDE;
          fr.y = y + EXTRUDE;
        },
      });
    });
  }

  const chars = glyphCharsSorted(input.font);
  const m = input.font.FONT_METRICS;
  const o = input.font.FONT_OUTLINE;
  for (const variant of ["plain", "outline", "crit"] as FontVariant[]) {
    const outlined = input.font.FONT_VARIANTS[variant].outline !== null;
    const cellW = outlined ? o.cellW : m.glyphW;
    const cellH = outlined ? o.cellH : m.glyphH;
    const rows = Math.ceil(chars.length / FONT_COLS);
    // 1 px transparent gap between cells and around the block (no extrusion for glyphs).
    const bw = FONT_COLS * (cellW + 1) + 1;
    const bh = rows * (cellH + 1) + 1;
    const fr: PlannedFrame = { key: fontFrameKey(variant), sprite: `font_${variant}`, index: 0, x: 0, y: 0, w: bw, h: bh };
    const glyphs: PlannedGlyph[] = chars.map((char, i) => ({
      char,
      code: char.codePointAt(0)!,
      x: 1 + (i % FONT_COLS) * (cellW + 1),
      y: 1 + Math.floor(i / FONT_COLS) * (cellH + 1),
      w: cellW,
      h: cellH,
    }));
    fonts.push({
      variant,
      frame: fr,
      cellW,
      cellH,
      xOffset: outlined ? o.xOffset : 0,
      yOffset: outlined ? o.yOffset : 0,
      glyphs,
    });
    frames.push(fr);
    items.push({ key: fr.key, w: bw, h: bh, pad: 0, place: (x, y) => { fr.x = x; fr.y = y; } });
  }

  items.sort((a, b) => b.h - a.h || b.w - a.w || (a.key < b.key ? -1 : 1));
  const widest = Math.max(...items.map((i) => i.w));
  const totalArea = items.reduce((acc, i) => acc + i.w * i.h, 0);

  let best: { w: number; h: number } | null = null;
  for (let w = 64; w <= MAX_ATLAS_SIDE; w *= 2) {
    if (w < widest) continue;
    const h = shelfHeight(items, w);
    const hp = nextPow2(h);
    if (hp > MAX_ATLAS_SIDE) continue;
    const area = w * hp;
    if (!best || area < best.w * best.h || (area === best.w * best.h && Math.max(w, hp) < Math.max(best.w, best.h))) {
      best = { w, h: hp };
    }
  }
  if (!best) fail(`atlas does not fit in ${MAX_ATLAS_SIDE}x${MAX_ATLAS_SIDE}; split into pages (pipeline-conventions.md §8)`);

  shelfPlace(items, best.w);
  return { width: best.w, height: best.h, frames, fonts, occupancy: totalArea / (best.w * best.h), sprites };
}

function nextPow2(v: number): number {
  let p = 1;
  while (p < v) p *= 2;
  return p;
}

function shelfHeight(items: PackItem[], width: number): number {
  let x = 0, y = 0, shelf = 0;
  for (const it of items) {
    if (x + it.w > width) { y += shelf; x = 0; shelf = 0; }
    x += it.w;
    shelf = Math.max(shelf, it.h);
  }
  return y + shelf;
}

function shelfPlace(items: PackItem[], width: number): void {
  let x = 0, y = 0, shelf = 0;
  for (const it of items) {
    if (x + it.w > width) { y += shelf; x = 0; shelf = 0; }
    it.place(x, y);
    x += it.w;
    shelf = Math.max(shelf, it.h);
  }
}

/** "#rrggbb" -> [r, g, b]. */
export function hexToRgb(hex: string): [number, number, number] {
  const m = /^#([0-9a-f]{6})$/i.exec(hex);
  if (!m) fail(`bad colour "${hex}"`);
  const n = parseInt(m[1], 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

/** "#rrggbb" -> 0xrrggbb (for setTint / particle tint). */
export function hexToNum(hex: string): number {
  const [r, g, b] = hexToRgb(hex);
  return (r << 16) | (g << 8) | b;
}

function colourOf(c: string, palette: Record<string, string>): [number, number, number] | null {
  if (c === ".") return null;
  if (c === MASK_CHAR) return hexToRgb(MASK_COLOR);
  const hex = palette[c];
  if (!hex || hex === "transparent") return null;
  return hexToRgb(hex);
}

export interface RasterAtlas {
  width: number;
  height: number;
  /** RGBA8, alpha is always 0 or 255 (no premultiplication question can arise). */
  data: Uint8ClampedArray;
}

/** Rasterizes a plan into RGBA bytes. Pure; Node-safe. */
export function rasterizeAtlas(plan: AtlasPlan, input: BakeInput): RasterAtlas {
  const { width, height } = plan;
  const data = new Uint8ClampedArray(width * height * 4);
  const put = (x: number, y: number, rgb: [number, number, number]) => {
    const i = (y * width + x) * 4;
    data[i] = rgb[0]; data[i + 1] = rgb[1]; data[i + 2] = rgb[2]; data[i + 3] = 255;
  };

  for (const fr of plan.frames) {
    if (fr.sprite.startsWith("font_")) continue;
    const s = plan.sprites[fr.sprite];
    const rows = s.frames[fr.index];
    // Pixels + 1-px edge extrusion (clamped source lookup).
    for (let yy = -EXTRUDE; yy < s.h + EXTRUDE; yy++) {
      const sy = Math.min(s.h - 1, Math.max(0, yy));
      for (let xx = -EXTRUDE; xx < s.w + EXTRUDE; xx++) {
        const sx = Math.min(s.w - 1, Math.max(0, xx));
        const rgb = colourOf(rows[sy][sx], input.palette);
        if (rgb) put(fr.x + xx, fr.y + yy, rgb);
      }
    }
  }

  const f = input.font;
  for (const pf of plan.fonts) {
    const spec = f.FONT_VARIANTS[pf.variant];
    const fill = colourOf(spec.fill, input.palette) ?? fail(`font ${pf.variant}: fill "${spec.fill}" is transparent`);
    const ring = spec.outline ? (colourOf(spec.outline, input.palette) ?? fail(`font ${pf.variant}: outline transparent`)) : null;
    for (const g of pf.glyphs) {
      const rows = f.FONT_GLYPHS[g.char];
      const ox = pf.frame.x + g.x - pf.xOffset; // glyph ink origin inside the cell
      const oy = pf.frame.y + g.y - pf.yOffset;
      const on = (x: number, y: number) => y >= 0 && y < rows.length && x >= 0 && x < rows[y].length && rows[y][x] === "#";
      if (ring) {
        const eight = f.FONT_OUTLINE.connectivity === 8;
        for (let y = -1; y <= rows.length; y++) {
          for (let x = -1; x <= f.FONT_METRICS.glyphW; x++) {
            if (on(x, y)) continue;
            const hit = on(x - 1, y) || on(x + 1, y) || on(x, y - 1) || on(x, y + 1) ||
              (eight && (on(x - 1, y - 1) || on(x + 1, y - 1) || on(x - 1, y + 1) || on(x + 1, y + 1)));
            if (hit) put(ox + x, oy + y, ring);
          }
        }
      }
      for (let y = 0; y < rows.length; y++) for (let x = 0; x < rows[y].length; x++) if (on(x, y)) put(ox + x, oy + y, fill);
    }
  }
  return { width, height, data };
}

// ---------------------------------------------------------------------------------------------
// Boot-time bake (browser)
// ---------------------------------------------------------------------------------------------

export interface BakeReport {
  atlasKey: string;
  width: number;
  height: number;
  frameCount: number;
  /** sprite id -> frame count, so code never hard-codes frame counts. */
  frameCounts: Record<string, number>;
  fonts: Record<FontVariant, string>;
  occupancy: number;
  ms: number;
}

let bakedPalette: Record<string, string> = {};
let bakedMeta: Record<string, Record<string, unknown>> = {};
let bakedFont: PixelFontData | null = null;
let bakedFrameCounts: Record<string, number> = {};

/**
 * Bakes the atlas and the three bitmap fonts. Call once in the Boot scene's `create()` (or `preload()`),
 * before any scene uses ATLAS_KEY / FONT_KEYS. Safe to call again (hot reload): it replaces both.
 */
export function bakeAll(scene: Phaser.Scene, input: BakeInput): BakeReport {
  const t0 = typeof performance !== "undefined" ? performance.now() : Date.now();
  const plan = planAtlas(input);
  const raster = rasterizeAtlas(plan, input);

  const canvas = document.createElement("canvas");
  canvas.width = raster.width;
  canvas.height = raster.height;
  const ctx = canvas.getContext("2d");
  if (!ctx) fail("2D canvas context unavailable");
  const img = ctx.createImageData(raster.width, raster.height);
  img.data.set(raster.data);
  ctx.putImageData(img, 0, 0);

  const textures = scene.textures;
  if (textures.exists(ATLAS_KEY)) textures.remove(ATLAS_KEY);
  const tex = textures.addCanvas(ATLAS_KEY, canvas);
  if (!tex) fail(`addCanvas("${ATLAS_KEY}") returned null`);
  tex.setFilter(1 /* Phaser.Textures.FilterMode.NEAREST */);

  for (const fr of plan.frames) tex.add(fr.key, 0, fr.x, fr.y, fr.w, fr.h);

  const cache = scene.cache.bitmapFont;
  for (const pf of plan.fonts) {
    const key = FONT_KEYS[pf.variant];
    const frame = tex.get(pf.frame.key);
    const sw = frame.source.width;
    const sh = frame.source.height;
    const chars: Record<number, unknown> = {};
    for (const g of pf.glyphs) {
      chars[g.code] = {
        x: g.x,
        y: g.y,
        width: g.w,
        height: g.h,
        centerX: Math.floor(g.w / 2),
        centerY: Math.floor(g.h / 2),
        xOffset: pf.xOffset,
        yOffset: pf.yOffset,
        xAdvance: input.font.FONT_METRICS.advance,
        data: {},
        kerning: {},
        u0: (frame.cutX + g.x) / sw,
        v0: 1 - (frame.cutY + g.y) / sh,
        u1: (frame.cutX + g.x + g.w) / sw,
        v1: 1 - (frame.cutY + g.y + g.h) / sh,
      };
    }
    const data = {
      font: key,
      size: input.font.FONT_METRICS.size,
      lineHeight: input.font.FONT_METRICS.lineHeight,
      retroFont: true,
      chars,
    };
    if (cache.exists(key)) cache.remove(key);
    cache.add(key, { data, texture: ATLAS_KEY, frame: pf.frame.key, fromAtlas: true });
  }

  bakedPalette = input.palette;
  bakedMeta = input.meta ?? {};
  bakedFont = input.font;
  bakedFrameCounts = {};
  for (const [id, s] of Object.entries(plan.sprites)) bakedFrameCounts[id] = s.frames.length;

  const t1 = typeof performance !== "undefined" ? performance.now() : Date.now();
  return {
    atlasKey: ATLAS_KEY,
    width: plan.width,
    height: plan.height,
    frameCount: plan.frames.length,
    frameCounts: { ...bakedFrameCounts },
    fonts: { ...FONT_KEYS },
    occupancy: plan.occupancy,
    ms: t1 - t0,
  };
}

/** Frame count of a baked sprite (0 if unknown). Use instead of hard-coding counts. */
export function frameCountOf(id: string): number {
  return bakedFrameCounts[id] ?? 0;
}

/** All frame keys of a sprite, in order: for `scene.anims.create({ frames: ... })`. */
export function animFrames(id: string): { key: string; frame: string }[] {
  const n = frameCountOf(id);
  return Array.from({ length: n }, (_, i) => ({ key: ATLAS_KEY, frame: frameKey(id, i) }));
}

/** Palette char -> 0xrrggbb, from the palette passed to bakeAll. */
export function paletteNum(char: string): number {
  if (char === MASK_CHAR) return 0xffffff;
  const hex = bakedPalette[char];
  if (!hex || hex === "transparent") fail(`palette char "${char}" unknown`);
  return hexToNum(hex);
}

// ---------------------------------------------------------------------------------------------
// Render helpers (pipeline-conventions.md §3)
// ---------------------------------------------------------------------------------------------

/** Pixel snap: `Math.round(v / g) * g`. g = the sprite's render scale in logical px. */
export function snap(v: number, g: number): number {
  return Math.round(v / g) * g;
}

/** Applies aliases, uppercases (UX rule), and replaces unknown chars with the fallback glyph. */
export function toFontText(text: string, uppercase = true): string {
  const f = bakedFont;
  if (!f) return uppercase ? text.toUpperCase() : text;
  let out = "";
  for (const raw of uppercase ? text.toUpperCase() : text) {
    const c = f.FONT_ALIASES[raw] ?? raw;
    out += c === "\n" || c in f.FONT_GLYPHS ? c : f.FONT_FALLBACK;
  }
  return out;
}

/** Width in logical px of a (single- or multi-line) string at integer scale s: 6·s·n − s per line. */
export function measureText(text: string, scale: number): number {
  const adv = bakedFont?.FONT_METRICS.advance ?? 6;
  const gap = bakedFont?.FONT_METRICS.letterSpacing ?? 1;
  let widest = 0;
  for (const line of text.split("\n")) {
    const n = [...line].length;
    widest = Math.max(widest, n ? (adv * n - gap) * scale : 0);
  }
  return widest;
}

export interface PixelTextOptions {
  /** Integer render scale (2, 3, 4, 6, 8). Default 4. */
  scale?: number;
  /** Default "plain" (tinted, panels only). Use "outline" over the stage and on buttons. */
  variant?: FontVariant;
  /** Tint for the plain variant, as a palette char ("w", "Y", "s") or a 0xrrggbb number. Default "w". */
  tint?: string | number;
  /** Uppercase the text (UX rule). Default true. */
  uppercase?: boolean;
  /** 0 left, 1 centre, 2 right (multi-line alignment). */
  align?: number;
}

/**
 * Adds pixel text with its glyph-box top-left at (x, y). fontSize = 7·scale, so the scale is exact.
 * x/y should be integers (multiples of `scale` keep font pixels on their own grid).
 */
export function addPixelText(scene: Phaser.Scene, x: number, y: number, text: string, opts: PixelTextOptions = {}): Phaser.GameObjects.BitmapText {
  const scale = opts.scale ?? 4;
  if (!Number.isInteger(scale) || scale < 1) fail(`text scale must be a positive integer, got ${scale}`);
  const variant = opts.variant ?? "plain";
  const size = (bakedFont?.FONT_METRICS.size ?? 7) * scale;
  const bt = scene.add.bitmapText(Math.round(x), Math.round(y), FONT_KEYS[variant], toFontText(text, opts.uppercase ?? true), size, opts.align ?? 0);
  bt.setOrigin(0, 0);
  if (variant === "plain") {
    const t = opts.tint ?? "w";
    bt.setTint(typeof t === "number" ? t : paletteNum(t));
  } else if (opts.tint !== undefined) {
    bt.setTint(typeof opts.tint === "number" ? opts.tint : paletteNum(opts.tint));
  }
  return bt;
}

/** A solid rectangle from the white mask frame. Batches with everything else (Graphics does not). */
export function addSolidRect(scene: Phaser.Scene, x: number, y: number, w: number, h: number, color: string | number, alpha = 1): Phaser.GameObjects.Image {
  const img = scene.add.image(x, y, ATLAS_KEY, frameKey("fx_px"));
  img.setOrigin(0, 0);
  img.setDisplaySize(w, h);
  img.setTint(typeof color === "number" ? color : color.startsWith("#") ? hexToNum(color) : paletteNum(color));
  img.setAlpha(alpha);
  return img;
}

/**
 * Pixel-art 9-slice. `widthPx`/`heightPx` are logical px and must be multiples of `scale`; the
 * slice insets are read from SPRITE_META[id].nineSlice (3 art px for ui_panel / ui_button).
 * Internally the NineSlice is built at art-pixel size and scaled by an integer, so corners stay crisp.
 * Change button state with `ns.setFrame(frameKey('ui_button', n))` (Phaser re-slices automatically).
 */
export function addPixelNineSlice(scene: Phaser.Scene, x: number, y: number, id: string, frame: number, widthPx: number, heightPx: number, scale = 4): Phaser.GameObjects.NineSlice {
  const ns = (bakedMeta[id]?.nineSlice as { left: number; right: number; top: number; bottom: number } | undefined) ?? { left: 3, right: 3, top: 3, bottom: 3 };
  if (widthPx % scale !== 0 || heightPx % scale !== 0) fail(`nine-slice ${id}: ${widthPx}x${heightPx} is not a multiple of scale ${scale}`);
  const w = widthPx / scale;
  const h = heightPx / scale;
  if (w < ns.left + ns.right || h < ns.top + ns.bottom) fail(`nine-slice ${id}: ${w}x${h} art px is below the ${ns.left + ns.right}x${ns.top + ns.bottom} minimum`);
  const obj = scene.add.nineslice(x, y, ATLAS_KEY, frameKey(id, frame), w, h, ns.left, ns.right, ns.top, ns.bottom);
  obj.setOrigin(0, 0);
  obj.setScale(scale);
  return obj;
}

// ---------------------------------------------------------------------------------------------
// FX (pipeline/fx-data.json)
// ---------------------------------------------------------------------------------------------

export interface FxEmitterDef {
  name: string;
  /** "anticipation" | "impact" | "decay" (typed as string so a JSON import type-checks). */
  phase: string;
  delayMs: number;
  pixelSnap: number;
  count: number;
  bindings?: Record<string, string>;
  spread?: Record<string, number>;
  arc?: { centerDeg: number; widthDeg: number; widthParam?: string };
  tintChars?: string[];
  reducedMotion?: { disabled?: boolean; countFactor?: number | string };
  config: Record<string, unknown>;
}

export interface FxFlipbookDef {
  name: string;
  sprite: string;
  frameMs: number;
  scale: number;
  pixelSnap: number;
  reducedMotion?: { disabled?: boolean };
}

export interface FxDef {
  id: string;
  layer?: string;
  emitters: FxEmitterDef[];
  flipbooks?: FxFlipbookDef[];
  variants?: Record<string, { emitters?: Record<string, { count?: number }> }>;
  [k: string]: unknown;
}

export interface FxData {
  fx: FxDef[];
  [k: string]: unknown;
}

export interface ResolvedEmitter {
  name: string;
  delayMs: number;
  pixelSnap: number;
  count: number;
  config: Phaser.Types.GameObjects.Particles.ParticleEmitterConfig;
}

export interface ResolveOptions {
  /** Live feel tunables (src/core/tuning.ts). Bound fields read from here, so tuning.ts stays the one source. */
  tuning?: Record<string, number>;
  reducedMotion?: boolean;
  variant?: string;
  /** Palette for tintChars. Defaults to the palette passed to bakeAll (lets Node tooling resolve without a bake). */
  palette?: Record<string, string>;
}

/**
 * Resolves one fx-data emitter into a Phaser ParticleEmitterConfig + burst count.
 * Returns null when the emitter is disabled (e.g. under reduced motion).
 */
export function resolveEmitter(fx: FxDef, def: FxEmitterDef, opts: ResolveOptions = {}): ResolvedEmitter | null {
  const tuning = opts.tuning ?? {};
  const cfg: Record<string, unknown> = JSON.parse(JSON.stringify(def.config));
  let count = def.count;

  for (const [field, param] of Object.entries(def.bindings ?? {})) {
    const v = tuning[param];
    if (typeof v !== "number") continue;
    if (field === "count") count = v;
    else cfg[field] = v;
  }
  for (const [field, s] of Object.entries(def.spread ?? {})) {
    const v = cfg[field];
    if (typeof v === "number") cfg[field] = { min: v * (1 - s), max: v * (1 + s) };
  }
  if (def.arc) {
    const w = (def.arc.widthParam && typeof tuning[def.arc.widthParam] === "number") ? tuning[def.arc.widthParam] : def.arc.widthDeg;
    cfg.angle = { min: def.arc.centerDeg - w / 2, max: def.arc.centerDeg + w / 2 };
  }
  if (def.tintChars?.length) {
    const pal = opts.palette;
    cfg.tint = def.tintChars.map((c) => (pal ? (c === MASK_CHAR ? 0xffffff : hexToNum(pal[c] ?? fail(`palette char "${c}" unknown`))) : paletteNum(c)));
  }

  const v = opts.variant ? fx.variants?.[opts.variant]?.emitters?.[def.name] : undefined;
  if (v?.count !== undefined) count = v.count;

  if (opts.reducedMotion && def.reducedMotion) {
    if (def.reducedMotion.disabled) return null;
    const f = def.reducedMotion.countFactor;
    const factor = typeof f === "number" ? f : typeof f === "string" && typeof tuning[f] === "number" ? tuning[f] : 0.5;
    count = Math.max(1, Math.round(count * factor));
  }

  cfg.emitting = false;
  return {
    name: def.name,
    delayMs: def.delayMs,
    pixelSnap: def.pixelSnap,
    count: Math.max(0, Math.round(count)),
    config: cfg as Phaser.Types.GameObjects.Particles.ParticleEmitterConfig,
  };
}

type ParticleCtor = typeof Phaser.GameObjects.Particles.Particle;

/**
 * Returns a Particle subclass that keeps a float position for physics but renders snapped to a
 * `grid`-px lattice (top-left aligned, so odd-sized frames land on the grid too).
 * Pass the runtime class: `makeSnappedParticleClass(Phaser.GameObjects.Particles.Particle, 4)`.
 * Emitters must sit at (0, 0) and burst with `explode(n, worldX, worldY)` so local == world.
 */
export function makeSnappedParticleClass(Base: ParticleCtor, grid: number): ParticleCtor {
  class SnappedParticle extends Base {
    fx = 0;
    fy = 0;
    private applySnap(): void {
      this.fx = this.x;
      this.fy = this.y;
      const hw = (this.frame ? this.frame.halfWidth : 0) * Math.abs(this.scaleX);
      const hh = (this.frame ? this.frame.halfHeight : 0) * Math.abs(this.scaleY);
      this.x = Math.round((this.x - hw) / grid) * grid + hw;
      this.y = Math.round((this.y - hh) / grid) * grid + hh;
    }
    fire(x?: number, y?: number): boolean {
      const alive = super.fire(x as number, y as number);
      this.applySnap();
      return alive;
    }
    update(delta: number, step: number, processors: Phaser.GameObjects.Particles.ParticleProcessor[]): boolean {
      this.x = this.fx;
      this.y = this.fy;
      const dead = super.update(delta, step, processors);
      this.applySnap();
      return dead;
    }
  }
  return SnappedParticle as unknown as ParticleCtor;
}

export interface FxPlayerOptions {
  /** `Phaser.GameObjects.Particles.Particle` (runtime class, used for pixel snapping). */
  Particle: ParticleCtor;
  tuning?: Record<string, number>;
  reducedMotion?: boolean;
  /** Depth per fx `layer` hint ("stage" | "ui"). Default 0. */
  depthFor?: (layer: string) => number;
}

export interface FxPlayer {
  play(id: string, x: number, y: number, variant?: string): void;
  setReducedMotion(on: boolean): void;
  setTuning(tuning: Record<string, number>): void;
  destroy(): void;
}

/**
 * Reference FX player: one pooled emitter per (fx, emitter), created up front at (0,0).
 * `play(id, x, y)` bursts every emitter after its delay and plays flipbooks. It does NOT fire
 * audio or shake: those stay on the gameplay event wiring (motion/event-markers.md), so nothing
 * double-fires. Register the flipbook anims first (this does it on construction).
 */
export function createFxPlayer(scene: Phaser.Scene, data: FxData, opts: FxPlayerOptions): FxPlayer {
  let reduced = !!opts.reducedMotion;
  let tuning = opts.tuning ?? {};
  const emitters = new Map<string, Phaser.GameObjects.Particles.ParticleEmitter>();
  const flipPool: Phaser.GameObjects.Sprite[] = [];
  const byId = new Map(data.fx.map((f) => [f.id, f] as const));

  for (const fx of data.fx) {
    const depth = opts.depthFor ? opts.depthFor(fx.layer ?? "stage") : 0;
    for (const def of fx.emitters) {
      const r = resolveEmitter(fx, def, { tuning, reducedMotion: false });
      if (!r) continue;
      const cfg = { ...r.config, particleClass: makeSnappedParticleClass(opts.Particle, r.pixelSnap) };
      const em = scene.add.particles(0, 0, ATLAS_KEY, cfg);
      em.setDepth(depth);
      emitters.set(`${fx.id}:${def.name}`, em);
    }
    for (const fb of fx.flipbooks ?? []) {
      const key = `fx_${fx.id}_${fb.name}`;
      if (!scene.anims.exists(key)) {
        scene.anims.create({ key, frames: animFrames(fb.sprite), frameRate: 1000 / fb.frameMs, repeat: 0 });
      }
    }
  }

  const playFlipbook = (fx: FxDef, fb: FxFlipbookDef, x: number, y: number) => {
    let s = flipPool.find((p) => !p.visible);
    if (!s) {
      s = scene.add.sprite(0, 0, ATLAS_KEY, frameKey(fb.sprite, 0));
      s.on("animationcomplete", (_a: unknown, _f: unknown, spr: Phaser.GameObjects.Sprite) => spr.setVisible(false));
      flipPool.push(s);
    }
    s.setDepth(opts.depthFor ? opts.depthFor(fx.layer ?? "stage") : 0);
    s.setScale(fb.scale);
    const hw = (fb.scale * (frameCountOf(fb.sprite) ? scene.textures.getFrame(ATLAS_KEY, frameKey(fb.sprite, 0)).halfWidth : 0));
    const hh = (fb.scale * (frameCountOf(fb.sprite) ? scene.textures.getFrame(ATLAS_KEY, frameKey(fb.sprite, 0)).halfHeight : 0));
    s.setPosition(snap(x - hw, fb.pixelSnap) + hw, snap(y - hh, fb.pixelSnap) + hh);
    s.setVisible(true);
    s.play(`fx_${fx.id}_${fb.name}`);
  };

  return {
    play(id, x, y, variant) {
      const fx = byId.get(id);
      if (!fx) fail(`unknown fx "${id}"`);
      for (const def of fx.emitters) {
        const r = resolveEmitter(fx, def, { tuning, reducedMotion: reduced, variant });
        const em = emitters.get(`${fx.id}:${def.name}`);
        if (!r || !em || r.count <= 0) continue;
        const go = () => em.explode(r.count, x, y);
        if (r.delayMs > 0) scene.time.delayedCall(r.delayMs, go);
        else go();
      }
      for (const fb of fx.flipbooks ?? []) {
        if (reduced && fb.reducedMotion?.disabled) continue;
        playFlipbook(fx, fb, x, y);
      }
    },
    setReducedMotion(on) { reduced = on; },
    setTuning(t) { tuning = t; },
    destroy() {
      emitters.forEach((e) => e.destroy());
      flipPool.forEach((s) => s.destroy());
      emitters.clear();
      flipPool.length = 0;
    },
  };
}
