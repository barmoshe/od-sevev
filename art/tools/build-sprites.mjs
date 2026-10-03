// Monkey Bananas — sprite authoring source (2D Artist).
//
// This script is the *authoring* file. It holds the hand-drawn grids, the
// procedural Big Banana, and a uniform auto-outline pass, and it emits the
// pure-data module art/sprites.ts (which is what the game imports) plus the
// contact sheet art/contact-sheet.html.
//
//   node art/tools/build-sprites.mjs
//
// Authoring rules (see art/style-guide.md):
// - Draw fills only on grids marked OUTLINE; the pass adds a 1-px outline on
//   every transparent pixel 4-adjacent to a filled pixel. Leave a 1-px margin.
// - Figure sprites (money, critters, icons, UI glyphs) outline in `k`.
//   Environment sprites outline in the darkest tone of their own ramp so they
//   recede behind the figure layer.
// - Light comes from the top-left. Shade = bottom/right, highlight = top/left.

import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const ART = join(dirname(fileURLToPath(import.meta.url)), '..');

// ---------------------------------------------------------------------------
// Master palette — 38 colours (24 core + 14 v1.1 bright-UI). `.` is transparent.
// '@' is reserved by the pipeline as the tint mask; never use it here.
// ---------------------------------------------------------------------------
const PALETTE = {
  '.': 'transparent',
  k: '#2b1b24', // outline / ink — warm plum-black, never pure #000
  w: '#fff8ec', // warm white — sparkle, badge, hard hat, UI glyphs, text
  h: '#fff3a0', // BANANA highlight
  Y: '#ffd23a', // BANANA yellow — reserved: money + banana currency only
  y: '#d9a21c', // BANANA shade
  O: '#ff8f1f', // GOLDEN amber — reserved: Golden Banana + its blip/burst
  o: '#b8481a', // GOLDEN shade
  B: '#8b5a35', // monkey fur / wood mid
  b: '#56331f', // fur shade / wood dark / banana stem + tip
  W: '#cf9255', // fur highlight / light wood / burlap
  F: '#f0c090', // monkey face + palms
  f: '#c7875a', // face shade
  L: '#a8d85a', // leaf highlight
  G: '#4f9f3a', // leaf / buy-button face
  g: '#2a6334', // leaf shade / foliage outline
  R: '#d8433a', // red accent — tie, sweatband, stamp ink, fuel, flag
  r: '#8e2a36', // red shade
  A: '#3f7fd6', // blue accent — lanyard, sound glyph fill
  s: '#bdb4c2', // light metal / white-object shade
  S: '#6f5f73', // dark metal / disabled face / panel rim
  p: '#452c3e', // legacy dark panel (v1.0). v1.1: reduced-motion EVOLVE_TX card fallback only
  D: '#1c55a3', // sky top — v1.1 saturated royal blue (value held: Y vs D 5.05)
  T: '#2773cc', // sky mid — v1.1 sunny azure (Y vs T 3.29, k vs T 3.43)
  t: '#2c845e', // sky low — v1.1 lush canopy green (Y vs t 3.18, k vs t 3.56)
  // ---- v1.1 bright UI (style-guide §11). None sits in the banana (42-53°) or golden (18-29°) hue bands
  // except the cream, whose chroma is too low to read as a yellow.
  c: '#fff4e0', // cream — panel / card / row fill
  m: '#d8f6e1', // mint — alternate shop row
  i: '#e4dcef', // lilac-grey — can't-afford row, soft lip under cream panels
  I: '#b8a5dd', // lavender — sunken / NEED / OFF / disabled face
  j: '#b98ff2', // lilac — unselected tab, grape gloss, bureaucrat plate
  v: '#8fe052', // lime — BUY / ON / primary button face
  q: '#ff78bf', // hot pink — top bar, marquee trim, badge, card ring, juiceGain
  Q: '#c42a7e', // deep pink — pink lip, focus ring outer
  e: '#4ccbf5', // sky cyan — shop tray, thumbs stat, intern plate
  E: '#1f7fc6', // deep cyan — rocket plate
  u: '#7c44d6', // grape — Evolve face, group labels, close disc, moon plate
  U: '#3a1e72', // deep grape — stat chips, marquee, banner, bar track, scrim, line-2 text
  x: '#ff705f', // coral — destructive face, hardhat plate
  a: '#3ee2c1', // turquoise — timechimp plate
  // ---- od-sevev (2026-09-29, ux/rtl-map.md §7.1 D23): the kit's `outline` swatch. UI only: the
  // modal scrim at 60% (a scrim must only darken; grape lifted the dark base to #2b1753).
  z: '#0b0a12', // outline swatch — modal scrim, spin tag plate, owned badge
};

// Sky gradient bands (the developer draws these procedurally, top → bottom).
const SKY_BANDS = [
  { color: PALETTE.D, from: 0.0, to: 0.22 },
  { color: PALETTE.T, from: 0.22, to: 0.5 },
  { color: PALETTE.t, from: 0.5, to: 0.72 },
];

// ---------------------------------------------------------------------------
// Grid helpers
// ---------------------------------------------------------------------------
function blank(w, h) {
  return Array.from({ length: h }, () => Array(w).fill('.'));
}
function toGrid(rows, name) {
  const w = rows[0].length;
  rows.forEach((r, i) => {
    if (r.length !== w) throw new Error(`${name}: row ${i} has length ${r.length}, expected ${w}: "${r}"`);
  });
  return rows.map((r) => r.split(''));
}
function toRows(g) {
  return g.map((r) => r.join(''));
}
function stamp(dst, rows, x, y) {
  rows.forEach((r, j) => {
    [...r].forEach((c, i) => {
      if (c === '.') return;
      const yy = y + j, xx = x + i;
      if (yy >= 0 && yy < dst.length && xx >= 0 && xx < dst[0].length) dst[yy][xx] = c;
    });
  });
  return dst;
}
function outline(g, ink = 'k') {
  const h = g.length, w = g[0].length;
  const out = g.map((r) => r.slice());
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    if (g[y][x] !== '.') continue;
    const n = [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => {
      const c = g[y + dy]?.[x + dx];
      return c && c !== '.' && c !== ink;
    });
    if (n) out[y][x] = ink;
  }
  return out;
}
// Build a frame: rows (strings), optional outline ink.
function F(rows, name, ink = 'k') {
  const g = toGrid(rows, name);
  return toRows(ink ? outline(g, ink) : g);
}
function compose(w, h, layers, ink = 'k') {
  const g = blank(w, h);
  for (const [rows, x, y] of layers) stamp(g, rows, x, y);
  return toRows(ink ? outline(g, ink) : g);
}
function replace(rows, map) {
  return rows.map((r) => [...r].map((c) => map[c] ?? c).join(''));
}

const SPRITES = {};
function add(id, frames, meta) {
  const h = frames[0].length, w = frames[0][0].length;
  SPRITES[id] = { w, h, frames, ...(meta ? { _meta: meta } : {}) };
}

// ---------------------------------------------------------------------------
// BIG BANANA — procedural crescent, 48×48, 3 frames:
//   [0] rest   [1] squash 0.94 (X 1.06 / Y 0.94)   [2] squash 0.88 (X 1.12 / Y 0.88)
// Pivot = bottom-centre (24, 47). Pre-drawn squash per feel-spec §8 note.
// ---------------------------------------------------------------------------
const BB = { Rc: 22, th0: -58, th1: 58, Tmax: 20, rot: 14 };
function bbLocalShape(u, v) {
  const { Rc, Tmax } = BB;
  const th0 = (BB.th0 * Math.PI) / 180, th1 = (BB.th1 * Math.PI) / 180;
  const thick = (s) => 2.6 + (Tmax - 2.6) * Math.pow(Math.sin(Math.PI * s), 0.6);
  const r = Math.hypot(u, v), th = Math.atan2(v, u);
  if (th >= th0 && th <= th1) {
    const s = (th - th0) / (th1 - th0);
    const d = (r - Rc) / (thick(s) / 2);
    if (Math.abs(d) <= 1) return { part: 'body', s, d };
  }
  const ex = Rc * Math.cos(th0), ey = Rc * Math.sin(th0);
  const ux = Math.sin(th0), uy = -Math.cos(th0);
  const px = u - ex, py = v - ey;
  const along = px * ux + py * uy, side = -px * uy + py * ux;
  if (along >= -0.5 && along <= 4.4 && Math.abs(side) <= 1.7) return { part: 'stem', along, side };
  return null;
}
// rest-pose placement: rotate local → canvas, then centre bbox at x=24, bottom at y=46
const bbRot = (BB.rot * Math.PI) / 180;
const toCanvas = (u, v) => [u * Math.cos(bbRot) - v * Math.sin(bbRot), u * Math.sin(bbRot) + v * Math.cos(bbRot)];
const toLocal = (x, y) => [x * Math.cos(-bbRot) - y * Math.sin(-bbRot), x * Math.sin(-bbRot) + y * Math.cos(-bbRot)];
const BB_OFF = (() => {
  let minX = 1e9, maxX = -1e9, maxY = -1e9;
  for (let v = -40; v <= 40; v += 0.25) for (let u = -10; u <= 50; u += 0.25) {
    if (!bbLocalShape(u, v)) continue;
    const [x, y] = toCanvas(u, v);
    minX = Math.min(minX, x); maxX = Math.max(maxX, x); maxY = Math.max(maxY, y);
  }
  return [24 - (minX + maxX) / 2, 47.9 - maxY];
})();
function magicianStandIn(sx, sy, happy) {
  const W = 48, H = 49;
  const g = blank(W, H);
  const pivX = 24, pivY = 47.5;
  const shape = (X, Y) => bbLocalShape(...toLocal(X - BB_OFF[0], Y - BB_OFF[1]));
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const u = pivX + (x + 0.5 - pivX) / sx;
    const v = pivY + (y + 0.5 - pivY) / sy;
    const p = shape(u, v);
    if (!p) continue;
    let c;
    if (p.part === 'stem') {
      c = p.along > 3.0 ? 'b' : p.side > 0.3 ? 'b' : 'B';
    } else {
      const { s, d } = p;
      if (s > 0.955) c = 'b'; // dark tip
      else if (s < 0.035) c = 'y'; // stem collar
      else if (d > 0.5 || (s > 0.86 && d > -0.1)) c = 'y';
      else if (d < -0.28 && d > -0.82 && s > 0.1 && s < 0.66) c = 'h';
      else c = 'Y';
      // faceted ridge: one ochre line along the belly, lower half only
      if (c === 'Y' && Math.abs(d - 0.3) < 0.09 && s > 0.62 && s < 0.9) c = 'y';
    }
    g[y][x] = c;
  }
  // specular glint (top-left of the highlight band)
  const placeL = (u, v) => { const [x, y] = toCanvas(u, v); return place(x + BB_OFF[0], y + BB_OFF[1]); };
  const place = (u, v) => [Math.floor(pivX + (u - pivX) * sx), Math.floor(pivY + (v - pivY) * sy)];
  const polar = (deg, r) => [r * Math.cos((deg * Math.PI) / 180), r * Math.sin((deg * Math.PI) / 180)];
  const [gx, gy] = placeL(...polar(-34, BB.Rc - 6));
  stamp(g, ['w', 'w'], gx, gy);
  stamp(g, ['w'], gx + 1, gy + 2);
  // face (stamped in output space so features never lose a row under squash)
  const [fx, fy] = placeL(...polar(-4, BB.Rc + 0.5));
  if (happy === 'crit') {
    stamp(g, ['k.......k', '.k.....k.', 'k.......k'], fx - 4, fy - 2); // > < squeeze
  } else if (!happy) {
    stamp(g, ['wk.....wk', 'kk.....kk', 'kk.....kk'], fx - 4, fy - 2);
  } else {
    stamp(g, ['.k.....k.', 'k.k...k.k'], fx - 4, fy - 1); // ^ ^ happy squint
  }
  stamp(g, ['R.........R', 'R.........R'], fx - 5, fy + 2); // cheeks
  stamp(g, ['k...k', '.kkk.'], fx - 2, fy + 3); // smile
  return toRows(outline(g, 'k'));
}
// Quantized squash set for the Animator's driver (motion/object-motion.md §1.1, §6).
// X ≈ 2 − Y keeps the area roughly constant. Canvas 48×49: one spare top row so
// the stretch fits and every frame shares the bottom baseline (row 48 = ink).
const BB_FRAMES = [
  { name: 'rest', sx: 1.0, sy: 1.0, happy: false },
  { name: 'squash094', sx: 1.06, sy: 0.92, happy: false },
  { name: 'squash088', sx: 1.125, sy: 0.85, happy: true },
  { name: 'squash084', sx: 1.16, sy: 0.825, happy: 'crit' },
  { name: 'stretch102', sx: 0.965, sy: 1.021, happy: false },
];
{
  const frames = BB_FRAMES.map((f) => magicianStandIn(f.sx, f.sy, f.happy));
  const bounds = frames.map((fr) => {
    let x0 = 99, x1 = -1, y0 = 99, y1 = -1;
    fr.forEach((r, y) => [...r].forEach((c, x) => { if (c !== '.') { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); } }));
    return { w: x1 - x0 + 1, h: y1 - y0 + 1, x0, y0, x1, y1 };
  });
  add('magicianStandIn', frames, {
    pivot: [0.5, 1],
    frames: ['rest', 'squash 0.94', 'squash 0.88 (happy squint)', 'deep squash 0.84 / crit (> < squeeze)', 'stretch 1.02 (overshoot)'],
    visibleWxH: bounds.map((b) => [b.w, b.h]),
    heightRatio: bounds.map((b) => +(b.h / bounds[0].h).toFixed(3)),
    restBounds: bounds[0],
    note: 'Canvas 48x49, all frames share the bottom baseline (ink on row 48). Pivot bottom-centre. Hit area = restBounds + pad (never follows the frame). Row heights include the 1-px ink; compare retunes against heightRatio, not 48 rows.',
  });
  // Hover / Tap-Frenzy halo: soft pixel oval, solid core + 2 dithered rings, banana-highlight h.
  // Drawn at the same x5 scale as the banana; alpha is set by code (0.3 hover, 0.35-0.85 frenzy).
  const HW = 44, HH = 56, hcx = (HW - 1) / 2, hcy = (HH - 1) / 2;
  const rx = 19.5, ry = 26.5;
  const halo = blank(HW, HH);
  for (let y = 0; y < HH; y++) for (let x = 0; x < HW; x++) {
    const e = Math.hypot((x - hcx) / rx, (y - hcy) / ry); // 1.0 = outer edge
    const checker = (x + y) % 2 === 0;
    const sparse = x % 2 === 0 && y % 2 === 0;
    if (e <= 0.8) halo[y][x] = 'h';
    else if (e <= 0.9 && checker) halo[y][x] = 'h';
    else if (e <= 1.0 && sparse) halo[y][x] = 'h';
  }
  const b0 = bounds[0];
  add('magicianStandIn_halo', [toRows(halo)], {
    pivot: [0.5, 0.5],
    alignTo: { sprite: 'magicianStandIn', canvasPx: [(b0.x0 + b0.x1 + 1) / 2, (b0.y0 + b0.y1 + 1) / 2] },
    note: 'Draw BEHIND magicianStandIn at the same scale, origin (0.5,0.5), centred on the banana rest bbox centre: magicianStandIn canvas px alignTo.canvasPx (from its top-left). Alpha by code. Never follows the squash frames.',
  });
}

