// The share platform in the runtime origin (headless Chromium, a phone size, real touches):
//   1. The share drawer (Bar 2026-10-02; game/web/shell.html window.odShareUI, ui/share_desk.gd):
//      the stage's 📣 chip opens it, the engine's card arrives before any tap (a File is ready), every
//      kind's tab (leak, breaking, term, career, receipt, result), the story (1080×1920) and text-only
//      formats, the family-safe toggle (no leader named), the channel row (wa.me / t.me / x.com links,
//      copy, save), the back button, and the analytics steps share/<kind>/<channel>/<result>.
//   2. navigator.share present (an iPhone UA): the button shares the PNG File with the text, the caption
//      goes to the clipboard first ("הטקסט הועתק"); an Instagram in-app UA without navigator.share:
//      WhatsApp is the primary and the in-app hint shows.
//   3. The media advisor's prompt (a moment, the calm beat): the chat toast, its tap opens the drawer;
//      T3's header 📣.
//   4. A /s/<variant>/ stub: its own og tags (absolute, 1200×630 JPEG ≤ 300 KB) and the forward into
//      the game with ?via= and the hash: window.odArrival, arrive/<kind>/<via>, the hash cleaned.
//   5. The brawl stage cue under Row B and the chat's "{n} ממתינים ↑" chip (views wave 6).
// Positions come from window.odDev (ui/dev_probe.gd, `?dev=1`) and window.odShareState (main.gd).
//   node tools/web/share_web.mjs <url> <out dir> [WxH@DPR]
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const [base, out, dev = '390x844@2'] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const [wh, dprS] = dev.split('@');
const [W, H] = wh.split('x').map(Number);
const DPR = Number(dprS);
const SITE = 'https://od-sevev.vercel.app/';
const ORIGIN = new URL(base).origin;
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
let failed = 0;
const check = (ok, msg) => { console.log(`  ${ok ? 'ok  ' : 'FAIL'}  ${msg}`); if (!ok) failed++; };
const errors = [];
const IPHONE = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1';
const INSTA = 'Mozilla/5.0 (Linux; Android 14; Pixel 8; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/126.0 Mobile Safari/537.36 Instagram 340.0.0.0';

