// Plays a whole first round to the election in the runtime origin, through the real UI with real
// touches (game-developer views, 2026-09-29; the UX review's "not reached at runtime" O3). Headless
// Chromium at a phone size, `?dev=1&speed=N` (the dev clock; nothing is granted): taps the
// Magician, buys the most expensive affordable source card, opens T3 and pays every open pill,
// scrolling the thread to reach the ones above the fold (the review's script paid only the bottom
// of the thread, which left the pending partners' join demands unpaid and stalled at 44/61),
// presses "צאו החוצה" on a brawl (it freezes two rows until pressed), testifies when summoned, and when "עוד סבב!" is up opens O3, calls the election and follows the
// transition to the news flash. Positions come from window.odDev (ui/dev_probe.gd) and
// window.odModal (ui/views/view_sheet_card.gd), in viewport logical px.
//   node tools/web/round_web.mjs <url> <out dir> [WxH@DPR] [speed] [budget s]
// Serve build/web first (python3 -m http.server --directory build/web).
// NOT a pacing measurement. The driver acts in wall-clock time (a few taps, one card and a look at
// the chat per loop of ~1-3 s) while ?speed=N runs the game N times faster, so in game time it taps
// and buys about N times less often than a player, never buys a spin and never catches the Suitcase.
// Its round time (34:24 of play at speed 10 on 2026-09-29) measures this driver, not the game: it
// prints its game-time cadence at the end, and tests/bench/test_web_driver.gd replays that cadence
// through PacingSim (same round length). The pacing gates live in tools/balance.sh.
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const [base, out, dev = '390x844@2', speed = '10', budgetArg = '900'] = process.argv.slice(2);
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
const wait = (ms) => page.waitForTimeout(ms);
let tid = 1;
let cv, disp;
const css = (x, y) => [cv.x + x * disp.f / DPR, cv.y + y * disp.f / DPR];
const col = (x, y) => css(x + disp.ox, y);   // 720-column logical -> CSS
async function tapAt([x, y], hold = 60) {
	const id = tid++;
	await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id }] });
	await wait(hold);
	await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
}
async function drag([x, y0], dy, steps = 8) {
	const id = tid++;
	await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y: y0, id }] });
	for (let i = 1; i <= steps; i++) {
		await wait(30);
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x, y: y0 + (dy * i) / steps, id }] });
	}
	await wait(60);
	await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
}
const probe = () => page.evaluate(() => window.odDev || null);
const modal = () => page.evaluate(() => window.odModal || null);
const shots = [];
async function shot(name) {
	const p = `${out}/${wh}@${DPR}-${name}.png`;
	await page.screenshot({ path: p });
	shots.push(p);
	console.log('  shot', p);
}
const tabsY = () => disp.logical[1] - 104;
const tab = (i) => col(540 - 180 * (i - 1) + 90, tabsY() + 52);
const log = (...a) => console.log(...a);

