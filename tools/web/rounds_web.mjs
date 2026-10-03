// The seeded rounds' browser check (game-developer, 2026-10-02): "תעבור אותי" and "הסבב היומי"
// on the real web build at a phone size, `?dev=1&speed=N`.
//   1. challenge: the page opens on a challenge link's hash; the intro card; GO; the round is played
//      to the 61 gate by the shared scripted player (round_play.mjs); the ghost chip is shot on the
//      way; "עוד סבב!" ends the round on the result card (no election); "לשלוח בחזרה" (the text
//      share's fallback: the clipboard); back to the player's own game.
//   2. daily: a fresh page; the picker's "הסבב היומי" entry; the daily card; GO; played to 61; the
//      result card with the grid; its share text.
// Shots go to <out>. Exit 0 when every step passed.
//   node tools/web/rounds_web.mjs <url> <out dir> [WxH@DPR] [speed] [budget s] [only: challenge|daily]
// Serve build/web first: python3 -m http.server 8851 --directory build/web
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const { makePlayer } = await import('./round_play.mjs');
const [base, out, spec = '390x844@2', speedArg = '5', budgetArg = '420', only = ''] = process.argv.slice(2);
if (!base || !out) {
	console.log('usage: node tools/web/rounds_web.mjs <url> <out dir> [WxH@DPR] [speed] [budget s] [only]');
	process.exit(2);
}
fs.mkdirSync(out, { recursive: true });
const [wh, dprS] = spec.split('@');
const [W, H] = wh.split('x').map(Number);
const DPR = Number(dprS);
const speed = Number(speedArg);
const log = (...a) => console.log(...a);
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
let failed = 0;
const ok = (cond, what) => { log(`  ${cond ? 'ok  ' : 'FAIL'} ${what}`); if (!cond) failed++; };

async function open(hash) {
	const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: true, hasTouch: true,
		permissions: ['clipboard-read', 'clipboard-write'] });
	const page = await ctx.newPage();
	const errors = [];
	page.on('pageerror', (e) => errors.push(e.message));
	const cdp = await ctx.newCDPSession(page);
	const P = makePlayer({ page, cdp, DPR, out, wh, log: () => {} });
	await P.st.ready;
	// navigator.share is absent in headless Chromium: the text share falls back to the clipboard
	await page.addInitScript(() => { window.__copied = []; const w = navigator.clipboard && navigator.clipboard.writeText; if (w) navigator.clipboard.writeText = (t) => { window.__copied.push(t); return Promise.resolve(); }; });
	await page.goto(`${base}?dev=1&speed=${speed}${hash}`);
	await page.waitForSelector('#od-sound', { state: 'visible', timeout: 120000 });
	await page.click('#od-quiet');
	await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
	await page.waitForTimeout(1500);
	await P.refresh();
	return { ctx, page, P, errors };
}

const shot = async (page, name) => { const p = `${out}/${wh}@${DPR}-${name}.png`; await page.screenshot({ path: p }); log('  shot', p); };
const modal = (page) => page.evaluate(() => window.odModal || null);
const round = (page) => page.evaluate(() => window.odRound || null);
async function tapModalButton(P, page, i) {
	const m = await modal(page);
	await P.tapAt(P.css(m.buttons[i][0], m.buttons[i][1]));
	await page.waitForTimeout(700);
}

// Plays the round to the gate, shooting the chip once; then taps the CTA. Returns the probe at the end.
async function playRound(P, page, chipShot) {
	let shotDone = false;
	const hooks = { loop: async () => {
		if (shotDone) return;
		const r = await round(page);
		if (r && r.chip && r.runSec > 40) { shotDone = true; await shot(page, chipShot); log(`  chip: ${JSON.stringify(r.chipLines)}`); }
	} };
	P.st.t0 = Date.now();
	for (let attempt = 0; attempt < 6; attempt++) {
		const why = await P.playToGate(Number(budgetArg) * 1000, hooks);
		let s = await P.probe();
		log(`  gate (${why}): seats ${s.seats.effective}/${s.seats.gate}, run ${Math.round(s.runSec)}s`);
		if (why !== 'gate') return null;
		for (let i = 0; i < 3 && (s.chat.open || s.modal !== ''); i++) {
			await P.esc(300);   // the chat (T3) covers the ticker's CTA
			s = await P.probe();
		}
		await shot(page, `${chipShot}-gate`);
		await P.tapAt(s.ctaAt ? P.css(s.ctaAt[0], s.ctaAt[1]) : P.col(360, P.st.disp.lowerY + 42));
		await page.waitForTimeout(900);
		const r = await round(page);
		if (r && r.done) return r;
	}
	return null;
}

