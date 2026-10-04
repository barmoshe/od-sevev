#!/usr/bin/env python3
"""Authoring tool for the "עוד סבב" audio data. Owner: Audio Director.

Writes audio/od/music.json (the four era themes, the Outside drum line, the stingers) and
audio/od/cues.json (every SFX cue) from the score below, then checks both against the sonic
brief (audio/sonic-brief v1.1 in the creative pack):

  - voice ranges (P1 D4-A6, P2 A3-E6, TRI A2-C4; the named cue exceptions are listed in cues.json)
  - no sustained tone over 1.0 s on any tonal voice, no glide over 200 ms, one direction only
  - bar 32 of every era is the "עוד סבב" motif (5 | 1 5 3 b2) with its pickup on bar 31, beat 4&
  - the quote check: no run of 5 consecutive intervals from a listed tune (interval-only, which
    is stricter than the brief's "same rhythm" rule)
  - no melody line on a single voice built only from triad notes over a fanfare (bugle rule)
  - every bar string holds exactly stepsPerBar tokens

The JSON is the source of truth for the generator (tools/gen_od_sevev.gd). This script is the
composing session: recallable, deterministic, and re-runnable in under a second.

    python3 audio/tools/compose_od.py          # write both files and run the checks
    python3 audio/tools/compose_od.py --check  # checks only, exit 1 on any failure
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "od")

PC = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
NAMES = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]


def midi(name):
    m = re.fullmatch(r"([A-G])([#b]?)(-?\d)", name)
    if not m:
        raise ValueError("bad note " + name)
    v = PC[m.group(1)] + (1 if m.group(2) == "#" else -1 if m.group(2) == "b" else 0)
    return v + (int(m.group(3)) + 1) * 12


def nm(m):
    return "%s%d" % (NAMES[m % 12], m // 12 - 1)


# ============================================================ score notation
# A line is "ITEM ITEM ... | ITEM ..." where ITEM is TOKEN:steps. TOKEN is a note (D5, F#4, Eb5),
# a chord (D4+A4), a rest (.), with optional ornaments: D5~Eb5 (upper mordent to Eb5),
# D5<C#5 (a scoop up from C#5, 50 ms), and an instrument override @inst.

def seq(line, spb):
    bars = []
    for chunk in line.split("|"):
        toks = []
        for item in chunk.split():
            tok, n = item.rsplit(":", 1)
            n = int(n)
            if tok == ".":
                toks += ["."] * n
            else:
                toks += [tok] + ["-"] * (n - 1)
        if len(toks) != spb:
            raise ValueError("bar has %d steps, not %d: %s" % (len(toks), spb, chunk.strip()))
        bars.append(" ".join(toks))
    return bars


def drums(spb, **voices):
    """One bar of a kit channel: voices are kit characters -> a step string ('x' hit, '.' none)."""
    steps = [""] * spb
    for ch, pat in voices.items():
        pat = pat.replace(" ", "")
        if len(pat) != spb:
            raise ValueError("drum pattern %s has %d steps" % (pat, len(pat)))
        for i, c in enumerate(pat):
            if c == "x":
                steps[i] += ch
    return " ".join(s if s else "." for s in steps)


def with_click(bars, inst_one):
    """Beat-1 bass notes get the phone-translation click (brief §8): the @inst_one override."""
    out = []
    for b in bars:
        t = b.split(" ")
        if t[0] not in (".", "-") and "@" not in t[0]:
            t[0] = t[0] + "@" + inst_one
        out.append(" ".join(t))
    return out


# v1.8 (Bar: "repetitive, thin, tiring"): the kit changes by section instead of one 2-bar groove for all
# 32 bars. A is light (the riq only on the off-beats), A' is the full groove, B drops to half time (no
# riq, one tek per bar), T is the full groove into the motif. `beat` = steps per beat.
def _kit_bar(bar, keep):
    out = []
    for i, st in enumerate(bar.split(" ")):
        k = "".join(c for c in st if c != "." and keep(i, c))
        out.append(k if k else ".")
    return " ".join(out)


def thin(bar, beat):
    off = beat // 2 if beat % 2 == 0 else beat - 1
    return _kit_bar(bar, lambda i, c: c != "j" or i % beat == off)


def half(bar, beat):
    return _kit_bar(bar, lambda i, c: c != "j" and not (c == "T" and i < 2 * beat))


def kit_form(g1, g2, fill, last, beat):
    return {"A": [thin(g1, beat), thin(g2, beat)] * 3 + [thin(g1, beat), fill],
            "A2": [g1, g2] * 3 + [g1, fill],
            "B": [half(g1, beat), half(g2, beat)] * 3 + [g1, fill],
            "T": [g1, g2] * 3 + [g1, last]}


# ============================================================ v2.0 trap helpers

HAT_SPB = 24   # the hats' grid: 24 steps a beat holds 8ths (12), 16ths (6), 16th triplets (4), 32nds (3), 32nd triplets (2)
HAT_HALF = {"-": [], "8": [0], "16": [0, 6], "t": [0, 4, 8], "32": [0, 3, 6, 9], "48": [0, 2, 4, 6, 8, 10],
            "o": ["o"], "s": [0], "S": [0, 8]}


def hats(*beats):
    """One bar of hats on the 24-step grid. Each beat is a code, or "a|b" for its two halves:
    - none, 8 an 8th, 16 16ths, t 16th triplets, 32 32nds, 48 32nd triplets, o an open hat.
    Swung codes for the triplet eras: "s" (the beat), "S" (beat + its last triplet, the swing)."""
    out = ["."] * (HAT_SPB * len(beats))
    for bi, code in enumerate(beats):
        if code in ("s", "S", "T"):   # whole-beat swing codes (Courthouse): 8th triplets
            pos = {"s": [0], "S": [0, 16], "T": [0, 8, 16]}[code]
            for p in pos:
                out[bi * HAT_SPB + p] = "h" if p == 0 else "g"
            continue
        halves = code.split("|") if "|" in code else [code, code if code in ("16", "t", "32", "48") else "-"]
        if code == "8":
            halves = ["8", "8"]
        for hi, h in enumerate(halves):
            pos = HAT_HALF[h]
            for k, p in enumerate(pos):
                if p == "o":
                    out[bi * HAT_SPB + hi * 12] = "o"
                    continue
                out[bi * HAT_SPB + hi * 12 + p] = _vel(k, len(pos), hi)
    return " ".join(out)


def _vel(k, n, half):
    """v2.1: a hat's velocity: the beat 'h', the offbeat 8th 'm', a roll swelling q -> g -> m."""
    if k == 0:
        return "h" if half == 0 else "m"
    f = k / max(1, n - 1)
    return "q" if f < 0.34 else "g" if f < 0.67 else "m"


def hats_tresillo(roll=None):
    """v2.1: the drill hat: 3+3+2 per half bar (16ths 1, 4, 7 at velocities 100 / 87 / 52, Native
    Instruments' drill walkthrough), as a bar on the 24-step grid. `roll` replaces beat 4's second half
    with a hats() half code (t, 32, 48) swelling into the next bar."""
    out = ["."] * (HAT_SPB * 4)
    for half in (0, 8):
        for p, v in ((0, "h"), (3, "m"), (6, "q")):
            out[(half + p) * 6] = v
    if roll:
        for i in range(HAT_SPB * 3 + 12, HAT_SPB * 4):
            out[i] = "."
        pos = HAT_HALF[roll]
        for k, p in enumerate(pos):
            out[HAT_SPB * 3 + 12 + p] = _vel(k, len(pos), 1) if k else "g"
    return " ".join(out)


def chord_pcs(name):
    """'Dm' -> [2, 5, 9]; 'A7' -> [9, 1, 4, 7]; 'Bb' -> [10, 2, 5]."""
    m = re.fullmatch(r"([A-G])([#b]?)(m?)(7?)", name)
    r = (PC[m.group(1)] + (1 if m.group(2) == "#" else -1 if m.group(2) == "b" else 0)) % 12
    pcs = [r, (r + (3 if m.group(3) else 4)) % 12, (r + 7) % 12]
    if m.group(4):
        pcs.append((r + 10) % 12)
    return pcs


def _place(pc, lo):
    """The pitch class pc at or above midi lo (within an octave)."""
    return lo + (pc - lo) % 12


def _halves(c):
    a, b = (c.split("|") + [c])[:2]
    return a, b


def _bar(spb, events):
    """events: (step, len, token) -> one bar string; later events cut earlier ones short."""
    t = ["."] * spb
    for st, ln, tok in sorted(events):
        t[st] = tok
        for i in range(st + 1, min(spb, st + ln)):
            t[i] = "-"
    return " ".join(t)


