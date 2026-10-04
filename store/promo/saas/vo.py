"""The English voiceover for saas/launch.html: one line a scene, Kokoro-82M (Apache-2.0), local and offline.

Bar: narration in English, good marketing copy, a brisk read (not slow). Each line fits its scene's two
bars (4.17 s) with air on both sides; the end card's line carries the CTA. "Od Sevev" is spoken from
written phonemes, since the phonemizer would read it as English.

Setup (once): python3 -m venv ~/.cache/kokoro-tts/venv && ~/.cache/kokoro-tts/venv/bin/pip install kokoro-onnx soundfile,
with kokoro-v1.0.int8.onnx and voices-v1.0.bin from github.com/thewh1teagle/kokoro-onnx/releases (model-files-v1.0).

    ~/.cache/kokoro-tts/venv/bin/python store/promo/saas/vo.py [voice] [speed]   ->  saas/.out/vo/<n>.wav + vo.json
"""
import json
import os
import sys

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

HERE = os.path.dirname(os.path.abspath(__file__))
K = os.path.expanduser("~/.cache/kokoro-tts")
OUT = os.path.join(HERE, ".out", "vo")
NAME = "ˈoʊd sɛˈvɛv"                   # עוד סבב

LINES = [  # (scene, at seconds into the scene, text): {name} is spoken from NAME; the on-screen copy matches
    (0, 0.30, "Elections moved to the cloud. Eight party leaders. Zero coalitions."),
    (1, 0.35, "Growth from the very first click. Every tap is a shekel."),
    (2, 0.35, "Build your coalition in real time. Every partner joins. For a price."),
    (3, 0.35, "Sixty-one seats. Almost. As always."),
    (4, 0.35, "And when it all falls apart? It auto-syncs to the next election."),
    (5, 0.25, "{name}. Live now, free in your browser. Link in the first comment."),
]


def main():
    voice = sys.argv[1] if len(sys.argv) > 1 else "af_heart"
    speed = float(sys.argv[2]) if len(sys.argv) > 2 else 1.12
    os.makedirs(OUT, exist_ok=True)
    kk = Kokoro(os.path.join(K, "kokoro-v1.0.int8.onnx"), os.path.join(K, "voices-v1.0.bin"))
    meta = []
    for i, (scene, at, text) in enumerate(LINES):
        if "{name}" in text:
            head, tail = text.split("{name}")
            ph = (kk.tokenizer.phonemize(head, "en-us") if head.strip() else "") + NAME + kk.tokenizer.phonemize(tail, "en-us")
            wav, sr = kk.create(ph, voice=voice, speed=speed, lang="en-us", is_phonemes=True)
        else:
            wav, sr = kk.create(text, voice=voice, speed=speed, lang="en-us")
        wav = np.clip(np.asarray(wav, np.float32), -0.98, 0.98)
        path = os.path.join(OUT, "%d.wav" % i)
        sf.write(path, wav, sr)
        meta.append({"scene": scene, "at": at, "text": text.replace("{name}", "Od Sevev"), "wav": path,
                     "seconds": round(len(wav) / sr, 3)})
        print("%d  %.2f s  %s" % (i, len(wav) / sr, text))
    json.dump({"voice": voice, "speed": speed, "lines": meta}, open(os.path.join(OUT, "vo.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
