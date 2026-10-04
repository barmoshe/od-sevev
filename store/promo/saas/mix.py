"""Lay the voiceover (vo.py) on the bed (music.mjs): each line on its scene, the bed ducked under the voice.

Scene starts are the beats music.mjs and launch.html share (115.2 BPM). The bed dips 8 dB while a line is
spoken (80 ms down, 350 ms back), the voice gets a light high-pass and sits on top, then the whole mix is
loudness-normalised to -14 LUFS for Reels.

    ~/.cache/kokoro-tts/venv/bin/python store/promo/saas/mix.py   ->  saas/.out/launch.wav
"""
import json
import os
import subprocess

import numpy as np
import soundfile as sf

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, ".out")
SR = 48000
BEAT = 60 / 115.2
SCENES = [0, 8, 15, 24, 29, 36]               # beats
AT = [0.2, 0.3, 0.25, 0.2, 0.25, 0.45]        # the line's start, seconds into its scene


def load48(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-af", "highpass=f=90", "-ar", str(SR), "-ac", "1",
                          "-f", "f32le", "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32)


def main():
    bed, sr = sf.read(os.path.join(OUT, "bed.wav"), dtype="float32")
    assert sr == SR
    n = len(bed)
    voice = np.zeros(n, np.float32)
    gate = np.zeros(n, np.float32)
    lines = json.load(open(os.path.join(OUT, "vo", "vo.json")))["lines"]
    ends = []
    for ln in lines:
        t0 = SCENES[ln["scene"]] * BEAT + AT[ln["scene"]]
        v = load48(ln["wav"])
        i = int(t0 * SR)
        v = v[: n - i]
        voice[i:i + len(v)] += v
        gate[i:i + len(v)] = 1
        ends.append((round(t0, 2), round(t0 + len(v) / SR, 2)))
    for (a0, a1), (b0, _) in zip(ends, ends[1:]):
        assert a1 <= b0, "lines overlap: %s %s" % (a1, b0)
    # the duck: an envelope that falls fast and recovers slowly
    lo = 10 ** (-8 / 20)
    env = np.ones(n, np.float32)
    g = 1.0
    down, up = 1 / (0.08 * SR), 1 / (0.35 * SR)
    for i in range(n):
        target = lo if gate[i] else 1.0
        g = max(target, g - down * (1 - lo)) if target < g else min(target, g + up * (1 - lo))
        env[i] = g
    mix = bed * env[:, None] + (voice * 1.9)[:, None]
    raw = os.path.join(OUT, "launch.raw.wav")
    sf.write(raw, np.clip(mix, -1, 1), SR)
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", raw, "-af", "loudnorm=I=-14:TP=-1.0:LRA=11", "-ar", str(SR),
                    os.path.join(OUT, "launch.wav")], check=True)
    print("lines:", ends)
    print(os.path.join(OUT, "launch.wav"))


if __name__ == "__main__":
    main()
