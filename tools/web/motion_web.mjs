// Motion check in the runtime origin (animator, 2026-09-29; wave B 2026-09-30): frame strips of
// - Bibi's court-day exit and return (the startle, the zip left, the hat on his mark, the fetch, the land);
// - the brawl cloud's boil (the stage cue and the inline cloud in T3);
// - the leader swap (wave B): the walk-in after a pick and the walk-out on the old stage before the EVOLVE_TX card
//   (the ceremony is forced with the dev flag window.odDevElect = 1, no 61 gate);
// - the ticker's page roll (M1) and its reduced-motion cross-fade.
// The game runs at 1/SLOW speed (&slow=N, Engine.time_scale) so a headless screenshot every ~100 ms of
// wall time is a frame every few ms of game time; each frame is saved with its game-time stamp (device
// px: one art px is k px).
//   node tools/web/motion_web.mjs <url> <out dir> [WxH@DPR,...]
//   MOTION_ONLY=walk,ticker MOTION_VARIANTS=rm node tools/web/motion_web.mjs ...   (sections: court, brawl,
//   walk, ticker; MOTION_SLOW_WALK / MOTION_SLOW_TICKER raise the slow-down on a loaded machine). The
//   engine-rendered ticker strip (16 ms steps): game/tests/dev/ticker_strip.gd.
// Serve build/web first (python3 -m http.server --directory build/web). Each device runs the court, the
// walk and the ticker twice (motion, then prefers-reduced-motion: the fades) and the brawl once.
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const [base, out, list = '390x844@2'] = process.argv.slice(2);
const fs = await import('node:fs');
fs.mkdirSync(out, { recursive: true });
const SLOW = 40;
const ONLY = (process.env.MOTION_ONLY || 'court,brawl,walk,ticker').split(',');
const VARIANTS = (process.env.MOTION_VARIANTS || 'motion,rm').split(',').map((v) => v === 'rm');   // walk and ticker
const DEVICES = list.split(',').map((s) => {
	const [wh, dpr] = s.split('@');
	const [w, h] = wh.split('x').map(Number);
	return { name: `${wh}@${dpr}`, w, h, dpr: Number(dpr), mobile: w < h };
});
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
let failed = 0;
const check = (ok, msg) => { console.log(`  ${ok ? 'ok  ' : 'FAIL'}  ${msg}`); if (!ok) failed++; };

