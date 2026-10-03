// LEADER_PICK in the runtime origin (leader select 2026-09-29; the roster ladder 2026-10-03, ADR
// 0007): a fresh game opens the picker with Bibi and Bennett open (the rest locked), pick Bibi, tap 1, a whole round to the election through the real UI (the shared
// player of tools/web/round_play.mjs: taps, the chat first, buys, the brawl, the court), O3 (the
// round holds under the open card: "the vote stops the clock", spec §7.4) → EVOLVE_TX → the flash,
// the picker (after: the again button), a reload mid-pick, the long-press card, a pick of בנט, round 2 live.
// Positions come from window.odPick (ui/views/view_pick.gd), window.odDev (ui/dev_probe.gd) and
// window.odModal / window.odFlash, in viewport logical px.
//   node tools/web/picker_web.mjs <url> <out dir> [WxH@DPR] [speed] [budget s]
// Serve build/web first (python3 -m http.server --directory build/web).
// Speed 5 (2026-09-30; was 12): at ×12 the driver's loop (a few seconds of wall time on a loaded
// machine) was a minute of game time, an ultimatum ran out between two looks at the chat, and
// Bennett's round never held 61 in the budget. The round is the driver's, not a pacing number.
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const { makePlayer } = await import('./round_play.mjs');
const [base, out, dev = '390x844@2', speed = '5', budgetArg = '1800'] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const [wh, dprS] = dev.split('@');
const [W, H] = wh.split('x').map(Number);
const DPR = Number(dprS);
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: true, hasTouch: true });
const page = await ctx.newPage();
const errors = [];
page.on('pageerror', (e) => errors.push(e.message));
const cdp = await ctx.newCDPSession(page);
const log = (...a) => console.log(...a);
const P = makePlayer({ page, cdp, DPR, out, wh, log });
const { wait, probe, modal, shot, css, tapAt } = P;
const pick = () => page.evaluate(() => window.odPick || null);
const checks = [];
const check = (ok, what) => { checks.push([ok, what]); log(`  ${ok ? 'ok  ' : 'FAIL'} ${what}`); };
const cellOf = (p, id) => ((p && p.cells) || []).find((c) => c[2] === id) || [-1, -1, ""];

await P.st.ready;   // the history log (round_play.mjs) is in place before the page loads
await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1&speed=${speed}`);
await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
await page.click('#od-quiet');
await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
await wait(1200);
await P.refresh();

// 1. a fresh game opens the picker with two open tiles (the roster ladder, ADR 0007): Bibi and
// Bennett side by side, the rest locked with the round they open in; pick Bibi
await page.waitForFunction(() => window.odPick && window.odPick.open, null, { timeout: 15000 }).catch(() => {});
let p = await pick();
let s = await probe();
const openIds = ((p && p.cells) || []).filter((c) => ['bibi', 'bennett'].includes(c[2])).map((c) => c[3]);
const lockedN = ((p && p.cells) || []).filter((c) => c[3]).length;
check(!!(p && p.open && p.variant === 'first'), `a fresh game opens the picker (${p && p.open})`);
check(openIds.length === 2 && openIds.every((x) => !x) && lockedN >= 5, `Bibi and Bennett are open, ${lockedN} tiles locked`);
await shot('p1-first-launch');
{
	const lk = ((p && p.cells) || []).find((c) => c[3]);
	if (lk) { await tapAt(css(lk[0], lk[1])); await wait(700); }
	s = await probe();
	check(s && s.mode === 'pick', `a tap on a locked tile starts nothing (mode ${s && s.mode})`);
	await shot('p2-locked-tap');
	const bc = cellOf(p, 'bibi');
	await tapAt(css(bc[0], bc[1]));
	await page.waitForFunction(() => window.odDev && window.odDev.mode !== 'pick', null, { timeout: 8000 }).catch(() => {});
	await wait(900);
	s = await probe();
	check(s && s.leader === 'bibi' && s.mode === 'title', `pick Bibi: the pre-tap stage (leader ${s && s.leader}, mode ${s && s.mode})`);
}
if (process.env.PICK_ONLY) {   // the first launch at this viewport only
	log(`  page errors: ${errors.length ? JSON.stringify(errors.slice(0, 5)) : 'none'}`);
	await browser.close();
	process.exit(checks.every((x) => x[0]) && !errors.length ? 0 : 1);
}
// tap 1
await tapAt(P.hat());
await wait(700);
s = await probe();
check(s && s.mode === 'main', `tap 1 starts Bibi's round (mode ${s && s.mode})`);
await shot('p4-bibi-tap1');
let c;
let md;

