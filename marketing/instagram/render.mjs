// Render an Instagram post HTML to PNG with Playwright (waits for the web font).
// Usage: node render.mjs <page.html> [WxH] [scale]   e.g. node render.mjs mordechai-government.html 1080x1350 1
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
const { chromium } = await import(path.join(execSync('npm root -g').toString().trim(), 'playwright/index.mjs'));
const [html, size = '1080x1350', scale = '1'] = process.argv.slice(2);
const [w, h] = size.split('x').map(Number);
const out = html.replace(/\.html$/, scale === '1' ? '.png' : `@${scale}x.png`);
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: +scale });
await p.goto('file://' + path.resolve(html), { waitUntil: 'networkidle' });
await p.evaluate(() => document.fonts.ready);
const heebo = await p.evaluate(() => document.fonts.check('900 40px Heebo'));
await p.screenshot({ path: out, clip: { x: 0, y: 0, width: w, height: h } });
await b.close();
console.log(out, `${w * scale}x${h * scale}`, heebo ? 'Heebo ok' : 'HEEBO MISSING');
