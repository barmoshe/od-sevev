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
	const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: !framed, hasTouch: !framed });
	const page = await ctx.newPage();
	const errors = [];
	page.on('pageerror', (e) => errors.push(e.message));
	const cdp = await ctx.newCDPSession(page);
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
	const refresh = async () => { disp = await page.evaluate(() => window.odDisplay); };
	const shot = async (step) => {
		const p = `${out}/${name}-${step}.png`;
		const buf = await page.screenshot({ path: p });
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
		check('spec', pk.tile && Math.abs(lastRow + th / 2 + 12 - stripTop) <= 4, `the grid is bottom-anchored: last row bottom ${Math.round(lastRow + th / 2)} + 12 = the strip top ${stripTop}`);
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
		// pick הפתעה (the centre cell, id "")
		const rnd = pk.cells.find((c) => c[2] === '') || pk.cells[0];
		await tap(css(rnd[0], rnd[1]));
		await page.waitForFunction(() => window.odDev && window.odDev.mode !== 'pick', null, { timeout: 8000 }).catch(() => {});
		await wait(1200);
		await refresh();
	}
	const pre = await shot('pretap');
	await bandCheck('pre-tap', pre, 'the pre-tap stage paints the apron below the stage');

	// ---- the verticals (the engine publishes lowerY today)
	check('spec', disp.lowerY === E.lowerY, `lowerY (stage bottom) = ${E.lowerY} (S ${E.S}; got ${disp.lowerY}, S ${disp.lowerY - E.stageTop})`);
	const hitBottom = (disp.lowerY - 140) / disp.logical[1];
	check('spec', hitBottom >= 0.4 && hitBottom <= 0.6, `reach: the leader's hit bottom sits at ${(100 * hitBottom).toFixed(0)}% of the height (40-60%), its centre at ${(100 * disp.hat[1] / disp.logical[1]).toFixed(0)}%`);

	// ---- tap 1-3 (card 1), then the first buy
	const hat = css(disp.hat[0], disp.hat[1]);
	for (let i = 0; i < 4; i++) { await tap([hat[0], hat[1] + 4 * i]); await wait(350); }
	await wait(1200);
	await refresh();
	const card1 = await shot('card1');
	await bandCheck('card 1', card1, 'card 1 + silhouettes fill the pane; the pane covers the tab slot before C1');
	let s = await probe();
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
	await bandCheck('bought', bought, 'Row B shows the sky before C2; the pane fills to the safe bottom before C1');

	// ---- C1: three kinds of source (the tab bar), then T3 and a paid demand (C2: Row B)
	for (let i = 0; i < 8; i++) {
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
	if (s && s.shop && s.shop.list) {
		const [lt, lb] = s.shop.list;
		const insB = 0;
		check('spec', Math.abs(lb + TABS - (floor4(disp.logical[1]) - insB)) <= 4, `the tab bar sits on the safe bottom (list ${Math.round(lt)}-${Math.round(lb)}, + ${TABS} = ${Math.round(lb + TABS)} vs ${floor4(disp.logical[1])})`);
		const all = s.shop.all || s.shop.rows || [];
		const vis = all.filter((r) => r[1] - 60 >= lt - 1 && r[1] + 60 <= lb + 1).length;
		const partial = all.map((r) => Math.max(0, Math.min(lb, r[1] + 60) - Math.max(lt, r[1] - 60))).filter((v) => v > 0 && v < 119);
		const silh = (s.shop.silhouettes || 0);   // §4.4: the engine publishes the teaser rows it draws
		check('spec', vis + silh >= E.n, `the pane shows ≥ ${E.n} whole rows: cards + silhouettes (got ${vis} cards of ${all.length} + ${silh} silhouettes)`);
		check('spec', partial.every((v) => v <= PEEK + 4), `a cut card shows ≤ ${PEEK} px (the peek), never its pill (partials ${JSON.stringify(partial.map(Math.round))})`);
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
	await page.keyboard.press('Escape');
	await wait(600);

	check('base', errors.length === 0, `no page errors ${errors.length ? JSON.stringify(errors.slice(0, 3)) : ''}`);
	summary.push(res);
	await ctx.close();
}
await browser.close();
console.log('\nsummary (failed checks: baseline / spec / width)');
for (const r of summary) console.log(`  ${r.name.padEnd(22)} ${r.base} / ${r.spec} / ${r.width}`);
const failed = failedBase + (BASELINE_ONLY ? 0 : failedSpec + failedWidth);
console.log(failed ? `MOBILE_WEB: ${failedBase} baseline, ${failedSpec} spec, ${failedWidth} width FAILED${BASELINE_ONLY ? ' (spec and width not gating: MOBILE_BASELINE=1)' : ''}` : `MOBILE_WEB: PASS${BASELINE_ONLY && (failedSpec + failedWidth) ? ` (baseline; ${failedSpec} spec, ${failedWidth} width checks open)` : ''}`);
process.exit(failed ? 1 : 0);
