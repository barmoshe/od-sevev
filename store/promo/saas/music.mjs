// The soundtrack for saas/launch.html, synthesized from nothing: no samples, no licence question.
// The brief (Bar, Oct 2026): "an elegant hi-tech SaaS launch", not the chiptune. The research says a
// premium product bed is restraint: a steady soft pulse, a simple diatonic piano line, warm pads,
// 105-120 BPM, clean swells at the cut points. So: 112 BPM, seven bars = 15.0 s exactly, one scene per
// bar and two for the end card, Am9 | Fmaj7 | Cmaj7 | Am9 | G6 | Cmaj9 | Fmaj9/C, drums from bar 2, a
// breath and a swell before the card, half-time under it, the last chord left ringing.
//   node store/promo/saas/music.mjs  ->  store/promo/saas/.out/launch.wav (-14 LUFS)
import { writeFile, mkdir } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const SR = 48000, BPM = 112, BEAT = 60 / BPM, BAR = 4 * BEAT, DUR = 7 * BAR, N = Math.ceil(SR * DUR);
const L = new Float32Array(N), R = new Float32Array(N);       // dry
const SL = new Float32Array(N), SR_ = new Float32Array(N);    // reverb send
const at = (t) => Math.round(t * SR);
let seed = 4242; const noise = () => ((seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x3fffffff - 1);

function biquad() {
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0, b0, b1, b2, a1, a2;
  return {
    set(type, f, q = 0.707) {
      const w = (2 * Math.PI * Math.min(f, SR * 0.45)) / SR, c = Math.cos(w), al = Math.sin(w) / (2 * q);
      let B0, B1, B2; const A0 = 1 + al;
      if (type === "lp") { B0 = (1 - c) / 2; B1 = 1 - c; B2 = (1 - c) / 2; }
      else if (type === "hp") { B0 = (1 + c) / 2; B1 = -(1 + c); B2 = (1 + c) / 2; }
      else { B0 = al; B1 = 0; B2 = -al; }
      b0 = B0 / A0; b1 = B1 / A0; b2 = B2 / A0; a1 = (-2 * c) / A0; a2 = (1 - al) / A0;
      return this;
    },
    run(x) { const y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2; x2 = x1; x1 = x; y2 = y1; y1 = y; return y; },
  };
}
function add(i, v, pan = 0, send = 0) {
  if (i < 0 || i >= N) return;
  const l = v * (1 - pan), r = v * (1 + pan);
  L[i] += l; R[i] += r; SL[i] += l * send; SR_[i] += r * send;
}
const NOTE = (n) => 440 * Math.pow(2, (n - 69) / 12);
const saw = (ph) => 2 * (ph - Math.floor(ph + 0.5));

// the pump: everything tonal ducks a little under each kick, so the bed breathes
const pump = new Float32Array(N).fill(1);
function duckAt(t0, depth = 0.35) {
  const s = at(t0);
  for (let i = 0; i < at(BEAT); i++) if (s + i < N) pump[s + i] = Math.min(pump[s + i], 1 - depth * Math.exp(-(i / SR) * 9));
}

// --- voices ---------------------------------------------------------------------------------
function piano(t0, n, vel = 1, len = 1.6, pan = 0) {
  const s = at(t0), f0 = NOTE(n), parts = [1, 2, 3, 4, 5.02, 6.05], amps = [1, 0.42, 0.2, 0.1, 0.05, 0.03];
  const lp = biquad().set("lp", 2400 + vel * 2600, 0.6);
  for (let i = 0; i < at(len + 0.8); i++) {
    const t = i / SR;
    let v = 0;
    for (let k = 0; k < parts.length; k++) v += Math.sin(2 * Math.PI * f0 * parts[k] * t) * amps[k] * Math.exp(-t * (1.6 + k * 1.3));
    const hammer = i < 240 ? noise() * 0.15 * (1 - i / 240) : 0;
    const env = Math.min(1, t / 0.004) * (t > len ? Math.max(0, 1 - (t - len) / 0.8) : 1);
    add(s + i, lp.run(v + hammer) * env * 0.16 * vel, pan, 0.55);
  }
}
function pad(t0, notes, dur, g = 1, cutoff = 1400, attack = 0.5) {
  const s = at(t0);
  notes.forEach((n, k) => {
    [-0.09, 0.0, 0.09].forEach((det, j) => {
      const f = biquad().set("lp", cutoff, 0.5); let ph = (k * 0.37 + j * 0.21) % 1;
      const pan = (j - 1) * 0.6, fr = NOTE(n) * Math.pow(2, det / 12);
      for (let i = 0; i < at(dur + 1.2); i++) {
        const t = i / SR, env = Math.min(1, t / attack) * (t > dur ? Math.max(0, 1 - (t - dur) / 1.2) : 1);
        ph += fr / SR;
        add(s + i, f.run(saw(ph)) * env * 0.018 * g * pump[Math.min(N - 1, s + i)], pan, 0.5);
      }
    });
  });
}
function sub(t0, n, dur, g = 1) {
  const s = at(t0), fr = NOTE(n);
  for (let i = 0; i < at(dur); i++) {
    const t = i / SR, env = Math.min(1, t / 0.02) * Math.min(1, (dur - t) / 0.05);
    add(s + i, Math.sin(2 * Math.PI * fr * t) * env * 0.32 * g * pump[Math.min(N - 1, s + i)]);
  }
}
function kick(t0, g = 1) {
  const s = at(t0); let ph = 0;
  for (let i = 0; i < at(0.4); i++) {
    const t = i / SR; ph += (2 * Math.PI * (46 + 70 * Math.exp(-t * 38))) / SR;
    add(s + i, Math.sin(ph) * Math.exp(-t * 9) * 0.75 * g);
  }
  duckAt(t0);
}
function rim(t0, g = 1) {                       // a soft finger-snap on 2 and 4
  const s = at(t0), f = biquad().set("bp", 2200, 1.6);
  for (let i = 0; i < at(0.12); i++) add(s + i, f.run(noise()) * Math.exp(-(i / SR) * 38) * 0.5 * g, -0.1, 0.35);
}
function shaker(t0, g = 1, pan = 0.3) {
  const s = at(t0), f = biquad().set("hp", 7000, 0.7);
  for (let i = 0; i < at(0.07); i++) {
    const t = i / SR, env = Math.min(1, t / 0.012) * Math.exp(-t * 55);
    add(s + i, f.run(noise()) * env * 0.16 * g, pan, 0.15);
  }
}
function swell(t0, dur, g = 1) {                // the air before a cut: filtered noise, rising
  const s = at(t0), f = biquad();
  for (let i = 0; i < at(dur); i++) {
    const p = i / at(dur); f.set("bp", 500 * Math.pow(14, p), 0.9);
    add(s + i, f.run(noise()) * p * p * 0.35 * g, (p - 0.5) * 0.6, 0.4);
  }
}
function bloom(t0, g = 1) {                     // the end card's soft hit: a low thump and a wash
  const s = at(t0), f = biquad(); let ph = 0;
  for (let i = 0; i < at(2.2); i++) {
    const t = i / SR; f.set("lp", 300 + 4000 * Math.exp(-t * 3), 0.6);
    ph += (2 * Math.PI * (55 + 30 * Math.exp(-t * 20))) / SR;
    add(s + i, (Math.sin(ph) * 0.7 * Math.exp(-t * 3.5) + f.run(noise()) * 0.18 * Math.exp(-t * 1.8)) * g, 0, 0.6);
  }
}
function chime(t0, n, g = 1) {                  // a UI glint: a glassy sine pair
  const s = at(t0);
  for (let i = 0; i < at(0.9); i++) {
    const t = i / SR, f = NOTE(n);
    add(s + i, (Math.sin(2 * Math.PI * f * t) + 0.3 * Math.sin(2 * Math.PI * f * 2.76 * t) * Math.exp(-t * 9)) *
      Math.exp(-t * 4.5) * 0.07 * g, 0.25, 0.7);
  }
}

// --- the arrangement ----------------------------------------------------------------------------
const CH = [ // pad voicing, sub root, the piano's arpeggio (low to high)
  { pad: [57, 60, 64, 71], root: 45, arp: [69, 72, 76, 79, 83] },     // Am9    the hook
  { pad: [53, 57, 60, 64], root: 41, arp: [65, 69, 72, 76, 77] },     // Fmaj7  taps
  { pad: [55, 60, 64, 71], root: 48, arp: [67, 71, 72, 76, 79] },     // Cmaj7  the coalition
  { pad: [57, 60, 64, 71], root: 45, arp: [69, 72, 76, 79, 83] },     // Am9    almost 61
  { pad: [55, 59, 62, 64], root: 43, arp: [62, 67, 71, 74, 76] },     // G6     the Knesset dissolves
  { pad: [48, 55, 59, 62, 64], root: 36, arp: [72, 74, 76, 79, 84] }, // Cmaj9  the end card
  { pad: [53, 57, 60, 64, 67], root: 36, arp: [65, 69, 72, 76, 79] }, // Fmaj9/C, left ringing
];
const ARP = [0, 2, 1, 3, 2, 4, 3, 1];          // eight eighths a bar
const bar = (j) => j * BAR;
const END = 5;                                  // the end card's bar

// drums first (they write the pump the tonal voices read)
for (let j = 1; j < END; j++) {
  for (let b = 0; b < 4; b++) {
    const t = bar(j) + b * BEAT;
    if (j === END - 1 && b === 3) break;        // the breath before the end card
    kick(t, j === 1 && b === 0 ? 1 : 0.85);
    if (b % 2 === 1) rim(t, 0.8);
    shaker(t + BEAT / 2, 0.9, 0.3); shaker(t + BEAT / 4, 0.35, -0.3); shaker(t + (3 * BEAT) / 4, 0.35, -0.3);
  }
}
for (let b = 0; b < 4; b++) {                   // under the card: half-time, then nothing
  if (b % 2 === 0) kick(bar(END) + b * BEAT, 0.6);
  shaker(bar(END) + b * BEAT + BEAT / 2, 0.6, 0.3);
}

for (let j = 0; j < 7; j++) {
  const c = CH[j], last = j === 6;
  pad(bar(j), c.pad, last ? 2.6 : BAR - 0.05, j === 0 ? 0.9 : 1, j === 0 ? 1000 : j >= END ? 2200 : 1500, j === 0 ? 1.0 : 0.3);
  if (j > 0) sub(bar(j), c.root, last ? 2.5 : BAR - 0.02, 0.8);
  const notes = last ? [0, 2, 4] : ARP;
  notes.forEach((k, i) => {
    const t = bar(j) + i * (last ? BEAT : BEAT / 2);
    piano(t, c.arp[k], i % 2 ? 0.6 : 0.85, last ? 2.4 : 0.9, (k - 2) * 0.12);
  });
  if (!last) piano(bar(j), c.root + 12, 0.5, BAR, -0.05);
}
// cut points: a swell into every bar, a glint on each headline, the bloom on the card
for (let j = 1; j <= END; j++) swell(bar(j) - 0.45, 0.45, j === END ? 1.6 : 0.6);
for (let j = 0; j < END; j++) chime(bar(j) + 0.12, 88 + (j % 3) * 2, 0.8);
bloom(bar(END), 1);
chime(bar(END) + BEAT, 91, 1);                  // the address lands

// --- reverb (Schroeder: four combs, two allpasses a side) on the send ----------------------------
function reverb(inp, offs) {
  const out = new Float32Array(N), combs = [1557, 1617, 1491, 1422].map((d) => d + offs), aps = [225 + offs, 556];
  for (const d of combs) {
    const buf = new Float32Array(d); let k = 0, lp = 0;
    for (let i = 0; i < N; i++) {
      const y = buf[k]; lp = y * 0.6 + lp * 0.4; buf[k] = inp[i] + lp * 0.84; k = (k + 1) % d; out[i] += y * 0.25;
    }
  }
  for (const d of aps) {
    const buf = new Float32Array(d); let k = 0;
    for (let i = 0; i < N; i++) { const b = buf[k], y = -out[i] + b; buf[k] = out[i] + b * 0.5; k = (k + 1) % d; out[i] = y; }
  }
  return out;
}
const wl = reverb(SL, 0), wr = reverb(SR_, 23);
for (let i = 0; i < N; i++) { L[i] += wl[i] * 0.55; R[i] += wr[i] * 0.55; }

// --- master: a soft fade, gentle tanh, normalise, write -----------------------------------------
const fade = at(0.35);
let peak = 0;
for (let i = 0; i < N; i++) {
  const g = i > N - fade ? (N - i) / fade : 1;
  L[i] = Math.tanh(L[i] * 1.1) * g; R[i] = Math.tanh(R[i] * 1.1) * g;
  peak = Math.max(peak, Math.abs(L[i]), Math.abs(R[i]));
}
const g = 0.89 / peak, buf = Buffer.alloc(44 + N * 4);
buf.write("RIFF", 0); buf.writeUInt32LE(36 + N * 4, 4); buf.write("WAVE", 8); buf.write("fmt ", 12);
buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22); buf.writeUInt32LE(SR, 24);
buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34); buf.write("data", 36); buf.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) { buf.writeInt16LE(Math.round(L[i] * g * 32767), 44 + i * 4); buf.writeInt16LE(Math.round(R[i] * g * 32767), 46 + i * 4); }
const out = join(dirname(fileURLToPath(import.meta.url)), ".out");
await mkdir(out, { recursive: true });
await writeFile(join(out, "launch.raw.wav"), buf);
const r = spawnSync(process.env.FFMPEG ?? "ffmpeg", ["-y", "-loglevel", "error", "-i", join(out, "launch.raw.wav"), "-af", "loudnorm=I=-14:TP=-1.0:LRA=11", "-ar", "48000", join(out, "launch.wav")], { stdio: "inherit" });
console.log(r.status === 0 ? `${join(out, "launch.wav")} (${DUR.toFixed(2)} s, -14 LUFS)` : "ffmpeg loudnorm failed");
