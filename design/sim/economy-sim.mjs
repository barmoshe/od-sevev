// "עוד סבב" pacing sanity sim (Game Designer paper check, not a test suite; studio invariant I1).
// Reads ../content.json, so the simulated numbers ARE the shipped numbers. It approximates the
// simulation developer's rules (game/scripts/sim: coalition.gd, investigation.gd) closely enough
// to check the pitch §5 / UX §2 beats; the binding bench is tools/balance.sh.
//
// Modelled: taps (scripted tap-7 rabbit, random crits from randomCritsFromTap), sources with the
// milestone doublings and the reveal rule, C1 (openAtSourcesOwned + firstDemandPrice), money-gated
// partner joins (unlock.runBananasAtLeast, joinGapSec), join and member demands (demandSec × ₪/s ×
// priceMult, Goldknopf's priceGrowth, Regev's ceremony = free), upkeep (upkeepPct of ₪/s, capped at
// upkeepMaxPct), own seats, Gafni's abstention (majority floor((120 - a)/2) + 1), Smotrich's VAT
// effect, suspicion from shady income share (court.sources) × Levin, onPay suspicion, summons then
// court day, the floor, and the per-round base payout. The buyer is greedy (best payback) and pays
// every demand as soon as it can; ultimatums, suitcases, spins and event cards are left out.
// coalition.unlockScalePerElection multiplies partner money thresholds by scale^elections (live in the sim).
// Usage: node design/sim/economy-sim.mjs
import { readFileSync } from 'node:fs';
const C = JSON.parse(readFileSync(new URL('../content.json', import.meta.url)));
const P = C.producers, PR = C.prestige, CO = C.coalition, CT = C.court;
const fmtT = s => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;
const ms = C.milestones.perProducer;
const mMult = o => ms.reduce((a, m) => (o >= m.owned ? a * m.mult : a), 1);
const K3_SPINS = 1500, Q1_COTTAGE = C.headlines.find(h => h.cottagePixel === 1).trigger.value;
const coalitionSide = p => (p.side || 'coalition') === 'coalition' && !p.standIn;