// ---------------------------------------------------------------------------
// GOLDEN BANANA — 16×16, amber (never Big-Banana yellow), smile crescent +
// 4-point sparkle. [0] base, [1] sparkle flare.
// ---------------------------------------------------------------------------
const goldenBase = [
  '................',
  '................',
  '................',
  '..bb............',
  '...bO.......Ob..',
  '...wOO.....OOo..',
  '...wOOO...OOOo..',
  '...OwOOOOOOOoo..',
  '....OwwwOOOOoo..',
  '.....OOOOOOooo..',
  '......ooooooo...',
  '................',
  '................',
  '................',
  '................',
  '................',
];
function halo(g, ink = 'w') {
  // exclusive to the Golden Banana: a 1-px warm-white rim outside the ink outline
  const out = g.map((r) => r.slice());
  for (let y = 0; y < g.length; y++) for (let x = 0; x < g[0].length; x++) {
    if (g[y][x] !== '.') continue;
    if ([[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => g[y + dy]?.[x + dx] === 'k')) out[y][x] = ink;
  }
  return out;
}
{
  const base = halo(outline(toGrid(goldenBase, 'suitcaseStandIn'), 'k'));
  const f0 = stamp(base.map((r) => r.slice()), ['.w.', 'wOw', '.w.'], 11, 0);
  const f1 = stamp(base.map((r) => r.slice()), ['..w..', '..w..', 'wwOww', '..w..', '..w..'], 10, -1);
  stamp(f1, ['w'], 1, 12);
  stamp(f1, ['w'], 14, 11);
  // Tilt frames: nearest-neighbour rotations of goldenBase about (8,7), then hand-cleaned
  // (stray pixels removed, bottom curve re-rounded, highlight kept as one streak).
  // Not flipX: the crescent is asymmetric (stem left, dark tip right).
  const tiltCCW = [ // -8° (Phaser angle -8, counter-clockwise): right tip rises
    '................',
    '................',
    '................',
    '............Ob..',
    '..bbO......OOo..',
    '...OOO.....OOo..',
    '...wOOO...OOoo..',
    '...OwOOOOOOOoo..',
    '...OOwwwOOOOoo..',
    '....OOOOOOOoo...',
    '......oooooo....',
    '................',
    '................',
    '................',
    '................',
    '................',
  ];
  const tiltCW = [ // +8° (Phaser angle +8, clockwise): stem side rises
    '................',
    '................',
    '...bb...........',
    '...bO...........',
    '...wO...........',
    '...wOO.....OOb..',
    '...OOOO...OOOo..',
    '....wOOOOOOOOo..',
    '....OwwwOOOOoo..',
    '.....OOOOOOOoo..',
    '......ooooooo...',
    '................',
    '................',
    '................',
    '................',
    '................',
  ];
  const f2 = stamp(halo(outline(toGrid(tiltCCW, 'suitcaseStandIn/tiltCCW'), 'k')), ['.w.', 'wOw', '.w.'], 8, 0);
  const f3 = stamp(halo(outline(toGrid(tiltCW, 'suitcaseStandIn/tiltCW'), 'k')), ['.w.', 'wOw', '.w.'], 11, 1);
  add('suitcaseStandIn', [toRows(f0), toRows(f1), toRows(f2), toRows(f3)], {
    pivot: [0.5, 0.5],
    frames: ['idle (upright, sparkle)', 'sparkle flare (upright)', 'tilt -8 deg (counter-clockwise)', 'tilt +8 deg (clockwise)'],
    note: 'Amber O/o body, k outline, w halo (halo is exclusive to the Golden Banana). Tilt frames replace runtime rotation; sequence up, +8, up, -8 per motion/object-motion.md section 2.',
  });
}

// ---------------------------------------------------------------------------
// Shared monkey parts (16 wide). Head occupies rows 0–9.
// ---------------------------------------------------------------------------
const HEAD = [
  '................',
  '.....BBBBBB.....',
  '....BWWBBBBb....',
  '..BBWBBBBBBBbb..',
  '.BFBBFFBBFFBbfb.',
  '.BFBFwkFFwkFbfb.',
  '..BBFkkFFkkFbb..',
  '...BFFFffFFFb...',
  '...bFFkFFkFfb...',
  '....bFFkkFfb....',
];
const HEAD_BLINK = replace(HEAD.slice(), {}).map((r, i) => (i === 5 ? '.BFBFFFFFFFFbfb.' : r));
// top-of-head without hair tuft (for hats)
const HEAD_NOTOP = HEAD.map((r, i) => (i < 3 ? '................' : r));
const HARDHAT = [
  '......wwww......',
  '....wwwswwss....',
  '...wwwwswwwss...',
  '...wwwwswwwss...',
  '.SssssssssssssS.',
];
const BROWS = ['................', '................', '................', '................', '....kkk..kkk....'];
const GOGGLES_A = ['....gggBBggg....', '...gLGggLGgg....', '...gGgLgGgLg....', '....ggg..ggg....'];
const GOGGLES_B = ['....gggBBggg....', '...gGLggGLgg....', '...gLgGgLgGg....', '....ggg..ggg....'];
const BUST_PLAIN = [
  '...BBBbbbbBbb...',
  '..BBWBBBBbbbbb..',
  '..BBBBBBBbbbbb..',
  '..BBBBBBBbbbbb..',
  '..BBBBBBBbbbbb..',
];
const BUST_INTERN = [
  '...BBAbbbbAbb...',
  '..BBWBAbbAbbbb..',
  '..BBBBwwwwbbbb..',
  '..BBBBwAAwbbbb..',
  '..BBBBwsswbbbb..',
];
const BUST_TIE = [
  '...wwwbbbbwww...',
  '..BBwwwRRwwbbb..',
  '..BBBBwRRwbbbb..',
  '..BBBBBRrbbbbb..',
  '..BBBBBRrbbbbb..',
];

// sitting body, rows 10–14 (y offset 10), tail curling on the right
const BODY = [
  '....bBBBBBBb..b.',
  '...FBBFFFFBbF.b.',
  '...FBBFFFFBbFb..',
  '....BBBFFBbbb...',
  '...FFBb..bBFF...',
];

// ---------------------------------------------------------------------------
// PRODUCER ICONS (16×16)
// ---------------------------------------------------------------------------
add('icon_intern', [compose(16, 16, [[HEAD, 0, 0], [BUST_INTERN, 0, 10]])]);

add('icon_tree', [F([
  '................',
  '...LG.....GL....',
  '..LGGG...GGGL...',
  '.LGgGGG.GGGgGL..',
  '.Gg..gGGGg..gG..',
  '.g..hYYBBgg..g..',
  '....YYyWbYy.....',
  '.....yYWbyY.....',
  '......yWb.y.....',
  '......BWb.......',
  '......WBb.......',
  '......BWb.......',
  '.....BWBBb......',
  '...GGWBBBbGG....',
  '..GgggggggggG...',
  '................',
], 'icon_tree')]);

add('icon_hardhat', [compose(16, 16, [
  [BUST_PLAIN, 0, 10], [HEAD_NOTOP, 0, 0], [HARDHAT, 0, 0],
  [['....S.', '...SsS', '..W..S', '.W....', 'W.....'], 9, 10],
])]);

add('icon_bureaucrat', [compose(16, 16, [
  [HEAD, 0, 0], [BROWS, 0, 0], [BUST_TIE, 0, 10],
  [['.hY', 'hYy', '.S.', 'RRR'], 12, 11],
])]);

add('icon_catapult', [F([
  '................',
  '..hY............',
  '.hYYy...........',
  '.bYyb...........',
  '.bbbbW..........',
  '.....WW.........',
  '......WW........',
  '.......WW..s....',
  '........WWSs....',
  '.......BWBWs....',
  '......BW..BW....',
  '.....BW....BW...',
  '..WWWWWWWWWWWW..',
  '..BbBBBBBBBBbB..',
  '..sSs......sSs..',
  '................',
], 'icon_catapult')]);

add('icon_rocket', [F([
  '................',
  '.......bb.......',
  '......hYYy......',
  '......YYYy......',
  '.....hYYYYy.....',
  '.....wwwwws.....',
  '.....wSSSSs.....',
  '.....SFkFkS.....',
  '.....SBFFBS.....',
  '.....wSSSSs.....',
  '.....wwwwws.....',
  '....RwwwwwsR....',
  '...RRwwwwwsRR...',
  '...Rr.RwR..rR...',
  '.......w........',
  '................',
], 'icon_rocket')]);

add('icon_timechimp', [compose(16, 16, [
  [HEAD, 0, 0], [GOGGLES_A, 0, 4], [BUST_PLAIN, 0, 10],
  [['.ss.', 'swks', 'swws', '.ss.'], 11, 10],
])]);

add('icon_moon', [F([
  '................',
  '.....bb.........',
  '....hYYy........',
  '...hYYy.........',
  '..hYYy..........',
  '..hYYy......s...',
  '.hYYy.......sRR.',
  '.hYYy.......sRRR',
  '.hYYy.......s...',
  '.hYYYy......s...',
  '..hYYYy....YY...',
  '..yYYYYyyyYYy...',
  '...yYYYYYYYy....',
  '....yyyyyyy.....',
  '................',
  '................',
], 'icon_moon')]);

// ---------------------------------------------------------------------------
// UPGRADE ICONS (16×16)
// ---------------------------------------------------------------------------
add('icon_glove', [F([
  '................',
  '.....ww.ww......',
  '....wwwwwwww....',
  '....wwwwwwwws...',
  '....wwwwwwwws...',
  '.ww.wwwwwwwws...',
  '.wwwwwwwwwwws...',
  '..wwwwwwwwwss...',
  '...wwwwwwwss....',
  '....wwwwwss.....',
  '....ssssssss....',
  '....wwwwwwws....',
  '....ssssssss....',
  '................',
  '................',
  '................',
], 'icon_glove')]);

add('icon_bothhands', [F([
  '................',
  '...FFFF..FFFF...',
  '...FfFf..fFfF...',
  '...FfFf..fFfF...',
  '.F.FFFF..FFFF.F.',
  '.FFFFFF..FFFFFF.',
  '.FFFfFf..fFfFFF.',
  '..FFFFf..fFFFF..',
  '..FFFf....fFFF..',
  '...BBB....BBB...',
  '...BBb....bBB...',
  '...BBb....bBB...',
  '................',
  '................',
  '................',
  '................',
], 'icon_bothhands')]);

add('icon_workout', [F([
  '................',
  '......FF........',
  '.....FFFf.......',
  '.....FFFf.......',
  '.....wRRw.......',
  '.....RRRr.......',
  '.....FFFf.......',
  '...FFFFFFFf.....',
  '..FFFFFFFFFf....',
  '..FfFFFFFFFf....',
  '..FFfFFFFFff....',
  '...FFFFFFFf.....',
  '...BBBBBBBb.....',
  '...BBBBBBbb.....',
  '................',
  '................',
], 'icon_workout')]);

add('icon_luckypeel', [F([
  '................',
  '.......bb.......',
  '.......YY.......',
  '......hYYy......',
  '......hYYy......',
  '.....hYYYYy.....',
  '....hYGYYYYy....',
  '...hYGLGYYYYy...',
  '..hYYYGYYyhYYy..',
  '.hYy.YgYy..hYy..',
  '.Yy..hYYy...Yy..',
  '.y...hYy.....y..',
  '.....Yy.........',
  '.....y..........',
  '................',
  '................',
], 'icon_luckypeel')]);

add('icon_radar', [F([
  '................',
  '..........w.....',
  '.........wOw....',
  '..s.......o.....',
  '..ss............',
  '..sws.....S.....',
  '..swws...S......',
  '..swwwsSS.......',
  '...swwwws.......',
  '....swwwwsss....',
  '.....SsssssS....',
  '.......SS.......',
  '.......SS.......',
  '.....SSSSSS.....',
  '................',
  '................',
], 'icon_radar')]);

add('icon_futures', [F([
  '................',
  '..........LGG...',
  '...........GG...',
  '.........LG.G...',
  '..LG....LG......',
  '.LGgG..LG.......',
  'LG..GLLG........',
  'g....GG.........',
  '................',
  '...hYYYYYYYy....',
  '..hYYYYYYYYYy...',
  '.bYyyyyyyyyyyb..',
  '................',
  '................',
  '................',
  '................',
], 'icon_futures')]);

add('icon_hammer', [F([
  '................',
  '................',
  '.b...........b..',
  '.Yh.........hY..',
  '.YYhhhhhhhhhYY..',
  '..YYYYYYYYYYy...',
  '...yyyyyyyyy....',
  '.......WB.......',
  '.......WB.......',
  '.......WB.......',
  '.......WB.......',
  '.......WB.......',
  '.......WB.......',
  '.......bb.......',
  '................',
  '................',
], 'icon_hammer')]);

{
  const mug = toGrid(F([
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '..WWWWWWWW......',
    '..WBBBBBBb.hY...',
    '..BbbbbbbbYyy...',
    '..BBBBBBBbY.y...',
    '..BBBBBBBbYyy...',
    '..BBBBBBBbhy....',
    '..BBBBBBBb......',
    '...bbbbbb.......',
    '................',
    '................',
  ], 'icon_internx2'), 'mug');
  stamp(mug, ['..w..w.', '.w..w..', '.w..w..', '..w..w.'], 2, 1); // steam, no ink
  add('icon_internx2', [toRows(mug)]);
}

add('icon_treex2', [F([
  '................',
  '......b.b.......',
  '.....WbWb.......',
  '.....WWWW.......',
  '....WWWWWB......',
  '...WWWWWWWB.....',
  '..WWWWWWWWWB....',
  '..WWhYYYyWWB....',
  '..WWYYYYYyWB....',
  '..WWWyyyyWWB....',
  '..WWWWWWWWWB....',
  '..WBWWWBWWBB....',
  '...BBBBBBBB.....',
  '................',
  '................',
  '................',
], 'icon_treex2')]);

add('icon_hardhatx2', [F([
  '................',
  '....hYYy........',
  '...hYYYYy.......',
  '....yyyy........',
  '...W....B.......',
  '...WBBBBB.......',
  '...W....B.......',
  '...W....B.......',
  '...WBBBBB.......',
  '...W....B.......',
  '...W....B.......',
  '...WBBBBB.......',
  '...W....B.......',
  '...b....b.......',
  '................',
  '................',
], 'icon_hardhatx2')]);

add('icon_bureaucratx2', [F([
  '................',
  '.....SSSS.......',
  '..WWWSssSWWW....',
  '..WwwwwwwwwW....',
  '..WwsssssswW....',
  '..WwwwwwwwwW....',
  '..WwRRRRwwwW....',
  '..WwRwwwRwwW....',
  '..WwwRRRRRwW....',
  '..WwwwwwwwwW....',
  '..WwssswwwwW....',
  '..WwwwwwwwwW....',
  '..WBBBBBBBBW....',
  '................',
  '................',
  '................',
], 'icon_bureaucratx2')]);

add('icon_catapultx2', [F([
  '................',
  '..hY......Yh....',
  '..bYy....yYb....',
  '...YYy..yYY.....',
  '....YYyyYY......',
  '.....hYYh.......',
  '....YYyyYY......',
  '...YYy..yYY.....',
  '..bYy....yYb....',
  '................',
  '...ssssssss.....',
  '....SSSSSS......',
  '...ssssssss.....',
  '....SSSSSS......',
  '...ssssssss.....',
  '................',
], 'icon_catapultx2')]);

add('icon_rocketx2', [F([
  '................',
  '......SSS.......',
  '.....SsSS.......',
  '...RRRRRRRR.....',
  '..RRRRRRRRRr....',
  '..RwRRRRRRRr....',
  '..RwRRhYRRRr....',
  '..RRRhYyYRRr....',
  '..RRRYy.yRRr....',
  '..RRRRRRRRRr....',
  '..RRRRRRRRRr....',
  '..RRRRRRRRrr....',
  '...rrrrrrrr.....',
  '................',
  '................',
  '................',
], 'icon_rocketx2')]);

add('icon_timechimpx2', [F([
  '................',
  '...BBBBBBBBB....',
  '...WWWWWWWWb....',
  '....ssssss......',
  '....wsssss......',
  '.....WWWs.......',
  '......Ws........',
  '......Ws........',
  '.....sYYs.......',
  '....shYyys......',
  '....WWWWWs......',
  '...WWWWWWWs.....',
  '...WWWWWWWWb....',
  '...BBBBBBBBB....',
  '................',
  '................',
], 'icon_timechimpx2')]);

add('icon_moonx2', [F([
  '................',
  '................',
  '...bb......bb...',
  '..hYy.....hYy...',
  '.hYy.....hYy....',
  '.hYy.....hYy....',
  '.hYy.....hYy....',
  '.hYYy....hYYy...',
  '..hYYyy...hYYyy.',
  '...yyyy....yyyy.',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
], 'icon_moonx2')]);

// ---------------------------------------------------------------------------
// CURRENCY ICONS
// ---------------------------------------------------------------------------
add('icon_thumb', [F([
  '................',
  '......BB........',
  '.....BWBb.......',
  '.....BWBb.......',
  '.....BWBb.......',
  '.....BBBb.......',
  '..BBBBBBBBb.....',
  '.BWWBBBBBBbb....',
  '.BWBBBBBBBBb....',
  '.BBFFFFFFFBb....',
  '.BBBBBBBBBBb....',
  '.BWFFFFFFBbb....',
  '.BBBBBBBBBb.....',
  '..bBBBBBBb......',
  '...bbbbbb.......',
  '................',
], 'icon_thumb')]);

add('icon_crescent', [F([
  '..........',
  '.......bb.',
  '.......Yy.',
  '......hYy.',
  '.....hYYy.',
  '.hhhYYYy..',
  '.yYYYYy...',
  '..yyyy....',
  '..........',
  '..........',
], 'icon_crescent')]);

// ---------------------------------------------------------------------------
// SCENE CRITTERS (16×16, 2 idle frames each)
// ---------------------------------------------------------------------------
function monkey({ head = HEAD, headDy = 0, extra = [], tailAlt = false }) {
  const body = tailAlt
    ? BODY.map((r, i) => (i === 0 ? '....bBBBBBBb.b..' : i === 1 ? '...FBBFFFFBbFb..' : i === 2 ? '...FBBFFFFBbFb..' : r))
    : BODY;
  const layers = [[body, 0, 10], [head, 0, headDy], ...extra];
  return compose(16, 16, layers);
}
const LANYARD = ['......A..A......', '.......ww.......', '.......AA.......'];
add('critter_intern', [
  monkey({ extra: [[LANYARD, 0, 10]] }),
  monkey({ head: HEAD_BLINK, headDy: 1, tailAlt: true, extra: [[LANYARD, 0, 11]] }),
]);

const PICK_UP = ['..S..', '.SsS.', 'S.W.S', '..W..', '..W..'];
const PICK_DN = ['.....', '...W.', '..W..', 'SsS..', '.S...'];
add('critter_hardhat', [
  monkey({ head: HEAD_NOTOP, extra: [[HARDHAT, 0, 0], [PICK_UP, 11, 8]] }),
  monkey({ head: HEAD_NOTOP, headDy: 1, tailAlt: true, extra: [[HARDHAT, 0, 1], [PICK_DN, 11, 10]] }),
]);

const TIE = ['...wwwbbbbwww...', '......wRRw......', '.......RR.......', '.......Rr.......'];
const STAMP_UP = ['.Y.', 'hYy', '.S.', 'RRR'];
const STAMP_DN = ['...', '.Y.', 'hYy', 'RRR'];
add('critter_bureaucrat', [
  monkey({ extra: [[BROWS, 0, 0], [TIE, 0, 10], [STAMP_UP, 12, 8]] }),
  monkey({ headDy: 1, tailAlt: true, extra: [[BROWS, 0, 1], [TIE, 0, 11], [STAMP_DN, 12, 10]] }),
]);

const CLOCK_A = ['.ss.', 'swks', 'swws', '.ss.'];
const CLOCK_B = ['.ss.', 'swws', 'swks', '.ss.'];
add('critter_timechimp', [
  monkey({ extra: [[GOGGLES_A, 0, 4], [CLOCK_A, 12, 11]] }),
  monkey({ headDy: 1, tailAlt: true, extra: [[GOGGLES_B, 0, 5], [CLOCK_B, 12, 11]] }),
]);

add('critter_tree', [F([
  '................',
  '...LG.....GL....',
  '..LGGG...GGGL...',
  '.LGgGGG.GGGgGL..',
  '.Gg..gGGGg..gG..',
  '.g..hYYBBgg..g..',
  '....YYyWbYy.....',
  '.....yYWbyY.....',
  '......yWb.y.....',
  '......BWb.......',
  '......WBb.......',
  '......BWb.......',
  '......WBb.......',
  '.....BWBBb......',
  '...GgWBBBbgG....',
  '................',
], 'critter_tree'), F([
  '................',
  '....LG.....GL...',
  '...LGGG...GGGL..',
  '..LGgGGG.GGGgGL.',
  '..Gg..gGGGg..gG.',
  '..g..hYYBBgg..g.',
  '....YYyWbYy.....',
  '.....yYWbyY.....',
  '......yWb.y.....',
  '......BWb.......',
  '......WBb.......',
  '......BWb.......',
  '......WBb.......',
  '.....BWBBb......',
  '...GgWBBBbgG....',
  '................',
], 'critter_tree/1')]);

add('critter_catapult', [F([
  '................',
  '................',
  '..hY............',
  '.hYYy...........',
  '.bYyb...........',
  '.bbbbW..........',
  '.....WW.........',
  '......WW........',
  '.......WW..s....',
  '........WWSs....',
  '.......BWBWs....',
  '......BW..BW....',
  '..WWWWWWWWWWWW..',
  '..BbBBBBBBBBbB..',
  '..sSs......sSs..',
  '................',
], 'critter_catapult'), F([
  '................',
  '................',
  '................',
  '..hY............',
  '.hYYy...........',
  '.bYybW..........',
  '.bbbbWW.........',
  '......WWW.......',
  '........WW.s....',
  '.........WSs....',
  '.......BWBWs....',
  '......BW..BW....',
  '..WWWWWWWWWWWW..',
  '..BbBBBBBBBBbB..',
  '..Ssw......Ssw..',
  '................',
], 'critter_catapult/1')]);

const ROCKET_BODY = [
  '.......bb.......',
  '......hYYy......',
  '......YYYy......',
  '.....hYYYYy.....',
  '.....wwwwws.....',
  '.....wSSSSs.....',
  '.....SFkFkS.....',
  '.....SBFFBS.....',
  '.....wSSSSs.....',
  '.....wwwwws.....',
  '....RwwwwwsR....',
  '...RRwwwwwsRR...',
  '...Rr......rR...',
];
add('critter_rocket', [
  compose(16, 16, [[ROCKET_BODY, 0, 0], [['......RwwR......', '.......Rw.......'], 0, 13]]),
  compose(16, 16, [[ROCKET_BODY, 0, 0], [['......RwhR......', '.......RR.......', '.......R........'], 0, 13]]),
]);

const MOON_BODY = [
  '................',
  '.....bb.........',
  '....hYYy........',
  '...hYYy.........',
  '..hYYy..........',
  '..hYYy..........',
  '.hYYy...........',
  '.hYYy...........',
  '.hYYy...........',
  '.hYYYy..........',
  '..hYYYy....YY...',
  '..yYYYYyyyYYy...',
  '...yYYYYYYYy....',
  '....yyyyyyy.....',
  '................',
  '................',
];
add('critter_moon', [
  compose(16, 16, [[MOON_BODY, 0, 0], [['s..', 'sRR', 'sRRR', 's..', 's..'].map((r) => r.padEnd(4, '.')), 12, 5]]),
  compose(16, 16, [[MOON_BODY, 0, 0], [['s...', 'sRRR', 'sRR.', 's...', 's...'], 12, 5]]),
].map((f, i) => {
  // twinkle star stamped after outline (no ink): alternates position
  const g = toGrid(f, 'critter_moon');
  stamp(g, i === 0 ? ['.w.', 'whw', '.w.'] : ['w'], i === 0 ? 7 : 8, i === 0 ? 3 : 4);
  return toRows(g);
}));

// ---------------------------------------------------------------------------
// ENVIRONMENT (tonal outlines — recede behind the figure layer)
// ---------------------------------------------------------------------------
// Grass top edge, tiles horizontally (cols 0 and 15 continue each other).
add('env_grass', [F([
  '..L.......L.....',
  '.LG..L...LG...L.',
  'LGGLLG..LGGL.LGL',
  'GGGGGGLLGGGGGGGG',
  'GgGGGGGGGgGGGGgG',
  'gGGgGGgGGGGgGGGg',
  'ggGggGgggGgGggGg',
  'bgggbgggbggbgggb',
  'BbBbBBbBBbBbBBbB',
  'BBBBBBBBBBBBBBBB',
  'BBbBBBBBWBBBBbBB',
  'BBBBBbBBBBBBBBBB',
  'BWBBBBBBBBbBBWBB',
  'BBBBBBBBBBBBBBBB',
  'BBBbBBBBBBBBBBBB',
  'BBBBBBBBWBBBbBBB',
], 'env_grass', null)], { tile: 'horizontal', note: 'Ground top edge. Tile along x. Below it fill with env_ground.' });

add('env_ground', [F([
  'BBBBBBBBBBBBBBBB',
  'BBbBBBBBWBBBBbBB',
  'BBBBBbBBBBBBBBBB',
  'BWBBBBBBBBbBBWBB',
  'BBBBBBBBBBBBBBBB',
  'BBBbBBBBBBBBBBBB',
  'BBBBBBBBWBBBbBBB',
  'BBBBBBBBBBBBBBBB',
  'BBBBBbBBBBBBBBBB',
  'BBWBBBBBBBBbBBBB',
  'BBBBBBBBBBBBBBBW',
  'bBBBBBBBBbBBBBBB',
  'BBBBBBWBBBBBBBBB',
  'BBBBBBBBBBBBWBBB',
  'BBBbBBBBBBBBBBBB',
  'BBBBBBBBBBbBBBBB',
], 'env_ground', null)], { tile: 'both', note: 'Dirt fill, tiles in x and y.' });

add('env_foliage_a', [F([
  '................',
  '................',
  '.....LL.........',
  '....LGGL..LL....',
  '...LGGGGLLGGL...',
  '..LGGgGGGGGGGL..',
  '.LGGGGGgGGgGGG..',
  '.GGgGGGGGGGGgG..',
  '.GGGGgGGGgGGGGg.',
  '.gGGGGGGGGGgGGg.',
  '.ggGgGGgGGGGggg.',
  '..gggggggggggg..',
  '................',
  '................',
  '................',
  '................',
], 'env_foliage_a', 'g')], { note: 'small bush clump, decorative' });

add('env_foliage_b', [F([
  '........................',
  '.........L..............',
  '....L...LG.....L........',
  '...LG..LGG....LG....L...',
  '..LGG.LGGGL..LGGL..LG...',
  '..GGGLGGgGGLLGGGGLLGG...',
  '.LGgGGGGGGGGGGgGGGGGGL..',
  '.GGGGGgGGGGgGGGGGGgGGG..',
  '.GgGGGGGGGGGGGGGgGGGGGg.',
  '.gGGGgGGGgGGGGGGGGGGgGg.',
  '.ggGGGGgGGGGgGGgGGGGGgg.',
  '.gggGggggGggggggGggggg..',
  '..ggggggggggggggggggg...',
  '........................',
  '........................',
  '........................',
], 'env_foliage_b', 'g')], { note: 'wide leafy clump, decorative' });

add('env_palm_trunk', [F([
  '................',
  '......WBBb......',
  '.....WBBBBb.....',
  '......bbbb......',
  '......WBBb......',
  '......WBBb......',
  '.....WBBBBb.....',
  '......bbbb......',
  '......WBBb......',
  '......WBBb......',
  '.....WBBBBb.....',
  '......bbbb......',
  '......WBBb......',
  '......WBBb......',
  '.....WBBBBb.....',
  '......bbbb......',
].map((r, i) => r), 'env_palm_trunk', null)].map((f) => f), { tile: 'vertical', note: 'trunk segment, tiles in y (4-row ring rhythm, no outline so it stacks seamlessly)' });

add('env_palm_crown', [F([
  '................................',
  '...........LL......LL...........',
  '.......LLLGGGL....LGGGLLL.......',
  '.....LLGGGGGGGL..LGGGGGGGLL.....',
  '...LLGGGGggGGGGLLGGGGggGGGGLL...',
  '..LGGGggg...gGGGGGGg...gggGGGL..',
  '.LGGgg.......gGGGGg.......ggGGL.',
  '.Ggg.......LLGGWBGGLL.......ggG.',
  '.g.......LLGGGgBBgGGGLL.......g.',
  '........LGGGgg.bb.ggGGGL........',
  '.......LGGgg..........ggGGL.....',
  '......LGGg..............gGGL....',
  '......GGg................gGG....',
  '.....LGg..................gGL...',
  '.....Gg....................gG...',
  '.....g......................g...',
], 'env_palm_crown', 'g')], { pivot: [0.5, 0.56], note: 'crown knot (B/b at x=15..16, y=7..9) sits on top of the env_palm_trunk column' });

add('env_cloud', [F([
  '........................',
  '.........wwww...........',
  '.......wwwwwwww.........',
  '...www.wwwwwwwww.www....',
  '..wwwwwwwwwwwwwwwwwwww..',
  '.wwwwwwwwwwwwwwwwwwwwww.',
  '.wwwwwwwwwwwwwwwwwwwwww.',
  '..sswwwwwwsssswwwwwsss..',
  '....ssssss....sssss.....',
  '........................',
  '........................',
  '........................',
], 'env_cloud', null)], { note: 'no outline; drifts on the sky layer' });

// ---------------------------------------------------------------------------
// UI — v1.1 "bright toy box" (style-guide §11). Supersedes the round-2 dark-plum set.
// ---------------------------------------------------------------------------
// Every UI shape is procedural: a rounded body mask, a BFS depth pass (depth 1 = ink outline,
// depth 2.. = coloured ring), then row-based gloss (top), inner shadow (sunken) and lip (bottom
// extrusion that doubles as the toy "drop shadow"). Shapes are built on a generous canvas and then
// cropped by crop9() to the smallest source whose centre bands are exactly 2 px and flat, so the
// 9-slice insets are *measured*, never hand-typed, and flatness holds by construction.
//
// Corner tables: transparent px per row, counted from the corner edge (row 0 = outermost row).
// Every table is transpose-symmetric, so the arc reads the same by row and by column.
const ARC = {
  1: [1],
  4: [3, 1, 1, 0], // soft corner, reads r ~ 3.5 art px
  6: [4, 2, 1, 1, 0, 0], // modal card corner
  8: [6, 4, 3, 2, 1, 1, 0, 0], // capsule end: on a 20-art-px control it reads as a pill
};
const CIRCLE = { 8: [2, 1, 0, 0], 16: [5, 3, 2, 1, 1, 0, 0, 0] }; // quadrant tables (diameter 8 / 16)

function bodyMask(w, h, { box = [0, 0, w - 1, h - 1], tl = null, tr = null, bl = null, br = null } = {}) {
  const [x0, y0, x1, y1] = box;
  const m = Array.from({ length: h }, () => Array(w).fill(false));
  for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) {
    const dt = y - y0, db = y1 - y, dl = x - x0, dr = x1 - x;
    if (tl && dt < tl.length && dl < tl[dt]) continue;
    if (tr && dt < tr.length && dr < tr[dt]) continue;
    if (bl && db < bl.length && dl < bl[db]) continue;
    if (br && db < br.length && dr < br[db]) continue;
    m[y][x] = true;
  }
  return m;
}
const corners = (t, which = 'tl tr bl br') => Object.fromEntries(which.split(' ').map((k) => [k, t]));

