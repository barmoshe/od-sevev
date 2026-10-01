// "עוד סבב" content lint (Game Designer paper check, not a test suite; studio invariant I1).
// Reads design/content.json, design/facts.json and design/redlines.json and reports:
//   red-line hits, poll-number hits, src ids missing from the fact sheet, the סבב rule, lowercase
//   Latin, invented quotes of real people in the ticker, length budgets, the ticker's no-break units
//   (≤ 280 px, ux/mobile-first-layout.md §5.2.1), duplicate ids, counts, and the
//   About page's public facts[].aboutHe (required on every launch fact; Hebrew, one sentence, red lines).
// Usage: node design/sim/content-lint.mjs [--strict] [--verbose]   (exit 1 on any error; --strict also fails on warnings)
// The developer's build lint (UX §6.3 item 4, engine O-U3 pixel widths) can import the same JSON files.
import { readFileSync } from 'node:fs';
const rd = f => JSON.parse(readFileSync(new URL('../' + f, import.meta.url)));
const C = rd('content.json'), F = rd('facts.json'), R = rd('redlines.json');
const strict = process.argv.includes('--strict'), verbose = process.argv.includes('--verbose');
const errors = [], warns = [];
const err = (p, m) => errors.push(`${p}: ${m}`), warn = (p, m) => warns.push(`${p}: ${m}`);

const factIds = new Map(F.facts.map(f => [f.id, f]));
const SKIP_KEYS = new Set(['visualHook', 'id', 'src', 'avatar', 'icon', 'music', 'props', 'skyBands', 'producer', 'partner', 'to',
  'firstPair', 'owner', 'ref', 'kind', 'type', 'era', 'eraOnly', 'replaces', 'opener', 'deck', 'tz',
  'requiresUpgrade', 'currencyId', 'when', 'trigger', 'unlock', 'requires', 'ruleLineOwner']);

// Collect every player-facing string with its path and the nearest object (for poll_like / src / reportedSpeech).
const strings = [];
function walk(o, path, holder) {
  if (typeof o === 'string') { strings.push({ path, text: o, holder }); return; }
  if (Array.isArray(o)) {
    // Chat-script tuple [speaker, text, src?, opts?]: index 2 is a src list (data), index 3 options.
    if (typeof o[0] === 'string' && typeof o[1] === 'string' && o.length >= 3 && (Array.isArray(o[2]) || o[2] === null)) {
      const h = { ...holder, src: [...(holder.src || []), ...(o[2] || [])], ...(o[3] && typeof o[3] === 'object' ? o[3] : {}) };
      walk(o[0], `${path}[0]`, h); walk(o[1], `${path}[1]`, h); return;
    }
    o.forEach((v, i) => walk(v, `${path}[${i}]`, holder)); return;
  }
  if (o && typeof o === 'object') {
    const h = { ...holder };
    for (const k of ['poll_like', 'reportedSpeech']) if (k in o) h[k] = o[k];
    if ('pollLike' in o) h.poll_like = o.pollLike;
    if (Array.isArray(o.src)) h.src = [...(holder.src || []), ...o.src];
    const id = o.id ? `${path}.${o.id}` : path;
    for (const [k, v] of Object.entries(o)) {
      if (k.startsWith('_') || SKIP_KEYS.has(k)) continue;
      walk(v, `${id}.${k}`, h);
    }
  }
}
walk(C, '', {});
// Chat script tuples [speaker, text, src?, opts?]: the src array at index 2 is data, not text.
const isSrcTuple = s => /\[\d+\]\[2\]\[\d+\]$/.test(s.path) && factIds.has(s.text);
const game = strings.filter(s => /[֐-׿]/.test(s.text) && !isSrcTuple(s));

// ---------- 1. src ids ----------
(function checkSrc(o, path) {
  if (Array.isArray(o)) {
    o.forEach((v, i) => checkSrc(v, `${path}[${i}]`));
    if (typeof o[0] === 'string' && typeof o[1] === 'string' && Array.isArray(o[2])) o[2].forEach(f => { if (!factIds.has(f)) err(path, `src '${f}' not in facts.json`); });
    return;
  }
  if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) {
    if ((k === 'src' || k.endsWith('Src'))) {
      const list = Array.isArray(v) ? v : (v && typeof v === 'object' ? Object.values(v).flat() : []);
      list.forEach(f => { if (!factIds.has(f)) err(`${path}.${k}`, `src '${f}' not in facts.json`); });
    } else checkSrc(v, `${path}.${o.id || k}`);
  }
})(C, '');
for (const f of F.facts) if (!f.usedIn?.length && !f.notUsed && !f.usedOutsideContent) warn(`facts.${f.id}`, 'fact is not used anywhere');
for (const f of F.facts) if (f.url === null && f.usedIn?.length && !f.notUsed) warn(`facts.${f.id}`, 'URL needed before ship');

// ---------- 2. red lines ----------
const heb = /[֐-׿]/;
const pre = R.match.hebrewPrefixes;
const allowFor = path => R.allow.filter(a => path.includes(`.${a.id}.`) || path.endsWith(`.${a.id}`)).flatMap(a => a.terms);
function hits(text, term) {
  if (!heb.test(term)) return new RegExp(`(^|[^A-Za-z])${term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}([^A-Za-z]|$)`, 'i').test(text);
  const t = term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  // Word boundary = anything but a Hebrew letter: a maqaf, geresh or gershayim is not a letter, so "ב־7 באוקטובר" still hits.
  return new RegExp(`(^|[^\\u05D0-\\u05EA])[${pre}]{0,${R.match.maxPrefixLetters}}${t}(?=$|[^\\u05D0-\\u05EA])`).test(text);
}
// The red lines cover every player-facing string, not only content.json: the UI strings and the
// About page's public fact lines too (Bar, 2026-09-29: no mention of October 7 anywhere).
const U = JSON.parse(readFileSync(new URL('../../ux/ui-strings.json', import.meta.url)));
const uiStrings = [];
(function walkUi(o, path) {
  if (typeof o === 'string') { if (heb.test(o) || /[A-Za-z]/.test(o)) uiStrings.push({ path, text: o }); return; }
  if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) if (!k.startsWith('_')) walkUi(v, `${path}.${k}`);
})(U, '.ui');
const aboutLines = F.facts.filter(f => typeof f.aboutHe === 'string').map(f => ({ path: `.facts.${f.id}.aboutHe`, text: f.aboutHe }));
// October 7 written as a date (7.10, 07.10, 7/10, 7.10.23, any year): a digit may not precede it, so 27.10 (the election) passes.
const oct7Date = /(^|[^\d])0?7\s*[./]\s*10(?![\d])/;
for (const s of [...game, ...uiStrings, ...aboutLines]) {
  const allowed = allowFor(s.path);
  for (const cat of R.categories) for (const term of cat.terms)
    if (!allowed.includes(term) && hits(s.text, term)) err(s.path, `red line [${cat.id}] '${term}' in: ${s.text}`);
  if (oct7Date.test(s.text)) err(s.path, `red line [oct7-hostages] the date 7.10 in: ${s.text}`);
  if (s.holder) for (const term of R.reviewTerms.terms) if (hits(s.text, term)) warn(s.path, `review term '${term}' (group-as-punchline check): ${s.text}`);
}

