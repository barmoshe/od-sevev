// Screenshots the views of the 2026-09-29 views wave in the runtime origin (headless Chromium, a
// phone size, real touches): the court summons card and its chip (R10), the court card over T3
// (R21), the chat header and a partner card (R12, R22), the reset confirm O10 (R7), the About page
// with its sticky back (R2), and the return card O1 on a cold load after 3 h away (R8). Positions
// come from window.odDev (ui/dev_probe.gd, `?dev=1`) and window.odModal.
//   node tools/web/modals_web.mjs <url> <out dir> [WxH@DPR]
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const [base, out, dev = '390x844@2'] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const [wh, dprS] = dev.split('@');
const [W, H] = wh.split('x').map(Number);
const DPR = Number(dprS);
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: true, hasTouch: true });
let failed = 0;
const check = (ok, msg) => { console.log(`  ${ok ? 'ok  ' : 'FAIL'}  ${msg}`); if (!ok) failed++; };
const errors = [];

async function boot(query, shift = 0) {
	const page = await ctx.newPage();
	page.on('pageerror', (e) => errors.push(e.message));
	if (shift) {
		// a cold load `shift` ms later: every clock the page reads runs ahead (the away credit)
		await page.addInitScript((ms) => {
			const now = Date.now;
			Date.now = () => now() + ms;
			const DT = Date;
			// eslint-disable-next-line no-global-assign
			Date = class extends DT { constructor(...a) { if (a.length) { super(...a); } else { super(now() + ms); } } static now() { return now() + ms; } };
		}, shift);
	}
	await page.goto(`${base}${base.includes('?') ? '&' : '?'}${query}`);
	const cdp = await ctx.newCDPSession(page);
	const P = { page, cdp, tid: 1 };
	P.wait = (ms) => page.waitForTimeout(ms);
	return P;
}
async function handoff(P, first = true) {
	// the disclaimer shows once per browser profile: a later page in this context skips it
	await P.page.waitForFunction(() => (window.mbHandoffDone > 0) || (document.getElementById('od-sound') && document.getElementById('od-sound').offsetParent !== null), null, { timeout: 90000 });
	if (first && await P.page.evaluate(() => !(window.mbHandoffDone > 0))) {
		await P.page.click('#od-quiet');
	}
	await P.page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
	await P.wait(1200);
	P.d = await P.page.evaluate(() => window.odDisplay);
	P.cv = await P.page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { x: r.x, y: r.y }; });
}
const css = (P, x, y) => [P.cv.x + x * P.d.f / DPR, P.cv.y + y * P.d.f / DPR];
const col = (P, x, y) => css(P, x + P.d.ox, y);
async function tap(P, [x, y], hold = 60) {
	const id = P.tid++;
	await P.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id }] });
	await P.wait(hold);
	await P.cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
}
const probe = (P) => P.page.evaluate(() => window.odDev || null);
async function shot(P, name) {
	const p = `${out}/${wh}@${DPR}-${name}.png`;
	await P.page.screenshot({ path: p });
	console.log('  shot', p);
}
const hat = (P) => css(P, P.d.hat[0], P.d.hat[1]);
// mobile-first §5.3: four fluid slots of floor4(cw / 4), right → left; the remainder goes to slot 4
const tabX = (P, i) => { const cw = P.d.cw || 720; const w = Math.floor(cw / 16) * 4; return i >= 4 ? (cw - 3 * w) / 2 : cw - i * w + w / 2; };
const tab = (P, i) => col(P, tabX(P, i), P.d.logical[1] - 104 + 52);

// 1. the court: the summons card and chip, then the testimony over T3
{
	const P = await boot('dev=1&grant=50000&susp=100&aide=300');
	await handoff(P);
	await tap(P, hat(P));
	await P.wait(2500);
	for (let i = 0; i < 3; i++) { await tap(P, hat(P)); await P.wait(200); }
	await P.page.waitForFunction(() => window.odDev && window.odDev.court.card, null, { timeout: 30000 }).catch(() => {});
	await P.wait(1600);   // past the tap-burst guard and the card's entry
	let s = await probe(P);
	check(s && s.court.card && s.court.phase === 'summons', `the summons card is up (${s && JSON.stringify(s.court)})`);
	await shot(P, 'r10-court-summons');
	// fold it: the chip reads "זימון"
	await P.page.keyboard.press('Escape');
	await P.wait(800);
	s = await probe(P);
	check(s.court.mode === 'chip' && !s.modal, `Esc folds the card to the chip, no settings (${s.court.mode}, modal '${s.modal}')`);
	await shot(P, 'r10-court-chip-summons');
	// the group: buy sources (one every 2.6 s: C1 pings 2 s after the last purchase)
	for (let k = 0; k < 6; k++) {
		const r = (s.shop.rows || []).filter((x) => x[3]);   // one of each kind, top down (C1's tab needs 3 kinds)
		if (r.length) await tap(P, css(P, r[k % r.length][0], r[k % r.length][1]));
		await P.wait(2600);
		s = await probe(P);
	}
	check(s.groupOpen, 'C1: the group opened');
	await P.wait(300);
	await shot(P, 'r5-chat-toast');
	// the court card expanded again from its chip, then T3 opened under it (the card stays on top).
	// Wait for the testimony: the summons turning into it folds an expanded card by design.
	await P.page.waitForFunction(() => window.odDev && window.odDev.court.phase === 'court', null, { timeout: 60000 }).catch(() => {});
	await tap(P, col(P, 96, P.d.lowerY + 42));
	await P.wait(900);
	s = await probe(P);
	check(s.court.card && s.court.mode === 'open', `the chip unfolds the card (${s.court.mode})`);
	await shot(P, 'r21-court-expanded');
	await tap(P, tab(P, 3));
	await P.wait(1200);
	s = await probe(P);
	console.log('  after the tab tap:', JSON.stringify({ chat: s.chat.open, court: s.court, modal: s.modal }));
	check(s.chat.open && s.court.card, 'T3 open with the court card expanded over it');
	await shot(P, 'r21-court-over-chat');
	await P.page.keyboard.press('Escape');
	await P.wait(900);
	s = await probe(P);
	check(s.chat.open && s.court.mode === 'chip', `Esc folds the card first, T3 stays (${s.court.mode})`);
	await shot(P, 'r22-chat-header');
	// Aim at a settled thread. The live group keeps posting, and T3 follows the newest message while
	// it is at the bottom, so an avatar read from odDev (published 4×/s) can have scrolled away by the
	// time the tap lands: that, not the fold, was the "first tap after Esc not taken" (traced
	// 2026-09-29: the tap reached the thread, 16 px off the avatar the thread had just scrolled). A
	// press during the fold itself is the engine bug fixed then (a folding card takes no press).
	let last = '';
	for (let i = 0; i < 20; i++) {
		s = await probe(P);
		const now = JSON.stringify(s.chat.avatars);
		if (now === last) break;
		last = now;
		await P.wait(400);
	}
	const av = s.chat.avatars[0];   // the topmost avatar in view
	if (av) {
		await tap(P, css(P, av[0], av[1]));
		await P.wait(900);
		s = await probe(P);
		check(s.modal === 'PARTNER_CARD', `the first tap after the fold opens the partner card (${s.modal})`);
		await shot(P, 'r12-partner-card');
		await P.page.keyboard.press('Escape');
		await P.wait(500);
	} else {
		check(false, 'an avatar is in view');
	}
	await P.page.close();
}