// o: { mask, open:{top,bottom,left,right}, ink, ring:[], fill, gloss, glossRows, shade, shadeRows,
//      lip, lipRows, hollowFrom }
function shade9(w, h, o) {
  const m = o.mask;
  const open = o.open ?? {};
  const inside = (x, y) => {
    if (y < 0) return !!open.top;
    if (y >= h) return !!open.bottom;
    if (x < 0) return !!open.left;
    if (x >= w) return !!open.right;
    return m[y][x];
  };
  // BFS depth from every non-body cell (a 1-cell padding stands in for the canvas border).
  const D = Array.from({ length: h }, () => Array(w).fill(Infinity));
  const q = [];
  for (let y = -1; y <= h; y++) for (let x = -1; x <= w; x++) if (!inside(x, y)) q.push([x, y, 0]);
  const seen = new Set(q.map(([x, y]) => x + ',' + y));
  for (let i = 0; i < q.length; i++) {
    const [x, y, d] = q[i];
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const nx = x + dx, ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= w || ny >= h || !m[ny][nx]) continue;
      const k = nx + ',' + ny;
      if (seen.has(k)) continue;
      seen.add(k); D[ny][nx] = d + 1; q.push([nx, ny, d + 1]);
    }
  }
  const ring = o.ring ?? [];
  const cls = (x, y) => { // 'out' | 'ink' | 'ring' | 'fill'
    if (!inside(x, y)) return 'out';
    if (x < 0 || y < 0 || x >= w || y >= h) return 'fill'; // open edge continues the fill
    const d = D[y][x];
    if (o.ink && d === 1) return 'ink';
    if (d - (o.ink ? 2 : 1) < ring.length) return 'ring';
    if (o.hollowFrom && d >= o.hollowFrom) return 'out';
    return 'fill';
  };
  const g = blank(w, h);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const c = cls(x, y);
    if (c === 'out') continue;
    if (c === 'ink') g[y][x] = o.ink;
    else if (c === 'ring') g[y][x] = ring[D[y][x] - (o.ink ? 2 : 1)];
    else g[y][x] = o.fill;
  }
  const edgeAbove = (x, y, n) => { for (let i = 1; i <= n; i++) if (cls(x, y - i) !== 'fill') return true; return false; };
  const edgeBelow = (x, y, n, onlyInk) => {
    for (let i = 1; i <= n; i++) { const c = cls(x, y + i); if (c === 'out' || c === 'ink' || (!onlyInk && c === 'ring')) return true; }
    return false;
  };
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const c = cls(x, y);
    if (c === 'fill' && o.gloss && edgeAbove(x, y, o.glossRows ?? 1)) g[y][x] = o.gloss;
    if (c === 'fill' && o.shade && edgeAbove(x, y, o.shadeRows ?? 1)) g[y][x] = o.shade;
    if ((c === 'fill' || c === 'ring') && o.lip && edgeBelow(x, y, o.lipRows ?? 1, true)) g[y][x] = o.lip;
  }
  return toRows(g);
}