// ---------- 3. poll-number rule (UX §6.3.4) ----------
const pollKw = ['מנדט', 'מנדטים', 'סקר', 'סקרים', 'מוביל', 'מובילה', 'אחוז החסימה', 'החסימה'];
// "רוב" (a majority) with a number reads as a seat forecast ("רוב של 64"). It is matched as a whole
// word after up to two prefix letters (רוב, הרוב, לרוב, ברוב, ורוב), never as a substring: the
// letters hide inside ordinary words (קרוב, סירוב, סירובים: "1,000 סירובים" is Liberman's tap count).
// The Knesset's own numbers are rules, not polls: 61 (the majority) and 120 (its size) may stand
// next to it ("צריך רוב של 61").
const pollStems = ['רוב'];
const KNESSET_RULE_NUMBERS = new Set(['61', '120']);
// (No כ prefix here: כרוב is a cabbage.)
const stemOf = w => w.replace(/[^֐-׿]/g, '').replace(/^[והבלמש]{0,2}(?=רוב$)/, '');
const pollHit = (words, i) => {
  const w = words[i];
  if (pollKw.some(k => w.replace(/[^֐-׿]/g, '').replace(new RegExp(`^[${pre}]{0,2}`), '') === k || w.includes(k)))
    return /\d/.test(words.slice(Math.max(0, i - 3), i + 4).join(' '));
  if (pollStems.includes(stemOf(w))) {
    const nums = words.slice(Math.max(0, i - 3), i + 4).join(' ').match(/\d[\d,.]*/g) || [];
    return nums.some(n => !KNESSET_RULE_NUMBERS.has(n.replace(/[.,]+$/, '')));
  }
  return false;
};
for (const s of game) {
  if (s.holder.poll_like === true) continue;
  const words = s.text.split(/\s+/);
  words.forEach((w, i) => {
    if (pollHit(words, i)) err(s.path, `poll-number rule: digit near '${w}' without poll_like:true: ${s.text}`);
  });
}

// ---------- 4. סבב rule ----------
const military = R.categories.filter(c => c.id === 'military' || c.id === 'war-places-and-foes').flatMap(c => c.terms);
for (const s of game) {
  const t = s.text;
  let m; const re = /(^|[^֐-׿])([והבלמש]{0,2})(סבב|סבבי|הסבב)(?=$|[^֐-׿])/g;
  while ((m = re.exec(t))) {
    const after = t.slice(m.index + m[0].length).trimStart();
    const before = t.slice(0, m.index + m[1].length);
    const titlePhrase = /עוד\s*$/.test(before);
    if (!/^(ה)?בחירות/.test(after) && !titlePhrase) err(s.path, `'סבב' without 'בחירות': ${t}`);
  }
  if (/סבב/.test(t) && military.some(term => hits(t, term))) err(s.path, `'סבב' next to a military term: ${t}`);
}

