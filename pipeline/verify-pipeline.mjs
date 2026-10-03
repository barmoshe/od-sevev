#!/usr/bin/env node
// The fork's pipeline verification. Owner: Technical Artist.
//   node pipeline/verify-pipeline.mjs
// Needs Node >= 22.18 / 23.6 (native TypeScript type stripping: imports the .ts data modules directly).
// No dependencies. Exits non-zero on any failure; prints a report either way.
//
// Checks: font data well-formed and covering every UI string; atlas plan fits (<= 2048, POT,
// no overlaps); the rasterized atlas round-trips every sprite frame and glyph losslessly and only
// contains palette colours with binary alpha; fx-data frames/tunables/budgets/hue rules;
// 9-slice insets; text contrast of the baked font variants.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");

const font = await import(path.join(here, "pixel-font.ts"));
const art = await import(path.join(root, "art", "sprites.ts"));
const baker = await import(path.join(here, "texture-baker.ts"));
const fxData = JSON.parse(fs.readFileSync(path.join(here, "fx-data.json"), "utf8"));

let failures = 0;
let checks = 0;
const ok = (cond, msg) => {
  checks++;
  if (!cond) {
    failures++;
    console.log(`  FAIL  ${msg}`);
  }
  return cond;
};
const section = (t) => console.log(`\n== ${t}`);