// The share drawer (the share platform's HTML sheet, ShareKit.request): wait for it, read its
// message (the text, then the link alone on the last line), close it. '' when it never opened.
async function drawerMsg(page) {
	await page.waitForFunction(() => window.odShareUI && window.odShareUI.state && window.odShareUI.state.open, null, { timeout: 8000 }).catch(() => {});
	const r = await page.evaluate(() => {
		const st = window.odShareUI && window.odShareUI.state;
		const el = document.getElementById('od-sh-msg');
		return st && st.open ? { kind: st.p && st.p.kind, msg: el ? el.textContent : '' } : null;
	});
	if (r) {
		await page.waitForTimeout(400);
		if (await page.isVisible('#od-sh-x')) await page.click('#od-sh-x');
		await page.waitForTimeout(700);
	}
	return r || { kind: '', msg: '' };
}

if (only === '' || only === 'challenge') {
	log('challenge');
	const { ctx, page, P, errors } = await open(`#k=challenge&l=${process.env.OD_LEADER || 'bibi'}&s=31337&t=300&r=abcd1234`);
	await page.waitForFunction(() => window.odModal && window.odModal.open && window.odModal.id === 'CHALLENGE_INTRO', null, { timeout: 15000 }).catch(() => {});
	const m0 = await modal(page);
	ok(m0 && m0.id === 'CHALLENGE_INTRO', 'the link opens the challenge card');
	ok(await page.evaluate(() => location.hash === ''), 'the hash is consumed (a reload lands in the own game)');
	await shot(page, 'c1-intro');
	await page.waitForTimeout(400);
	await tapModalButton(P, page, 0);
	let r = await round(page);
	ok(r && r.inRound && r.leader === (process.env.OD_LEADER || 'bibi') && r.seed === 31337, `the round: ${r && r.leader} seed ${r && r.seed}`);
	await shot(page, 'c2-pretap');
	await P.tapAt(P.hat());
	await page.waitForTimeout(800);
	r = await playRound(P, page, 'c3-ghost');
	ok(r && r.done && r.result && r.result.mine > 0, `the round ends at the gate: ${r && JSON.stringify(r.result)}`);
	await page.waitForTimeout(800);
	const m1 = await modal(page);
	ok(m1 && m1.id === 'CHALLENGE_RESULT', 'the result card (no election)');
	await shot(page, 'c4-result');
	const ev = (await P.probe()).evolutions;
	ok(ev === 0, 'no election happened in the round');
	await tapModalButton(P, page, 0);
	const sh1 = await drawerMsg(page);
	log(`  share: ${JSON.stringify(sh1)}`);
	ok(sh1.kind === 'challenge' && /\/s\/[a-z]+-challenge\/\?via=[a-z]+#r=[a-z0-9]{8}&k=challenge&l=[a-z]+&s=31337&t=\d+&vs=300$/.test(sh1.msg), 'the drawer: the return link carries my time and vs=300');
	await shot(page, 'c5-sent');
	await tapModalButton(P, page, 1);
	await page.waitForTimeout(1500);
	r = await round(page);
	const s = await P.probe();
	ok(r && !r.inRound && s.mode === 'pick', `back to the own game (a new player: the picker): ${s.mode}`);
	await shot(page, 'c6-back');
	ok(!errors.length, `page errors: ${errors.length ? JSON.stringify(errors.slice(0, 3)) : 'none'}`);
	await ctx.close();
}

// the daily round is off in content (flags.dailyRound, Bar 2026-10-02): its section runs only when asked for
// (`only` = daily) on a build with the flag on
if (only === 'daily') {
	log('daily');
	const { ctx, page, P, errors } = await open('');
	let r = await round(page);
	await shot(page, 'd1-picker');
	ok(r && r.daily, `the picker shows the daily entry (#${r && r.n}, played ${r && r.played})`);
	if (r && r.daily) {
		await P.tapAt(P.css(r.daily[0], r.daily[1]));
		await page.waitForTimeout(900);
		const m0 = await modal(page);
		ok(m0 && m0.id === 'DAILY', 'the daily card');
		await shot(page, 'd2-card');
		await tapModalButton(P, page, 0);
		r = await round(page);
		ok(r && r.inRound && r.kind === 'daily', `the daily round: ${r && r.leader}`);
		await P.tapAt(P.hat());
		await page.waitForTimeout(800);
		r = await playRound(P, page, 'd3-chip');
		ok(r && r.done, `the daily round ends at the gate: ${r && JSON.stringify(r.result)}`);
		await page.waitForTimeout(800);
		const m1 = await modal(page);
		ok(m1 && m1.id === 'DAILY_RESULT', 'the daily result card');
		await shot(page, 'd4-result');
		await tapModalButton(P, page, 0);
		const sh2 = await drawerMsg(page);
		log(`  share (${sh2.kind}):\n${sh2.msg}`);
		ok(sh2.kind === 'daily' && sh2.msg.startsWith('עוד סבב #') && /\/s\/daily\/\?via=[a-z]+#r=[a-z0-9]{8}&k=daily$/.test(sh2.msg), 'the drawer: the grid text starts with a Hebrew word, the daily stub link last');
		await tapModalButton(P, page, 1);
		await page.waitForTimeout(1500);
		r = await round(page);
		ok(r && !r.inRound && r.played, 'today is played, back to the own game');
		await shot(page, 'd5-back');
		if (r && r.daily) {
			await P.tapAt(P.css(r.daily[0], r.daily[1]));
			await page.waitForTimeout(900);
			await shot(page, 'd6-card-played');
		}
	}
	ok(!errors.length, `page errors: ${errors.length ? JSON.stringify(errors.slice(0, 3)) : 'none'}`);
	await ctx.close();
}
if (only === '' || only === 'offer') {
	// 3. the offer: an election in the player's own game (the dev election, window.odDevElect), the
	//    after-election picker (its daily entry), the "אתגר חבר" toast after the pick, the offer card
	log('offer');
	const { ctx, page, P, errors } = await open('');
	const pickCell = async (id) => {
		const pk = await page.evaluate(() => window.odPick || null);
		const c = pk && pk.cells && pk.cells.find((x) => x[2] === id);
		if (c) { await P.tapAt(P.css(c[0], c[1])); await page.waitForTimeout(400); await P.tapAt(P.css(c[0], c[1])); }   // the ballot booth (ADR 0007): a tap chooses the slip, a second tap votes
		await page.waitForTimeout(2500);
	};
	await pickCell('bibi');
	for (let i = 0; i < 12; i++) { await P.tapAt(P.hat()); await page.waitForTimeout(120); }
	await page.waitForTimeout(3000);
	await page.evaluate(() => { window.odDevElect = 1; });
	for (let i = 0; i < 60; i++) {
		const st = await page.evaluate(() => ({ pick: window.odPick || null, flash: window.odFlash || null }));
		if (st.pick && st.pick.open && st.pick.variant === 'after') break;
		if (st.flash && st.flash.open && st.flash.next) { await P.tapAt(P.css(st.flash.next[0], st.flash.next[1])); }
		await page.waitForTimeout(1000);
	}
	await page.waitForTimeout(1500);
	const r = await round(page);
	ok(r && !r.daily, 'the after-election picker has no daily entry (the daily round is off)');
	await shot(page, 'o1-picker-after');
	await pickCell('bibi');
	// the undo chip holds the lane toasts for 5 s of wall time; then the offer's toast docks
	await page.waitForFunction(() => { const h = window.odDev && window.odDev.hud; return h && !h.undo.on && h.toast && h.toast.length === 4; }, null, { timeout: 20000 }).catch(() => {});
	const hud = await page.evaluate(() => (window.odDev && window.odDev.hud) || {});
	// (no shot here: a swiftshader screenshot outlasts the toast; o2 is shot by the "toast" variant)
	if (process.env.OD_TOAST_SHOT) await shot(page, 'o2-offer-toast');
	if (hud.toast && hud.toast.length === 4) {
		await P.tapAt(P.css(hud.toast[0] + hud.toast[2] / 2, hud.toast[1] + hud.toast[3] / 2));
		await page.waitForTimeout(900);
	}
	log(`  toast ${JSON.stringify(hud.toast)}; after the tap: modal ${JSON.stringify(await modal(page))}`);
	const m = await modal(page);
	ok(m && m.id === 'CHALLENGE_OFFER', `the toast opens the offer card (${m && m.id})`);
	await shot(page, 'o3-offer');
	if (m && m.id === 'CHALLENGE_OFFER') {
		await tapModalButton(P, page, 0);
		const sh3 = await drawerMsg(page);
		log(`  share: ${JSON.stringify(sh3)}`);
		ok(sh3.kind === 'challenge' && /\/s\/bibi-challenge\/\?via=[a-z]+#r=[a-z0-9]{8}&k=challenge&l=bibi&s=\d+&t=\d+$/.test(sh3.msg), 'the drawer: the challenge link');
		await shot(page, 'o4-offer-sent');
	}
	ok(!errors.length, `page errors: ${errors.length ? JSON.stringify(errors.slice(0, 3)) : 'none'}`);
	await ctx.close();
}
await browser.close();
log(failed ? `ROUNDS_WEB: FAIL (${failed})` : 'ROUNDS_WEB: PASS');
process.exit(failed ? 1 : 0);
