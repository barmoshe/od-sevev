#!/usr/bin/env python3
"""Measures the "עוד סבב" renders. Owner: Audio Director. Read-only on the build.

Needs the heard-level preview WAVs that tools/gen_od_sevev.gd writes when OD_AUDIO_PREVIEW is set,
plus game/assets/audio/od/od_manifest.json. Uses numpy and ffmpeg (ebur128, true peak).

    OD_AUDIO_PREVIEW=/tmp/od tools/godot.sh --headless --path game -s $PWD/tools/gen_od_sevev.gd
    python3 audio/tools/measure_od.py /tmp/od

Reports:
  1. per era, per layer, per section (A A' B T) integrated loudness: the layer balance and the
     "L1 carries B alone" check for anti-fatigue loop 2
  2. the loop seams: the step across the wrap (last sample -> first sample) against the stem's own
     typical sample-to-sample step, and the level either side
  3. the tap bell: the measured fundamental of each bell root (r<midi>) against its pitch
  4. per cue: the spectral centroid and the 10 dB band against the slot in the sonic brief
  5. the full mix, 60 s per era: all three layers + 5 taps/s (the r72 bell, +-1.5 dB
     jitter) + a chat ping, a Dubi squawk and babble (Music ducked -6 dB), a suitcase spawn and catch
     (Music ducked -4 dB) - integrated loudness and true peak before the master chain
  6. the no-go scan on every render: longest steady tonal segment, and pitch glides
"""
import json
import os
import subprocess
import sys
import wave

import numpy as np

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
MAN = json.load(open(os.path.join(ROOT, "game/assets/audio/od/od_manifest.json")))
PRE = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("OD_AUDIO_PREVIEW", "")
MIX_SR = 48000


def read(name):
    with wave.open(os.path.join(PRE, name.replace(".res", ".wav"))) as w:
        sr = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float64) / 32767.0
    return x, sr


def resample(x, sr, to=MIX_SR):
    if sr == to:
        return x
    n = int(round(len(x) * to / sr))
    return np.interp(np.arange(n) * sr / to, np.arange(len(x)), x)


def ebur(x, sr, stereo=True):
    """Integrated loudness, LRA-free, and true peak through ffmpeg (dual mono when stereo)."""
    tmp = os.path.join(PRE, "_m.wav")
    y = np.clip(x, -1, 1)
    data = (y * 32767).astype("<i2")
    if stereo:
        data = np.repeat(data, 2)
    with wave.open(tmp, "wb") as w:
        w.setnchannels(2 if stereo else 1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())
    out = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", tmp, "-af", "ebur128=peak=true", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    summ = out[out.rfind("Summary:"):]
    I = float(summ.split("I:")[1].split("LUFS")[0])
    tp = float(summ.split("Peak:")[1].split("dBFS")[0]) if "Peak:" in summ else float("nan")
    return I, tp


def section_loudness():
    print("\n1. Layer balance, integrated LUFS per section (heard level)")
    print("   %-11s %-3s %8s %8s %8s %8s %8s" % ("era", "lyr", "A", "A'", "B", "T", "loop"))
    for eid, e in MAN["eras"].items():
        bar = e["barSamples"]
        for layer in ["L0", "L1", "L2"]:
            x, sr = read(e["layers"][layer])
            row = []
            for s in range(4):
                seg = x[s * 8 * bar:(s + 1) * 8 * bar]
                row.append(ebur(seg, sr)[0])
            row.append(ebur(x, sr)[0])
            print("   %-11s %-3s %8.1f %8.1f %8.1f %8.1f %8.1f" % (eid, layer, *row))


def seams():
    print("\n2. Loop seams: |y[0]-y[-1]| vs the stem's 99.9th-percentile step; RMS 50 ms either side")
    for eid, e in MAN["eras"].items():
        for layer in ["L0", "L1", "L2"] + (["outside"] if "outside" in e else []):
            name = e["layers"][layer] if layer != "outside" else e["outside"]["file"]
            x, sr = read(name)
            step = abs(x[0] - x[-1])
            p999 = np.percentile(np.abs(np.diff(x)), 99.9)
            n = int(0.05 * sr)
            r0 = 20 * np.log10(np.sqrt(np.mean(x[-n:] ** 2)) + 1e-9)
            r1 = 20 * np.log10(np.sqrt(np.mean(x[:n] ** 2)) + 1e-9)
            flag = "OK" if step <= p999 else "CHECK"
            print("   %-11s %-7s seam step %.4f (p99.9 %.4f) %-5s  tail %6.1f dB -> head %6.1f dB" % (eid, layer, step, p999, flag, r0, r1))