// 2. the round, to the election (the shared player); the gate can fall between the CTA and the card
// (a walkout before the vote): play on and try again. Under the open card it must hold.
P.st.t0 = Date.now();
const budget = Number(budgetArg) * 1000;
let shotRound = false;
let shotPress = false;
const hooks = {
	loop: async (q) => { if (!shotRound && q.runSec > 60) { shotRound = true; await shot('p5-bibi-round'); } },
	summons: async () => { if (!shotPress) { shotPress = true; await shot('p5-bibi-press-card'); } },
};
let called = false;
let held = true;
for (let attempt = 0; attempt < 6 && !called && Date.now() - P.st.t0 < budget; attempt++) {
	const why = await P.playToGate(budget, hooks);
	s = await probe();
	if (s) log(`  gate (${why}): seats ${s.seats.effective}/${s.seats.gate}, ready ${s.ready}, cta ${s.cta}, run ${Math.round(s.runSec)}s, paid ${P.st.paid} pills, loops ${P.st.loops}`);
	if (why === 'budget' || why === 'navigated' || !s) break;
	const r = await P.callElection({ card: 'p6-election-card' });
	if (r === 'held-fail') { held = false; break; }
	if (r === 'navigated') break;
	if (r !== 'called') continue;
	// committed: EVOLVE_TX runs, then the flash or the picker opens
	called = await page.waitForFunction(() => (window.odFlash && window.odFlash.open) || (window.odPick && window.odPick.open)
		|| (window.odDev && window.odDev.evolutions > 0), null, { timeout: 40000 }).then(() => true).catch(() => false);
	if (!called) log('  the confirm did not start the election');
}
log(`  ${P.cadence(speed)}`);
check(held, 'the round holds under the open election card (the vote stops the clock)');
check(called, 'Bibi calls the election (O3 "לפזר את הכנסת")');
if (called) {
	await page.waitForFunction(() => (window.odFlash && window.odFlash.open) || (window.odPick && window.odPick.open), null, { timeout: 40000 }).catch(() => {});
	await wait(1500);
	const fl = await page.evaluate(() => window.odFlash || null);
	if (fl && fl.open) {
		await shot('p7-flash');
		await tapAt(css(fl.next[0], fl.next[1]));
		await wait(900);
	}
	await page.waitForFunction(() => window.odPick && window.odPick.open, null, { timeout: 15000 }).catch(() => {});
	await wait(600);
	p = await pick();
	s = await probe();
	check(!!(p && p.open && p.variant === 'after' && p.again && p.again[2] === 'bibi'), `the picker opens after the first election: after, "עוד סבב עם ביבי" (${JSON.stringify(p && p.again)})`);
	check(s && s.evolutions === 1 && s.pickPending, `round 2 waits for the pick (evolutions ${s && s.evolutions})`);
	await shot('p8-picker-after');
	// a reload mid-pick lands in the picker again (the driver's own navigation: not logged as one)
	P.st.armed = false;
	await page.reload();
	await page.waitForFunction(() => window.odPick && window.odPick.open, null, { timeout: 120000 }).catch(() => {});
	await wait(1500);
	await P.refresh();
	p = await pick();
	check(!!(p && p.open && p.variant === 'after'), 'a reload mid-pick shows the picker again (leaderPickPending)');
	await shot('p9-picker-after-reload');
	// the leader card: a long press on Bennett's tile, then "לשחק בתור בנט"
	c = cellOf(p, 'bennett');
	{
		const [x, y] = css(c[0], c[1]);
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id: 900 }] });
		await wait(900);
		await page.waitForFunction(() => window.odModal && window.odModal.open && window.odModal.id === 'LEADER_CARD', null, { timeout: 6000 }).catch(() => {});
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
		await wait(500);
	}
	md = await modal();
	check(!!(md && md.open && md.id === 'LEADER_CARD'), `a long press opens the leader card (${md && md.id})`);
	await shot('p10-leader-card');
	if (md && md.open) {
		await tapAt(css(md.buttons[0][0], md.buttons[0][1]));   // "לשחק בתור בנט"
		await page.waitForFunction(() => window.odDev && window.odDev.mode === 'main', null, { timeout: 8000 }).catch(() => {});
		await wait(1200)
	}
	s = await probe();
	check(s && s.leader === 'bennett' && s.mode === 'main' && s.evolutions === 1, `pick בנט: round 2 is his (leader ${s && s.leader}, mode ${s && s.mode})`);
	await shot('p11-bennett-round2');
	const run0 = s ? s.runSec : 0;
	for (let i = 0; i < 8; i++) { await tapAt(P.hat(), 40); await wait(90); }
	await wait(600);
	s = await probe();
	check(s && s.leader === 'bennett' && s.runSec > run0 && s.bank > 0, `Bennett's round 2 runs: taps pay, the clock moves (run ${s && s.runSec.toFixed(1)} s, bank ${s && Math.round(s.bank)})`);
	await shot('p12-bennett-taps');
}
if (Object.keys(P.st.modals).length) log(`  overlays closed on the way: ${JSON.stringify(P.st.modals)}`);
if (P.st.summonsWaits) log(`  summonses left to serve themselves under T3 (the LayerHistory race, a game bug): ${P.st.summonsWaits}`);
check(!P.st.navs.length, `the page never left the game mid-run (${P.st.navs.length} navigations, see NAVIGATION above)`);
log(`  page errors: ${errors.length ? JSON.stringify(errors.slice(0, 5)) : 'none'}`);
const ok = checks.every((x) => x[0]) && !errors.length;
log(ok ? 'PICKER_WEB: PASS' : 'PICKER_WEB: FAIL');
await browser.close();
process.exit(ok ? 0 : 1);
