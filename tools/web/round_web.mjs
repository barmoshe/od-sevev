// Plays a whole first round to the election in the runtime origin, through the real UI with real
// touches (game-developer views, 2026-09-29; the UX review's "not reached at runtime" O3). Headless
// Chromium at a phone size, `?dev=1&speed=N` (the dev clock; nothing is granted). The player loop is
// tools/web/round_play.mjs (shared with picker_web.mjs): taps the leader, pays the chat first
// (every affordable pill, scrolling the thread; "צאו החוצה" on a brawl; it saves for an open
// ultimatum), buys the most expensive affordable source card, testifies when summoned. When
// "עוד סבב!" is up it opens O3, checks that the round holds under the open card ("the vote stops
// the clock", spec §7.4), calls the election and follows the transition to the news flash.
// Positions come from window.odDev (ui/dev_probe.gd) and window.odModal (ui/views/view_sheet_card.gd),
// in viewport logical px.
//   node tools/web/round_web.mjs <url> <out dir> [WxH@DPR] [speed] [budget s]
// Serve build/web first (python3 -m http.server --directory build/web).
// NOT a pacing measurement. The driver acts in wall-clock time while ?speed=N runs the game N times
// faster, so in game time it taps and buys about N times less often than a player, never buys a
// spin and never catches the Suitcase. It prints its game-time cadence at the end, and
// tests/bench/test_web_driver.gd replays that cadence through PacingSim. The pacing gates live in
// tools/balance.sh. Speed 5 (2026-09-30): at ×10 an ultimatum's 90 s pass in 9 s of wall time, less
// than one loop of this driver on a loaded machine, so the round was a race against the machine.
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const { makePlayer } = await import('./round_play.mjs');
const [base, out, dev = '390x844@2', speed = '5', budgetArg = '1500'] = process.argv.slice(2);
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
const { wait, probe, shot } = P;

await P.st.ready;   // the history log (round_play.mjs) is in place before the page loads
await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1&speed=${speed}`);
await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
await page.click('#od-quiet');
await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
await wait(1200);
await P.refresh();
// a fresh game opens LEADER_PICK: הפתעה (the centre tile) deals a random leader, as the UX spec's
// default, or LEADER=<id> picks that one; then tap 1 starts the round
let pk = await page.evaluate(() => window.odPick || null);
if (pk && pk.open) {
	const c = pk.cells.find((x) => x[2] === (process.env.LEADER || '') && !x[3]) || pk.cells[0];   // the first open tile (ADR 0007)
	await P.tapAt(P.css(c[0], c[1]));   // the ballot booth (ADR 0007): a tap chooses the slip, a second tap votes
	await wait(400);
	await P.tapAt(P.css(c[0], c[1]));
	await page.waitForFunction(() => window.odDev && window.odDev.mode !== 'pick', null, { timeout: 8000 }).catch(() => {});
	await wait(600);
}
await P.tapAt(P.hat());
await wait(800);
P.st.t0 = Date.now();
const budget = Number(budgetArg) * 1000;
let s = await probe();
log(`  leader ${s && s.leader}, speed ${speed}`);
let seen = { toast: false, summons: false };
const hooks = {
	loop: async (q) => { if (!seen.toast && q.groupOpen) { seen.toast = true; await shot('chat-toast'); } },
	summons: async () => { if (!seen.summons) { seen.summons = true; await wait(500); await shot('court-summons'); } },
};
let called = false;
let ok = false;
let heldFail = false;
for (let attempt = 0; attempt < 6 && !called && !heldFail && Date.now() - P.st.t0 < budget; attempt++) {
	const why = await P.playToGate(budget, hooks);
	s = await probe();
	if (s) log(`  gate (${why}): seats ${s.seats.effective}/${s.seats.gate}, ready ${s.ready}, cta ${s.cta}, run ${Math.round(s.runSec)}s, paid ${P.st.paid} pills, loops ${P.st.loops}`);
	if (why === 'budget' || why === 'navigated' || !s) break;
	await shot('e0-cta');
	const r = await P.callElection({ card: 'e1-election-card' });
	if (r === 'held-fail') { heldFail = true; break; }
	if (r === 'navigated') break;
	if (r !== 'called') continue;
	called = true;
	await wait(900);
	await shot('e2-transition');
	await page.waitForFunction(() => window.odFlash && window.odFlash.open, null, { timeout: 30000 }).catch(() => {});
	await wait(1500);
	await shot('e3-flash');
	s = await probe();
	ok = s.evolutions === 1;
	const fl = await page.evaluate(() => window.odFlash || null);
	log(`  after the election: round ${s.evolutions + 1}, flash ${JSON.stringify(fl)}`);
	if (fl && fl.open) { await P.tapAt(P.css(fl.next[0], fl.next[1])); await wait(900); }
	await shot('e4-round2');
}
s = await probe();
log(`  ${P.cadence(speed)}`);
if (!called) {
	// evidence for the stall: the thread as it stands
	if (s && !s.chat.open && s.groupOpen) { await P.tapAt(P.tab(3)); await wait(900); }
	await shot('stall-chat');
	ok = false;
}
if (heldFail) log('  FAIL: the gate moved under the open election card (the vote must stop the clock)');
if (Object.keys(P.st.modals).length) log(`  overlays closed on the way: ${JSON.stringify(P.st.modals)}`);
if (P.st.summonsWaits) log(`  summonses left to serve themselves under T3 (the LayerHistory race, a game bug): ${P.st.summonsWaits}`);
if (P.st.navs.length) { log(`  FAIL: the page left the game mid-run (${P.st.navs.length}x, see NAVIGATION above)`); ok = false; }
log(`  page errors: ${errors.length ? JSON.stringify(errors.slice(0, 5)) : 'none'}`);
log(ok && !errors.length ? 'ROUND_WEB: PASS' : 'ROUND_WEB: FAIL');
await browser.close();
process.exit(ok && !errors.length ? 0 : 1);