def f0(x, sr, t0=0.014, t1=0.05):
    seg = x[int(t0 * sr):int(t1 * sr)]
    seg = seg * np.hanning(len(seg))
    n = 1 << 16
    sp = np.abs(np.fft.rfft(seg, n))
    fr = np.fft.rfftfreq(n, 1 / sr)
    band = (fr > 200) & (fr < 2500)
    # harmonic product spectrum over 3 harmonics for a robust fundamental
    hps = sp.copy()
    for h in (2, 3):
        dec = sp[::h]
        hps[:len(dec)] *= dec
    idx = np.argmax(np.where(band, hps, 0))
    return fr[idx]


def tap_bell():
    print("\n3. Tap bell roots (v1.10): measured fundamental vs the root's pitch (cents off)")
    worst = 0
    for v, f in sorted(MAN["cues"]["tap"]["files"]["_"]["_"].items()):
        want = 440 * 2 ** ((int(v[1:]) - 69) / 12)
        x, sr = read(f)
        c = 1200 * np.log2(f0(x, sr) / want)
        worst = max(worst, abs(c))
        print("   %s %7.1f Hz  %+5.1f cents" % (v, want, c))
    print("   worst deviation %.1f cents (FFT bin resolution at 32 kHz / 65536 is ~0.5 Hz)" % worst)


SLOTS = {"tap": (1500, 4000), "rabbitCrit": (200, 3000), "suitcaseSpawn": (2500, 8000), "suitcaseCatch": (2500, 8000),
         "chatPing": (1200, 2500), "ultimatumTick": (3000, 6000), "gavel": (80, 2000), "stamp": (90, 2000),
         "transferWhistle": (2500, 3200), "shutter": (3000, 8000), "dubiBlip": (1200, 3000), "dubiSquawk": (1200, 3000),
         "uiClick": (1000, 2000)}


def first_file(tree):
    for k in tree.values():
        for p in k.values():
            for v in p.values():
                return v


def slots():
    print("\n4. Spectral slot: centroid and the band holding the top 10 dB of energy vs the brief's slot")
    for cid, (lo, hi) in SLOTS.items():
        x, sr = read(first_file(MAN["cues"][cid]["files"]))
        sp = np.abs(np.fft.rfft(x * np.hanning(len(x)), 1 << 15)) ** 2
        fr = np.fft.rfftfreq(1 << 15, 1 / sr)
        cen = float(np.sum(fr * sp) / np.sum(sp))
        top = fr[sp > sp.max() / 10]
        print("   %-16s centroid %6.0f Hz, top-10 dB band %5.0f-%5.0f Hz   (slot %d-%d)" % (cid, cen, top.min(), top.max(), lo, hi))