async function context(opts = {}) {
	const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: true, hasTouch: true,
		acceptDownloads: true, permissions: ['clipboard-read', 'clipboard-write'], ...opts });
	for (const host of ['https://wa.me/**', 'https://t.me/**', 'https://x.com/**']) {
		await ctx.route(host, (r) => r.fulfill({ status: 200, contentType: 'text/html', body: '<title>ext</title>' }));
	}
	// the deployed origin's files (the stubs' og images in the text-only preview) come from the build
	await ctx.route(SITE + '**', async (r) => {
		const resp = await r.fetch({ url: ORIGIN + new URL(r.request().url()).pathname }).catch(() => null);
		if (resp) await r.fulfill({ response: resp }); else await r.abort();
	});
	return ctx;
}
async function boot(ctx, query, init) {
	const page = await ctx.newPage();
	page.on('pageerror', (e) => errors.push(e.message));
	if (init) await page.addInitScript(init);
	await page.goto(`${base}${base.includes('?') ? '&' : '?'}${query}`);
	const cdp = await ctx.newCDPSession(page);
	const P = { page, cdp, tid: 1, ctx };
	P.wait = (ms) => page.waitForTimeout(ms);
	return P;
}
async function handoff(P) {
	await P.page.waitForFunction(() => (window.mbHandoffDone > 0) || (document.getElementById('od-sound') && document.getElementById('od-sound').offsetParent !== null), null, { timeout: 90000 });
	if (await P.page.evaluate(() => !(window.mbHandoffDone > 0))) {
		await P.page.click('#od-quiet');
	}
	await P.page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
	await P.wait(1200);
	await refresh(P);
}
async function refresh(P) {
	P.d = await P.page.evaluate(() => window.odDisplay);
	P.cv = await P.page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { x: r.x, y: r.y }; });
}
const css = (P, x, y) => [P.cv.x + x * P.d.f / DPR, P.cv.y + y * P.d.f / DPR];
async function tap(P, [x, y], hold = 60) {
	const id = P.tid++;
	await P.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id }] });
	await P.wait(hold);
	await P.cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
}
const probe = (P) => P.page.evaluate(() => window.odDev || null);
const desk = (P) => P.page.evaluate(() => window.odShareState || null);
async function shot(P, name) {
	const p = `${out}/${wh}@${DPR}-${name}.png`;
	await P.page.screenshot({ path: p });
	console.log('  shot', p);
}
const hat = (P) => css(P, P.d.hat[0], P.d.hat[1]);
// LEADER_PICK comes first on a fresh save: pick ביבי (the seeded brawl, Amsalem and Smotrich, is his
// lineup's), not whichever tile the random order puts under the Magician
async function pickBibi(P) {
	const pk = await P.page.evaluate(() => window.odPick || null);
	if (!pk || !pk.open) return;
	const c = pk.cells.find((q) => q[2] === 'bibi') || pk.cells[0];
	await P.wait(500);
	await tap(P, css(P, c[0], c[1]));   // the ballot booth (ADR 0007): a tap chooses the slip, a second tap votes
	await P.wait(400);
	await tap(P, css(P, c[0], c[1]));
	await P.page.waitForFunction(() => !(window.odPick && window.odPick.open), null, { timeout: 8000 }).catch(() => {});
	await P.wait(1200);
	await refresh(P);
}
// the drawer: its state, the current image key and its PNG's size
const ui = (P) => P.page.evaluate(async () => {
	const s = window.odShareUI && window.odShareUI.state;
	if (!s) return null;
	const root = document.getElementById('od-share');
	const key = s.p ? s.p.kind + '|' + (s.p.fmt === 'text' ? 'sq' : s.p.fmt) + '|' + (s.p.neutral ? 'n' : 'p') : '';
	const f = s.files[key];
	let dims = null;
	if (f) {
		const b = new Uint8Array(await f.slice(16, 24).arrayBuffer());
		const v = new DataView(b.buffer);
		dims = [v.getUint32(0), v.getUint32(4)];
	}
	return { open: s.open, kind: s.p && s.p.kind, fmt: s.p && s.p.fmt, neutral: s.p && s.p.neutral, text: s.p && s.p.text, key,
		file: f ? f.name : '', size: f ? f.size : 0, dims, tabs: [...document.querySelectorAll('#od-sh-tabs button')].map((b) => b.dataset.kind),
		msg: document.getElementById('od-sh-msg').textContent, go: document.getElementById('od-sh-go').textContent,
		goDisabled: document.getElementById('od-sh-go').disabled, inapp: root.classList.contains('od-inapp'),
		wa: document.getElementById('od-sh-wa').href, tg: document.getElementById('od-sh-tg').href, x: document.getElementById('od-sh-x2').href,
		status: document.getElementById('od-sh-status').textContent, log: (window.odShareLog || []).slice(-3), track: (window.odTrackLog || []).slice(-4) };
});
async function waitImage(P, fmt = 'sq') {
	await P.page.waitForFunction((f) => {
		const s = window.odShareUI && window.odShareUI.state;
		if (!s || !s.p) return false;
		const key = s.p.kind + '|' + f + '|' + (s.p.neutral ? 'n' : 'p');
		return !!s.files[key];
	}, fmt, { timeout: 20000 }).catch(() => {});
	await P.wait(250);
}
// a round with a group chat, four past rounds and the gate (so every kind has its tab)
async function seed(P) {
	await P.page.evaluate(() => { window.odDevChat = 1; window.odDevHistory = 4; });
	await P.wait(800);
}