function round({ tps, k, base, clean = false, seed = 1 }) {
  let R = seed; const rnd = () => ((R = (R * 16807) % 2147483647) / 2147483647);
  const pm = 1 + PR.multPerThumb * base;
  const floor = Math.min(CT.floorPerRoundPct * k, CT.floorMaxPct);
  const s = { t: 0, bank: 0, run: 0, own: P.map(() => 0), taps: 0, susp: floor, phase: 'idle', phaseT: 0, courtDays: 0,
    members: new Set(), gk: 1, beats: {}, paid: 0 };
  const eff = id => C.partners.find(p => p.id === id);
  const prodMult = i => { let m = mMult(s.own[i]); for (const id of s.members) for (const e of eff(id).effects || []) if (e.type === 'producerMult' && e.producer === P[i].id) m *= e.mult; return m; };
  const gross = () => P.reduce((a, p, i) => a + p.baseBps * s.own[i] * prodMult(i), 0) * pm;
  const upkeep = () => Math.min(CO.upkeepMaxPct, [...s.members].reduce((a, id) => a + (eff(id).upkeepPct || 0), 0)) / 100;
  const bps = () => gross() * (1 - upkeep()) * (s.phase === 'court' ? CT.courtBpsMult : 1);
  const cost = i => P[i].baseCost * Math.pow(P[i].costGrowth, s.own[i]);
  const top = () => s.own.reduce((q, o, i) => (o > 0 ? i + 1 : q), 0);
  const own = () => Math.min(CO.ownSeats.max, CO.ownSeats.base + CO.ownSeats.perTier * top() + CO.ownSeats.perBaseDoubling * Math.floor(Math.log2(1 + base)));
  const seats = () => own() + [...s.members].filter(id => coalitionSide(eff(id))).reduce((a, id) => a + eff(id).seats, 0);
  const majority = () => Math.floor((CO.knessetSize - [...s.members].reduce((a, id) => a + (eff(id).abstain || 0), 0)) / 2) + 1;
  const mark = b => { if (s.beats[b] === undefined) s.beats[b] = s.t; };
  const price = p => (p.demandKind === 'ceremony' ? 0 : Math.max(CO.minPrice, CO.demandSec * gross() * (p.priceMult || 1) * (p.id === 'goldknopf' ? s.gk : 1)));
  let c1 = false, lastJoin = -1e9, queue = [], nextMember = null, acc = 0; const dt = 0.1;
  while (s.t < 5400) {
    acc += tps * dt;
    while (acc >= 1) { acc--; s.taps++; if (s.phase === 'court' && CT.courtPausesTaps) continue;
      let v = (C.tap.baseValue * pm + (C.tap.pctOfBpsBase || 0) * bps()) * (s.phase === 'court' ? CT.courtBpsMult : 1);
      if (k === 0 && s.taps === C.tap.firstCrit.atTap) v *= C.tap.firstCrit.mult;
      else if ((k > 0 || s.taps >= C.tap.firstCrit.randomCritsFromTap) && rnd() < C.tap.critChance) v *= C.tap.critMult;
      s.bank += v; s.run += v; if (k === 0 && s.taps === 12) s.beats.bankAtTap12 = s.bank; }
    const inc = bps() * dt; s.bank += inc; s.run += inc;
    // suspicion (rate from shady income share), summons -> court -> floor
    const g = gross();
    if (s.phase === 'idle' && g > 0) {
      const lv = [...s.members].reduce((a, id) => a * ((eff(id).effects || []).find(e => e.type === 'suspicionGainMult')?.mult ?? 1), 1);
      const rate = P.reduce((a, p, i) => a + (CT.sources[p.id] || 0) * (p.baseBps * s.own[i] * prodMult(i) * pm) / g, 0) * lv;
      s.susp = Math.min(CT.max, s.susp + rate * dt);
      if (s.susp >= CT.max) { s.phase = 'summons'; s.phaseT = CT.summonsAutoTestifySec; }
    } else if (s.phase === 'summons') { s.phaseT -= dt; if (s.phaseT <= 0) { s.phase = 'court'; s.phaseT = CT.courtDaySec; s.courtDays++; mark('first court day'); } }
    else if (s.phase === 'court') { s.phaseT -= dt; if (s.phaseT <= 0) { s.phase = 'idle'; s.susp = floor; } }
    // coalition
    const nOwned = s.own.reduce((a, b) => a + b, 0);
    if (!c1 && nOwned >= CO.openAtSourcesOwned && (k > 0 || s.bank >= CO.firstDemandPrice)) {
      c1 = true; mark('C1 chat ping'); queue.push({ id: CO.firstPartner, price: k === 0 ? CO.firstDemandPrice : price(eff(CO.firstPartner)) }); lastJoin = s.t; }
    if (c1 && queue.length === 0 && s.t - lastJoin >= CO.joinGapSec) {
      const cand = C.partners.find(p => p.id !== CO.firstPartner && !p.standIn && !p.rebel && !s.members.has(p.id) && s.beats['asked ' + p.id] === undefined
        && s.run >= (p.unlock?.runBananasAtLeast ?? 0) * Math.pow(CO.unlockScalePerElection || 1, k) && (p.unlock?.evolutionsAtLeast ?? 0) <= k && !(p.excludes || []).some(x => s.members.has(x)));
      if (cand) { s.beats['asked ' + cand.id] = s.t; queue.push({ id: cand.id, price: price(cand) }); lastJoin = s.t; }
    }
    if (queue.length && s.bank >= queue[0].price) {
      const q = queue.shift(); const p = eff(q.id); s.bank -= q.price; s.members.add(q.id); s.paid++;
      if (p.priceGrowth) s.gk *= p.priceGrowth; if (p.onPay?.suspicion) s.susp = Math.min(CT.max, s.susp + p.onPay.suspicion);
      if (k === 0 && s.paid === 1) { mark('first partner paid'); s.beats.seatsAtFirstPartner = seats(); }
      if (nextMember === null) nextMember = s.t + 90;
    }
    if (nextMember !== null && s.t >= nextMember && s.members.size) {   // member upkeep demand (paid at once when affordable)
      const ids = [...s.members].filter(id => eff(id).demandWeight > 0); const id = ids[Math.floor(rnd() * ids.length)];
      if (id) { const pr = price(eff(id)); if (s.bank >= pr) { s.bank -= pr; if (eff(id).priceGrowth) s.gk *= eff(id).priceGrowth; } }
      const gap = Math.max(CO.demandGapMinSec, (CO.demandGapSec[0] + rnd() * (CO.demandGapSec[1] - CO.demandGapSec[0])) * Math.pow(CO.demandGapPerMember, s.members.size));
      nextMember = s.t + gap;
    }
    // greedy buyer
    if (!queue.length) { let best = null, bp = Infinity;
      P.forEach((p, i) => { if (clean && p.shady) return; const reveal = p.revealAtRunEarned ?? C.producerReveal.revealAtRunBananasFracOfBaseCost * p.baseCost;
        if (s.run < reveal && s.own[i] === 0) return; const c = cost(i);
        const pb = c / (p.baseBps * pm * mMult(s.own[i] + 1)) + Math.max(0, c - s.bank) / Math.max(bps() + tps, 1e-9);
        if (pb < bp) { bp = pb; best = i; } });
      if (best !== null && s.bank >= cost(best)) { if (P[best].shady) mark('first shady source'); s.bank -= cost(best); s.own[best]++; continue; } }
    if (k === 0) { if (s.run >= K3_SPINS) mark('spins tab (K3)'); if (s.run >= Q1_COTTAGE) mark('cottage (Q1)');
      for (const m of [180, 300]) if (s.t >= m && s.beats['@' + m] === undefined) s.beats['@' + m] = { seats: seats(), majority: majority(), susp: Math.round(s.susp), bps: Math.round(bps()) }; }
    if (seats() >= majority()) { mark('61: עוד סבב!'); break; }
    s.t += dt;
  }
  return { ...s, top: top(), bps: bps() };
}

