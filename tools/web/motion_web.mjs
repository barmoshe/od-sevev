// Motion check in the runtime origin (animator, 2026-09-29): frame strips of Bibi's court-day exit
// and return (the startle, the zip left, the hat on his mark, the fetch, the land) and of the brawl
// cloud's boil (the stage cue and the inline cloud in T3). The game runs at 1/SLOW speed
// (&slow=N, Engine.time_scale) so a headless screenshot every ~100 ms of wall time is a frame every
// few ms of game time; each frame is saved with its game-time stamp (device px: one art px is k px).
//   node tools/web/motion_web.mjs <url> <out dir> [WxH@DPR,...]
// Serve build/web first (python3 -m http.server --directory build/web). Runs each device twice for the
// court (motion, then prefers-reduced-motion: the fades) and once for the brawl.
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const [base, out, list = '390x844@2'] = process.argv.slice(2);
const fs = await import('node:fs');
fs.mkdirSync(out, { recursive: true });
const SLOW = 40;
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
	return { ctx, page, errors, tap, disp, css };
}

// Captures `n` frames of a logical-px rect as fast as the renderer allows; returns [{t, file}].
async function strip(o, prefix, rect, n, gapMs = 60) {
	const [x0, y0] = o.css(rect[0], rect[1]);
	const [x1, y1] = o.css(rect[0] + rect[2], rect[1] + rect[3]);
	const clip = { x: x0, y: y0, width: x1 - x0, height: y1 - y0 };
	const t0 = Date.now();
	const frames = [];
	for (let i = 0; i < n; i++) {
		const t = (Date.now() - t0) / SLOW;
		const file = `${prefix}-${String(i).padStart(3, '0')}.png`;
		await o.page.screenshot({ path: file, clip });
		frames.push({ t: Math.round(t), file });
		await o.page.waitForTimeout(gapMs);
	}
	return frames;
}

for (const d of DEVICES) {
	for (const reduced of [false, true]) {
		const tag = `${d.name}${reduced ? '-rm' : ''}`;
		console.log(`court ${tag}`);
		const o = await open(d, `court=2&slow=${SLOW}&grant=50000`, reduced);
		const { disp } = o;
		// the whole stage: the thermometer, the courthouse window, the Magician and the hat
		const stage = [disp.ox, disp.stageY + 160, 720, disp.lowerY - disp.stageY - 160];
		const [hx, hy] = o.css(disp.hat[0], disp.hat[1]);
		await o.tap(hx, hy, 100);   // title → main; the court day is already running
		const frames = await strip(o, `${out}/court-${tag}`, stage, reduced ? 70 : 110, 10);
		fs.writeFileSync(`${out}/court-${tag}.json`, JSON.stringify({ k: disp.k, slow: SLOW, frames }, null, 1));
		check(frames.length > 0, `${frames.length} frames over ${frames.at(-1).t} ms of game time`);
		check(o.errors.length === 0, `no page errors ${o.errors.length ? JSON.stringify(o.errors.slice(0, 3)) : ''}`);
		await o.ctx.close();
	}
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
await browser.close();
console.log(failed ? `MOTION_WEB: ${failed} FAILED` : 'MOTION_WEB: PASS');
process.exit(failed ? 1 : 0);
