// The scripted player shared by round_web.mjs and picker_web.mjs (Game Designer 2026-09-30): one
// loop that plays a round to the 61 gate through the real UI with real touches, and one election
// call that checks "the vote stops the clock" (sim/politics.gd, design/leader-select-spec.md §7.4).
//
// How it plays (one look per loop, like a person glancing at the phone):
//   - an overlay that is not the election card: Esc (and it is logged: a stray overlay under a burst
//     of taps once opened the share sheet, whose WhatsApp button navigates the page);
//   - the court: testify when summoned;
//   - 4 taps on the leader;
//   - the chat FIRST whenever a line is payable, an ultimatum or a rejoin is open, or a brawl is up:
//     every affordable pill, the thread dragged to bring each one into view;
//   - then the most expensive affordable source card, unless that would leave the bank short of
//     the open ultimatum / rejoin (the driver saves for it, as the bench's attentive player does).
// Every tap burst re-reads window.odDev first, so a tap never lands in an overlay it did not see.
// Not a pacing measurement: see round_web.mjs's header (tools/balance.sh has the pacing gates).

export function makePlayer({ page, cdp, DPR, out, wh, log }) {
	const wait = (ms) => page.waitForTimeout(ms);
	const st = { disp: null, cv: null, tid: 1, t0: Date.now(), lastSeats: -1, paid: 0, loops: 0, lastBuy: 0,
		hatTaps: 0, buyActions: 0, cardTaps: 0, chatLooks: 0, modals: {}, actions: [], navs: [], shots: [], armed: false };
	const wall = () => Math.round((Date.now() - st.t0) / 1000);
	const act = (what) => { st.actions.push(`${wall()}s ${what}`); if (st.actions.length > 12) st.actions.shift(); };
	// "the page navigated mid-run" (seen once in round_web on v4, again in picker_web 2026-09-30):
	// a new document after the round started. The game's own layer history (LayerHistory:
	// pushState per layer, history.go(-n) when layers close; the shell's About) fires
	// framenavigated too, same URL, same document; those only go to a ring buffer. The page's
	// history calls are logged from inside the page (kept here, so they survive the navigation).
	st.hist = [];
	st.frames = [];
	const ring = (a, e) => { a.push(`${wall()}s ${e}`); if (a.length > 16) a.shift(); };
	st.ready = Promise.all([
		page.exposeFunction('odHistLog', (e) => ring(st.hist, e)),
		page.addInitScript(() => {
			const H = window.history;
			const say = (e) => { try { window.odHistLog(`${e} len ${H.length} state ${JSON.stringify(H.state)} layers ${window.odLayers}`); } catch (x) { /* ignore */ } };
			const push = H.pushState.bind(H);
			const go = H.go.bind(H);
			const back = H.back.bind(H);
			window.odGoPending = 0;   // history.go / back traversals not yet landed (their popstate)
			H.pushState = (...a) => { push(...a); say(`push (${window.odGoPending} go pending)`); };
			H.go = (n) => { window.odGoPending++; say(`go(${n})`); go(n); };
			H.back = () => { window.odGoPending++; say('back()'); back(); };
			window.addEventListener('popstate', () => { window.odGoPending = Math.max(0, window.odGoPending - 1); say('popstate'); });
			window.addEventListener('pagehide', (e) => say(`pagehide persisted ${e.persisted}`));
			say(`new document ${location.href}`);
		}),
	]);
	page.on('framenavigated', (fr) => { if (fr === page.mainFrame()) ring(st.frames, fr.url()); });
	const navigated = (why) => {
		const n = { why, url: page.url(), wall: wall(), last: st.actions.slice(-6), hist: st.hist.slice(-10), frames: st.frames.slice(-6) };
		st.navs.push(n);
		log(`  NAVIGATION (${why}) at ${n.wall}s wall, now ${n.url}`);
		log(`    the driver's last actions: ${n.last.join(' | ')}`);
		log(`    the page's history calls: ${n.hist.join(' | ')}`);
		log(`    main-frame navigations: ${n.frames.join(' | ')}`);
	};
	page.on('domcontentloaded', () => { if (st.armed) navigated('a new document loaded'); });
	const lostPage = (e) => /Execution context was destroyed|navigation|Target closed|detached/i.test(String(e && e.message));
	async function refresh() {
		st.disp = await page.evaluate(() => window.odDisplay);
		st.cv = await page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { x: r.x, y: r.y }; });
	}
	const css = (x, y) => [st.cv.x + x * st.disp.f / DPR, st.cv.y + y * st.disp.f / DPR];
	const col = (x, y) => css(x + st.disp.ox, y);   // 720-column logical -> CSS
	async function tapAt([x, y], hold = 60) {
		const id = st.tid++;
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id }] });
		await wait(hold);
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
	}
	async function drag([x, y0], dy, steps = 8) {
		const id = st.tid++;
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y: y0, id }] });
		for (let i = 1; i <= steps; i++) {
			await wait(30);
			await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x, y: y0 + (dy * i) / steps, id }] });
		}
		await wait(60);
		await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
	}
	// Escape closes the top layer, and the game rewinds its history entry with history.go(-1), which
	// lands asynchronously. A layer opened before it lands (a tap in the next frame on a loaded
	// machine) pushes an entry the traversal then skips past: the game's count of entries is one too
	// high and its next go(-1) leaves the page (LayerHistory; seen as "the page navigated mid-run").
	// That is a game bug (reported, not fixed here); a person never acts within that frame, so the
	// driver waits for the traversal to land before its next action.
	async function settle() {
		await page.waitForFunction(() => !window.odGoPending, null, { timeout: 3000 }).catch(() => {});
	}
	async function esc(wait_ms = 250) {
		await page.keyboard.press('Escape');
		await wait(wait_ms);
		await settle();
	}
	const probe = () => page.evaluate(() => window.odDev || null);
	const modal = () => page.evaluate(() => window.odModal || null);
	async function shot(name) {
		const p = `${out}/${wh}@${DPR}-${name}.png`;
		await page.screenshot({ path: p });
		st.shots.push(p);
		log('  shot', p);
	}
	const tabsY = () => st.disp.logical[1] - 104;
	// mobile-first §5.3: four fluid slots of floor4(cw / 4), right → left; the remainder goes to slot 4
	const tabX = (i) => { const cw = st.disp.cw || 720; const w = Math.floor(cw / 16) * 4; return i >= 4 ? (cw - 3 * w) / 2 : cw - i * w + w / 2; };
	const tab = (i) => col(tabX(i), tabsY() + 52);
	const hat = () => css(st.disp.hat[0], st.disp.hat[1]);
	// nothing over the round: no overlay, the controller in main (the tap bursts re-check this)
	const clear = (s) => s && s.modal === '' && s.mode === 'main';

	// the chat: every affordable pill and "צאו החוצה", scrolling to each. Returns the last probe.
	async function payChat(s) {
		st.chatLooks++;
		if (!s.chat.open) { act('tab chat'); await tapAt(tab(3)); await wait(500); }
		for (let guard = 0; guard < 16; guard++) {
			s = await probe();
			if (!s.chat.open || s.modal !== '' || (s.ready && s.cta)) break;
			const [top, bot] = s.chat.thread;
			const pills = s.chat.pills.filter((p) => p[3]).concat((s.chat.brawls || []).map((b) => [b[0], b[1], b[2], true, false]));
			if (!pills.length) break;
			const vis = pills.filter((p) => p[1] > top + 50 && p[1] < bot - 50);
			if (vis.length) {
				const p = vis[vis.length - 1];
				act(`pill ${p[2]}`);
				await tapAt(css(p[0], p[1]));
				st.paid++;
				await wait(p[4] ? 3400 : 350);   // a ceremony's ribbon runs 3 s of real time; a stamp needs a beat
			} else {
				const p = pills[0];
				act('drag thread');
				await drag(css(360 + st.disp.ox, (top + bot) / 2), -(p[1] - (top + bot) / 2) * st.disp.f / DPR * 0.9, 10);
				await wait(300);
			}
		}
		act('esc chat');
		await esc(250);
		return probe();
	}

	// one approach to the gate: returns 'gate' (the CTA is up and the election can be called),
	// 'card' (the election card is already open) or 'budget'
	async function playToGate(budgetMs, hooks = {}) {
		try {
			return await playLoop(budgetMs, hooks);
		} catch (e) {
			if (!lostPage(e)) throw e;
			if (!st.navs.length) navigated(String(e.message).split('\n')[0]);
			return 'navigated';
		}
	}
	async function playLoop(budgetMs, hooks) {
		if (!st.armed) { st.armed = true; st.url = page.url(); }   // a load from here on is not the boot's
		while (Date.now() - st.t0 < budgetMs) {
			st.loops++;
			if (st.loops % 5 === 1) await refresh();   // the layout moves (C1's tab bar, the split)
			let s = await probe();
			if (!s) { await wait(300); continue; }
			if (s.seats.effective !== st.lastSeats) {
				log(`  wall ${wall()}s  game ${Math.round(s.runSec)}s  seats ${s.seats.effective}/${s.seats.gate}  bank ${Math.round(s.bank)}  paid ${st.paid}`);
				st.lastSeats = s.seats.effective;
			}
			if (s.modal !== '') {
				if (s.modal === 'EVOLUTION') return 'card';
				st.modals[s.modal] = (st.modals[s.modal] || 0) + 1;
				act(`esc overlay ${s.modal}`);
				await esc(400);
				continue;
			}
			st.runSec = s.runSec;
			if (s.cta && s.ready) return 'gate';
			if (hooks.loop) await hooks.loop(s);
			if (s.court.card && s.court.phase === 'summons' && s.court.testify[0] > 0) {
				if (hooks.summons) await hooks.summons(s);
				act('testify');
				await tapAt(css(s.court.testify[0], s.court.testify[1]));
				await wait(400);
				continue;
			}
			if (!clear(s)) { await wait(200); continue; }
			// taps: the leader matters early; once sources pay, two taps a loop keep the verb alive
			const nTaps = s.groupOpen ? 2 : 4;
			for (let i = 0; i < nTaps; i++) { await tapAt(hat(), 40); await wait(50); st.hatTaps++; }
			act(`${nTaps} taps`);
			s = await probe();
			// the chat first: a line the bank covers, or a brawl ("צאו החוצה")
			if (s.groupOpen && (s.coal.afford > 0 || s.chat.openBrawl)) {
				s = await payChat(s);
				if (s.ready && s.cta) return 'gate';
			}
			if (!clear(s)) continue;
			// sources: the most expensive affordable card, scrolled into view. Before the group opens
			// (C1) buy at most every 4 s: C1 pings only when the last purchase is >= 2 s old.
			const quiet = !s.groupOpen && Date.now() - st.lastBuy < 4000;
			if (quiet) continue;
			// save for the open ultimatum / rejoin: never spend the bank below twice its price
			if (s.coal.save > 0 && s.bank < s.coal.save * 2) continue;
			if (s.groupOpen && s.shop.tab !== 'producers') { act('tab sources'); await tapAt(tab(1)); await wait(250); s = await probe(); }
			for (let pass = 0; pass < 2; pass++) {
				if (!clear(s) || s.shop.tab !== 'producers' || s.chat.open) break;   // an overlay came up: never tap into it
				const aff = (s.shop.all || []).filter((r) => r[3]);
				if (!aff.length) break;
				const r = aff[aff.length - 1];
				const [top, bot] = s.shop.list;
				if (r[1] < top + 60 || r[1] > bot - 60) {
					act('drag shop');
					await drag(css(360 + st.disp.ox, (top + bot) / 2), -(r[1] - (top + bot) / 2) * st.disp.f / DPR);
					await wait(200);
					s = await probe();
					continue;
				}
				st.lastBuy = Date.now();
				st.buyActions++;
				act(`buy ${r[2]} ×3`);
				for (let k = 0; k < 3; k++) { await tapAt(css(r[0], r[1])); await wait(60); st.cardTaps++; }
				break;
			}
		}
		return 'budget';
	}

	// Calls the election from the gate: closes T3, taps the ticker's "עוד סבב!" CTA, and checks the
	// card. Returns 'called', 'slipped' (the gate fell between the CTA and the card: a walkout before
	// the vote is the game; play on) or 'held-fail' (the gate fell UNDER the open card: a game bug
	// since the vote stops the clock).
	async function callElection(names = {}) {
		try {
			return await callOnce(names);
		} catch (e) {
			if (!lostPage(e)) throw e;
			if (!st.navs.length) navigated(String(e.message).split('\n')[0]);
			return 'navigated';
		}
	}
	async function callOnce(names) {
		let s = await probe();
		for (let i = 0; i < 3 && s.modal !== 'EVOLUTION' && (s.chat.open || s.modal !== ''); i++) {
			await esc(250);
			s = await probe();
		}
		if (s.modal !== 'EVOLUTION') {
			act('tap CTA');
			await tapAt(s.ctaAt ? css(s.ctaAt[0], s.ctaAt[1]) : col(360, st.disp.lowerY + 42));
			await page.waitForFunction(() => window.odModal && window.odModal.open && window.odModal.id === 'EVOLUTION', null, { timeout: 10000 }).catch(() => {});
		}
		const m = await modal();
		const s0 = await probe();
		if (!(m && m.open && m.id === 'EVOLUTION')) {
			log('  the CTA did not open the election card: back to the round');
			return 'slipped';
		}
		if (!m.ready) {
			log(`  the gate fell between the CTA and the card (seats ${s0.seats.effective}): close it, play on`);
			await esc(400);
			return 'slipped';
		}
		// the vote stops the clock: read the card for a while at ×speed; nothing may move
		await wait(1500);
		if (names.card) await shot(names.card);
		const s1 = await probe();
		const held = s1.ready && s1.coal.vote && s1.runSec === s0.runSec && s1.seats.effective === s0.seats.effective && s1.bank === s0.bank;
		log(`  O3 ${JSON.stringify(m)}; on the card 1.5 s: seats ${s0.seats.effective} → ${s1.seats.effective}, run ${s0.runSec.toFixed(2)} → ${s1.runSec.toFixed(2)}, vote ${s1.coal.vote}: ${held ? 'the round holds' : 'MOVED'}`);
		if (!held) return 'held-fail';
		act('tap ELECT_GO');
		await tapAt(css(m.buttons[0][0], m.buttons[0][1]));
		return 'called';
	}

	function cadence(speed, runSec = st.runSec) {
		const g = Math.max(1, runSec), w = (Date.now() - st.t0) / 1000;
		return `cadence (game time, speed ${speed}, ${Math.round(w)} s wall): ${(st.hatTaps / g).toFixed(3)} taps/s, `
			+ `a purchase action every ${(g / Math.max(1, st.buyActions)).toFixed(1)} s (${st.cardTaps} card taps), `
			+ `the chat every ${(g / Math.max(1, st.chatLooks)).toFixed(1)} s, a loop every ${(g / Math.max(1, st.loops)).toFixed(1)} s; `
			+ 'no spins, no Suitcase. Not a pacing measurement (tools/balance.sh is).';
	}

	return { st, wait, refresh, css, col, tapAt, drag, probe, modal, shot, tab, hat, esc, settle, playToGate, payChat, callElection, cadence };
}
