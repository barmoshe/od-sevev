// Views wave 6 in the runtime origin (headless Chromium, a phone size, real touches):
//   1. O4 the receipt and O5 the result card from T4's rows (review R25): the sheet, the exported PNG
//      ("לשמור תמונה" → a download, saved next to the screenshots), "לשתף" (no navigator.share in
//      headless Chromium: the PNG downloads and the text + URL go to the clipboard), and
//      "לשתף בוואטסאפ" (Bar 2026-09-29: a desktop opens wa.me/?text=… in a new tab; the link must
//      decode to the share text, which ends with the site URL).
//   2. The brawl stage cue under Row B (`&chat=N` seeds the group and an open brawl), its tap into
//      T3 at the brawl, and the chat's "{n} ממתינים ↑" chip, whose tap brings the open pill in.
//   3. About's invite: the WhatsApp link and the page's absolute og:url / og:image.
// Positions come from window.odDev (ui/dev_probe.gd, `?dev=1`) and window.odModal (the sheet).
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
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: true, hasTouch: true,
	acceptDownloads: true, permissions: ['clipboard-read', 'clipboard-write'] });
await ctx.route('https://wa.me/**', (r) => r.fulfill({ status: 200, contentType: 'text/html', body: '<title>wa</title>' }));
let failed = 0;
const check = (ok, msg) => { console.log(`  ${ok ? 'ok  ' : 'FAIL'}  ${msg}`); if (!ok) failed++; };
const errors = [];