// ---------- 4b. About page: facts[].aboutHe (public; ux/rtl-map.md §9, review R2) ----------
// Every launch fact (notUsed false) needs one public Hebrew sentence; the renderer prints it and never `text`.
for (const f of F.facts) {
  const p = `.facts.${f.id}.aboutHe`;
  if (typeof f.notUsed !== 'boolean') { err(`facts.${f.id}`, 'notUsed must be a boolean (the reason goes in notUsedWhy)'); continue; }
  // A fact that ships with a pending feature (launchWith, e.g. the leader select) is checked as if it were live,
  // so flipping notUsed to false on ship day can't surface a bad About line.
  if (f.notUsed && !f.launchWith) continue;
  const a = f.aboutHe;
  if (typeof a !== 'string' || !a.trim()) { err(`facts.${f.id}`, 'launch fact without aboutHe (the About page skips it)'); continue; }
  const letters = [...a].filter(ch => /[A-Za-z֐-׿]/.test(ch));
  if (letters.filter(ch => /[֐-׿]/.test(ch)).length < letters.length * 0.9 || !heb.test(a)) err(p, `not Hebrew: ${a}`);
  if (/[A-Za-z]/.test(a)) err(p, `Latin letters (English or a production note) on the public page: ${a}`);
  if (/(^|[^֐-׿])[והבלמש]?(המשחק|משחק|בהשקה|השקה|לא בשימוש|ספסל|לאימות|טיוטה)(?=$|[^֐-׿])/.test(a)) err(p, `production note: ${a}`);
  if (/[.!?]\s+\S/.test(a)) err(p, `more than one sentence: ${a}`);
  if (!/[.!?]["״]?$/.test(a)) warn(p, 'does not end with a full stop');
  if ([...a].length > 240) warn(p, `${[...a].length} chars > 240 (one short sentence)`);
  if (f.heStatus === 'unverified' && /["“”„״](?![א-ת])/.test(a.replace(/[א-ת]״[א-ת]/g, ''))) err(p, `quote marks, but the Hebrew wording is unverified (heStatus); use reported speech: ${a}`);
  const allowed = allowFor(p);
  for (const cat of R.categories) for (const term of cat.terms)
    if (!allowed.includes(term) && hits(a, term)) err(p, `red line [${cat.id}] '${term}' on the public page: ${a}`);
  for (const term of R.reviewTerms.terms) if (hits(a, term)) warn(p, `review term '${term}': ${a}`);
  const words = a.split(/\s+/);
  words.forEach((w, i) => {
    if (pollHit(words, i)) err(p, `poll-number rule: digit near '${w}' (the About page is public during the blackout): ${a}`);
  });
}

// ---------- 5. glyph coverage (Sevev 9 has no emoji; TA objection) ----------
const okChars = new Set([...R.glyphs.fontNonAscii, ...R.glyphs.approvedPictograms, '\n']);
const pictUsed = new Set();
(function cover(o, path) {
  if (typeof o === 'string') { for (const ch of o) { const cp = ch.codePointAt(0);
      if ((cp >= 0x20 && cp <= 0x7e) || (cp >= 0x05d0 && cp <= 0x05ea)) continue;
      if (R.glyphs.approvedPictograms.includes(ch)) { pictUsed.add(ch); continue; }
      if (!okChars.has(ch)) err(path, `no glyph for U+${cp.toString(16).toUpperCase().padStart(4, '0')} '${ch}' in: ${o}`); } return; }
  if (Array.isArray(o)) return o.forEach((v, i) => cover(v, `${path}[${i}]`));
  if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) if (!k.startsWith('_')) cover(v, `${path}.${k}`);
})(C, '');

// ---------- 6. invented quotes of real people in ticker lines ----------
const realNames = ['לפיד', 'בנט', 'גנץ', 'ליברמן', 'אייזנקוט', 'גולן', 'עבאס', 'בן גביר', 'סמוטריץ׳', 'דרעי', 'גולדקנופף', 'גפני', 'לוין',
  'רגב', 'גוטליב', 'אמסלם', 'קרעי', 'דיסטל', 'טראמפ', 'הרצוג', 'נתניהו', 'ביבי', 'אילוז', 'אלמוג כהן', 'מרדכי דוד',
  'לזימי', 'קריב', 'טרופר', 'טיבי'];
const tickerPaths = s => /^\.(headlines|ambientHeadlinesV2)|\.ticker$|tickerStart$|\.onPaidTicker$/.test(s.path);
for (const s of game.filter(tickerPaths)) {
  if (!/"/.test(s.text)) continue;
  if (!realNames.some(n => s.text.includes(n))) continue;
  const q = (s.holder.src || []).some(f => factIds.get(f)?.label === 'Q');
  if (!q && !s.holder.reportedSpeech) err(s.path, `quote marks + real name without a [Q] src: ${s.text}`);
}

// ---------- 6b. the reported-speech rule on Dubi's story cards (manual test 2026-09-30, B15) ----------
// Every leader's post-election flash (content.story and leaders[].kit.story): invented quotes of real
// people are forbidden. A quote is allowed only in the narrator's mouth ("דובי: \"...\"", a fictional
// parrot parroting), or with a [Q] src / reportedSpeech on the holder. Reported speech without quote
// marks ("בלשכה מסרו ש...", "לפי הפרסומים") is fine. A real name followed by a speech verb and a colon
// ("X ענה: ...", "X: ...") is an invented line in that person's mouth, quote marks or not.
const narrator = C.narrator?.name || 'דובי';
const speechVerb = '(?:\\s+(?:אמר|אמרה|ענה|ענתה|הודיע|הודיעה|הגיב|הגיבה|הבטיח|הבטיחה|מסר|מסרה|טען|טענה|צעק|צעקה|הוסיף|הוסיפה|השיב|השיבה))?';
const storyLines = game.filter(s => /\.story\.beats\[/.test(s.path));
let storyQuoted = 0;
for (const s of storyLines) {
  const q = (s.holder.src || []).some(f => factIds.get(f)?.label === 'Q') || s.holder.reportedSpeech;
  const quoted = /["“”„]/.test(s.text.replace(/[א-ת]״[א-ת]/g, ''));
  if (quoted) {
    storyQuoted++;
    if (!new RegExp(`^${narrator}:\\s*["“„]`).test(s.text) && !q) err(s.path, `story: a quote outside the narrator's mouth (use reported speech, e.g. "בלשכה מסרו ש..."): ${s.text}`);
  }
  for (const n of realNames) if (new RegExp(`(^|[^\\u05D0-\\u05EA])${n}${speechVerb}\\s*:`).test(s.text)) err(s.path, `story: an invented line in ${n}'s mouth (reported speech only): ${s.text}`);
}

// ---------- 7. length budgets ----------
const over45 = [];
const len = t => [...t.replace(/\{[^}]*\}/g, '00')].length;
for (const s of game) {
  const L = len(s.text);
  if (tickerPaths(s)) { if (L > 60) err(s.path, `ticker ${L} > 60: ${s.text}`); else if (L > 45 && !s.path.includes('cal01')) over45.push(s.path); }
  if (/\.(flavor|levelUp)$/.test(s.path) && L > 60) err(s.path, `flavour ${L} > 60: ${s.text}`);
  if (/\.story\.beats/.test(s.path) && L > 50) warn(s.path, `story line ${L} > 50`);
}
// ---------- 7b. ticker no-break units fit the narrowest clip (ux/mobile-first-layout.md §5.2.1, ask G2) ----------
// The pager never splits a strong glue unit: G1 the ₪ with what it measures, G2 closing punctuation
// with the word before it, G3 opening punctuation with the word after it. G4 (a number with its
// magnitude word, "850.6 מיליארד") is weak: the pager may break there, so it is not one unit.
// Every strong unit must fit 280 px (the narrowest ticker clip) at ×4 in sevev9 (its xadvance).
const FONT_ADV = new Map([...readFileSync(new URL('../../game/assets/fonts/sevev9.fnt', import.meta.url), 'utf8')
  .matchAll(/^char id=(\d+) .*?xadvance=(-?\d+)/gm)].map(m => [Number(m[1]), Number(m[2])]));
const pxWidth = t => [...t].reduce((a, ch) => a + (FONT_ADV.get(ch.codePointAt(0)) ?? FONT_ADV.get(32)), 0) * 4;
const TICKER_CLIP_MIN = 280;
const CLOSERS = /^[.,:;!?…)\]״"׳']+$/, OPENERS = /^[(\[„"״]$/;
function glueUnits(text) {
  const toks = text.replace(/\{[^{}]*(\{[^{}]*\}[^{}]*)*\}/g, '00').split(' ').filter(Boolean);
  const units = [];
  let cur = null, openNext = false;
  for (let i = 0; i < toks.length; i++) {
    const t = toks[i], prev = toks[i - 1] || '';
    const glue = cur !== null && (openNext || t.startsWith('₪') || CLOSERS.test(t)
      || (prev === '₪' && /^[\d⁦-⁩]/.test(t)));
    if (glue) cur += ' ' + t; else { if (cur !== null) units.push(cur); cur = t; }
    openNext = OPENERS.test(t);
  }
  if (cur !== null) units.push(cur);
  return units;
}
let tickerUnits = 0, widestUnit = ['', 0];
for (const s of game.filter(tickerPaths)) for (const u of glueUnits(s.text)) {
  tickerUnits++;
  const w = pxWidth(u);
  if (w > widestUnit[1]) widestUnit = [u, w];
  if (w > TICKER_CLIP_MIN) err(s.path, `ticker unit "${u}" is ${w} px at ×4 > the ${TICKER_CLIP_MIN} clip (§5.2.1): reword, or split it at a weak joint`);
}

for (const p of C.perks.list) {
  const v = Math.max(...p.levels.map(Number));
  const d = p.desc.replace('{v}', String(v));
  if ([...d].length > 18) err(`perks.${p.id}`, `desc ${[...d].length} > 18: ${d}`);
}

// ---------- 8. unique ids ----------
const ids = new Map();
const ambientAll = [...C.ambientHeadlinesV2.list, ...(C.ambientHeadlinesV2.listPolitics || [])];
const idLists = { headlines: C.headlines, ambient: ambientAll, producers: C.producers, upgrades: C.upgrades,
  trophies: C.achievements.list, perks: C.perks.list, partners: C.partners, events: C.events };
const tickerIds = new Set();
for (const [name, list] of Object.entries(idLists)) for (const o of list) {
  const key = `${name}:${o.id}`;
  if (ids.has(key)) err(key, 'duplicate id'); ids.set(key, 1);
  if (name === 'headlines' || name === 'ambient') { if (tickerIds.has(o.id)) err(o.id, 'duplicate ticker id'); tickerIds.add(o.id); }
}
// poll_like present on every ticker, story and card line
for (const o of [...C.headlines, ...ambientAll]) if (typeof o.poll_like !== 'boolean') err(o.id, 'poll_like missing');
for (const o of [...C.events, ...C.partners]) if (o.pollLike !== undefined && typeof o.pollLike !== 'boolean') err(o.id, 'pollLike must be boolean');
// cross refs
const producerIds = new Set(C.producers.map(p => p.id));
for (const s of C.upgrades) if (s.followUp?.ticker && !tickerIds.has(s.followUp.ticker)) err(`upgrades.${s.id}`, `followUp ticker ${s.followUp.ticker} missing`);
for (const w of C.calendar.windows) for (const l of w.lines) if (!tickerIds.has(l)) err(`calendar.${w.id}`, `line ${l} missing`);
// engine-safety checks (the fork engine reads these keys directly)
for (const u of C.upgrades) if (typeof u.cost !== 'number') err(`upgrades.${u.id}`, 'cost missing (Economy reads u["cost"])');
for (const k of ['multPerThumb', 'minPendingFloor', 'minPendingRatioOfOwned', 'showEvolveButtonAtAllTimeBananas', 'divisor', 'epsilon', 'speciesTitles'])
  if (!(k in C.prestige)) err('prestige', `${k} missing (the fork engine reads it directly)`);
const storyKeys = new Set(['era', 'owned', 'frenzy', 'tapFrenzy', 'hour', 'evolutionsAtLeast', 'perk', 'trophiesAtLeast', 'allTimeAtLeast', 'goldenAtLeast']);
for (const o of C.ambientHeadlinesV2.list) for (const k of Object.keys(o.when || {})) if (!storyKeys.has(k)) err(o.id, `when key ${k} is not Story's; move the line to listPolitics`);
// politics contract v1 (binding, STATUS.md): an unknown key or type fails Politics.validate()
const condKeys = new Set(['era', 'evolutionsAtLeast', 'evolutionsBelow', 'runBananasAtLeast', 'allTimeAtLeast', 'ownedAtLeast', 'sourcesOwnedAtLeast', 'shadyOwnedAtLeast',
  'seatsAtLeast', 'seatsBelow', 'membersAtLeast', 'partnerMember', 'partnerNotMember', 'suspicionAtLeast', 'suspicionBelow', 'courtDaysAtLeast', 'critsLifetimeAtLeast',
  'goldenCaughtLifetimeAtLeast', 'playSecAtLeast', 'runSecAtLeast', 'partnersInAtLeast', 'weekday', 'hour', 'mode', 'pendingEngine']);
const eventEffects = new Set(['none', 'blockade', 'screenBlock', 'suspicion', 'noCrit', 'brawl', 'leak', 'interview', 'pardonDesk', 'seatDrain', 'roulette', 'kaia', 'drumline', 'loseRandomPartner', 'pledge', 'mediation']);
const econEffects = new Set(['tapMult', 'tapPctOfBps', 'critChance', 'goldenIntervalMult', 'goldenLifeMult', 'globalMult', 'producerMult', 'suspicionGainMult', 'baseMult', 'bpsMult',
  'tapAdd', 'offlineMult', 'basePctThisRound', 'suspicionFreeze', 'wipeSourceSuspicion',
  // spin effects in game/scripts/sim/spins.gd (Spins.TYPES)
  'tapBuff', 'idleToTap', 'karhiLine', 'flightIncome', 'basePerOppositionCard']);
for (const e of C.events) {
  for (const k of Object.keys(e.when || {})) if (!condKeys.has(k)) err(`events.${e.id}`, `when key ${k} unknown to Conditions`);
  if (!eventEffects.has(e.effect?.type)) err(`events.${e.id}`, `effect ${e.effect?.type} unknown to Events.EFFECTS`);
  if (e.flag && !(e.flag in C.flags)) err(`events.${e.id}`, `flag ${e.flag} not declared in flags`);
  for (const pr of e.effect?.pairs || []) for (const x of pr) if (!C.partners.some(p => p.id === x)) err(`events.${e.id}`, `unknown partner ${x}`);
  // Mordechai David per leader (effect.byLeader, Events.visit_mode): leader ids, block | none | tapBuff
  for (const [lid, ov] of Object.entries(e.effect?.byLeader || {})) {
    if (!(C.leaders || []).some(L => L.id === lid)) err(`events.${e.id}.effect.byLeader`, `unknown leader ${lid}`);
    if (!['block', 'none', 'tapBuff'].includes(ov?.type)) err(`events.${e.id}.effect.byLeader.${lid}`, `type must be block | none | tapBuff, got ${ov?.type}`);
    if (ov?.type === 'tapBuff' && !(Number(ov.mult) > 1)) err(`events.${e.id}.effect.byLeader.${lid}`, `tapBuff needs mult > 1`);
  }
}
for (const p of C.partners) {
  for (const k of Object.keys(p.unlock || {})) if (!condKeys.has(k)) err(`partners.${p.id}`, `unlock key ${k} unknown to Conditions`);
  for (const k of Object.keys(p.lines || {})) if (!['demand', 'threat', 'thanks', 'return', 'status', 'after'].includes(k)) err(`partners.${p.id}`, `lines.${k} is not a contract line`);
  for (const e of p.effects || []) { if (!econEffects.has(e.type)) err(`partners.${p.id}`, `effect ${e.type} unknown`); if (e.producer && !C.producers.some(q => q.id === e.producer)) err(`partners.${p.id}`, `unknown producer ${e.producer}`); }
  for (const x of p.excludes || []) if (!C.partners.some(q => q.id === x)) err(`partners.${p.id}`, `excludes unknown ${x}`);
  if (p.transfer && !C.partners.some(q => q.id === p.transfer.to)) err(`partners.${p.id}`, `transfer.to unknown`);
  if (!['m', 'f'].includes(p.g)) err(`partners.${p.id}`, 'g must be m or f');
}
if (!C.partners.some(p => p.id === C.coalition.firstPartner)) err('coalition.firstPartner', 'unknown partner');
for (const id of Object.keys(C.court.sources)) if (!C.producers.some(p => p.id === id)) err('court.sources', `unknown producer ${id}`);
for (const p of C.producers) if (!!p.shady !== (p.id in C.court.sources)) err(`producers.${p.id}`, 'shady flag disagrees with court.sources');
for (const u of C.upgrades) for (const k of Object.keys(u.unlock || {})) if (!condKeys.has(k)) err(`upgrades.${u.id}`, `unlock key ${k} unknown (Politics.validate fails)`);
const held = u => u.unlock?.pendingEngine === true || u.unlock?.evolutionsBelow === 0;
for (const u of C.upgrades) if (!held(u) && !econEffects.has(u.effect?.type)) err(`upgrades.${u.id}`, `effect ${u.effect?.type} not implemented; hold it with unlock.pendingEngine: true + _pendingEngine`);
for (const u of C.upgrades) if (!['once', 'consumable', 'line', undefined].includes(u.kind)) err(`upgrades.${u.id}`, `kind ${u.kind} unknown (once | consumable | line)`);
const eraIds = new Set(C.eras.list.map(e => e.id));
for (const o of ambientAll) if (o.when?.era && ![o.when.era].flat().every(e => eraIds.has(e))) err(o.id, `unknown era ${o.when.era}`);
for (const o of C.golden.outcomes) if (!['instant', 'bpsFrenzy', 'tapFrenzy'].includes(o.type)) err(`golden.${o.id}`, `type ${o.type} unknown`);
for (const o of ambientAll) if (o.when?.owned && !producerIds.has(o.when.owned.producer)) err(o.id, 'unknown producer');
const partnerIds = new Set(C.partners.map(p => p.id));
for (const o of ambientAll) for (const k of ['partnerMember', 'partnerNotMember']) if (o.when?.[k]) [o.when[k]].flat().forEach(id => { if (!partnerIds.has(id)) err(o.id, `unknown partner ${id}`); });
const w = C.golden.outcomes.filter(o => !o.era).reduce((a, o) => a + o.weight, 0);
if (Math.abs(w - 1) > 1e-9) err('golden.outcomes', `weights outside Washington sum to ${w}, not 1`);

// ---------- 9. leader select (design/leader-select-spec.md; pending engine, additive) ----------
// Every leader's kit is complete and buildable, the references resolve, lineups keep the round's seat
// capacity, and the per-leader ticker lines follow the ticker rules (length, quotes, poll_like, unique ids).
const leaderReport = [];
if (C.leaderSelect || C.leaders) {
  const LS = C.leaderSelect || {}, LEADERS = C.leaders || [];
  const lp = id => `leaders.${id}`;
  let SPR = null;
  try { SPR = rd('../game/assets/sprites/sprites.json'); } catch { warn('leaders', 'game/assets/sprites/sprites.json not readable: art checks skipped'); }
  const charOf = slug => SPR && (SPR.chars?.[slug] || SPR.chars?.[SPR.aliases?.[slug]]);
  const get = (o, path) => path.split('.').reduce((a, k) => (a == null ? a : a[k]), o);
  const hebStr = v => typeof v === 'string' && heb.test(v);
  const leaderIds = new Set();
  for (const L of LEADERS) { if (leaderIds.has(L.id)) err(lp(L.id), 'duplicate leader id'); leaderIds.add(L.id); }
  for (const id of LS.roster || []) if (!leaderIds.has(id)) err('leaderSelect.roster', `no leaders[] entry for ${id}`);
  for (const id of LS.contentReady || []) if (!(LS.roster || []).includes(id)) err('leaderSelect.contentReady', `${id} is not in the roster`);
  if (LS.defaultLeader && !leaderIds.has(LS.defaultLeader)) err('leaderSelect.defaultLeader', `unknown ${LS.defaultLeader}`);
  // shared maps point at shipped content
  const upIds = new Set(C.upgrades.map(u => u.id));
  const slotsSpin = Object.entries(LS.spinSlots || {}).filter(([k]) => /^[A-Z]$/.test(k));
  for (const [k, v] of slotsSpin) if (!upIds.has(v)) err(`leaderSelect.spinSlots.${k}`, `unknown upgrade ${v}`);
  const skinSlots = slotsSpin.map(([k]) => k).filter(k => !(LS.spinSlots.sharedAsIs || []).includes(k));
  for (const [t, pid] of Object.entries(LS.sourceTiers?.tiers || {})) if (!producerIds.has(pid)) err(`leaderSelect.sourceTiers.${t}`, `unknown producer ${pid}`);
  for (const pid of LS.sourceTiers?.shared || []) if (!producerIds.has(pid)) err('leaderSelect.sourceTiers.shared', `unknown producer ${pid}`);
  const B = LS.bibiOnly || {};
  const hlIds = new Set(C.headlines.map(h => h.id)), amIds = new Set(C.ambientHeadlinesV2.list.map(h => h.id)),
    apIds = new Set((C.ambientHeadlinesV2.listPolitics || []).map(h => h.id)), evIds = new Set(C.events.map(e => e.id)),
    trIds = new Set(C.achievements.list.map(a => a.id)), goIds = new Set(C.golden.outcomes.map(o => o.id));
  for (const [key, set] of [['headlines', hlIds], ['ambient', amIds], ['ambientPolitics', apIds], ['upgrades', upIds], ['events', evIds], ['trophies', trIds], ['goldenOutcomes', goIds]])
    for (const id of B[key] || []) if (!set.has(id)) err(`leaderSelect.bibiOnly.${key}`, `unknown id ${id}`);
  for (const id of Object.keys(B.upgradesPartnerScoped || {})) if (!upIds.has(id)) err('leaderSelect.bibiOnly.upgradesPartnerScoped', `unknown upgrade ${id}`);
  // cast: shipped partners + new profiles; cards: shipped events + new card profiles
  const profiles = new Map([...C.partners.map(p => [p.id, p]), ...(LS.partnerProfiles || []).map(p => [p.id, p])]);
  for (const p of LS.partnerProfiles || []) {
    if (C.partners.some(q => q.id === p.id)) err(`leaderSelect.partnerProfiles.${p.id}`, 'id collides with a shipped partner');
    if (!['m', 'f'].includes(p.g)) err(`leaderSelect.partnerProfiles.${p.id}`, 'g must be m or f');
    for (const k of ['demand', 'threat', 'thanks', 'return']) if (!hebStr(p.lines?.[k])) err(`leaderSelect.partnerProfiles.${p.id}`, `lines.${k} missing`);
    if (p.linesVariants?.demand && p.linesVariants.demand[0] !== p.lines.demand) err(`leaderSelect.partnerProfiles.${p.id}`, 'linesVariants.demand[0] must equal lines.demand (C1 plays variant 0)');
    for (const x of p.excludes || []) if (!profiles.has(x)) err(`leaderSelect.partnerProfiles.${p.id}`, `excludes unknown ${x}`);
    for (const e of p.effects || []) if (!econEffects.has(e.type)) err(`leaderSelect.partnerProfiles.${p.id}`, `effect ${e.type} unknown`);
    if (SPR && !charOf(p.art)) err(`leaderSelect.partnerProfiles.${p.id}`, `art ${p.art} is not in sprites.json chars`);
  }
  const cards = new Map([...C.events.filter(e => e.side === 'opposition').map(e => [e.id, e]), ...(LS.cardProfiles || []).map(e => [e.id, e])]);
  for (const e of LS.cardProfiles || []) {
    if (!eventEffects.has(e.effect?.type)) err(`leaderSelect.cardProfiles.${e.id}`, `effect ${e.effect?.type} unknown to Events.EFFECTS`);
    for (const k of Object.keys(e.when || {})) if (!condKeys.has(k)) err(`leaderSelect.cardProfiles.${e.id}`, `when key ${k} unknown to Conditions`);
    if (!profiles.has(e.person)) err(`leaderSelect.cardProfiles.${e.id}`, `person ${e.person} unknown`);
    if (!hebStr(e.copy?.text) || !hebStr(e.copy?.name)) err(`leaderSelect.cardProfiles.${e.id}`, 'copy.name / copy.text missing');
  }
  // slots
  const SL = LS.coalitionSlots || {};
  const slotIds = Object.keys(SL).filter(k => !k.startsWith('_'));
  for (const s of slotIds) for (const k of Object.keys(SL[s].unlock || {})) if (!condKeys.has(k)) err(`leaderSelect.coalitionSlots.${s}`, `unlock key ${k} unknown to Conditions`);
  const R9 = LS.lineupRules || {};
  // ticker-rule check for leader-scoped lines
  const allTicker = new Set(tickerIds);
  const checkTick = (o, path, holderSrc = []) => {
    if (!o || typeof o !== 'object') return err(path, 'ticker line missing');
    if (!hebStr(o.text)) return err(path, 'ticker text missing');
    if (allTicker.has(o.id)) err(path, `duplicate ticker id ${o.id}`); allTicker.add(o.id);
    if (typeof o.poll_like !== 'boolean') err(path, 'poll_like missing');
    const L = len(o.text);
    if (L > 60) err(path, `ticker ${L} > 60: ${o.text}`);
    if (/"/.test(o.text) && realNames.some(n => o.text.includes(n))) {
      const q = [...holderSrc, ...(o.src || [])].some(f => factIds.get(f)?.label === 'Q');
      if (!q && !o.reportedSpeech) err(path, `quote marks + real name without a [Q] src: ${o.text}`);
    }
  };
  for (const t of LS.rivalTicker || []) { checkTick(t, `leaderSelect.rivalTicker.${t.id}`); if (!profiles.has(t.rival) && !cards.has(`card_${t.rival}`)) err(`leaderSelect.rivalTicker.${t.id}`, `rival ${t.rival} unknown`); }
  if (LS.leakRight?.ticker && len(LS.leakRight.ticker) > 60) err('leaderSelect.leakRight.ticker', 'ticker > 60');
  // each leader
  const steps = C.court.postpone.excuseSteps;
  for (const L of LEADERS) {
    const P = lp(L.id);
    const ready = (LS.contentReady || []).includes(L.id);
    for (const k of ['name', 'short', 'party']) if (!hebStr(L[k])) err(P, `${k} missing`);
    if (!['m', 'f'].includes(L.g)) err(P, 'g must be m or f');
    if (!['coalition', 'opposition'].includes(L.side)) err(P, 'side must be coalition or opposition');
    if (SPR && !charOf(L.art)) err(P, `art ${L.art} is not in sprites.json chars`);
    if (!ready) { if (L.status !== 'backlog') warn(P, 'not contentReady and not marked backlog'); continue; }
    for (const k of ['blurb', 'line']) if (!hebStr(L.pick?.[k])) err(P, `pick.${k} missing`);
    // The picker shows no numbers at all (spec §3.2, L9: safe in the blackout): a tile's blurb and line carry no digit.
    for (const k of ['blurb', 'line']) if (/\d/.test(L.pick?.[k] || '')) err(`${P}.pick.${k}`, `a number on the picker (spec §3.2): ${L.pick[k]}`);
    // Every leader, the default included, shows one signature rule on the picker's long-press and in T4.
    for (const k of ['name', 'text']) if (!hebStr(L.rule?.[k])) err(`${P}.rule`, `${k} missing (the picker and T4 show every leader's rule, Bibi's too)`);
    const K = L.kit || {};
    const stringsBefore = strings.filter(s => s.path.startsWith(`.leaders[`) && s.path.includes(`.${L.id}.`) && heb.test(s.text)).length;
    let facts = new Set();
    JSON.stringify(L, (k, v) => { if (k === 'src') [v].flat().concat(v && typeof v === 'object' && !Array.isArray(v) ? Object.values(v).flat() : []).forEach(x => typeof x === 'string' && facts.add(x)); return v; });
    if (L.id !== (LS.defaultLeader || 'bibi')) {
      // a new leader: the full kit (spec §5, content volume table)
      for (const k of ['prop', 'critAnim', 'verb', 'verbPlural', 'critName', 'critPlural', 'frenzyBanner']) if (!K.tap?.[k]) err(`${P}.kit.tap`, `${k} missing`);
      const ch = charOf(L.art);
      if (ch && K.tap?.critAnim && !ch.anims?.[K.tap.critAnim]) err(`${P}.kit.tap`, `critAnim ${K.tap.critAnim} is not an anim of ${L.art}`);
      if (ch && K.tap?.critEvent && !Object.keys(ch.anims?.[K.tap.critAnim]?.events || {}).includes(K.tap.critEvent)) warn(`${P}.kit.tap`, `critEvent ${K.tap.critEvent} is not an event of ${L.art}.${K.tap.critAnim}`);
      for (const k of ['firstTap', 'firstCrit', 'taps1000', 'firstPartner']) checkTick(K.headlines?.[k], `${P}.kit.headlines.${k}`);
      for (const t of Object.keys(LS.sourceTiers?.tiers || {})) {
        const s = K.sources?.[t];
        if (!s) { err(`${P}.kit.sources`, `${t} missing`); continue; }
        for (const k of ['name', 'flavor', 'levelUp']) if (!hebStr(s[k])) err(`${P}.kit.sources.${t}`, `${k} missing`);
        checkTick(s.firstOwned, `${P}.kit.sources.${t}.firstOwned`, s.src || []);
      }
      const got = (K.spins || []).map(s => s.slot);
      for (const s of skinSlots) if (!got.includes(s)) err(`${P}.kit.spins`, `slot ${s} missing`);
      for (const s of got) if (!skinSlots.includes(s)) err(`${P}.kit.spins`, `slot ${s} is not a skinnable slot`);
      if (new Set(got).size !== got.length) err(`${P}.kit.spins`, 'duplicate slot');
      for (const s of K.spins || []) for (const k of ['name', 'flavor']) if (!hebStr(s[k])) err(`${P}.kit.spins.${s.slot}`, `${k} missing`);
      const H = K.hazard || {};
      if (!LS.hazardSkins?.[H.skin]) err(`${P}.kit.hazard`, `skin ${H.skin} unknown`);
      if (!hebStr(H.postponeVerb)) err(`${P}.kit.hazard`, 'postponeVerb missing');
      if ((H.excuses || []).length !== steps) err(`${P}.kit.hazard`, `excuses ${(H.excuses || []).length} != court.postpone.excuseSteps ${steps}`);
      (H.excuses || []).forEach((x, i) => { if (i && !x.startsWith(H.excuses[i - 1].replace(/\.$/, ''))) warn(`${P}.kit.hazard.excuses[${i}]`, 'does not grow from the previous excuse (the gag is that it gets one sentence longer)'); });
      for (const k of ['firsttap', 'buy', 'elect', 'miss']) if (!hebStr(K.dubi?.squawks?.[k])) err(`${P}.kit.dubi.squawks`, `${k} missing`);
      if ((K.dubi?.talkingPoints || []).length < 4) err(`${P}.kit.dubi`, 'talkingPoints < 4 (word salad needs three)');
      for (const k of ['cash', 'frenzy', 'tapFrenzy', 'miss']) if (!hebStr(K.suitcase?.lines?.[k])) err(`${P}.kit.suitcase.lines`, `${k} missing`);
      const st = K.story || {};
      if ((st.titles || []).length !== (st.beats || []).length || (st.beats || []).length < 3) err(`${P}.kit.story`, 'needs ≥ 3 beats and one title per beat');
      if ((K.ticker || []).length < 10) err(`${P}.kit.ticker`, `${(K.ticker || []).length} lines < 10`);
      for (const t of K.ticker || []) checkTick(t, `${P}.kit.ticker.${t.id}`);
      if (!K.trophy?.id || trIds.has(K.trophy.id)) err(`${P}.kit.trophy`, 'missing, or id collides with a shipped trophy');
      if (!L.rule?.effect) err(P, 'rule missing (every leader has one signature rule, spec §5.1)');
    }
    // coalition lineup
    const Cn = L.coalition || {};
    const members = (Cn.lineup || []).map(m => m.id);
    if (new Set(members).size !== members.length) err(`${P}.coalition`, 'duplicate lineup member');
    for (const m of Cn.lineup || []) {
      if (!profiles.has(m.id)) err(`${P}.coalition.lineup`, `unknown partner ${m.id}`);
      if (!slotIds.includes(m.slot)) err(`${P}.coalition.lineup.${m.id}`, `unknown slot ${m.slot}`);
      if (m.id === L.id) err(`${P}.coalition.lineup`, `${m.id} is the leader`);
    }
    const first = (Cn.lineup || []).find(m => m.slot === 'S1');
    if (!first || first.id !== Cn.firstPartner) err(`${P}.coalition`, 'firstPartner must hold slot S1');
    for (const s of R9.requiredSlots || []) if (!(Cn.lineup || []).some(m => m.slot === s)) err(`${P}.coalition`, `required slot ${s} missing`);
    const late = (Cn.lineup || []).filter(m => /^L/.test(m.slot)).length;
    if (late < (R9.minLateSlots || 0)) err(`${P}.coalition`, `${late} late slots < ${R9.minLateSlots}`);
    const cap = (Cn.lineup || []).reduce((a, m) => a + (SL[m.slot]?.seats || 0), 0);
    if (cap < (R9.minSeatCapacity || 0)) err(`${P}.coalition`, `seat capacity ${cap} < ${R9.minSeatCapacity}`);
    for (const x of Cn.excluded || []) if (members.includes(x)) err(`${P}.coalition`, `${x} is both excluded and in the lineup`);
    for (const r of Cn.rivals || []) {
      if (!cards.has(r)) err(`${P}.coalition.rivals`, `unknown card ${r}`);
      const person = cards.get(r)?.person || r;
      if (members.includes(person) || person === L.id) err(`${P}.coalition.rivals`, `${r} is the leader or a partner in this round`);
    }
    // Bibi's lineup must reproduce the shipped partner numbers (his balance is unchanged)
    if (L.id === (LS.defaultLeader || 'bibi')) for (const m of Cn.lineup || []) {
      const p = C.partners.find(q => q.id === m.id), s = SL[m.slot];
      if (!p || !s) continue;
      for (const k of ['seats', 'upkeepPct', 'demandWeight', 'threatChance']) {
        if (p[k] === s[k] || (k === 'seats' && p.abstain) || (k === 'threatChance' && p.cannotLeave)) continue;
        err(`${P}.coalition.lineup.${m.id}`, `${k} ${p[k]} != slot ${m.slot} ${s[k]} (Bibi's lineup must equal content.partners)`);
      }
      if (JSON.stringify(p.unlock || {}) !== JSON.stringify(s.unlock || {})) err(`${P}.coalition.lineup.${m.id}`, `unlock differs from slot ${m.slot}`);
    }
    leaderReport.push(`${L.id} (${stringsBefore} strings, ${facts.size} facts, lineup ${members.length}, capacity ${cap})`);
  }
}

// ---------- report ----------
const tick = C.headlines.length + ambientAll.length;
const bubbles = C.partners.reduce((a, p) => a + new Set([...Object.values(p.lines || {}), ...Object.values(p.linesVariants || {})].flat().filter(x => typeof x === 'string' && heb.test(x))).size, 0);
console.log(`strings (Hebrew, player-facing): ${game.length}`);
console.log(`ticker lines: ${tick} (milestones ${C.headlines.length}, ambient ${C.ambientHeadlinesV2.list.length} live + ${(C.ambientHeadlinesV2.listPolitics || []).length} politics-conditional); opposition-targeted ambient: ${ambientAll.filter(o => o.target).length}`);
console.log(`sources ${C.producers.length} · spins ${C.upgrades.length} (${C.upgrades.filter(held).length} held until their effect lands) · partners ${C.partners.length} (bubbles ${bubbles}) · events ${C.events.length} (opposition ${C.events.filter(e => e.side === 'opposition').length}) · trophies ${C.achievements.list.length} · perks ${C.perks.list.length} · facts ${F.facts.length}`);
console.log(`src-tagged strings: ${game.filter(s => (s.holder.src || []).length).length}`);
console.log(`approved pictograms in use (2D Artist draws them as glyphs): ${[...pictUsed].join(' ')}`);
console.log(`ticker lines over the 45-char ideal (≤ 60 enforced): ${over45.length}` + (verbose ? '\n  ' + over45.join('\n  ') : ' (--verbose lists them)'));
console.log(`ticker no-break units (§5.2.1 strong glue): ${tickerUnits}, all ≤ ${TICKER_CLIP_MIN} px at ×4 required; the widest "${widestUnit[0]}" ${widestUnit[1]} px`);
if (leaderReport.length) console.log(`leaders (pending engine): ${leaderReport.join(' · ')}`);
console.log(`story cards (reported-speech rule): ${storyLines.length} lines, ${storyQuoted} quoted (the narrator's only); per leader: ${(C.leaders || []).map(L => `${L.id} ${((L.id === (C.leaderSelect?.defaultLeader || 'bibi') ? C.story : L.kit?.story)?.beats || []).length}`).join(' · ')}`);
if (warns.length) console.log(`\nWARN (${warns.length})\n  ` + warns.join('\n  '));
if (errors.length) console.log(`\nERROR (${errors.length})\n  ` + errors.join('\n  '));
else console.log('\nno errors');
process.exit(errors.length || (strict && warns.length) ? 1 : 0);
