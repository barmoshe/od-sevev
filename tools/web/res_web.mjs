// Resolution check in the runtime origin (integer art scaling, game/scripts/core/display.gd): plays
// the web build in headless Chromium at real phone sizes and DPRs, passes the disclaimer, taps the
// Magician three times and buys the first money source by touch, and saves a screenshot at each
// step (device px, so one art px is k screenshot px). `python3 tools/lib/pixel_runs.py` measures them.
//   node tools/web/res_web.mjs <url> <out dir> [before|after] [WxH@DPR,...]
// "before" adds &forkscale=1: the same build with the fork's fractional stretch. The device list
// defaults to 390x844 at DPR 2 and 3 plus a 1280x800 desktop window (desktop = DPR 1, no touch
// emulation of a phone).
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const [base, out, tag = 'after', list = '390x844@2,390x844@3,1280x800@1'] = process.argv.slice(2);
const fs = await import('node:fs');
fs.mkdirSync(out, { recursive: true });
const DEVICES = list.split(',').map((s) => {
	const [wh, dpr] = s.split('@');
	const [w, h] = wh.split('x').map(Number);
	const mobile = w < h;
	return { name: `${mobile ? '' : 'desktop-'}${wh}@${dpr}`, w, h, dpr: Number(dpr), mobile };
});
const url = `${base}${base.includes('?') ? '&' : '?'}dev=1&grant=500${tag === 'before' ? '&forkscale=1' : ''}`;
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
let failed = 0;
const check = (ok, msg) => { console.log(`  ${ok ? 'ok  ' : 'FAIL'}  ${msg}`); if (!ok) failed++; };
for (const d of DEVICES) {
	console.log(`${tag} ${d.name}`);
	const ctx = await browser.newContext({ viewport: { width: d.w, height: d.h }, deviceScaleFactor: d.dpr, isMobile: d.mobile, hasTouch: true });
	// records when each cue file was played on the Audio's own clock (window.odCueLogMs, set just
	// before window.odCueLog) and the frame times (a slow software-GL frame is worth reporting)
	await ctx.addInitScript(() => {
		window.__cueG = {};
		window.__frames = [];
		let v = [];
		Object.defineProperty(window, 'odCueLog', { configurable: true, get: () => v, set: (a) => {
			const ms = window.odCueLogMs || [];
			a.forEach((f, i) => { if (!(f in window.__cueG) && ms[i] !== undefined) window.__cueG[f] = ms[i]; });
			v = a;
		} });
		const raf = (t) => { window.__frames.push(t); if (window.__frames.length > 1200) window.__frames.shift(); requestAnimationFrame(raf); };
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
	// a desktop window gets the shell's 390-CSS phone frame (game/web/shell.html odFit)
	const fr = await page.evaluate(() => window.odFrame || { framed: false, left: 0, top: 0 });
	check(canvas[0] === (fr.framed ? Math.round(390 * d.dpr) : Math.floor(d.w * d.dpr)), `the backing store is CSS × DPR wide (${canvas[0]}${fr.framed ? ', phone frame' : ''})`);
	if (tag !== 'before') {
		// the crisp rule (display.gd crisp_k): the largest multiple of 2 or 3 ≤ the k that fits
		const fit = Math.min(Math.floor(canvas[0] / 180), Math.floor(canvas[1] / 267));
		let ck = fit;
		while (ck > 1 && ck % 2 !== 0 && ck % 3 !== 0) ck--;
		check(disp.integer && disp.k === ck, `k = crisp(min(floor(W/180), floor(H/267))) = crisp(${fit}) = ${disp.k}`);
	}
	await shot('title');
	const css = (lx, ly) => [fr.left + lx * disp.f / d.dpr, fr.top + ly * disp.f / d.dpr];
	// LEADER_PICK replaced the title (rtl-map §8): pick הפתעה first, so tap 1 lands on the pre-tap stage
	const pk = await page.evaluate(() => window.odPick || null);
	if (pk && pk.open) {
		const c = pk.cells.find((q) => q[2] === '') || pk.cells[0];
		await page.waitForTimeout(500);
		const [px, py] = css(c[0], c[1]);
		await tap(px, py, 90);
		await page.waitForFunction(() => !(window.odPick && window.odPick.open), null, { timeout: 8000 }).catch(() => {});
		await page.waitForTimeout(1500);
	}
	const [hx, hy] = css(disp.hat[0], disp.hat[1]);
	// tap 1: the motif, and Dubi's first line only after its musicalSeconds (O-A3), measured on
	// the Audio's clock (exact to one frame; game time, which Godot slows on frames over 8/60 s)
	await tap(hx, hy, 100);
	await page.waitForFunction(() => 'dubiSquawk_D_down.res' in window.__cueG, null, { timeout: 10000 }).catch(() => {});
	const cue = await page.evaluate(() => {
		const m = Object.keys(window.__cueG).find((f) => f.startsWith('stinger_motif'));
		const fr = window.__frames.slice(-60);
		let worst = 0;
		for (let i = 1; i < fr.length; i++) worst = Math.max(worst, fr[i] - fr[i - 1]);
		return { motif: m ? window.__cueG[m] : null, squawk: window.__cueG['dubiSquawk_D_down.res'] ?? null, worstMs: worst,
			meanMs: fr.length > 1 ? (fr[fr.length - 1] - fr[0]) / (fr.length - 1) : 0 };
	});
	check(cue.motif !== null, 'tapping the Magician plays the motif');
	const gap = (cue.squawk - cue.motif) / 1000;
	check(cue.squawk !== null && gap >= 2.327 && gap <= 2.328 + Math.min(cue.worstMs, 8000 / 60) / 1000,
		`Dubi's first squawk starts at the motif's musicalSeconds 2.328 s: ${gap.toFixed(3)} s on the Audio clock (frames ${cue.meanMs.toFixed(0)} ms mean, ${cue.worstMs.toFixed(0)} ms worst)`);
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
