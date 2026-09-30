const PW = '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const fs = await import('node:fs');
const [base] = process.argv.slice(2);
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true });
const page = await ctx.newPage();
const cdp = await ctx.newCDPSession(page);
await page.goto(`${base}?dev=1&slow=20`);
await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
await page.click('#od-quiet');
await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 300000 });
await page.waitForTimeout(3000);
const fps = await page.evaluate(() => new Promise((r) => { let n = 0; const t0 = performance.now(); const f = () => { n++; if (performance.now() - t0 < 3000) requestAnimationFrame(f); else r(n / 3); }; requestAnimationFrame(f); }));
let t0 = Date.now(); let sz = 0;
for (let i = 0; i < 6; i++) { const r = await cdp.send('Page.captureScreenshot', { format: 'jpeg', quality: 92, optimizeForSpeed: true }); sz = r.data.length; if (i == 5) fs.writeFileSync('/tmp/claude-0/-home-user/e19209d3-280a-559f-b1ff-f72441556d54/scratchpad/fast.jpg', Buffer.from(r.data, 'base64')); }
console.log(`slow=20 @3: rAF ${fps.toFixed(1)}, cdp jpeg ${((Date.now() - t0) / 6).toFixed(0)} ms, ${sz} b64`);
await browser.close();
