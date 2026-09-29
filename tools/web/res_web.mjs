// Resolution check in the runtime origin (integer art scaling, game/scripts/core/display.gd): plays
// the web build in headless Chromium at real phone sizes and DPRs, passes the disclaimer, taps the
// Magician three times and buys the first money source by touch, and saves a screenshot at each
// step (device px, so one art px is k screenshot px). `python3 tools/lib/pixel_runs.py` measures them.
//   node tools/web/res_web.mjs <url> <out dir> [before]
// "before" adds &forkscale=1: the same build with the fork's fractional stretch.
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const [base, out, tag = 'after'] = process.argv.slice(2);
const fs = await import('node:fs');
fs.mkdirSync(out, { recursive: true });
const DEVICES = [
	{ name: '390x844@2', w: 390, h: 844, dpr: 2, mobile: true },
	{ name: '390x844@3', w: 390, h: 844, dpr: 3, mobile: true },
	{ name: 'desktop-1280x800@1', w: 1280, h: 800, dpr: 1, mobile: false },
];
const url = `${base}${base.includes('?') ? '&' : '?'}dev=1&grant=500${tag === 'before' ? '&forkscale=1' : ''}`;
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
let failed = 0;
const check = (ok, msg) => { console.log(`  ${ok ? 'ok  ' : 'FAIL'}  ${msg}`); if (!ok) failed++; };
for (const d of DEVICES) {
	console.log(`${tag} ${d.name}`);
	const ctx = await browser.newContext({ viewport: { width: d.w, height: d.h }, deviceScaleFactor: d.dpr, isMobile: d.mobile, hasTouch: true });
	// timestamps each cue file when the engine publishes window.odCueLog (in-page clock), and the
	// frame times, so a slow software-GL frame is visible next to the O-A3 gap it blurs
	await ctx.addInitScript(() => {
		window.__cueT = {};
		window.__frames = [];
		let v = [];
		Object.defineProperty(window, 'odCueLog', { configurable: true, get: () => v, set: (a) => {
			const t = performance.now();
			for (const f of a) if (!(f in window.__cueT)) window.__cueT[f] = t;
			v = a;
		} });
		const raf = (t) => { window.__frames.push(t); if (window.__frames.length > 120) window.__frames.shift(); requestAnimationFrame(raf); };
		requestAnimationFrame(raf);
	});
	const page = await ctx.newPage();
	const errors = [];
	page.on('pageerror', (e) => errors.push(e.message));
	const cdp = await ctx.newCDPSession(page);
	const tap = async (x, y, id = 1) => {
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id }] });
		await page.waitForTimeout(60);
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
	};
	await page.goto(url);
	await page.waitForSelector('#od-sound', { state: 'visible', timeout: 60000 });
	await page.tap('#od-sound');
	await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 90000 });
	await page.waitForTimeout(1500);
	const shot = async (step) => page.screenshot({ path: `${out}/${tag}-${d.name}-${step}.png` });
	const disp = await page.evaluate(() => window.odDisplay);
	const canvas = await page.evaluate(() => { const c = document.querySelector('canvas'); return [c.width, c.height]; });
	console.log(`  canvas ${canvas.join('x')} device px, odDisplay ${JSON.stringify(disp)}`);
	check(canvas[0] === Math.floor(d.w * d.dpr), `the backing store is CSS × DPR wide (${canvas[0]})`);
	if (tag !== 'before') {
		check(disp.integer && disp.k === Math.min(Math.floor(canvas[0] / 180), Math.floor(canvas[1] / 267)), `k = floor(W/180) (height-bound on landscape): ${disp.k}`);
	}
	await shot('title');
	const css = (lx, ly) => [lx * disp.f / d.dpr, ly * disp.f / d.dpr];
	const [hx, hy] = css(disp.hat[0], disp.hat[1]);
	// tap 1: the motif, and Dubi's first line only after its musicalSeconds (O-A3). The log is
	// published every 250 ms of game time, on a frame: the gap is good to ±(250 ms + one frame).
	await tap(hx, hy, 100);
	await page.waitForFunction(() => 'dubiSquawk_D_down.res' in window.__cueT, null, { timeout: 8000 }).catch(() => {});
	const cue = await page.evaluate(() => {
		const m = Object.keys(window.__cueT).find((f) => f.startsWith('stinger_motif'));
		const fr = window.__frames;
		return { motif: m ? window.__cueT[m] : null, squawk: window.__cueT['dubiSquawk_D_down.res'] ?? null,
			frameMs: fr.length > 1 ? (fr[fr.length - 1] - fr[0]) / (fr.length - 1) : 0 };
	});
	check(cue.motif !== null, 'tapping the Magician plays the motif');
	const gap = (cue.squawk - cue.motif) / 1000;
	const slack = 0.25 + cue.frameMs / 1000;
	check(cue.squawk !== null && gap > 2.33 - slack && gap < 2.33 + slack,
		`Dubi's first squawk follows the motif by its 2.33 s (measured ${gap.toFixed(2)} s, ±${slack.toFixed(2)} at ${cue.frameMs.toFixed(0)} ms/frame)`);
	for (let i = 1; i < 3; i++) {
		await tap(hx, hy + 6 * i, 100 + i);
		await page.waitForTimeout(350);
	}
	await page.waitForTimeout(1200);
	await shot('main');
	const buys = (log) => log.filter((f) => f.startsWith('buy')).length;
	const before = buys(await page.evaluate(() => (window.odCueLog || []).slice()));
	const lower = await page.evaluate(() => window.odDisplay.lowerY);
	const [cx, cy] = css(disp.ox + 560, lower + 84 + 60);   // card 1 (rtl-map §6.1), the name area
	await tap(cx, cy, 200);
	await page.waitForTimeout(900);
	const log2 = await page.evaluate(() => (window.odCueLog || []).slice());
	check(buys(log2) > before, `tapping card 1 buys the first money source (${log2.filter((f) => f.startsWith('buy')).join(', ')})`);
	await shot('bought');
	check(errors.length === 0, `no page errors ${errors.length ? JSON.stringify(errors.slice(0, 3)) : ''}`);
	await ctx.close();
}
await browser.close();
console.log(failed ? `RES_WEB: ${failed} FAILED` : 'RES_WEB: PASS');
process.exit(failed ? 1 : 0);
