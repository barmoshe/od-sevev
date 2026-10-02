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
		const s = await P.probe();
		log(`  gate (${why}): seats ${s.seats.effective}/${s.seats.gate}, run ${Math.round(s.runSec)}s`);
		if (why !== 'gate') return null;
		await shot(page, `${chipShot}-gate`);
		await P.tapAt(s.ctaAt ? P.css(s.ctaAt[0], s.ctaAt[1]) : P.col(360, P.st.disp.lowerY + 42));
		await page.waitForTimeout(900);
		const r = await round(page);
		if (r && r.done) return r;
	}
	return null;
}

if (only !== 'daily') {
	log('challenge');
	const { ctx, page, P, errors } = await open('#k=challenge&l=bennett&s=31337&t=300&r=abcd1234');
	await page.waitForFunction(() => window.odModal && window.odModal.open && window.odModal.id === 'CHALLENGE_INTRO', null, { timeout: 15000 }).catch(() => {});
	const m0 = await modal(page);
	ok(m0 && m0.id === 'CHALLENGE_INTRO', 'the link opens the challenge card');
	ok(await page.evaluate(() => location.hash === ''), 'the hash is consumed (a reload lands in the own game)');
	await shot(page, 'c1-intro');
	await page.waitForTimeout(400);
	await tapModalButton(P, page, 0);
	let r = await round(page);
	ok(r && r.inRound && r.leader === 'bennett' && r.seed === 31337, `the round: ${r && r.leader} seed ${r && r.seed}`);
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
	const copied = await page.evaluate(() => window.__copied || []);
	log(`  share text: ${JSON.stringify(copied[copied.length - 1] || '')}`);
	ok(copied.length > 0 && /#k=challenge&l=bennett&s=31337&t=\d+&r=[a-z0-9]{8}&vs=300/.test(copied[copied.length - 1]), 'the return link carries my time and vs=300');
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

if (only !== 'challenge') {
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
		const copied = await page.evaluate(() => window.__copied || []);
		log(`  share text:\n${copied[copied.length - 1] || ''}`);
		ok(copied.length > 0 && copied[copied.length - 1].startsWith('עוד סבב #'), 'the grid text starts with a Hebrew word');
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
await browser.close();
log(failed ? `ROUNDS_WEB: FAIL (${failed})` : 'ROUNDS_WEB: PASS');
process.exit(failed ? 1 : 0);