async function open(d, query, reduced) {
	const ctx = await browser.newContext({ viewport: { width: d.w, height: d.h }, deviceScaleFactor: d.dpr, isMobile: d.mobile,
		hasTouch: d.mobile, reducedMotion: reduced ? 'reduce' : 'no-preference' });
	const page = await ctx.newPage();
	const errors = [];
	page.on('pageerror', (e) => errors.push(e.message));
	const cdp = await ctx.newCDPSession(page);
	const tap = async (x, y, id = 1) => {
		if (d.mobile) {
			await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id }] });
			await page.waitForTimeout(40);
			await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
		} else {
			await page.mouse.move(x, y);
			await page.mouse.down();
			await page.waitForTimeout(40);
			await page.mouse.up();
		}
	};
	await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1&${query}`);
	await page.waitForSelector('#od-sound', { state: 'visible', timeout: 60000 });
	await page.click('#od-sound');
	await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
	const disp = await page.evaluate(() => window.odDisplay);
	check(disp.reducedMotion === reduced, `the game follows prefers-reduced-motion: ${reduced ? 'reduce' : 'no-preference'} (${disp.reducedMotion})`);
	const cv = await page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { x: r.x, y: r.y }; });
	const css = (lx, ly) => [cv.x + lx * disp.f / d.dpr, cv.y + ly * disp.f / d.dpr];
	const probe = () => page.evaluate(() => window.odDev || null);
	return { ctx, page, errors, tap, disp, css, probe };
}

// Captures `n` frames of a logical-px rect as fast as the renderer allows; returns [{t, file}].
// `untilMs` > 0: keep going until that much game time is covered (n is then the cap), so the strip
// covers the motion whatever a screenshot costs on the machine.
async function strip(o, prefix, rect, n, gapMs = 60, slow = SLOW, untilMs = 0) {
	const [x0, y0] = o.css(rect[0], rect[1]);
	const [x1, y1] = o.css(rect[0] + rect[2], rect[1] + rect[3]);
	const clip = { x: x0, y: y0, width: x1 - x0, height: y1 - y0 };
	const t0 = Date.now();
	const frames = [];
	for (let i = 0; i < n; i++) {
		const t = (Date.now() - t0) / slow;
		if (untilMs > 0 && frames.length > 0 && frames.at(-1).t >= untilMs) break;
		const file = `${prefix}-${String(i).padStart(3, '0')}.png`;
		await o.page.screenshot({ path: file, clip });
		frames.push({ t: Math.round(t), file });
		await o.page.waitForTimeout(gapMs);
	}
	return frames;
}

// A fresh game opens LEADER_PICK: tap `id`'s tile (window.odDev.pick, viewport logical px).
async function pickTile(o, id, slow = SLOW) {
	await o.page.waitForFunction(() => window.odDev && window.odDev.pick && window.odDev.pick.open, null, { timeout: 600000 });
	await o.page.waitForTimeout(400 * slow);   // the picker's 300 ms tap-burst guard, in game time
	const s = await o.probe();
	const c = (s.pick.cells || []).find((x) => x[2] === id);
	if (!c) return false;
	const [x, y] = o.css(c[0], c[1]);
	await o.tap(x, y, 7);
	return true;
}

// After a pick: the stage is back (the pre-tap state or the round).
async function untilStage(o) {
	await o.page.waitForFunction(() => window.odDev && window.odDev.mode !== 'pick', null, { timeout: 600000 }).catch(() => {});
}

// The whole stage column, full canvas width: a walk starts and ends off the canvas.
const stageRect = (disp) => [0, disp.stageY + 160, disp.logical[0], disp.lowerY - disp.stageY - 160];

for (const d of DEVICES) {
	if (ONLY.includes('court')) {
		for (const reduced of [false, true]) {
			const tag = `${d.name}${reduced ? '-rm' : ''}`;
			console.log(`court ${tag}`);
			const o = await open(d, `court=2&slow=${SLOW}&grant=50000`, reduced);
			const { disp } = o;
			// the whole stage: the thermometer, the courthouse window, the Magician and the hat
			const stage = [disp.sx ?? disp.ox, disp.stageY + 160, 720, disp.lowerY - disp.stageY - 160];   // the stage column (mobile-first §4.1)
			// leader select: a fresh game opens the picker first; the court is Bibi's
			await pickTile(o, 'bibi', SLOW);
			await untilStage(o);
			const [hx, hy] = o.css(disp.hat[0], disp.hat[1]);
			await o.tap(hx, hy, 100);   // title → main; the court day is already running
			const frames = await strip(o, `${out}/court-${tag}`, stage, reduced ? 70 : 110, 10);
			fs.writeFileSync(`${out}/court-${tag}.json`, JSON.stringify({ k: disp.k, slow: SLOW, frames }, null, 1));
			check(frames.length > 0, `${frames.length} frames over ${frames.at(-1).t} ms of game time`);
			check(o.errors.length === 0, `no page errors ${o.errors.length ? JSON.stringify(o.errors.slice(0, 3)) : ''}`);
			await o.ctx.close();
		}
	}
	if (ONLY.includes('brawl')) {
		console.log(`brawl ${d.name}`);
		const o = await open(d, `chat=3&slow=${SLOW}&grant=50000`, false);
		const { disp } = o;
		const [hx, hy] = o.css(disp.hat[0], disp.hat[1]);
		await o.tap(hx, hy, 100);
		await o.page.waitForTimeout(800);
		// the stage cue: ChatView BRAWL_CUE (8, 4, 144, 104) tall-local = stage-local + STAGE.y (160)
		const cue = [disp.ox, disp.stageY + 160, 176, 128];
		const frames = await strip(o, `${out}/brawl-cue-${d.name}`, cue, 30, 10);
		fs.writeFileSync(`${out}/brawl-cue-${d.name}.json`, JSON.stringify({ k: disp.k, slow: SLOW, frames }, null, 1));
		check(frames.length === 30, `brawl cue: ${frames.length} frames over ${frames.at(-1).t} ms of game time`);
		check(o.errors.length === 0, `no page errors ${o.errors.length ? JSON.stringify(o.errors.slice(0, 3)) : ''}`);
		await o.ctx.close();
	}
	if (ONLY.includes('walk')) {
		// wave B: the leader swap. SLOW 40: a stage screenshot every ~0.5 s of wall time is ~12 ms of game time.
		const WS = Number(process.env.MOTION_SLOW_WALK || 40);   // raise it on a loaded machine (each screenshot is slower)
		for (const reduced of VARIANTS) {
			const tag = `${d.name}${reduced ? '-rm' : ''}`;
			console.log(`walk ${tag}`);
			const o = await open(d, `slow=${WS}&grant=50000`, reduced);
			const { disp } = o;
			const stage = stageRect(disp);
			// the walk-in: the picker's commit (≈ 520 ms), then 640 ms of walk (RM: a 150 ms fade)
			check(await pickTile(o, 'bennett', WS), 'the picker is open and Bennett\'s tile is tapped');
			const inFrames = await strip(o, `${out}/walk-in-${tag}`, stage, 90, 0, WS, reduced ? 650 : 1250);
			fs.writeFileSync(`${out}/walk-in-${tag}.json`, JSON.stringify({ k: disp.k, slow: WS, frames: inFrames }, null, 1));
			await untilStage(o);
			let s = await o.probe();
			check(s && s.leader === 'bennett' && s.mode === 'title', `Bennett's round, pre-tap (leader ${s && s.leader}, mode ${s && s.mode})`);
			check(inFrames.at(-1).t >= (reduced ? 650 : 1250), `walk-in: ${inFrames.length} frames over ${inFrames.at(-1).t} ms of game time`);
			// tap 1 starts the round; then the forced ceremony: the walk-out is its f0, on the old stage,
			// before the card (state-graph §9 rev 2); the strip covers the walk, the empty beat and the dim
			const [hx, hy] = o.css(disp.hat[0], disp.hat[1]);
			await o.tap(hx, hy, 8);
			await o.page.waitForTimeout(1500);
			await o.page.evaluate(() => { window.odDevElect = 1; });
			await o.page.waitForFunction(() => window.odDevElect === 0, null, { timeout: 600000 });   // taken: EVOLVE_TX's f0
			const outFrames = await strip(o, `${out}/walk-out-${tag}`, stage, 70, 0, WS, reduced ? 450 : 950);
			fs.writeFileSync(`${out}/walk-out-${tag}.json`, JSON.stringify({ k: disp.k, slow: WS, frames: outFrames }, null, 1));
			await o.page.waitForFunction(() => window.odDev && (window.odDev.mode === 'pick' || window.odDev.modal !== ''), null, { timeout: 600000 }).catch(() => {});
			s = await o.probe();
			check(s && (s.mode === 'pick' || s.modal !== ''), `after the walk-out: the flash or the picker (mode ${s && s.mode}, modal ${s && s.modal})`);
			check(o.errors.length === 0, `no page errors ${o.errors.length ? JSON.stringify(o.errors.slice(0, 3)) : ''}`);
			await o.ctx.close();
		}
	}
	if (ONLY.includes('ticker')) {
		// M1: the ticker row, SLOW 20 (a frame every ~10-20 ms of game time; 300 frames hold at least one page change)
		const TS = Number(process.env.MOTION_SLOW_TICKER || 20);
		for (const reduced of VARIANTS) {
			const tag = `${d.name}${reduced ? '-rm' : ''}`;
			console.log(`ticker ${tag}`);
			const o = await open(d, `slow=${TS}&grant=50000`, reduced);
			check(await pickTile(o, 'deri', TS), 'Deri\'s tile is tapped');
			await untilStage(o);
			const [hx, hy] = o.css(o.disp.hat[0], o.disp.hat[1]);
			await o.tap(hx, hy, 9);
			await o.page.waitForTimeout(1500);
			const disp = await o.page.evaluate(() => window.odDisplay);
			const tk = disp.ticker;
			check(tk && tk.mode === 'page' && tk.transition === (reduced ? 'fade' : 'roll'), `odDisplay.ticker: ${JSON.stringify(tk)}`);
			const row = [disp.ox + tk.clipX - 8, disp.lowerY + tk.clipY, tk.clipW + 16, tk.clipH];
			const frames = await strip(o, `${out}/ticker-${tag}`, row, 400, 0, TS, 6000);   // 6 s: at least one page change
			fs.writeFileSync(`${out}/ticker-${tag}.json`, JSON.stringify({ k: disp.k, slow: TS, frames, clip: row }, null, 1));
			check(frames.at(-1).t >= 6000, `ticker: ${frames.length} frames over ${frames.at(-1).t} ms of game time`);
			check(o.errors.length === 0, `no page errors ${o.errors.length ? JSON.stringify(o.errors.slice(0, 3)) : ''}`);
			await o.ctx.close();
		}
	}
}
await browser.close();
console.log(failed ? `MOTION_WEB: ${failed} FAILED` : 'MOTION_WEB: PASS');
process.exit(failed ? 1 : 0);
