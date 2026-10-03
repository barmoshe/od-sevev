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
// a page that was playing and comes back without a pagehide (&crash=1): an iOS out-of-memory reload
await ctx.addInitScript(() => {
	if (location.search.includes('crash=1')) {
		sessionStorage.setItem('odsevev.playing', '1');
	}
});
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
		aboutLink: !!document.querySelector('#od-about a[href="about.html"]'),
		mailto: !!document.querySelector('#od-about a[href="mailto:1barmoshe1@gmail.com"]'),
		title: document.title,
		h1s: [...document.querySelectorAll('h1')].map((x) => x.textContent),
		headSizes: ['od-title', 'od-about-title'].map((id) => { const el = document.getElementById(id); el.closest('[hidden]') && el.closest('[hidden]').removeAttribute('hidden'); return el.tagName + ':' + getComputedStyle(el).fontSize; }),
		splashAlt: (document.getElementById('status-splash') || {}).alt || '',
		description: (document.querySelector('meta[name="description"]') || {}).content || '',
		left: (document.documentElement.innerHTML.match(/\{\{[A-Z0-9_]+\}\}/g) || []),
	};
});
check(/^https:\/\/.+\/$/.test(head.canonical), `canonical is the absolute site URL (${head.canonical})`);
check(head.robots.includes('index'), `robots meta (${head.robots})`);
check(!!head.json && head.json['@type'].includes('VideoGame') && head.json.inLanguage === 'he' && head.json.description.length > 20
	&& head.json.offers.price === '0', `JSON-LD parses: VideoGame, he, a description, free (${head.json && head.json.description})`);
check(head.faqAbout === 5, `About carries the five FAQ questions (${head.faqAbout})`);
check(head.aboutLink, 'About links to about.html');
check(head.h1s.length === 1 && head.h1s[0].includes('משחק הבחירות'), `one h1, the game's name (${head.h1s.join(' | ')})`);
check(head.headSizes.every((x) => x === 'H2:22px'), `the dialogs' titles are h2 at the old size (${head.headSizes})`);
check(head.splashAlt === 'עוד סבב', `the loading splash has alt text (${head.splashAlt})`);
check(head.about.includes('בר משה') && head.mailto, 'About names its maker, with the mail as a link');
check(head.title.includes('משחק הבחירות') && head.title.includes('2026'), `the title carries the search words (${head.title})`);
check(head.description.startsWith('משחק בחירות סאטירי'), `meta description is META_DESCRIPTION (${head.description})`);
check(!!head.json && head.json.author && head.json.author.name === 'בר משה' && /^\d{4}-\d\d-\d\d$/.test(head.json.dateModified || ''),
	`JSON-LD names the author and a dateModified (${head.json && head.json.dateModified})`);

// 1b. the static About page (crawlers that run no JS read it; its one script counts the visit)
const ap = await page.evaluate(async () => {
	const r = await fetch('about.html');
	const t = await r.text();
	const doc = new DOMParser().parseFromString(t, 'text/html');
	let ld = null;
	try { ld = JSON.parse(doc.querySelector('script[type="application/ld+json"]').textContent); } catch (e) { /* null */ }
	return { status: r.status, h1: (doc.querySelector('h1') || {}).textContent || '', faq: doc.querySelectorAll('h3').length,
		left: (t.match(/\{\{[A-Z0-9_]+\}\}/g) || []), canonical: (doc.querySelector('link[rel="canonical"]') || {}).href || '',
		lead: (doc.querySelector('.lead') || {}).textContent || '', scripts: doc.querySelectorAll('script:not([type])').length,
		ld: ld ? ld['@type'] + ':' + (ld.mainEntity || []).length : '' };
});
check(ap.status === 200 && ap.h1.includes('משחק הבחירות'), `about.html serves its h1 (${ap.status}, ${ap.h1})`);
check(ap.lead.startsWith('עוד סבב הוא משחק דפדפן'), 'about.html opens on the direct answer');
check(ap.faq === 5 && ap.ld === 'FAQPage:5', `about.html: 5 FAQ questions, FAQPage JSON-LD (${ap.faq}, ${ap.ld})`);
check(ap.left.length === 0 && ap.scripts === 1, `about.html: no placeholder, only the page-view script (${ap.left.join(', ')}; ${ap.scripts})`);
check(/\/about\.html$/.test(ap.canonical), `about.html canonical (${ap.canonical})`);
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
const loaders = await page.evaluate(() => [...document.querySelectorAll('script[src]')].map((x) => x.getAttribute('src')).filter((x) => /k7|k8|_vercel/.test(x)));
check(loaders.length === 0, `no analytics script is loaded on localhost (${loaders})`);

// 3. the load and the return visit
await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
await page.click('#od-quiet');
await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
await wait(1200);
await P.refresh();
let st = await steps();
check(st.some((x) => /^loaded\/back\/(lt3|3-8|8-20|gt20)s$/.test(x)), `a returning device's load reports loaded/back/<time> (${st})`);
check(st.includes('return/d2-7'), `a player back 3 days after the first visit reports return/d2-7 (${st})`);

// 4. a pick, the first taps
const pk = await page.evaluate(() => window.odPick || null);
const cell = ((pk && pk.cells) || []).find((c) => c[2] === 'bennett');
check(!!cell, 'the picker shows בנט');
if (cell) {
	await tapAt(css(cell[0], cell[1]));   // the ballot booth (ADR 0007): a tap chooses the slip, a second tap votes
	await wait(400);
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
check(st.filter((x) => x.startsWith('first-tap/')).length === 1 && st.includes('first-tap/off'),
	`first-tap once in three taps, with the disclaimer's choice (quiet → off) (${st})`);
const again = await page.evaluate(() => { window.odTrack('first-tap/on'); window.odTrack('seats/61'); return window.odTrackLog.length; });
check(again === st.length, 'a second first-tap (other sound) and an unknown step are dropped');
// leaving the tab: one session step, however many times it is hidden
const sess = await page.evaluate(() => {
	Object.defineProperty(document, 'visibilityState', { value: 'hidden', configurable: true });
	document.dispatchEvent(new Event('visibilitychange'));
	document.dispatchEvent(new Event('visibilitychange'));
	Object.defineProperty(document, 'visibilityState', { value: 'visible', configurable: true });
	return window.odTrackLog.filter((x) => x.startsWith('session/'));
});
check(sess.length === 1 && /^session\/(lt1|1-3|3-10|10-30|gt30)m$/.test(sess[0]), `hiding the page logs one session step (${sess})`);
const funnel = await page.evaluate(() => (window.odFunnel || []).map((e) => e.ev));
check(funnel.includes('first_tap') && funnel.includes('leader_pick_committed'), `window.odFunnel keeps the engine's events (${funnel})`);

// 5. back the same day after a crash-like reload: reload-after-crash, no second return step
await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1&crash=1`);
await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 }).catch(async () => {
	await page.click('#od-quiet').catch(() => {});
	await page.waitForFunction(() => window.mbHandoffDone > 0, null, { timeout: 120000 });
});
await wait(800);
st = await steps();
check(!st.some((x) => x.startsWith('return/')), `the same day again reports no return (${st})`);
check(st.includes('reload-after-crash'), `a playing page reloaded without pagehide reports reload-after-crash (${st})`);
await P.shot('a1-after-reload');

log(`  page errors: ${errors.length ? JSON.stringify(errors.slice(0, 5)) : 'none'}`);
await browser.close();
log(failed ? `FAIL (${failed})` : 'PASS');
process.exit(failed || errors.length ? 1 : 0);