def mix():
    print("\n5. Full mix, 60 s per era (pre-master): 3 layers + 5 taps/s + ping, Dubi, suitcase")
    rng = np.random.default_rng(7)
    for eid, e in MAN["eras"].items():
        key = e["key"]
        T = 60.0
        n = int(T * MIX_SR)
        mus = np.zeros(n)
        for layer in ["L0", "L1", "L2"]:
            x, sr = read(e["layers"][layer])
            y = resample(x, sr)
            reps = int(np.ceil(n / len(y)))
            mus += np.tile(y, reps)[:n]
        if "outside" in e:
            x, sr = read(e["outside"]["file"])
            y = resample(x, sr)
            mus += np.tile(y, int(np.ceil(n / len(y))))[:n] * 10 ** (-12 / 20)   # ~ the LPF's loss, crude
        duck = np.ones(n)
        sfx = np.zeros(n)

        def put(name, t, db=0.0):
            x, sr = read(name)
            y = resample(x, sr) * 10 ** (db / 20)
            i = int(t * MIX_SR)
            j = min(n, i + len(y))
            sfx[i:j] += y[:j - i]
            return len(y) / MIX_SR

        def ducks(t, dur, db, a=0.05, r=0.2):
            t0, t1 = int(t * MIX_SR), int((t + dur) * MIX_SR)
            g = 10 ** (db / 20)
            ra, rr = int(a * MIX_SR), int(r * MIX_SR)
            env = np.ones(n)
            env[t0:t0 + ra] = np.linspace(1, g, ra)[:len(env[t0:t0 + ra])]
            env[t0 + ra:t1] = g
            env[t1:t1 + rr] = np.linspace(g, 1, rr)[:len(env[t1:t1 + rr])]
            np.minimum(duck, env, out=duck)

        taps = MAN["cues"]["tap"]["files"]["_"]["_"]
        i = 0
        t = 0.5
        while t < T - 0.2:
            put(taps["r72"], t, rng.uniform(-1.5, 1.5))   # the bell's middle root (pitch_scale is runtime)
            i += 1
            t += 0.2
        ping = MAN["cues"]["chatPing"]["files"][key]["_"]["benGvir"]
        put(ping, 20.0)
        sq = MAN["cues"]["dubiSquawk"]["files"][key]["_"]["up"]
        d = put(sq, 30.0)
        bank = MAN["cues"]["dubiBlip"]["files"][key]
        degs = [p for p in bank]
        for b in range(12):
            put(bank[degs[(b * 3) % len(degs)]]["_"], 30.0 + d + 0.02 + b * 0.125)
        ducks(30.0, d + 1.6, -6, 0.03, 0.25)
        spawn = MAN["cues"]["suitcaseSpawn"]["files"]["_"]["_"]["g28"]
        ds = put(spawn, 40.0)
        catch = MAN["cues"]["suitcaseCatch"]["files"][key]["_"]["_"]
        dc = put(catch, 42.0)
        ducks(40.0, ds, -4)
        ducks(42.0, dc, -4)
        full = mus * duck + sfx
        I, tp = ebur(full, MIX_SR)
        Im, _ = ebur(mus, MIX_SR)
        It, _ = ebur(sfx, MIX_SR)
        print("   %-11s full %6.2f LUFS, true peak %6.2f dBTP   (music alone %6.2f, SFX alone %6.2f)" % (eid, I, tp, Im, It))


def nogo():
    print("\n6. No-go scan (renders): longest steady tonal run (pitch within +-50 cents, level within 3 dB)")
    names = sorted(f for f in os.listdir(PRE) if f.endswith(".wav") and not f.startswith("_") and not f.startswith("music_"))
    worst = (0, "")
    for f in names:
        x, sr = read(f)
        hop = int(0.02 * sr)
        win = int(0.04 * sr)
        run = 0.0
        best = 0.0
        prev = None
        for i in range(0, len(x) - win, hop):
            seg = x[i:i + win]
            rms = np.sqrt(np.mean(seg ** 2))
            if rms < 1e-3:
                prev = None
                run = 0
                continue
            zc = np.count_nonzero(np.diff(np.signbit(seg))) / 2 / (win / sr)
            if prev and abs(1200 * np.log2(max(zc, 1) / max(prev[0], 1))) < 50 and abs(20 * np.log10(rms / prev[1])) < 3:
                run += hop / sr
            else:
                run = 0
            prev = (zc, rms)
            best = max(best, run)
        if best > worst[0]:
            worst = (best, f)
    print("   longest steady segment in any cue/stinger: %.2f s (%s); the red line is 1.0 s" % worst)


if __name__ == "__main__":
    if not PRE:
        sys.exit("usage: measure_od.py <preview dir>")
    which = sys.argv[2:] or ["sections", "seams", "bell", "slots", "mix", "nogo"]
    if "sections" in which:
        section_loudness()
    if "seams" in which:
        seams()
    if "bell" in which:
        tap_bell()
    if "slots" in which:
        slots()
    if "mix" in which:
        mix()
    if "nogo" in which:
        nogo()