// ------------------------------------------------------------------------------------------
section("pixel font");
const { FONT_GLYPHS, FONT_METRICS: M, FONT_OUTLINE: O, FONT_VARIANTS, FONT_ALIASES, FONT_FALLBACK } = font;
const glyphChars = Object.keys(FONT_GLYPHS);
for (const [c, rows] of Object.entries(FONT_GLYPHS)) {
  ok([...c].length === 1, `glyph key ${JSON.stringify(c)} is one character`);
  ok(rows.length === M.glyphH, `glyph ${JSON.stringify(c)} has ${M.glyphH} rows`);
  for (const r of rows) ok(r.length === M.glyphW && /^[.#]+$/.test(r), `glyph ${JSON.stringify(c)} row "${r}" is ${M.glyphW} of [.#]`);
  const inked = rows.join("").includes("#");
  ok(c === " " ? !inked : inked, c === " " ? "space is blank" : `glyph ${JSON.stringify(c)} has ink`);
}
for (let cp = 32; cp <= 126; cp++) ok(String.fromCharCode(cp) in FONT_GLYPHS, `ASCII ${cp} ${JSON.stringify(String.fromCharCode(cp))} present`);
ok("×" in FONT_GLYPHS, "× (U+00D7) present");
ok("→" in FONT_GLYPHS, "→ (U+2192) present");
ok(FONT_FALLBACK in FONT_GLYPHS, "fallback glyph present");
for (const [a, b] of Object.entries(FONT_ALIASES)) ok(b in FONT_GLYPHS, `alias ${JSON.stringify(a)} -> ${JSON.stringify(b)} resolves`);
ok(M.advance === M.glyphW + M.letterSpacing, "advance = glyphW + letterSpacing");
ok(O.cellW === M.glyphW + 2 * O.px && O.cellH === M.glyphH + 2 * O.px, "outline cell = glyph + 2·px");
ok(O.xOffset === -O.px && O.yOffset === -O.px, "outline offset keeps the glyph box origin");
// Distinctness: no two glyphs share a bitmap (catches copy-paste slips such as O == 0).
const seen = new Map();
for (const [c, rows] of Object.entries(FONT_GLYPHS)) {
  const k = rows.join("|");
  if (seen.has(k)) ok(false, `glyphs ${JSON.stringify(seen.get(k))} and ${JSON.stringify(c)} are identical`);
  else seen.set(k, c);
}
for (const [a, b] of [["O", "0"], ["I", "1"], ["S", "5"], ["B", "8"], ["Z", "2"], ["X", "×"]]) {
  const diff = FONT_GLYPHS[a].join("").split("").filter((ch, i) => ch !== FONT_GLYPHS[b].join("")[i]).length;
  ok(diff >= 3, `${a} vs ${b} differ by >= 3 px (${diff})`);
}

// UI copy coverage (uppercased, placeholders removed): every char must have a glyph.
const uiPath = path.join(root, "ux", "ui-strings.json");
let uncovered = new Set();
if (fs.existsSync(uiPath)) {
  const ui = JSON.parse(fs.readFileSync(uiPath, "utf8"));
  const texts = [];
  const walk = (v, k) => {
    if (typeof v === "string" && !String(k).startsWith("_")) texts.push(v);
    else if (v && typeof v === "object") for (const [kk, vv] of Object.entries(v)) walk(vv, kk);
  };
  walk(ui, "");
  for (const t of texts) {
    for (let ch of t.replace(/\{[^}]*\}/g, "").toUpperCase()) {
      ch = FONT_ALIASES[ch] ?? ch;
      if (!(ch in FONT_GLYPHS)) uncovered.add(ch);
    }
  }
  if (ui.requiredGlyphs) for (const ch of ui.requiredGlyphs) ok(ch in FONT_GLYPHS, `requiredGlyphs ${JSON.stringify(ch)} present`);
  ok(uncovered.size === 0, `every ui-strings.json char has a glyph (missing: ${[...uncovered].map((c) => JSON.stringify(c)).join(" ") || "none"})`);
  console.log(`  ui-strings.json: ${texts.length} strings scanned`);
} else console.log("  (ux/ui-strings.json not present yet; coverage check skipped)");
const contentPath = path.join(root, "design", "content.json");
if (fs.existsSync(contentPath)) {
  const txt = fs.readFileSync(contentPath, "utf8");
  const names = [...txt.matchAll(/"(?:name|title|flavor|headline|text|desc|description)"\s*:\s*"([^"]*)"/g)].map((m) => m[1]);
  const missing = new Set();
  for (const n of names) for (let ch of n.toUpperCase()) { ch = FONT_ALIASES[ch] ?? ch; if (!(ch in FONT_GLYPHS)) missing.add(ch); }
  ok(missing.size === 0, `design/content.json display text covered (${names.length} strings; missing: ${[...missing].join(" ") || "none"})`);
}
console.log(`  ${glyphChars.length} glyphs, advance ${M.advance}, line ${M.lineHeight}, size ${M.size}`);

// ------------------------------------------------------------------------------------------
section("atlas plan");
const input = { palette: art.PALETTE, sprites: art.SPRITES, meta: art.SPRITE_META, font };
const plan = baker.planAtlas(input);
const pow2 = (v) => (v & (v - 1)) === 0;
ok(plan.width <= 2048 && plan.height <= 2048, `atlas ${plan.width}x${plan.height} <= 2048x2048`);
ok(pow2(plan.width) && pow2(plan.height), "atlas sides are powers of two");
const keys = new Set();
for (const f of plan.frames) {
  ok(!keys.has(f.key), `frame key ${f.key} unique`);
  keys.add(f.key);
  ok(f.x >= 0 && f.y >= 0 && f.x + f.w <= plan.width && f.y + f.h <= plan.height, `frame ${f.key} inside atlas`);
}
// Overlap test on packed rects (frame + gutter).
const rects = plan.frames.map((f) => {
  const g = f.sprite.startsWith("font_") ? 0 : baker.EXTRUDE;
  return { k: f.key, x0: f.x - g, y0: f.y - g, x1: f.x + f.w + g, y1: f.y + f.h + g };
});
let overlaps = 0;
for (let i = 0; i < rects.length; i++)
  for (let j = i + 1; j < rects.length; j++) {
    const a = rects[i], b = rects[j];
    if (a.x0 < b.x1 && b.x0 < a.x1 && a.y0 < b.y1 && b.y0 < a.y1) { overlaps++; if (overlaps < 5) ok(false, `overlap ${a.k} / ${b.k}`); }
  }
ok(overlaps === 0, `no packed rects overlap (${rects.length} rects)`);
for (const [id, s] of Object.entries(art.SPRITES)) for (let i = 0; i < s.frames.length; i++) ok(keys.has(baker.frameKey(id, i)), `art frame ${id}/${i} planned`);
const vram = plan.width * plan.height * 4;
console.log(`  ${plan.width}x${plan.height}, ${plan.frames.length} frames, occupancy ${(plan.occupancy * 100).toFixed(1)}%, VRAM ${(vram / 1024).toFixed(0)} KiB (RGBA8, no mips)`);
const spriteCounts = Object.entries(plan.sprites).map(([k, s]) => `${k}:${s.frames.length}`);
console.log(`  sprites: ${Object.keys(plan.sprites).length} (${spriteCounts.filter((s) => !s.endsWith(":1")).join(", ")}; the rest 1 frame)`);

// ------------------------------------------------------------------------------------------
section("raster round-trip");
const raster = baker.rasterizeAtlas(plan, input);
const px = (x, y) => { const i = (y * raster.width + x) * 4; return raster.data.slice(i, i + 4); };
const hex = (p) => "#" + [p[0], p[1], p[2]].map((v) => v.toString(16).padStart(2, "0")).join("");
const allowed = new Set(Object.values(art.PALETTE).filter((h) => h.startsWith("#")).map((h) => h.toLowerCase()));
allowed.add(baker.MASK_COLOR);
let badAlpha = 0, offPalette = 0;
for (let i = 0; i < raster.data.length; i += 4) {
  const a = raster.data[i + 3];
  if (a !== 0 && a !== 255) badAlpha++;
  if (a === 255 && !allowed.has(hex(raster.data.slice(i, i + 4)))) offPalette++;
}
ok(badAlpha === 0, `alpha is binary (0/255) everywhere (${badAlpha} bad)`);
ok(offPalette === 0, `every opaque texel is a palette colour or the mask white (${offPalette} off-palette)`);
let mism = 0;
for (const f of plan.frames) {
  if (f.sprite.startsWith("font_")) continue;
  const rows = plan.sprites[f.sprite].frames[f.index];
  for (let y = 0; y < f.h; y++) for (let x = 0; x < f.w; x++) {
    const c = rows[y][x];
    const p = px(f.x + x, f.y + y);
    const want = c === "." ? null : c === baker.MASK_CHAR ? baker.MASK_COLOR : art.PALETTE[c].toLowerCase();
    if (want === null ? p[3] !== 0 : p[3] !== 255 || hex(p) !== want) mism++;
  }
  // extrusion: the gutter copies the edge
  for (let x = 0; x < f.w; x++) {
    const top = px(f.x + x, f.y), gut = px(f.x + x, f.y - 1);
    if (top[3] !== gut[3] || hex(top) !== hex(gut)) mism++;
  }
}
ok(mism === 0, `every sprite frame round-trips losslessly incl. edge extrusion (${mism} mismatches)`);
let gm = 0;
for (const pf of plan.fonts) {
  const spec = FONT_VARIANTS[pf.variant];
  const fillHex = spec.fill === baker.MASK_CHAR ? baker.MASK_COLOR : art.PALETTE[spec.fill].toLowerCase();
  const ringHex = spec.outline ? art.PALETTE[spec.outline].toLowerCase() : null;
  for (const g of pf.glyphs) {
    const rows = FONT_GLYPHS[g.char];
    const ox = pf.frame.x + g.x - pf.xOffset, oy = pf.frame.y + g.y - pf.yOffset;
    for (let y = 0; y < M.glyphH; y++) for (let x = 0; x < M.glyphW; x++) {
      const p = px(ox + x, oy + y);
      if (rows[y][x] === "#") { if (hex(p) !== fillHex || p[3] !== 255) gm++; }
      else if (ringHex === null && p[3] !== 0) gm++;
      else if (ringHex !== null && p[3] === 255 && hex(p) !== ringHex) gm++;
    }
    if (ringHex) {
      // every inked pixel's 8 neighbours are fill or ring (never transparent): the outline is closed
      for (let y = 0; y < M.glyphH; y++) for (let x = 0; x < M.glyphW; x++) if (rows[y][x] === "#")
        for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) if (px(ox + x + dx, oy + y + dy)[3] !== 255) gm++;
    }
  }
}
ok(gm === 0, `all ${plan.fonts.length} font variants round-trip, outlines closed (${gm} mismatches)`);

