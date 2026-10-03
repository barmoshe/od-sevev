// The pre-tap + HUD slice's screenshots (2026-09-30 manual test, fixes A2/A3/A7/B10/B12): the
// first picker, the pre-tap stage with the undo bar (≈ 1 s after the pick) and after it (≈ 7 s), the
// P0 hand (≈ 10 s),
// card 1 (tap 3), the picker after a forced election (the F9_PICK caption on its plate) and round
// 2's first second (the new name in Row A, the undo chip in the lane) and round 2 at ≈ 7 s (the fresh
// toast in the lane band, once the undo chip has gone), at each device.
// S18 (merge review M1, D62): hud.toast is sampled every 250 ms in the page from the pick to tap 1 and
// from round 2's pick to 7 s, and fails on any intersection with hud.leaderHit. M2 (S15): round 2
// starts with ≤ 5 ₪ in hand, and card 1 is a source card over the teaser rows. Shots are saved at half the device size (ImageMagick-free: a 2×2 box filter in JS).
//   node tools/web/pretap_shots.mjs <url> <out dir> [WxH@DPR,...] [leader] [prefix]
// Serve build/web first: python3 -m http.server 8833 --directory build/web
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const [base, out, list = '390x844@3,375x667@2,430x932@3', leader = 'bengvir', prefix = 'dev2-'] = process.argv.slice(2);
if (!base || !out) {
	console.log('usage: node tools/web/pretap_shots.mjs <url> <out dir> [WxH@DPR,...] [leader] [prefix]');
	process.exit(2);
}
fs.mkdirSync(out, { recursive: true });
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
let failed = 0;
for (const spec of list.split(',')) {
	const [wh, dprS] = spec.split('@');
	const [W, H] = wh.split('x').map(Number);
	const DPR = Number(dprS);
	const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: true, hasTouch: true });
	const page = await ctx.newPage();
	const errors = [];
	page.on('pageerror', (e) => errors.push(e.message));
	const cdp = await ctx.newCDPSession(page);
	const wait = (ms) => page.waitForTimeout(ms);
	let tid = 1;
	let disp;
	const refresh = async () => { disp = await page.evaluate(() => window.odDisplay); };
	const css = (x, y) => [x * disp.f / DPR, y * disp.f / DPR];
	const tap = async ([x, y], hold = 60) => {
		const id = tid++;
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id }] });
		await wait(hold);
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
	};
	// S18: the in-page sampler (odDev publishes at 4 Hz)
	const s18Start = () => page.evaluate(() => {
		const hit = (a, b) => a && b && a.length === 4 && b.length === 4 && a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
		if (window.__s18 && window.__s18.id) clearInterval(window.__s18.id);
		const t0 = performance.now();
		const S = { n: 0, seen: 0, bad: [], rects: [] };
		S.id = setInterval(() => {
			const h = (window.odDev && window.odDev.hud) || {};
			S.n++;
			if (h.toast && h.toast.length === 4) {
				S.seen++;
				const k = h.toast.map(Math.round).join(',');
				if (!S.rects.includes(k)) S.rects.push(k);
			}
			if (hit(h.toast, h.leaderHit)) S.bad.push([Math.round(performance.now() - t0), h.toast.map(Math.round), h.leaderHit.map(Math.round)]);
		}, 250);
		window.__s18 = S;
	});
	const s18Seen = () => page.evaluate(() => (window.__s18 || {}).seen || 0);
	const s18Stop = async (what) => {
		const S = await page.evaluate(() => { const S = window.__s18 || { n: 0, seen: 0, bad: [], rects: [] }; clearInterval(S.id); S.id = 0; return S; });
		const ok = S.n > 0 && S.seen > 0 && S.bad.length === 0;
		console.log(`  ${ok ? 'ok  ' : 'FAIL'} S18 ${what}: no toast over the leader's hit (${S.n} samples, a toast in ${S.seen}${S.rects.length ? ` at ${S.rects.map((r) => `[${r}]`).join(' ')}` : ''}${S.bad.length ? `; OVER THE HIT ${JSON.stringify(S.bad.slice(0, 3))}` : ''})`);
		if (!ok) failed++;
	};
	const shot = async (step) => {
		// half size: the viewport at DPR / 2
		const p = `${out}/${prefix}${step}-${W}x${H}.png`;
		const buf = await page.screenshot({ scale: 'device', timeout: 120000 });
		const half = await page.evaluate(async ({ b64, w, h }) => {
			const img = new Image();
			img.src = `data:image/png;base64,${b64}`;
			await img.decode();
			const c = document.createElement('canvas');
			c.width = Math.round(w / 2); c.height = Math.round(h / 2);
			const g = c.getContext('2d');
			g.imageSmoothingEnabled = true;
			g.imageSmoothingQuality = 'high';
			g.drawImage(img, 0, 0, c.width, c.height);
			return c.toDataURL('image/png').split(',')[1];
		}, { b64: buf.toString('base64'), w: Math.round(W * DPR), h: Math.round(H * DPR) });
		fs.writeFileSync(p, Buffer.from(half, 'base64'));
		console.log('  shot', p);
	};
	console.log(`\n${spec}`);
	await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1`);
	await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
	await page.click('#od-quiet');
	await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay && window.odPick && window.odPick.open, null, { timeout: 120000 });
	await wait(1500);
	await refresh();
	await shot('picker');
	let pk = await page.evaluate(() => window.odPick);
	const cell = pk.cells.find((c) => c[2] === leader) || pk.cells[0];
	await s18Start();
	await tap(css(cell[0], cell[1]));   // the ballot booth (ADR 0007): a tap chooses the slip, a second tap votes
	await wait(400);
	await tap(css(cell[0], cell[1]));
	await page.waitForFunction(() => window.odDev && window.odDev.mode === 'title', null, { timeout: 8000 }).catch(() => {});
	await wait(1100);
	await refresh();
	let dev = await page.evaluate(() => window.odDev);
	const hud = dev.hud || {};
	console.log(`  hud ${JSON.stringify(hud)}`);
	const inter = (a, b) => a.length && b.length && a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
	const ok = hud.identity && hud.identity.rect.length && !inter(hud.identity.rect, hud.leaderHit);
	console.log(`  ${ok ? 'ok  ' : 'FAIL'} the identity chip ${JSON.stringify(hud.identity && hud.identity.rect)} is clear of the leader's hit ${JSON.stringify(hud.leaderHit)}`);
	if (!ok) failed++;
	await shot('pretap-undo');
	await wait(6000);
	await shot('pretap');
	// ftue.md P0 F2 (idle ≥ 9 s from the pick): the hand at the tap object's right side (merge review M4)
	await wait(4000);
	await shot('pretap-hand');
	await s18Stop('round 1, the pick to tap 1');
	const hat = css(disp.hat[0], disp.hat[1]);
	for (let i = 0; i < 3; i++) { await tap([hat[0], hat[1] + 4 * i]); await wait(400); }
	await wait(1600);
	await shot('card1');
	// a forced election (dev) → EVOLVE_TX → the flash → the picker (after)
	await page.evaluate(() => { window.odDevElect = 1; });
	for (let t = 0; t < 90; t++) {
		await wait(1000);
		pk = await page.evaluate(() => window.odPick || null);
		if (pk && pk.open && pk.variant === 'after') break;
		const mdl = await page.evaluate(() => (window.odDev && window.odDev.modalButtons) || []);
		if (mdl.length) { await refresh(); await tap(css(mdl[mdl.length - 1][0], mdl[mdl.length - 1][1])); }
		const fl = await page.evaluate(() => window.odFlash || null);
		if (fl && fl.open) { await refresh(); const b = fl.skip && fl.skip[0] >= 0 ? fl.skip : fl.next; await tap(css(b[0], b[1])); }
	}
	await wait(1200);
	if (pk && pk.open && pk.variant === 'after') {
		await shot('picker-after');
		// round 2 starts: a different leader (the name back in Row A, the undo chip in the lane)
		await refresh();
		const bank = Number(((await page.evaluate(() => window.odDev)) || {}).bank || 0);
		const other = pk.cells.find((c) => c[2] !== '' && c[2] !== leader && c[2] !== 'gantz' && !c[3]) || pk.cells[0];   // an open slip
		await s18Start();
		const t0 = Date.now();
		await tap(css(other[0], other[1]));
		await wait(400);
		await tap(css(other[0], other[1]));
		await page.waitForFunction(() => window.odDev && window.odDev.mode === 'main', null, { timeout: 8000 }).catch(() => {});
		await wait(1300);
		await shot('round2-start');
		const st = (await page.evaluate(() => window.odDev)) || {};
		const sh = st.shop || {};
		const ok2 = bank <= 5 && st.hud && st.hud.card1 === true && (sh.rows || []).length >= 1 && (sh.silhouettes || 0) >= 1;
		console.log(`  ${ok2 ? 'ok  ' : 'FAIL'} M2/S15: round 2 starts with ${bank.toFixed(1)} ₪ (≤ 5): card 1 is a source card (${JSON.stringify((sh.rows || []).map((r) => r[2]))}) over ${sh.silhouettes || 0} teaser rows`);
		if (!ok2) failed++;
		// a loaded machine: the game clock lags the wall clock; keep sampling up to 25 s until the toast shows
		while (Date.now() - t0 < 7000 || (Date.now() - t0 < 25000 && !((await s18Seen()) > 1))) await wait(250);
		await shot('round2-fresh');
		await s18Stop('round 2, the pick to 7 s');
	} else { console.log('  FAIL the after-election picker did not open'); failed++; }
	if (errors.length) { console.log(`  FAIL page errors ${JSON.stringify(errors.slice(0, 3))}`); failed++; }
	await ctx.close();
}
await browser.close();
console.log(failed ? `PRETAP_SHOTS: ${failed} FAILED` : 'PRETAP_SHOTS: PASS');
process.exit(failed ? 1 : 0);