// 2. settings → O10 and About
{
	const P = await boot('dev=1&grant=20000');
	await handoff(P);
	await tap(P, hat(P));
	await P.wait(1500);
	await P.page.keyboard.press('Escape');   // settings
	await P.wait(900);
	let s = await probe(P);
	check(s.modal === 'SETTINGS', `Esc opens the settings (${s.modal})`);
	await shot(P, 'r26-settings');
	const bs = s.modalButtons;
	const reset = bs[bs.length - 3];
	await tap(P, css(P, reset[0], reset[1]));
	await P.page.waitForFunction(() => window.odModal && window.odModal.open && window.odModal.id === 'RESET_CONFIRM', null, { timeout: 15000 }).catch(() => {});
	await P.wait(700);
	s = await probe(P);
	check(s.modal === 'RESET_CONFIRM', `the reset row opens O10 (${s.modal})`);
	await shot(P, 'r7-reset');
	await tap(P, [4, 4]);   // the backdrop does nothing
	await P.wait(500);
	s = await probe(P);
	check(s.modal === 'RESET_CONFIRM', 'a backdrop tap keeps O10');
	await P.page.keyboard.press('Escape');
	await P.wait(700);
	s = await probe(P);
	check(s.modal === 'SETTINGS', `Esc returns to the settings (${s.modal})`);
	const about = s.modalButtons[s.modalButtons.length - 4];
	await tap(P, css(P, about[0], about[1]));
	await P.page.waitForSelector('#od-about', { state: 'visible', timeout: 10000 }).catch(() => {});
	await P.wait(500);
	await shot(P, 'r2-about-top');
	const a = await P.page.evaluate(() => {
		const el = document.getElementById('od-about');
		const items = el.querySelectorAll('ul li');
		const link = el.querySelector('ul a');
		return { items: items.length, dir: el.querySelector('ul').getAttribute('dir'), link: link ? getComputedStyle(link).color : '', text: el.innerText };
	});
	check(a.items === 44 && a.dir === 'rtl', `44 public sources in an RTL list (${a.items}, ${a.dir})`);
	// palette v4: About is a white notice, its links flag blue (8.5:1; was #9fc3ff on the dark page)
	check(a.link === 'rgb(0, 56, 184)', `links are #0038b8 on the white notice (${a.link})`);
	check(!/NOT USED|GAP:|Bench only|never names/.test(a.text), 'no internal notes');
	await P.page.evaluate(() => { const el = document.getElementById('od-about'); el.scrollTop = el.scrollHeight / 2; });
	await P.wait(300);
	const back = await P.page.evaluate(() => { const r = document.getElementById('od-about-back').getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height }; });
	check(back.y >= 0 && back.y < 40 && back.x < 120 && back.h >= 48, `ABOUT_BACK stays at the top-left while scrolling (${JSON.stringify(back)})`);
	await shot(P, 'r2-about-mid');
	await P.page.click('#od-about-back');
	await P.wait(400);
	await P.page.close();
}

// 3. O1: a cold load 3 h later (the same browser context keeps the save)
{
	const P = await boot('dev=1&grant=20000', 3 * 3600 * 1000);
	await P.page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 }).catch(() => {});
	await P.page.waitForFunction(() => window.odModal && window.odModal.open, null, { timeout: 20000 }).catch(() => {});
	await P.wait(900);
	const m = await P.page.evaluate(() => window.odModal || null);
	check(m && m.open && m.id === 'OFFLINE', `a cold load after 3 h shows O1 (${JSON.stringify(m)})`);
	await shot(P, 'r8-return');
	await P.page.close();
}
console.log(`  page errors: ${errors.length ? JSON.stringify(errors.slice(0, 5)) : 'none'}`);
if (errors.length) failed++;
console.log(failed ? 'MODALS_WEB: FAIL' : 'MODALS_WEB: PASS');
await browser.close();
process.exit(failed ? 1 : 0);