def bass808(chords, rhythm, spb, lo=29, prev=None, inst="808"):
    """The 808 line. `rhythm`: a bar's (step, len, kind), or a list of such bars cycled bar by bar.
    kind: R the root, punched (a fresh hit); r the root, gliding from the previous note (legato, the
    trap/drill slide, 808u<n> / 808d<n>); O the octave above, gliding up into it; F the fifth above,
    gliding. The chord's root (X|Y splits at the half bar) sits in F1-E2 (midi 29-40)."""
    if rhythm and isinstance(rhythm[0], tuple):
        rhythm = [rhythm]
    bars = []
    for bi, c in enumerate(chords):
        a, b = _halves(c)
        ev = []
        for st, ln, kind in rhythm[bi % len(rhythm)]:
            r = _place(chord_pcs(a if st < spb // 2 else b)[0], lo)
            n = {"R": r, "r": r, "O": r + 12, "F": r + 7}[kind]
            if kind != "R" and prev is not None and prev != n and abs(prev - n) <= 24:
                ov = "@%s%s%d" % (inst, "d" if prev > n else "u", abs(prev - n))
            else:
                ov = ""
            ev.append((st, ln, nm(n) + ov))
            prev = n
        bars.append(_bar(spb, ev))
    return bars


def keys_part(chords, hits, spb, lo=55):
    """Soft keys: the chord, closed in G3-F#4, struck at each (step, len) of hits."""
    bars = []
    for c in chords:
        ev = []
        for st, ln in hits:
            ch = (_halves(c))[0 if st < spb // 2 else 1]
            notes = sorted(_place(pc, lo) for pc in chord_pcs(ch)[:3])
            ev.append((st, ln, "+".join(nm(n) for n in notes)))
        bars.append(_bar(spb, ev))
    return bars


def bells_part(chords, pattern, spb, lo=72):
    """Dark bells: an arpeggio over the chord in C5-B5 (+ the root's octave). pattern: (step, index)
    with index into [root, third, fifth, root']."""
    bars = []
    for c in chords:
        ev = []
        for st, ix in pattern:
            ch = (_halves(c))[0 if st < spb // 2 else 1]
            p = chord_pcs(ch)
            r = _place(p[0], lo)
            tones = [r, _place(p[1], r), _place(p[2], r), r + 12]
            ev.append((st, 1, nm(tones[ix])))
        bars.append(_bar(spb, ev))
    return bars


# the lead's echo: a dotted-8th throw (3 steps), no detuned double (that was the chip chorus)
TRAP_FX = {"echo": {"steps": 3, "db": -10.0, "repeats": 2}}


def kit_split(sections, keep):
    """The kit's bars with only the characters in `keep` (the snares get their own channel and its
    reverb send; the kick, rim and perc stay dry)."""
    return {sec: [" ".join(("".join(c for c in st if c in keep) or ".") for st in b.split(" ")) for b in bars]
            for sec, bars in sections.items()}


# v2.1, the mix (the trap/drill mix guides): the 808 ducks 5 dB under every kick (2 ms down, 15 ms
# hold, 120 ms back); the snares, bells, keys and lead send to one Freeverb room per layer (the send
# high-passed at 250 Hz: the low end stays dry and mono); L0 goes through a soft clipper (the drum-bus
# clipper: peaks rounded, density up, the same LUFS hits harder)
# v2.1, the channel balance, set by measuring each channel's RMS (OD_AUDIO_CHANNELS dumps) against the
# trap balance the mix guides give: the 808 loudest, the kick about 6 dB under it, the snares about 10,
# the melody about 6, the hats 15-20, the keys and bells far back (texture, not a part)
MIX = {"bass": 0.56, "drums": 0.9, "snares": 1.5, "hats": 0.62, "keys": 0.055, "bells": 0.25, "p2": 0.22, "lead": 0.19}
# v2.1, the master pass (measured against a trap reference curve, octave bands relative to 1 kHz: the
# first mix sat 5-8 dB light in the sub and 63-250 Hz, 8 dB light at 2-4 kHz, heavy around 1 kHz where
# the flute and keys live). Channel moves: the 808 evened out by a slow low compressor (the mix guides'
# "each 808 note lands with the same weight"), the lead and keys dipped at 1 kHz, the snares given
# presence. Stem moves: L0 a low shelf for the sub and a presence shelf, glue (2:1, 10 ms / 120 ms)
# before the clipper; L1 / L2 the 1 kHz dip and a little air.
EQ_LEAD = [{"type": "peaking", "freq": 1100, "Q": 0.8, "gainDb": -3.0}, {"type": "highshelf", "freq": 4500, "Q": 0.7, "gainDb": 2.5}]
EQ_KEYS = [{"type": "peaking", "freq": 900, "Q": 0.8, "gainDb": -4.0}, {"type": "highpass", "freq": 160, "Q": -3.0103}]
EQ_SNARES = [{"type": "peaking", "freq": 3200, "Q": 0.9, "gainDb": 3.0}, {"type": "highpass", "freq": 150, "Q": -3.0103}]
COMP_808 = {"thresholdDb": -9.0, "ratio": 3.0, "attackMs": 30, "releaseMs": 200}
STEM_EQ = {"L0": [{"type": "highpass", "freq": 26, "Q": -3.0103}, {"type": "lowshelf", "freq": 90, "Q": 0.7, "gainDb": 3.0},
                  {"type": "peaking", "freq": 170, "Q": 0.9, "gainDb": 3.5}, {"type": "peaking", "freq": 2000, "Q": 1.0, "gainDb": 2.5},
                  {"type": "highshelf", "freq": 2500, "Q": 0.7, "gainDb": 3.0}],
           "L1": [{"type": "peaking", "freq": 1000, "Q": 0.7, "gainDb": -2.0}, {"type": "highshelf", "freq": 6000, "Q": 0.7, "gainDb": 1.5}],
           "L2": [{"type": "highshelf", "freq": 6000, "Q": 0.7, "gainDb": 1.5}]}
# the Courthouse renders at 22 kHz with triplet hats on every beat: it measured 4-7 dB bright at 4-8 kHz,
# so its L0 keeps the body moves and drops the presence shelf
STEM_EQ_COURT = dict(STEM_EQ, L0=[f for f in STEM_EQ["L0"] if f["type"] != "highshelf"])
BUS_COMP = {"L0": {"thresholdDb": -10.0, "ratio": 2.0, "attackMs": 10, "releaseMs": 120}}
DUCK = {"by": "drums", "hits": ["kick"], "db": -5.0, "attackMs": 2, "holdMs": 15, "releaseMs": 120}
ROOM = {"size": 0.72, "damp": 0.45, "predelayMs": 18, "hpHz": 250}
BUS = {"L0": 1.8}
SENDS = {"snares": -7.0, "keys": -9.0, "bells": -5.0, "p2": -9.0, "lead": -11.0}


def trap_channels(bass, kit, hat, keys, bells, p2, lead, lead_inst, gains, p2_inst="pluck", lead_section_inst=None,
                  lead_fx=TRAP_FX, kit_name="trap", bass_inst="808"):
    """The v2.0 layer map: L0 = the 808 + the kit + the hats (always on), L1 = keys + bells + the
    counter-line (from the first source), L2 = the lead (while the taps rest)."""
    gains = dict(MIX, **gains)
    ch = {
        "bass": {"instrument": bass_inst, "layer": "L0", "gain": gains["bass"], "sections": bass, "duck": DUCK},
        "drums": {"kit": kit_name, "layer": "L0", "gain": gains["drums"], "sections": kit_split(kit, "KRtTX")},
        "snares": {"kit": kit_name, "layer": "L0", "gain": gains["snares"], "sections": kit_split(kit, "CSsN")},
        "hats": {"kit": "trapHats", "layer": "L0", "gain": gains["hats"], "stepsPerBeat": HAT_SPB, "sections": hat},
        "keys": {"instrument": "keys", "layer": "L1", "gain": gains["keys"], "sections": keys},
        "bells": {"instrument": "bell", "layer": "L1", "gain": gains["bells"], "sections": bells},
        "p2": {"instrument": p2_inst if isinstance(p2_inst, str) else "pluck", "layer": "L1", "gain": gains["p2"], "sections": p2},
        "lead": {"instrument": lead_inst, "layer": "L2", "gain": gains["lead"], "sections": lead, "fx": lead_fx},
    }
    for cid, db in SENDS.items():
        ch[cid]["reverb"] = db
    ch["lead"]["eq"] = EQ_LEAD
    ch["keys"]["eq"] = EQ_KEYS
    ch["snares"]["eq"] = EQ_SNARES
    ch["bass"]["comp"] = COMP_808
    if isinstance(p2_inst, dict):
        ch["p2"]["sectionInstrument"] = p2_inst
    if lead_section_inst:
        ch["lead"]["sectionInstrument"] = lead_section_inst
    return ch


# the lead's chip echo channel and detuned double (gen_od_sevev.gd _channel_fx): fuller, less beepy
LEAD_FX = {"double": {"cents": 7, "db": -8.0}, "echo": {"steps": 3, "db": -11.0, "repeats": 2}}


# ============================================================ instruments (lib_dsp layer schema, A4 = root)

VIB = {"rateHz": 5.5, "depthCents": 15, "delay": 0.25}


def L(**k):
    return k


INSTRUMENTS = {
    "_doc": "lib_dsp layer schema (tools/lib_dsp.gd render_layer). Tonal layers are authored at A4 = the "
            "note played; 'gate' shortens a held note (noteSeconds = steps * stepSeconds * gate). Voice "
            "names follow the brief §3: P1 pulse 25%, P2 pulse 12.5%/50%, TRI (4-bit crushed triangle), "
            "NOI-L (LFSR long mode, wave 'noise'), NOI-S (LFSR short/metallic, wave 'noiseMetal'), BLIP.",
    # P1: the Magician's hand. 0 ms attack, vibrato 5.5 Hz +-15 cents after 250 ms. v1.8 (Bar: "thin /
    # harsh, tiring"): every pulse voice of the music is low-passed (lead 4.5 kHz, counter-line 3.5-4 kHz),
    # so the buzz above the phone's presence band goes; the riq is 3 dB down.
    "p1": {"gate": 0.9, "layers": [L(id="p1", wave="pulse", duty=0.25, freqStart="A4", attack=0.001, decay=0.09,
                                      sustain=0.62, duration="note", release=0.035, filter={"type": "lowpass", "freq": 4500, "Q": 0.7}, gain=1.0, vibrato=VIB)]},
    "p1s": {"gate": 0.72, "layers": [L(id="p1", wave="pulse", duty=0.25, freqStart="A4", attack=0.001, decay=0.08,
                                       sustain=0.55, duration="note", release=0.03, filter={"type": "lowpass", "freq": 4500, "Q": 0.7}, gain=1.0)]},
    # P2: counter-line. 12.5% = the nasal answer, 50% = the brass.
    "p2n": {"gate": 0.88, "layers": [L(id="p2", wave="pulse", duty=0.125, freqStart="A4", attack=0.002, decay=0.1,
                                        sustain=0.55, duration="note", release=0.04, filter={"type": "lowpass", "freq": 3500, "Q": 0.7}, gain=1.0, vibrato={"rateHz": 5.0, "depthCents": 10, "delay": 0.3})]},
    # v1.9: the counter-line with the lead's short gate (p1s), for a canon's long notes (<= 1.0 s steady)
    "p2ns": {"gate": 0.72, "layers": [L(id="p2", wave="pulse", duty=0.125, freqStart="A4", attack=0.002, decay=0.1,
                                         sustain=0.55, duration="note", release=0.04, filter={"type": "lowpass", "freq": 3500, "Q": 0.7}, gain=1.0)]},
    "p2b": {"gate": 0.82, "layers": [L(id="p2", wave="pulse", duty=0.5, freqStart="A4", attack=0.002, decay=0.1,
                                        sustain=0.5, duration="note", release=0.04, filter={"type": "lowpass", "freq": 4000, "Q": 0.7}, gain=0.8)]},
    "p2stab": {"gate": 1.0, "layers": [L(id="p2", wave="pulse", duty=0.5, freqStart="A4", attack=0.001, decay=0.08,
                                          sustain=0.0, duration=0.085, release=0.015, filter={"type": "lowpass", "freq": 4000, "Q": 0.7}, gain=1.0)]},
    "p2nstab": {"gate": 1.0, "layers": [L(id="p2", wave="pulse", duty=0.125, freqStart="A4", attack=0.001, decay=0.08,
                                           sustain=0.0, duration=0.085, release=0.015, filter={"type": "lowpass", "freq": 3500, "Q": 0.7}, gain=1.0)]},
    # TRI: bass, A2-C4. 4-bit crush for the chip staircase and for phone-speaker harmonics.
    "tri": {"gate": 0.8, "layers": [L(id="tri", wave="triangle", crush=4, freqStart="A4", attack=0.002, decay=0.07,
                                       sustain=0.8, duration="note", release=0.02, gain=1.0)]},
    "triTip": {"gate": 0.55, "layers": [L(id="tri", wave="triangle", crush=4, freqStart="A4", attack=0.002, decay=0.09,
                                           sustain=0.5, duration="note", release=0.02, gain=1.0)]},
    # the phone click (brief §8): every beat-1 bass note also plays a 20 ms P2 12.5% click an octave up
    "triOne": {"gate": 0.8, "layers": [
        L(id="tri", wave="triangle", crush=4, freqStart="A4", attack=0.002, decay=0.07, sustain=0.8, duration="note", release=0.02, gain=1.0),
        L(id="click", wave="pulse", duty=0.125, freqStart="A5", attack=0.001, decay=0.018, sustain=0.0, duration=0.02, release=0.004, gain=0.3)]},
    "triTipOne": {"gate": 0.55, "layers": [
        L(id="tri", wave="triangle", crush=4, freqStart="A4", attack=0.002, decay=0.09, sustain=0.5, duration="note", release=0.02, gain=1.0),
        L(id="click", wave="pulse", duty=0.125, freqStart="A5", attack=0.001, decay=0.018, sustain=0.0, duration=0.02, release=0.004, gain=0.3)]},
    # BLIP: Dubi's voice
    "blip": {"gate": 1.0, "layers": [L(id="blip", wave="pulse", duty=0.125, freqStart="A4", attack=0.001, decay=0.05,
                                        sustain=0.3, duration=0.055, release=0.012, gain=1.0)]},
    # darbuka: dum = TRI pitch-drop kick 110 -> 55 Hz over 60 ms; tek = NOI-L with a small ring; riq = NOI-S
    "dum": {"gate": 1.0, "layers": [
        L(id="body", wave="triangle", crush=4, freqStart=110, freqEnd=55, freqCurve="exp", glide=0.06, followPitch=False,
          attack=0.001, decay=0.11, sustain=0.0, duration=0.11, release=0.01, gain=1.0),
        L(id="skin", wave="noise", clockStart=12000, filter={"type": "bandpass", "freq": 900, "Q": 1.0},
          attack=0.0005, decay=0.02, sustain=0.0, duration=0.02, release=0.005, gain=0.25)]},
    "dumSoft": {"gate": 1.0, "layers": [
        L(id="body", wave="triangle", crush=4, freqStart=110, freqEnd=55, freqCurve="exp", glide=0.06, followPitch=False,
          attack=0.004, decay=0.1, sustain=0.0, duration=0.1, release=0.01, gain=0.55),
        L(id="skin", wave="noise", clockStart=12000, filter={"type": "bandpass", "freq": 900, "Q": 1.0},
          attack=0.001, decay=0.02, sustain=0.0, duration=0.02, release=0.005, gain=0.2)]},
    "tekSoft": {"gate": 1.0, "layers": [
        L(id="snap", wave="noise", clockStart=26000, filter={"type": "bandpass", "freq": 2200, "Q": 0.9},
          attack=0.003, decay=0.06, sustain=0.0, duration=0.06, release=0.015, gain=0.6),
        L(id="ring", wave="triangle", freqStart=820, freqEnd=780, freqCurve="exp", glide=0.02, followPitch=False,
          attack=0.001, decay=0.03, sustain=0.0, duration=0.03, release=0.008, gain=0.15)]},
    "dumG": {"gate": 1.0, "layers": [
        L(id="body", wave="triangle", crush=4, freqStart=110, freqEnd=55, freqCurve="exp", glide=0.06, followPitch=False,
          attack=0.001, decay=0.08, sustain=0.0, duration=0.08, release=0.01, gain=0.5)]},
    "tek": {"gate": 1.0, "layers": [
        L(id="snap", wave="noise", clockStart=32000, filter={"type": "bandpass", "freq": 2600, "Q": 1.1},
          attack=0.0005, decay=0.045, sustain=0.0, duration=0.045, release=0.01, gain=1.0),
        L(id="ring", wave="triangle", freqStart=880, freqEnd=820, freqCurve="exp", glide=0.02, followPitch=False,
          attack=0.0005, decay=0.03, sustain=0.0, duration=0.03, release=0.008, gain=0.22)]},
    "tekG": {"gate": 1.0, "layers": [
        L(id="snap", wave="noise", clockStart=32000, filter={"type": "bandpass", "freq": 2800, "Q": 1.1},
          attack=0.0005, decay=0.025, sustain=0.0, duration=0.025, release=0.008, gain=0.38)]},
    "riq": {"gate": 1.0, "layers": [
        L(id="jingle", wave="noiseMetal", clockStart=44000, filter={"type": "highpass", "freq": 6000, "Q": 0.7},
          attack=0.001, decay=0.045, sustain=0.0, duration=0.045, release=0.015, gain=0.38)]},
    "riqO": {"gate": 1.0, "layers": [
        L(id="jingle", wave="noiseMetal", clockStart=44000, filter={"type": "highpass", "freq": 5500, "Q": 0.7},
          attack=0.002, decay=0.12, sustain=0.0, duration=0.12, release=0.03, gain=0.36)]},
    # OUT: the protest drum line outside the window (rendered full band; the Outside bus low-passes it)
    "outThump": {"gate": 1.0, "layers": [
        L(id="body", wave="triangle", crush=4, freqStart=92, freqEnd=80, freqCurve="exp", glide=0.03, followPitch=False,
          attack=0.001, decay=0.12, sustain=0.0, duration=0.12, release=0.01, gain=1.0),
        L(id="skin", wave="noise", clockStart=9000, filter={"type": "lowpass", "freq": 700, "Q": 0.5},
          attack=0.001, decay=0.05, sustain=0.0, duration=0.05, release=0.01, gain=0.35)]},
    "outSnare": {"gate": 1.0, "layers": [
        L(id="noise", wave="noise", clockStart=18000, filter={"type": "bandpass", "freq": 1100, "Q": 0.8},
          attack=0.001, decay=0.11, sustain=0.0, duration=0.11, release=0.02, gain=0.9),
        L(id="body", wave="triangle", crush=4, freqStart=190, freqEnd=170, freqCurve="exp", glide=0.02, followPitch=False,
          attack=0.001, decay=0.04, sustain=0.0, duration=0.04, release=0.01, gain=0.35)]},
    "outGhost": {"gate": 1.0, "layers": [
        L(id="noise", wave="noise", clockStart=18000, filter={"type": "bandpass", "freq": 1200, "Q": 0.8},
          attack=0.001, decay=0.05, sustain=0.0, duration=0.05, release=0.01, gain=0.28)]},
    # fanfare: a darbuka roll in four dynamic steps (high-passed: no low-frequency body) and the crash
    "roll1": {"gate": 1.0, "layers": [L(id="n", wave="noise", clockStart=30000, filter={"type": "highpass", "freq": 1300, "Q": 0.7}, attack=0.0005, decay=0.03, sustain=0.0, duration=0.03, release=0.008, gain=0.18)]},
    "roll2": {"gate": 1.0, "layers": [L(id="n", wave="noise", clockStart=30000, filter={"type": "highpass", "freq": 1300, "Q": 0.7}, attack=0.0005, decay=0.03, sustain=0.0, duration=0.03, release=0.008, gain=0.34)]},
    "roll3": {"gate": 1.0, "layers": [L(id="n", wave="noise", clockStart=30000, filter={"type": "highpass", "freq": 1300, "Q": 0.7}, attack=0.0005, decay=0.03, sustain=0.0, duration=0.03, release=0.008, gain=0.58)]},
    "roll4": {"gate": 1.0, "layers": [L(id="n", wave="noise", clockStart=30000, filter={"type": "highpass", "freq": 1300, "Q": 0.7}, attack=0.0005, decay=0.03, sustain=0.0, duration=0.03, release=0.008, gain=0.9)]},
    "crash": {"gate": 1.0, "layers": [
        L(id="wash", wave="noise", clockStart=42000, filter={"type": "highpass", "freq": 2200, "Q": 0.7},
          attack=0.001, decay=0.8, sustain=0.0, duration=0.8, release=0.05, gain=0.55),
        L(id="bell", wave="noiseMetal", clockStart=38000, filter={"type": "bandpass", "freq": 5200, "Q": 2.0},
          attack=0.001, decay=0.35, sustain=0.0, duration=0.35, release=0.04, gain=0.25)]},
    # the photobomb shutter as a kit hit (for the trophy stinger): two 12 ms NOI-S bursts 70 ms apart
    # high-passed at 3 kHz, plus a P1 pip at 4 kHz
    "shutter": {"gate": 1.0, "layers": [
        L(id="a", wave="noiseMetal", clockStart=46000, filter={"type": "highpass", "freq": 3000, "Q": 0.7}, attack=0.0005, decay=0.012, sustain=0.0, duration=0.012, release=0.004, gain=0.8),
        L(id="b", wave="noiseMetal", clockStart=46000, filter={"type": "highpass", "freq": 3000, "Q": 0.7}, delay=0.07, attack=0.0005, decay=0.012, sustain=0.0, duration=0.012, release=0.004, gain=0.7),
        L(id="pip", wave="pulse", duty=0.25, freqStart=4000, followPitch=False, delay=0.075, attack=0.001, decay=0.03, sustain=0.0, duration=0.03, release=0.008, gain=0.35)]},
}

# ============================================================ v2.0 (2026-10-04): the trap palette
# Bar: "less 8-bit and more trap hip-hop". The tunes, chords, tempos and form stay; the voices change.
# The 808 is a driven sine (tanh: its harmonics carry it on a phone speaker) with a 35 ms pitch punch
# and a short knock an octave up (the phone click of brief §8, now built into every 808 note). The
# lead is a breathy flute (the trap flute), the harmony dark bells and soft keys, the kit a kick,
# clap + snare, rim and white-noise hats with rolls on their own 24-steps-a-beat grid.
SUB = {"type": "lowpass", "freq": 1800, "Q": 0.0}


SAMPLE_DIR = os.path.join(HERE, "..", "od", "samples")


def sample_len(f):
    import wave
    with wave.open(os.path.join(SAMPLE_DIR, f)) as w:
        return w.getnframes() / w.getframerate()


def samp(f, gain=1.0, **k):
    """v2.1: a one-shot from audio/od/samples (CC0, SOURCES.md), played whole at its own pitch."""
    d = sample_len(f)
    return L(id=f[:-4], wave="sample", file=f, followPitch=False, attack=0.0005, decay=0.0, sustain=1.0, duration=round(d, 4),
             release=0.01, gain=gain, **k)


# v2.1 (Bar: "download free cc0 drum samples one shots to improve"): the 808 is a real 808 sample, tuned
# to every note (rootHz: its measured pitch; the playback rate follows the note and the glides), with
# the driven-sine grit band above 140 Hz kept under it for the phone speaker
S808 = {"808": ("808_c2.wav", 65.42, 0.34), "808x": ("808_drill_c1.wav", 32.73, 0.16)}


def _808s(name, slide=0, glide=0.11):
    f, root, grit = S808[name]
    start, g = ("A4", 0.0) if slide == 0 else (nm(69 + slide), glide)
    pitch = dict(freqStart=start, freqEnd="A4", freqCurve="exp", glide=g) if slide else dict(freqStart="A4")
    env = dict(attack=0.002 if slide == 0 else 0.01, decay=0.0, sustain=1.0, duration="note", release=0.06)
    return {"gate": 0.92, "layers": [
        L(id="s808", wave="sample", file=f, rootHz=root, gain=1.0, **pitch, **env),
        L(id="grit", wave="sine", drive=6.0, filter={"type": "highpass", "freq": 140, "Q": -3.0103}, gain=grit,
          **pitch, **dict(env, decay=0.9, sustain=0.5))]}


def _808(slide=0, glide=0.11):
    """v2.1 (Bar: "חסר לי סאבים מגניבים"): the 808 in two bands, as the mix guides split it. `sub`: a
    clean sine, the deep weight (40-80 Hz), untouched. `grit`: the same sine driven hard (tanh x6) and
    high-passed at 140 Hz, so its 3rd and 5th harmonics carry the bass line on a phone speaker while
    the sub stays clean; `oct` adds the 2nd harmonic. A plain note opens with the punch (an octave
    above, falling in 40 ms: the knock that makes an 808 read as a hit). `slide` != 0: a legato glide
    from `slide` semitones away (the previous note) over `glide` s, no punch (a slide never re-attacks)."""
    start, g = ("A5", 0.04) if slide == 0 else (nm(69 + slide), glide)
    env = dict(attack=0.003 if slide == 0 else 0.012, decay=0.9, sustain=0.55, duration="note", release=0.09)
    pitch = dict(freqStart=start, freqEnd="A4", freqCurve="exp", glide=g)
    return {"gate": 0.92, "layers": [
        L(id="sub", wave="sine", gain=1.0, **pitch, **env),
        L(id="grit", wave="sine", drive=6.0, filter={"type": "highpass", "freq": 140, "Q": -3.0103}, gain=0.5, **pitch, **env),
        L(id="oct", wave="sine", drive=2.0, filter={"type": "highpass", "freq": 140, "Q": -3.0103}, gain=0.16,
          **dict(pitch, freqStart=nm(81 + slide) if slide else "A6", freqEnd="A5"), **env)]}


# the 808 hat (TR-808 circuit): six square oscillators at the 808's metal frequencies, band-passed
# high; plus a little white noise for air (Cherry Audio's Transistor 808 notes, the 808 service notes)
HAT_OSC = [205.3, 304.4, 369.6, 522.7, 540.0, 800.0]


def _hat(decay, gain, bp=10000):
    return {"gate": 1.0, "layers": [
        L(id="o%d" % i, wave="square", freqStart=f, followPitch=False, filter={"type": "bandpass", "freq": bp, "Q": 1.2},
          attack=0.0005, decay=decay, sustain=0.0, duration=decay, release=0.008, gain=gain * 1.6)
        for i, f in enumerate(HAT_OSC)] + [
        L(id="air", wave="noise", clockStart=44000, filter={"type": "highpass", "freq": 7500, "Q": -3.0103},
          attack=0.0005, decay=decay * 0.8, sustain=0.0, duration=decay * 0.8, release=0.008, gain=gain * 0.35)]}


def _flute(gate, sustain, decay, release, vib=True):
    v = {"rateHz": 5.0, "depthCents": 14, "delay": 0.22} if vib else None
    tone = L(id="tone", wave="sine", freqStart="A4", attack=0.022, decay=decay, sustain=sustain, duration="note",
             release=release, gain=1.0)
    body = L(id="body", wave="triangle", freqStart="A4", attack=0.03, decay=decay, sustain=sustain * 0.85,
             duration="note", release=release, filter={"type": "lowpass", "freq": 4000, "Q": 0.0}, gain=0.4)
    over = L(id="over", wave="sine", freqStart="A5", attack=0.02, decay=decay, sustain=sustain * 0.6, duration="note",
             release=release, gain=0.14)
    third = L(id="third", wave="sine", freqStart="E6", attack=0.02, decay=decay, sustain=sustain * 0.4, duration="note",
              release=release, gain=0.07)
    breath = L(id="breath", wave="noise", clockStart=30000, filter={"type": "bandpass", "freq": 3200, "Q": 1.0},
               attack=0.004, decay=0.07, sustain=0.08, duration="note", release=release, gain=0.24)
    if v:
        for x in (tone, body, over, third):
            x["vibrato"] = v
    return {"gate": gate, "layers": [tone, body, over, third, breath]}


def _bell(ring, gain=1.0):
    return {"gate": 1.0, "layers": [
        L(id="p1", wave="sine", freqStart="A4", attack=0.002, decay=ring, sustain=0.0, duration=ring, release=0.08, gain=gain),
        L(id="p2", wave="sine", freqStart="A5", attack=0.001, decay=ring * 0.4, sustain=0.0, duration=ring * 0.4, release=0.05, gain=0.32 * gain),
        L(id="p3", wave="sine", freqStart="E6", attack=0.001, decay=ring * 0.15, sustain=0.0, duration=ring * 0.15, release=0.03, gain=0.14 * gain),
        L(id="tine", wave="sine", freqStart="E7", attack=0.0005, decay=0.02, sustain=0.0, duration=0.02, release=0.01, gain=0.12 * gain)]}


TRAP = {
    "808": _808(),
    # the lead: legato flute (the anthem's home voice: gate >= 0.85, "note" length) and a short one
    "flute": _flute(0.92, 0.78, 0.18, 0.08),
    "fluteS": _flute(0.7, 0.55, 0.12, 0.06, vib=False),
    # the counter-line voice (Knesset's hocket and round): a marimba-ish pluck, a sine and its octave
    "pluck": {"gate": 0.8, "layers": [
        L(id="tone", wave="sine", freqStart="A4", attack=0.002, decay=0.22, sustain=0.25, duration="note", release=0.06, gain=1.0),
        L(id="oct", wave="sine", freqStart="A5", attack=0.001, decay=0.07, sustain=0.0, duration=0.07, release=0.02, gain=0.3),
        L(id="body", wave="triangle", freqStart="A4", attack=0.002, decay=0.12, sustain=0.15, duration="note", release=0.05,
          filter={"type": "lowpass", "freq": 2000, "Q": 0.0}, gain=0.3)]},
    "bell": _bell(0.55),
    "bellLong": _bell(0.9),
    # soft keys: a sine and a low-passed triangle, slow attack, re-struck (never over 1.0 s)
    "keys": {"gate": 0.9, "layers": [
        L(id="tone", wave="sine", freqStart="A4", attack=0.035, decay=0.35, sustain=0.55, duration="note", release=0.14, gain=1.0),
        L(id="body", wave="triangle", freqStart="A4", attack=0.04, decay=0.3, sustain=0.45, duration="note", release=0.14,
          filter={"type": "lowpass", "freq": 1500, "Q": 0.0}, gain=0.45),
        L(id="tine", wave="sine", freqStart="A6", attack=0.001, decay=0.04, sustain=0.0, duration=0.04, release=0.02, gain=0.08)]},
    # the kit
    # the kick: a sine falling 210 -> 48 Hz in 60 ms (the punch), driven, a click on top. It owns the
    # attack; the 808 ducks under it (the sidechain, gen_od_sevev.gd _duck)
    "kick": {"gate": 1.0, "layers": [
        L(id="body", wave="sine", freqStart=210, freqEnd=48, freqCurve="exp", glide=0.06, followPitch=False, drive=2.2,
          attack=0.0008, decay=0.28, sustain=0.0, duration=0.28, release=0.02, gain=1.0),
        L(id="click", wave="noise", clockStart=26000, filter={"type": "bandpass", "freq": 3500, "Q": 0.8},
          attack=0.0003, decay=0.005, sustain=0.0, duration=0.005, release=0.003, gain=0.5)]},
    # the 808 clap: band-passed noise (1.1 kHz) retriggered four times 11 ms apart, then the tail;
    # a high crack for the phone. The room comes from the snares channel's reverb send.
    "clap": {"gate": 1.0, "layers": [
        L(id="c%d" % i, wave="noise", clockStart=30000, filter={"type": "bandpass", "freq": 1100, "Q": 1.0}, delay=0.011 * i,
          attack=0.0004, decay=0.009, sustain=0.0, duration=0.009, release=0.002, gain=0.75 + 0.05 * i) for i in range(3)] + [
        L(id="tail", wave="noise", clockStart=30000, filter={"type": "bandpass", "freq": 1250, "Q": 0.9}, delay=0.033,
          attack=0.0004, decay=0.19, sustain=0.0, duration=0.19, release=0.03, gain=0.95),
        L(id="crack", wave="noise", clockStart=44000, filter={"type": "highpass", "freq": 3000, "Q": -3.0103}, delay=0.033,
          attack=0.0004, decay=0.07, sustain=0.0, duration=0.07, release=0.02, gain=0.5)]},
    # the snare: two drum-head tones and the snappy (high-passed noise), tight (a trap snare is dry)
    "snare": {"gate": 1.0, "layers": [
        L(id="head1", wave="sine", freqStart=330, freqEnd=185, freqCurve="exp", glide=0.02, followPitch=False,
          attack=0.0005, decay=0.07, sustain=0.0, duration=0.07, release=0.01, gain=0.55),
        L(id="head2", wave="triangle", freqStart=480, freqEnd=330, freqCurve="exp", glide=0.015, followPitch=False,
          attack=0.0005, decay=0.04, sustain=0.0, duration=0.04, release=0.01, gain=0.25),
        L(id="snappy", wave="noise", clockStart=44000, filter={"type": "highpass", "freq": 1800, "Q": -3.0103},
          attack=0.0005, decay=0.15, sustain=0.0, duration=0.15, release=0.02, gain=0.7)]},
    "snareG": {"gate": 1.0, "layers": [
        L(id="snappy", wave="noise", clockStart=44000, filter={"type": "highpass", "freq": 2000, "Q": -3.0103},
          attack=0.0005, decay=0.05, sustain=0.0, duration=0.05, release=0.01, gain=0.26)]},
    "rim": {"gate": 1.0, "layers": [
        L(id="click", wave="noise", clockStart=30000, filter={"type": "bandpass", "freq": 2600, "Q": 3.0},
          attack=0.0005, decay=0.018, sustain=0.0, duration=0.018, release=0.005, gain=0.7),
        L(id="tone", wave="triangle", freqStart=1650, followPitch=False, attack=0.0005, decay=0.016, sustain=0.0,
          duration=0.016, release=0.005, gain=0.25)]},
    "hat": _hat(0.04, 1.0),
    "hatO": _hat(0.26, 0.8, 9000),
    # the fanfare's snare roll in four dynamic steps
    "sroll1": {"gate": 1.0, "layers": [L(id="n", wave="noise", clockStart=30000, filter={"type": "bandpass", "freq": 1900, "Q": 0.7}, attack=0.0005, decay=0.045, sustain=0.0, duration=0.045, release=0.01, gain=0.2)]},
    "sroll2": {"gate": 1.0, "layers": [L(id="n", wave="noise", clockStart=30000, filter={"type": "bandpass", "freq": 1900, "Q": 0.7}, attack=0.0005, decay=0.045, sustain=0.0, duration=0.045, release=0.01, gain=0.36)]},
    "sroll3": {"gate": 1.0, "layers": [L(id="n", wave="noise", clockStart=30000, filter={"type": "bandpass", "freq": 2000, "Q": 0.7}, attack=0.0005, decay=0.04, sustain=0.0, duration=0.04, release=0.01, gain=0.58)]},
    "sroll4": {"gate": 1.0, "layers": [L(id="n", wave="noise", clockStart=30000, filter={"type": "bandpass", "freq": 2100, "Q": 0.7}, attack=0.0005, decay=0.035, sustain=0.0, duration=0.035, release=0.01, gain=0.85)]},
}
# v2.1: the 808's legato glides, one instrument per interval from the previous note: 808u<n> slides UP
# into the note from n semitones below, 808d<n> slides DOWN from n above (bass808 picks them)
for _name in S808:
    TRAP[_name] = _808s(_name)
    for _n in range(1, 25):
        TRAP["%su%d" % (_name, _n)] = _808s(_name, -_n)
        TRAP["%sd%d" % (_name, _n)] = _808s(_name, _n)
# the kit, sampled (audio/od/samples/SOURCES.md); the synthesized voices above stay as the fallback
TRAP.update({
    "kick": {"gate": 1.0, "layers": [samp("kick.wav", 1.0)]},
    "clap": {"gate": 1.0, "layers": [samp("clap.wav", 1.0)]},
    "snare": {"gate": 1.0, "layers": [samp("snare.wav", 0.9)]},
    "snareG": {"gate": 1.0, "layers": [samp("snare.wav", 0.28)]},
    "rim": {"gate": 1.0, "layers": [samp("rim.wav", 0.8)]},
    "snap": {"gate": 1.0, "layers": [samp("snap.wav", 0.9)]},
    "hat": {"gate": 1.0, "layers": [samp("hat.wav", 1.0)]},
    "hatO": {"gate": 1.0, "layers": [samp("hat_open.wav", 0.8)]},
    "tablaG": {"gate": 1.0, "layers": [samp("tabla_te.wav", 0.5)]},
    "tabla": {"gate": 1.0, "layers": [samp("tabla_na.wav", 0.6)]},
})
INSTRUMENTS.update(TRAP)

KITS = {
    "darbuka": {"D": "dum", "d": "dumG", "T": "tek", "k": "tekG", "j": "riq", "o": "riqO"},
    # the courthouse tiptoes: a brushed, softer darbuka (lower crest factor in the sparsest era)
    "darbukaCourt": {"D": "dumSoft", "T": "tekSoft", "k": "tekG", "j": "riq", "o": "riqO"},
    "outside": {"B": "outThump", "S": "outSnare", "g": "outGhost"},
    "fanfare": {"1": "roll1", "2": "roll2", "3": "roll3", "4": "roll4", "X": "crash", "D": "dum"},
    "shutter": {"Z": "shutter"},
    # v2.0: the trap kit (K kick, C clap, S snare, s ghost snare, R rim, t the darbuka tek as a ghost
    # perc, o the open riq) and the hats on their own grid (h hat, g ghost, o open)
    "trap": {"K": "kick", "C": "clap", "S": "snare", "s": "snareG", "R": "rim", "t": "tablaG", "T": "tabla", "N": "snap", "X": "crash"},
    # v2.1: the hats with velocity: h 100, m 85, g 55, q 35 (rolls swell q -> m), o the open hat
    "trapHats": {"h": "hat", "m": "hat@0.85", "g": "hat@0.55", "q": "hat@0.35", "o": "hatO"},
    "trapFanfare": {"1": "sroll1", "2": "sroll2", "3": "sroll3", "4": "sroll4", "X": "crash", "K": "kick"},
}

# ============================================================ v1.2 (2026-09-29): HaTikva's minor
# Client direction (Bar, via the orchestrator): the shared mode moves from hijaz to HaTikva's minor
# (natural minor, the leading tone raised at cadences), and the material alludes to the anthem's
# contour: the stepwise rise 1-2-b3-4-5 to the held 5, the b6-5 / b6-5 neighbour, the leap to the
# octave. Played straight, never mocked; about 2 bars of contour at most in any one place. The
# hijaz data of v1.1 is archived in audio/od/legacy/*.v1.1-hijaz.json (never rendered).
#
# The leitmotif "עוד סבב" is now the anthem's rise in the speech rhythm of the words: pickup 1 |
# 2 (OD) b3 (s') 4 (VAV) 5 (held, over V). It lands on the dominant, unresolved; the next round's
# bar-1 downbeat (i) is the resolution. The round still never closes.

# ============================================================ BALFOUR: D minor, 116 BPM, hora

def balfour():
    S = 16
    lead = {
        # v1.8 (Bar 2026-10-03: "HaTikva and more traditional songs"; the full first phrase, respectfully):
        # A is the anthem's first section as written, "כל עוד בלבב פנימה / נפש יהודי הומיה" and its
        # repeat, "ולפאתי מזרח קדימה / עין לציון צופיה". Verified: the Hatikvah score (English
        # Wikipedia rev 1375885586, CC BY-SA 4.0; melody Samuel Cohen 1888, public domain) via the npm
        # package anthem-scores 0.1.1 (anthems/IL.json, D minor), its rhythm to the 16th. Played
        # straight: legato on P1, no ornaments, no bends, never cut short (ANTHEM_HOME, check_music).
        "A": seq("D5:2 E5:2 F5:2 G5:2 A5:4 A5:4 | Bb5:2 A5:2 Bb5:2 D6:2 A5:8 | G5:4 G5:2 G5:2 F5:4 F5:4 |"
                 "E5:2 D5:2 E5:2 F5:2 D5:6 A4:2 | D5:2 E5:2 F5:2 G5:2 A5:4 A5:4 | Bb5:2 A5:2 Bb5:2 D6:2 A5:8 |"
                 "G5:4 G5:2 G5:2 F5:4 F5:4 | E5:2 D5:2 E5:2 F5:2 D5:8", S),
        "A2": seq("D5~E5:6 F5:6 G5:4 | A5:6 A5:6 G5:2 A5:2 | Bb5:6 A5:6 Bb5:4 | D6:6 A5:6 F5:4 |"
                  "F5:6 Bb5:6 D6:4 | C6:6 E6:6 D6:4 | C#6:6 E6:6 A5:4 | E6:4 D6:2 C#6:6 .:4", S),
        # v1.9: B is Hava Nagila (TUNES["havaNagila"]), part A "הבה נגילה ×3, ונשמחה" and part B "הבה
        # נרננה", in its own key D (freygish: D Eb F# G A Bb C), the F# the B section's colour
        "B": seq("D5:4 D5:6 F#5:2 Eb5:2 D5:2 | F#5:4 F#5:6 A5:2 G5:2 F#5:2 | G5:4 G5:6 Bb5:2 A5:2 G5:2 |"
                 "F#5:4 Eb5:4 D5:8 | F#5:2 F#5:4 Eb5:2 D5:2 D5:2 D5:4 | Eb5:2 Eb5:4 D5:2 C5:2 C5:2 C5:4 |"
                 "C5:4 Eb5:3 D5:1 C5:4 G5:4 | F#5:4 Eb5:4 D5:8", S),
        "T": seq("A5:6 F5:6 D5:4 | G5:6 Bb5:6 G5:4 | E5:6 G5:6 C6:4 | A5:6 C6:6 A5:4 |"
                 "Bb5:6 A5:6 G5:4 | G5:6 F5:6 E5:4 | E5:6 C#5:2 E5:4 .:2 D5:2 | E5:4 F5:2 G5:6 A5:4", S),
    }
    # A: the anthem's own harmony, a chord per half bar where the melody turns (bar 2: Gm under the
    # b6 neighbour, Dm under the held 5; bar 4: A under the 2-1-2, Dm under the close)
    A = ["Dm", "Gm|Dm", "Gm", "A|Dm", "Dm", "Gm|Dm", "Gm", "A|Dm"]
    A2 = ["Dm", "Dm", "Gm", "Dm", "Bb", "C", "A", "A"]
    B = ["D", "D", "Gm", "D", "D", "Cm", "Cm", "D"]   # Hava Nagila: the source's chords (John Chambers' ABC)
    T = ["Dm", "Gm", "C", "F", "Bb", "Gm", "A"]
    # v2.0 (Bar: "less 8-bit, more trap"): melodic trap at 116, half time (the clap on 3). A is held
    # back under the anthem (kick, clap, 8th hats, the 808 on 1 and 3); A' bounces (the 808 jumps the
    # octave on the "a" of 2, hats roll); B drops out for two bars under Hava Nagila, then builds;
    # T is the full beat into the motif.
    r_a = [(0, 8, "R"), (10, 6, "R")]
    r_main = [(0, 6, "R"), (7, 2, "O"), (10, 4, "R"), (14, 2, "F")]
    r_b = [(0, 7, "R"), (8, 4, "r"), (12, 4, "O")]
    bass = {"A": bass808(A, r_a, S), "A2": bass808(A2, r_main, S), "B": bass808(B, r_b, S),
            "T": bass808(T, r_main, S) + bass808(["Dm|A"], [(0, 7, "R"), (8, 8, "R")], S)}
    g_a = drums(S, K="x.........x.....", N="........x.......", t="......x.......x.")   # v2.1: finger snaps under the anthem
    g1 = drums(S, K="x......x..x.....", C="........x.......", S="........x.......", t="...x......x...x.")
    g2 = drums(S, K="x......x..x...x.", C="........x.......", S="........x.......", R="....x.......x...", s=".............x..")
    drop = drums(S, C="........x.......")
    fill = drums(S, K="x......x........", C="........x.......", S="........x.......", s="...........x.xxx")
    last = drums(S, K="x.......x.......", C="........x.......", s="............xxxx")
    kit = {"A": [g_a] * 7 + [fill], "A2": [g1, g2] * 3 + [g1, fill],
           "B": [drop, drop, g1, g2, g1, g2, g1, fill], "T": [g1, g2] * 3 + [g1, last]}
    h_a = hats("8", "8", "8", "8")
    h1 = hats("8", "16", "8", "16|t")
    h2 = hats("8", "8", "t", "32|o")
    h3 = hats("16", "8", "16", "48")
    h_fill = hats("16", "t", "32", "48")
    none = hats("-", "-", "-", "-")
    hat = {"A": [h_a] * 7 + [h1], "A2": [h1, h2, h1, h3, h1, h2, h1, h_fill],
           "B": [none, none, h_a, h_a, h1, h2, h1, h_fill], "T": [h1, h2, h3, h2, h1, h2, h1, hats("8", "8", "t", "32")]}
    half = [(0, 8), (8, 8)]
    keys = {k: keys_part(v, half, S) for k, v in {"A": A, "A2": A2, "B": B, "T": T + ["Dm|A"]}.items()}
    bounce = [(0, 0), (3, 2), (6, 1), (8, 3), (11, 2), (14, 1)]   # 3+3+2: the trap bell bounce
    bells = {"A": [_bar(S, [])] * 8, "A2": bells_part(A2, bounce, S), "B": [_bar(S, [])] * 4 + bells_part(B[4:], bounce, S),
             "T": bells_part(T, bounce, S) + [_bar(S, [])]}
    # bar 32 harmonises the motif a sixth below (the raised leading tone C# under the held 5)
    p2 = {"A": [_bar(S, [])], "A2": [_bar(S, [])], "B": [_bar(S, [])],
          "T": [_bar(S, [])] * 7 + [" ".join(seq("G4:4 A4:2 Bb4:6 C#5:4", S))]}
    outside = [drums(S, B="x.....x.....x...", S="....x.......x...", g="..x......x.....x"),
               drums(S, B="x.....x.....x...", S="....x.......x...", g=".......x..x...x.")]
    return {
        "title": "הכובע של בלפור (Balfour)",
        "tempoBpm": 116, "beatsPerBar": 4, "stepsPerBeat": 4, "rate": 31900, "key": "D", "mode": "minor",
        "mood": "Melodic trap in HaTikva's minor, the anthem on a flute, played straight; protest drums leak through the window.",
        "chords": {"A": A, "A2": A2, "B": B, "T": T + ["Dm|A"]},
        "reverb": ROOM, "busClip": BUS, "stemEq": STEM_EQ, "busComp": BUS_COMP,
        "channels": trap_channels(bass, kit, hat, keys, bells, p2, lead, "flute",
                                  gains={}),
        "outside": {"kit": "outside", "bars": outside, "gain": 0.6},
    }


# ============================================================ KNESSET: E minor, 132 BPM, maqsum

def knesset():
    S = 16
    # v1.9 (Bar: traditional songs; the Knesset argues): A is Hevenu Shalom Aleichem (TUNES["hevenu"],
    # Dm -> Em, up an octave), "הבאנו שלום עליכם" sung through. In A' they argue over it: P2 takes the
    # melody an octave down and P1 snatches every pickup before P2 can (a hocket), until both land on
    # the cadence together. B is Shalom Chaverim (TUNES["shalomChaverim"], its own key Em) as the round
    # it is: P1 leads, P2 enters two bars later in canon, and neither ever finishes first.
    lead = {
        "A": seq("B5:8 G5:6 F#5:2 | F#5:4 E5:4 .:2 E5:2 G5:2 B5:2 | E6:8 C6:6 B5:2 | B5:4 A5:4 .:2 A5:2 B5:2 C6:2 |"
                 "B5:6 F#5:2 B5:6 A5:2 | A5:4 G5:4 .:2 F#5:2 G5:2 A5:2 | B5:4 B5:4 B5:4 B5:4 |"
                 "B5:3 A5:1 G5:2 A5:2 B5:2 B4:2 E5:2 G5:2", S),
        "A2": seq(".:16 | .:10 E5:2 G5:2 B5:2 | .:16 | .:10 A5:2 B5:2 C6:2 | .:16 | .:10 F#5:2 G5:2 A5:2 | .:16 |"
                  "B5:3 A5:1 G5:2 F#5:2 E5:8", S),
        "B": seq("E5:4 E5:2 F#5:2 G5:4 E5:4 | G5:4 G5:2 A5:2 B5:4 B5:4 | E6:12 D6:4 | B5:12 B5:4 |"
                 "E6:4 B5:2 A5:2 G5:4 A5:4 | B5:4 G5:2 F#5:2 E5:4 B4:4 | E5:12 F#5:2 G5:2 | G5:12 B4:4", S),
        "T": seq("E5:3 G5:3 B5:2 E6:4 D6:2 B5:2 | C6:3 B5:3 C6:2 B5:4 A5:4 | A5:3 F#5:3 D5:2 F#5:4 A5:4 |"
                 "B5:3 G5:3 D5:2 G5:4 .:4 | E5:3 G5:3 C6:2 B5:4 A5:4 | A5:3 C6:3 E6:2 D#6:4 B5:4 |"
                 "F#5:6 D#5:2 F#5:4 .:2 E5:2 | F#5:4 G5:2 A5:6 B5:4", S),
    }
    A = ["Em|B", "Em", "Am|B", "Am", "B", "Em", "B", "B"]          # Hevenu: the source's chords, Dm -> Em
    A2 = ["Em|B", "Em", "Am|B", "Am", "B", "Em", "B", "B|Em"]
    B = ["Em", "G", "C", "B", "C", "Em", "Am", "Em"]               # Shalom Chaverim (the round agrees with them)
    T = ["Em", "Am", "D", "G", "C", "Am", "B"]
    # v2.0: the plenum goes drill. The 808 slides (up into the octave, down into the root), the hats
    # run in triplets, a second, late snare argues at the end of every other bar.
    p2 = {
        "A": [_bar(S, [])],
        # the melody an octave down, the pickups left to the lead (the hocket)
        "A2": seq("B4:8 G4:6 F#4:2 | F#4:4 E4:4 .:8 | E5:8 C5:6 B4:2 | B4:4 A4:4 .:8 | B4:6 F#4:2 B4:6 A4:2 |"
                  "A4:4 G4:4 .:8 | B4:4 B4:4 B4:4 B4:4 | B4:3 A4:1 G4:2 F#4:2 E4:8", S),
        # the round: the second voice enters two bars after the lead, an octave down
        "B": seq(".:16 | .:16 | E4:4 E4:2 F#4:2 G4:4 E4:4 | G4:4 G4:2 A4:2 B4:4 B4:4 | E5:12 D5:4 | B4:12 B4:4 |"
                 "E5:4 B4:2 A4:2 G4:4 A4:4 | B4:4 G4:2 F#4:2 E4:4 B3:4", S),
        "T": [_bar(S, [])] * 6 + [". . D#5 . . . F#5 . . . . . . . . .", " ".join(seq("A4:4 B4:2 C5:6 D#5:4", S))],
    }
    p2_inst = {"A": "pluck", "A2": "pluck", "B": "fluteS", "T": "pluck"}
    # v2.1: real drill (Native Instruments' drill walkthrough, Attack's UK drill dissection). Two-bar
    # cells: the snare on beat 3 of bar 1 and SHIFTED to beat 4 in bar 2; sparse kicks (bar 1: 1 and
    # the last 8th; bar 2: 16ths 1, 4, 7 and the last 8th); tresillo hats (3+3+2) with rolls into the
    # cell; the 808 follows the kicks and glides, and climbs the octave on bar 2's last two 8ths.
    k1 = drums(S, K="x.............x.", C="........x.......", S="........x.......", t="..........x.....")
    k2 = drums(S, K="x..x..x.......x.", C="............x...", S="............x...", R="........x.......", s="..........x.....")
    k1g = drums(S, K="x.............x.", C="........x.......", S="........x.......", s="...........x..x.", t="..........x.....")
    k2g = drums(S, K="x..x..x.......x.", C="............x...", S="............x...", R="........x.......", s="......x...x....x")
    a1 = drums(S, K="x.............x.", S="........x.......")
    a2 = drums(S, K="x..x..x.........", S="............x...")
    drop = drums(S, S="........x.......")
    fill = drums(S, K="x..x..x.........", C="............x...", S="............x...", s="........x.x.xxxx")
    last = drums(S, K="x.......x.......", S="........x.......", s="............xxxx")
    kit = {"A": [a1, a2] * 3 + [a1, fill], "A2": [k1, k2, k1g, k2g] * 2,
           "B": [drop, drop, k1, k2, k1g, k2g, k1, fill], "T": [k1, k2, k1g, k2g, k1, k2, k1g, last]}
    kit["A2"][-1] = fill
    r1 = [(0, 9, "R"), (14, 2, "r")]
    r2 = [(0, 3, "R"), (3, 3, "r"), (6, 6, "F"), (12, 2, "O"), (14, 2, "O")]
    bass = {"A": bass808(A, [[(0, 9, "R"), (14, 2, "r")], [(0, 3, "R"), (3, 3, "r"), (6, 8, "r")]], S, inst="808x"),
            "A2": bass808(A2, [r1, r2], S, inst="808x"), "B": bass808(B, [[(0, 9, "R")], [(0, 9, "R")], r1, r2], S, inst="808x"),
            "T": bass808(T, [r1, r2], S, inst="808x") + bass808(["Em|B"], [(0, 7, "R"), (8, 8, "r")], S, inst="808x")}
    tr = hats_tresillo()
    hat = {"A": [tr] * 7 + [hats_tresillo("t")], "A2": [tr, hats_tresillo("t"), tr, hats_tresillo("32")] * 2,
           "B": [hats("-", "-", "-", "-")] * 2 + [tr, hats_tresillo("t"), tr, hats_tresillo("32"), tr, hats_tresillo("48")],
           "T": [tr, hats_tresillo("t"), tr, hats_tresillo("32"), tr, hats_tresillo("t"), tr, hats_tresillo("48")]}
    half = [(0, 8), (8, 8)]
    keys = {k: keys_part(v, half, S) for k, v in {"A": A, "A2": A2, "B": B, "T": T + ["Em|B"]}.items()}
    dark = [(0, 3), (3, 2), (6, 0), (8, 1), (11, 2), (14, 0)]
    bells = {"A": bells_part(A, dark, S), "A2": [_bar(S, [])], "B": [_bar(S, [])] * 4 + bells_part(B[4:], dark, S),
             "T": bells_part(T, dark, S) + [_bar(S, [])]}
    return {
        "title": "המליאה (Knesset)",
        "tempoBpm": 132, "beatsPerBar": 4, "stepsPerBeat": 4, "rate": 32032, "key": "E", "mode": "minor",
        "mood": "A plenum haggle gone drill: shifting snares, tresillo hats, gliding 808s under Hevenu Shalom Aleichem, "
                "then Shalom Chaverim as a round nobody finishes first.",
        "chords": {"A": A, "A2": A2, "B": B, "T": T + ["Em|B"]},
        "reverb": ROOM, "busClip": BUS, "stemEq": STEM_EQ, "busComp": BUS_COMP,
        "channels": trap_channels(bass, kit, hat, keys, bells, p2, lead, "flute", p2_inst=p2_inst,
                                  lead_section_inst={"B": "fluteS"}, bass_inst="808x",
                                  gains={"p2": 0.24}),
    }


# ============================================================ COURTHOUSE: G minor, 88 BPM, half-time swing

def courthouse():
    S = 12   # triplet 8ths: a swung 8th pair is 2 + 1
    lead = {
        # bars 1-4: the anthem's contour in half time, legato on P1 (@flute) and dead straight over the
        # tiptoe bass: the mock-solemn register is the sincerity. Then the noir tiptoe resumes. The
        # staccato tiptoe never carries the anthem contour (the guardrail: never mocked).
        "A": seq("G4@flute:3 A4@flute:3 Bb4@flute:3 C5@flute:3 | D5@flute:4 .:2 D5@flute:3 .:3 | Eb5@flute:3 D5@flute:3 Eb5@flute:3 G5@flute:3 |"
                 "D5@flute:4 .:2 Bb4:1 .:1 G4:1 .:3 | G5:1 .:1 F5:1 Eb5:1 .:1 D5:1 C5:3 .:3 |"
                 "Bb4:1 .:1 C5:1 D5:1 .:1 Eb5:1 G5:3 .:3 | F#5:2 Eb5:1 D5:2 C5:1 A4:3 .:3 | Bb4:2 A4:1 G4:3 .:6", S),
        "A2": seq("G5:1 .:1 D5:1 C5:1 .:1 D5:1 Bb4:3 .:3 | C5:1 .:1 C5:1 D5:1 .:1 C5:1 Bb4:1 .:1 A4:1 G4:3 |"
                  "Eb5:1 .:1 Eb5:1 F5:1 .:1 Eb5:1 C6:3 .:3 | Bb5:1 .:1 Bb5:1 C6:1 .:1 Bb5:1 G5:3 .:3 |"
                  "G5:1 .:1 G5:1 F5:1 .:1 Eb5:1 Bb4:3 .:3 | Eb5:1 .:1 Eb5:1 D5:1 .:1 C5:1 G4:3 .:3 |"
                  "A4:2 C5:1 F#5:2 C5:1 A4:2 C5:1 F#4:3 | D5:2 A4:1 F#4:2 A4:1 D5:3 .:3", S),
        # v1.9: B is Ma'oz Tzur (TUNES["maozTzur"]), its first section, D major -> G minor (3 -> b3,
        # 6 -> b6, the leading tone kept): a hymn for the trial, slow and straight
        "B": seq("G4:3 D4:3 G4:3 C5:3 | Bb4:3 A4:3 G4:6 | D5:3 Eb5:3 A4:3 Bb4:2 C5:1 | Bb4:3 A4:3 G4:6 |"
                 "G4:3 D4:3 G4:3 C5:3 | Bb4:3 A4:3 G4:6 | D5:3 Eb5:3 A4:3 Bb4:2 C5:1 | Bb4:3 A4:3 G4:6", S),
        "T": seq("D5:1 .:1 D5:1 C5:1 .:1 D5:1 Bb4:3 .:3 | Eb5:1 .:1 Eb5:1 G5:1 .:1 Eb5:1 Bb4:3 .:3 |"
                 "C5:1 .:1 Eb5:1 G5:1 .:1 Eb5:1 C5:3 .:3 | D5:2 Bb4:1 G4:3 .:6 | Eb5:1 .:1 Eb5:1 D5:1 .:1 C5:1 G4:3 .:3 |"
                 "G4:2 Bb4:1 Eb5:2 Bb4:1 G4:3 .:3 | F#4:2 A4:1 D5:3 .:5 G4:1 | A4@flute:3 Bb4@flute:2 C5@flute:4 D5@flute:3", S),
    }
    A = ["Gm", "Gm", "Cm", "Gm", "Cm", "Eb", "D", "Gm"]
    A2 = ["Gm", "Gm", "Cm", "Gm", "Eb", "Cm", "D", "D"]
    B = ["Gm|Cm", "Gm|D", "Cm|D", "Gm", "Gm|Cm", "Gm|D", "Cm|D", "Gm"]   # Ma'oz Tzur, the source's harmony in G minor
    T = ["Gm", "Eb", "Cm", "Gm", "Cm", "Eb", "D"]
    # v2.0: the courthouse is the slow, swung trap (the triplet grid is native here): claps on 2 and
    # 4, triplet hats with 16th-triplet rolls, a sparse 808. The anthem's contour on the flute, the
    # tiptoe on the pluck, Ma'oz Tzur on the short flute over the keys.
    p2 = {"A": [_bar(S, [])], "A2": [_bar(S, [])], "B": [_bar(S, [])],
          "T": [_bar(S, [])] * 6 + [". . . F#4 . . . . . . . .", " ".join(seq("C4:3 D4:2 Eb4:4 F#4:3", S))]}
    r_a = [(0, 4, "R"), (6, 4, "R")]
    r_main = [(0, 4, "R"), (5, 2, "O"), (8, 4, "r")]
    bass = {"A": bass808(A, r_a, S), "A2": bass808(A2, r_main, S), "B": bass808(B, r_a, S),
            "T": bass808(T, r_main, S) + bass808(["Gm|D"], r_a, S)}
    g_a = drums(S, K="x.......x...", C="...x.....x..")
    g1 = drums(S, K="x....x..x...", C="...x.....x..", S=".........x..", t=".......x....")
    g2 = drums(S, K="x....x....x.", C="...x.....x..", S=".........x..", s="...........x")
    drop = drums(S, C="...x.....x..")
    fill = drums(S, K="x....x......", C="...x.....x..", S=".........x..", s=".......x.xxx")
    last = drums(S, K="x.....x.....", C="...x.....x..", s="..........xx")
    kit = {"A": [g_a] * 7 + [fill], "A2": [g1, g2] * 3 + [g1, fill],
           "B": [drop, drop, g1, g2, g1, g2, g1, fill], "T": [g1, g2] * 3 + [g1, last]}
    h_a = hats("S", "S", "S", "S")
    h1 = hats("T", "S", "T", "t")
    h2 = hats("S", "T", "S", "48")
    h3 = hats("T", "T", "t", "48")
    none = hats("-", "-", "-", "-")
    hat = {"A": [h_a] * 7 + [h1], "A2": [h1, h2, h1, h3, h1, h2, h1, hats("t", "t", "48", "48")],
           "B": [none, none, h_a, h_a, h1, h2, h1, h3], "T": [h1, h2, h3, h2, h1, h2, h1, hats("S", "S", "T", "48")]}
    half = [(0, 4), (6, 4)]
    keys = {k: keys_part(v, half, S) for k, v in {"A": A, "A2": A2, "B": B, "T": T + ["Gm|D"]}.items()}
    swing = [(0, 0), (2, 2), (3, 1), (5, 3), (6, 2), (8, 1), (9, 0), (11, 2)]
    bells = {"A": [_bar(S, [])] * 4 + bells_part(A[4:], swing, S), "A2": bells_part(A2, swing, S), "B": [_bar(S, [])],
             "T": bells_part(T, swing, S) + [_bar(S, [])]}
    return {
        "title": "בית המשפט (Courthouse)",
        "tempoBpm": 88, "beatsPerBar": 4, "stepsPerBeat": 3, "rate": 22044, "key": "G", "mode": "minor",
        "mood": "Mock-solemn swung trap: the anthem's contour stated straight on the flute, then sneaking past the bench on a pluck.",
        "targetOffsetDb": -1.0,
        "_targetOffset": "The court hush: 1 LU under the other eras (mock-solemn).",
        "chords": {"A": A, "A2": A2, "B": B, "T": T + ["Gm|D"]},
        "reverb": ROOM, "busClip": BUS, "stemEq": STEM_EQ_COURT, "busComp": BUS_COMP,
        "channels": trap_channels(bass, kit, hat, keys, bells, p2, lead, "pluck", lead_section_inst={"B": "fluteS"},
                                  lead_fx={"echo": {"steps": 2, "db": -10.0, "repeats": 2}},
                                  gains={"p2": 0.26, "lead": 0.23, "drums": 1.0, "hats": 0.42}),
    }


# ============================================================ WASHINGTON: F Mixolydian, 144 BPM, stride

def washington():
    S = 16
    # Stays the odd one out: showbiz Mixolydian. The anthem follows him abroad only at cadences, in
    # the minor and played straight: A bar 7 is the b6-5 / b6-5 neighbour over bVI (Db), and bar 32 is
    # the motif in F minor over V (C, with the raised E). No anthem contour in the ragtime major: a
    # major-key stride anthem would read as parody (the guardrail).
    lead = {
        # v1.9 (Bar: traditional songs; the money): A is Dayenu's verse "אילו הוציאנו" (TUNES["dayenu"],
        # G -> F), the second time an octave up; A' is its chorus "דיינו" in full: it would have been
        # enough, and the cheques keep coming. B is Siman Tov u'Mazal Tov (TUNES["simanTov"], the
        # freilach, Gm -> D minor, F's relative minor): the wedding toast at the gala.
        "A": seq("A4:2 C5:2 C5:2 C5:2 C5:2 D5:2 C5:2 Bb4:2 | A4:2 C5:2 C5:2 C5:2 C5:2 D5:2 C5:2 Bb4:2 |"
                 "A4:2 C5:2 G4:2 Bb4:2 A4:2 C5:2 G4:2 Bb4:2 | A4:4 G4:4 F4:4 .:4 |"
                 "A5:2 C6:2 C6:2 C6:2 C6:2 D6:2 C6:2 Bb5:2 | A5:2 C6:2 C6:2 C6:2 C6:2 D6:2 C6:2 Bb5:2 |"
                 "A5:2 C6:2 G5:2 Bb5:2 A5:2 C6:2 G5:2 Bb5:2 | A5:4 G5:4 F5:4 .:4", S),
        "A2": seq("A4:4 A4:4 C5:2 Bb4:4 G4:2 | Bb4:4 Bb4:4 D5:2 C5:4 A4:2 | C5:4 C5:4 F5:2 E5:4 E5:2 |"
                  "E5:2 C5:2 D5:2 E5:2 F5:2 C5:2 A4:2 F4:2 | A4:4 A4:4 C5:2 Bb4:4 G4:2 | Bb4:4 Bb4:4 D5:2 C5:4 A4:2 |"
                  "C5:4 C5:4 F5:2 E5:4 E5:2 | E5:2 C5:2 D5:2 E5:2 F5:4 .:4", S),
        "B": seq("D5:2 D5:2 D5:2 A4:2 D5:2 D5:2 D5:2 A4:2 | D5:2 D5:2 D5:2 A4:2 D5:2 D5:2 D5:4 |"
                 "F5:2 F5:2 F5:2 D5:2 F5:2 F5:2 F5:2 D5:2 | F5:2 F5:2 F5:2 D5:2 F5:2 F5:2 F5:4 |"
                 "G5:2 G5:2 G5:2 F5:2 G5:2 G5:2 G5:2 F5:2 | G5:2 G5:2 G5:2 A5:2 F5:2 E5:2 D5:4 |"
                 "D5:4 G5:4 G5:4 F5:2 E5:2 | D5:8 .:8", S),
        "T": seq("F5:3 A5:3 C6:2 D6:3 C6:3 A5:2 | G5:3 Bb5:3 Eb6:2 D6:3 C6:3 Bb5:2 | D6:3 F6:3 D6:2 Bb5:4 F5:4 |"
                 "A5:3 C6:3 Eb6:2 D6:4 C6:4 | Bb5:3 G5:3 D5:2 G5:2 A5:2 Bb5:4 | C6:3 Bb5:3 G5:2 Eb5:4 G5:4 |"
                 "A5:3 G5:3 C5:2 .:6 F5:2 | G5:4 Ab5:2 Bb5:6 C6:4", S),
    }
    A = ["F", "F", "F|C7", "F", "F", "F", "F|C7", "F"]                       # Dayenu's verse, I / V7
    A2 = ["F|C7", "Bb|F", "C7", "C7|F", "F|C7", "Bb|F", "C7", "C7|F"]        # its chorus
    B = ["Dm", "Dm", "Dm", "Dm", "Gm", "A7|Dm", "Gm|A7", "Dm"]               # Siman Tov: the source's chords, Gm -> Dm
    T = ["F", "Eb", "Bb", "F", "Gm", "Eb", "F"]
    # v2.0: showbiz trap at 144, the classic tempo: the 808 walks the stride's roots, open hats lift
    # every other beat, a rim keeps the old backbeat under the clap on 3; bright bells in the major.
    p2 = {"A": [_bar(S, [])], "A2": [_bar(S, [])], "B": [_bar(S, [])],
          "T": [_bar(S, [])] * 7 + [" ".join(seq("Bb4:4 C5:2 Db5:6 E5:4", S))]}
    r_a = [(0, 7, "R"), (8, 7, "R")]
    r_main = [(0, 6, "R"), (7, 2, "O"), (10, 3, "R"), (13, 3, "r")]
    bass = {"A": bass808(A, r_a, S), "A2": bass808(A2, r_main, S), "B": bass808(B, r_main, S),
            "T": bass808(T, r_main, S) + bass808(["Fm|C"], [(0, 7, "R"), (8, 8, "R")], S)}
    g_a = drums(S, K="x.........x.....", C="........x.......", R="....x.......x...")
    g1 = drums(S, K="x......x..x.....", C="........x.......", S="........x.......", R="....x...........", s="..............x.")
    g2 = drums(S, K="x......x..x...x.", C="........x.......", S="........x.......", R="....x.......x...")
    drop = drums(S, C="........x.......", R="....x.......x...")
    fill = drums(S, K="x......x........", C="........x.......", S="........x.......", s="..........x.xxxx")
    last = drums(S, K="x.......x.......", C="........x.......", s="............xxxx")
    kit = {"A": [g_a] * 7 + [fill], "A2": [g1, g2] * 3 + [g1, fill],
           "B": [drop, drop, g1, g2, g1, g2, g1, fill], "T": [g1, g2] * 3 + [g1, last]}
    h_a = hats("8", "8|o", "8", "8|o")
    h1 = hats("16", "8|o", "16", "16|t")
    h2 = hats("8", "16", "8|o", "32")
    h3 = hats("16", "16", "t", "48")
    none = hats("-", "-", "-", "-")
    hat = {"A": [h_a] * 7 + [h1], "A2": [h1, h2, h1, h3, h1, h2, h1, hats("16", "t", "32", "48")],
           "B": [none, none, h_a, h_a, h1, h2, h1, h3], "T": [h1, h2, h3, h2, h1, h2, h1, hats("8", "8", "t", "32")]}
    half = [(0, 8), (8, 8)]
    keys = {k: keys_part(v, half, S) for k, v in {"A": A, "A2": A2, "B": B, "T": T + ["Fm|C"]}.items()}
    bright = [(0, 0), (2, 1), (4, 2), (6, 3), (10, 2), (12, 1)]
    bells = {"A": [_bar(S, [])] * 4 + bells_part(A[4:], bright, S), "A2": bells_part(A2, bright, S),
             "B": [_bar(S, [])] * 4 + bells_part(B[4:], bright, S), "T": bells_part(T, bright, S) + [_bar(S, [])]}
    return {
        "title": "וושינגטון (Washington)",
        "tempoBpm": 144, "beatsPerBar": 4, "stepsPerBeat": 4, "rate": 31968, "key": "F", "mode": "mixolydian",
        "mood": "Showbiz trap: Dayenu over a strutting 808 (it would have been enough), Siman Tov at the gala; the anthem's minor follows him abroad at bar 32.",
        "chords": {"A": A, "A2": A2, "B": B, "T": T + ["Fm|C"]},
        "reverb": ROOM, "busClip": BUS, "stemEq": STEM_EQ, "busComp": BUS_COMP,
        "channels": trap_channels(bass, kit, hat, keys, bells, p2, lead, "flute",
                                  gains={"lead": 0.18}),
    }


# ============================================================ stingers (written in D minor; transposed per key)

TRANSPOSE = {"D": 0, "E": 2, "G": 5, "F": 3}
KEY_ERA = {"D": "balfour", "E": "knesset", "G": "courthouse", "F": "washington"}


def stingers():
    S = 32   # 32nds
    # Fanfare, played straight: 1 bar of snare roll (crescendo; a darbuka roll before v2.0) whose last beat carries the pickup
    # (a C#-D leading-tone lift into 1: stepwise chromatic, so never a bugle call); then the motif,
    # the anthem's rise 2-b3-4-5 on P1 with P2 a sixth below at 50% (the raised leading tone C# under
    # the held 5), TRI i - bVI - V, the crash on the downbeat. Then up to 4 half-bar P2 "ta-da" tags,
    # the anthem's other two gestures, one more per round: b6-5, b6-5, the leap up to the octave 5-5',
    # b6'-5'. Every cut ends on 5 over V: unresolved; the new loop's bar-1 downbeat (i) resolves it.
    # v2.0: the trap snare roll, accelerating: 8ths, 16ths, then 32nds in two dynamic steps
    roll = "1 . . . 1 . . . 2 . 2 . 2 . 2 . 3 3 3 3 3 3 3 3 4 4 4 4 4 4 4 4"
    fan = {
        "lead": [". " * 28 + "C#5 - D5 -", " ".join(seq("E5:8 F5:4 G5:12 A5:8", S)), ". " * 31 + ".", ". " * 31 + "."],
        "p2": [". " * 28 + "F4 - - -", " ".join(seq("G4:8 A4:4 Bb4:12 C#5:8", S)),
               " ".join(seq("Bb4:4 A4:12 Bb4:4 A4:12", S)), " ".join(seq("A4:4 A5:12 Bb5:4 A5:12", S))],
        # v2.0: the 808 an octave under the old TRI line; the kick under the crash
        "bass": [". " * 32, " ".join(seq("D2:6 .:6 Bb1:10 .:2 A1:8", S)),
                 " ".join(seq(".:4 A1:10 .:2 .:4 A1:10 .:2", S)), " ".join(seq(".:4 A1:10 .:2 .:4 A1:10 .:2", S))],
        "kit": [roll, "X K . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .", ". " * 31 + ".", ". " * 31 + "."],
    }
    fan = {k: [b.strip() for b in v] for k, v in fan.items()}
    # Court day: the motif augmented (double durations) on the keys alone (TRI before v2.0) at 88 BPM in G, legato and
    # solemn (long notes re-struck in quarters: a held TRI tone over 1 s would be a steady tone).
    # Not the v1 staccato tiptoe: a tiptoed anthem contour would read as mocking it.
    court = {"bass": [" ".join(seq(".:9 G3:3", 12)),
                      " ".join(seq("A3:3 A3:3 Bb3:3 C4:3", 12)),
                      " ".join(seq("C4:3 C4:3 D4:3 D4:3", 12))]}
    # The motif alone on the flute (P1 before v2.0): the first sound of the game (the unlock tap). Pickup, one bar, held 5.
    # (v1.2 fix: the file starts ON the pickup, not a bar early: no silent lead-in on the first tap)
    motif = {"lead": ["D5 -", " ".join(seq("E5:4 F5:2 G5:6 A5:4", 16))]}
    # Photobomb trophy: the shutter, then a BLIP "ta-da" (5 b7 1'). Never the anthem on Dubi's chip
    # voice: that is the kazoo the guardrail forbids.
    trophy = {"blip": [". . A5 - C6 - D6 - - - . ."], "kit": ["Z . . . . . . . . . . ."]}
    # Dubi's news flash: 5-1-5 on BLIP, staccato (neutral: no anthem contour on the parrot).
    flash = {"blip": [" ".join(seq("A5:1 .:1 D6:1 .:1 A6:1 .:11", 16))]}
    # Milestone (order of magnitude): the rise begins, 1-2-b3, on the bells (P2 brass before v2.0).
    head = {"p2": [" ".join(seq("D5:2 E5:4 F5:2 .:8", 16))]}
    fix = lambda d: {k: [" ".join(b.split()) for b in v] for k, v in d.items()}
    return {
        "_doc": "Tempo-bound one-shots, written in D minor (Balfour) and transposed per key: +2 E (Knesset), +5 G "
                "(Courthouse), +3 F (Washington: F minor, the cadence's minor turn), rendered at that era's tempo. "
                "'tags' (fanfare) cuts the render after bars 1-2 plus k half-bar tags; each cut ends on 5 over V, "
                "unresolved, and the new loop's bar-1 downbeat (i) is the resolution.",
        "fanfare": {"stepsPerBeat": 8, "rate": 22050, "bus": "Music", "keys": ["D", "E", "G", "F"], "tags": [0, 1, 2, 3, 4],
                    "tagSteps": 16, "baseSteps": 64,
                    "markerSteps": {"pickup": 28, "rollEnd": 32},
                    "_markers": "rollEnd = the motif downbeat + crash (the visual IMPACT); pickup = the C#-D lift; "
                                "tagOnsets = each tag's start; fanfareEnd = musicalSamples (the new loop's bar 1).",
                    "channels": {"lead": {"instrument": "flute", "gain": 0.4, "bars": fan["lead"]},
                                 "p2": {"instrument": "keys", "gain": 0.3, "bars": fan["p2"]},
                                 "bass": {"instrument": "808", "gain": 0.5, "bars": fan["bass"]},
                                 "kit": {"kit": "trapFanfare", "gain": 0.5, "bars": fan["kit"]}}},
        "courtIn": {"stepsPerBeat": 3, "rate": 22050, "bus": "SFX-Critical", "keys": ["G"], "writtenIn": "G",
                    "_v2": "v2.0: the augmented motif on the soft keys (was TRI), the slapback kept.",
                    "channels": {"bass": {"instrument": "keys", "gain": 0.6, "bars": fix(court)["bass"]}},
                    "slapback": {"ms": 180, "db": -12},
                    "_note": "The keys play the rise G3-D4 in one octave."},
        "motif": {"stepsPerBeat": 4, "rate": 22050, "bus": "SFX-Critical", "keys": ["D", "E", "G", "F"],
                  "channels": {"lead": {"instrument": "flute", "gain": 0.4, "bars": fix(motif)["lead"]}}},
        "trophy": {"stepsPerBeat": 4, "rate": 22050, "bus": "UI", "keys": ["D", "E", "G", "F"],
                   "channels": {"blip": {"instrument": "blip", "gain": 0.34, "bars": fix(trophy)["blip"]},
                                "kit": {"kit": "shutter", "gain": 0.5, "bars": fix(trophy)["kit"]}}},
        "dubiFlash": {"stepsPerBeat": 4, "rate": 22050, "bus": "Voice", "keys": ["D", "E", "G", "F"],
                      "channels": {"blip": {"instrument": "blip", "gain": 0.36, "bars": flash["blip"]}}},
        "milestone": {"stepsPerBeat": 4, "rate": 22050, "bus": "SFX-Critical", "keys": ["D", "E", "G", "F"],
                      "channels": {"p2": {"instrument": "bell", "gain": 0.34, "bars": head["p2"]}}},
    }


def music():
    eras = {"balfour": balfour(), "knesset": knesset(), "courthouse": courthouse(), "washington": washington()}
    for eid, e in eras.items():
        e["tapLine"] = tap_line(eid, e)
    return {
        "version": "od-1",
        "_doc": "עוד סבב: the era themes, the Outside drum line and the tempo-bound stingers. Owner: Audio "
                "Director. Written by audio/tools/compose_od.py (edit the score there, then run it); rendered "
                "by tools/gen_od_sevev.gd into game/assets/audio/od/. Bar strings: one token per step; '.' "
                "rest, '-' hold, NOTE (D5, F#4, Eb5), NOTE~UPPER (a 40 ms upper mordent), NOTE<FROM (a 50 ms "
                "scoop, 1 semitone at most), NOTE@inst (an instrument override), kit channels one character "
                "per simultaneous hit. Sections shorter than sectionBars cycle.",
        "a4Hz": 440,
        "form": {"order": ["A", "A2", "B", "T"], "sectionBars": 8, "totalBars": 32,
                 "_doc": "A(1-8) A'(9-16) B(17-24) T(25-32). Bar 32 is the motif; its pickup is bar 31 beat "
                         "4&. The motif's held b2 resolves into the loop's own bar 1 (the seam is a cadence)."},
        "layers": {
            "L0": {"voices": "TRI bass + darbuka (NOI-L tek, NOI-S riq, TRI dum)", "default": True,
                   "rule": "always on while music plays"},
            "L1": {"voices": "P2 (hora/maqsum/stride stabs; the complete B melody)", "default": False,
                   "rule": "on once the first money source is bought (sources_owned >= 1); stays on"},
            "L2": {"voices": "P1 lead", "default": False,
                   "rule": "on while the last tap was < 3000 ms ago; off otherwise. Forced off during court day "
                           "and during the ultimatum's last 3 s"},
            "fade": {"quantize": "bar", "fadeBars": 1,
                     "_doc": "Every layer change starts at the next bar line and ramps linearly over one bar."},
        },
        "antiFatigue": {
            "_doc": "0-byte variety (sonic brief v1.1, O-A1): a loop counter (1-based, counting completed passes of "
                    "bar 32 -> bar 1) picks a mute plan, applied at bar lines with the normal 1-bar fade.",
            "cycle": [
                {"loop": 1, "mute": []},
                {"loop": 2, "mute": [{"layer": "L2", "bars": [17, 24]}]},
                {"loop": 3, "mute": []},
                {"loop": 4, "mute": [{"layer": "L1", "bars": [9, 16]}, {"layer": "L2", "bars": [9, 16]}]},
            ],
        },
        "courtDay": {
            "_doc": "Sonic brief v1.1 (O-A2). At the next bar line: equal-power crossfade (400 ms) onto the same "
                    "bar of the courthouse track, L2 forced off, and the courtIn stinger starts on that bar line. "
                    "Taps, pings and Dubi use the G files while court day lasts. On exit: the same crossfade back "
                    "to the era's track at the next bar line, courtOut on that bar line. In the courthouse era "
                    "itself: only the L2 mute and the stinger.",
            "track": "courthouse", "xfadeMs": 400, "forceOff": ["L2"],
        },
        "outside": {
            "_doc": "Balfour only. A 2-bar loop on its own sub-bus 'Outside' (-> Music): AudioEffectLowPassFilter "
                    "800 Hz, AudioEffectPanner -0.3, mono. Starts with Balfour's music, locked to its bar grid. "
                    "Level: the manifest's out play_db (-14 LU under L0 after the 800 Hz filter), rising by up to "
                    "+6 dB with era progress (0..1). Pink Front (Saturday night, device clock): the cutoff sweeps "
                    "800 -> 4000 Hz over 2 bars (exponential) and +8 dB; tap-to-beat judges against beats 1 and 3 "
                    "of each bar (the manifest lists the downbeat sample positions).",
            "era": "balfour", "lpfHz": 800, "pan": -0.3, "underL0Db": -14, "riseDb": 6,
            "pinkFront": {"lpfHz": 4000, "sweepBars": 2, "boostDb": 8},
        },
        "targets": {
            "_doc": "Loudness targets (K-weighted BS.1770, dual mono) that set each item's play_db. music = all "
                    "three layers of an era together (every era lands on the same value, so era changes do not jump). "
                    "Stingers: integrated = over the whole stinger; momentary = the loudest 400 ms.",
            # v2.1 (Bar: "mix and master it together with the SFX"): measured in the game (tools/mix_session.gd),
            # music alone -18.0 and SFX alone -18.6 LUFS: the dense trap bed sat level with the taps. 1.2 LU back,
            # so the HaTikva bell and the coins sit on top (game-mix guidance: effects at or above the music)
            "music": -20.5,
            "fanfare": {"type": "integrated", "lufs": -17.0},
            "courtIn": {"type": "momentary", "lufs": -16.0},
            "motif": {"type": "momentary", "lufs": -15.0},
            "trophy": {"type": "momentary", "lufs": -18.0},
            "dubiFlash": {"type": "burst", "lufs": -15.0},
            "milestone": {"type": "burst", "lufs": -15.0},
        },
        "instruments": INSTRUMENTS,
        "kits": KITS,
        "eras": eras,
        "stingers": stingers(),
    }


# ============================================================ cues

KEYS = {
    "_doc": "The four playing keys. Taps, pings, Dubi and every keyed cue render once per key; the runtime "
            "plays the key of the track that is playing (G during court day).",
    "D": {"root": "D", "mode": "minor", "era": "balfour", "tempoBpm": 116},
    "E": {"root": "E", "mode": "minor", "era": "knesset", "tempoBpm": 132},
    "G": {"root": "G", "mode": "minor", "era": "courthouse", "tempoBpm": 88},
    "F": {"root": "F", "mode": "mixolydian", "era": "washington", "tempoBpm": 144},
}
MODES = {"minor": [0, 2, 3, 5, 7, 8, 10], "mixolydian": [0, 2, 4, 5, 7, 9, 10],
         "_doc": "minor = HaTikva's natural minor (the tap walk and Dubi's bank); the music raises the 7th at cadences. "
                 "Washington (F) stays Mixolydian so its taps agree with its stride body."}


# HaTikva for the tap (v1.11, Bar 2026-10-03: "it should play HaTikva when you tap the character, every
# tap a note"). The whole anthem, one entry per tap, in semitones above the key's root. Source: the
# Hatikvah score on English Wikipedia ("Hatikvah", the <score> LilyPond block, \relative d' in D minor;
# CC BY-SA 4.0, melody Samuel Cohen 1888, public domain), the same score anthem-scores 0.1.1 converted
# for section A (IL.json). Cross-checked by parsing both LilyPond blocks: the Hebrew Wikipedia score
# ("התקווה", \relative c' in A minor) has the same intervals for the first 77 notes; from "ארץ ציון" it
# sets "וירושלים" (one note fewer than "ויְרושלים") and starts the repeat of the last two lines lower. The
# English score repeats them as written (volta), which is what is followed here. Replaces v1.6's section B, which was written from memory and was wrong
# ("עוד לא אבדה" leaps to the octave: 1 8 8 8, not 5 5 5 5).
TAP_BELL_ROOTS = [60, 66, 72, 78, 84, 90]   # v1.10: C4 F#4 C5 F#5 C6 F#6
TAP_ANTHEM = {
    "semis": [0, 2, 3, 5, 7, 7, 8, 7, 8, 12, 7,           # כל עוד בלבב פנימה
              5, 5, 5, 3, 3, 2, 0, 2, 3, 0, -5,           # נפש יהודי הומיה
              0, 2, 3, 5, 7, 7, 8, 7, 8, 12, 7,           # ולפאתי מזרח קדימה
              5, 5, 5, 3, 3, 2, 0, 2, 3, 0,               # עין לציון צופיה
              0, 12, 12, 12, 10, 12, 10, 8, 7,            # עוד לא אבדה תקוותנו
              0, 12, 12, 12, 10, 12, 10, 8, 7,            # התקווה בת שנות אלפיים
              10, 10, 10, 3, 3, 5, 7, 8, 10, 7, 5, 3,     # להיות עם חופשי בארצנו
              5, 5, 3, 3, 3, 2, 0, 2, 3, 0,               # ארץ ציון וירושלים
              10, 10, 10, 3, 3, 5, 7, 8, 10, 7, 5, 3,     # להיות עם חופשי בארצנו
              5, 5, 3, 3, 3, 2, 0, 2, 3, 0],              # ארץ ציון וירושלים
    "phrases": [0, 11, 22, 33, 43, 52, 61, 73, 83, 95],    # the ten lines (2 bars each)
}


def noise_burst(delay, hp, gain, dur=0.018, metal=True, bp=None):
    f = {"type": "bandpass", "freq": bp, "Q": 1.2} if bp else {"type": "highpass", "freq": hp, "Q": 0.7}
    return L(wave="noiseMetal" if metal else "noise", clockStart=44000 if metal else 30000, filter=f,
             delay=round(delay, 4), attack=0.0008, decay=dur, sustain=0.0, duration=dur, release=0.004, gain=round(gain, 3))


def zipper(rate_hz, length=0.3, hp0=2600, hp1=6500, rising=True, gain=(0.5, 0.9)):
    """NOI-S gated at rate_hz: one short high-passed burst per gate period, the HP rising (spawn) or the
    amplitude swelling (the reversed zipper of the catch)."""
    n = int(length * rate_hz)
    out = []
    for i in range(n):
        t = i / rate_hz
        a = i / max(1, n - 1)
        hp = hp0 * (hp1 / hp0) ** a
        g = gain[0] + (gain[1] - gain[0]) * (a if rising else a)
        out.append(noise_burst(t, round(hp), g, dur=0.014))
    return out


def tone(note, delay, dur, wave="pulse", duty=0.125, gain=1.0, decay=None, sustain=0.5, release=0.02, **k):
    d = L(wave=wave, freqStart=note, delay=round(delay, 4), attack=0.001, decay=decay if decay else dur,
          sustain=sustain, duration=dur, release=release, gain=gain)
    if wave == "pulse":
        d["duty"] = duty
    d.update(k)
    return d


def swish(f0, f1, gain, dur, attack, decay, release, Q=1.2, clock=16000, id="swish"):
    """Air: band-passed noise sweeping f0 -> f1 (the spawn whoosh, a panel, a paper slide or flick)."""
    return L(id=id, wave="noise", clockStart=clock, filter={"type": "bandpass", "freq": f0, "freqEnd": f1, "Q": Q},
             attack=attack, decay=decay, sustain=0.0, duration=dur, release=release, gain=gain)


def body(delay, dur, gain, decay, sustain=0.2, release=0.02):
    """Weight under a reward: a crushed TRI root an octave down (A3 = degree 1, one octave under the cue)."""
    return tone("A3", delay, dur, wave="triangle", crush=4, gain=gain, decay=decay, sustain=sustain, release=release)


def glint(delay, note, gain, hp=7000, dur=0.06, decay=0.05, sustain=0.1, release=0.03, noise_at=None, noise_gain=None, noise_dur=0.02):
    """A coin's glint: a high noise tick and a quiet P2 50 % sparkle on a chord note."""
    return [noise_burst(delay if noise_at is None else noise_at, hp, gain if noise_gain is None else noise_gain, dur=noise_dur),
            tone(note, delay, dur, duty=0.5, gain=gain, decay=decay, sustain=sustain, release=release)]


def arp(start, step, dur, gain, decay, sustain, release, notes=("A4", "C5", "E5")):
    """The rising 1-b3-5 on P1 (the 'yes' under a bulk buy and a finished wizard step)."""
    return [tone(n, start + i * step, dur, duty=0.25, gain=gain, decay=decay, sustain=sustain, release=release)
            for i, n in enumerate(notes)]


def ui_cue(meaning, octave, variants, runtime, lufs, priority=1, poly=1, ducks=(), first=False, pitch=None):
    """A cue on the UI bus (quiet, short, oldest stolen)."""
    c = {"meaning": meaning, "bus": "UI", "priority": priority, "poly": poly, "steal": "oldest", "ducks": list(ducks),
         "pitch": pitch or {"type": "key", "rootOctave": octave}, "variants": variants}
    if first:
        c["firstSound"] = True
    c.update({"runtime": runtime, "target": {"type": "burst", "lufs": lufs}})
    return c


def cues():
    C = {}
    # 1. tap: a mallet, a thud and a marimba tone on the next note of HaTikva (v2.1, below; the 15 ms NOI-S
    #    cloth puff before it is kept for the other cues that use it);
    #    `blip` is the pre-v1.5 tap voice, kept for the other cues
    puff = L(id="puff", wave="noiseMetal", clockStart=40000, filter={"type": "bandpass", "freq": 5000, "Q": 0.9},
             attack=0.001, decay=0.015, sustain=0.0, duration=0.015, release=0.004, gain=0.35)
    blip = lambda duty: L(id="blip", wave="pulse", duty=duty, freqStart="A4", delay=0.012, attack=0.001, decay=0.03,
                          sustain=0.45, duration=0.04, release=0.012, gain=1.0,
                          filter={"type": "highpass", "freq": 1000, "Q": -3.0103})
    # Every tap is the next note of HaTikva on a bell, played straight (v1.5; v1.11: the whole anthem from
    # a verified score, each era's tapLine in music.json). The bell is rendered at six roots a tritone apart
    # (C4 .. F#6, v1.10) and the runtime plays each note from the nearest root with pitch_scale (3
    # semitones at most, so the bell's decay moves by under 19%).
    # v2.1 (Bar: "improve the tapping sound effect"): the tap leaves the chip. A soft mallet transient
    # (noise at 2 kHz, 6 ms: soft and brief, a tick that can fire thousands of times without grating,
    # in place of the 5 kHz metal puff), a deep gentle thud for the finger's weight (a sine falling
    # 120 -> 70 Hz), and a marimba / kalimba tone: the fundamental with a pluck's 25-cent fall into
    # pitch, a double 6 cents up (the beating that makes it rich), the octave, a fast 4th partial (the
    # mallet) and a low-passed triangle for warmth. 0.42 s, not 0.55: at 5 taps/s over the 808 it stays clear.
    def bell(root):
        hz = 440.0 * 2 ** ((root - 69) / 12)
        fall = 2 ** (25 / 1200)
        tone = lambda i, mult, g, dec, det=1.0: L(id="tone%d" % i, wave="sine", freqStart=hz * mult * det * fall,
                                                   freqEnd=hz * mult * det, freqCurve="exp", glide=0.025, attack=0.0015,
                                                   decay=dec, sustain=0.0, duration=dec, release=0.04, gain=g)
        return [
            L(id="mallet", wave="noise", clockStart=30000, filter={"type": "bandpass", "freq": 2000, "Q": 1.2},
              attack=0.0005, decay=0.006, sustain=0.0, duration=0.006, release=0.003, gain=0.22),
            L(id="thud", wave="sine", freqStart=120, freqEnd=70, freqCurve="exp", glide=0.04, followPitch=False,
              attack=0.001, decay=0.06, sustain=0.0, duration=0.06, release=0.01, gain=0.3),
            tone(0, 1, 1.0, 0.42), tone(1, 1, 0.32, 0.36, 2 ** (6 / 1200)), tone(2, 2, 0.2, 0.18),
            tone(3, 4, 0.1, 0.035),
            L(id="warm", wave="triangle", freqStart=hz, filter={"type": "lowpass", "freq": 1800, "Q": -3.0103},
              attack=0.002, decay=0.25, sustain=0.0, duration=0.25, release=0.04, gain=0.18)]
    C["tap"] = {"meaning": "The trick worked; money came out, to the next note of the song the era is playing.", "bus": "SFX-Frequent",
                "priority": 2, "poly": 6, "steal": "oldest", "ducks": [], "jitterDb": 1.5,
                "pitch": {"type": "none"},
                "melody": ["n%d" % x for x in TAP_ANTHEM["semis"]], "phrases": TAP_ANTHEM["phrases"],
                "variants": {"r%d" % r: bell(r) for r in TAP_BELL_ROOTS},
                "runtime": "v2.2 (Bar: \"the tapping notes should change according to the song that is playing\"; ADR "
                           "0012): each tap plays the next note of the playing era's tapLine (music.json): the song the "
                           "loop plays (HaTikva, Hava Nagila, Hevenu, ...), from the bell root (variant r<midi>) nearest "
                           "the note, at pitch_scale 2^(semitones/12). The taps follow the music: after a pause the next "
                           "tap joins the note the music is on, and at each phrase's end a tap that has fallen behind (or "
                           "run more than a phrase ahead) jumps to the phrase the music plays. Without music the line runs "
                           "on by itself. `melody` (the whole of HaTikva, semitones above the key's root in octave 5) is "
                           "the fallback for a manifest without tap lines. A stolen voice fades over 30 ms. Gain jitter +-1.5 dB.",
                "lengthMs": 460, "target": {"type": "stream", "rateHz": 5, "lufs": -21.0}}
    # 2. rabbit crit
    def rabbit(slide):
        head_t = 0.12 + slide + 0.01
        return [
            L(id="boing", wave="triangle", crush=4, freqStart=440, freqEnd=220, freqCurve="exp", glide=0.2, followPitch=False,
              attack=0.001, decay=0.2, sustain=0.3, duration=0.2, release=0.03, gain=0.9, vibrato={"rateHz": 12, "depthCents": 40, "delay": 0.0}),
            L(id="slide", wave="pulse", duty=0.25, freqStart="E4", freqEnd="A4", freqCurve="exp", glide=slide,
              delay=0.12, attack=0.001, decay=slide, sustain=0.6, duration=slide, release=0.01, gain=0.7),
            tone("E5", head_t, 0.06, duty=0.25, gain=0.8, decay=0.05, sustain=0.5),
            tone("A5", head_t + 0.075, 0.06, duty=0.25, gain=0.8, decay=0.05, sustain=0.5),
            tone("E6", head_t + 0.15, 0.08, duty=0.25, gain=0.75, decay=0.07, sustain=0.4, release=0.04),
            tone("E4", head_t, 0.06, duty=0.125, gain=0.5, decay=0.05, sustain=0.5),
            tone("A4", head_t + 0.075, 0.06, duty=0.125, gain=0.5, decay=0.05, sustain=0.5),
            tone("E5", head_t + 0.15, 0.08, duty=0.125, gain=0.45, decay=0.07, sustain=0.4, release=0.04),
        ]
    C["rabbitCrit"] = {"meaning": "The trick went spectacularly right (rare).", "bus": "SFX-Critical", "priority": 5,
                       "poly": 1, "steal": "never", "ducks": [{"bus": "Music", "db": -4, "attackMs": 50, "releaseMs": 200}],
                       "pitch": {"type": "key", "rootOctave": 4},
                       "variants": {"s120": rabbit(0.12), "s150": rabbit(0.15), "s180": rabbit(0.18)},
                       "markers": {"s120": {"slide": 0.12, "head": 0.25}, "s150": {"slide": 0.12, "head": 0.28}, "s180": {"slide": 0.12, "head": 0.31}},
                       "runtime": "Round-robin s120 -> s150 -> s180. The head's 16ths are a fixed 75 ms in every era so "
                                  "the whole cue stays <= 600 ms (brief §5 cue 2).",
                       "target": {"type": "burst", "lufs": -12.0}}
    # 3. suitcase
    spawn_air = swish(700, 2400, 0.45, 0.18, 0.12, 0.08, 0.03, id="whoosh")
    C["suitcaseSpawn"] = {"meaning": "A catchable opportunity is on screen.", "bus": "SFX-Critical", "priority": 4, "poly": 1,
                          "steal": "never", "ducks": [{"bus": "Music", "db": -4, "attackMs": 50, "releaseMs": 200}],
                          "pan": "the suitcase's x mapped to -0.4..+0.4 on the 'Suitcase' bus panner, set at spawn",
                          "pitch": {"type": "none"},
                          "variants": {"g25": [spawn_air] + [dict(b, delay=round(b["delay"] + 0.15, 4)) for b in zipper(25)],
                                       "g28": [spawn_air] + [dict(b, delay=round(b["delay"] + 0.15, 4)) for b in zipper(28)],
                                       "g31": [spawn_air] + [dict(b, delay=round(b["delay"] + 0.15, 4)) for b in zipper(31)]},
                          "runtime": "Random variant (gate rate 25/28/31 Hz). The whoosh is UX's spawn twin (first-minute §3).",
                          "target": {"type": "burst", "lufs": -14.0}}
    catch = [dict(b, delay=round(b["delay"], 4)) for b in zipper(33, length=0.12, hp0=6500, hp1=2800, gain=(0.2, 0.85))]
    catch += [tone("E5", 0.13, 0.07, duty=0.5, gain=0.7, decay=0.06, sustain=0.4),
              tone("A5", 0.2, 0.16, duty=0.5, gain=0.75, decay=0.1, sustain=0.45, release=0.06),
              noise_burst(0.2, 5000, 0.5, dur=0.01)]
    # v1.6 (2026-10-03, Bar: "rewards not satisfying"): weight under the cha-ching (a crushed TRI root an
    # octave down on each hit) and a sparkle tail after it (5' and 1'' on P2 50 %, a high glint), so the
    # catch lands and then rings out. The ending stays 1' (the motif head's resolution is returnAway's).
    catch += [body(0.13, 0.08, 0.55, 0.07), body(0.2, 0.12, 0.6, 0.1, sustain=0.25, release=0.04),
              tone("E6", 0.3, 0.07, duty=0.5, gain=0.3, decay=0.06, sustain=0.2, release=0.03)]
    catch += glint(0.36, "A6", 0.26, hp=7500, dur=0.12, decay=0.1, sustain=0.15, release=0.06, noise_gain=0.25)
    C["suitcaseCatch"] = {"meaning": "Got it.", "bus": "SFX-Critical", "priority": 4, "poly": 1, "steal": "oldest",
                          "ducks": [{"bus": "Music", "db": -4, "attackMs": 50, "releaseMs": 200}],
                          "pitch": {"type": "key", "rootOctave": 5}, "variants": {"": catch},
                          "markers": {"_": {"zipperEnd": 0.12, "chaChing": 0.13, "chaChing2": 0.2}},
                          "runtime": "Also the first half of the 'while you were away' return (returnAway).",
                          "target": {"type": "burst", "lufs": -13.0}}
    C["suitcaseMiss"] = {"meaning": "It reached its destination. Nobody knew. (deadpan)", "bus": "SFX-Frequent",
                         "priority": 1, "poly": 1, "steal": "oldest", "ducks": [],
                         "pitch": {"type": "key", "rootOctave": 3},
                         "variants": {"": [L(id="bwomp", wave="triangle", crush=4, freqStart="A4", freqEnd="Ab4", freqCurve="exp",
                                             glide=0.12, attack=0.004, decay=0.16, sustain=0.2, duration=0.18, release=0.05, gain=1.0)]},
                         "runtime": "One quiet TRI bwomp down a semitone, under the ticker line. Nothing else.",
                         "target": {"type": "burst", "lufs": -21.0}}
    # 4. coalition chat ping: two P2 12.5% notes of 60 ms; the interval is the partner's act
    def ping(a, b, gb=1.0, gap=0.075):
        return [tone(a, 0.0, 0.06, gain=1.0, decay=0.05, sustain=0.5), tone(b, gap, 0.06, gain=gb, decay=0.05, sustain=0.5, release=0.03)]
    # root = degree 1 in octave 5; A4 below is degree 1, Bb4 the b2, E5 the 5, etc.
    shapes = {
        "default": (ping("F5", "E5"), "b6 -> 5, the minor sigh"),
        "benGvir": (ping("A4", "A4") + [tone("A4", 0.15, 0.06, gain=0.8, decay=0.05, sustain=0.5)], "1 1 1: he threatens more than once"),
        "smotrich": (ping("A4", "D5"), "1 -> 4: raises (VAT)"),
        "deri": (ping("A4", "E4"), "1 -> 5 below: settled, not going anywhere"),
        "goldknopf": (ping("D5", "E5"), "4 -> 5: a little more, every time"),
        "gafni": ([tone("A4", 0.0, 0.06, gain=1.0, decay=0.05, sustain=0.5), tone("A4", 0.075, 0.03, gain=0.18, decay=0.03, sustain=0.0)], "1, then the second note left the room"),
        "levin": (ping("C5", "B4"), "b3 -> 2: petitioning, left hanging"),
        "regev": (ping("E5", "A5"), "5 -> 1': the ribbon-cut ta-da"),
        "gotliv": (ping("C5", "G#4"), "b3 -> the raised 7 below: a diminished fourth, between rows"),
        "left": ([tone("A4", 0.0, 0.06, gain=1.0, decay=0.05, sustain=0.5), tone("Bb4", 0.075, 0.09, gain=1.0, decay=0.08, sustain=0.4, release=0.03),
                  L(id="door", wave="noise", clockStart=26000, filter={"type": "bandpass", "freq": 2200, "Q": 2.0}, delay=0.19,
                    attack=0.0005, decay=0.01, sustain=0.0, duration=0.01, release=0.003, gain=0.6)], "1 -> b2 up, unresolved, and a door click"),
        "burst": (ping("F5", "E5") + [tone("F5", 0.15, 0.06, gain=0.9, decay=0.05, sustain=0.5)], "a burst coalesced: b6 5 b6 (x3)"),
        # v1.3 (2026-09-29): the brawl (two partners at each other, two rows frozen). Two pings talk
        # over each other: 1+b2, then b6+5, then 1+b2 again, each voice at half gain so the pair
        # peaks no higher than one ping (the family's scale and play_db stay as they were).
        "brawl": ([dict(t, gain=0.5) for t in ping("A4", "F5") + ping("Bb4", "E5")]
                  + [tone("A4", 0.15, 0.06, gain=0.45, decay=0.05, sustain=0.5), tone("Bb4", 0.15, 0.06, gain=0.45, decay=0.05, sustain=0.5, release=0.03)],
                  "1+b2 / b6+5 / 1+b2: two pings talking over each other"),
    }
    C["chatPing"] = {"meaning": "A partner posted a demand.", "bus": "UI", "priority": 3, "poly": 1, "steal": "oldest", "ducks": [],
                     "pitch": {"type": "key", "rootOctave": 5},
                     "variants": {k: v[0] for k, v in shapes.items()},
                     "shapes": {k: v[1] for k, v in shapes.items()},
                     "runtime": "Variant = the partner id (unknown partners: default). At most one ping per 700 ms; pings "
                                "inside that window coalesce into one 'burst'. Never during a Dubi squawk: queue it until "
                                "300 ms after Dubi stops (UX first-minute §9). 'left' = left the group.",
                     "target": {"type": "burst", "lufs": -16.0}}
    # 5. ultimatum
    tick = lambda f: [L(id="t", wave="noiseMetal", clockStart=46000, filter={"type": "bandpass", "freq": f, "Q": 3.0}, attack=0.0005,
                        decay=0.008, sustain=0.0, duration=0.008, release=0.003, gain=1.0)]
    C["ultimatumTick"] = {"meaning": "Pay before zero or they walk.", "bus": "SFX-Critical", "priority": 3, "poly": 1, "steal": "oldest",
                          "ducks": [], "pitch": {"type": "none"}, "variants": {"tick": tick(4800), "tock": tick(3300)},
                          "runtime": "One per displayed second, alternating tick/tock. In the last 3 s: two per second, and "
                                     "force L2 off (tension by subtraction). No duck (a tick every 500 ms would pump the music).",
                          "target": {"type": "relative", "to": "tap", "db": -6.0}}
    zero = [L(id="deflate", wave="triangle", crush=4, freqStart="C5", freqEnd="A4", freqCurve="exp", glide=0.18, attack=0.003,
              decay=0.2, sustain=0.2, duration=0.2, release=0.05, gain=1.0)]
    zero += [dict(t, delay=round(t.get("delay", 0) + 0.32, 4)) for t in [tone("A5", 0.0, 0.06, gain=0.8, decay=0.05, sustain=0.5),
                                                                          tone("Bb5", 0.075, 0.09, gain=0.8, decay=0.08, sustain=0.4, release=0.03)]]
    zero.append(L(id="door", wave="noise", clockStart=26000, filter={"type": "bandpass", "freq": 2200, "Q": 2.0}, delay=0.51,
                  attack=0.0005, decay=0.01, sustain=0.0, duration=0.01, release=0.003, gain=0.5))
    C["ultimatumZero"] = {"meaning": "Time ran out: they left the group.", "bus": "SFX-Critical", "priority": 4, "poly": 1, "steal": "oldest",
                          "ducks": [{"bus": "Music", "db": -4, "attackMs": 50, "releaseMs": 200}],
                          "pitch": {"type": "key", "rootOctave": 4}, "variants": {"": zero},
                          "markers": {"_": {"deflate": 0.0, "leftPing": 0.32, "door": 0.51}},
                          "runtime": "A TRI deflate a minor third down (b3 -> 1), then the 'left the group' ping. No alarm beep, ever.",
                          "target": {"type": "burst", "lufs": -14.0}}
    # 6. gavel
    def knock(t, g=1.0, f0=110.0, f1=45.0):
        # the recipe's TRI thud (110 -> 45 Hz over 80 ms) for headphones; a crushed TRI 'wood' body at
        # ~300 Hz (inside the 80-400 Hz slot) and the NOI-L crack carry it on a phone speaker
        return [L(wave="triangle", crush=4, freqStart=f0, freqEnd=f1, freqCurve="exp", glide=0.08, followPitch=False, delay=t,
                  attack=0.001, decay=0.1, sustain=0.0, duration=0.1, release=0.01, gain=0.22 * g),
                L(wave="triangle", crush=3, freqStart=f0 * 3.6, freqEnd=f0 * 3.0, freqCurve="exp", glide=0.04, followPitch=False, delay=t,
                  attack=0.0008, decay=0.06, sustain=0.0, duration=0.06, release=0.01, gain=0.75 * g),
                L(wave="noise", clockStart=34000, filter={"type": "bandpass", "freq": 2000, "Q": 0.9}, delay=t + 0.002,
                  attack=0.0005, decay=0.03, sustain=0.0, duration=0.03, release=0.006, gain=1.0 * g)]
    C["gavel"] = {"meaning": "Court day starts.", "bus": "SFX-Critical", "priority": 5, "poly": 1, "steal": "never",
                  "ducks": [{"bus": "Music", "db": -4, "attackMs": 50, "releaseMs": 200}], "pitch": {"type": "none"},
                  "variants": {"a": knock(0.0) + knock(0.18), "b": knock(0.0, 0.97) + knock(0.18, 1.0), "c": knock(0.0, 1.0) + knock(0.18, 0.95)},
                  "markers": {"_": {"knock1": 0.0, "knock2": 0.18}},
                  "runtime": "Then the music moves to the courthouse track at the next bar line, where courtIn starts.",
                  "target": {"type": "burst", "lufs": -12.0}}
    C["gavelWeak"] = {"meaning": "Postponement granted.", "bus": "SFX-Frequent", "priority": 2, "poly": 1, "steal": "oldest",
                      "ducks": [], "pitch": {"type": "none"}, "variants": {"": knock(0.0, 0.5, 220.0, 90.0)},
                      "runtime": "One weak knock, an octave up. The 'tik'.",
                      "target": {"type": "relative", "to": "gavel", "db": -6.0}}
    C["courtOut"] = {"meaning": "Court day is over; back to the era.", "bus": "SFX-Frequent", "priority": 2, "poly": 1,
                     "steal": "oldest", "ducks": [], "pitch": {"type": "key", "rootOctave": 4},
                     "variants": {"": [tone("E5", 0.0, 0.05, wave="triangle", crush=4, gain=1.0, decay=0.05, sustain=0.4),
                                       tone("A5", 0.14, 0.07, wave="triangle", crush=4, gain=1.0, decay=0.06, sustain=0.4, release=0.04)]},
                     "runtime": "Two TRI tiptoe notes, 5 -> 1' in the era key being returned to, on the crossfade bar line.",
                     "target": {"type": "burst", "lufs": -18.0}}
    # 7. rubber stamp: deliberately identical
    stamp = [L(id="thump", wave="noise", clockStart=30000, filter={"type": "highpass", "freq": 2500, "Q": 0.7}, attack=0.0005,
               decay=0.03, sustain=0.0, duration=0.03, release=0.006, gain=0.7),
             L(id="hit", wave="triangle", crush=4, freqStart=90, followPitch=False, attack=0.001, decay=0.06, sustain=0.0,
               duration=0.06, release=0.01, gain=0.5),
             L(id="ink", wave="pulse", duty=0.25, freqStart=660, freqEnd=588, freqCurve="exp", glide=0.06, followPitch=False,
               delay=0.035, attack=0.002, decay=0.06, sustain=0.2, duration=0.07, release=0.02, gain=0.55)]
    bell = [L(id="bell", wave="pulse", duty=0.5, freqStart=2000, followPitch=False, delay=0.12, attack=0.001, decay=0.2,
              sustain=0.0, duration=0.2, release=0.03, gain=0.4),
            L(id="bell2", wave="sine", freqStart=4000, followPitch=False, delay=0.12, attack=0.001, decay=0.12, sustain=0.0,
              duration=0.12, release=0.02, gain=0.2)]
    C["stamp"] = {"meaning": "Request bounced. Again. (נדרשים מסמכים נוספים)", "bus": "SFX-Frequent", "priority": 2, "poly": 2,
                  "steal": "oldest", "ducks": [], "pitch": {"type": "none"},
                  "variants": {"": stamp, "bell": stamp + bell},
                  "runtime": "Deliberately identical (+-0.5 dB at most). Every 5th stamp plays the 'bell' variant.",
                  "target": {"type": "burst", "lufs": -15.0}}
    # 8. transfer-window whistle: pea whistle, 2.8 kHz, 28 Hz warble +-30 cents, short-short-long
    def whistle(rate):
        v = {"rateHz": rate, "depthCents": 30, "delay": 0.0}
        return [L(wave="pulse", duty=0.5, freqStart=2800, followPitch=False, delay=d, attack=0.004, decay=0.02, sustain=0.85,
                  duration=l, release=0.02, gain=1.0, vibrato=v) for d, l in [(0.0, 0.12), (0.16, 0.12), (0.32, 0.4)]]
    C["transferWhistle"] = {"meaning": "A partner switched jerseys (the transfer window).", "bus": "SFX-Critical", "priority": 4,
                            "poly": 1, "steal": "never", "ducks": [{"bus": "Music", "db": -4, "attackMs": 50, "releaseMs": 200}],
                            "pitch": {"type": "none"}, "variants": {"w26": whistle(26), "w28": whistle(28), "w30": whistle(30)},
                            "markers": {"_": {"w1": 0.0, "w2": 0.16, "w3": 0.32}},
                            "runtime": "Random variant. Pitch-stable, no glide, 740 ms in total: siren-safe (brief §2).",
                            "target": {"type": "burst", "lufs": -15.0}}
    # 9. camera shutter
    def shutter(semi):
        return [noise_burst(0.0, 3000, 0.9, dur=0.012), noise_burst(0.07, 3000, 0.8, dur=0.012),
                L(id="pip", wave="pulse", duty=0.25, freqStart=round(4000 * 2 ** (semi / 12), 2), followPitch=False, delay=0.075,
                  attack=0.001, decay=0.03, sustain=0.0, duration=0.03, release=0.008, gain=0.4)]
    C["shutter"] = {"meaning": "You caught the people who live in our cameras (photobomb).", "bus": "UI", "priority": 3, "poly": 1,
                    "steal": "oldest", "ducks": [], "pitch": {"type": "none"},
                    "variants": {"m1": shutter(-1), "p0": shutter(0), "p1": shutter(1)},
                    "runtime": "Random variant (the pip +-1 semitone). The 'שלום בית בפריים' trophy plays the trophy "
                               "stinger instead (shutter + the full motif on BLIP).",
                    "target": {"type": "burst", "lufs": -16.0}}
    # 10. Dubi
    rasp = L(id="rasp", wave="noiseMetal", clockStart=24000, filter={"type": "bandpass", "freq": 2600, "Q": 1.5}, attack=0.004,
             decay=0.06, sustain=0.0, duration=0.06, release=0.01, gain=0.35)
    C["dubiSquawk"] = {"meaning": "Dubi is about to speak.", "bus": "Voice", "priority": 4, "poly": 1, "steal": "oldest",
                       "ducks": [{"bus": "Music", "db": -6, "attackMs": 30, "releaseMs": 250}],
                       "pitch": {"type": "key", "rootOctave": 5},
                       "variants": {"up": [L(id="chirp", wave="pulse", duty=0.125, freqStart="E5", freqEnd="B5", freqCurve="exp", glide=0.08,
                                             attack=0.002, decay=0.08, sustain=0.3, duration=0.085, release=0.02, gain=1.0), rasp],
                                    "down": [L(id="chirp", wave="pulse", duty=0.125, freqStart="B5", freqEnd="E5", freqCurve="exp", glide=0.08,
                                               attack=0.002, decay=0.08, sustain=0.3, duration=0.085, release=0.02, gain=1.0), rasp]},
                       "runtime": "Before a spoken line: 'up' before a headline, 'down' before a flash. +-7 semitones over 80 ms.",
                       "target": {"type": "burst", "lufs": -15.0}}
    C["dubiBlip"] = {"meaning": "One syllable of Dubi's babble.", "bus": "Voice", "priority": 4, "poly": 1, "steal": "oldest",
                     "ducks": [{"bus": "Music", "db": -6, "attackMs": 30, "releaseMs": 250}],
                     "pitch": {"type": "degrees", "degrees": ["1", "3", "4", "5", "b7"], "octaves": [5, 6]},
                     "variants": {"": [L(id="blip", wave="pulse", duty=0.125, freqStart="A4", attack=0.001, decay=0.045, sustain=0.35,
                                         duration=0.055, release=0.012, gain=1.0)]},
                     "runtime": "Replaces the F-pentatonic babble bank (ADR 0003). One blip per displayed syllable (about 1 "
                                "per 2 Hebrew letters) at 8 per second; degrees drawn from the bank (seeded by the text), "
                                "a final '!' steps up to the next higher degree. Capped at 1.6 s. The ticker babbles on at "
                                "most one headline per 20 s. Canned lines use babbleContours instead.",
                     "target": {"type": "shortTerm", "rateHz": 8, "lufs": -18.0}}
    C["returnAway"] = {"meaning": "While you were away (the return).", "bus": "SFX-Critical", "priority": 3, "poly": 1, "steal": "oldest",
                       "ducks": [{"bus": "Music", "db": -4, "attackMs": 50, "releaseMs": 200}], "pitch": {"type": "key", "rootOctave": 5},
                       "variants": {"": catch + [tone("E5", 0.52, 0.08, duty=0.5, gain=0.7, decay=0.06, sustain=0.4),
                                                 tone("A5", 0.6, 0.18, duty=0.5, gain=0.75, decay=0.12, sustain=0.45, release=0.06)]},
                       "firstSound": True,
                       "runtime": "The catch's cha-ching, then the motif head (5-1). v1.3: a first sound like leaderPick "
                                  "(the return card comes before any tap after a reload, so the first-tap gate used to "
                                  "swallow it).", "target": {"type": "burst", "lufs": -14.0}}
    # the families: buy, can't afford, UI click, coin
    # v1.6: a purchase gets a body (a crushed TRI root an octave down under the blip: the coin hits the
    # counter) and a glint on the 1' (a high noise tick and a quiet 5'' sparkle), so it reads as money
    # changing hands rather than a menu blip.
    buy_body = body(0.0, 0.07, 0.5, 0.06)
    buy_glint = glint(0.08, "E6", 0.28, dur=0.07, decay=0.06, noise_at=0.07, noise_dur=0.025)
    C["buy"] = {"meaning": "Bought a source or a spin.", "bus": "SFX-Frequent", "priority": 3, "poly": 2, "steal": "oldest", "ducks": [],
                "pitch": {"type": "key", "rootOctave": 4},
                "variants": {v: [puff, buy_body, dict(blip(d), freqStart="E5"), tone("A5", 0.07, 0.1, duty=d, gain=0.9, decay=0.08, sustain=0.4, release=0.04)] + buy_glint
                             for v, d in (("d25", 0.25), ("d12", 0.125))},
                "runtime": "The tap blip on 5 over a low body, then the motif's first bar note (1') on P1 with a glint. "
                           "Alternate d25 / d12. A bulk buy (x10, max) plays buyBig instead.",
                "target": {"type": "burst", "lufs": -16.0}}
    # v1.6: a bulk buy (x10 / max) is a bigger purchase, so it sounds bigger: the buy's opening, then a
    # rising 1-b3-5-1' arpeggio in 16ths on P1 over the body, and a short coin shower (three glints on
    # the chord's notes). Still under the purchase's deadpan rule: no fanfare, no anthem.
    big = [puff, body(0.0, 0.1, 0.6, 0.09)] + arp(0.0, 0.045, 0.05, 0.85, 0.045, 0.4, 0.02)
    big += [tone("A5", 0.135, 0.14, duty=0.25, gain=0.95, decay=0.1, sustain=0.45, release=0.05),
            body(0.135, 0.12, 0.55, 0.1, sustain=0.25, release=0.04)]
    for j, (n, t) in enumerate([("E6", 0.19), ("A6", 0.235), ("C6", 0.28)]):
        big += glint(t, n, 0.26, hp=7000 + 400 * j, noise_gain=0.24)
    C["buyBig"] = {"meaning": "A bulk purchase (x10 or max).", "bus": "SFX-Frequent", "priority": 3, "poly": 1, "steal": "oldest",
                   "ducks": [], "pitch": {"type": "key", "rootOctave": 4}, "variants": {"": big},
                   "runtime": "Instead of buy on a bulk purchase (main.gd sends buyBulk when the quantity is over one).",
                   "target": {"type": "burst", "lufs": -14.5}}
    # Bar 2026-10-01: Gantz on the picker. The sad trombone: three falling staccato pulses and a held
    # fourth that sags a semitone with a wide vibrato. Wrong pick, said with a shrug.
    C["fail"] = {"meaning": "A wrong pick (Gantz on the leader picker): the sad trombone.", "bus": "SFX-Critical",
                 "priority": 2, "poly": 1, "steal": "oldest", "ducks": [],
                 "pitch": {"type": "key", "rootOctave": 3},
                 "variants": {"": [tone("D4", 0.0, 0.2, duty=0.25, gain=0.9, decay=0.16, sustain=0.6, release=0.04),
                                   tone("C#4", 0.26, 0.2, duty=0.25, gain=0.9, decay=0.16, sustain=0.6, release=0.04),
                                   tone("C4", 0.52, 0.2, duty=0.25, gain=0.9, decay=0.16, sustain=0.6, release=0.04),
                                   L(id="sag", wave="pulse", duty=0.25, freqStart="B3", freqEnd="Bb3", freqCurve="exp", glide=0.2,
                                     delay=0.78, attack=0.004, decay=0.3, sustain=0.7, duration=0.7, release=0.12, gain=1.0,
                                     vibrato={"rateHz": 6.0, "depthCents": 45, "delay": 0.2})]},
                 "runtime": "On a Gantz tap in the picker, with the modal.", "target": {"type": "burst", "lufs": -17.0}}
    C["cantAfford"] = {"meaning": "Not enough money.", "bus": "UI", "priority": 1, "poly": 1, "steal": "oldest", "ducks": [],
                       "pitch": {"type": "key", "rootOctave": 4},
                       "variants": {"": [tone("G#4", 0.0, 0.045, gain=1.0, decay=0.04, sustain=0.3), tone("G#4", 0.075, 0.045, gain=0.8, decay=0.04, sustain=0.3)]},
                       "runtime": "Two quiet P2 staccatos on the raised leading tone, left hanging.", "target": {"type": "burst", "lufs": -21.0}}
    # v1.6 (Bar: "UI sounds thin and the same"): the press gets a finger (a 6 ms band-passed noise
    # click) and a faint sine octave over the blip; opening, closing and toggling get their own cues
    # (uiOpen, uiClose, uiToggle below), so a menu reads by ear.
    click = noise_burst(0.0, 0, 0.45, dur=0.006, metal=False, bp=3600)
    C["uiClick"] = ui_cue("A UI press.", 6, {"": [click, tone("A4", 0.0, 0.025, duty=0.5, gain=1.0, decay=0.025, sustain=0.0, release=0.008),
                                                   tone("A5", 0.003, 0.035, wave="sine", gain=0.22, decay=0.035, sustain=0.0, release=0.01)]},
                          "One P2 blip on degree 1 in octave 6 (1.2-1.6 kHz) with a click and a sine octave.", -21.0, poly=2)
    # a panel opens: a short rising air swish and 5 -> 1' up on P1; it closes: the mirror, softer
    panel = lambda f0, f1, g: swish(f0, f1, g, 0.07, 0.02, 0.05, 0.015, Q=1.1, clock=18000)
    C["uiOpen"] = ui_cue("A panel, sheet or menu opens.", 5,
                         {"": [click, panel(900, 3000, 0.4), tone("E5", 0.0, 0.035, duty=0.25, gain=0.8, decay=0.03, sustain=0.3),
                               tone("A5", 0.045, 0.05, duty=0.25, gain=0.9, decay=0.045, sustain=0.3, release=0.03)]},
                         "panelOpen, evolveOpen.", -20.5)
    C["uiClose"] = ui_cue("A panel, sheet or menu closes.", 5,
                          {"": [click, panel(3000, 900, 0.32), tone("A5", 0.0, 0.035, duty=0.25, gain=0.75, decay=0.03, sustain=0.3),
                                tone("E5", 0.045, 0.045, duty=0.25, gain=0.75, decay=0.04, sustain=0.25, release=0.025)]},
                          "panelClose, evolveClose.", -22.0)
    # a switch: a click and a two-step blip, up (on) then down (off) on alternate presses. The UI's quiet
    # ticks (this, the booth's slips, the wizard's skip) are unpitched: one file each, written at the
    # boot key's pitches (D: 1 = D6 here), so they don't cost four keys of payload.
    step2 = lambda a, b, g: [click, tone(a, 0.0, 0.025, duty=0.5, gain=0.8, decay=0.02, sustain=0.0, release=0.006),
                             tone(b, 0.03, 0.03, duty=0.5, gain=g, decay=0.025, sustain=0.0, release=0.008)]
    C["uiToggle"] = ui_cue("A switch or a mode cycles (settings toggles, the buy-mode chip).", 6,
                           {"on": step2("G5", "D6", 0.9), "off": step2("D6", "G5", 0.8)},
                           "uiToggle, buyModeCycle. Alternates on / off.", -21.5, pitch={"type": "none"})
    C["coin"] = {"meaning": "Coins (the settings 'צ'ינג' preview; payout sparkle, at most 6 per tap).", "bus": "SFX-Frequent",
                 "priority": 1, "poly": 3, "steal": "oldest", "ducks": [], "pitch": {"type": "key", "rootOctave": 5},
                 # v2.2 (Bar: "the coin sounds should be more in the background"): sines, not the 50% pulse,
                 # a softer shimmer, and 7 LU back (-19 -> -26): a sparkle behind the tap's melody
                 "variants": {"a": [noise_burst(0.0, 8000, 0.18, dur=0.03, metal=False), tone("E6", 0.0, 0.05, wave="sine", gain=0.5, decay=0.05, sustain=0.2),
                                    tone("A6", 0.045, 0.08, wave="sine", gain=0.45, decay=0.08, sustain=0.1, release=0.04)],
                              "b": [noise_burst(0.0, 8500, 0.18, dur=0.03, metal=False), tone("C6", 0.0, 0.05, wave="sine", gain=0.5, decay=0.05, sustain=0.2),
                                    tone("E6", 0.045, 0.08, wave="sine", gain=0.45, decay=0.08, sustain=0.1, release=0.04)]},
                 "runtime": "The deadpan rule: the payout never scales loudness or count (<= 6 coins per tap, whatever the sum).",
                 "target": {"type": "burst", "lufs": -26.0}}
    # v1.10: the player's taps played a whole phrase of the song: a quiet sparkle up the open fifth
    # (5, 8, 5'; no third, so it agrees with every era's mode), 80 ms after the phrase's last note
    C["phraseDone"] = {"meaning": "The taps played a whole phrase of the era's song (the phrase bonus).", "bus": "SFX-Frequent",
                       "priority": 2, "poly": 1, "steal": "oldest", "ducks": [], "pitch": {"type": "key", "rootOctave": 5},
                       "variants": {"": glint(0.08, "E5", 0.4, dur=0.05, decay=0.05, sustain=0.2)
                                    + glint(0.14, "A5", 0.45, dur=0.06, decay=0.06, sustain=0.15, noise_gain=0.15)
                                    + glint(0.2, "E6", 0.5, dur=0.12, decay=0.1, sustain=0.1, release=0.06, noise_gain=0.12)},
                       "runtime": "audio.gd: on the last note of a phrase the taps played whole, at most once in 1.5 phrases.",
                       "target": {"type": "burst", "lufs": -21.0}}

    # ---------------------------------------------------------------- v1.3 (2026-09-29): leader select
    # and the views added in session 2 (cue-spec §4.1, §5.8). Every new cue is its own family (own
    # scale, own play_db), so no shipped file changes; brawl above is the one new variant of an old
    # family, kept under that family's peak and burst.

    # leaderPick: the new first sound (the pick commits on touchend, which is the iOS unlock).
    # The fanfare's own material, cut to its gesture of arrival: the darbuka roll (roll2-roll4,
    # 32nds at 116 BPM = 64.7 ms), the C#-D leading-tone lift with P2 brass a sixth below, and the
    # downbeat on 1 over i with the crash. It RESOLVES (a pick is a decision); it never states the
    # rise, which stays the motif's on the first tap (§6). Written in D, A4 = the key's root at
    # octave 4 (D5 -> A5, C#5 -> G#5, F4 -> C5, E4 -> B4, D3 -> A3).
    st = 60.0 / 116 / 8
    roll = lambda t, g: L(id="roll", wave="noise", clockStart=30000, filter={"type": "highpass", "freq": 1300, "Q": 0.7},
                          delay=round(t, 4), attack=0.0005, decay=0.03, sustain=0.0, duration=0.03, release=0.008, gain=g)
    down = 6 * st
    pick = [roll(i * st, g) for i, g in enumerate([0.34, 0.34, 0.58, 0.58, 0.9, 0.9])]
    pick += [tone("G#5", 4 * st, 2 * st * 0.9, duty=0.25, gain=0.34 / 0.36, decay=0.09, sustain=0.62, release=0.035),
             tone("B4", 4 * st, 2 * st * 0.82, duty=0.5, gain=0.26 / 0.36 * 0.8, decay=0.1, sustain=0.5, release=0.04),
             tone("A5", down, 0.22, duty=0.25, gain=0.34 / 0.36, decay=0.09, sustain=0.62, release=0.06),
             tone("C5", down, 0.2, duty=0.5, gain=0.26 / 0.36 * 0.8, decay=0.1, sustain=0.5, release=0.06),
             tone("A3", down, 0.2, wave="triangle", crush=4, gain=0.46 / 0.36, decay=0.12, sustain=0.5, release=0.05),
             L(id="wash", wave="noise", clockStart=42000, filter={"type": "highpass", "freq": 2200, "Q": 0.7}, delay=round(down, 4),
               attack=0.001, decay=0.42, sustain=0.0, duration=0.42, release=0.03, gain=0.55 * 0.45 / 0.36),
             L(id="bell", wave="noiseMetal", clockStart=38000, filter={"type": "bandpass", "freq": 5200, "Q": 2.0}, delay=round(down, 4),
               attack=0.001, decay=0.25, sustain=0.0, duration=0.25, release=0.03, gain=0.25 * 0.45 / 0.36)]
    # v1.6 (2026-10-03, the ballot booth, ADR 0008): the pick is a vote, so the slip is heard going in. A
    # paper slide over the roll (a band-passed swish rising 1.4 -> 4 kHz), and the slip landing in the
    # box on the downbeat: a dull low thunk (TRI 150 -> 70 Hz and low-passed noise) and a short wooden
    # knock for the phone speaker, under the crash.
    pick += [swish(1400, 4000, 0.32, 0.18, 0.04, 0.12, 0.03, Q=1.3, clock=20000, id="slide"),
             L(id="box", wave="triangle", freqStart=150, freqEnd=70, freqCurve="exp", glide=0.08, followPitch=False, delay=round(down, 4),
               attack=0.001, decay=0.1, sustain=0.0, duration=0.1, release=0.015, gain=0.45),
             L(id="boxNoise", wave="noise", clockStart=14000, filter={"type": "lowpass", "freq": 520, "Q": 0.0}, delay=round(down, 4),
               attack=0.001, decay=0.05, sustain=0.0, duration=0.05, release=0.01, gain=0.55),
             L(id="wood", wave="triangle", crush=3, freqStart=330, freqEnd=260, freqCurve="exp", glide=0.03, followPitch=False,
               delay=round(down + 0.002, 4), attack=0.0008, decay=0.04, sustain=0.0, duration=0.04, release=0.01, gain=0.4)]
    C["leaderPick"] = {"meaning": "You picked this round's leader (the picker's commit).", "bus": "SFX-Critical", "priority": 5,
                       "poly": 1, "steal": "oldest", "ducks": [{"bus": "Music", "db": -4, "attackMs": 50, "releaseMs": 200}],
                       "pitch": {"type": "key", "rootOctave": 4}, "variants": {"": pick},
                       "markers": {"_": {"pickup": round(4 * st, 4), "downbeat": round(down, 4)}},
                       "firstSound": True,
                       "runtime": "On the picker's commit (and again on a re-pick inside the undo window). It is the "
                                  "game's first sound now: it plays before the first-tap gate, and while the web audio "
                                  "context is still locked it is held (up to 5 s) and plays on the unlock, like the "
                                  "motif. It does not open the first-tap gate: the first tap still plays the motif.",
                       "target": {"type": "burst", "lufs": -15.0}}

    # critReact: the crit of every leader but Bibi (Bibi keeps rabbitCrit), keyed by the react
    # strip's event (spec §9.5). Each variant is the event's transient, then rabbitCrit's head
    # (5-1'-5' on P1 over P2), which is the crit's signature: a crit always ends in the same ta-da.
    def crit_head(h):
        return [tone("E5", h, 0.06, duty=0.25, gain=0.8, decay=0.05, sustain=0.5),
                tone("A5", h + 0.075, 0.06, duty=0.25, gain=0.8, decay=0.05, sustain=0.5),
                tone("E6", h + 0.15, 0.08, duty=0.25, gain=0.75, decay=0.07, sustain=0.4, release=0.04),
                tone("E4", h, 0.06, duty=0.125, gain=0.5, decay=0.05, sustain=0.5),
                tone("A4", h + 0.075, 0.06, duty=0.125, gain=0.5, decay=0.05, sustain=0.5),
                tone("E5", h + 0.15, 0.08, duty=0.125, gain=0.45, decay=0.07, sustain=0.4, release=0.04)]

    def no_knocks(g=1.0):
        # "no. no.": two flat TRI staccatos on 1 below, the second a whole step lower (it closes)
        return [tone("A3", 0.0, 0.07, wave="triangle", crush=4, gain=1.0 * g, decay=0.06, sustain=0.2, release=0.02),
                noise_burst(0.0, 0, 0.35 * g, dur=0.012, metal=False, bp=900),
                tone("G3", 0.14, 0.09, wave="triangle", crush=4, gain=1.0 * g, decay=0.08, sustain=0.2, release=0.03),
                noise_burst(0.14, 0, 0.35 * g, dur=0.012, metal=False, bp=900)]

    whoosh = [swish(600, 3200, 0.55, 0.12, 0.06, 0.08, 0.02, id="whoosh")]
    shout = [tone("A4", 0.0, 0.09, duty=0.5, gain=0.7, decay=0.08, sustain=0.5, release=0.02),
             tone("E5", 0.0, 0.09, duty=0.5, gain=0.55, decay=0.08, sustain=0.5, release=0.02),
             noise_burst(0.0, 0, 0.5, dur=0.03, metal=False, bp=1500)]
    land = [L(id="thud", wave="triangle", crush=4, freqStart="A3", freqEnd="A2", freqCurve="exp", glide=0.07, attack=0.001,
              decay=0.09, sustain=0.0, duration=0.09, release=0.015, gain=1.0),
            noise_burst(0.002, 0, 0.45, dur=0.04, metal=False, bp=420)]
    C["critReact"] = {"meaning": "A crit (every leader but Bibi): the leader's react landed.", "bus": "SFX-Critical", "priority": 5,
                      "poly": 1, "steal": "never", "ducks": [{"bus": "Music", "db": -4, "attackMs": 50, "releaseMs": 200}],
                      "pitch": {"type": "key", "rootOctave": 4},
                      "variants": {"whoosh": whoosh + crit_head(0.12), "shout": shout + crit_head(0.11),
                                   "no": no_knocks() + crit_head(0.26), "land": land + crit_head(0.09)},
                      "markers": {"whoosh": {"head": 0.12}, "shout": {"head": 0.11}, "no": {"head": 0.26}, "land": {"head": 0.09}},
                      "runtime": "Variant = the react strip's event (crits table). Fires on that event's frame (sprites.json "
                                 "chars.<art>.anims.<critAnim>.events), a third of the delay in reduced motion, like rabbitCrit.",
                      "target": {"type": "burst", "lufs": -12.0}}

    # decline (Liberman's "לא אשב" pill): the same "no. no." without the crit's head. A refusal,
    # not a loss and not a shortfall (cantAfford hangs on the leading tone; this closes on b7).
    C["decline"] = {"meaning": "You declined a partner's demand (Liberman's rule).", "bus": "SFX-Frequent", "priority": 2, "poly": 1,
                    "steal": "oldest", "ducks": [], "pitch": {"type": "key", "rootOctave": 4}, "variants": {"": no_knocks()},
                    "runtime": "On the decline pill's commit. The partner's 'left' ping is the sim's business, not this cue.",
                    "target": {"type": "burst", "lufs": -16.0}}

    # merge (Golan's "לאחד" pill): two P2 voices a third apart glide into one note (b3 up to 4,
    # 5 down to 4), then the stapler (Golan's prop): two dry NOI clicks and the unison blip.
    merge = [L(id="a", wave="pulse", duty=0.125, freqStart="C5", freqEnd="D5", freqCurve="exp", glide=0.12, attack=0.002,
               decay=0.12, sustain=0.5, duration=0.12, release=0.01, gain=0.5),
             L(id="b", wave="pulse", duty=0.125, freqStart="E5", freqEnd="D5", freqCurve="exp", glide=0.12, attack=0.002,
               decay=0.12, sustain=0.5, duration=0.12, release=0.01, gain=0.5),
             noise_burst(0.13, 3000, 0.7, dur=0.008),
             noise_burst(0.16, 0, 0.8, dur=0.01, metal=False, bp=2400),
             tone("D5", 0.16, 0.08, duty=0.125, gain=0.9, decay=0.07, sustain=0.4, release=0.03)]
    C["merge"] = {"meaning": "Two members merged into one (Golan's rule).", "bus": "SFX-Frequent", "priority": 2, "poly": 1,
                  "steal": "oldest", "ducks": [], "pitch": {"type": "key", "rootOctave": 5}, "variants": {"": merge},
                  "runtime": "On the merge pill's commit (Coalition.merge).",
                  "target": {"type": "burst", "lufs": -16.0}}

    # suspicionHot: the thermometer crosses into 'hot' (>= 75 %, the icon turns into a gavel). A dry
    # TRI gulp (5 down to 4, 60 ms) and one sweat drip. Quiet, no duck: a warning, not an event.
    C["suspicionHot"] = {"meaning": "Suspicion is hot (the thermometer passed 75 %).", "bus": "SFX-Frequent", "priority": 2,
                         "poly": 1, "steal": "never", "ducks": [], "pitch": {"type": "key", "rootOctave": 4},
                         "variants": {"": [L(id="gulp", wave="triangle", crush=4, freqStart="E5", freqEnd="D5", freqCurve="exp", glide=0.06,
                                             attack=0.002, decay=0.08, sustain=0.2, duration=0.08, release=0.02, gain=1.0),
                                           L(id="drip", wave="pulse", duty=0.5, freqStart=2600, freqEnd=3400, freqCurve="exp", glide=0.02,
                                             followPitch=False, delay=0.13, attack=0.001, decay=0.025, sustain=0.0, duration=0.025,
                                             release=0.008, gain=0.35)]},
                         "runtime": "Once per upward crossing of 75 % (the view's calm -> hot change). Silent at 95 % "
                                    "(boiling): the visual boil and the coming gavel carry it.",
                         "target": {"type": "burst", "lufs": -20.0}}

    # slipStamp (v1.4, the Animator's wave B): the rubber stamp on the ballot slip (a spin card's tag slams
    # x6 -> x5 -> x4). A dry rubber-on-paper thunk: a paper slap (band-passed noise at 1.2 kHz), a dark noise
    # body (low-passed at 900 Hz: the pad on the desk), a short crushed TRI rubber knock (380 -> 260 Hz, the
    # phone-speaker body, too short to read as a note), a low TRI thud under it for headphones, and a faint
    # lift-off tick. It is NOT Herzog's stamp: no 2.5 kHz thump, no pitched 'ink' glide, no bell. That stamp's
    # sameness is its joke (cue-spec §5.6) and stays unspent. Unpitched, one file, like the stamp.
    slip = [L(id="slap", wave="noise", clockStart=30000, filter={"type": "bandpass", "freq": 1200, "Q": 0.8},
              attack=0.0005, decay=0.022, sustain=0.0, duration=0.022, release=0.004, gain=1.0),
            L(id="pad", wave="noise", clockStart=14000, filter={"type": "lowpass", "freq": 900, "Q": 0.0},
              delay=0.006, attack=0.002, decay=0.06, sustain=0.0, duration=0.06, release=0.012, gain=0.9),
            L(id="rubber", wave="triangle", crush=4, freqStart=380, freqEnd=260, freqCurve="exp", glide=0.03,
              followPitch=False, delay=0.009, attack=0.001, decay=0.035, sustain=0.0, duration=0.035, release=0.01,
              gain=0.8),
            L(id="thud", wave="triangle", freqStart=150, freqEnd=100, freqCurve="exp", glide=0.05, followPitch=False,
              delay=0.012, attack=0.001, decay=0.06, sustain=0.0, duration=0.06, release=0.01, gain=0.25),
            L(id="lift", wave="noiseMetal", clockStart=44000, filter={"type": "highpass", "freq": 3500, "Q": 0.7},
              delay=0.075, attack=0.0005, decay=0.006, sustain=0.0, duration=0.006, release=0.003, gain=0.2)]
    C["slipStamp"] = {"meaning": "The ballot slip is stamped (a spin card's tag appears or changes: '1/5' -> '2/5', 'שחוק').",
                      "bus": "UI", "priority": 1, "poly": 2, "steal": "oldest", "ducks": [], "pitch": {"type": "none"},
                      "variants": {"": slip},
                      "runtime": "On the slam's f0 (the x6 frame) in shop.gd; in reduced motion on the cut. It often lands "
                                 "with `buy` (the purchase that changed the tag): it sits 4.5 dB under it, centred at 0.7 kHz under its "
                                 "1-4 kHz blips. Repeats per purchase, so it sits 2 dB under the stamp's heard -18.5 (0.5 over uiClick).",
                      "target": {"type": "burst", "lufs": -20.5}}

    # ---------------------------------------------------------------- v1.6 (2026-10-03, Bar: "improve the SFX";
    # 8-bit but fuller: the UI less thin and alike, the rewards more satisfying, sound for the ballot booth and
    # the wizard). Each new cue is its own family. uiClick, buy, suitcaseCatch (and returnAway through it) and
    # leaderPick got fuller layers above; buyBig, uiOpen, uiClose and uiToggle are new there.

    # paid: a partner's demand is paid (one line or 'pay all'). It was Herzog's stamp, whose sameness is a
    # joke about bounced requests; a payment is the opposite, money going out and a deal closed. The slip's
    # rubber thunk, then a cash-register ka-ching: the drawer (a metal noise burst), 5 and 1' bells on P2
    # 50 % with a sine 1' ringing over them. Unpitched thunk, keyed bells.
    paid = [dict(b, delay=b.get("delay", 0.0)) for b in slip[:3]]
    paid += [noise_burst(0.06, 6000, 0.55, dur=0.03),
             tone("E5", 0.07, 0.1, duty=0.5, gain=0.6, decay=0.09, sustain=0.2, release=0.03),
             tone("A5", 0.13, 0.18, duty=0.5, gain=0.55, decay=0.15, sustain=0.2, release=0.08),
             tone("A5", 0.13, 0.24, wave="sine", gain=0.25, decay=0.22, sustain=0.0, release=0.06)]
    C["paid"] = {"meaning": "A partner's demand is paid (the chat's pay pill or 'pay all').", "bus": "SFX-Frequent", "priority": 3,
                 "poly": 1, "steal": "oldest", "ducks": [], "pitch": {"type": "key", "rootOctave": 5}, "variants": {"": paid},
                 "runtime": "partnerPaid (view_chat.gd: a pay, or one per 'pay all'). Herzog's desk keeps stamp.",
                 "target": {"type": "burst", "lufs": -16.0}}

    # slipChoose: a slip is lifted off the booth's tray (chosen, not voted): a paper flick (band-passed
    # noise rising 1.8 -> 3.6 kHz, 45 ms) and a tiny pick tick on 1 or 5, alternating, so browsing the
    # tray doesn't repeat one sound. slipLocked: a slip still at the printer: the flick muffled (low-passed)
    # and a dull TRI bwomp down a semitone, quiet. Neither is a reward: the vote is (leaderPick).
    flick = swish(1800, 3600, 0.8, 0.045, 0.004, 0.04, 0.01, Q=1.4, clock=22000, id="flick")
    tick = lambda n: tone(n, 0.012, 0.022, duty=0.125, gain=0.4, decay=0.02, sustain=0.0, release=0.006)
    C["slipChoose"] = ui_cue("A slip is chosen in the ballot booth (the big card shows it).", 6,
                             {"a": [flick, tick("D6")], "b": [flick, tick("A5")]}, "Alternates a / b.", -21.5, pitch={"type": "none"})
    C["slipLocked"] = ui_cue("A slip still in print is chosen (it can't be voted yet).", 4,
                             {"": [dict(flick, id="muffled", filter={"type": "lowpass", "freq": 700, "Q": 0.0}, attack=0.003, duration=0.04),
                                   L(id="bwomp", wave="triangle", crush=4, freqStart="D4", freqEnd="C#4", freqCurve="exp", glide=0.08,
                                     delay=0.01, attack=0.003, decay=0.09, sustain=0.2, duration=0.1, release=0.03, gain=0.6)]},
                             "Once per choice of a locked slip.", -23.0, pitch={"type": "none"})

    # The booth and the wizard come before the first tap on a first launch. Their sounds answer a gesture,
    # which opens the SFX gate (audio.gd gesture()), except wizardStep: a step shows on its own, so it is a
    # first sound (like leaderPick and returnAway) and plays before any gesture.
    # the wizard (ADR 0007): a step appears: a soft two-bell 'notice' (sine 5 -> 1', a glint), a gentle
    # duck under it; a step is done: a quick 1-b3-5-1' on P1 (a small 'yes'); 'דלג': an air swish falling
    # 3.2 -> 0.7 kHz over a TRI 5 -> 1 slide down. Quiet: the game's own sound for the action plays too.
    C["wizardStep"] = ui_cue("A wizard step appears (the dim, the hole, Dubi's bubble).", 5, {"": [tone("E5", 0.0, 0.16, wave="sine", gain=0.75, decay=0.15, sustain=0.0, release=0.04),
                                         tone("E6", 0.0, 0.06, wave="sine", gain=0.15, decay=0.06, sustain=0.0, release=0.02),
                                         tone("A5", 0.09, 0.22, wave="sine", gain=0.85, decay=0.2, sustain=0.0, release=0.06),
                                         tone("A6", 0.09, 0.08, wave="sine", gain=0.16, decay=0.08, sustain=0.0, release=0.03),
                                         noise_burst(0.09, 7000, 0.15, dur=0.02)]},
                             "When a step first shows (not again on a re-show).", -20.0, priority=2,
                             ducks=[{"bus": "Music", "db": -3, "attackMs": 40, "releaseMs": 300}], first=True)
    C["wizardDone"] = ui_cue("A wizard step the player saw is done.", 5,
                             {"": arp(0.0, 0.04, 0.045, 0.75, 0.04, 0.3, 0.015)
                                  + [tone("A5", 0.12, 0.1, duty=0.25, gain=0.85, decay=0.08, sustain=0.3, release=0.05),
                                     noise_burst(0.12, 7500, 0.2, dur=0.02)]},
                             "Plays 100 ms after the event (audio.gd WIZARD_DONE_DELAY_MS), so it follows the action's own cue.",
                             -21.0, priority=2)
    C["wizardSkip"] = ui_cue("The wizard is skipped ('דלג').", 4,
                             {"": [swish(3200, 700, 0.55, 0.12, 0.015, 0.1, 0.02, id="swoosh"),
                                   L(id="slide", wave="triangle", crush=4, freqStart="A4", freqEnd="D4", freqCurve="exp", glide=0.1,
                                     delay=0.01, attack=0.003, decay=0.1, sustain=0.2, duration=0.11, release=0.03, gain=0.45)]},
                             "On 'דלג' (or Esc).", -22.0, pitch={"type": "none"})
    return {
        "version": "od-1",
        "_doc": "עוד סבב SFX cues. Owner: Audio Director. Written by audio/tools/compose_od.py; rendered by "
                "tools/gen_od_sevev.gd to game/assets/audio/od/<cue>_<key>_<pitch>_<variant>.res (QOA one-shots). "
                "Layers use the lib_dsp layer schema; tonal layers with followPitch (the default) are authored with "
                "A4 = the cue's root, i.e. degree 1 of the key in rootOctave (A4 = 1, B4 = 2, C5 = b3, D5 = 4, "
                "E5 = 5, F5 = b6, G5 = b7, G#4 = the raised 7 below, A5 = 1'). The 'degrees' pitch type counts "
                "scale steps of the key's mode ('3' = the mode's third, minor in D/E/G, major in F Mixolydian). The generator computes each cue's play_db from its loudness "
                "target (K-weighted, BS.1770, measured as dual mono), capped by the bus ceiling; the manifest "
                "carries it. Target types: burst = the loudest 100 ms (transients shorter than the 400 ms "
                "momentary window), momentary = the loudest 400 ms, shortTerm = the loudest 3 s of a steady "
                "stream at rateHz, stream = integrated over 12 s at rateHz, relative = burst dB under another cue.",
        "rate": 32000,
        "keys": KEYS,
        "modes": MODES,
        "degrees": {"1": 0, "b2": 1, "2": 2, "3": 4, "4": 5, "5": 7, "b6": 8, "6": 9, "b7": 10},
        "buses": {
            "_doc": "mix-bus-topology (audio/od/cue-spec.md §3). Levels live in play_db; buses sit at 0 dB.",
            "Music": {"children": ["Outside"], "db": 0}, "Outside": {"parent": "Music", "effects": ["LowPass 800 Hz", "Panner -0.3"]},
            "SFX-Critical": {"db": 0}, "SFX-Frequent": {"db": 0}, "UI": {"db": 0}, "Voice": {"db": 0},
            "Suitcase": {"parent": "SFX-Critical", "effects": ["Panner (set at spawn)"]},
        },
        "ceilings": {
            "_doc": "Heard sample-peak ceiling per bus (dBFS at the bus, before the master): play_db is capped so a "
                    "file's peak lands at or under it, whatever its loudness target asks. Keeps SFX + music under "
                    "the -1 dB master limiter in normal play.",
            "SFX-Critical": -3.0, "SFX-Frequent": -5.0, "UI": -6.0, "Voice": -6.0, "Music": -3.0},
        "babbleContours": {
            "_doc": "Canned squawks (voice/copy-deck §H): the parrot repeats what he was told, so each line has a "
                    "fixed contour of [degree, octave] per blip; a doubled line repeats its contour after a 150 ms gap.",
            "אין כלום!": [["5", 6], ["5", 6], ["1", 6]],
            "אין כובע!": [["5", 6], ["5", 6], ["3", 6]],
            "ציד מכשפות!": [["5", 5], ["5", 5], ["b7", 5], ["1", 6]],
            "כספים קואליציוניים!": [["5", 5], ["4", 5], ["3", 5], ["5", 5], ["4", 5], ["3", 5], ["b7", 5], ["1", 6]],
            "לקנות!": [["3", 6], ["5", 6]],
            "בחירות!": [["1", 6], ["3", 6], ["5", 6]],
            "לא ידענו!": [["5", 6], ["4", 6], ["3", 6], ["1", 6]],
            "מי?": [["5", 5], ["1", 6]],
            "בכובע!": [["1", 6], ["b7", 5], ["1", 6]],
            # v1.3: every leader's squawks (content leaders[].kit.dubi.squawks; Bibi's are above).
            # Never the anthem on BLIP: the bank has no 2 or b6, and no line leaps 5 -> 5'.
            "ביחד!": [["5", 5], ["1", 6], ["3", 6]],
            "לחתום!": [["5", 6], ["1", 6]],
            "נגיב מחר!": [["5", 6], ["4", 6], ["3", 6], ["1", 6]],
            "אני פורש!": [["3", 5], ["5", 5], ["b7", 5], ["1", 6]],
            "תקציב!": [["1", 6], ["5", 6]],
            "לא איום!": [["5", 6], ["3", 6], ["1", 6]],
            "לא אשב!": [["1", 6], ["1", 6], ["5", 5]],
            "מס!": [["1", 6]],
            "לא!": [["5", 5]],
            "ישר!": [["5", 5], ["5", 5]],
            "ישר לקופה!": [["5", 5], ["5", 5], ["5", 5], ["5", 5], ["1", 6]],
            "עקום!": [["5", 6], ["3", 5]],
            "אין כסף!": [["5", 6], ["5", 6], ["b7", 5]],
            "העברה!": [["1", 6], ["3", 6], ["4", 6], ["5", 6]],
            "גירעון!": [["5", 6], ["4", 6], ["b7", 5]],
            "לא לך!": [["1", 6], ["5", 5], ["1", 6]],
            "מסדרון!": [["3", 6], ["1", 6], ["3", 6]],
            "קפה!": [["4", 6], ["3", 6]],
            "נסגור!": [["5", 5], ["3", 6], ["1", 6]],
            "לא שר?": [["3", 6], ["5", 6]],
            "איחוד!": [["1", 6], ["3", 6]],
            "עוד אחד!": [["5", 5], ["1", 6], ["3", 6]],
            "פיצול!": [["3", 6], ["b7", 5]],
        },
        "crits": {
            "_doc": "v1.3 (leader-select spec §9.5): the crit cue of a react event. A leader's event is "
                    "kit.tap.critEvent; Bibi (critAnim 'crit', the rabbit prop) is 'rabbit'. rabbitCrit keeps its "
                    "round-robin; the others play critReact's variant of the same name. An unknown event plays "
                    "'land'. The tap itself stays the shared tap cue for everyone.",
            "rabbit": {"cue": "rabbitCrit", "variant": "roundRobin"},
            "whoosh": {"cue": "critReact", "variant": "whoosh"},
            "shout": {"cue": "critReact", "variant": "shout"},
            "no": {"cue": "critReact", "variant": "no"},
            "land": {"cue": "critReact", "variant": "land"},
        },
        "cues": C,
    }


# ============================================================ checks

RANGES = {"lead": ("D4", "A6"), "p2": ("A3", "E6"), "bass": ("F1", "E3"), "blip": ("C5", "B6"),
          "keys": ("F3", "D5"), "bells": ("C5", "C7")}   # v2.0: the 808 (bass) F1-E3, the keys and bells
CHECK_ERRORS = []


def err(msg):
    CHECK_ERRORS.append(msg)


# Incipits for the quote check, as interval runs (semitones). Only tunes whose opening I can state
# with confidence are listed; the check is interval-only (stricter than the brief's same-rhythm rule).
QUOTES = {
    "Misirlou (E F G# A B C B)": [1, 3, 1, 2, 1, -1],
    "Merrily We Roll Along / Mary Had a Little Lamb (3 2 1 2 3 3 3)": [-2, -2, 2, 2, 0, 0],
    "Yankee Doodle (1 1 2 3 1 3 2)": [0, 2, 2, -4, 4, -2],
    "Entry of the Gladiators (chromatic run)": [-1, -1, -1, -1, -1],
    "chromatic run up": [1, 1, 1, 1, 1],
    "Hail to the Chief (5 6 1' 1' 2' 3')": [2, 3, 0, 2, 2],
    "Hava Nagila (verse: 3 2 1 3 3 3)": [-2, -2, 4, 0, 0],
    "Stars and Stripes Forever (march theme 5 5 4 3 4)": [0, -1, -2, 1],
}


# HaTikva's opening two bars as intervals: 1 2 b3 4 5 5 | b6 5 b6 1' 5 (public domain, Cohen 1888).
# The client direction allows allusion; the guardrail caps verbatim contour at about 2 bars in any
# one place, i.e. at most these 10 intervals in a row (the check is interval-only, rhythm ignored).
ANTHEM = [2, 1, 2, 2, 0, 1, -1, 1, 4, -5]
ANTHEM_MAX = 10
ANTHEM_RUNS = {}
# v1.8 (Bar 2026-10-03: "HaTikva and more traditional songs"; "the full first phrase, respectfully"):
# the anthem's whole first section (bars 1-4 of the verified score, 21 intervals) may sound in full,
# in one declared place only: ANTHEM_HOME (era/channel/section). There it is held to the respect
# rules: the legato lead voice (gate >= 0.85, a "note"-length envelope), no ornaments (~ mordent,
# < scoop), no instrument overrides (no stab, no click). Everywhere else the 2-bar cap stands,
# measured against the full phrase.
ANTHEM_PHRASE = ANTHEM + [-2, 0, 0, -2, 0, -1, -2, 2, 1, -3, -5]
ANTHEM_HOME = {("balfour", "lead", "A")}

# v1.9 (Bar 2026-10-03: "HaTikva and more traditional songs"): the traditional tunes the eras play on
# purpose, as their sources give them (pitch names in the source key, the sounding order; rests and
# rhythm live in the scores). All public domain: traditional melodies, none with a living composer.
# TUNE_HOMES says where each is played and how it is transposed; check_tunes holds every home's
# notes to its source, note for note, and the quote check (QUOTES) skips a tune only in its home.
TUNES = {
    "havaNagila": {"src": "flutetunes.com hava-nagila.mid (= John Chambers, trillian.mit.edu ~jc/music/abc/Klezmer/HavaNagila.abc, D phrygian); "
                          "trad. Sadigura niggun (1840s), A. Z. Idelsohn (d. 1938)",
                   "notes": "D5 D5 F#5 Eb5 D5 F#5 F#5 A5 G5 F#5 G5 G5 Bb5 A5 G5 F#5 Eb5 D5 "
                            "F#5 F#5 Eb5 D5 D5 D5 Eb5 Eb5 D5 C5 C5 C5 C5 Eb5 D5 C5 G5 F#5 Eb5 D5"},
    "hevenu": {"src": "John Chambers, trillian.mit.edu ~jc/music/abc/Klezmer/HeveynuShalomAleychem.abc (X:2, Dm, with the words); "
                      "trad. Hasidic melody",
               "notes": "A4 F4 E4 E4 D4 D4 F4 A4 D5 Bb4 A4 A4 G4 G4 A4 Bb4 A4 E4 A4 G4 G4 F4 E4 F4 G4 A4 A4 A4 A4 "
                        "A4 G4 F4 G4 A4 A3 D4 F4"},
    "shalomChaverim": {"src": "Musica Viva (musicaviva.com/israel/shalom-shaverim.abc, via abcnotation.com), anon., Em",
                       "notes": "E4 E4 F#4 G4 E4 G4 G4 A4 B4 B4 E5 D5 B4 B4 E5 B4 A4 G4 A4 B4 G4 F#4 E4 B3 E4 F#4 G4 G4 B3"},
    "maozTzur": {"src": "flutetunes.com maoz-tzur.mid (Trad. German), the melody track, D major", 
                 "notes": "D5 A4 D5 G5 F#5 E5 D5 A5 B5 E5 F#5 G5 F#5 E5 D5 D5 A4 D5 G5 F#5 E5 D5 A5 B5 E5 F#5 G5 F#5 E5 D5"},
    "dayenuVerse": {"src": "flutetunes.com dayenu.mid (Trad. Jewish), G major, the verse",
                    "notes": "B4 D5 D5 D5 D5 E5 D5 C5 B4 D5 D5 D5 D5 E5 D5 C5 B4 D5 A4 C5 B4 D5 A4 C5 B4 A4 G4"},
    "dayenuChorus": {"src": "flutetunes.com dayenu.mid (Trad. Jewish), G major, the chorus",
                     "notes": "B4 B4 D5 C5 A4 C5 C5 E5 D5 B4 D5 D5 G5 F#5 F#5 F#5 D5 E5 F#5 G5 D5 B4 G4 "
                              "B4 B4 D5 C5 A4 C5 C5 E5 D5 B4 D5 D5 G5 F#5 F#5 F#5 D5 E5 F#5 G5"},
    "simanTov": {"src": "John Chambers (trillian.mit.edu ~jc/music/abc/Klezmer/SimanTov_Gm.abc; allklez 0577-0579), the freilach, Gm",
                 "notes": "G4 G4 G4 D4 G4 G4 G4 D4 G4 G4 G4 D4 G4 G4 G4 Bb4 Bb4 Bb4 G4 Bb4 Bb4 Bb4 G4 Bb4 Bb4 Bb4 G4 Bb4 Bb4 Bb4 "
                          "C5 C5 C5 Bb4 C5 C5 C5 Bb4 C5 C5 C5 D5 Bb4 A4 G4 G4 C5 C5 Bb4 A4 G4"},
}
MAJ_TO_MIN = {0: 0, 2: 2, 4: 3, 5: 5, 7: 7, 9: 8, 11: 11}   # the leading tone kept (Ma'oz Tzur's cadences)
# (era, channel, section) -> [(tune, transform)], played in order; a transform maps a source MIDI note
TUNE_HOMES = {
    ("balfour", "lead", "B"): [("havaNagila", lambda m: m)],
    ("knesset", "lead", "A"): [("hevenu", lambda m: m + 14)],
    ("knesset", "lead", "B"): [("shalomChaverim", lambda m: m + 12)],
    ("courthouse", "lead", "B"): [("maozTzur", lambda m: m - 7 + MAJ_TO_MIN[(m - midi("D4")) % 12] - (m - midi("D4")) % 12)],
    ("washington", "lead", "A"): [("dayenuVerse", lambda m: m - 2), ("dayenuVerse", lambda m: m + 10)],
    ("washington", "lead", "A2"): [("dayenuChorus", lambda m: m - 2)],
    ("washington", "lead", "B"): [("simanTov", lambda m: m + 7)],
}
TUNE_QUOTES = {"havaNagila": "Hava Nagila (verse: 3 2 1 3 3 3)"}   # the QUOTES entry a tune's home may play


def check_tunes(m):
    for (eid, cid, sec), parts in TUNE_HOMES.items():
        want = [f(midi(n)) for t, f in parts for n in TUNES[t]["notes"].split()]
        got = [n for n, _ in line_notes(m["eras"][eid]["channels"][cid]["sections"][sec])]
        if got != want:
            k = next((i for i, (a, b) in enumerate(zip(got, want)) if a != b), min(len(got), len(want)))
            err("%s/%s/%s: not the source of %s at note %d (%s vs %s; %d vs %d notes)" % (
                eid, cid, sec, "+".join(t for t, _ in parts), k, nm(got[k]) if k < len(got) else "-",
                nm(want[k]) if k < len(want) else "-", len(got), len(want)))


def longest_phrase_run(iv):
    best = 0
    for i in range(len(iv)):
        for j in range(len(ANTHEM_PHRASE)):
            k = 0
            while i + k < len(iv) and j + k < len(ANTHEM_PHRASE) and iv[i + k] == ANTHEM_PHRASE[j + k]:
                k += 1
            best = max(best, k)
    return best


def longest_anthem_run(iv):
    best = 0
    for i in range(len(iv)):
        for j in range(len(ANTHEM)):
            k = 0
            while i + k < len(iv) and j + k < len(ANTHEM) and iv[i + k] == ANTHEM[j + k]:
                k += 1
            best = max(best, k)
    return best


def line_events(bars):
    """Monophonic notes (onset step, midi, steps) from bar strings (first note of a chord, no ornaments)."""
    out = []
    toks = " ".join(bars).split()
    for i, t in enumerate(toks):
        if t in (".", "-") or not re.match(r"[A-G]", t):
            continue
        n = 1
        while i + n < len(toks) and toks[i + n] == "-":
            n += 1
        out.append((i, midi(re.split(r"[~<@+]", t)[0]), n))
    return out


def line_notes(bars):
    """Monophonic note list (midi, steps) from bar strings (first note of a chord)."""
    return [(m, n) for _, m, n in line_events(bars)]


def form_bars(era, ch):
    bars = []
    for sec in ["A", "A2", "B", "T"]:
        sb = era["channels"][ch]["sections"][sec]
        for i in range(8):
            bars.append(sb[i % len(sb)])
    return bars


# v2.2 (Bar, 2026-10-04: "the tapping notes should change according to the song that is playing"; ADR
# 0012, which brings back ADR 0009's tap): the tap plays the song the era is playing. tapLine is the
# melody of the loop, one entry per note: its onset (steps from bar 1), its midi pitch (the bell's
# register: a section that sits low goes up an octave), and the 2-bar phrases (note indexes) the
# runtime follows the music by and pays the phrase bonus on. The lead carries the song, except in the
# Knesset's A' hocket, where P2 has the melody (an octave down, so it comes back up). HaTikva
# (TAP_ANTHEM) is the cue's fallback melody, and it is what Balfour's A plays anyway.
TAP_SOURCE = {("knesset", "A2"): ("p2", 12)}
TAP_PHRASE_BARS = 2
TAP_FLOOR = midi("D4")      # the lowest bell note
TAP_LOW_SECTION = midi("F5")  # a section whose top is at or under this plays an octave up


def tap_line(eid, e):
    spb = e["stepsPerBeat"] * e["beatsPerBar"]
    sb = 8   # form_bars' section length (music()["form"]["sectionBars"])
    steps, notes = [], []
    for si, sec in enumerate(["A", "A2", "B", "T"]):
        ch, shift = TAP_SOURCE.get((eid, sec), ("lead", 0))
        bars = form_bars(e, ch)[si * sb:(si + 1) * sb]
        sec_notes = [(si * sb * spb + st, m + shift) for st, m, _ in line_events(bars)]
        if sec_notes and max(n for _, n in sec_notes) <= TAP_LOW_SECTION:
            sec_notes = [(st, n + 12) for st, n in sec_notes]
        for st, n in sec_notes:
            steps.append(st)
            notes.append(n + 12 if n < TAP_FLOOR else n)
    phrases = []
    for ph in range(4 * sb // TAP_PHRASE_BARS):
        first = next((i for i, st in enumerate(steps) if st >= ph * TAP_PHRASE_BARS * spb), None)
        if first is not None and first not in phrases and steps[first] < (ph + 1) * TAP_PHRASE_BARS * spb:
            phrases.append(first)
    return {"steps": steps, "midi": notes, "phrases": phrases, "phraseBars": TAP_PHRASE_BARS}


def check_tap_lines(m):
    sm = TAP_ANTHEM["semis"]
    if [b - a for a, b in zip(sm, sm[1:])][:len(ANTHEM)] != ANTHEM:
        err("tap: HaTikva (the fallback) does not open with the anthem's verified first two bars")
    if TAP_ANTHEM["phrases"][0] != 0 or sorted(set(TAP_ANTHEM["phrases"])) != TAP_ANTHEM["phrases"] \
            or TAP_ANTHEM["phrases"][-1] >= len(sm):
        err("tap: the fallback's phrase starts are not rising note indexes inside the anthem")
    for eid, e in m["eras"].items():
        tl = e["tapLine"]
        if len(tl["phrases"]) < 12:
            err("%s tapLine: only %d phrases" % (eid, len(tl["phrases"])))
        bounds = tl["phrases"] + [len(tl["midi"])]
        for a, b in zip(bounds, bounds[1:]):
            if not 3 <= b - a <= 18:
                err("%s tapLine: a phrase of %d notes at note %d" % (eid, b - a, a))
        lo, hi = min(tl["midi"]), max(tl["midi"])
        if lo < TAP_FLOOR or hi > midi("A6"):
            err("%s tapLine: range %s-%s" % (eid, nm(lo), nm(hi)))
        far = [n for n in tl["midi"] if min(abs(n - r) for r in TAP_BELL_ROOTS) > 3]
        if far:
            err("%s tapLine: %s more than 3 semitones from a bell root" % (eid, nm(far[0])))


def check_music(m):
    for eid, e in m["eras"].items():
        spb = e["stepsPerBeat"] * e["beatsPerBar"]
        step_s = 60.0 / e["tempoBpm"] / e["stepsPerBeat"]
        step_n = step_s * e["rate"]
        if abs(step_n - round(step_n)) > 1e-6:
            err("%s: a step is %.4f samples at %d Hz" % (eid, step_n, e["rate"]))
        for cid, ch in e["channels"].items():
            cspb = ch.get("stepsPerBeat", e["stepsPerBeat"]) * e["beatsPerBar"]   # v2.0: the hats' own grid
            for sec, bars in ch["sections"].items():
                for b in bars:
                    if len(b.split()) != cspb:
                        err("%s/%s/%s: bar of %d tokens" % (eid, cid, sec, len(b.split())))
            if "kit" in ch:
                continue
            bars = form_bars(e, cid)
            notes = line_notes(bars)
            lo, hi = RANGES[cid]
            for mn, n in notes:
                if not midi(lo) <= mn <= midi(hi):
                    err("%s/%s: %s out of range %s-%s" % (eid, cid, nm(mn), lo, hi))
            inst = ch.get("instrument")
            for sec in ["A", "A2", "B", "T"]:
                ins = ch.get("sectionInstrument", {}).get(sec, inst)
                gate = INSTRUMENTS[ins]["gate"]
                dur = INSTRUMENTS[ins]["layers"][0]["duration"]
                for mn, n in line_notes(ch["sections"][sec]):
                    held = n * step_s * gate if dur == "note" else float(dur)
                    if held > 1.0:
                        err("%s/%s/%s: %s held %.2f s (> 1.0 s steady tone)" % (eid, cid, sec, nm(mn), held))
            if cid in ("lead", "p2"):
                # the anthem's home section is checked on its own (the phrase in full, played straight);
                # the rest of the line, with the home section left out, keeps the 2-bar cap
                home = [sec for sec in ["A", "A2", "B", "T"] if (eid, cid, sec) in ANTHEM_HOME]
                for sec in home:
                    ins = ch.get("sectionInstrument", {}).get(sec, ch.get("instrument"))
                    if INSTRUMENTS[ins]["gate"] < 0.85 or INSTRUMENTS[ins]["layers"][0]["duration"] != "note":
                        err("%s/%s/%s: the anthem is played legato (%s is not)" % (eid, cid, sec, ins))
                    for b in ch["sections"][sec]:
                        if "~" in b or "<" in b or "@" in b:
                            err("%s/%s/%s: no ornament or override on the anthem (%s)" % (eid, cid, sec, b))
                rest = [b for i, b in enumerate(bars) if ["A", "A2", "B", "T"][i // 8] not in home]
                rnotes = line_notes(rest)
                iv = [b[0] - a[0] for a, b in zip(rnotes, rnotes[1:])]
                run = longest_phrase_run(iv)
                ANTHEM_RUNS["%s/%s" % (eid, cid)] = run
                if run > ANTHEM_MAX:
                    err("%s/%s: %d consecutive anthem intervals (> %d, about 2 bars)" % (eid, cid, run, ANTHEM_MAX))
                iv = [b[0] - a[0] for a, b in zip(notes, notes[1:])]
                # the quote check: a listed tune is allowed only in its own home (TUNE_HOMES)
                homes = {sec: [TUNE_QUOTES.get(t) for t, _ in TUNE_HOMES.get((eid, cid, sec), [])] for sec in ["A", "A2", "B", "T"]}
                for q, pat in QUOTES.items():
                    k = len(pat)
                    qbars = [b for i, b in enumerate(bars) if q not in homes[["A", "A2", "B", "T"][i // 8]]]
                    qn = line_notes(qbars)
                    qiv = [b[0] - a[0] for a, b in zip(qn, qn[1:])]
                    for i in range(len(qiv) - k + 1):
                        if qiv[i:i + k] == pat:
                            err("%s/%s: quote check hit %s at note %d" % (eid, cid, q, i))
        # the motif at bar 32 on the lead, pickup on bar 31
        root = midi(e["key"] + "4")
        lead = form_bars(e, "lead")
        last = line_notes([lead[31]])
        pick = line_notes([lead[30]])[-1][0]
        want = [2, 3, 5, 7]   # the anthem's rise: pickup 1 | 2 b3 4 5 (held, over V)
        got = [(n - root) % 12 for n, _ in last]
        if got != want or (pick - root) % 12 != 0:
            err("%s: bar 32 is not the motif (got %s, pickup %s)" % (eid, got, nm(pick)))
        tok31 = lead[30].split()
        if tok31[spb - spb // 8] == "." and e["stepsPerBeat"] == 4:
            err("%s: pickup is not on bar 31 beat 4&" % eid)
        # v1.9: bar 1 resolves the motif onto the tonic chord (Hevenu enters on its 5, Dayenu on its 3)
        bar1 = line_notes([lead[0]])[0][0]
        triad = (0, 3, 7) if e["mode"] == "minor" else (0, 4, 7)
        if (bar1 - root) % 12 not in triad:
            err("%s: bar 1 does not resolve onto the tonic chord (%s)" % (eid, nm(bar1)))


def check_cues(c):
    for cid, cue in c["cues"].items():
        for vid, layers in cue["variants"].items():
            for Lr in layers:
                g = Lr.get("glide")
                if "freqEnd" in Lr and g and g > 0.2 + 1e-9:
                    err("%s/%s: glide %.3f s > 200 ms" % (cid, vid, g))
                dur = Lr.get("duration", 0)
                if isinstance(dur, (int, float)) and Lr["wave"] in ("pulse", "triangle", "sine", "square") and dur > 0.8:
                    err("%s/%s: sustained tone %.2f s > 800 ms" % (cid, vid, dur))
                if Lr["wave"].startswith("noise") and cid in ("shutter", "stamp", "suitcaseSpawn", "suitcaseCatch"):
                    f = Lr.get("filter", {})
                    if f.get("type") == "highpass" and f.get("freq", 0) < 2500:
                        err("%s/%s: noise high-pass %s < 2.5 kHz" % (cid, vid, f.get("freq")))
            end = max(Lr.get("delay", 0) + (Lr["duration"] if isinstance(Lr.get("duration"), (int, float)) else 0)
                      + Lr.get("release", 0) for Lr in layers)
            # v1.3 mix pass: UI cues keep short tails; a first sound starts at t=0 and ends inside 1 s
            if cue["bus"] == "UI" and end > 0.4:
                err("%s/%s: UI cue ends at %.2f s (> 0.4 s tail)" % (cid, vid, end))
            if cid == "slipStamp" and end > 0.25:                # v1.4: a stamp that can repeat stays a thunk
                err("%s/%s: ends at %.2f s (> 0.25 s)" % (cid, vid, end))
            if cue.get("firstSound"):
                if min(Lr.get("delay", 0) for Lr in layers) > 0.0005:
                    err("%s: a first sound must start at t=0 (no silent lead-in)" % cid)
                if end > 1.0:
                    err("%s: %.2f s > 1 s" % (cid, end))
    tap = c["cues"]["tap"]
    if sorted(tap["variants"]) != sorted("r%d" % r for r in TAP_BELL_ROOTS):
        err("tap: the variants are the bell roots r<midi>")
    # v1.3: Dubi's canned lines stay off the anthem: bank degrees only (no 2, no b6), no 5 -> 5' leap
    bank = {"1", "3", "4", "5", "b7"}
    for line, contour in c["babbleContours"].items():
        if line.startswith("_"):
            continue
        for a, b in zip(contour, contour[1:]):
            if a[0] == "5" and b[0] == "5" and b[1] == a[1] + 1:
                err("babble %s: 5 -> 5' is the anthem's leap" % line)
        for d, o in contour:
            if d not in bank or o not in (5, 6):
                err("babble %s: %s_%s is not in Dubi's bank" % (line, d, o))
    for ev, m in c.get("crits", {}).items():
        if not ev.startswith("_") and m["cue"] not in c["cues"]:
            err("crits/%s: no cue %s" % (ev, m["cue"]))
        elif not ev.startswith("_") and m["variant"] != "roundRobin" and m["variant"] not in c["cues"][m["cue"]]["variants"]:
            err("crits/%s: %s has no variant %s" % (ev, m["cue"], m["variant"]))


def check_fanfare(m):
    """Bugle rule (brief §2): every fanfare line holds stepwise motion (never triad-only), the lead
    carries a chromatic step, and (v1.2) the lead states the anthem's rise 2-b3-4-5."""
    f = m["stingers"]["fanfare"]["channels"]
    for cid in ("lead", "p2"):
        notes = line_notes(f[cid]["bars"])
        iv = [b[0] - a[0] for a, b in zip(notes, notes[1:])]
        pcs = {n % 12 for n, _ in notes}
        triad_only = pcs <= {2, 5, 9} or pcs <= {9, 1, 4}
        if triad_only or not any(abs(i) in (1, 2) for i in iv):
            err("fanfare/%s: no stepwise motion (bugle rule)" % cid)
        ANTHEM_RUNS["fanfare/%s" % cid] = longest_anthem_run(iv)
    lead = line_notes(f["lead"]["bars"])
    iv = [b[0] - a[0] for a, b in zip(lead, lead[1:])]
    if 1 not in iv:
        err("fanfare/lead: no chromatic step")
    if not any(iv[i:i + 4] == [2, 1, 2, 2] for i in range(len(iv))):
        err("fanfare/lead: the anthem's rise 1-2-b3-4-5 is missing")


def main():
    m = music()
    check_fanfare(m)
    c = cues()
    check_music(m)
    check_tunes(m)
    check_tap_lines(m)
    check_cues(c)
    if CHECK_ERRORS:
        for e in CHECK_ERRORS:
            print("CHECK FAIL:", e)
        sys.exit(1)
    if "--check" not in sys.argv:
        os.makedirs(OUT, exist_ok=True)
        for name, data in (("music.json", m), ("cues.json", c)):
            with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
                f.write(json.dumps(data, ensure_ascii=False, indent=1) + "\n")
    n_cues = len(c["cues"])
    print("compose_od: 4 eras, %d stingers, %d cues; all checks pass (ranges, <= 1.0 s tones, <= 200 ms glides, "
          "motif at bar 32, fanfare bugle rule, %d quote incipits, anthem runs <= %d)" % (len([k for k in m["stingers"] if not k.startswith("_")]), n_cues, len(QUOTES), ANTHEM_MAX))
    print("  longest HaTikva interval run per line:", ", ".join("%s %d" % kv for kv in sorted(ANTHEM_RUNS.items())))


if __name__ == "__main__":
    main()
