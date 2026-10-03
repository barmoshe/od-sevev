// View check in the runtime origin for Dubi's news flash (O3b), the Cottage Index cup and the
// desktop phone frame (game-developer views, 2026-09-29). Plays the web build in headless Chromium,
// passes the disclaimer, taps the Magician (the dev flag &flash=1 opens the round-1 flash on that
// tap), closes the flash with "לסבב הבחירות הבא", taps the cottage cup, and saves a screenshot at
// each step (device px: one art px is k screenshot px).
//   node tools/web/views_web.mjs <url> <out dir> [WxH@DPR,...]
// Serve build/web first (python3 -m http.server --directory build/web). Wide windows are desktop
// (a mouse: the shell's phone frame); portrait ones are phones (touch, no frame).
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const [base, out, list = '390x844@2,390x844@3,1440x900@1'] = process.argv.slice(2);
const fs = await import('node:fs');
fs.mkdirSync(out, { recursive: true });
const DEVICES = list.split(',').map((s) => {
	const [wh, dpr] = s.split('@');
	const [w, h] = wh.split('x').map(Number);
	const mobile = w < h;
	return { name: `${mobile ? '' : 'desktop-'}${wh}@${dpr}`, w, h, dpr: Number(dpr), mobile };
});
const url = `${base}${base.includes('?') ? '&' : '?'}dev=1&grant=5000000&flash=1`;
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
let failed = 0;
const check = (ok, msg) => { console.log(`  ${ok ? 'ok  ' : 'FAIL'}  ${msg}`); if (!ok) failed++; };
for (const d of DEVICES) {
	console.log(d.name);
	const ctx = await browser.newContext({ viewport: { width: d.w, height: d.h }, deviceScaleFactor: d.dpr, isMobile: d.mobile, hasTouch: d.mobile });
	const page = await ctx.newPage();
	const errors = [];
	page.on('pageerror', (e) => errors.push(e.message));
	const cdp = await ctx.newCDPSession(page);
	const tap = async (x, y, id = 1) => {
		if (d.mobile) {
			await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id }] });
			await page.waitForTimeout(60);
			await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
		} else {
			await page.mouse.move(x, y);
			await page.mouse.down();
			await page.waitForTimeout(60);
			await page.mouse.up();
		}
	};
	await page.goto(url);
	await page.waitForSelector('#od-sound', { state: 'visible', timeout: 60000 });
	await page.click('#od-sound');
	await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 90000 });
	await page.waitForTimeout(1500);
	const shot = async (step) => page.screenshot({ path: `${out}/${d.name}-${step}.png` });
	const disp = await page.evaluate(() => window.odDisplay);
	const fr = await page.evaluate(() => window.odFrame);
	const cv = await page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { w: c.width, h: c.height, x: r.x, y: r.y, cw: r.width, ch: r.height }; });
	console.log(`  canvas ${cv.w}x${cv.h} at CSS (${cv.x}, ${cv.y}), odFrame ${JSON.stringify(fr)}, odDisplay k ${disp.k}`);
	check(fr.framed === !d.mobile, `the phone frame is ${d.mobile ? 'off on a phone' : 'on on a desktop window'}`);
	if (!d.mobile) {
		check(cv.w === Math.round(390 * d.dpr), `the frame's backing store is 390 CSS × DPR wide (${cv.w})`);
	} else {
		check(cv.w === Math.floor(d.w * d.dpr), `a phone's backing store is the window × DPR (${cv.w})`);
	}
	check(Math.abs(cv.cw * d.dpr - cv.w) < 1e-6 && Math.abs(cv.ch * d.dpr - cv.h) < 1e-6, 'the canvas box is exactly its backing store / DPR (no browser resample)');
	check(Math.abs(cv.x * d.dpr - Math.round(cv.x * d.dpr)) < 1e-6 && Math.abs(cv.y * d.dpr - Math.round(cv.y * d.dpr)) < 1e-6, 'the canvas sits on whole device px');
	// the crisp rule (display.gd crisp_k): the largest multiple of 2 or 3 ≤ the k that fits
	const fit = Math.min(Math.floor(cv.w / 180), Math.floor(cv.h / 267));
	let ck = fit;
	while (ck > 1 && ck % 2 !== 0 && ck % 3 !== 0) ck--;
	check(disp.integer && disp.k === ck, `k = crisp(min(floor(W/180), floor(H/267))) = crisp(${fit}) = ${disp.k}`);
	await shot('title');
	const css = (lx, ly) => [cv.x + lx * disp.f / d.dpr, cv.y + ly * disp.f / d.dpr];
	// LEADER_PICK replaced the title (rtl-map §8): pick הפתעה first, so tap 1 lands on the pre-tap stage
	const pk = await page.evaluate(() => window.odPick || null);
	if (pk && pk.open) {
		const c = pk.cells.find((q) => q[2] === '') || pk.cells[0];
		await page.waitForTimeout(500);
		const [px, py] = css(c[0], c[1]);
		await tap(px, py, 90);   // the ballot booth (ADR 0007): a tap chooses the slip, a second tap votes
		await page.waitForTimeout(400);
		await tap(px, py, 90);
		await page.waitForFunction(() => !(window.odPick && window.odPick.open), null, { timeout: 8000 }).catch(() => {});
		await page.waitForTimeout(1500);
	}
	const [hx, hy] = css(disp.hat[0], disp.hat[1]);
	await tap(hx, hy, 100);
	await page.waitForFunction(() => window.odFlash && window.odFlash.open, null, { timeout: 15000 }).catch(() => {});
	await page.waitForTimeout(1600);
	const fl = await page.evaluate(() => window.odFlash || null);
	check(fl && fl.open, `the news flash is open (art ×${fl ? fl.artScale : '?'})`);
	await shot('flash');
	const cue = await page.evaluate(() => (window.odCueLog || []).slice());
	check(cue.some((f) => f.startsWith('stinger_dubiFlash') || f.includes('dubiFlash')), `the dubiFlash head played (${cue.slice(-6).join(', ')})`);
	if (fl && fl.open) {
		const [nx, ny] = css(fl.next[0], fl.next[1]);
		await tap(nx, ny, 101);
		await page.waitForTimeout(700);
		check(!(await page.evaluate(() => window.odFlash && window.odFlash.open)), 'FLASH_NEXT closes it');
	}
	await page.waitForTimeout(600);
	await shot('cottage');
	const topY = disp.stageY - 20;   // _stage_y = top_y + 180 − 160
	const [cx, cy] = css(disp.ox + 668 + ((disp.cw || 720) - 720), topY + 48);   // the cup's 88×88 hit centre (rtl-map §2; R-anchored, mobile-first §4.1)
	await tap(cx, cy, 102);
	await page.waitForTimeout(700);
	await shot('cottage-tip');
	check(errors.length === 0, `no page errors ${errors.length ? JSON.stringify(errors.slice(0, 3)) : ''}`);
	await ctx.close();
}
await browser.close();
console.log(failed ? `VIEWS_WEB: ${failed} FAILED` : 'VIEWS_WEB: PASS');
process.exit(failed ? 1 : 0);
