// The wizard overlay (ui/wizard.gd, ADR 0007) on the real web build: a fresh game with `?wiz=1`
// plays the first round through the wizard. Each step is shot once; the driver taps only the
// wizard's own target (window.odWizard.hole), and between steps it plays like a person (taps the
// leader, buys a card, pays the chat) with the dim gone. Then a second page checks "דלג".
//   node tools/web/wizard_web.mjs <url> <out dir> [WxH@DPR] [speed] [budget s]
// Serve build/web first (python3 -m http.server --directory build/web).
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const { makePlayer } = await import('./round_play.mjs');
const [base, out, dev = '390x844@2', speed = '3', budgetArg = '900'] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const [wh, dprS] = dev.split('@');
const [W, H] = wh.split('x').map(Number);
const DPR = Number(dprS);
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const checks = [];
const log = (...a) => console.log(...a);
const check = (ok, what) => { checks.push([ok, what]); log(`  ${ok ? 'ok  ' : 'FAIL'} ${what}`); };
const FIRST = ['pick', 'tap', 'buy', 'suitcase', 'chat', 'pay', 'seats', 'elect'];

async function boot() {
	const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: true, hasTouch: true });
	const page = await ctx.newPage();
	const errors = [];
	page.on('pageerror', (e) => errors.push(e.message));
	const cdp = await ctx.newCDPSession(page);
	const P = makePlayer({ page, cdp, DPR, out, wh, log });
	await P.st.ready;
	await page.goto(`${base}${base.includes('?') ? '&' : '?'}dev=1&wiz=1&speed=${speed}`);
	await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
	await page.click('#od-quiet');
	await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
	await P.wait(1500);
	await P.refresh();
	return { ctx, page, P, errors };
}
const wiz = (page) => page.evaluate(() => window.odWizard || { flow: '' });