// 1. the drawer from the stage chip: every kind, the formats, family-safe, the channels
{
	const ctx = await context();
	const P = await boot(ctx, 'dev=1&speed=5&grant=50000');
	await handoff(P);
	await pickBibi(P);
	for (let i = 0; i < 6; i++) { await tap(P, hat(P), 40); await P.wait(80); }
	await seed(P);
	await P.wait(1200);
	let ds = await desk(P);
	check(ds && ds.chip && ds.chip[0], `the 📣 chip stands on the stage once the group is open (${JSON.stringify(ds && ds.chip)})`);
	await shot(P, 'share-chip');
	await tap(P, css(P, ds.chip[1], ds.chip[2]));
	await P.page.waitForFunction(() => window.odShareUI && window.odShareUI.isOpen(), null, { timeout: 10000 }).catch(() => {});
	await waitImage(P);
	let u = await ui(P);
	check(u && u.open, 'a tap on the chip opens the share drawer');
	check(u && JSON.stringify(u.tabs) === JSON.stringify(['leak', 'breaking', 'term', 'career', 'receipt', 'result']), `every kind has its tab (${u && u.tabs})`);
	check(u && u.dims && u.dims[0] === 1080 && u.dims[1] === 1350 && u.size > 5000, `the card is a ready 1080×1350 PNG File before any share tap (${u && u.dims}, ${u && u.size} B, ${u && u.file})`);
	check(u && /^[א-ת]/.test(u.text) && u.text.length <= 200 && !/—/.test(u.text), `the text starts with a Hebrew word, ≤ 200 chars, no em dash (${u && u.text})`);
	check(u && u.msg.endsWith(u.msg.split('\n').pop()) && /\nhttps:\/\/od-sevev\.vercel\.app\/s\/bibi-leak\/\?via=img#r=[a-z0-9]{8}&k=leak$/.test(u.msg),
		`the message: the text, then the stub link alone on the last line (${u && u.msg.split('\n').pop()})`);
	for (const kind of ['leak', 'breaking', 'term', 'career', 'receipt', 'result']) {
		if (kind !== 'leak') {
			await P.page.click(`#od-sh-tabs button[data-kind="${kind}"]`);
			await P.page.waitForFunction((k) => window.odShareUI.state.p.kind === k, kind, { timeout: 8000 }).catch(() => {});
			await waitImage(P);
		}
		u = await ui(P);
		check(u.kind === kind && u.dims && u.dims[0] === 1080 && u.dims[1] === 1350, `${kind}: its card rendered (${u.dims}) and its text: ${u.text}`);
		await shot(P, `drawer-${kind}`);
	}
	// the story format
	await P.page.click('#od-sh-tabs button[data-kind="term"]');
	await P.page.waitForFunction(() => window.odShareUI.state.p.kind === 'term', null, { timeout: 8000 }).catch(() => {});
	await P.page.click('.od-sh-seg button[data-fmt="story"]');
	await waitImage(P, 'story');
	u = await ui(P);
	check(u.fmt === 'story' && u.dims && u.dims[0] === 1080 && u.dims[1] === 1920, `סטורי: a 1080×1920 card (${u.dims}, ${u.file})`);
	await shot(P, 'drawer-term-story');
	// text only: the link preview of the stub (its own og image and title)
	await P.page.click('.od-sh-seg button[data-fmt="text"]');
	await P.wait(600);
	u = await ui(P);
	const lp = await P.page.evaluate(() => [document.getElementById('od-sh-lp-img').src, document.getElementById('od-sh-lp-t').textContent]);
	check(u.fmt === 'text' && /\/og\/[a-z]+-term\.jpg$/.test(lp[0]) && lp[1].length > 4, `טקסט בלבד: the bubble shows the stub's link preview (${lp.join(' · ')})`);
	await shot(P, 'drawer-text-only');
	await P.page.click('.od-sh-seg button[data-fmt="sq"]');
	await waitImage(P);
	// family-safe: no leader's name in the text, the image re-renders
	await P.page.click('#od-sh-tabs button[data-kind="leak"]');
	await P.page.waitForFunction(() => window.odShareUI.state.p.kind === 'leak', null, { timeout: 8000 }).catch(() => {});
	await waitImage(P);
	await P.page.click('#od-sh-neutral');
	await P.page.waitForFunction(() => window.odShareUI.state.p.neutral && window.odShareUI.state.files['leak|sq|n'], null, { timeout: 15000 }).catch(() => {});
	await P.wait(400);
	u = await ui(P);
	check(u.neutral && !/ביבי|בן גביר|סמוטריץ|דרעי|בנט/.test(u.text) && /all-leak/.test(u.msg), `the family-safe leak names nobody and links all-leak (${u.text})`);
	await shot(P, 'drawer-leak-neutral');
	await P.page.click('#od-sh-neutral');
	await waitImage(P);
	// no navigator.share in headless Chromium: the primary is WhatsApp
	u = await ui(P);
	check(u.go === 'לשתף בוואטסאפ' && !u.goDisabled, `no navigator.share: the primary is WhatsApp (${u.go})`);
	const [pop] = await Promise.all([ctx.waitForEvent('page', { timeout: 10000 }).catch(() => null), P.page.click('#od-sh-go')]);
	if (pop) {
		const t = new URL(pop.url()).searchParams.get('text') || '';
		check(pop.url().startsWith('https://wa.me/') && /\?via=wa#r=/.test(t) && t.startsWith(u.text), `wa.me carries the text and the ?via=wa link (${t.split('\n').pop()})`);
		await pop.close();
	} else {
		check(false, 'WhatsApp opens a new tab');
	}
	u = await ui(P);
	check(u.track.includes('share/leak/wa/opened'), `analytics: share/leak/wa/opened (${u.track})`);
	check(/^https:\/\/t\.me\/share\/url\?url=.*via%3Dtg/.test(u.tg) && /^https:\/\/x\.com\/intent\/post\?text=.*via%3Dx/.test(u.x), 'the Telegram and X links carry their own via');
	await P.page.click('#od-sh-copy');
	await P.wait(500);
	const clip = await P.page.evaluate(() => navigator.clipboard.readText().catch(() => ''));
	u = await ui(P);
	check(clip.startsWith(u.text) && /\?via=copy#r=/.test(clip) && u.status === 'הטקסט והקישור הועתקו.', `להעתיק: the text and the ?via=copy link (${u.status})`);
	const [dl] = await Promise.all([P.page.waitForEvent('download', { timeout: 10000 }).catch(() => null), P.page.click('#od-sh-save')]);
	check(!!dl && /^od-sevev-(leak|kabala|tozaa)/.test(dl ? dl.suggestedFilename() : ''), `לשמור: the PNG downloads (${dl && dl.suggestedFilename()})`);
	if (dl) await dl.saveAs(`${out}/${wh}@${DPR}-card-leak.png`);
	// back closes it (its own history entry), the engine hears it
	await P.page.goBack().catch(() => {});
	await P.wait(800);
	u = await ui(P);
	ds = await desk(P);
	check(!u.open && !ds.open, `the back button closes the drawer, the engine's session ends (${JSON.stringify([u.open, ds.open])})`);
	check((await probe(P)).mode === 'main', 'the game stays in the round');
	// the media advisor: a moment, then the calm beat (no taps), the chat toast; its tap opens the drawer
	await P.page.evaluate(() => { window.odDevMoment = 'breaking'; });
	await P.page.waitForFunction(() => window.odShareState && window.odShareState.prompted, null, { timeout: 15000 }).catch(() => {});
	await P.wait(500);
	ds = await desk(P);
	check(ds.prompted, 'the moment brings the advisor\'s prompt after the calm beat');
	// the prompt queues behind a toast already up: wait for its plate to report (odDev runs at 4 Hz)
	await P.page.waitForFunction(() => window.odDev && window.odDev.hud && window.odDev.hud.toast && window.odDev.hud.toast.length === 4, null, { timeout: 8000 }).catch(() => {});
	const s = await probe(P);   // a toast stays 3 s: read and tap it before any screenshot
	const toast = s.hud && s.hud.toast;
	if (toast && toast[2] > 0) {
		await tap(P, css(P, toast[0] + toast[2] / 2, toast[1] + toast[3] / 2));
	} else {
		await tap(P, css(P, P.d.cw / 2, 200));
	}
	await P.page.waitForFunction(() => window.odShareUI.isOpen(), null, { timeout: 8000 }).catch(() => {});
	u = await ui(P);
	ds = await desk(P);
	check(u.open && u.kind === ds.promptKind, `the prompt's tap opens the drawer on its moment (${u.kind})`);
	await waitImage(P);
	await shot(P, 'drawer-from-prompt');
	if (await P.page.isVisible('#od-sh-x')) await P.page.click('#od-sh-x');
	await P.wait(700);
	console.log('  share log', JSON.stringify(await P.page.evaluate(() => (window.odShareLog || []).slice(-6))));
	await P.page.evaluate(() => { window.odDevMoment = 'leak'; });
	await P.wait(4000);
	ds = await desk(P);
	check(ds.moment === 'leak', 'a second moment lights the dot, and no second prompt in the session');
	// T3's header 📣
	const tabsY = P.d.logical[1] - 104;
	const cw = P.d.cw || 720;
	const w = Math.floor(cw / 16) * 4;
	await tap(P, css(P, cw - 3 * w + w / 2, tabsY + 52));
	await P.wait(1200);
	ds = await desk(P);
	check(ds.chatBtn && ds.chatBtn[0], `T3's header has the 📣 (${JSON.stringify(ds.chatBtn)})`);
	await shot(P, 'chat-header-share');
	if (ds.chatBtn && ds.chatBtn[0]) {
		await tap(P, css(P, ds.chatBtn[1], ds.chatBtn[2]));
		await P.page.waitForFunction(() => window.odShareUI.isOpen(), null, { timeout: 8000 }).catch(() => {});
		u = await ui(P);
		check(u.open && u.kind === 'leak', `T3's 📣 opens the drawer on the waiting moment (${u.kind})`);
	}
	await P.page.close();
	await ctx.close();
}

// 2. navigator.share (an iPhone) and an in-app browser without it
{
	const ctx = await context({ userAgent: IPHONE });
	const P = await boot(ctx, 'dev=1&speed=5&grant=50000', () => {
		window.__shared = [];
		navigator.canShare = (d) => !!(d && d.files && d.files.length);
		navigator.share = (d) => { window.__shared.push({ text: d.text, files: (d.files || []).map((f) => [f.name, f.type, f.size]) }); return Promise.resolve(); };
	});
	await handoff(P);
	await pickBibi(P);
	for (let i = 0; i < 4; i++) { await tap(P, hat(P), 40); await P.wait(80); }
	await seed(P);
	await P.page.evaluate(() => { window.odDevShare = 'career'; });
	await P.page.waitForFunction(() => window.odShareUI && window.odShareUI.isOpen(), null, { timeout: 10000 }).catch(() => {});
	await waitImage(P);
	let u = await ui(P);
	check(u.go === 'לשתף' && !u.goDisabled, `navigator.share: the primary is "לשתף", live once the PNG is there (${u.go})`);
	await shot(P, 'drawer-career-native');
	await P.page.click('#od-sh-go');
	await P.wait(800);
	const sh = await P.page.evaluate(() => window.__shared);
	u = await ui(P);
	const clip = await P.page.evaluate(() => navigator.clipboard.readText().catch(() => ''));
	check(sh.length === 1 && sh[0].files.length === 1 && sh[0].files[0][0] === 'od-sevev-career.png' && sh[0].files[0][1] === 'image/png' && /via=img/.test(sh[0].text),
		`navigator.share got the PNG File and the text with ?via=img (${JSON.stringify(sh[0] && sh[0].files)})`);
	check(clip === (sh[0] && sh[0].text) && u.status.length > 0, `iPhone: the caption waits on the clipboard (${u.status})`);
	check(u.track.includes('share/career/img/shared'), `analytics: share/career/img/shared (${u.track})`);
	await shot(P, 'drawer-after-native');
	await P.page.close();
	await ctx.close();
	const ctx2 = await context({ userAgent: INSTA });
	const Q = await boot(ctx2, 'dev=1&speed=5&grant=50000', () => { delete Navigator.prototype.share; delete Navigator.prototype.canShare; });
	await handoff(Q);
	await pickBibi(Q);
	for (let i = 0; i < 4; i++) { await tap(Q, hat(Q), 40); await Q.wait(80); }
	await seed(Q);
	await Q.page.evaluate(() => { window.odDevShare = 'result'; });
	await Q.page.waitForFunction(() => window.odShareUI && window.odShareUI.isOpen(), null, { timeout: 10000 }).catch(() => {});
	await waitImage(Q);
	u = await ui(Q);
	check(u.inapp && u.go === 'לשתף בוואטסאפ', `an Instagram in-app browser: the hint, WhatsApp first (${u.go})`);
	await Q.page.evaluate(() => { const s = document.querySelector('#od-share .od-sh-sheet'); s.scrollTop = s.scrollHeight; });
	await Q.wait(300);
	await shot(Q, 'drawer-inapp-fallback');
	await Q.page.close();
	await ctx2.close();
}

// 3. a stub: its own og tags, the forward with ?via= and the hash, the arrival
{
	const ctx = await context();
	const page = await ctx.newPage();
	page.on('pageerror', (e) => errors.push(e.message));
	const raw = await (await page.request.get(`${ORIGIN}/s/smotrich-leak/index.html`)).text();
	const meta = (k) => ((raw.match(new RegExp(`<meta property="${k}" content="([^"]*)"`)) || [])[1] || '');
	check(meta('og:title') === 'הודלף מהקואליציה של סמוטריץ׳', `the stub's og:title (${meta('og:title')})`);
	check(meta('og:image') === SITE + 'og/smotrich-leak.jpg' && meta('og:image:width') === '1200' && meta('og:image:height') === '630' && meta('og:image:type') === 'image/jpeg',
		`absolute og:image 1200×630 JPEG (${meta('og:image')})`);
	const img = await page.request.get(`${ORIGIN}/og/smotrich-leak.jpg`);
	const ib = await img.body();
	check(img.ok() && ib.length <= 300 * 1024 && ib[0] === 0xff && ib[1] === 0xd8, `the og image is a JPEG ≤ 300 KB (${ib.length} B)`);
	fs.writeFileSync(`${out}/${wh}@${DPR}-og-smotrich-leak.jpg`, ib);
	const head = raw.split('</head>')[0].replace(/</g, '&lt;');
	await page.setContent(`<html dir="ltr"><body style="margin:0;background:#fff;font:12px monospace"><pre style="white-space:pre-wrap;padding:8px">${head}</pre><img src="data:image/jpeg;base64,${ib.toString('base64')}" style="width:100%"></body></html>`);
	await page.screenshot({ path: `${out}/${wh}@${DPR}-stub-head.png`, fullPage: true });
	console.log('  shot', `${out}/${wh}@${DPR}-stub-head.png`);
	await page.goto(`${ORIGIN}/s/smotrich-leak/?via=wa#r=abc12345&k=leak&s=77`);
	await page.waitForFunction(() => window.odArrival !== undefined && document.getElementById('canvas'), null, { timeout: 20000 }).catch(() => {});
	const arr = await page.evaluate(() => ({ a: window.odArrival, url: location.href, log: window.odTrackLog }));
	check(arr.a && arr.a.kind === 'leak' && arr.a.via === 'wa' && arr.a.ref === 'abc12345' && arr.a.params.s === '77' && arr.a.params.v === 'smotrich-leak',
		`window.odArrival from the hash (${JSON.stringify(arr.a)})`);
	check(!/#|via=/.test(arr.url), `the address bar is clean (${arr.url})`);
	check(arr.log.includes('arrive/leak/wa'), `analytics: arrive/leak/wa (${arr.log})`);
	const P = { page, cdp: await ctx.newCDPSession(page), tid: 1, ctx, wait: (ms) => page.waitForTimeout(ms) };
	await handoff(P);
	await pickBibi(P);
	await tap(P, hat(P));
	await P.wait(1500);
	await shot(P, 'arrival-toast');
	await page.close();
	await ctx.close();
}

// the old share check's context for part 5
const ctx = await context();

// 5. the brawl cue and the pending chip
{
	// `&chat=N` seeds the group and an open brawl (dev_probe) on a save that already has its leader
	// (seeded before the first pick, the pick is refused): one plain visit picks Bibi first, as the
	// old driver's earlier parts did on the shared context
	{
		const P0 = await boot(ctx, 'dev=1&grant=50000');
		await handoff(P0);
		await pickBibi(P0);
		await tap(P0, hat(P0));
		await P0.wait(1500);
		await P0.page.close();
	}
	const P = await boot(ctx, 'dev=1&grant=50000&chat=14');
	await handoff(P);
	await pickBibi(P);
	await tap(P, hat(P));
	await P.page.waitForFunction(() => window.odDev && window.odDev.brawlCue && window.odDev.brawlCue.visible, null, { timeout: 20000 }).catch(() => {});
	await P.wait(600);
	let s = await probe(P);
	check(s.brawlCue.visible && s.chat.openBrawl && !s.chat.open, 'an open brawl with T3 closed: the cloud stands under Row B');
	await shot(P, 'brawl-cue');
	await tap(P, css(P, s.brawlCue.x, s.brawlCue.y));
	await P.wait(1400);
	s = await probe(P);
	check(s.chat.open && !s.brawlCue.visible, 'the cue opens T3 (and leaves the stage)');
	const [top, bottom] = s.chat.thread;
	const br = s.chat.brawls[0];
	check(br && br[1] > top && br[1] < bottom, `T3 opens at the brawl's "צאו החוצה" (${br && br[1]} in ${top}-${bottom})`);
	check(s.chat.pending.visible && s.chat.pending.n >= 1, `the "{n} ממתינים ↑" chip counts the pill above (${JSON.stringify(s.chat.pending)})`);
	await shot(P, 'pending-chip');
	const n0 = s.chat.pending.n;
	const target = s.chat.pending.seq;
	await tap(P, css(P, s.chat.pending.x, s.chat.pending.y));
	await P.wait(900);
	s = await probe(P);
	const pill = s.chat.pills.find((p) => p[2] === target);
	check(pill && pill[1] > top && pill[1] < bottom, `the chip's tap brings the nearest open pill in (seq ${target} at y ${pill && pill[1]})`);
	check(!s.chat.pending.visible || s.chat.pending.n < n0, `the chip counts it gone (${JSON.stringify(s.chat.pending)})`);
	await shot(P, 'pending-after');
	await P.page.close();
}

console.log(`  page errors: ${errors.length ? errors.join(' | ') : 'none'}`);
if (errors.length) failed++;
await ctx.close();
await browser.close();
console.log(failed ? `SHARE_WEB: FAIL (${failed})` : 'SHARE_WEB: PASS');
process.exit(failed ? 1 : 0);