const gain = run => Math.floor(Math.pow(run / PR.payout.divisor, 1 / PR.payout.rootDegree) + PR.payout.epsilon);

console.log('# Round 1 beats (pitch §5, UX §2), greedy buyer that pays every demand at once');
for (const tps of [1, 1.5, 3]) {
  const r = round({ tps, k: 0, base: 0 }); const b = r.beats;
  const line = Object.entries(b).filter(([k, v]) => typeof v === 'number' && !/^(bank|seats)/.test(k)).sort((x, y) => x[1] - y[1]).map(([k, v]) => `${k} ${fmtT(v)}`).join(' · ');
  console.log(`\n## ${tps} taps/s\n${line}\nbank at tap 12: ${b.bankAtTap12?.toFixed(0)} ₪ · seats at first partner: ${b.seatsAtFirstPartner} · @3:00 ${JSON.stringify(b['@180'])} · @5:00 ${JSON.stringify(b['@300'])} · round earned ${r.run.toExponential(2)} → base +${gain(r.run)} · court days ${r.courtDays}`);
}
for (const [label, clean] of [['all sources', false], ['clean route (never buys shady)', true]]) {
  console.log(`\n# Rounds, election at the gate, 1.5 taps/s, ${label}, per-round payout floor(cbrt(runEarned/${PR.payout.divisor}))`);
  let base = 0, T = 0; const rows = [];
  for (let k = 0; k < 12; k++) {
    const r = round({ tps: 1.5, k, base, clean, seed: 7 + k }); T += r.t; const g = gain(r.run); base += g;
    rows.push(`r${k + 1} ${fmtT(r.t)} (Σ ${fmtT(T)}) earned ${r.run.toExponential(1)} top ${r.top} court ${r.courtDays} +${g} → base ${base} ×${(1 + PR.multPerThumb * base).toFixed(1)}`);
  }
  console.log(rows.join('\n'));
}
const s06 = C.upgrades.find(u => u.id === 's06');
console.log(`\nS06 כנף ציון costs ${s06.cost.toExponential(2)} and unlocks at evolutions >= ${s06.unlock.evolutionsAtLeast}: compare with 'earned' in round ${s06.unlock.evolutionsAtLeast + 1}.`);