await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1&speed=${speed}`);
await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
await page.click('#od-quiet');
await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
await wait(1200);
disp = await page.evaluate(() => window.odDisplay);
cv = await page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { x: r.x, y: r.y }; });
const hat = css(disp.hat[0], disp.hat[1]);
await tapAt(hat);
await wait(800);
const t0 = Date.now();
const budget = Number(budgetArg) * 1000;
let seen = { toast: false, card: false, summons: false, chat: false, ult: false };
let lastSeats = -1;
let paid = 0;
let rounds = 0;
let lastBuy = 0;
let hatTaps = 0, buyActions = 0, cardTaps = 0, chatLooks = 0;
while (Date.now() - t0 < budget) {
	rounds++;
	let s = await probe();
	if (!s) { await wait(300); continue; }
	if (s.seats.effective !== lastSeats) { log(`  t ${Math.round(s.runSec)}s  seats ${s.seats.effective}/${s.seats.gate}  bank ${Math.round(s.bank)}  paid ${paid}`); lastSeats = s.seats.effective; }
	if (s.modal !== '') {
		if (s.modal === 'EVOLUTION') break;
		await page.keyboard.press('Escape');
		await wait(400);
		continue;
	}
	if (s.cta && s.ready) break;
	// the court: testify (after a look at the summons card)
	if (s.court.card && s.court.phase === 'summons' && s.court.testify[0] > 0) {
		if (!seen.summons) { seen.summons = true; await wait(500); await shot('court-summons'); }
		await tapAt(css(s.court.testify[0], s.court.testify[1]));
		await wait(400);
		continue;
	}
	for (let i = 0; i < 4; i++) { await tapAt(hat, 40); await wait(70); hatTaps++; }
	// sources: the most expensive affordable card, scrolled into view. Before the group opens (C1)
	// buy at most every 4 s: C1 pings only when the last purchase is >= 2 s old and no toast shows.
	const quiet = !s.groupOpen && Date.now() - lastBuy < 4000;
	if (s.groupOpen && s.shop.tab !== 'producers') { await tapAt(tab(1)); await wait(300); s = await probe(); }
	const aff = quiet ? [] : (s.shop.all || []).filter((r) => r[3]);
	if (aff.length) {
		lastBuy = Date.now();
		buyActions++;
		const r = aff[aff.length - 1];
		const [top, bot] = s.shop.list;
		if (r[1] < top + 60 || r[1] > bot - 60) {
			await drag(css(360 + disp.ox, (top + bot) / 2), -(r[1] - (top + bot) / 2) * disp.f / DPR);
			await wait(300);
		} else {
			for (let k = 0; k < 3; k++) { await tapAt(css(r[0], r[1])); await wait(90); cardTaps++; }
		}
	}
	// the chat: every open pill, scrolling to it
	s = await probe();
	const wantChat = s.groupOpen && (s.chat.open || s.chat.openBrawl || rounds % 2 === 0);
	if (!wantChat) continue;
	if (!seen.toast) { seen.toast = true; await shot('chat-toast'); }
	chatLooks++;
	if (!s.chat.open) { await tapAt(tab(3)); await wait(600); }
	for (let guard = 0; guard < 14; guard++) {
		s = await probe();
		if (!s.chat.open || (s.ready && s.cta)) break;   // the gate is open: go call the election
		if (!seen.chat && s.chat.pills.length) { seen.chat = true; await shot('chat'); }
		const [top, bot] = s.chat.thread;
		// the pills it can pay, and "צאו החוצה" (a brawl keeps two rows out of the 61 until pressed)
		const pills = s.chat.pills.filter((p) => p[3]).concat((s.chat.brawls || []).map((b) => [b[0], b[1], b[2], true, false]));
		if (!pills.length) break;
		const vis = pills.filter((p) => p[1] > top + 50 && p[1] < bot - 50);
		if (vis.length) {
			const p = vis[vis.length - 1];
			await tapAt(css(p[0], p[1]));
			paid++;
			await wait(p[4] ? 3400 : 500);   // a ceremony's ribbon runs 3 s of real time; a stamp needs a beat
		} else {
			const p = pills[0];
			await drag(css(360 + disp.ox, (top + bot) / 2), -(p[1] - (top + bot) / 2) * disp.f / DPR * 0.9, 10);
			await wait(400);
		}
	}
	await page.keyboard.press('Escape');
	await wait(300);
}
let s = await probe();
log(`  gate: seats ${s.seats.effective}/${s.seats.gate}, ready ${s.ready}, cta ${s.cta}, run ${Math.round(s.runSec)}s, paid ${paid} pills, loops ${rounds}`);
{
	// The cadence it played at, in GAME seconds (compare the bench's median player: 1.5 taps/s, a buy
	// whenever the best one is affordable, spins, every Suitcase). Not a pacing number: see the header.
	const g = Math.max(1, s.runSec), wall = (Date.now() - t0) / 1000;
	log(`  cadence (game time, speed ${speed}, ${Math.round(wall)} s wall): ${(hatTaps / g).toFixed(3)} taps/s, `
		+ `a purchase action every ${(g / Math.max(1, buyActions)).toFixed(1)} s (${cardTaps} card taps), `
		+ `the chat every ${(g / Math.max(1, chatLooks)).toFixed(1)} s, a loop every ${(g / Math.max(1, rounds)).toFixed(1)} s; `
		+ 'no spins, no Suitcase. Not a pacing measurement (tools/balance.sh is).');
}
let ok = s.ready && s.cta;
if (!ok) {
	// evidence for the stall: the thread as it stands
	if (!s.chat.open && s.groupOpen) { await tapAt(tab(3)); await wait(900); }
	await shot('stall-chat');
}
if (ok) {
	// close T3 (the CTA sits in the ticker row under it); Esc folds an expanded court card first
	for (let i = 0; i < 3 && s.modal !== 'EVOLUTION' && (s.chat.open || s.modal !== ''); i++) {
		await page.keyboard.press('Escape');
		await wait(400);
		s = await probe();
	}
	await shot('e0-cta');
	if (s.modal !== 'EVOLUTION') {
		await tapAt(col(360, disp.lowerY + 42));
		await page.waitForFunction(() => window.odModal && window.odModal.open && window.odModal.id === 'EVOLUTION', null, { timeout: 15000 }).catch(() => {});
	}
	await wait(700);
	await shot('e1-election-card');
	const m = await modal();
	ok = !!(m && m.open && m.id === 'EVOLUTION' && m.ready);
	log(`  O3 ${JSON.stringify(m)}`);
	if (ok) {
		await tapAt(css(m.buttons[0][0], m.buttons[0][1]));
		await wait(900);
		await shot('e2-transition');
		await page.waitForFunction(() => window.odFlash && window.odFlash.open, null, { timeout: 30000 }).catch(() => {});
		await wait(1500);
		await shot('e3-flash');
		s = await probe();
		ok = s.evolutions === 1;
		log(`  after the election: round ${s.evolutions + 1}, flash ${JSON.stringify(await page.evaluate(() => window.odFlash || null))}`);
		const fl = await page.evaluate(() => window.odFlash || null);
		if (fl && fl.open) { await tapAt(css(fl.next[0], fl.next[1])); await wait(900); }
		await shot('e4-round2');
	}
}
log(`  page errors: ${errors.length ? JSON.stringify(errors.slice(0, 5)) : 'none'}`);
log(ok && !errors.length ? 'ROUND_WEB: PASS' : 'ROUND_WEB: FAIL');
await browser.close();
process.exit(ok && !errors.length ? 0 : 1);
