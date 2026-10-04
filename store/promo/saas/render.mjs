// Renders launch.html (window.__seek / __duration) to MP4 at a chosen size; the HoneyBook engine's render.mjs
// with a --size flag and a URL hash for the layout (#li = LinkedIn 4:5). Playwright comes from that engine.
//   node store/promo/saas/render.mjs store/promo/saas/launch.html --size 1080x1350 --hash li --audio <wav> --name launch-li
//   [--frames 0.5,3,8]
import { createRequire } from "node:module";
import { spawn } from "node:child_process";
import { mkdir } from "node:fs/promises";
import { resolve, basename, dirname, join } from "node:path";
import { pathToFileURL } from "node:url";

const ENGINE = process.env.MOTION_ENGINE ?? "/Users/barmoshe/bar_builds/jobs/honeybook/gtm-content/engine/package.json";
const { chromium } = createRequire(ENGINE)("playwright");
const args = process.argv.slice(2);
const opt = (k) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : null; };
const page_ = resolve(args[0]);
const [W, H] = (opt("--size") ?? "1080x1920").split("x").map(Number);
const hash = opt("--hash") ? `#${opt("--hash")}` : "";
const name = opt("--name") ?? basename(page_, ".html");
const out = join(dirname(page_), ".out");
await mkdir(out, { recursive: true });
const FPS = 30;

const browser = await chromium.launch(process.platform === "darwin" ? { channel: "chrome" } : {});
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
await page.goto(pathToFileURL(page_).href + hash);
await page.evaluate(() => window.__ready);
const duration = await page.evaluate(() => window.__duration);

const frames = opt("--frames");
if (frames) {
  for (const t of frames.split(",").map(Number)) {
    await page.evaluate((t) => window.__seek(t), t);
    await page.screenshot({ path: join(out, `${name}-${String(t).replace(".", "_")}.png`) });
  }
  console.log(`frames: ${out}`);
  await browser.close();
  process.exit(0);
}
const audio = opt("--audio");
const mp4 = join(out, `${name}.mp4`);
const ff = spawn(process.env.FFMPEG ?? "ffmpeg", [
  "-y", "-loglevel", "error", "-f", "image2pipe", "-framerate", String(FPS), "-c:v", "mjpeg", "-i", "-",
  ...(audio ? ["-i", resolve(audio)] : []),
  "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
  ...(audio ? ["-c:a", "aac", "-b:a", "192k", "-shortest"] : []), mp4,
], { stdio: ["pipe", "inherit", "inherit"] });
const n = Math.round(duration * FPS);
for (let i = 0; i < n; i++) {
  await page.evaluate((t) => window.__seek(t), i / FPS);
  const buf = await page.screenshot({ type: "jpeg", quality: 95 });
  if (!ff.stdin.write(buf)) await new Promise((r) => ff.stdin.once("drain", r));
  if (i % 90 === 0) process.stdout.write(`\r  ${i}/${n}`);
}
ff.stdin.end();
await new Promise((r) => ff.on("close", r));
await browser.close();
console.log(`\n${mp4} (${duration} s, ${n} frames, ${W}x${H})`);
