// LEADER_PICK in the runtime origin (game-developer engine, leader select 2026-09-29): a fresh game
// shows the picker before the first tap, the long-press leader card, a pick of בנט, the pre-tap
// stage with the undo chip, tap 1, a whole round to the election through the real UI (the loop of
// round_web.mjs: taps, buys, T3 pills, the brawl, the court), O3 → EVOLVE_TX → the flash, the
// picker again (after: the again button and the fresh chip), a pick of ליברמן, round 2 live.
// Positions come from window.odPick (ui/views/view_pick.gd), window.odDev (ui/dev_probe.gd) and
// window.odModal / window.odFlash, in viewport logical px.
//   node tools/web/picker_web.mjs <url> <out dir> [WxH@DPR] [speed] [budget s]
// Serve build/web first (python3 -m http.server --directory build/web).
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const [base, out, dev = '390x844@2', speed = '12', budgetArg = '1200'] = process.argv.slice(2);
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
const col = (x, y) => css(x + disp.ox, y);
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
const pick = () => page.evaluate(() => window.odPick || null);
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
const checks = [];
const check = (ok, what) => { checks.push([ok, what]); log(`  ${ok ? 'ok  ' : 'FAIL'} ${what}`); };
const cellOf = (p, id) => (p.cells || []).find((c) => c[2] === id);

await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1&speed=${speed}`);
await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
await page.click('#od-quiet');
await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
await wait(1200);
disp = await page.evaluate(() => window.odDisplay);
cv = await page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { x: r.x, y: r.y }; });

// 1. the first picker
let p = await pick();
check(!!(p && p.open && p.variant === 'first' && p.cells.length === 9 && p.cells[4][2] === ''), `a fresh game opens LEADER_PICK (first), 3 × 3 with הפתעה in the centre (${p && p.cells.length} cells, avatar ${p && p.avatar})`);
await shot('p1-picker-first');
// the leader card: a long press on Bennett's tile
let c = cellOf(p, 'bennett');
await tapAt(css(c[0], c[1]), 900);
await wait(500);
let md = await modal();
check(!!(md && md.open && md.id === 'LEADER_CARD'), `a long press opens the leader card (${md && md.id})`);
await shot('p2-leader-card');
if (md && md.open) {
	await tapAt(css(md.buttons[0][0], md.buttons[0][1]));   // "לשחק בתור בנט"
	await page.waitForFunction(() => window.odDev && window.odDev.mode !== 'pick', null, { timeout: 8000 }).catch(() => {});
	await wait(400);
}
let s = await probe();
check(s && s.leader === 'bennett' && s.mode === 'title', `"לשחק בתור בנט" picks him: the pre-tap state (leader ${s && s.leader}, mode ${s && s.mode})`);
check(s && s.undo, 'the undo chip is up');
await shot('p3-bennett-pretap');
// tap 1
const hat = css(disp.hat[0], disp.hat[1]);
await tapAt(hat);
await wait(700);
s = await probe();
check(s && s.mode === 'main' && !s.undo, `tap 1 starts Bennett's round (mode ${s && s.mode}), the chip goes`);
await shot('p4-bennett-tap1');