// ---- 1. the first round, through the wizard
{
	const { ctx, page, P, errors } = await boot();
	const { wait, probe, shot, css, tapAt } = P;
	const seen = [];
	const t0 = Date.now();
	const budget = Number(budgetArg) * 1000;
	let swallowChecked = false;
	let lastBuy = 0;
	while (Date.now() - t0 < budget) {
		const w = await wiz(page);
		const s = await probe();
		if (!s) { await wait(300); continue; }
		if (s.evolutions >= 1) break;
		if (w.flow === 'first') {
			if (!seen.includes(w.step)) {
				seen.push(w.step);
				log(`  step ${w.step}: "${w.text}"`);
				await wait(350);   // the 160 ms fade
				await P.refresh();
				await shot(`w-${seen.length}-${w.step}`);
			}
			if (w.step === 'tap' && !swallowChecked) {
				// a press outside the hole is swallowed: the bank does not move on a tap far from the hole
				swallowChecked = true;
				const b0 = s.bank;
				const sk = css(w.skip[0] + 200, w.skip[1] + 200);
				await tapAt(sk);
				await wait(400);
				const s1 = await probe();
				const w1 = await wiz(page);
				check(w1.flow === 'first' && w1.step === 'tap' && s1.bank === b0, `a press outside the hole does nothing (bank ${b0} → ${s1.bank}, step ${w1.step})`);
			}
			if (w.step === 'pick') {
				const pk = await page.evaluate(() => window.odPick || null);
				const c = pk && pk.cells.find((x) => x[2] === 'bibi');
				if (c) await tapAt(css(c[0], c[1]));
				await wait(900);
			} else if (w.step === 'elect') {
				const r = await P.callElection({ card: 'w-election-card' });
				log(`  election: ${r}`);
				await wait(1500);
			} else {
				await tapAt(css(w.center[0], w.center[1]), 40);
				await wait(w.step === 'tap' ? 60 : 500);
			}
			continue;
		}
		if (w.flow && w.flow !== 'first') {   // another flow: shoot it, then do its thing
			if (!seen.includes(`${w.flow}/${w.step}`)) { seen.push(`${w.flow}/${w.step}`); await shot(`w-x-${w.flow}-${w.step}`); }
			await tapAt(css(w.center[0], w.center[1]));
			await wait(500);
			continue;
		}
		// between steps: play like a person (the dim is gone), who looks before acting: a wizard step
		// due this moment (the pay pill once the chat opens) shows within a second
		if (s.mode === 'title') { await tapAt(P.hat()); await wait(300); continue; }
		await page.waitForFunction(() => window.odWizard && window.odWizard.flow, null, { timeout: 1200 }).catch(() => {});
		if ((await wiz(page)).flow) continue;
		if (s.chat && s.chat.open) {
			if (s.coal.afford > 0) { await P.payChat(s); } else { await P.esc(); }
			continue;
		}
		if (s.groupOpen && s.coal.afford > 0 && s.modal === '') { await P.payChat(s); continue; }
		for (let i = 0; i < 6; i++) { await tapAt(P.hat(), 40); await wait(50); }
		const aff = ((s.shop && s.shop.rows) || []).filter((r) => r[3]);
		if (aff.length && s.modal === '' && Date.now() - lastBuy > 2500 && (!s.coal || !s.coal.save || s.bank > s.coal.save * 2)) {
			lastBuy = Date.now();
			const r = aff[aff.length - 1];
			await tapAt(css(r[0], r[1]));
		}
		await wait(150);
	}
	const s = await probe();
	log(`  steps seen: ${seen.join(' → ')} in ${Math.round((Date.now() - t0) / 1000)} s wall`);
	const order = seen.filter((x) => FIRST.includes(x));
	check(order[0] === 'pick' && order[1] === 'tap' && order[2] === 'buy', `the first steps: pick → tap → buy (${order.join(' → ')})`);
	for (const st of ['chat', 'pay', 'seats', 'elect']) check(order.includes(st), `the wizard showed "${st}"`);
	check(s && s.evolutions >= 1, `the first election through the wizard (evolutions ${s && s.evolutions})`);
	// round 2: the picker's new leader (soft) and the spins wizard
	if (s && s.evolutions >= 1) {
		const t1 = Date.now();
		let sawLeaders = false;
		let sawSpins = false;
		while (Date.now() - t1 < 120000 && !(sawLeaders && sawSpins)) {
			const fl = await page.evaluate(() => window.odFlash || null);
			if (fl && fl.open) { await P.refresh(); const b = fl.skip && fl.skip[0] >= 0 ? fl.skip : fl.next; await tapAt(css(b[0], b[1])); await wait(800); continue; }
			const w = await wiz(page);
			if (w.flow === 'leaders' && !sawLeaders) {
				sawLeaders = true;
				await wait(400);
				await P.refresh();
				await shot('w-r2-new-leader');
				check(w.soft === true && /חדש בבחירות/.test(w.text), `round 2's picker shows the new leader, soft ("${w.text}")`);
				const pk = await page.evaluate(() => window.odPick || null);
				const c = pk && pk.cells.find((x) => x[2] === 'bibi');
				if (c) await tapAt(css(c[0], c[1]));
				await wait(1200);
				continue;
			}
			if (w.flow === 'spins' && !sawSpins) {
				sawSpins = true;
				await wait(400);
				await P.refresh();
				await shot('w-r2-spins');
				await tapAt(css(w.center[0], w.center[1]));
				await wait(600);
				continue;
			}
			const q = await probe();
			if (q && q.mode === 'pick') {
				// a person reads the picker first: the new leader's wizard shows within a second
				await page.waitForFunction(() => window.odWizard && window.odWizard.flow, null, { timeout: 2000 }).catch(() => {});
				if ((await wiz(page)).flow) continue;
				const pk = await page.evaluate(() => window.odPick || null);
				const c = pk && pk.cells.find((x) => x[2] === 'bibi');
				if (c) { await tapAt(css(c[0], c[1])); await wait(900); }
				continue;
			}
			if (q && q.mode === 'title') { await tapAt(P.hat()); await wait(300); continue; }
			for (let i = 0; i < 8; i++) { await tapAt(P.hat(), 40); await wait(50); }
			const aff = ((q && q.shop && q.shop.rows) || []).filter((r) => r[3]);
			if (aff.length && q.modal === '') await tapAt(css(aff[aff.length - 1][0], aff[aff.length - 1][1]));
			await wait(200);
		}
		check(sawLeaders, 'round 2: the new-leader wizard');
		check(sawSpins, 'round 2: the spins wizard, when the tab appears');
	}
	check(errors.length === 0, `no page errors ${errors.length ? JSON.stringify(errors.slice(0, 3)) : ''}`);
	await ctx.close();
}

// ---- 2. "דלג": the first step's skip ends the wizard; the picker still works
{
	const { ctx, page, P, errors } = await boot();
	const { wait, probe, shot, css, tapAt } = P;
	await page.waitForFunction(() => window.odWizard && window.odWizard.flow === 'first', null, { timeout: 15000 }).catch(() => {});
	const w = await wiz(page);
	check(w.flow === 'first' && w.step === 'pick', `a fresh game opens on the wizard's pick step (${w.flow}/${w.step})`);
	await tapAt(css(w.skip[0], w.skip[1]));
	await wait(600);
	const w2 = await wiz(page);
	check(w2.flow === '', `דלג ends the wizard (${w2.flow})`);
	await shot('w-skip');
	const pk = await page.evaluate(() => window.odPick || null);
	const c = pk && pk.cells.find((x) => x[2] === 'bennett');
	if (c) await tapAt(css(c[0], c[1]));
	await wait(1000);
	await tapAt(P.hat());
	await wait(600);
	let again = false;
	for (let i = 0; i < 20; i++) {
		for (let k = 0; k < 5; k++) { await tapAt(P.hat(), 40); await wait(50); }
		if ((await wiz(page)).flow === 'first') again = true;
		await wait(200);
	}
	const s = await probe();
	check(s && s.leader === 'bennett' && !again, `after דלג the round is Bennett's and the first wizard never returns (${s && s.leader})`);
	check(errors.length === 0, `no page errors ${errors.length ? JSON.stringify(errors.slice(0, 3)) : ''}`);
	await ctx.close();
}
const ok = checks.every((x) => x[0]);
log(ok ? 'WIZARD_WEB: PASS' : 'WIZARD_WEB: FAIL');
await browser.close();
process.exit(ok ? 0 : 1);