// Crop a set of same-size frames to the smallest 9-slice source whose centre bands are exactly
// 2 px and flat along their stretch axis in *every* frame. Insets are clamped to >= minInset
// (a clamped side is filled from the flat run, so flatness still holds). Returns { frames, nineSlice }.
function crop9(frames, minInset = 1) {
  const h = frames[0].length, w = frames[0][0].length;
  const colKey = (x) => frames.map((f) => f.map((r) => r[x]).join('')).join('|');
  const rowKey = (y) => frames.map((f) => f[y]).join('|');
  const run = (n, key) => { // longest run of identical consecutive slices; ties go to the most central
    const segs = [];
    let a = 0;
    for (let i = 1; i <= n; i++) if (i === n || key(i) !== key(a)) { segs.push([a, i - 1]); a = i; }
    const mid = (n - 1) / 2;
    segs.sort((p, q) => (q[1] - q[0]) - (p[1] - p[0]) || Math.abs((p[0] + p[1]) / 2 - mid) - Math.abs((q[0] + q[1]) / 2 - mid));
    return segs[0];
  };
  const axis = (n, key) => {
    const [a, b] = run(n, key);
    if (b - a < 1) throw new Error('crop9: no 2-px flat centre band');
    const lo = Math.max(minInset, a), hi = Math.max(minInset, n - 1 - b);
    // new index -> original index (any index inside [a, b] is equivalent)
    const map = (j) => (j < lo ? Math.min(j, a) : j < lo + 2 ? a : Math.max(b, n - hi + (j - lo - 2)));
    return { lo, hi, len: lo + 2 + hi, map };
  };
  const X = axis(w, colKey), Y = axis(h, rowKey);
  const out = frames.map((f) => Array.from({ length: Y.len }, (_, j) => Array.from({ length: X.len }, (_, i) => f[Y.map(j)][X.map(i)]).join('')));
  return { frames: out, nineSlice: { left: X.lo, right: X.hi, top: Y.lo, bottom: Y.hi } };
}
function add9(id, frames, meta = {}, minInset = 1) {
  const { frames: fr, nineSlice } = crop9(frames, minInset);
  add(id, fr, { nineSlice, ...meta });
}

// ---- panels -----------------------------------------------------------------------------------
// Rounded card: 1-px ink, cream fill, w gloss, 2-row lip. Rows of the shop alternate frames 0/2.
const PW = 16, PH = 16;
const panelMask = bodyMask(PW, PH, corners(ARC[4]));
const panel = (fill, gloss, lip) => shade9(PW, PH, { mask: panelMask, ink: 'k', fill, gloss, lip, lipRows: 2 });
add9('ui_panel', [panel('c', 'w', 'i'), panel('i', null, 'I'), panel('m', 'w', 'i'), panel('i', null, 'I')], {
  frames: ['light card: shop row A can afford, buff chip (cream c, lip i)', "shop row A can't afford (lilac-grey i, no gloss)", 'shop row B can afford (mint m) — alternate rows 0/2', "shop row B can't afford (same as 1)"],
  cornerArtPx: 4,
  note: 'Labels k (C4). Do NOT use for the ticker occluders: they are 4 art px wide, below this sprite minimum; use ui_ticker.',
});

