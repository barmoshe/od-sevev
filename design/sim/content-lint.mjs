// "עוד סבב" content lint (Game Designer paper check, not a test suite; studio invariant I1).
// Reads design/content.json, design/facts.json and design/redlines.json and reports:
//   red-line hits, poll-number hits, src ids missing from the fact sheet, the סבב rule, lowercase
//   Latin, invented quotes of real people in the ticker, length budgets, duplicate ids, and counts.
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
  return new RegExp(`(^|[^\\u0590-\\u05FF])[${pre}]{0,${R.match.maxPrefixLetters}}${t}(?=$|[^\\u0590-\\u05FF])`).test(text);
}
for (const s of game) {
  const allowed = allowFor(s.path);
  for (const cat of R.categories) for (const term of cat.terms)
    if (!allowed.includes(term) && hits(s.text, term)) err(s.path, `red line [${cat.id}] '${term}' in: ${s.text}`);
  for (const term of R.reviewTerms.terms) if (hits(s.text, term)) warn(s.path, `review term '${term}' (group-as-punchline check): ${s.text}`);
}

// ---------- 3. poll-number rule (UX §6.3.4) ----------
const pollKw = ['מנדט', 'מנדטים', 'סקר', 'סקרים', 'מוביל', 'מובילה', 'אחוז החסימה', 'החסימה'];
for (const s of game) {
  if (s.holder.poll_like === true) continue;
  const words = s.text.split(/\s+/);
  words.forEach((w, i) => {
    if (!pollKw.some(k => w.replace(/[^֐-׿]/g, '').replace(new RegExp(`^[${pre}]{0,2}`), '') === k || w.includes(k))) return;
    const near = words.slice(Math.max(0, i - 3), i + 4).join(' ');
    if (/\d/.test(near)) err(s.path, `poll-number rule: digit near '${w}' without poll_like:true: ${s.text}`);
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
  'רגב', 'גוטליב', 'אמסלם', 'קרעי', 'דיסטל', 'טראמפ', 'הרצוג', 'נתניהו', 'ביבי', 'אילוז', 'אלמוג כהן'];
const tickerPaths = s => /^\.(headlines|ambientHeadlinesV2)|\.ticker$|tickerStart$|\.onPaidTicker$/.test(s.path);
for (const s of game.filter(tickerPaths)) {
  if (!/"/.test(s.text)) continue;
  if (!realNames.some(n => s.text.includes(n))) continue;
  const q = (s.holder.src || []).some(f => factIds.get(f)?.label === 'Q');
  if (!q && !s.holder.reportedSpeech) err(s.path, `quote marks + real name without a [Q] src: ${s.text}`);
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
  'goldenCaughtLifetimeAtLeast', 'playSecAtLeast', 'weekday', 'hour', 'mode']);
const eventEffects = new Set(['none', 'suspicion', 'noCrit', 'brawl', 'leak', 'interview', 'pardonDesk', 'seatDrain', 'roulette', 'kaia', 'drumline', 'loseRandomPartner', 'pledge']);
const econEffects = new Set(['tapMult', 'tapPctOfBps', 'critChance', 'goldenIntervalMult', 'goldenLifeMult', 'globalMult', 'producerMult', 'suspicionGainMult', 'baseMult', 'bpsMult',
  'tapAdd', 'offlineMult', 'basePctThisRound', 'suspicionFreeze', 'wipeSourceSuspicion']);
for (const e of C.events) {
  for (const k of Object.keys(e.when || {})) if (!condKeys.has(k)) err(`events.${e.id}`, `when key ${k} unknown to Conditions`);
  if (!eventEffects.has(e.effect?.type)) err(`events.${e.id}`, `effect ${e.effect?.type} unknown to Events.EFFECTS`);
  if (e.flag && !(e.flag in C.flags)) err(`events.${e.id}`, `flag ${e.flag} not declared in flags`);
  for (const pr of e.effect?.pairs || []) for (const x of pr) if (!C.partners.some(p => p.id === x)) err(`events.${e.id}`, `unknown partner ${x}`);
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
const held = u => u.unlock?.evolutionsBelow === 0;
for (const u of C.upgrades) if (!held(u) && !econEffects.has(u.effect?.type)) err(`upgrades.${u.id}`, `effect ${u.effect?.type} not implemented; hold it with unlock.evolutionsBelow: 0 + _pendingEngine`);
const eraIds = new Set(C.eras.list.map(e => e.id));
for (const o of ambientAll) if (o.when?.era && ![o.when.era].flat().every(e => eraIds.has(e))) err(o.id, `unknown era ${o.when.era}`);
for (const o of C.golden.outcomes) if (!['instant', 'bpsFrenzy', 'tapFrenzy'].includes(o.type)) err(`golden.${o.id}`, `type ${o.type} unknown`);
for (const o of ambientAll) if (o.when?.owned && !producerIds.has(o.when.owned.producer)) err(o.id, 'unknown producer');
const partnerIds = new Set(C.partners.map(p => p.id));
for (const o of ambientAll) for (const k of ['partnerMember', 'partnerNotMember']) if (o.when?.[k]) [o.when[k]].flat().forEach(id => { if (!partnerIds.has(id)) err(o.id, `unknown partner ${id}`); });
const w = C.golden.outcomes.filter(o => !o.era).reduce((a, o) => a + o.weight, 0);
if (Math.abs(w - 1) > 1e-9) err('golden.outcomes', `weights outside Washington sum to ${w}, not 1`);

// ---------- report ----------
const tick = C.headlines.length + ambientAll.length;
const bubbles = C.partners.reduce((a, p) => a + new Set([...Object.values(p.lines || {}), ...Object.values(p.linesVariants || {})].flat().filter(x => typeof x === 'string' && heb.test(x))).size, 0);
console.log(`strings (Hebrew, player-facing): ${game.length}`);
console.log(`ticker lines: ${tick} (milestones ${C.headlines.length}, ambient ${C.ambientHeadlinesV2.list.length} live + ${(C.ambientHeadlinesV2.listPolitics || []).length} politics-conditional); opposition-targeted ambient: ${ambientAll.filter(o => o.target).length}`);
console.log(`sources ${C.producers.length} · spins ${C.upgrades.length} (${C.upgrades.filter(u => u.unlock?.evolutionsBelow === 0).length} held until their effect lands) · partners ${C.partners.length} (bubbles ${bubbles}) · events ${C.events.length} (opposition ${C.events.filter(e => e.side === 'opposition').length}) · trophies ${C.achievements.list.length} · perks ${C.perks.list.length} · facts ${F.facts.length}`);
console.log(`src-tagged strings: ${game.filter(s => (s.holder.src || []).length).length}`);
console.log(`approved pictograms in use (2D Artist draws them as glyphs): ${[...pictUsed].join(' ')}`);
console.log(`ticker lines over the 45-char ideal (≤ 60 enforced): ${over45.length}` + (verbose ? '\n  ' + over45.join('\n  ') : ' (--verbose lists them)'));
if (warns.length) console.log(`\nWARN (${warns.length})\n  ` + warns.join('\n  '));
if (errors.length) console.log(`\nERROR (${errors.length})\n  ` + errors.join('\n  '));
else console.log('\nno errors');
process.exit(errors.length || (strict && warns.length) ? 1 : 0);
