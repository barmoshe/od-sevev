// Mobile-first layout check (ux/mobile-first-layout.md §9): plays the web build in headless Chromium
// at every phone of the device matrix (and the desktop phone frame), through the real UI with real
// touches, and asserts what can be measured:
//   baseline  (holds on today's build): the canvas fills the viewport (backing store = CSS × DPR,
//             box at 0,0), window.odDisplay is integer with k = crisp(min(floor(W/180), floor(H/267))),
//             one art px ≥ 2 CSS px (so the 88-logical floor is ≥ 44 CSS pt), no page errors;
//   spec      (the mobile-first layout, ux/mobile-first-layout.md): the vertical split (S, P, whole
//             card rows + a 40-px peek), the tab bar on the safe bottom, no dead band of ≥ 8 art px
//             outside the stage sky, the fluid width (odDisplay.cw), the paged ticker
//             (odDisplay.ticker), the bottom-anchored picker grid (odPick.tile / odPick.grid).
// Screens: the picker (when the build has one), the pre-tap stage, card 1, the first buy ("bought"),
// C1 (the tab bar) and C2 (Row B), T3 (the chat), and the settings sheet.
// The pre-tap + HUD fixes (2026-09-30 manual test; mobile-first §3.3, §5.1.1, §5.8.1, §5.9): the
// picker's caption on its navy plate (A3), card 1 up from the pick (A2), the round's name in Row A's
// identity chip, never over the leader's hit (A7/B10, checked pre-tap and at card 1), and the
// pre-tap undo chip in its navy bar in the ticker slot (B12). They read window.odPick.strip and
// window.odDev.hud.
//   node tools/web/mobile_web.mjs <url> <out dir> [devices]
//     devices: comma list of WxH@DPR (a phone: touch, isMobile) or frame-WxH@DPR (a desktop window,
//     mouse: the shell's 390-CSS phone frame). Default: the spec's matrix (below).
//   MOBILE_BASELINE=1  report the spec checks but fail only on the baseline (today's build)
// The width rule (Bar, 2026-09-30: "make sure the UX/UI fills the phone's width"), kind 'width', on
// every phone of the matrix: the game runs with `&clear=1`, a sentinel clear colour (#ff00ff) that
// only shows where nothing is drawn, and the page's own background is set to it too; every shot's
// left and right 3% columns (1%, 2%, 3% / 97%, 98%, 99%, one row every 8 art px) must never show it:
// the HUD, the ticker, the pane, the tab bar, the stage with its wings and the plaza reach both
// edges. Plus: cards keep ≤ 4 art px (16 logical) of gutter per side; the settings sheet and the
// picker grid span ≥ 92% of the canvas. It keys on "not the background", never on a palette.
// S18 (merge review M1, D62; mobile-first §5.9), kind 'spec': window.odDev.hud.toast is sampled every
// 250 ms (in the page) from the pick to tap 1, and from round 2's pick to 7 s, and must never
// intersect hud.leaderHit: before the round starts toasts dock in the lane band under his feet.
// Round 2 with an empty purse (merge review M2, S8 + S15), kind 'spec': a second page per device, no
// grant, 3 taps (≤ 5 ₪ in hand), a forced election (window.odDevElect), a new leader: at round 2's
// start card 1 is a real source card over the teaser rows, and the dead-band rule holds.
// The settings reach (manual test 2026-09-30 A6), kind 'spec': every settings row is built, and each
// one is wholly on screen or brought on screen by dragging the sheet's body; the fixed "סגור" stays on
// screen under the rows (window.odDev.modalRows / modalClip).
// Serve build/web first: python3 -m http.server <port> --directory build/web
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const zlib = await import('node:zlib');
const MATRIX = '375x667@2,390x844@3,393x852@3,430x932@3,360x780@3,412x915@2.625,frame-1440x900@1,390x664@3,375x548@2';
const [base, out, list = MATRIX] = process.argv.slice(2);
if (!base || !out) {
	console.log('usage: node tools/web/mobile_web.mjs <url> <out dir> [WxH@DPR,frame-WxH@DPR,...]');
	process.exit(2);
}
const BASELINE_ONLY = process.env.MOBILE_BASELINE === '1';
fs.mkdirSync(out, { recursive: true });