// Top-bar banner: flat top that bleeds off the canvas, rounded bottom corners, pink Q lip.
add9('ui_topbar', [shade9(PW, PH, { mask: bodyMask(PW, PH, corners(ARC[4], 'bl br')), open: { top: true }, ink: 'k', fill: 'q', lip: 'Q', lipRows: 1 })], {
  frames: ['hot-pink banner; the bottom 2 art px (lip Q + ink k) are the 152-160 border'], cornerArtPx: 4,
});
// Shop tray: flat shelf, open sides/bottom, ink + w gloss top border (712-720).
add9('ui_tray', [shade9(8, 8, { mask: bodyMask(8, 8), open: { left: true, right: true, bottom: true }, ink: 'k', fill: 'e', gloss: 'w' })], {
  frames: ['sky-cyan tray; top border = k + w (2 art px)'], cornerArtPx: 0,
});
// Ticker marquee strip: square ends so the side occluders (same sprite) butt seamlessly.
add9('ui_ticker', [shade9(8, 8, { mask: bodyMask(8, 8), open: { left: true, right: true }, ink: 'k', ring: ['q'], fill: 'U' })], {
  frames: ['deep-grape marquee with pink trim rows; text w (C7), milestone flash = UI_THEME.juiceGain'], cornerArtPx: 0,
  note: 'Use for the ticker panel AND both occluders (4 art px min width).',
});
// Modal card: 2-px pink ring, cream fill, pink Q lip under the ring.
{
  const W = 20, H = 20;
  add9('ui_card', [shade9(W, H, { mask: bodyMask(W, H, corners(ARC[6])), ink: 'k', ring: ['q', 'q'], fill: 'c', gloss: 'w', lip: 'Q', lipRows: 2 })], {
    frames: ['overlay card (SETTINGS, RESET_CONFIRM, EVOLUTION, OFFLINE); title/body k, group labels u'], cornerArtPx: 6,
  });
}
// Buff banner: deep-grape plate with pink ring; Y text (banana frenzy = banana meaning).
add9('ui_banner', [shade9(PW, PH, { mask: panelMask, ink: 'k', ring: ['q'], fill: 'U', lip: 'Q', lipRows: 1 })], {
  frames: ['buff banner (text Y, C9)'], cornerArtPx: 4,
});
// Stat window: ONE deep-grape "scoreboard" window on the pink banner holds bank, bps and thumbs;
// each stat keeps its own hue in its numerals (Y / v / e). Lilac bezel, amber bezel during Frenzy.
// (Three separate chips were tried and rejected: with an ink + ring edge the 8-art-px bps chip
// left 16 px for 21-px text; see style-guide §11.4.)
add9('ui_chip', ['j', 'O'].map((rc) => shade9(PW, PH, { mask: panelMask, ink: 'k', ring: [rc], fill: 'U', gloss: 'u' })), {
  frames: ['stat window, normal (lilac bezel j)', 'stat window during Frenzy (amber bezel O — Golden buff)'],
  cornerArtPx: 4,
});
// Icon plates behind shop-row icons, one accent per producer (content.json order), then extras.
const PLATE = ['e', 'v', 'x', 'j', 'q', 'E', 'a', 'u'];
add9('ui_plate', [
  ...PLATE.map((f) => shade9(PW, PH, { mask: panelMask, ink: 'k', fill: f, gloss: 'w' })),
  shade9(PW, PH, { mask: panelMask, ink: 'k', ring: ['q'], fill: 'w' }),
  shade9(PW, PH, { mask: panelMask, ink: 'k', fill: 'I', gloss: 'i' }),
], {
  frames: ['intern (e)', 'tree (v)', 'hardhat (x)', 'bureaucrat (j)', 'catapult (q)', 'rocket (E)', 'timechimp (a)', 'moon (u)', 'global/tap upgrade (w + q ring)', '??? silhouette (I)'],
  cornerArtPx: 4,
});

// ---- capsule controls (radius 8 art px, a pill on a 20-art-px control) ------------------------
const CW = 24, CH = 22;
const capMask = bodyMask(CW, CH, corners(ARC[8]));
const capMaskDown = bodyMask(CW, CH, { box: [0, 1, CW - 1, CH - 1], ...corners(ARC[8]) });
const raised = (fill, lip, lipRows = 2, gloss = 'w') => shade9(CW, CH, { mask: capMask, ink: 'k', fill, gloss, lip, lipRows });
const pressed = (fill, lip) => shade9(CW, CH, { mask: capMaskDown, ink: 'k', fill, shade: lip, lip, lipRows: 1 });
const hover = (fill, lip, rim = 'w') => shade9(CW, CH, { mask: capMask, ink: 'k', ring: [rim], fill, lip, lipRows: 2 });
const sunken = shade9(CW, CH, { mask: capMask, ink: 'k', fill: 'I', shade: 'u' });

add9('ui_button', [raised('v', 'G'), pressed('v', 'G'), sunken, hover('v', 'G')], {
  frames: ['default (raised lime, label k)', 'pressed (face down 1 art px, label +1 art px)', 'disabled / sunken (lavender I well, label k) — also the Evolve "not ready" state', 'hover (mouse only: w inner rim)'],
  cornerArtPx: 8,
});
add9('ui_pill', [raised('v', 'G', 1), sunken, pressed('v', 'G')], {
  frames: ['BUY (raised lime; verb + cost k)', 'NEED (sunken lavender; verb + cost k)', 'pressed (BUY held; label +1 art px down)'],
  cornerArtPx: 8,
  note: '1-row lip so the line-2 cost (ry+52..73) stays on the face.',
});
add9('ui_button_danger', [raised('x', 'R'), pressed('x', 'R'), hover('x', 'R')], {
  frames: ['default (coral, label k 6.0:1)', 'pressed', 'hover'], cornerArtPx: 8,
});
add9('ui_button_evolve', [raised('u', 'U', 2, 'j'), pressed('u', 'U'), hover('u', 'U', 'j')], {
  frames: ['EVOLVE ready (grape, lilac gloss, label w 5.4:1)', 'pressed', 'hover'], cornerArtPx: 8,
  note: 'Disabled Evolve uses ui_button frame 2. Evolution overlay EVOLVE! confirm uses this sprite too.',
});

// Toggle: fixed 36x20 capsule with a round 16-px knob (ON right, OFF left).
{
  const W = 36, H = 20;
  const track = (on) => shade9(W, H, { mask: bodyMask(W, H, corners(ARC[8])), ink: 'k', fill: on ? 'v' : 'I', gloss: on ? 'w' : null, shade: on ? null : 'u', lip: on ? 'G' : null, lipRows: 1 });
  const knob = shade9(16, 16, { mask: bodyMask(16, 16, corners(CIRCLE[16])), ink: 'k', fill: 'w', lip: 'i', lipRows: 2 });
  const f = (on) => { const g = toGrid(track(on), 'ui_toggle'); stamp(g, knob, on ? 19 : 1, 2); return toRows(g); };
  // Fixed-size source (never cropped): the knob must not sit in a stretch band.
  add('ui_toggle', [f(true), f(false)], {
    nineSlice: { left: 17, right: 17, top: 9, bottom: 9 },
    frames: ['ON (lime track, knob right; label k)', 'OFF (sunken lavender track, knob left; label k)'],
    cornerArtPx: 8, knobDiameterArtPx: 16,
    labelRegionArtPx: [[2, 18], [18, 34]],
    note: 'Centre the ON/OFF label inside labelRegionArtPx[frame] (art-px x range within the 36-px toggle), not the full visual, or the knob covers it.',
  });
}

// Tabs: rounded top, square bottom. Selected = raised cream with a pink underline lip; unselected =
// sunken lilac, 1 art px lower.
{
  const W = 16, H = 14;
  const selected = shade9(W, H, { mask: bodyMask(W, H, corners(ARC[4], 'tl tr')), ink: 'k', fill: 'c', gloss: 'w', lip: 'q', lipRows: 2 });
  const unselected = shade9(W, H, { mask: bodyMask(W, H, { box: [0, 1, W - 1, H - 1], ...corners(ARC[4], 'tl tr') }), ink: 'k', fill: 'j', shade: 'u' });
  add9('ui_tab', [selected, unselected], {
    frames: ['selected (cream, pink underline, label k)', 'unselected (sunken lilac j, 1 art px lower, label k)'], cornerArtPx: 4,
  });
}

// Badge: a true circle at 8x8 (corners only), a capsule when wider. Pink, digit k.
// No gloss: an 8-art-px badge has 6 interior rows and ×3 text needs 21 px of them.
add9('ui_badge', [shade9(12, 12, { mask: bodyMask(12, 12, corners(CIRCLE[8])), ink: 'k', fill: 'q' })], {
  frames: ['badge / NEWS tag (pink q, text k 6.8:1)'], cornerArtPx: 4,
});

// Progress bars: rounded 1-px ends. Track is a deep-grape well; fills carry a w gloss row.
add('ui_bar_track', [['.UU.', 'UUUU', 'UUUU', '.UU.']], {
  nineSlice: { left: 1, right: 1, top: 1, bottom: 1 }, cornerArtPx: 1,
  note: 'Bars >= 3 art px tall. For 2-art-px bars (Evolve button, buff chip) draw flat rows: track U; fill top v/O, bottom G/o.',
});
add('ui_bar_fill', [['.ww.', 'vvvv', 'vvvv', '.GG.'], ['.ww.', 'OOOO', 'OOOO', '.oo.']], {
  nineSlice: { left: 1, right: 1, top: 1, bottom: 1 }, cornerArtPx: 1,
  frames: ['progress: lime v vs track U 8.05:1', 'Golden-Banana buff: amber O vs U 5.72:1'],
  note: 'For 2-art-px bars: row 0 = v (or O), row 1 = G (or o). Never trim.',
});

// Focus ring: rounded double ring, deep pink Q outside (>= 4.8:1 on cream) + hot pink q inside
// (>= 6.8:1 against every control's k outline). Drawn 2 art px outside the control.
add9('ui_focus', [shade9(PW, PH, { mask: panelMask, ink: 'Q', ring: ['q'], fill: 'q', hollowFrom: 3 })], {
  cornerArtPx: 4, note: 'Keyboard focus ring. Transparent centre. Insets stay <= 4 because the ring is created at 32x32 logical (8 art px) before it is sized to a control.',
});

// ---- glyphs (8x8, w with k outline; softened corners) -------------------------------------------
add('ui_lock', [[
  '..kkkk..',
  '.kk..kk.',
  '.k....k.',
  'kkkkkkkk',
  'kwwwwwik',
  'kwwkkwik',
  'kwwwwiik',
  '.kkkkkk.',
]]);
add('ui_sound_on', [[
  '...k..k.',
  '..kwk..k',
  '.kwwk.kk',
  'kwwwk.kk',
  'kwwwk.kk',
  '.kwwk.kk',
  '..kwk..k',
  '...k..k.',
]]);
add('ui_sound_off', [[
  '...k....',
  '..kwk...',
  '.kwwkx.x',
  'kwwwk.x.',
  'kwwwk.x.',
  '.kwwkx.x',
  '..kwk...',
  '...k....',
]]);
add('ui_music_on', [[
  '...kkk..',
  '...kwwk.',
  '...kwkwk',
  '...kwk.k',
  '.kkkwk..',
  'kwwwwk..',
  'kwwwik..',
  '.kkkk...',
]]);
add('ui_music_off', [[
  'x..kkk..',
  '.x.kwwk.',
  '..xkwkwk',
  '...xwk.k',
  '.kkkxk..',
  'kwwwkx..',
  'kwwwik.x',
  '.kkkk...',
]]);
add('ui_gear', [[
  '..k..k..',
  '.kwkkwk.',
  'kwwwwwwk',
  'kwwkkwwk',
  'kwwkkwik',
  'kwwwwiik',
  '.kwkkik.',
  '..k..k..',
]]);
add('ui_close', [[
  '.kk..kk.',
  'kwwkkwwk',
  '.kwwwwk.',
  '..kwwk..',
  '..kwwk..',
  '.kwwwwk.',
  'kwwkkwwk',
  '.kk..kk.',
]]);
add('ui_arrow_up', [[
  '...kk...',
  '..kwwk..',
  '.kwwwwk.',
  'kwwwwwwk',
  '.kkwwkk.',
  '..kwwk..',
  '..kwik..',
  '...kk...',
]]);