// 2. the round, to the election (round_web.mjs's loop)
const t0 = Date.now();
const budget = Number(budgetArg) * 1000;
let lastSeats = -1;
let paid = 0;
let rounds = 0;
let lastBuy = 0;
let shotRound = false;
while (Date.now() - t0 < budget) {
	rounds++;
	s = await probe();
	if (!s) { await wait(300); continue; }
	if (s.seats.effective !== lastSeats) { log(`  t ${Math.round(s.runSec)}s  seats ${s.seats.effective}/${s.seats.gate}  bank ${Math.round(s.bank)}  paid ${paid}`); lastSeats = s.seats.effective; }
	if (s.modal !== '') {
		if (s.modal === 'EVOLUTION') break;
		await page.keyboard.press('Escape');
		await wait(400);
		continue;
	}
	if (s.cta && s.ready) break;
	if (s.court.card && s.court.phase === 'summons' && s.court.testify[0] > 0) {
		await shot('p5-bennett-press-card');
		await tapAt(css(s.court.testify[0], s.court.testify[1]));
		await wait(400);
		continue;
	}
	for (let i = 0; i < 4; i++) { await tapAt(hat, 40); await wait(70); }
	if (!shotRound && s.runSec > 60) { shotRound = true; await shot('p5-bennett-round'); }
	const quiet = !s.groupOpen && Date.now() - lastBuy < 4000;
	if (s.groupOpen && s.shop.tab !== 'producers') { await tapAt(tab(1)); await wait(300); s = await probe(); }
	const aff = quiet ? [] : (s.shop.all || []).filter((r) => r[3]);
	if (aff.length) {
		lastBuy = Date.now();
		const r = aff[aff.length - 1];
		const [top, bot] = s.shop.list;
		if (r[1] < top + 60 || r[1] > bot - 60) {
			await drag(css(360 + disp.ox, (top + bot) / 2), -(r[1] - (top + bot) / 2) * disp.f / DPR);
			await wait(300);
		} else {
			for (let k = 0; k < 3; k++) { await tapAt(css(r[0], r[1])); await wait(90); }
		}
	}
	s = await probe();
	const wantChat = s.groupOpen;   // every loop once the group exists: under load an ultimatum (90 s of game time) passes in seconds
	if (!wantChat) continue;
	if (!s.chat.open) { await tapAt(tab(3)); await wait(600); }
	for (let guard = 0; guard < 14; guard++) {
		s = await probe();
		if (!s.chat.open || (s.ready && s.cta)) break;
		const [top, bot] = s.chat.thread;
		const pills = s.chat.pills.filter((q) => q[3]).concat((s.chat.brawls || []).map((b) => [b[0], b[1], b[2], true, false]));
		if (!pills.length) break;
		const vis = pills.filter((q) => q[1] > top + 50 && q[1] < bot - 50);
		if (vis.length) {
			const q = vis[vis.length - 1];
			await tapAt(css(q[0], q[1]));
			paid++;
			await wait(q[4] ? 3400 : 500);
		} else {
			const q = pills[0];
			await drag(css(360 + disp.ox, (top + bot) / 2), -(q[1] - (top + bot) / 2) * disp.f / DPR * 0.9, 10);
			await wait(400);
		}
	}
	await page.keyboard.press('Escape');
	await wait(300);
}
s = await probe();
log(`  gate: seats ${s.seats.effective}/${s.seats.gate}, ready ${s.ready}, cta ${s.cta}, run ${Math.round(s.runSec)}s, paid ${paid} pills, loops ${rounds}`);
let elected = s.ready && s.cta;
check(elected, 'Bennett reaches the election gate');
if (elected) {
	for (let i = 0; i < 3 && s.modal !== 'EVOLUTION' && (s.chat.open || s.modal !== ''); i++) {
		await page.keyboard.press('Escape');
		await wait(400);
		s = await probe();
	}
	if (s.modal !== 'EVOLUTION') {
		await tapAt(col(360, disp.lowerY + 42));
		await page.waitForFunction(() => window.odModal && window.odModal.open && window.odModal.id === 'EVOLUTION', null, { timeout: 15000 }).catch(() => {});
	}
	await wait(700);
	await shot('p6-election-card');
	md = await modal();
	if (md && md.open && md.id === 'EVOLUTION' && md.ready) {
		await tapAt(css(md.buttons[0][0], md.buttons[0][1]));
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
		check(!!(p && p.open && p.variant === 'after' && p.again && p.again[2] === 'bennett'), `the picker follows the election: after, "עוד סבב עם בנט" (${JSON.stringify(p && p.again)})`);
		check(s && s.evolutions === 1 && s.pickPending, `round 2 waits for the pick (evolutions ${s && s.evolutions})`);
		await shot('p8-picker-after');
		// a reload mid-pick lands in the picker again
		await page.reload();
		await page.waitForFunction(() => window.odPick && window.odPick.open, null, { timeout: 120000 }).catch(() => {});
		await wait(1500);
		disp = await page.evaluate(() => window.odDisplay);
		cv = await page.evaluate(() => { const cc = document.querySelector('canvas'); const r = cc.getBoundingClientRect(); return { x: r.x, y: r.y }; });
		p = await pick();
		check(!!(p && p.open && p.variant === 'after'), 'a reload mid-pick shows the picker again (leaderPickPending)');
		await shot('p9-picker-after-reload');
		c = cellOf(p, 'liberman');
		await tapAt(css(c[0], c[1]));
		await page.waitForFunction(() => window.odDev && window.odDev.mode === 'main', null, { timeout: 8000 }).catch(() => {});
		await wait(1200);
		s = await probe();
		check(s && s.leader === 'liberman' && s.mode === 'main' && s.evolutions === 1, `pick ליברמן: round 2 is his (leader ${s && s.leader}, mode ${s && s.mode})`);
		await shot('p10-liberman-round2');
		for (let i = 0; i < 8; i++) { await tapAt(css(disp.hat[0], disp.hat[1]), 40); await wait(90); }
		await wait(400);
		await shot('p11-liberman-taps');
	}
}
log(`  page errors: ${errors.length ? JSON.stringify(errors.slice(0, 5)) : 'none'}`);
const ok = checks.every((x) => x[0]) && !errors.length;
log(ok ? 'PICKER_WEB: PASS' : 'PICKER_WEB: FAIL');
await browser.close();
process.exit(ok ? 0 : 1);