// ------------------------------------------------------------------ the spec's rules (keep equal to
// ux/tools/mobile_layout.py and ux/mobile-first-layout.md §2 / §5.8)
const ROW_A = 96, ROW_B = 84, TICKER = 84, TABS = 104, FIXED = ROW_A + ROW_B + TICKER + TABS;
const CARD = 120, PEEK = 40, S_PREF = 640, S_FULL = 560, S_MIN = 460;
const floor4 = (v) => Math.floor(v / 4) * 4;
const ceil4 = (v) => Math.ceil(v / 4) * 4;
const crisp = (k) => { if (k <= 1) return Math.max(0, k); while (k % 2 && k % 3) k--; return k; };
function split(R, top = 0, vh = 0) {
	let n = R - (3 * CARD + PEEK) >= S_MIN ? Math.max(3, Math.floor((R - S_PREF - PEEK) / CARD)) : 2;
	// the reach guard (§6): the leader's hit bottom (stage bottom − 140) stays ≥ 40% of the height
	while (vh && n > 3 && top + ROW_A + ROW_B + (R - n * CARD - PEEK) - 140 < 0.4 * vh) n--;
	let P = n * CARD + PEEK;
	let S = R - P;
	if (S < S_MIN) { S = S_MIN; P = R - S; }
	return { S, P, n };
}
function expected(disp, insT = 0, insB = 0) {
	const vh = floor4(disp.logical[1]);
	const R = vh - insT - insB - FIXED;
	const { S, P, n } = split(R, insT, vh);
	const top = insT;
	return { R, S, P, n, cw: floor4(disp.logical[0]), stageTop: top + ROW_A + ROW_B, lowerY: top + ROW_A + ROW_B + S,
		tabsY: top + ROW_A + ROW_B + S + TICKER + P, leader: S >= S_FULL ? 4 : 3 };
}

// ------------------------------------------------------------------ a small PNG reader (8-bit RGB/RGBA)
function readPng(buf) {
	let o = 8, w = 0, h = 0, ct = 0;
	const idat = [];
	while (o < buf.length) {
		const len = buf.readUInt32BE(o);
		const type = buf.toString('ascii', o + 4, o + 8);
		const d = buf.subarray(o + 8, o + 8 + len);
		if (type === 'IHDR') { w = d.readUInt32BE(0); h = d.readUInt32BE(4); ct = d[9]; }
		if (type === 'IDAT') idat.push(d);
		o += 12 + len;
	}
	const bpp = ct === 6 ? 4 : 3;
	const raw = zlib.inflateSync(Buffer.concat(idat));
	const stride = w * bpp;
	const px = Buffer.alloc(h * stride);
	for (let y = 0; y < h; y++) {
		const f = raw[y * (stride + 1)];
		const src = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1));
		for (let x = 0; x < stride; x++) {
			const a = x >= bpp ? px[y * stride + x - bpp] : 0;
			const b = y > 0 ? px[(y - 1) * stride + x] : 0;
			const c = x >= bpp && y > 0 ? px[(y - 1) * stride + x - bpp] : 0;
			let v = src[x];
			if (f === 1) v += a;
			else if (f === 2) v += b;
			else if (f === 3) v += (a + b) >> 1;
			else if (f === 4) { const p = a + b - c; const pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c); v += pa <= pb && pa <= pc ? a : (pb <= pc ? b : c); }
			px[y * stride + x] = v & 255;
		}
	}
	return { w, h, bpp, px };
}
// Rows (device px) where ≥ 98.5% of the samples (one per art px) equal the row's first pixel: a band
// of such rows ≥ 8 art px tall is "no content": a flat fill, an empty panel, a horizontal-stripe tile.
function deadBands(img, k, minArt = 8) {
	const { w, h, bpp, px } = img;
	const step = Math.max(1, k);
	const blank = (y) => {
		const r0 = y * w * bpp;
		let same = 0, n = 0;
		for (let x = 0; x < w; x += step) {
			const i = r0 + x * bpp;
			n++;
			if (Math.abs(px[i] - px[r0]) + Math.abs(px[i + 1] - px[r0 + 1]) + Math.abs(px[i + 2] - px[r0 + 2]) <= 6) same++;
		}
		return same / n >= 0.985;
	};
	const bands = [];
	for (let y = 0; y < h;) {
		if (!blank(y)) { y++; continue; }
		const y0 = y;
		while (y < h && blank(y)) y++;
		if (y - y0 >= minArt * k) bands.push([y0, y]);
	}
	return bands;
}