// 16x16 overlay glyphs (drawn x4 = 64 px; hit 104x104 per UX)
{ // close: a grape candy button with a chunky white X (w on u 5.44:1)
  const disc = toGrid(shade9(16, 16, { mask: bodyMask(16, 16, corners(CIRCLE[16])), ink: 'k', fill: 'u', gloss: 'j', lip: 'U', lipRows: 2 }), 'close16');
  for (let i = 0; i < 6; i++) for (const [x, y] of [[5 + i, 4 + i], [5 + i, 5 + i], [10 - i, 4 + i], [10 - i, 5 + i]]) disc[y][x] = 'w';
  add('ui_close16', [toRows(disc)]);
}
{ // gear: 6 chunky round-tipped teeth, w with i shade, grape hub
  const g = blank(16, 16);
  const cx = 7.5, cy = 7.5;
  for (let y = 0; y < 16; y++) for (let x = 0; x < 16; x++) {
    const dx = x - cx, dy = y - cy, r = Math.hypot(dx, dy), a = Math.atan2(dy, dx);
    const tooth = Math.cos(6 * (a + Math.PI / 12)) > 0.2;
    const outer = tooth ? 6.7 : 5.1;
    if (r <= outer) g[y][x] = r <= 2.2 ? 'u' : (dx + dy > 3 ? 'i' : 'w');
  }
  add('ui_gear16', [toRows(outline(g, 'k'))]);
}
// FTUE pointer: white cartoon glove, k outline, candy-pink cuff. Frame 0 points UP (rotate
// 90/180/270 for right/down/left). Frame 1 points UP-LEFT (flipX / flipY for other diagonals).
add('ui_pointer', [F([
  '................',
  '......ww........',
  '.....wwws.......',
  '.....wwws.......',
  '.....wwws.......',
  '.....wwwsww.....',
  '..ww.wwwswwws...',
  '..wwswwwwwwwws..',
  '...wwwwwwwwwws..',
  '...wwwwwwwwwws..',
  '....wwwwwwwws...',
  '....qqqqqqqqqq..',
  '....qwqqwqqwqQ..',
  '....QQQQQQQQQQ..',
  '................',
  '................',
], 'ui_pointer/up'), F([
  '................',
  '.ww.............',
  '.wwws...........',
  '..wwws..........',
  '...wwws.........',
  '....wwwsww......',
  '..w..wwwwws.....',
  '..wwswwwwwws....',
  '...wwwwwwwwws...',
  '....wwwwwwwws...',
  '.....wwwwwwws...',
  '......wwwwws.q..',
  '.......qqwwwqq..',
  '........qqwwqQ..',
  '.........QQQQ...',
  '................',
], 'ui_pointer/upleft')], {
  frames: ['points up (rotate for right/down/left)', 'points up-left (flip for other diagonals)'],
  hotspot: [[6, 1], [1, 1]],
  note: 'Outline k plus w fill: k >= 3.43:1 on any sky band, w >= 6.6:1 on sky top; k outline >= 6.8:1 on every v1.1 panel (N7).',
});

// "???" silhouette rows (producers only): outer contour -> grape rim u, everything else -> deep U.
// On the lilac-grey can't-afford row (i) the U mass is 9.81:1 (N6); on the lavender plate 4.9:1.
for (const id of ['intern', 'tree', 'hardhat', 'bureaucrat', 'catapult', 'rocket', 'timechimp', 'moon']) {
  const src = SPRITES['icon_' + id].frames[0];
  const edge = (x, y) => [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => (src[y + dy]?.[x + dx] ?? '.') === '.');
  add('sil_' + id, [src.map((r, y) => [...r].map((c, x) => (c === '.' ? '.' : c === 'k' && edge(x, y) ? 'u' : 'U')).join(''))]);
}

// ---------------------------------------------------------------------------
// UI_THEME — every UI colour role, as { char, hex }. The developer wires all UI colour through
// this map (never through literal chars), so a retune happens here and flows everywhere.
// Sprite refs are { sprite, frame } (or a frames map). Rects are *suggestions* for UX sign-off.
// ---------------------------------------------------------------------------
const C = (ch) => ({ char: ch, hex: PALETTE[ch] });
const PRODUCER_ORDER = ['intern', 'tree', 'hardhat', 'bureaucrat', 'catapult', 'rocket', 'timechimp', 'moon'];
const UI_THEME = {
  letterbox: C('U'),
  // ---- top bar (hud-layout §4 #1-7) ----
  topBar: { sprite: 'ui_topbar', frame: 0, fill: C('q'), lip: C('Q'), ink: C('k') },
  statWindow: {
    sprite: 'ui_chip',
    frames: { normal: 0, frenzy: 1 },
    fill: C('U'), bezel: C('j'), bezelFrenzy: C('O'),
    suggestedRect: [8, 8, 372, 140], // UX-agreed; content box x20-368 y24-136 (insets 12/12/16/12 logical); thumbs icon at y104
  },
  statText: { bank: C('Y'), bankGoldenRoll: C('O'), bps: C('v'), bpsFrenzy: C('O'), thumbs: C('e') },
  juiceGain: C('q'), // flash tint for bank / bps / milestone ticker text: all of them sit on U (5.40:1)
  juiceGainOnLight: C('Q'), // the same flash for text on cream/mint grounds (row names, card text): 4.84 / 4.57:1. Never use q there (2.22:1)
  evolve: {
    ready: { sprite: 'ui_button_evolve', frames: { normal: 0, pressed: 1, hover: 2 } },
    notReady: { sprite: 'ui_button', frame: 2 },
    labelReady: C('w'),
    labelNotReady: C('k'),
    dropShadow: C('Q'), // the enabled state's 4-px drop shadow (hud-layout §6), pink lip tone on the pink bar
    glint: C('w'),
    barTrack: C('U'), barFillTop: C('v'), barFillBottom: C('G'),
    badge: { sprite: 'ui_badge', frame: 0, text: C('k') },
  },
  gear: { sprite: 'ui_gear16', frame: 0 },
  // ---- stage ----
  buffChip: { sprite: 'ui_panel', frame: 0, text: C('k'), barTrack: C('U'), barFillTop: C('O'), barFillBottom: C('o') },
  banner: { sprite: 'ui_banner', frame: 0, text: C('Y') },
  frenzyEdgeGlow: C('O'),
  floater: { fill: C('w'), outline: C('k') },
  floaterCrit: { fill: C('Y'), outline: C('r') },
  callout: { fill: C('w'), outline: C('k') }, // "CATCH IT!" and every other text drawn over the stage
  pointer: { sprite: 'ui_pointer' },
  // ---- ticker (#15) ----
  ticker: {
    sprite: 'ui_ticker', frame: 0, // panel AND both occluders
    bg: C('U'), trim: C('q'), text: C('w'), milestoneText: C('q'), flash: C('w'),
    tag: { sprite: 'ui_badge', frame: 0, fill: C('q'), text: C('k') },
  },
  // ---- shop (#16-22) ----
  shop: { sprite: 'ui_tray', frame: 0, fill: C('e'), emptyText: C('k'), scrollThumb: C('U') },
  tab: { sprite: 'ui_tab', frames: { selected: 0, unselected: 1 }, labelSelected: C('k'), labelUnselected: C('k'), badge: { sprite: 'ui_badge', frame: 0, text: C('k') } },
  buyMode: { sprite: 'ui_button', frames: { normal: 0, pressed: 1, hover: 3 }, label: C('k') },
  row: {
    sprite: 'ui_panel',
    frames: { afford: [0, 2], cantAfford: [1, 3] }, // index by rowIndex % 2 (alternating candy rows)
    fill: [C('c'), C('m')], fillCantAfford: C('i'),
    name: C('k'), line2: C('U'), nameCantAfford: C('k'), line2CantAfford: C('U'),
    affordFlash: C('w'),
  },
  plate: {
    sprite: 'ui_plate',
    suggestedRect: 'row-relative [24, ry+8, 80, 80] behind the 64-px icon at [32, ry+16]',
    frames: { ...Object.fromEntries(PRODUCER_ORDER.map((id, n) => [id, n])), upgradeGlobal: 8, silhouette: 9 },
    upgradeRule: 'effect.producer set -> that producer\'s plate frame; otherwise upgradeGlobal',
  },
  producerAccent: Object.fromEntries(PRODUCER_ORDER.map((id, n) => [id, { ...C(PLATE[n]), plateFrame: n }])),
  pill: { sprite: 'ui_pill', frames: { buy: 0, need: 1, pressed: 2 }, labelBuy: C('k'), labelNeed: C('k') },
  silhouette: { rim: C('u'), fill: C('U'), plateFrame: 9, rowFrame: 1 },
  // ---- overlays (hud-layout §11) ----
  scrim: { ...C('z'), alpha: 0.6 },
  modal: { sprite: 'ui_card', frame: 0, title: C('k'), body: C('k'), groupLabel: C('u'), note: C('U'), divider: C('I'), version: C('U') },
  button: { sprite: 'ui_button', frames: { normal: 0, pressed: 1, disabled: 2, hover: 3 }, label: C('k'), labelDisabled: C('k') },
  danger: { sprite: 'ui_button_danger', frames: { normal: 0, pressed: 1, hover: 2 }, label: C('k') },
  toggle: { sprite: 'ui_toggle', frames: { on: 0, off: 1 }, labelOn: C('k'), labelOff: C('k'), labelRegionArtPx: [[2, 18], [18, 34]] },
  focusRing: { sprite: 'ui_focus', frame: 0, outsetPx: 8 },
  // od-sevev: the kit's 16x16 round ✕ (TA PNG, game/assets/sprites), one ✕ style for every card
  // (review R26; the court card already uses it). `ui_close16` stays in SPRITES for the fork.
  close: { sprite: 'icon_close', frame: 0 },
  offline: { amount: C('k'), amountIcon: 'icon_crescent' },
  evolveTx: { card: C('w'), text: C('k'), reducedMotionCard: C('U'), reducedMotionText: C('w') },
  // ---- title (hud-layout §10): all title text is over the stage -> outline font variant ----
  title: { text: C('w'), outline: C('k') },
};

// ---------------------------------------------------------------------------
// PARTICLES (no outline — they fly over dark foliage and sky)
// ---------------------------------------------------------------------------
add('particle_chunk', [[
  '.hY.',
  'hYYy',
  'YYyy',
  '.yy.',
]]);
add('particle_chip', [[
  'hY',
  'Yy',
]], { note: 'feel-spec tap chip, 2x2 art px, no outline. Same texel density as every other sprite at the stage scale.' });
add('particle_sparkle', [
  ['.w.', 'whw', '.w.'],
  ['w.w', '.h.', 'w.w'],
]);
add('particle_gold', [
  ['.O.', 'OwO', '.o.'],
]);
add('particle_leaf', [[
  '...LG',
  '..LGg',
  '.LGg.',
  'LGg..',
  'g....',
], [
  'gG...',
  'LGg..',
  '.LGg.',
  '..LGg',
  '...g.',
]]);

// ---------------------------------------------------------------------------
// Emit
// ---------------------------------------------------------------------------
function assertAll() {
  for (const [id, s] of Object.entries(SPRITES)) {
    s.frames.forEach((fr, fi) => {
      if (fr.length !== s.h) throw new Error(`${id}[${fi}] has ${fr.length} rows, expected ${s.h}`);
      fr.forEach((row, ri) => {
        if (row.length !== s.w) throw new Error(`${id}[${fi}] row ${ri} length ${row.length} != ${s.w}`);
        for (const c of row) if (!(c in PALETTE)) throw new Error(`${id}[${fi}] row ${ri}: unknown char '${c}'`);
      });
    });
  }
}
assertAll();

const idsOrder = Object.keys(SPRITES);
const metaEntries = idsOrder.filter((id) => SPRITES[id]._meta).map((id) => [id, SPRITES[id]._meta]);

let ts = `// AUTO-GENERATED by art/tools/build-sprites.mjs — edit the authoring script, not this file.
// Monkey Bananas procedural pixel art. PURE DATA: no imports, no Phaser.
//
// PALETTE maps one char to a hex colour; '.' is transparent (skip the pixel).
// SPRITES[id].frames[f] is an array of h strings, each w chars wide.
// Bake each frame to a texture at boot (nearest-neighbour, integer scale only).
// Style rules and scale guidance: art/style-guide.md.
//
// 9-SLICE (v1.1 rounded set): every ui_* piece with SPRITE_META.nineSlice reads its insets from
//   there (left/right/top/bottom, measured by the generator, up to 17 art px for the fixed-size
//   toggle). Rounded corners live entirely inside the insets; the 2-px centre bands are flat colour.
//   SPRITE_META[id].cornerArtPx is the corner radius. Corners never scale. Do not trim.
//   Frame meanings for every multi-frame sprite are in SPRITE_META[id].frames.
// UI_THEME maps every UI colour role to a palette char + hex (style-guide §11).

export const PALETTE: Record<string, string> = {
`;
for (const [k, v] of Object.entries(PALETTE)) ts += `  ${JSON.stringify(k)}: ${JSON.stringify(v)},\n`;
ts += `};\n\n`;
ts += `/** Sky gradient bands, top → bottom, as fractions of the diorama height. Drawn procedurally. */\n`;
ts += `export const SKY_BANDS: { color: string; from: number; to: number }[] = ${JSON.stringify(SKY_BANDS)};\n\n`;
ts += `/**\n * v1.1 bright UI: every UI colour role as { char, hex } plus sprite/frame refs. Wire all UI colour\n * through this map (style-guide §11). Rects marked suggested* await UX sign-off.\n */\n`;
ts += `export const UI_THEME = ${JSON.stringify(UI_THEME, null, 2)} as const;\n\n`;
ts += `/** Per-sprite notes: pivots, tiling axes, 9-slice insets, frame meanings. */\n`;
ts += `export const SPRITE_META: Record<string, Record<string, unknown>> = {\n`;
for (const [id, m] of metaEntries) ts += `  ${id}: ${JSON.stringify(m)},\n`;
ts += `};\n\n`;
ts += `export const SPRITES: Record<string, { w: number; h: number; frames: string[][] }> = {\n`;
for (const id of idsOrder) {
  const s = SPRITES[id];
  ts += `  ${id}: {\n    w: ${s.w},\n    h: ${s.h},\n    frames: [\n`;
  for (const fr of s.frames) {
    ts += `      [\n`;
    for (const row of fr) ts += `        ${JSON.stringify(row)},\n`;
    ts += `      ],\n`;
  }
  ts += `    ],\n  },\n`;
}
ts += `};\n`;
writeFileSync(join(ART, 'sprites.ts'), ts);

