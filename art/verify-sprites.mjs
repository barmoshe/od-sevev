// Verifies art/sprites.ts: every frame is exactly w×h, every char is in PALETTE,
// every required sprite id exists (from design/content.json), and prints the
// WCAG contrast table the style guide quotes.
//
//   node art/verify-sprites.mjs        (Node ≥ 23.6 strips TS types natively;
//                                        on older Node use: npx tsx art/verify-sprites.mjs)
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
let mod;
try {
  mod = await import(join(here, 'sprites.ts'));
} catch {
  // Fallback for runtimes without type stripping: strip the annotations by regex and eval.
  const src = readFileSync(join(here, 'sprites.ts'), 'utf8')
    .replace(/export const (\w+):[^=]+=/g, 'export const $1 =');
  mod = await import('data:text/javascript,' + encodeURIComponent(src));
}
const { PALETTE, SPRITES, UI_THEME } = mod;
if (!UI_THEME) { console.error('FAIL: sprites.ts does not export UI_THEME'); process.exit(1); }
const content = JSON.parse(readFileSync(join(here, '..', 'design', 'content.json'), 'utf8'));

const errors = [];
const fail = (m) => errors.push(m);

// 1. palette
const colours = Object.entries(PALETTE).filter(([k]) => k !== '.');
if (PALETTE['.'] === undefined) fail("PALETTE is missing '.' (transparent)");
for (const [k, v] of colours) {
  if (k.length !== 1) fail(`palette key '${k}' is not one char`);
  if (!/^#[0-9a-f]{6}$/i.test(v)) fail(`palette '${k}' = ${v} is not #rrggbb`);
}
// v1.1: 24 core + bright-UI colours. Ceiling 40 (single-char keys, one atlas palette).
if (colours.length < 16 || colours.length > 40) fail(`palette has ${colours.length} colours; the ceiling is 40`);
if ('@' in PALETTE) fail("'@' is the pipeline tint-mask char and must not be a palette key");

// 2. dimensions + chars
let frames = 0;
for (const [id, s] of Object.entries(SPRITES)) {
  if (!Number.isInteger(s.w) || !Number.isInteger(s.h)) fail(`${id}: w/h not integers`);
  if (!Array.isArray(s.frames) || s.frames.length === 0) { fail(`${id}: no frames`); continue; }
  s.frames.forEach((fr, fi) => {
    frames++;
    if (fr.length !== s.h) fail(`${id}[${fi}]: ${fr.length} rows, expected ${s.h}`);
    fr.forEach((row, ri) => {
      if (row.length !== s.w) fail(`${id}[${fi}] row ${ri}: length ${row.length}, expected ${s.w}`);
      for (const c of row) if (!(c in PALETTE)) fail(`${id}[${fi}] row ${ri}: char '${c}' not in PALETTE`);
    });
    if (fr.every((row) => /^\.*$/.test(row))) fail(`${id}[${fi}]: frame is empty`);
  });
}

// 3. required ids + size rules
const need = (id, pred, why) => {
  const s = SPRITES[id];
  if (!s) return fail(`missing sprite '${id}'`);
  if (pred && !pred(s)) fail(`${id}: ${why}`);
};
need('magicianStandIn', (s) => s.w === 48 && s.h === 49 && s.frames.length === 5, '48×49 with 5 frames (rest, 0.94, 0.88, 0.84, stretch)');
need('magicianStandIn_halo', (s) => s.frames.length === 1 && s.w >= 36 && s.h >= 48, 'single soft halo frame about 40×56');
need('suitcaseStandIn', (s) => s.w <= 16 && s.h <= 16 && s.frames.length === 4, '≤16×16 with 4 frames (idle, flare, tilt -8, tilt +8)');
// Big Banana: every frame shares the baseline (bottom ink row 48) and its height falls in the
// Animator's quantize band (motion/object-motion.md §1.1) relative to the rest frame.
if (SPRITES.magicianStandIn?.frames.length === 5) {
  const rows = SPRITES.magicianStandIn.frames.map((fr) => {
    const filled = fr.map((r, y) => (/[^.]/.test(r) ? y : -1)).filter((y) => y >= 0);
    return { top: Math.min(...filled), bottom: Math.max(...filled) };
  });
  rows.forEach((r, i) => { if (r.bottom !== 48) fail(`magicianStandIn[${i}] baseline is row ${r.bottom}, expected 48`); });
  const h = rows.map((r) => r.bottom - r.top + 1);
  const ratio = h.map((x) => x / h[0]);
  const bands = [[0.9688, 1.0104], [0.9167, 0.9688], [0.8646, 0.9167], [0, 0.8646], [1.0104, 9]];
  ratio.forEach((q, i) => { if (!(q >= bands[i][0] && q < bands[i][1])) fail(`magicianStandIn[${i}] height ratio ${q.toFixed(3)} outside band [${bands[i]}]`); });
  console.log('magicianStandIn heights (rows):', h.join(' / '), ' ratios:', ratio.map((q) => q.toFixed(3)).join(' / '));
}
need('icon_thumb', (s) => s.w === 16 && s.h === 16, '16×16');
need('icon_crescent', (s) => (s.w === 8 && s.h === 8) || (s.w === 10 && s.h === 10), '8×8 or 10×10');
for (const p of content.producers) {
  need(`icon_${p.id}`, (s) => s.w === 16 && s.h === 16, '16×16');
  need(`critter_${p.id}`, (s) => s.w === 16 && s.h === 16 && s.frames.length === 2, '16×16 with 2 idle frames');
}
for (const u of content.upgrades) need(`icon_${u.id}`, (s) => s.w === 16 && s.h === 16, '16×16');
need('ui_panel', (s) => s.frames.length === 4, '4 frames (row A afford, row A can\'t, row B afford, row B can\'t)');
need('ui_button', (s) => s.frames.length === 4, 'default / pressed / disabled / hover');
need('ui_lock', (s) => s.w === 8 && s.h === 8, '8×8');
need('particle_chunk', (s) => s.w === 4 && s.h === 4, '4×4');
need('particle_sparkle', (s) => s.w === 3 && s.h === 3, '3×3');
need('particle_leaf', (s) => s.w === 5 && s.h === 5, '5×5');
for (const id of ['env_grass', 'env_ground', 'env_palm_trunk']) need(id, (s) => s.w === 16 && s.h === 16, '16×16 tile');
for (const id of ['env_foliage_a', 'env_palm_crown', 'env_cloud']) need(id);

// Golden size rule (feel-spec): ≤ 0.35× the Big Banana's on-screen size at the same scale
const gb = SPRITES.suitcaseStandIn, bb = SPRITES.magicianStandIn;
if (gb && bb && Math.max(gb.w, gb.h) / Math.max(bb.w, bb.h) > 0.35) fail('suitcaseStandIn exceeds 0.35× Big Banana');

// Hue reservation: the Golden Banana never uses Big-Banana yellows and the Big Banana never uses golden amber
const uses = (s, chars) => s.frames.some((fr) => fr.some((r) => [...r].some((c) => chars.includes(c))));
if (gb && uses(gb, ['Y', 'y', 'h'])) fail('suitcaseStandIn uses banana-yellow chars');
if (bb && uses(bb, ['O', 'o'])) fail('magicianStandIn uses golden-amber chars');
if (SPRITES.magicianStandIn_halo && uses(SPRITES.magicianStandIn_halo, ['O', 'o'])) fail('magicianStandIn_halo uses golden-amber chars');

// Tile seams: horizontal tiles must match colour classes at the left/right edge in ≥ 75% of rows
for (const id of ['env_grass', 'env_ground']) {
  const fr = SPRITES[id].frames[0];
  const same = fr.filter((r) => r[0] === r[r.length - 1] || r[0] !== '.').length;
  if (same < fr.length) fail(`${id}: edge columns contain transparency — tile will show gaps`);
}

// 3b. round-2 UI set (ux/hud-layout.md, ux/ftue-flow.md, ux/settings-and-a11y.md)
need('ui_pointer', (s) => s.w === 16 && s.h === 16 && s.frames.length === 2, '16×16, frames up + up-left');
need('ui_gear16', (s) => s.w === 16 && s.h === 16, '16×16');
need('ui_close16', (s) => s.w === 16 && s.h === 16, '16×16');
need('ui_pill', (s) => s.frames.length === 3, 'BUY raised / NEED sunken / pressed');
need('ui_tab', (s) => s.frames.length === 2, 'selected / unselected');
need('ui_toggle', (s) => s.frames.length === 2, 'ON / OFF');
need('ui_button_danger', (s) => s.frames.length === 3, 'default / pressed / hover');
need('ui_bar_track'); need('ui_bar_fill'); need('ui_badge'); need('ui_focus');
// v1.1 bright set
need('ui_topbar'); need('ui_tray'); need('ui_ticker'); need('ui_card'); need('ui_banner');
need('ui_chip', (s) => s.frames.length === 2, 'stat window normal / frenzy');
need('ui_plate', (s) => s.frames.length === content.producers.length + 2, 'one per producer + upgradeGlobal + silhouette');
need('ui_button_evolve', (s) => s.frames.length === 3, 'normal / pressed / hover');
need('ui_toggle', (s) => s.w === 36 && s.h === 20, 'fixed 36×20 with a 16-px knob');
for (const p of content.producers) need(`sil_${p.id}`, (s) => s.w === 16 && s.h === 16 && !uses(s, ['k']), '16×16 silhouette without ink');
// 9-slice rules (v1.1 rounded set).
// The v1.0 rule "borders <= 2 art px" is retired: rounded corners need the arc inside the inset.
// What replaces it is falsifiable against the layout instead of a fixed number:
//  (a) every stretch band is flat along its stretch axis (unchanged);
//  (b) insets fit the SMALLEST rect the layout renders that sprite at (ux/hud-layout.md), so the
//      texture-baker never throws "below the minimum";
//  (c) Animator squish budget (motion/ui-juice.yaml): squishable controls shrink by 2 art px for
//      1-2 frames, so each corner slice must be <= (restSize - 2) / 2 on that axis;
//  (d) no inset exceeds 17 art px (the fixed-size toggle, whose knob lives inside the corner slice).
const MIN_RENDER_ART = { // [w, h] art px, smallest use in ux/hud-layout.md (UI_THEME suggestions for chips/plates)
  ui_panel: [88, 12], ui_topbar: [180, 40], ui_tray: [180, 142], ui_ticker: [4, 12], ui_card: [140, 112],
  ui_banner: [132, 16], ui_chip: [91, 32], ui_plate: [20, 20], ui_button: [42, 20], ui_button_evolve: [54, 24],
  ui_button_danger: [36, 20], ui_pill: [42, 20], ui_toggle: [36, 20], ui_tab: [62, 20], ui_badge: [8, 8],
  ui_focus: [8, 8], ui_bar_track: [2, 2], ui_bar_fill: [2, 2],
};
const SQUISH = { // rest size [w, h] art px of controls the Animator squishes by 2 art px
  ui_pill: [42, 20], ui_tab: [62, 20], ui_toggle: [36, 20], ui_button: [42, 20], ui_button_danger: [36, 20],
  ui_button_evolve: [54, 24], ui_banner: [132, 16], ui_panel: [88, 12],
};
{
  const src = readFileSync(join(here, 'sprites.ts'), 'utf8');
  const metaBlock = src.slice(src.indexOf('export const SPRITE_META'), src.indexOf('export const SPRITES'));
  console.log('\n9-slice insets (L/R/T/B art px, corner radius):');
  for (const m of metaBlock.matchAll(/^\s+(\w+): (\{.*\}),$/gm)) {
    const meta = JSON.parse(m[2]);
    if (!meta.nineSlice) continue;
    const { left, right, top, bottom } = meta.nineSlice;
    const id = m[1], s = SPRITES[id];
    console.log(`  ${id.padEnd(17)} ${left}/${right}/${top}/${bottom}  r${meta.cornerArtPx ?? '?'}  src ${s.w}x${s.h}`);
    if (Math.max(left, right, top, bottom) > 17) fail(`${id}: 9-slice inset > 17 art px`);
    if (left + right >= s.w + 1 || top + bottom >= s.h + 1) fail(`${id}: insets leave no centre in ${s.w}x${s.h}`);
    const mr = MIN_RENDER_ART[id];
    if (!mr) fail(`${id}: no MIN_RENDER_ART entry — add its smallest layout size`);
    else if (left + right > mr[0] || top + bottom > mr[1]) fail(`${id}: insets ${left + right}x${top + bottom} exceed smallest render ${mr[0]}x${mr[1]} art px`);
    const sq = SQUISH[id];
    if (sq && (Math.max(left, right) > (sq[0] - 2) / 2 || Math.max(top, bottom) > (sq[1] - 2) / 2)) fail(`${id}: corner slice exceeds the Animator squish budget for a ${sq[0]}x${sq[1]} control`);
    if (meta.cornerArtPx === undefined) fail(`${id}: SPRITE_META.cornerArtPx missing`);
    s.frames.forEach((fr, fi) => {
      for (let y = 0; y < s.h; y++) { // horizontal bands: cols left..w-right-1 identical per row
        const band = fr[y].slice(left, s.w - right);
        if (new Set(band).size > 1) fail(`${id}[${fi}] row ${y}: stretch band not flat ("${band}")`);
      }
      for (let x = 0; x < s.w; x++) { // vertical bands: rows top..h-bottom-1 identical per column
        const col = fr.slice(top, s.h - bottom).map((r) => r[x]);
        if (new Set(col).size > 1) fail(`${id}[${fi}] col ${x}: stretch band not flat`);
      }
    });
  }
}

// Hue reservation on the UI: banana yellows never appear in a UI sprite (the bank numerals carry
// the yellow); golden amber only in Golden-buff frames (Frenzy stat-window bezel, golden bar fill).
{
  const okY = {}, okO = { ui_chip: [1], ui_bar_fill: [1] };
  for (const [id, s] of Object.entries(SPRITES)) {
    if (!id.startsWith('ui_')) continue;
    s.frames.forEach((fr, fi) => {
      const has = (chars) => fr.some((r) => [...r].some((c) => chars.includes(c)));
      if (has(['Y', 'y', 'h']) && !(okY[id] ?? []).includes(fi)) fail(`${id}[${fi}] uses banana yellow`);
      if (has(['O', 'o']) && !(okO[id] ?? []).includes(fi)) fail(`${id}[${fi}] uses golden amber outside a Golden-buff frame`);
    });
  }
}

// 4. contrast table (WCAG relative luminance)
const lum = (hex) => {
  const c = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255).map((v) => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
};
const ratio = (a, b) => { const [x, y] = [lum(PALETTE[a]), lum(PALETTE[b])].sort((m, n) => n - m); return (x + 0.05) / (y + 0.05); };
const pairs = [
  ['Y', 'D', 'Big Banana fill vs sky top'], ['Y', 'T', 'Big Banana fill vs sky mid'], ['Y', 't', 'Big Banana fill vs canopy haze'],
  ['Y', 'g', 'Big Banana fill vs foliage shade'], ['k', 'T', 'ink outline vs sky mid'], ['k', 't', 'ink outline vs canopy haze'], ['k', 'Y', 'ink vs banana fill'],
  ['w', 'T', 'Golden halo vs sky mid'], ['w', 't', 'Golden halo vs canopy haze'], ['O', 'k', 'Golden fill vs its ink'], ['O', 'T', 'Golden fill vs sky mid (fails alone: halo + ink carry it)'],
  ['c', 'q', 'cream panel vs pink top bar (edge carried by k ink)'], ['v', 'I', 'BUY face vs NEED face (value channel)'], ['v', 'c', 'lime control vs cream row (edge carried by k ink)'],
  ['w', 'k', 'floater white vs its ink'], ['Y', 'r', 'crit floater yellow vs its r outline'], ['Y', 'G', 'Big Banana vs grass (avoid: needs backplate)'],
];
console.log('\ncontrast (WCAG 2.x ratio):');
for (const [a, b, what] of pairs) console.log(`  ${a} ${PALETTE[a]} / ${b} ${PALETTE[b]}  ${ratio(a, b).toFixed(2).padStart(5)}:1  ${what}`);

// v1.1 UX contrast pairs, read from UI_THEME so the verifier follows any retune.
// Text >= 4.5:1 (C1 and C5 target 7:1); non-text >= 3:1. [id, fg, bg, min, what]
const T = UI_THEME, ch = (x) => x.char;
const UX = [
  ['C1', ch(T.statText.bank), ch(T.statWindow.fill), 7.0, 'bank value / stat window (target 7)'],
  ['C1', ch(T.statText.bankGoldenRoll), ch(T.statWindow.fill), 4.5, 'bank during the Golden roll / stat window'],
  ['C2', ch(T.statText.bps), ch(T.statWindow.fill), 4.5, 'bps / stat window'],
  ['C2', ch(T.statText.bpsFrenzy), ch(T.statWindow.fill), 4.5, 'Frenzy bps / stat window'],
  ['C2', ch(T.statText.thumbs), ch(T.statWindow.fill), 4.5, 'thumbs / stat window'],
  ['C3', ch(T.evolve.labelReady), 'u', 4.5, 'Evolve ready label / grape face'],
  ['C3', ch(T.evolve.labelNotReady), 'I', 4.5, 'Evolve not-ready label / sunken lavender well'],
  ...T.row.fill.map((f) => ['C4', ch(T.row.name), ch(f), 4.5, `row name / row fill ${ch(f)}`]),
  ...T.row.fill.map((f) => ['C4', ch(T.row.line2), ch(f), 4.5, `row line 2 / row fill ${ch(f)}`]),
  ['C4', ch(T.row.nameCantAfford), ch(T.row.fillCantAfford), 4.5, "row name / can't-afford row"],
  ['C4', ch(T.row.line2CantAfford), ch(T.row.fillCantAfford), 4.5, "row line 2 / can't-afford row"],
  ['C5', ch(T.pill.labelBuy), 'v', 7.0, 'pill verb+cost / BUY lime (target 7)'],
  ['C5', ch(T.pill.labelNeed), 'I', 7.0, 'pill verb+cost / NEED lavender (target 7)'],
  ['C6', ch(T.tab.labelSelected), 'c', 4.5, 'tab label / selected cream tab'],
  ['C6', ch(T.tab.labelUnselected), 'j', 4.5, 'tab label / unselected lilac tab'],
  ['C6', ch(T.tab.badge.text), 'q', 4.5, 'badge digit / pink badge'],
  ['C7', ch(T.ticker.text), ch(T.ticker.bg), 4.5, 'ticker text / marquee'],
  ['C7', ch(T.ticker.tag.text), ch(T.ticker.tag.fill), 4.5, '"NEWS" / pink tag'],
  ['C7', ch(T.ticker.milestoneText), ch(T.ticker.bg), 4.5, 'milestone ticker text (juiceGain) / marquee'],
  ['C8', ch(T.floater.fill), ch(T.floater.outline), 4.5, 'floater, "CATCH IT!" glyph / its outline'],
  ['C8', ch(T.floaterCrit.fill), ch(T.floaterCrit.outline), 4.5, 'crit floater glyph / its outline'],
  ['C9', ch(T.banner.text), 'U', 4.5, 'banner text / deep-grape banner'],
  ['C9', ch(T.buffChip.text), 'c', 4.5, 'buff chip text / cream chip'],
  ['C10', ch(T.modal.title), 'c', 4.5, 'overlay title/body / cream card'],
  ['C10', ch(T.modal.groupLabel), 'c', 4.5, 'overlay group labels / card'],
  ['C10', ch(T.modal.note), 'c', 4.5, 'overlay note + version / card'],
  ['C10', ch(T.button.label), 'v', 4.5, 'raised button label / lime'],
  ['C10', ch(T.button.labelDisabled), 'I', 4.5, 'disabled button label / lavender well'],
  ['C10', ch(T.toggle.labelOn), 'v', 4.5, 'toggle ON label / lime track'],
  ['C10', ch(T.toggle.labelOff), 'I', 4.5, 'toggle OFF label / lavender track'],
  ['C10', ch(T.danger.label), 'x', 4.5, 'RESET label / coral face'],
  ['C10', ch(T.offline.amount), 'c', 4.5, 'offline amount / card'],
  ['C11', ch(T.evolveTx.text), ch(T.evolveTx.card), 4.5, 'EVOLVE_TX text / white card'],
  ['C11', ch(T.evolveTx.reducedMotionText), ch(T.evolveTx.reducedMotionCard), 4.5, 'EVOLVE_TX text / reduced-motion card'],
  ['C12', ch(T.juiceGain), ch(T.statWindow.fill), 4.5, 'juiceGain flash on bank / bps (stat window)'],
  ['C12', ch(T.shop.emptyText), ch(T.shop.fill), 4.5, '"NO UPGRADES YET" / cyan tray'],
  ['C12', ch(T.juiceGainOnLight), 'c', 4.5, 'juiceGainOnLight flash / cream'],
  ['C12', ch(T.juiceGainOnLight), 'm', 4.5, 'juiceGainOnLight flash / mint row'],
  ['N1', 'k', 'c', 3.0, 'control ink outline / cream panel, row, card'],
  ['N1', 'k', 'm', 3.0, 'control ink outline / mint row'],
  ['N1', 'k', 'i', 3.0, "control ink outline / can't-afford row"],
  ['N1', 'k', ch(T.topBar.fill), 3.0, 'stat window + Evolve ink outline / pink top bar'],
  ['N1', 'k', ch(T.shop.fill), 3.0, 'tab + buy-mode ink outline / cyan tray'],
  ['N2', ch(T.evolve.barFillTop), ch(T.evolve.barTrack), 3.0, 'progress fill / track'],
  ['N2', ch(T.evolve.barFillBottom), ch(T.evolve.barTrack), 3.0, 'progress fill lower row / track'],
  ['N2', ch(T.buffChip.barFillTop), ch(T.buffChip.barTrack), 3.0, 'golden buff fill / track'],
  ['N2', ch(T.evolve.barTrack), 'c', 3.0, 'bar track / cream card'],
  ['N2', ch(T.evolve.barTrack), 'I', 3.0, 'bar track / lavender Evolve well'],
  ['N3', 'Q', 'c', 3.0, 'focus ring outer / cream card'],
  ['N3', 'q', 'k', 3.0, 'focus ring inner / control ink outline'],
  ['N4', 'k', 'T', 3.0, 'Big Banana outline / sky mid (worst band it overlaps)'],
  ['N4', 'k', 't', 3.0, 'Big Banana outline / canopy haze'],
  ['N4', 'k', 'G', 3.0, 'Big Banana outline / grass (bottom 13 px)'],
  ['N4', 'Y', 'T', 3.0, 'Big Banana fill / sky mid'],
  ['N4', 'Y', 't', 3.0, 'Big Banana fill / canopy haze'],
  ['N5', 'w', 'D', 3.0, 'Golden halo / sky top'],
  ['N5', 'w', 'T', 3.0, 'Golden halo / sky mid'],
  ['N5', 'w', 't', 3.0, 'Golden halo / canopy haze'],
  ['N5', 'w', ch(T.ticker.bg), 3.0, 'Golden halo / marquee (it may drift over the ticker)'],
  ['N6', ch(T.silhouette.fill), ch(T.row.fillCantAfford), 3.0, "silhouette mass / can't-afford row"],
  ['N6', ch(T.silhouette.fill), 'I', 3.0, 'silhouette mass / lavender plate'],
  ['N7', 'k', 'T', 3.0, 'pointer outline / sky mid'],
  ['N7', 'w', 'D', 3.0, 'pointer fill / sky top'],
  ['N7', 'k', 'c', 3.0, 'pointer outline / cream panel'],
  ['N8', 'k', ch(T.ticker.trim), 3.0, 'marquee ink / pink trim'],
  ['N8', 'w', 'u', 3.0, 'close X / grape disc'],
];
console.log('\nUX contrast pairs (v1.1 bright UI, from UI_THEME):');
for (const [id, a, b, min, what] of UX) {
  const q = ratio(a, b);
  const ok = q >= min;
  if (!ok) fail(`${id} ${a}/${b} = ${q.toFixed(2)} < ${min} (${what})`);
  console.log(`  ${id.padEnd(4)} ${a}/${b} ${q.toFixed(2).padStart(5)}:1  ${ok ? 'PASS' : 'FAIL'} (min ${min})  ${what}`);
}

if (errors.length) {
  console.error(`\nFAIL — ${errors.length} problem(s):`);
  for (const e of errors) console.error('  - ' + e);
  process.exit(1);
}
console.log(`\nOK — ${Object.keys(SPRITES).length} sprites, ${frames} frames, ${colours.length} palette colours; all frames exact w×h, all chars in PALETTE, all content.json ids present.`);
