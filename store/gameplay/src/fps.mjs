const PW = '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const [base] = process.argv.slice(2);
for (const [w, h, dpr] of [[390, 844, 2], [390, 844, 3]]) {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const ctx = await browser.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: dpr, isMobile: true, hasTouch: true });
  const page = await ctx.newPage();
  await page.goto(`${base}?dev=1`);
  await page.waitForSelector('#od-sound', { state: 'visible', timeout: 90000 });
  await page.click('#od-quiet');
  await page.waitForFunction(() => window.mbHandoffDone > 0 && window.odDisplay, null, { timeout: 120000 });
  await page.waitForTimeout(2000);
  const fps = await page.evaluate(() => new Promise((r) => { let n = 0; const t0 = performance.now(); const f = () => { n++; if (performance.now() - t0 < 3000) requestAnimationFrame(f); else r(n / 3); }; requestAnimationFrame(f); }));
  let t0 = Date.now(); for (let i = 0; i < 5; i++) await page.screenshot({ path: '/tmp/claude-0/-home-user/e19209d3-280a-559f-b1ff-f72441556d54/scratchpad/fps.png' });
  console.log(`${w}x${h}@${dpr}: rAF ${fps.toFixed(1)} fps, screenshot ${((Date.now() - t0) / 5).toFixed(0)} ms`);
  await browser.close();
}