async function boot(query) {
	const page = await ctx.newPage();
	page.on('pageerror', (e) => errors.push(e.message));
	await page.goto(`${base}${base.includes('?') ? '&' : '?'}${query}`);
	const cdp = await ctx.newCDPSession(page);
	const P = { page, cdp, tid: 1 };
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
const modal = (P) => P.page.evaluate(() => window.odModal || null);
async function shot(P, name) {
	const p = `${out}/${wh}@${DPR}-${name}.png`;
	await P.page.screenshot({ path: p });
	console.log('  shot', p);
}
const hat = (P) => css(P, P.d.hat[0], P.d.hat[1]);
const btn = (m, i) => m.buttons[i];

// 1. O4 / O5 from T4
{
	const P = await boot('dev=1&grant=5000000&susp=20&evo=5');
	await handoff(P);
	await tap(P, hat(P));
	await P.wait(1500);
	let s = await probe(P);
	// a few sources, so the receipt has income lines
	for (let k = 0; k < 4; k++) {
		const r = (s.shop.rows || []).filter((x) => x[3]);
		if (r.length) await tap(P, css(P, r[k % r.length][0], r[k % r.length][1]));
		await P.wait(700);
		s = await probe(P);
	}
	await P.wait(1500);
	s = await probe(P);
	check(s.thermo.shown, 'the thermometer is up (&susp=20)');
	await tap(P, css(P, s.thermo.x, s.thermo.y));
	await P.page.waitForFunction(() => window.odDev && window.odDev.dossier.open && window.odDev.dossier.rows.length > 0, null, { timeout: 15000 }).catch(() => {});
	await P.wait(700);
	s = await probe(P);
	const kinds = s.dossier.rows.map((r) => r[2]);
	check(kinds[0] === 'receipt' && kinds[1] === 'result', `R25: T4 shows the receipt and result rows (${kinds.join(',')})`);
	await shot(P, 't4-share-rows');
	for (const kind of ['receipt', 'result']) {
		const tag = kind === 'receipt' ? 'o4-receipt' : 'o5-result';
		s = await probe(P);
		const row = s.dossier.rows.find((r) => r[2] === kind);
		await tap(P, css(P, row[0], row[1]));
		await P.page.waitForFunction(() => window.odModal && window.odModal.open && window.odModal.ready, null, { timeout: 30000 }).catch(() => {});
		await P.wait(900);
		let m = await modal(P);
		check(m && m.id === (kind === 'receipt' ? 'SHARE_RECEIPT' : 'SHARE_RESULT') && m.ready, `${tag}: the sheet is open and rendered (${m && m.id})`);
		check(m.png > 5000, `${tag}: a real PNG was read back (${m.png} bytes)`);
		const labels = m.buttons.map((b) => b[2]);
		check(labels.includes('לשתף') && labels.includes('לשמור תמונה') && labels.includes('לשתף בוואטסאפ') && labels.includes('סגור'),
			`${tag}: לשתף, לשמור תמונה, לשתף בוואטסאפ, סגור (${labels.join(' | ')})`);
		check(m.text.endsWith(' ' + SITE) && !/הקוסם/.test(m.text), `${tag}: the message ends with the URL, says no הקוסם (${m.text})`);
		const dp = m.artPx * P.d.f;
		check(Math.abs(dp - Math.round(dp)) < 1e-6, `${tag}: the preview is ${m.artPx} logical px per art px = ${dp} device px (whole)`);
		await shot(P, tag);
		// the exported image: "לשמור תמונה" downloads it
		const save = btn(m, labels.indexOf('לשמור תמונה'));
		const [dl] = await Promise.all([P.page.waitForEvent('download', { timeout: 15000 }).catch(() => null), tap(P, css(P, save[0], save[1]))]);
		check(!!dl, `${tag}: "לשמור תמונה" downloads the card`);
		if (dl) {
			const p = `${out}/${wh}@${DPR}-${tag}-export.png`;
			await dl.saveAs(p);
			const b = fs.readFileSync(p);
			const w = b.readUInt32BE(16);
			const h = b.readUInt32BE(20);
			check(w === 1080 && h === 1350, `${tag}: the PNG is 1080×1350 (${w}×${h}, ${dl.suggestedFilename()})`);
			console.log('  export', p);
		}
		await P.wait(400);
		// "לשתף": headless Chromium has no navigator.share → the PNG downloads and the text is copied
		const share = btn(m, labels.indexOf('לשתף'));
		const [dl2] = await Promise.all([P.page.waitForEvent('download', { timeout: 15000 }).catch(() => null), tap(P, css(P, share[0], share[1]))]);
		await P.wait(700);
		const log = await P.page.evaluate(() => window.odShareLog.slice(-1)[0]);
		const clip = await P.page.evaluate(() => navigator.clipboard.readText().catch(() => ''));
		check(!!dl2 && log && log[1] === 'fallback', `${tag}: "לשתף" falls back to download + copy (${JSON.stringify(log)})`);
		check(clip === m.text, `${tag}: the clipboard holds the share text with the URL`);
		await shot(P, `${tag}-after-share`);
		// "לשתף בוואטסאפ": a desktop UA opens wa.me in a new tab
		const wa = btn(m, labels.indexOf('לשתף בוואטסאפ'));
		const [pop] = await Promise.all([ctx.waitForEvent('page', { timeout: 15000 }).catch(() => null), tap(P, css(P, wa[0], wa[1]))]);
		check(!!pop, `${tag}: WhatsApp opens a new tab`);
		if (pop) {
			await pop.waitForLoadState().catch(() => {});
			const u = new URL(pop.url());
			check(u.origin === 'https://wa.me' && u.searchParams.get('text') === m.text, `${tag}: wa.me/?text= decodes to the share text (${pop.url().slice(0, 80)}…)`);
			await pop.close();
		}
		await P.page.keyboard.press('Escape');
		await P.wait(700);
		m = await modal(P);
		check(!m.open, `${tag}: Esc closes the sheet`);
	}
	// About's invite and the OG tags
	const a = await P.page.evaluate(() => {
		const og = (k) => (document.querySelector(`meta[property="${k}"]`) || {}).content;
		return { url: og('og:url'), image: og('og:image'), wa: document.getElementById('od-invite-wa').href, site: window.odSiteUrl };
	});
	check(a.url === SITE && a.image === SITE + 'og.jpg' && a.site === SITE, `absolute og:url / og:image and window.odSiteUrl (${a.url}, ${a.image})`);
	const inv = new URL(a.wa).searchParams.get('text');
	// the invite is leader-neutral since the picker shipped (SHARE_TEXT_INVITE took the _NEXT copy;
	// it no longer names ביבי): the text, then the site
	check(inv && inv.endsWith(' ' + SITE) && inv.length > SITE.length + 8, `About's WhatsApp invite: ${inv}`);
	await P.page.evaluate(() => window.odOpenAbout());
	await P.wait(400);
	await P.page.evaluate(() => document.getElementById('od-invite').scrollIntoView({ block: 'center' }));
	await P.wait(300);
	await shot(P, 'about-invite');
	await P.page.close();
}

// 2. the brawl cue and the pending chip
{
	const P = await boot('dev=1&grant=50000&chat=14');
	await handoff(P);
	// LEADER_PICK comes first: pick ביבי (the seeded brawl is his lineup's Amsalem and Smotrich), not
	// whichever tile the random order puts under the Magician
	const pk = await P.page.evaluate(() => window.odPick || null);
	if (pk && pk.open) {
		const c = pk.cells.find((q) => q[2] === 'bibi') || pk.cells[0];
		await P.wait(500);
		await tap(P, css(P, c[0], c[1]));
		await P.page.waitForFunction(() => !(window.odPick && window.odPick.open), null, { timeout: 8000 }).catch(() => {});
		await P.wait(1200);
	}
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
await browser.close();
console.log(failed ? `SHARE_WEB: FAIL (${failed})` : 'SHARE_WEB: PASS');
process.exit(failed ? 1 : 0);
