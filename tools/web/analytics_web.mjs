// The analytics layer and the SEO head in the runtime origin (2026-10-01): the shell's window.odTrack
// (virtual page views under /play/ for Vercel Web Analytics; on localhost nothing is sent and
// window.odTrackLog keeps every step), the funnel events the engine hands it (main.gd _funnel →
// window.odTrackFunnel), the once-per-device dedupe, the return-visit bucket, the /index.html → /
// rewrite (va beforeSend), and the crawlable head + About: canonical, JSON-LD, the FAQ, ABOUT_7_TELEMETRY.
//   node tools/web/analytics_web.mjs <url> <out dir> [WxH@DPR]
// Serve build/web first (python3 -m http.server --directory build/web).
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const { makePlayer } = await import('./round_play.mjs');
const [base, out, dev = '390x844@2'] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const [wh, dprS] = dev.split('@');
const [W, H] = wh.split('x').map(Number);
const DPR = Number(dprS);
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: true, hasTouch: true });
// a returning player: first played 3 days ago, last seen yesterday → return/d2-7
await ctx.addInitScript(() => {
	if (sessionStorage.getItem('seeded')) {
		return;
	}
	sessionStorage.setItem('seeded', '1');
	const day = (n) => { const d = new Date(); d.setDate(d.getDate() - n); return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate(); };
	localStorage.setItem('odsevev.first', day(3));
	localStorage.setItem('odsevev.last', day(1));
});
const page = await ctx.newPage();
const errors = [];
page.on('pageerror', (e) => errors.push(e.message));
const cdp = await ctx.newCDPSession(page);
const log = (...a) => console.log(...a);
const P = makePlayer({ page, cdp, DPR, out, wh, log });
const { wait, probe, css, tapAt } = P;
let failed = 0;
const check = (ok, msg) => { log(`  ${ok ? 'ok  ' : 'FAIL'} ${msg}`); if (!ok) failed++; };
const steps = () => page.evaluate(() => window.odTrackLog.slice());

await P.st.ready;
await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1`);

// 1. the head and the About page (static HTML: what a crawler reads)
const head = await page.evaluate(() => {
	const ld = document.querySelector('script[type="application/ld+json"]');
	let json = null;
	try { json = JSON.parse(ld.textContent); } catch (e) { /* stays null */ }
	return {
		canonical: (document.querySelector('link[rel="canonical"]') || {}).href || '',
		robots: (document.querySelector('meta[name="robots"]') || {}).content || '',
		json,
		faqAbout: document.querySelectorAll('#od-about h3').length,
		about: document.getElementById('od-about').textContent,
		left: (document.documentElement.innerHTML.match(/\{\{[A-Z0-9_]+\}\}/g) || []),
	};
});
check(/^https:\/\/.+\/$/.test(head.canonical), `canonical is the absolute site URL (${head.canonical})`);
check(head.robots.includes('index'), `robots meta (${head.robots})`);
check(!!head.json && head.json['@type'].includes('VideoGame') && head.json.inLanguage === 'he' && head.json.description.length > 20
	&& head.json.offers.price === '0', `JSON-LD parses: VideoGame, he, a description, free (${head.json && head.json.description})`);
check(head.faqAbout === 3, `About carries the three FAQ questions (${head.faqAbout})`);
check(head.about.includes('נתוני שימוש אנונימיים'), 'About says anonymous usage data is collected (ABOUT_7_TELEMETRY)');
check(head.left.length === 0, `no placeholder left in the page (${head.left.join(', ')})`);

// 2. beforeSend: an old Home Screen icon's /index.html counts as /
const rewritten = await page.evaluate(() => {
	const bs = (window.vaq || []).find((a) => a[0] === 'beforeSend');
	return bs ? bs[1]({ type: 'pageview', url: 'https://x.test/index.html?dev=1' }).url : '';
});
check(rewritten === 'https://x.test/?dev=1', `beforeSend maps /index.html to / (${rewritten})`);
const queuedViews = await page.evaluate(() => (window.vaq || []).filter((a) => a[0] === 'pageview').length);
check(queuedViews === 0, `no page view is queued on localhost (${queuedViews})`);

// 3. the load and the return visit
await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
await page.click('#od-quiet');
await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
await wait(1200);
await P.refresh();
let st = await steps();
check(st.includes('loaded'), `the engine's load reports loaded (${st})`);
check(st.includes('return/d2-7'), `a player back 3 days after the first visit reports return/d2-7 (${st})`);

// 4. a pick, the first taps
const pk = await page.evaluate(() => window.odPick || null);
const cell = ((pk && pk.cells) || []).find((c) => c[2] === 'bennett');
check(!!cell, 'the picker shows בנט');
if (cell) {
	await tapAt(css(cell[0], cell[1]));
	await page.waitForFunction(() => window.odDev && window.odDev.mode !== 'pick', null, { timeout: 8000 }).catch(() => {});
	await wait(400);
}
const s = await probe();
check(s && s.leader === 'bennett', `the pick lands (leader ${s && s.leader})`);
for (let i = 0; i < 3; i++) {
	await tapAt(P.hat());
	await wait(300);
}
await wait(500);
st = await steps();
check(st.includes('picked/bennett'), `the pick reports picked/bennett (${st})`);
check(st.filter((x) => x === 'first-tap').length === 1, `first-tap once in three taps (${st})`);
const again = await page.evaluate(() => { window.odTrack('first-tap'); window.odTrack('seats/61'); return window.odTrackLog.length; });
check(again === st.length, 'a second first-tap and an unknown step are dropped');
const funnel = await page.evaluate(() => (window.odFunnel || []).map((e) => e.ev));
check(funnel.includes('first_tap') && funnel.includes('leader_pick_committed'), `window.odFunnel keeps the engine's events (${funnel})`);

// 5. a reload the same day: no second return step, no second first-tap
await page.reload();
await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 }).catch(async () => {
	await page.click('#od-quiet').catch(() => {});
	await page.waitForFunction(() => window.mbHandoffDone > 0, null, { timeout: 120000 });
});
await wait(800);
st = await steps();
check(!st.some((x) => x.startsWith('return/')), `the same day again reports no return (${st})`);
await P.shot('a1-after-reload');

log(`  page errors: ${errors.length ? JSON.stringify(errors.slice(0, 5)) : 'none'}`);
await browser.close();
log(failed ? `FAIL (${failed})` : 'PASS');
process.exit(failed || errors.length ? 1 : 0);
