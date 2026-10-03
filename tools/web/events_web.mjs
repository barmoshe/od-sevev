// Fires the content events through the dev hook (window.odDevEvent, ?dev=1) in a real round and
// shoots each one's copy on screen (2026-10-01: card toasts, the leaked screenshot in the chat, a
// stage event's ticker). Plays until the coalition group is open first, so the leak has a chat.
//   node tools/web/events_web.mjs <url> <out dir> [WxH@DPR] [events comma list]
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const { makePlayer } = await import('./round_play.mjs');
const [base, out, dev = '390x844@2', list = 'lapid,trump,card_deri,kaia,leak'] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const [wh, dprS] = dev.split('@');
const [W, H] = wh.split('x').map(Number);
const DPR = Number(dprS);
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: true, hasTouch: true });
const page = await ctx.newPage();
const errors = [];
page.on('pageerror', (e) => errors.push(e.message));
const cdp = await ctx.newCDPSession(page);
const log = (...a) => console.log(...a);
const P = makePlayer({ page, cdp, DPR, out, wh, log });
const { wait, probe, shot } = P;
await P.st.ready;
await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1&speed=5`);
await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
await page.click('#od-quiet');
await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
await wait(1200);
await P.refresh();
const pk = await page.evaluate(() => window.odPick || null);
if (pk && pk.open) {
	const c = pk.cells.find((x) => x[2] === (process.env.LEADER || 'bibi')) || pk.cells[4];
	await P.tapAt(P.css(c[0], c[1]));   // the ballot booth (ADR 0007): a tap chooses the slip, a second tap votes
	await wait(400);
	await P.tapAt(P.css(c[0], c[1]));
	await page.waitForFunction(() => window.odDev && window.odDev.mode !== 'pick', null, { timeout: 8000 }).catch(() => {});
	await wait(600);
}
await P.tapAt(P.hat());
await wait(800);
P.st.t0 = Date.now();
// play until the group is open (the leak needs a chat), at most 4 minutes
const until = Date.now() + 240000;
let s = await probe();
while (Date.now() < until && !(s && s.groupOpen)) {
	await P.playToGate(15000, {});
	s = await probe();
}
log(`  group open: ${s && s.groupOpen}`);
for (const id of list.split(',')) {
	await page.evaluate((x) => { window.odDevEvent = x; }, id);
	await wait(700);
	if (id === 'leak') {
		await shot(`ev-${id}-toast`);
		s = await probe();
		if (s && !s.chat.open) { await P.tapAt(P.tab(3)); await wait(1200); }
		await shot(`ev-${id}-chat`);
		await P.esc();
	} else {
		await shot(`ev-${id}`);
		await wait(3500);   // let the toast clear
	}
}
log(errors.length ? `  page errors: ${errors.join(' | ')}` : '  no page errors');
await browser.close();