// ------------------------------------------------------------------------------------------
section("font contrast (WCAG relative luminance)");
const lum = (h) => {
  const [r, g, b] = baker.hexToRgb(h).map((v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const ratio = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((m, n) => n - m); return (x + 0.05) / (y + 0.05); };
for (const v of ["outline", "crit"]) {
  const s = FONT_VARIANTS[v];
  const r = ratio(art.PALETTE[s.fill], art.PALETTE[s.outline]);
  ok(r >= 4.5, `${v}: fill ${s.fill} vs ring ${s.outline} = ${r.toFixed(2)}:1 (>= 4.5, settings-and-a11y C8)`);
  console.log(`  ${v}: ${s.fill} on ${s.outline} ring ${r.toFixed(2)}:1`);
}
for (const [fg, bg] of [["w", "p"], ["Y", "p"], ["s", "p"]]) {
  const r = ratio(art.PALETTE[fg], art.PALETTE[bg]);
  ok(r >= 4.5, `plain tinted ${fg} on panel ${bg} = ${r.toFixed(2)}:1`);
  console.log(`  plain ${fg} on ${bg}: ${r.toFixed(2)}:1`);
}

// ------------------------------------------------------------------------------------------
section("9-slice");
for (const id of ["ui_panel", "ui_button"]) {
  const s = art.SPRITES[id], ns = art.SPRITE_META[id]?.nineSlice;
  if (!ok(s && ns, `${id} exists with nineSlice meta`)) continue;
  ok(ns.left + ns.right < s.w && ns.top + ns.bottom < s.h, `${id} insets ${ns.left}/${ns.right}/${ns.top}/${ns.bottom} leave a stretchable centre in ${s.w}x${s.h}`);
  console.log(`  ${id}: ${s.w}x${s.h}, insets L${ns.left} R${ns.right} T${ns.top} B${ns.bottom}, frames ${s.frames.length}`);
}

// ------------------------------------------------------------------------------------------
section("fx-data");
const feel = fs.existsSync(path.join(root, "design", "feel-spec.md")) ? fs.readFileSync(path.join(root, "design", "feel-spec.md"), "utf8") : "";
const tunables = Object.fromEntries([...feel.matchAll(/param:\s*(\w+),\s*value:\s*([-\d.]+)/g)].map((m) => [m[1], Number(m[2])]));
const reserved = new Set(["Y", "h", "y", "O", "o", "A"]);
let aliveTotal = 0;
for (const fx of fxData.fx) {
  let peak = 0;
  for (const e of fx.emitters) {
    const c = e.config;
    for (const fr of c.frame) ok(keys.has(fr), `${fx.id}.${e.name}: frame ${fr} exists in the atlas`);
    ok(c.blendMode === "NORMAL", `${fx.id}.${e.name}: blend NORMAL`);
    ok(Number.isInteger(c.scale) && c.scale === e.pixelSnap, `${fx.id}.${e.name}: integer scale ${c.scale} == pixelSnap ${e.pixelSnap}`);
    ok(c.rotate === undefined, `${fx.id}.${e.name}: no rotation`);
    ok(c.maxAliveParticles <= fxData.budget.perEmitterMaxAliveCap, `${fx.id}.${e.name}: maxAlive ${c.maxAliveParticles} <= ${fxData.budget.perEmitterMaxAliveCap}`);
    for (const p of Object.values(e.bindings ?? {})) ok(!feel || p in tunables, `${fx.id}.${e.name}: binding ${p} is a feel-spec tunable`);
    if (typeof e.reducedMotion?.countFactor === "string") ok(!feel || e.reducedMotion.countFactor in tunables, `${fx.id}.${e.name}: reduced factor ${e.reducedMotion.countFactor} is a tunable`);
    for (const t of e.tintChars ?? []) { ok(t in art.PALETTE, `${fx.id}.${e.name}: tint ${t} in palette`); ok(!reserved.has(t), `${fx.id}.${e.name}: tint ${t} avoids reserved hues`); }
    if (fx.id !== "goldenCatch") ok(!c.frame.some((f) => f.startsWith("particle_gold")), `${fx.id}.${e.name}: particle_gold reserved for goldenCatch`);
    const r = baker.resolveEmitter(fx, e, { tuning: tunables, palette: art.PALETTE });
    const rr = baker.resolveEmitter(fx, e, { tuning: tunables, palette: art.PALETTE, reducedMotion: true });
    const vmax = Math.max(r.count, ...Object.values(fx.variants ?? {}).map((v) => v.emitters?.[e.name]?.count ?? 0));
    peak += vmax;
    aliveTotal += c.maxAliveParticles;
    console.log(`  ${fx.id}.${e.name}: count ${r.count}${vmax !== r.count ? ` (variants up to ${vmax})` : ""}, reduced ${rr ? rr.count : "off"}, maxAlive ${c.maxAliveParticles}`);
  }
  for (const fb of fx.flipbooks ?? []) ok(fb.sprite in plan.sprites, `${fx.id}: flipbook sprite ${fb.sprite} exists`);
  ok(peak <= fxData.budget.perFxPeakParticlesCap, `${fx.id}: peak ${peak} <= ${fxData.budget.perFxPeakParticlesCap}`);
  ok(fx.costs.fillratePeakMpx <= fxData.budget.fillratePerFxCapMpx, `${fx.id}: fillrate ${fx.costs.fillratePeakMpx} Mpx <= cap`);
  ok(fx.events.every((ev) => ev.fireFromFx === false), `${fx.id}: events are cross-refs only (no double-fire)`);
}
ok(aliveTotal <= fxData.budget.gameplayMaxAliveTotal, `sum of maxAlive ${aliveTotal} <= ${fxData.budget.gameplayMaxAliveTotal}`);
console.log(`  sum of emitter maxAlive caps: ${aliveTotal}`);

// ------------------------------------------------------------------------------------------
console.log(`\n${failures ? "FAILED" : "OK"}: ${checks - failures}/${checks} checks passed`);
process.exit(failures ? 1 : 0);