// contact sheet (inline data copy so it opens from file://)
// The HUD mock renders real text with the TA's 5x7 font (read-only import; the mock falls back to
// canvas text if the pipeline file is absent).
let FONT_GLYPHS = null;
try { FONT_GLYPHS = (await import(pathToFileURL(join(ART, '..', 'pipeline', 'pixel-font.ts')).href)).FONT_GLYPHS; } catch { FONT_GLYPHS = null; }
const NS = Object.fromEntries(metaEntries.filter(([, m]) => m.nineSlice).map(([id, m]) => [id, m.nineSlice]));
const data = { PALETTE, SKY_BANDS, UI_THEME, NS, FONT: FONT_GLYPHS, SPRITES: Object.fromEntries(idsOrder.map((id) => [id, { w: SPRITES[id].w, h: SPRITES[id].h, frames: SPRITES[id].frames }])) };
const html = `<!doctype html>
<html><head><meta charset="utf-8"><title>Monkey Bananas Contact Sheet</title>
<style>
  :root { --bg:#1b1418; --fg:#fff8ec; --mut:#bdb4c2; }
  body { margin:0; padding:16px; background:var(--bg); color:var(--fg); font:13px/1.4 ui-monospace,Menlo,monospace; }
  h1 { font-size:16px; margin:0 0 8px; } h2 { font-size:13px; color:var(--mut); margin:18px 0 6px; font-weight:normal; text-transform:uppercase; letter-spacing:.08em; }
  .row { display:flex; flex-wrap:wrap; gap:10px; align-items:flex-end; }
  .cell { display:flex; flex-direction:column; align-items:center; gap:3px; }
  .cell span { color:var(--mut); font-size:10px; }
  canvas { image-rendering:pixelated; background: repeating-conic-gradient(#2a2127 0 25%, #221a1f 0 50%) 0 0/16px 16px; }
  .sw { width:48px; height:32px; border:1px solid #000; } .swl { font-size:10px; color:var(--mut); text-align:center; }
  .scenes { display:flex; gap:12px; flex-wrap:wrap; } .scenes canvas { background:none; } #hud canvas { width:360px; height:640px; image-rendering:auto; }
  button { background:#452c3e; color:var(--fg); border:1px solid #6f5f73; padding:4px 8px; font:inherit; cursor:pointer; }
</style></head><body>
<h1>Monkey Bananas — procedural pixel contact sheet (×4)</h1>
<div id="pal" class="row"></div>
<h2>v1.1 HUD mock (720×1280 logical, shown at 50%) — main · squint (greyscale) · deuteranopia · settings modal · control states at use size</h2>
<div class="scenes" id="hud"></div>
<h2>Scene mock (Big Banana ×5, critters ×3) — normal · greyscale (squint) · deuteranopia · protanopia</h2>
<div class="scenes" id="scenes"></div>
<div id="groups"></div>
<script>
const DATA = ${JSON.stringify(data)};
const { PALETTE, SPRITES, SKY_BANDS, UI_THEME, NS, FONT } = DATA;
function draw(ctx, id, f, x, y, s) {
  const sp = SPRITES[id]; const fr = sp.frames[f % sp.frames.length];
  for (let j = 0; j < sp.h; j++) for (let i = 0; i < sp.w; i++) {
    const c = fr[j][i]; if (c === '.') continue;
    ctx.fillStyle = PALETTE[c]; ctx.fillRect(x + i * s, y + j * s, s, s);
  }
}
// palette
const pal = document.getElementById('pal');
for (const [k, v] of Object.entries(PALETTE)) { if (k === '.') continue;
  const d = document.createElement('div'); d.className = 'cell';
  d.innerHTML = '<div class="sw" style="background:' + v + '"></div><div class="swl">' + k + ' ' + v + '</div>'; pal.appendChild(d); }
// groups
const groups = [
  ['Hero', (id) => id === 'magicianStandIn' || id === 'suitcaseStandIn'],
  ['Producer icons', (id) => ['intern','tree','hardhat','bureaucrat','catapult','rocket','timechimp','moon'].some(p => id === 'icon_' + p)],
  ['Upgrade icons', (id) => id.startsWith('icon_') && !['intern','tree','hardhat','bureaucrat','catapult','rocket','timechimp','moon','thumb','banana'].some(p => id === 'icon_' + p)],
  ['Currency', (id) => id === 'icon_thumb' || id === 'icon_crescent'],
  ['Critters (2-frame idle)', (id) => id.startsWith('critter_')],
  ['Environment', (id) => id.startsWith('env_')],
  ['UI', (id) => id.startsWith('ui_')],
  ['Particles', (id) => id.startsWith('particle_')],
];
const root = document.getElementById('groups');
for (const [title, pred] of groups) {
  const h = document.createElement('h2'); h.textContent = title; root.appendChild(h);
  const row = document.createElement('div'); row.className = 'row'; root.appendChild(row);
  for (const id of Object.keys(SPRITES).filter(pred)) {
    const sp = SPRITES[id];
    sp.frames.forEach((_, f) => {
      const S = 4; const c = document.createElement('canvas'); c.width = sp.w * S; c.height = sp.h * S;
      draw(c.getContext('2d'), id, f, 0, 0, S);
      const cell = document.createElement('div'); cell.className = 'cell'; cell.appendChild(c);
      const l = document.createElement('span'); l.textContent = id + (sp.frames.length > 1 ? '[' + f + ']' : ''); cell.appendChild(l); row.appendChild(cell);
    });
  }
}
// scene mock — a 180x200 art-px slice of the 180x320 stage, drawn at 2 logical/art px
function scene(frame) {
  const AW = 180, AH = 200, S = 2; const c = document.createElement('canvas'); c.width = AW * S; c.height = AH * S;
  const x = c.getContext('2d'); x.imageSmoothingEnabled = false;
  const u = S; // 1 art px
  for (const b of SKY_BANDS) { x.fillStyle = b.color; x.fillRect(0, b.from * AH * u, AW * u, (b.to - b.from) * AH * u + 1); }
  x.fillStyle = PALETTE.t; x.fillRect(0, 0.72 * AH * u, AW * u, AH * u);
  draw(x, 'env_cloud', 0, 16 * u, 18 * u, u); draw(x, 'env_cloud', 0, 120 * u, 34 * u, u);
  // back palms
  for (const px of [6, 142]) { for (let k = 0; k < 5; k++) draw(x, 'env_palm_trunk', 0, (px + 8) * u, (92 + k * 16) * u, u); draw(x, 'env_palm_crown', 0, px * u, 80 * u, u); }
  draw(x, 'env_foliage_b', 0, 0, 150 * u, u); draw(x, 'env_foliage_b', 0, 150 * u, 148 * u, u); draw(x, 'env_foliage_a', 0, 30 * u, 152 * u, u); draw(x, 'env_foliage_a', 0, 128 * u, 152 * u, u);
  for (let i = 0; i < AW; i += 16) draw(x, 'env_grass', 0, i * u, 160 * u, u);
  for (let i = 0; i < AW; i += 16) for (let j = 176; j < AH; j += 16) draw(x, 'env_ground', 0, i * u, j * u, u);
  // big banana ×5 art px → render at 5/4 of stage unit; here stage unit=2px so draw at 2.5 → use 2 and 3 alternately? keep integer: 2px per banana px (=×4 logical-ish)
  draw(x, 'magicianStandIn', frame, 66 * u, 70 * u, u * 1);
  const B = 1; // critters at 1 art px here = x4 logical; banana shown at same stage scale
  ['intern','tree','hardhat','bureaucrat','catapult','rocket','timechimp','moon'].forEach((p, i) => draw(x, 'critter_' + p, frame, (8 + i * 21) * u, 146 * u, u));
  draw(x, 'suitcaseStandIn', frame, 140 * u, 60 * u, u);
  return c;
}
function filtered(src, mode) {
  const c = document.createElement('canvas'); c.width = src.width; c.height = src.height; const x = c.getContext('2d'); x.drawImage(src, 0, 0);
  const im = x.getImageData(0, 0, c.width, c.height); const d = im.data;
  const M = { deut: [0.625,0.375,0,0.7,0.3,0,0,0.3,0.7], prot: [0.567,0.433,0,0.558,0.442,0,0,0.242,0.758] };
  for (let i = 0; i < d.length; i += 4) { const r = d[i], g = d[i+1], b = d[i+2];
    if (mode === 'grey') { const L = 0.2126*r + 0.7152*g + 0.0722*b; d[i]=d[i+1]=d[i+2]=L; }
    else { const m = M[mode]; d[i]=m[0]*r+m[1]*g+m[2]*b; d[i+1]=m[3]*r+m[4]*g+m[5]*b; d[i+2]=m[6]*r+m[7]*g+m[8]*b; } }
  x.putImageData(im, 0, 0); return c;
}

// ---------------- v1.1 HUD mock ----------------
function halve(hex) { const n = parseInt(hex.slice(1), 16); const r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255; return 'rgb(' + (r >> 1) + ',' + (g >> 1) + ',' + (b >> 1) + ')'; }
function spr(ctx, id, f, x, y, s, o) {
  o = o || {}; const sp = SPRITES[id]; const fr = sp.frames[f % sp.frames.length];
  for (let j = 0; j < sp.h; j++) for (let i = 0; i < sp.w; i++) {
    const c = fr[j][o.flipX ? sp.w - 1 - i : i]; if (c === '.') continue;
    ctx.fillStyle = o.dim ? halve(PALETTE[c]) : PALETTE[c]; ctx.fillRect(x + i * s, y + j * s, s, s);
  }
}
function nine(ctx, id, f, r, s) {
  s = s || 4; const sp = SPRITES[id], fr = sp.frames[f % sp.frames.length], ns = NS[id];
  const W = r[2] / s, H = r[3] / s;
  const mx = (t) => (t < ns.left ? t : t >= W - ns.right ? sp.w - (W - t) : ns.left);
  const my = (t) => (t < ns.top ? t : t >= H - ns.bottom ? sp.h - (H - t) : ns.top);
  for (let ty = 0; ty < H; ty++) for (let tx = 0; tx < W; tx++) {
    const c = fr[my(ty)][mx(tx)]; if (c === '.') continue;
    ctx.fillStyle = PALETTE[c]; ctx.fillRect(r[0] + tx * s, r[1] + ty * s, s, s);
  }
}
function rect(ctx, r, ch, a) { ctx.globalAlpha = a == null ? 1 : a; ctx.fillStyle = PALETTE[ch] || ch; ctx.fillRect(r[0], r[1], r[2], r[3]); ctx.globalAlpha = 1; }
function glyph(c) { if (!FONT) return null; return FONT[c] || FONT['?']; }
function textW(str, s) { return (6 * str.length - 1) * s; }
function text(ctx, str, x, y, s, fill, ring) {
  str = String(str).toUpperCase();
  if (!FONT) { ctx.fillStyle = PALETTE[fill]; ctx.font = (7 * s) + 'px monospace'; ctx.textBaseline = 'top'; ctx.fillText(str, x, y); return; }
  const pass = (colour, dil) => {
    ctx.fillStyle = PALETTE[colour];
    [...str].forEach((c, n) => { const g = glyph(c); const gx = x + n * 6 * s;
      for (let j = 0; j < 7; j++) for (let i = 0; i < 5; i++) { if (g[j][i] !== '#') continue;
        if (dil) { for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) ctx.fillRect(gx + (i + dx) * s, y + (j + dy) * s, s, s); }
        else ctx.fillRect(gx + i * s, y + j * s, s, s); } });
  };
  if (ring) pass(ring, true);
  pass(fill, false);
}
function ctext(ctx, str, rx, rw, y, s, fill, ring) { text(ctx, str, rx + 4 * Math.floor((rw - textW(String(str), s)) / 2 / 4), y, s, fill, ring); }
const T = UI_THEME, CH = (o) => o.char;
function stage(x) {
  const SY = 160, SH = 504;
  for (const b of SKY_BANDS) rect(x, [0, SY + Math.round(b.from * SH / 4) * 4, 720, Math.round((b.to - b.from) * SH / 4) * 4 + 4], b.color);
  const gy = SY + Math.round(0.72 * SH / 4) * 4;
  spr(x, 'env_cloud', 0, 40, 200, 4); spr(x, 'env_cloud', 0, 470, 250, 4);
  for (const px of [8, 600]) { for (let k = 0; k < 4; k++) spr(x, 'env_palm_trunk', 0, px + 32, 360 + k * 64, 4); spr(x, 'env_palm_crown', 0, px, 312, 4); }
  spr(x, 'env_foliage_b', 0, 0, gy - 40, 4); spr(x, 'env_foliage_a', 0, 600, gy - 36, 4);
  for (let i = 0; i < 720; i += 64) spr(x, 'env_grass', 0, i, gy, 4);
  for (let i = 0; i < 720; i += 64) for (let j = gy + 64; j < 664; j += 64) spr(x, 'env_ground', 0, i, j, 4);
  [['rocket', 112, 168], ['rocket', 40, 168], ['timechimp', 328, 168], ['moon', 544, 168]].forEach(([p, cx, cy]) => spr(x, 'critter_' + p, 0, cx, cy, 4));
  [['tree', 168, 536], ['intern', 328, 536], ['bureaucrat', 408, 536], ['tree', 568, 536]].forEach(([p, cx, cy]) => spr(x, 'critter_' + p, 1, cx, cy, 4));
  [['catapult', 48, 584], ['hardhat', 208, 584], ['intern', 288, 584], ['intern', 368, 584], ['hardhat', 448, 584], ['bureaucrat', 528, 584], ['catapult', 608, 584]].forEach(([p, cx, cy]) => spr(x, 'critter_' + p, 0, cx, cy, 4));
  spr(x, 'magicianStandIn', 0, 240, 291, 5);
  spr(x, 'suitcaseStandIn', 0, 560, 330, 4);
  text(x, '+128', 470, 330, 4, CH(T.floater.fill), CH(T.floater.outline));
  text(x, '+1.2K!', 150, 300, 6, CH(T.floaterCrit.fill), CH(T.floaterCrit.outline));
  spr(x, 'ui_pointer', 1, 460, 470, 4);
  // buff chip + banner
  nine(x, T.buffChip.sprite, T.buffChip.frame, [184, 176, 352, 48]);
  text(x, 'FRENZY ×5 12S', 200, 184, 3, CH(T.buffChip.text));
  rect(x, [200, 212, 320, 8], CH(T.buffChip.barTrack)); rect(x, [200, 212, 200, 4], CH(T.buffChip.barFillTop)); rect(x, [200, 216, 200, 4], CH(T.buffChip.barFillBottom));
  nine(x, T.banner.sprite, 0, [96, 232, 528, 64]);
  ctext(x, 'BANANA FRENZY ×5!', 96, 528, 248, 4, CH(T.banner.text));
}
function topbar(x) {
  nine(x, T.topBar.sprite, 0, [0, 0, 720, 160]);
  nine(x, T.statWindow.sprite, T.statWindow.frames.frenzy, T.statWindow.suggestedRect);
  spr(x, 'icon_crescent', 0, 25, 25, 3);
  text(x, '123,456', 64, 28, 4, CH(T.statText.bank));
  text(x, '24.3K PER SEC ×5', 64, 72, 3, CH(T.statText.bpsFrenzy));
  spr(x, 'icon_thumb', 0, 24, 104, 2); text(x, '12  ×2.2', 64, 112, 3, CH(T.statText.thumbs));
  // Evolve (ready) with its drop shadow
  nine(x, 'ui_button_evolve', 0, [388, 24, 216, 96]); // drop-shadow stand-in: the dev draws a flat Q rect here
  x.globalCompositeOperation = 'source-atop'; rect(x, [388, 24, 216, 96], CH(T.evolve.dropShadow)); x.globalCompositeOperation = 'source-over';
  nine(x, 'ui_button_evolve', 0, [384, 20, 216, 96]);
  spr(x, 'icon_thumb', 0, 408, 32, 2); text(x, 'EVOLVE!', 448, 36, 3, CH(T.evolve.labelReady));
  ctext(x, '+12', 384, 216, 80, 3, CH(T.evolve.labelReady));
  nine(x, 'ui_badge', 0, [564, 20, 32, 32]); ctext(x, '!', 564, 32, 24, 3, CH(T.evolve.badge.text));
  spr(x, 'ui_gear16', 0, 624, 36, 4);
}
function ticker(x) {
  nine(x, 'ui_ticker', 0, [0, 664, 720, 48]);
  text(x, 'TROOP DECLARES 100 BANANAS "A LOT."', 120, 676, 3, CH(T.ticker.text));
  nine(x, 'ui_ticker', 0, [0, 664, 104, 48]); nine(x, 'ui_ticker', 0, [704, 664, 16, 48]);
  nine(x, 'ui_badge', 0, [16, 672, 80, 32]); text(x, 'NEWS', 24, 676, 3, CH(T.ticker.tag.text));
}
function shop(x) {
  nine(x, 'ui_tray', 0, [0, 712, 720, 568]);
  nine(x, 'ui_tab', 0, [16, 728, 248, 80]); text(x, 'PRODUCERS', 60, 756, 3, CH(T.tab.labelSelected));
  nine(x, 'ui_tab', 1, [272, 728, 248, 80]); text(x, 'UPGRADES', 300, 756, 3, CH(T.tab.labelUnselected));
  nine(x, 'ui_badge', 0, [448, 752, 40, 32]); ctext(x, '3', 448, 40, 756, 3, CH(T.tab.badge.text));
  nine(x, 'ui_button', 0, [536, 728, 168, 80]); ctext(x, 'BUY ×10', 536, 168, 756, 3, CH(T.buyMode.label));
  const rows = [
    { id: 'intern', name: 'INTERN MONKEY', l2: 'OWNED 23', afford: true, v: 'BUY ×10', c: '1.24K' },
    { id: 'tree', name: 'BANANA TREE', l2: 'OWNED 11', afford: true, v: 'BUY ×10', c: '15.6K' },
    { id: 'hardhat', name: 'HARD-HAT CREW', l2: 'OWNED 4', afford: false, v: 'NEED', c: '130K' },
    { id: 'bureaucrat', name: '???', l2: '', afford: false, v: 'NEED', c: '1.40M', sil: true },
    { id: 'intern', name: 'PEEK', l2: '', afford: true, v: 'BUY', c: '1' },
  ];
  x.save(); x.beginPath(); x.rect(16, 824, 688, 448); x.clip();
  rows.forEach((r, k) => {
    const ry = 828 + 104 * k, alt = k % 2;
    nine(x, 'ui_panel', r.afford ? T.row.frames.afford[alt] : T.row.frames.cantAfford[alt], [16, ry, 688, 96]);
    nine(x, 'ui_plate', r.sil ? T.plate.frames.silhouette : T.plate.frames[r.id], [24, ry + 8, 80, 80]);
    if (r.sil) spr(x, 'sil_' + r.id, 0, 32, ry + 16, 4); else spr(x, 'icon_' + r.id, 0, 32, ry + 16, 4, { dim: !r.afford });
    text(x, r.name, 112, ry + 24, 3, CH(r.afford ? T.row.name : T.row.nameCantAfford));
    if (r.l2) text(x, r.l2, 112, ry + 52, 3, CH(r.afford ? T.row.line2 : T.row.line2CantAfford));
    nine(x, 'ui_pill', r.afford ? T.pill.frames.buy : T.pill.frames.need, [520, ry + 8, 168, 80]);
    ctext(x, r.v, 520, 168, ry + 24, 3, CH(r.afford ? T.pill.labelBuy : T.pill.labelNeed));
    ctext(x, r.c, 520, 168, ry + 52, 3, CH(r.afford ? T.pill.labelBuy : T.pill.labelNeed));
  });
  x.restore();
  rect(x, [708, 824, 4, 160], CH(T.shop.scrollThumb));
}
function hudMock() {
  const c = document.createElement('canvas'); c.width = 720; c.height = 1280; const x = c.getContext('2d');
  rect(x, [0, 0, 720, 1280], CH(T.letterbox)); stage(x); topbar(x); ticker(x); shop(x); return c;
}
function modalMock() {
  const c = hudMock(); const x = c.getContext('2d');
  rect(x, [0, 0, 720, 1280], CH(T.scrim), T.scrim.alpha);
  nine(x, T.modal.sprite, 0, [48, 192, 624, 880]);
  text(x, 'SETTINGS', 264, 224, 4, CH(T.modal.title));
  spr(x, 'ui_close16', 0, 592, 220, 4);
  const rowsS = [['SOUND', 312], ['SOUND EFFECTS', 380, true, 352], ['MUSIC', 484, false, 456], ['ACCESSIBILITY', 572], ['REDUCED MOTION', 640, false, 612], ['GAME', 728], ['FULLSCREEN', 796, true, 768]];
  rowsS.forEach(([lab, y, on, ty]) => {
    if (on === undefined) { text(x, lab, 80, y, 3, CH(T.modal.groupLabel)); return; }
    text(x, lab, 80, y, 3, CH(T.modal.body));
    nine(x, 'ui_toggle', on ? 0 : 1, [496, ty, 144, 80]);
    const reg = T.toggle.labelRegionArtPx[on ? 0 : 1];
    ctext(x, on ? 'ON' : 'OFF', 496 + reg[0] * 4, (reg[1] - reg[0]) * 4, ty + 28, 3, CH(on ? T.toggle.labelOn : T.toggle.labelOff));
  });
  nine(x, 'ui_focus', 0, [488, 344, 160, 96]);
  text(x, 'RESET SAVE', 80, 900, 3, CH(T.modal.body));
  nine(x, 'ui_button_danger', 0, [496, 872, 144, 80]); ctext(x, 'RESET', 496, 144, 900, 3, CH(T.danger.label));
  text(x, 'KEYS: SPACE = TAP, ESC = MENU', 100, 988, 3, CH(T.modal.note));
  ctext(x, 'MONKEY BANANAS V1.0 - MADE BY BASE67', 48, 624, 1032, 2, CH(T.modal.version));
  return c;
}
function statesMock() {
  const c = document.createElement('canvas'); c.width = 720; c.height = 640; const x = c.getContext('2d');
  nine(x, 'ui_card', 0, [0, 0, 720, 640]);
  const lab = (t, y) => text(x, t, 24, y, 2, CH(T.modal.groupLabel));
  const btn = (id, f, r, l, ch, dy) => { nine(x, id, f, r); ctext(x, l, r[0], r[2], r[1] + Math.floor((r[3] - 21) / 2 / 4) * 4 + (dy || 0), 3, ch); };
  lab('UI_BUTTON 0 DEFAULT / 1 PRESSED / 2 DISABLED / 3 HOVER', 20);
  ['OK', 'OK', 'OK', 'OK'].forEach((l, f) => btn('ui_button', f, [24 + f * 172, 40, 160, 96], l, CH(T.button.label), f === 1 ? 4 : 0));
  lab('UI_PILL 0 BUY / 1 NEED / 2 PRESSED   UI_BUTTON_DANGER 0 / 1 / 2', 152);
  [['BUY', 0], ['NEED', 1], ['BUY', 2]].forEach(([l, f], n) => btn('ui_pill', f, [24 + n * 112, 172, 104, 80], l, CH(T.pill.labelBuy), f === 2 ? 4 : 0));
  [0, 1, 2].forEach((f) => btn('ui_button_danger', f, [364 + f * 116, 172, 108, 80], 'RESET', CH(T.danger.label), f === 1 ? 4 : 0));
  lab('UI_BUTTON_EVOLVE 0 / 1 / 2   UI_TOGGLE 0 ON / 1 OFF', 268);
  [0, 1, 2].forEach((f) => btn('ui_button_evolve', f, [24 + f * 112, 288, 104, 96], 'GO!', CH(T.evolve.labelReady), f === 1 ? 4 : 0));
  [true, false].forEach((on, n) => { const r = [376 + n * 164, 296, 144, 80]; nine(x, 'ui_toggle', on ? 0 : 1, r); const g = T.toggle.labelRegionArtPx[on ? 0 : 1]; ctext(x, on ? 'ON' : 'OFF', r[0] + g[0] * 4, (g[1] - g[0]) * 4, r[1] + 28, 3, CH(T.toggle.labelOn)); });
  lab('UI_TAB 0 / 1 ON THE TRAY - BADGE - BARS - FOCUS RING', 400);
  nine(x, 'ui_tray', 0, [24, 416, 672, 200]);
  nine(x, 'ui_tab', 0, [40, 432, 200, 80]); ctext(x, 'SELECTED', 40, 200, 460, 3, CH(T.tab.labelSelected));
  nine(x, 'ui_tab', 1, [248, 432, 200, 80]); ctext(x, 'OTHER', 248, 200, 460, 3, CH(T.tab.labelUnselected));
  nine(x, 'ui_badge', 0, [464, 456, 32, 32]); ctext(x, '3', 464, 32, 460, 3, CH(T.tab.badge.text));
  nine(x, 'ui_badge', 0, [512, 456, 80, 32]); text(x, 'NEWS', 520, 460, 3, CH(T.ticker.tag.text));
  nine(x, 'ui_bar_track', 0, [40, 536, 300, 16]); nine(x, 'ui_bar_fill', 0, [40, 536, 180, 16]);
  nine(x, 'ui_bar_track', 0, [40, 568, 300, 16]); nine(x, 'ui_bar_fill', 1, [40, 568, 120, 16]);
  nine(x, 'ui_button', 0, [424, 536, 168, 64]); nine(x, 'ui_focus', 0, [416, 528, 184, 80]); ctext(x, 'FOCUS', 424, 168, 556, 3, CH(T.button.label));
  return c;
}
{
  const hd = document.getElementById('hud');
  const m = hudMock(); hd.appendChild(m); hd.appendChild(filtered(m, 'grey')); hd.appendChild(filtered(m, 'deut')); hd.appendChild(modalMock()); const st = statesMock(); st.style.height = '320px'; hd.appendChild(st);
}
const sc = document.getElementById('scenes');
const base = scene(0); sc.appendChild(base); sc.appendChild(filtered(base, 'grey')); sc.appendChild(filtered(base, 'deut')); sc.appendChild(filtered(base, 'prot'));
</script></body></html>`;
writeFileSync(join(ART, 'contact-sheet.html'), html);
console.log(`wrote sprites.ts (${idsOrder.length} sprites) and contact-sheet.html`);