// ------------------------------------------------------------------ the run
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
let failedBase = 0, failedSpec = 0, failedWidth = 0;
const summary = [];
for (const spec of list.split(',')) {
	const framed = spec.startsWith('frame-');
	const [wh, dprS] = spec.replace('frame-', '').split('@');
	const [W, H] = wh.split('x').map(Number);
	const DPR = Number(dprS);
	const name = `${framed ? 'frame-' : ''}${wh}@${DPR}`;
	console.log(`\n${name}`);
	const res = { name, base: 0, spec: 0, width: 0 };
	const check = (kind, ok, msg) => {
		console.log(`  ${ok ? 'ok  ' : 'FAIL'} [${kind}] ${msg}`);
		if (!ok) { if (kind === 'base') { failedBase++; res.base++; } else if (kind === 'width') { failedWidth++; res.width++; } else { failedSpec++; res.spec++; } }
	};
	let ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: !framed, hasTouch: !framed });
	let page = await ctx.newPage();
	const errors = [];
	page.on('pageerror', (e) => errors.push(e.message));
	let cdp = await ctx.newCDPSession(page);
	const wait = (ms) => page.waitForTimeout(ms);
	let tid = 1;
	let cv, disp, fr;
	const css = (x, y) => [cv.x + x * disp.f / DPR, cv.y + y * disp.f / DPR];
	const tap = async ([x, y], hold = 60) => {
		if (framed) { await page.mouse.click(x, y, { delay: hold }); return; }
		const id = tid++;
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id }] });
		await wait(hold);
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
	};
	const probe = () => page.evaluate(() => window.odDev || null);
	// S18: an in-page sampler of hud.toast ∩ hud.leaderHit, every 250 ms (odDev publishes at 4 Hz)
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
	const s18Stop = () => page.evaluate(() => { const S = window.__s18 || { n: 0, seen: 0, bad: [], rects: [] }; clearInterval(S.id); S.id = 0; return S; });
	const s18Check = (what, S) => check('spec', S.n > 0 && S.seen > 0 && S.bad.length === 0,
		`S18 ${what}: no toast over the leader's hit (${S.n} samples, a toast in ${S.seen}${S.rects.length ? ` at ${S.rects.map((r) => `[${r}]`).join(' ')}` : ''}${S.bad.length ? `; OVER THE HIT ${JSON.stringify(S.bad.slice(0, 3))}` : ''})`);
	// a drag from a to b (CSS px): touch on a phone, the mouse in the desktop frame
	const swipe = async ([x0, y0], [x1, y1], steps = 8) => {
		if (framed) {
			await page.mouse.move(x0, y0); await page.mouse.down();
			for (let i = 1; i <= steps; i++) { await page.mouse.move(x0 + (x1 - x0) * i / steps, y0 + (y1 - y0) * i / steps); await wait(16); }
			await page.mouse.up();
			return;
		}
		const id = tid++;
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: x0, y: y0, id }] });
		for (let i = 1; i <= steps; i++) {
			await wait(16);
			await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: x0 + (x1 - x0) * i / steps, y: y0 + (y1 - y0) * i / steps, id }] });
		}
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
	};
	// Manual test A6: every settings row is on screen, or reachable by scrolling the sheet's body (a
	// real drag), and the fixed "סגור" stays on screen. window.odDev.modalRows = [id, top, bottom] and
	// modalClip = [top, bottom] in viewport logical px; a row counts when it is wholly inside the clip.
	const SETTINGS_ROWS = ['sfx', 'music', 'reducedMotion', 'largeText', 'about', 'reset'];
	const settingsReach = async (st) => {
		const H0 = disp.logical[1];
		const rowsOf = (x) => (x && x.modal === 'SETTINGS' && x.modalRows) || [];
		const inView = (x) => {
			const [ct, cb] = x.modalClip || [0, -1];
			return rowsOf(x).filter((r) => r[1] >= ct - 0.5 && r[2] <= cb + 0.5 && r[2] <= H0 + 0.5).map((r) => r[0]);
		};
		const ids = rowsOf(st).map((r) => r[0]);
		check('spec', SETTINGS_ROWS.every((k) => ids.includes(k)), `settings: every row is built (${ids.join(', ')})`);
		const onScreen = new Set(inView(st));
		const seen = new Set(onScreen);
		let cur = st;
		for (let i = 0; i < 6 && cur && seen.size < ids.length && cur.modalClip; i++) {
			const [ct, cb] = cur.modalClip;
			await swipe(css(disp.cw / 2, cb - 24), css(disp.cw / 2, Math.max(ct + 24, cb - 24 - 0.6 * (cb - ct))));
			await wait(500);
			cur = await probe();
			inView(cur).forEach((k) => seen.add(k));
		}
		const missing = ids.filter((k) => !seen.has(k));
		const scrolled = [...seen].filter((k) => !onScreen.has(k));
		check('spec', missing.length === 0, `settings: every row is on screen or reachable (on screen: ${onScreen.size}/${ids.length}${scrolled.length ? `; by scrolling: ${scrolled.join(', ')}` : ''}${missing.length ? `; NOT reachable: ${missing.join(', ')}` : ''})`);
		if (scrolled.length) await shot('settings-scrolled');
		const close = ((cur && cur.modalButtons) || []).filter((b) => b[2] !== '').pop();
		check('spec', !!close && close[1] + 44 <= H0 + 0.5 && (!cur.modalClip || close[1] - 44 >= cur.modalClip[1] - 0.5), `settings: the fixed "סגור" is on screen under the rows (${close ? Math.round(close[1]) : '?'} of ${Math.round(H0)})`);
	};
	// S7 + review U6: the pill rect of every row the pane shows at least partly (source cards, the
	// locked row, the teasers); a pill is drawn only when it lies wholly inside the pane
	const pillCheck = (step, st) => {
		if (!st || !st.shop || !st.shop.list) return;
		const [lt, lb] = st.shop.list;
		const pills = st.shop.pills || [];
		const cut = pills.filter((p) => p[2] && (p[0] < lt - 0.5 || p[1] > lb + 0.5));
		check('spec', pills.length > 0 && cut.length === 0, `${step}: no pill on a partly visible row (${pills.length} rows in the pane; cut pills ${JSON.stringify(cut.map((p) => p.slice(0, 2).map(Math.round)))})`);
	};
	const refresh = async () => { disp = await page.evaluate(() => window.odDisplay); };
	const shot = async (step) => {
		const p = `${out}/${name}-${step}.png`;
		const buf = await page.screenshot({ path: p, timeout: 120000 });   // a loaded machine: swiftshader frames can take seconds
		console.log('  shot', p);
		return buf;
	};
	// The dead-band rule on one screenshot (§9.1). Exempt, in logical y: the stage sky, from Row A's
	// bottom (Row B's slot shows the sky until C2) to the leader's hit top, except a band there in the
	// HUD fill #140c24 (an empty, covered Row B slot is never sky); Row B itself once revealed (the
	// whole row is one target); `opts.exempt` replaces the sky interval (the picker).
	const hudFill = [0x14, 0x0c, 0x24];
	// the width rule: the sentinel background in the edge columns = a gap to the canvas edge
	const edgeCheck = (step, buf) => {
		if (!buf || framed) return;
		const img = readPng(buf);
		const hits = new Set();
		for (let y = 0; y < img.h; y += Math.max(1, disp.k * 8)) {
			for (const fx of [0.01, 0.02, 0.03, 0.97, 0.98, 0.99]) {
				const x = Math.min(img.w - 1, Math.floor(img.w * fx));
				const i = (y * img.w + x) * img.bpp;
				if (Math.abs(img.px[i] - 255) + img.px[i + 1] + Math.abs(img.px[i + 2] - 255) <= 12) hits.add(`${fx < 0.5 ? 'L' : 'R'}${Math.round(y / disp.f)}`);
			}
		}
		const list = [...hits];
		check('width', list.length === 0, `${step}: the chrome, art and cards reach both canvas edges (no background in the edge 3%)${list.length ? `: ${list.slice(0, 12).join(' ')}${list.length > 12 ? ' …' : ''}` : ''}`);
	};
	const bandCheck = async (step, buf, why, opts = {}) => {
		edgeCheck(step, buf);
		if (!buf || framed) return;   // the frame's bezel and page margin are not the game's
		const img = readPng(buf);
		const k = disp.k;             // device px per art px (the screenshot is in device px)
		const toLog = (dy) => dy / disp.f;
		const top = disp.stageY + 160 - ROW_A - ROW_B;
		const hitTop = disp.lowerY - ((disp.lowerY - disp.stageY - 160) >= S_FULL ? 556 : 452);
		const sky = opts.exempt || [[top + ROW_A, hitTop]];
		const bad = [];
		for (const [a, b] of deadBands(img, k)) {
			const i = a * img.w * img.bpp;
			const col = [img.px[i], img.px[i + 1], img.px[i + 2]];
			const isHud = col.every((v, j) => Math.abs(v - hudFill[j]) <= 3);
			const la = toLog(a), lb = toLog(b);
			let left = lb - la;
			const cover = (ea, eb) => { left -= Math.max(0, Math.min(lb, eb + 4) - Math.max(la, ea - 4)); };
			if (!(isHud && !opts.exempt)) for (const [ea, eb] of sky) cover(ea, eb);
			if (opts.rowB) cover(top + ROW_A, top + ROW_A + ROW_B);
			if (left >= 32) bad.push(`${Math.round(la)}-${Math.round(lb)} (${Math.round((b - a) / k)} art, #${col.map((v) => v.toString(16).padStart(2, '0')).join('')})`);
		}
		check('spec', bad.length === 0, `${step}: no band of ≥ 8 art px without content outside the stage sky${why ? ` (${why})` : ''}${bad.length ? `: logical y ${bad.join(', ')}` : ''}`);
	};

	await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1&grant=500&clear=1`);
	if (!framed) await page.evaluate(() => { document.documentElement.style.background = '#ff00ff'; document.body.style.background = '#ff00ff'; });
	await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
	await page.click('#od-quiet');
	await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
	await wait(1500);
	await refresh();
	cv = await page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height, bw: c.width, bh: c.height }; });
	fr = await page.evaluate(() => window.odFrame || { framed: false });
	console.log(`  canvas ${cv.bw}x${cv.bh} at ${cv.x},${cv.y} (${cv.w}x${cv.h} CSS)  odDisplay ${JSON.stringify(disp)}`);

	// ---- baseline
	const bw = framed ? Math.round(390 * DPR) : Math.floor(W * DPR);
	check('base', cv.bw === bw && (framed || cv.bh === Math.floor(H * DPR)), `backing store = CSS × DPR (${cv.bw}x${cv.bh})`);
	check('base', framed ? fr.framed === true : (cv.x === 0 && cv.y === 0 && Math.abs(cv.w - W) < 1 && Math.abs(cv.h - H) < 1), framed ? 'the desktop window gets the 390-CSS phone frame' : 'the canvas box covers the whole viewport');
	const fit = Math.min(Math.floor(cv.bw / 180), Math.floor(cv.bh / 267));
	check('base', disp.integer === true && disp.k === crisp(fit), `integer scale, k = crisp(${fit}) = ${disp.k}`);
	const artCss = disp.k / DPR;
	check('base', artCss >= 2 - 1e-9, `one art px = ${artCss.toFixed(3)} CSS px ≥ 2 (88 logical = ${(22 * artCss).toFixed(1)} CSS ≥ 44)`);
	check('base', Math.abs(disp.logical[0] - cv.bw / disp.f) < 1 && Math.abs(disp.logical[1] - cv.bh / disp.f) < 1, `logical viewport = device / f (${disp.logical.map((v) => v.toFixed(1)).join('×')})`);
	const E = expected(disp);
	console.log(`  spec: R ${E.R}  S ${E.S}  P ${E.P} (${E.n} rows + ${E.P - E.n * CARD})  lowerY ${E.lowerY}  tabsY ${E.tabsY}  cw ${E.cw}  leader ×${E.leader}`);

	// ---- spec: fluid width and the paged ticker (published by the engine once built)
	check('spec', disp.cw === E.cw, `odDisplay.cw = floor4(logical width) = ${E.cw} (the chrome spans the canvas; got ${disp.cw})`);
	check('spec', !!(disp.ticker && disp.ticker.mode === 'page' && disp.ticker.clipW === 324 + (E.cw - 720)), `odDisplay.ticker = {mode: 'page', clipW: ${324 + E.cw - 720}} (got ${JSON.stringify(disp.ticker)})`);

	// ---- the picker (builds with LEADER_PICK)
	let pk = await page.evaluate(() => window.odPick || null);
	if (pk && pk.open) {
		const buf = await shot('pick');
		const tw = floor4((E.cw - 72) / 3);
		check('spec', !!(pk.tile && pk.tile[0] === tw), `pick tiles are fluid: ${tw} wide (got ${JSON.stringify(pk.tile)})`);
		const H0 = floor4(disp.logical[1]);
		const bottoms = pk.cells.map((c) => c[1]);
		const lastRow = Math.max(...bottoms);
		const th = pk.tile ? pk.tile[1] : 0;
		const stripTop = H0 - 16 - 112;
		// §5.14.2 (F15): the booth frames the grid wherever it costs no tile pixel (the tall phones and
		// the desktop frame), never at the SE or the toolbar viewports; with it the grid sits 20 over
		// the strip (the booth's bottom 8 over it), without it 12
		const wantBooth = framed || (H >= 780 && !(W === 375 && H === 667));
		const booth = pk.booth || null;
		check('spec', !!booth === wantBooth, `the booth is ${wantBooth ? 'on' : 'off'} here (${JSON.stringify(booth)})`);
		const gap = booth ? 20 : 12;
		check('spec', pk.tile && Math.abs(lastRow + th / 2 + gap - stripTop) <= 4, `the grid is bottom-anchored: last row bottom ${Math.round(lastRow + th / 2)} + ${gap} = the strip top ${stripTop}`);
		if (booth) {
			check('width', booth[0] <= 0.5 && booth[2] >= disp.cw - 0.5, `the booth spans the canvas (${booth[0]}, ${booth[2]} of ${disp.cw})`);
			check('spec', Math.abs(booth[1] + booth[3] - (stripTop - 8)) <= 4, `the booth's bottom is 8 over the strip (${booth[1] + booth[3]} vs ${stripTop - 8})`);
		}
		// §5.8 avatar choice: the largest of 192 (even k only), 128, 96, 64 whose 3 × 3 fits `avail`
		const header = pk.variant === 'after' ? 132 : (12 + (H0 >= 1280 ? 116 : 64) + 12 + 44 + 12);
		const avail = H0 - header - 112 - (pk.variant === 'after' ? 116 : 16);
		const wantA = ([...(disp.k % 2 === 0 ? [192] : []), 128, 96, 64]).find((a) => a + 24 <= tw && 3 * (156 + a) + 24 <= avail) || 64;
		check('spec', pk.avatar === wantA, `the avatar is the largest crisp size that fits: ${wantA} (got ${pk.avatar})`);
		const gridTop = Math.min(...pk.cells.map((c) => c[1])) - (th || 0) / 2;
		const gx0 = Math.min(...pk.cells.map((c) => c[0])) - (pk.tile ? pk.tile[0] : 0) / 2;
		const gx1 = Math.max(...pk.cells.map((c) => c[0])) + (pk.tile ? pk.tile[0] : 0) / 2;
		check('width', (gx1 - gx0) >= 0.92 * disp.cw, `the picker grid spans ${Math.round(gx1 - gx0)} of ${disp.cw} (≥ 92%)`);
		await bandCheck('pick', buf, 'grid, strip and foot; the scrimmed stage above the title line is the exempt sky', { exempt: [[0, gridTop - 72]] });
		// A3 (mobile-first §5.8.1): the caption strip sits on a full-bleed navy plate, its text inside it
		const sp = pk.strip || [];
		const st = pk.stripText || [];
		check('spec', sp.length === 4 && sp[0] <= 0.5 && sp[2] >= disp.logical[0] - 0.5 && st.length === 2 && st[0] >= sp[1] && st[1] <= sp[1] + sp[3],
			`A3: the caption is on its full-bleed plate (plate ${JSON.stringify(sp)}, text ${JSON.stringify(st)})`);
		// pick הפתעה (the centre cell, id "")
		const rnd = pk.cells.find((c) => c[2] === '') || pk.cells[0];
		await s18Start();
		await tap(css(rnd[0], rnd[1]));
		await page.waitForFunction(() => window.odDev && window.odDev.mode !== 'pick', null, { timeout: 8000 }).catch(() => {});
		await wait(1200);
		await refresh();
	}
	const pre = await shot('pretap');
	await bandCheck('pre-tap', pre, 'Row A, the stage, the plaza strip in the ticker slot, card 1 and the teaser rows');
	// the pre-tap HUD (A2, A7/B10, B12)
	const inter = (a, b) => a && b && a.length === 4 && b.length === 4 && a[0] < b[0] + b[2] && b[0] < a[0] + a[2] && a[1] < b[1] + b[3] && b[1] < a[1] + a[3];
	const hudCheck = async (step) => {
		const h = ((await probe()) || {}).hud || {};
		const idr = (h.identity && h.identity.rect) || [];
		check('spec', idr.length === 4 && !inter(idr, h.leaderHit) && idr[1] + idr[3] <= disp.stageY + 160 - ROW_B,
			`${step}: the name plate (Row A's identity chip ${JSON.stringify(idr)}, ${h.identity && h.identity.leader}) is clear of the leader's hit ${JSON.stringify(h.leaderHit)} and inside Row A`);
		return h;
	};
	if (pk && pk.open) {
		const h0 = await hudCheck('pre-tap');
		check('spec', h0.card1 === true && h0.ticker === false && h0.top === true, `A2: card 1 and Row A are up before tap 1, the ticker waits for H1 (${JSON.stringify({ card1: h0.card1, ticker: h0.ticker, top: h0.top })})`);
		const u = h0.undo || {};
		check('spec', !u.on || (u.home === 'row' && u.rect.length === 4 && u.rect[1] >= disp.lowerY && u.rect[1] + u.rect[3] <= disp.lowerY + TICKER),
			`B12: the pre-tap undo chip sits in its bar in the ticker slot (${JSON.stringify(u)}, slot ${disp.lowerY}-${disp.lowerY + TICKER})`);
	}

	// ---- the verticals (the engine publishes lowerY today)
	check('spec', disp.lowerY === E.lowerY, `lowerY (stage bottom) = ${E.lowerY} (S ${E.S}; got ${disp.lowerY}, S ${disp.lowerY - E.stageTop})`);
	const hitBottom = (disp.lowerY - 140) / disp.logical[1];
	check('spec', hitBottom >= 0.4 && hitBottom <= 0.6, `reach: the leader's hit bottom sits at ${(100 * hitBottom).toFixed(0)}% of the height (40-60%), its centre at ${(100 * disp.hat[1] / disp.logical[1]).toFixed(0)}%`);

	// ---- tap 1-3 (card 1), then the first buy
	const hat = css(disp.hat[0], disp.hat[1]);
	if (pk && pk.open) {
		// S18 round 1: Dubi's pre-tap line lands ≈ 0.9 s after the pick and shows 3 s; give it the time
		// to show before tap 1 retires it, so the check samples a real toast
		for (let t = 0; t < 24 && !((await page.evaluate(() => (window.__s18 || {}).seen || 0)) > 0); t++) await wait(250);
		s18Check('round 1, the pick to tap 1', await s18Stop());
	}
	// A2 (supersedes review U3): card 1 and its white field are up from the pick; at tap 1 the ticker
	// takes the plaza strip's slot, so no blank band may open under the stage here
	await tap([hat[0], hat[1]]);
	await wait(1200);
	await refresh();
	const tap1 = await shot('tap1');
	await bandCheck('tap 1', tap1, 'the ticker takes the strip; the pane stays (A2)');
	for (let i = 1; i < 4; i++) { await tap([hat[0], hat[1] + 4 * i]); await wait(350); }
	await wait(1200);
	await refresh();
	const card1 = await shot('card1');
	await bandCheck('card 1', card1, 'card 1 + silhouettes fill the pane; the pane covers the tab slot before C1');
	// D19 (mobile-first §5.2.2): the strip is never empty: a headline, a held one or the standing line
	const tickerText = async (step) => {
		const tk = ((await probe()) || {}).ticker || {};
		check('spec', tk.visible === true && String(tk.text || '').trim() !== '', `${step}: the ticker strip shows text (${tk.idle ? 'the standing line' : tk.held ? 'a held headline' : 'a headline'}: "${tk.text || ''}")`);
	};
	await tickerText('card 1');
	if (pk && pk.open) await hudCheck('card 1');
	let s = await probe();
	pillCheck('card 1', s);
	const buyRow = async () => {
		s = await probe();
		const r = ((s && s.shop && s.shop.rows) || []).filter((x) => x[3]);
		if (r.length) await tap(css(r[0][0], r[0][1]));
		return r.length > 0;
	};
	await buyRow();
	await wait(1500);
	await refresh();
	const bought = await shot('bought');
	await tickerText('bought');
	await bandCheck('bought', bought, 'Row B shows the sky before C2; the pane fills to the safe bottom before C1');
	pillCheck('bought', await probe());

	// ---- C1: three kinds of source (the tab bar), then T3 and a paid demand (C2: Row B)
	// up to 20 rounds (it breaks as soon as the group opens): on a loaded machine the game clock runs
	// slower than the wall clock (frames over 250 ms), so 60 ₪ after 3 sources can take longer
	for (let i = 0; i < 20; i++) {
		s = await probe();
		if (s && s.groupOpen) break;
		const rows = ((s && s.shop && s.shop.rows) || []).filter((x) => x[3]);
		const pickRow = rows.length ? rows[Math.min(rows.length - 1, i % 3)] : null;
		if (pickRow) await tap(css(pickRow[0], pickRow[1]));
		else { for (let t = 0; t < 10; t++) { await tap([hat[0], hat[1]]); await wait(120); } }
		await wait(2600);
	}
	await wait(3000);
	await refresh();
	s = await probe();
	check('base', !!(s && s.groupOpen), 'C1: the group opened (the tab bar is revealed)');
	const c1 = await shot('c1-tabs');
	await tickerText('C1');
	if (s && s.shop && s.shop.list) {
		const [lt, lb] = s.shop.list;
		const insB = 0;
		check('spec', Math.abs(lb + TABS - (floor4(disp.logical[1]) - insB)) <= 4, `the tab bar sits on the safe bottom (list ${Math.round(lt)}-${Math.round(lb)}, + ${TABS} = ${Math.round(lb + TABS)} vs ${floor4(disp.logical[1])})`);
		const all = s.shop.all || s.shop.rows || [];
		const vis = all.filter((r) => r[1] - 60 >= lt - 1 && r[1] + 60 <= lb + 1).length;
		const partial = all.map((r) => Math.max(0, Math.min(lb, r[1] + 60) - Math.max(lt, r[1] - 60))).filter((v) => v > 0 && v < 119);
		const silh = (s.shop.silhouettes || 0);   // §4.4: the engine publishes the teaser rows it draws
		check('spec', vis + silh >= E.n, `the pane shows ≥ ${E.n} whole rows: cards + silhouettes (got ${vis} cards of ${all.length} + ${silh} silhouettes)`);
		check('spec', partial.every((v) => v <= PEEK + 4), `a cut card shows ≤ ${PEEK} px (the peek) (partials ${JSON.stringify(partial.map(Math.round))})`);
		// review U6: the pill rect of every row the pane shows at least partly (source cards, the
		// locked row, the teasers): a pill is drawn only when it lies wholly inside the pane
		pillCheck('C1', s);
		// D20 (mobile-first §5.4.1): the 4-art gutter stays; it is now a deliberate ruled margin (a
		// flag-blue 1-art rule on each canvas edge + 3 art of the white field), so the rule is unchanged
		const card = s.shop.card || [0, 0];
		check('width', card[0] <= 16 + 0.5 && disp.cw - card[1] <= 16 + 0.5, `the cards keep ≤ 4 art px of gutter per side (x ${Math.round(card[0])}-${Math.round(card[1])} of ${disp.cw})`);
	}
	await bandCheck('C1', c1, 'the tab bar is up');
	// T3 (tab slot 3), pay the first demand
	const tabX = (i) => (E.cw > 0 && disp.cw ? (disp.cw - (disp.cw / 4) * i + disp.cw / 8) : disp.ox + 540 - 180 * (i - 1) + 90);
	const tabsY = s && s.shop && s.shop.list ? s.shop.list[1] + 52 : floor4(disp.logical[1]) - 52;
	await tap(css(tabX(3), tabsY));
	await wait(1800);
	s = await probe();
	check('base', !!(s && s.chat && s.chat.open), 'T3 opens from tab slot 3');
	for (let t = 0; t < 12 && s && s.chat && !(s.chat.pills || []).some((p) => p[3]); t++) { await wait(1000); s = await probe(); }
	const pill = ((s && s.chat && s.chat.pills) || []).find((p) => p[3]);
	if (pill) { await tap(css(pill[0], pill[1])); await wait(1800); }
	edgeCheck('T3', await shot('t3-chat'));
	await page.keyboard.press('Escape');
	await wait(1200);
	await refresh();
	const c2 = await shot('c2-rowb');
	await bandCheck('C2', c2, 'Row B is up', { rowB: true });
	// the settings sheet (gear, Row A left)
	await tap(css(disp.ox + 52, 48));
	await wait(1200);
	edgeCheck('settings', await shot('settings'));
	s = await probe();
	const mr = (s && s.modalRect) || [0, 0];
	check('width', mr[1] >= 0.92 * disp.cw, `the settings sheet spans ${Math.round(mr[1])} of ${disp.cw} (≥ 92%)`);
	await settingsReach(s);
	await page.keyboard.press('Escape');
	await wait(600);

	check('base', errors.length === 0, `no page errors ${errors.length ? JSON.stringify(errors.slice(0, 3)) : ''}`);
	await ctx.close();

	// ---- round 2 with an empty purse (merge review M1 S18 + M2 S8/S15): a second page, no grant
	if (pk && pk.open) {
		ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: !framed, hasTouch: !framed });
		page = await ctx.newPage();
		const errors2 = [];
		page.on('pageerror', (e) => errors2.push(e.message));
		cdp = await ctx.newCDPSession(page);
		await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1&clear=1`);
		if (!framed) await page.evaluate(() => { document.documentElement.style.background = '#ff00ff'; document.body.style.background = '#ff00ff'; });
		await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
		await page.click('#od-quiet');
		await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay && window.odPick && window.odPick.open, null, { timeout: 120000 });
		await wait(1500);
		await refresh();
		cv = await page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height, bw: c.width, bh: c.height }; });
		let pk2 = await page.evaluate(() => window.odPick);
		const first = pk2.cells.find((c) => c[2] !== '') || pk2.cells[0];
		await tap(css(first[0], first[1]));
		await page.waitForFunction(() => window.odDev && window.odDev.mode === 'title', null, { timeout: 8000 }).catch(() => {});
		await wait(1200);
		await refresh();
		const h2 = css(disp.hat[0], disp.hat[1]);
		for (let i = 0; i < 3; i++) { await tap([h2[0], h2[1] + 4 * i]); await wait(400); }
		await wait(800);
		await page.evaluate(() => { window.odDevElect = 1; });
		for (let t = 0; t < 90; t++) {
			await wait(1000);
			pk2 = await page.evaluate(() => window.odPick || null);
			if (pk2 && pk2.open && pk2.variant === 'after') break;
			const mdl = await page.evaluate(() => (window.odDev && window.odDev.modalButtons) || []);
			if (mdl.length) { await refresh(); await tap(css(mdl[mdl.length - 1][0], mdl[mdl.length - 1][1])); }
			const fl = await page.evaluate(() => window.odFlash || null);
			if (fl && fl.open) { await refresh(); const b = fl.skip && fl.skip[0] >= 0 ? fl.skip : fl.next; await tap(css(b[0], b[1])); }
		}
		await wait(1200);
		if (pk2 && pk2.open && pk2.variant === 'after') {
			await refresh();
			const bank = Number(((await probe()) || {}).bank || 0);
			const other = pk2.cells.find((c) => c[2] !== '' && c[2] !== first[2]) || pk2.cells[0];
			await s18Start();
			const t0 = Date.now();
			await tap(css(other[0], other[1]));
			await page.waitForFunction(() => window.odDev && window.odDev.mode === 'main', null, { timeout: 8000 }).catch(() => {});
			await wait(1300);
			await refresh();
			const r2 = await shot('round2-start');
			const st = (await probe()) || {};
			const sh = st.shop || {};
			const hh = st.hud || {};
			check('spec', bank <= 5 && hh.card1 === true && (sh.rows || []).length >= 1 && (sh.silhouettes || 0) >= 1,
				`M2/S15: round 2 starts with ${bank.toFixed(1)} ₪ (≤ 5): card 1 is a source card (${JSON.stringify((sh.rows || []).map((r) => r[2]))}) over ${sh.silhouettes || 0} teaser rows, never a locked row alone`);
			await bandCheck('round 2 start', r2, 'M2: card 1 and the teasers fill the pane with an empty purse');
			// S18 round 2: to 7 s after the pick (the fresh toast waits for the undo chip, then docks in the lane)
			// (on a loaded machine the game clock can lag the wall clock: past 7 s, wait up to 11 s for the toast)
			while (Date.now() - t0 < 7000 || (Date.now() - t0 < 11000 && !((await page.evaluate(() => (window.__s18 || {}).seen || 0)) > 0))) await wait(250);
			s18Check('round 2, the pick to 7 s', await s18Stop());
			await shot('round2-fresh');
		} else check('spec', false, 'round 2: the after-election picker opened');
		check('base', errors2.length === 0, `round 2: no page errors ${errors2.length ? JSON.stringify(errors2.slice(0, 3)) : ''}`);
		await ctx.close();
	}
	summary.push(res);
}
await browser.close();
console.log('\nsummary (failed checks: baseline / spec / width)');
for (const r of summary) console.log(`  ${r.name.padEnd(22)} ${r.base} / ${r.spec} / ${r.width}`);
const failed = failedBase + (BASELINE_ONLY ? 0 : failedSpec + failedWidth);
console.log(failed ? `MOBILE_WEB: ${failedBase} baseline, ${failedSpec} spec, ${failedWidth} width FAILED${BASELINE_ONLY ? ' (spec and width not gating: MOBILE_BASELINE=1)' : ''}` : `MOBILE_WEB: PASS${BASELINE_ONLY && (failedSpec + failedWidth) ? ` (baseline; ${failedSpec} spec, ${failedWidth} width checks open)` : ''}`);
process.exit(failed ? 1 : 0);
