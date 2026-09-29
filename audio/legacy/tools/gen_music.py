#!/usr/bin/env python3
"""Generates audio/music.json for Monkey Bananas.

Lead and drums are hand-composed below. Bass, comp and frenzy arpeggio are
derived from the chord chart so they can never disagree with it.
Re-run:  python3 audio/tools/gen_music.py   (then python3 audio/tools/build_preview.py)
"""
import json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "music.json")

STEPS = 12  # 8th-note triplets per 4/4 bar -> shuffle feel
PC = {"C": 0, "Db": 1, "D": 2, "Eb": 3, "E": 4, "F": 5, "Gb": 6, "G": 7, "Ab": 8, "A": 9, "Bb": 10, "B": 11}
NAMES = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
F_MAJOR = {5, 7, 9, 10, 0, 2, 4}

def midi(name):
    m = re.fullmatch(r"([A-G])(#|b)?(-?\d)", name)
    base = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}[m.group(1)]
    acc = {"#": 1, "b": -1, None: 0}[m.group(2)]
    return (int(m.group(3)) + 1) * 12 + base + acc

def name(n):
    return f"{NAMES[n % 12]}{n // 12 - 1}"

def in_range(pc, lo, hi):
    """Lowest MIDI note with pitch class pc that is >= lo; must be < hi."""
    n = lo + ((pc - lo) % 12)
    assert n < hi, (pc, lo, hi)
    return n

# ---- chord chart (one entry per bar; "X|Y" = two chords, half a bar each) ----
CHORDS = {
    "A":  ["F", "F", "Bb", "C7"],
    "A2": ["F", "Eb", "Bb|C", "F"],
    "B":  ["Dm", "Bb", "Gm", "C7"],
    "B2": ["Dm", "Bb", "Gm|C", "C7"],
    "C":  ["Bb", "Bb", "C", "C"],
}
ORDER = ["A", "A2", "B", "B2", "A", "A2", "C", "A2"]

def chord_tones(sym):
    minor = sym.endswith("m")
    seventh = sym.endswith("7")
    root = sym.rstrip("m7")
    r = PC[root]
    third = (r + (3 if minor else 4)) % 12
    fifth = (r + 7) % 12
    sev = (r + 10) % 12 if seventh else None
    return r, third, fifth, sev

# ---- hand-composed lead (octave 4; never above D5) ----
LEAD = {
    "A": [
        "A4 - -  F4 - .  C4 - F4  A4 - .",
        "G4 - A4  G4 - F4  D4 - -  C4 - .",
        "D4 - -  Bb3 - D4  F4 - D4  Bb3 - .",
        "C4 - E4  G4 - Bb4  A4 - G4  E4 - C4",
    ],
    "A2": [
        "A4 - -  F4 - .  C4 - F4  A4 - C5",
        "Bb4 - -  G4 - Eb4  G4 - -  Bb4 - .",
        "D4 - F4  Bb4 - A4  G4 - E4  C4 - E4",
        "F4 - -  A4 - G4  F4 - .  . . C4",
    ],
    "B": [
        "D4 . D4  F4 . D4  A4 - -  F4 . .",
        "D4 . D4  F4 . D4  Bb4 - -  A4 . .",
        "G4 - Bb4  A4 - G4  F4 - D4  Bb3 - .",
        "C4 - -  E4 - -  G4 - -  Bb4 - .",
    ],
    "B2": [
        "A4 . A4  F4 . D4  A4 - -  D5 . .",
        "D5 - C5  Bb4 - A4  F4 - -  D4 . .",
        "G4 - A4  Bb4 - G4  E4 - G4  C5 - .",
        "C5 . Bb4  A4 . G4  F4 . E4  D4 - C4",
    ],
    "C": [
        ". . .  D4 . F4  . . .  Bb4 . .",
        ". . .  D4 . F4  . . .  A4@ook - .",
        ". . .  E4 . G4  . . .  C5@ook - .",
        ". . .  E4 . G4  Bb4 . G4  E4 - C4",
    ],
}

# ---- hand-composed drums (kit chars; several chars in one token = simultaneous hits) ----
G1 = "K . H  S . H  K . H  S . H"
G2 = "K . H  S . K  . . H  S . H"
HT = "K . .  . . H  S . .  . . H"
DRUMS = {
    "A":  [G1, G1, G1, "K . H  S . H  K . K  S S S"],
    "A2": [G1, G1, G1, "K . H  S . H  K . K  S . O"],
    "B":  [G2, G2, G2, "K . H  S . H  K . K  S S S"],
    "B2": [G2, G2, G2, "K . H  S . H  S . S  S S S"],
    "C":  [HT, HT, HT, "K . .  . . H  S . S  S S S"],
}
PERC_BAR = "Bs s bs  s Bs bs  Bs s bs  Bs bs Bs"
PERC = {sec: [PERC_BAR] * 4 for sec in CHORDS}

# ---- derived channels ----
BASS_LO, BASS_HI = midi("Eb2"), midi("Eb3")  # low roots live in [Eb2, D3]

def lower_neighbour(pc):
    for d in (1, 2):
        if (pc - d) % 12 in F_MAJOR:
            return (pc - d) % 12
    return (pc - 1) % 12

def bass_bar(sec, bar_syms, next_sym):
    halves = bar_syms.split("|")
    nr = chord_tones(next_sym.split("|")[0])[0]
    nr_low = in_range(nr, BASS_LO, BASS_HI)
    lead_in = nr_low - ((nr - lower_neighbour(nr)) % 12)  # step up INTO the next root
    toks = []
    if sec == "C":  # breakdown: sparse
        r = in_range(chord_tones(halves[0])[0], BASS_LO, BASS_HI)
        r2 = in_range(chord_tones(halves[-1])[0], BASS_LO, BASS_HI)
        return f"{name(r)} - -  . . {name(r+12)}  {name(r2)} - -  . . {name(lead_in)}"
    def beat_pair(sym, last):
        r = in_range(chord_tones(sym)[0], BASS_LO, BASS_HI)
        f = r + 7
        a = [name(r), "-", name(r + 12), name(f), "-"]
        a.append(last if last else name(r + 12))
        return a
    if len(halves) == 1:
        toks = beat_pair(halves[0], None) + beat_pair(halves[0], name(lead_in))
    else:
        toks = beat_pair(halves[0], None) + beat_pair(halves[1], name(lead_in))
    return "  ".join(" ".join(toks[i:i + 3]) for i in range(0, 12, 3))

COMP_LO = midi("G3")

def comp_voicing(sym):
    r, third, fifth, sev = chord_tones(sym)
    if sev is not None:  # C7 -> Bb3 + E4: the cheeky tritone
        a = in_range(sev, COMP_LO, COMP_LO + 12)
        b = a + ((third - sev) % 12)
        return f"{name(a)}+{name(b)}"
    a = in_range(third, COMP_LO, COMP_LO + 12)
    b = a + ((fifth - third) % 12)
    return f"{name(a)}+{name(b)}"

def comp_bar(sec, bar_syms):
    halves = bar_syms.split("|")
    x1, x2 = comp_voicing(halves[0]), comp_voicing(halves[-1])
    if sec == "C":
        return f". . .  . . {x1}  . . .  . . {x2}"
    return f". . {x1}  . . {x1}  . . {x2}  . . {x2}"

ARP_LO = midi("C4")

def arp_six(sym):
    r, third, fifth, sev = chord_tones(sym)
    R = in_range(r, ARP_LO, ARP_LO + 12)
    t = R + ((third - r) % 12)
    f = R + 7
    top = R + 12 if sev is None else R + 10
    return [name(R), name(t), name(f), name(top), name(f), name(t)]

def arp_bar(bar_syms):
    halves = bar_syms.split("|")
    a = arp_six(halves[0]) + arp_six(halves[-1])
    return "  ".join(" ".join(a[i:i + 3]) for i in range(0, 12, 3))

def next_bar_sym(order_idx, bar_idx):
    if bar_idx < 3:
        return CHORDS[ORDER[order_idx]][bar_idx + 1]
    return CHORDS[ORDER[(order_idx + 1) % len(ORDER)]][0]

# Bass lead-in depends on what follows each section. Sections that recur
# (A, A2) are always followed by the same chord family (F or Dm or Bb), so we
# derive from the first occurrence and assert consistency across occurrences.
BASS, COMP, ARP = {}, {}, {}
for oi, sec in enumerate(ORDER):
    bars = [bass_bar(sec, CHORDS[sec][b], next_bar_sym(oi, b)) for b in range(4)]
    BASS.setdefault(sec, bars)  # recurring sections keep their first lead-in (A2 -> C3, the dominant, works before Dm, Bb and F)
    COMP[sec] = [comp_bar(sec, CHORDS[sec][b]) for b in range(4)]
    ARP[sec] = [arp_bar(CHORDS[sec][b]) for b in range(4)]

music = {
    "version": 1,
    "_doc": "Monkey Bananas procedural chiptune loop. Owner: Audio Director. Generated by audio/tools/gen_music.py (edit the script, not this file). Instruments use the cues.json layer schema. Reference player: preview.html (class MusicPlayer). Keys that start with '_' are documentation.",
    "title": "Banana Republic Shuffle",
    "tempoBpm": 126,
    "timeSignature": [4, 4],
    "stepsPerBeat": 3,
    "stepsPerBar": STEPS,
    "_grid": "One step = one 8th-note triplet = 60/126/3 s = 0.1587 s. Swung 8ths are written long-short on beat positions 0 and 2 ('X - Y'). A bar lasts 1.905 s and the 32-bar loop lasts 60.95 s.",
    "key": "F major",
    "a4Hz": 440,
    "noteFormat": {
        "_doc": "Each bar is ONE string of exactly 12 whitespace-separated tokens (the extra spaces between beats are cosmetic).",
        "note": "Scientific pitch, e.g. 'F4', 'Bb3', 'C#5'. Starts a note on that step.",
        "chord": "Notes joined by '+', e.g. 'A3+C4'. Starts all of them on that step (the comp channel only).",
        "instrumentOverride": "'NOTE@inst', e.g. 'A4@ook', plays that note with instruments[inst] instead of the channel's instrument.",
        "hold": "'-' extends the previous note by one step (ties may cross bar lines but never the loop point).",
        "rest": "'.' is silence; any sounding note is released at this step.",
        "drums": "On a channel with a 'kit', each character of a token is one simultaneous hit looked up in that kit ('KH' = kick + hat). '.' = nothing.",
        "length": "noteSeconds = heldSteps * stepSeconds * instrument.gate. A layer with duration 'note' uses noteSeconds (floored at attack + decay)."
    },
    "instruments": {
        "_doc": "Layer schema = cues.json _schema.layer. Tonal layers are authored at A4 (440 Hz): at play time frequency *= noteHz / 440 for followPitch layers. Drum layers use absolute Hz (followPitch false).",
        "lead": {"gate": 0.92, "layers": [
            {"id": "pulse", "wave": "pulse", "duty": 0.25, "freqStart": "A4", "attack": 0.004, "decay": 0.12, "sustain": 0.55, "duration": "note", "release": 0.05, "gain": 1.0,
             "vibrato": {"rateHz": 5.5, "depthCents": 15, "delay": 0.2}}]},
        "ook": {"gate": 0.92, "layers": [
            {"id": "slide", "wave": "pulse", "duty": 0.25, "freqStart": "E4", "freqEnd": "A4", "freqCurve": "exp", "glide": 0.07,
             "attack": 0.003, "decay": 0.08, "sustain": 0.5, "duration": "note", "release": 0.04, "gain": 1.0}]},
        "bass": {"gate": 0.85, "layers": [
            {"id": "tri", "wave": "triangle", "crush": 4, "freqStart": "A4", "attack": 0.002, "decay": 0.06, "sustain": 0.85, "duration": "note", "release": 0.02, "gain": 1.0},
            {"id": "growl", "wave": "pulse", "duty": 0.125, "freqStart": "A4", "filter": {"type": "lowpass", "freq": 1200, "Q": 0.7},
             "attack": 0.002, "decay": 0.08, "sustain": 0.4, "duration": "note", "release": 0.02, "gain": 0.12}]},
        "comp": {"gate": 1.0, "layers": [
            {"id": "chk", "wave": "pulse", "duty": 0.125, "freqStart": "A4", "attack": 0.002, "decay": 0.07, "sustain": 0, "duration": 0.072, "release": 0.01, "gain": 1.0}]},
        "arp": {"gate": 0.8, "layers": [
            {"id": "pulse", "wave": "pulse", "duty": 0.125, "freqStart": "A4", "attack": 0.002, "decay": 0.09, "sustain": 0.25, "duration": "note", "release": 0.03, "gain": 1.0}]},
        "kick": {"gate": 1.0, "layers": [
            {"id": "body", "wave": "triangle", "crush": 4, "freqStart": 160, "freqEnd": 48, "freqCurve": "exp", "glide": 0.09, "followPitch": False,
             "attack": 0.001, "decay": 0.13, "sustain": 0, "duration": 0.131, "release": 0.01, "gain": 1.0},
            {"id": "click", "wave": "noise", "clockStart": 48000, "filter": {"type": "highpass", "freq": 3000, "Q": 0.7},
             "attack": 0.0005, "decay": 0.008, "sustain": 0, "duration": 0.0085, "release": 0.003, "gain": 0.25}]},
        "snare": {"gate": 1.0, "layers": [
            {"id": "noise", "wave": "noise", "clockStart": 24000, "filter": {"type": "bandpass", "freq": 1900, "Q": 0.9},
             "attack": 0.001, "decay": 0.13, "sustain": 0, "duration": 0.131, "release": 0.02, "gain": 1.0},
            {"id": "body", "wave": "triangle", "crush": 4, "freqStart": 240, "freqEnd": 170, "freqCurve": "exp", "glide": 0.05, "followPitch": False,
             "attack": 0.001, "decay": 0.06, "sustain": 0, "duration": 0.061, "release": 0.01, "gain": 0.35}]},
        "hatC": {"gate": 1.0, "layers": [
            {"id": "noise", "wave": "noise", "clockStart": 48000, "filter": {"type": "highpass", "freq": 7500, "Q": 0.7},
             "attack": 0.0005, "decay": 0.03, "sustain": 0, "duration": 0.031, "release": 0.005, "gain": 0.6}]},
        "hatO": {"gate": 1.0, "layers": [
            {"id": "noise", "wave": "noise", "clockStart": 48000, "filter": {"type": "highpass", "freq": 7000, "Q": 0.7},
             "attack": 0.0005, "decay": 0.14, "sustain": 0, "duration": 0.141, "release": 0.02, "gain": 0.45}]},
        "shaker": {"gate": 1.0, "layers": [
            {"id": "noise", "wave": "noise", "clockStart": 48000, "filter": {"type": "highpass", "freq": 5500, "Q": 0.7},
             "attack": 0.012, "decay": 0.045, "sustain": 0, "duration": 0.058, "release": 0.01, "gain": 0.5}]},
        "bongoHi": {"gate": 1.0, "layers": [
            {"id": "tri", "wave": "triangle", "crush": 4, "freqStart": 560, "freqEnd": 420, "freqCurve": "exp", "glide": 0.04, "followPitch": False,
             "attack": 0.001, "decay": 0.08, "sustain": 0, "duration": 0.081, "release": 0.01, "gain": 0.9}]},
        "bongoLo": {"gate": 1.0, "layers": [
            {"id": "tri", "wave": "triangle", "crush": 4, "freqStart": 380, "freqEnd": 280, "freqCurve": "exp", "glide": 0.05, "followPitch": False,
             "attack": 0.001, "decay": 0.1, "sustain": 0, "duration": 0.101, "release": 0.01, "gain": 0.9}]},
    },
    "kits": {
        "drums": {"K": "kick", "S": "snare", "H": "hatC", "O": "hatO"},
        "perc": {"B": "bongoHi", "b": "bongoLo", "s": "shaker"},
    },
    "channels": {
        "_doc": "gain is linear inside the music submix. 'layer' names the adaptive layer the channel belongs to. sections[sectionId] = 4 bar strings.",
        "lead": {"instrument": "lead", "gain": 0.34, "layer": "base", "sections": LEAD},
        "bass": {"instrument": "bass", "gain": 0.40, "layer": "base", "sections": BASS},
        "drums": {"kit": "drums", "gain": 0.40, "layer": "base", "sections": DRUMS},
        "comp": {"instrument": "comp", "gain": 0.16, "layer": "evolved", "sections": COMP},
        "perc": {"kit": "perc", "gain": 0.30, "layer": "frenzy", "sections": PERC},
        "arpFrenzy": {"instrument": "arp", "gain": 0.14, "layer": "frenzy", "sections": ARP},
    },
    "form": {
        "_doc": "The song is ORDER expanded to 32 bars. After bar 32 it wraps to bar 1 (no intro, no outro). Seam: bar 32 ends with the C4 pickup at pos 11 that leads into the A4 of bar 1 (the 'Ba-NA-na' motif), so the loop point sits INSIDE a phrase, which makes it inaudible.",
        "sectionBars": 4,
        "order": ORDER,
        "chords": CHORDS,
        "totalBars": 32,
        "cuePoints": {"loopStart": "1:1", "motif": ["1:1", "5:1", "17:1", "21:1", "29:1"], "breakdown": "25:1", "loopEnd": "32:12"},
    },
    "adaptive": {
        "layers": {
            "base": {"channels": ["lead", "bass", "drums"], "default": True},
            "evolved": {"channels": ["comp"], "default": False,
                         "_rule": "ON when evolutions >= 1 AND the frenzy layer is off. (Slightly Smarter Monkeys have discovered the off-beat.)"},
            "frenzy": {"channels": ["perc", "arpFrenzy"], "default": False,
                        "_rule": "ON while frenzyActive OR tapFrenzyActive. While on, 'evolved' is forced off (the arp replaces the comp)."},
        },
        "transitions": {
            "layerOn": {"quantize": "beat", "fadeInMs": 40,
                        "_doc": "The first step >= the next unscheduled step that is a multiple of stepsPerBeat. Notes are only scheduled for enabled layers; the layer GainNode ramps 0->1 over fadeInMs at that step. The pattern is indexed by the global step, so a layer always enters in phase."},
            "layerOff": {"quantize": "bar", "fadeOutMs": 200,
                         "_doc": "Stop scheduling from the next bar boundary; ramp the layer GainNode 1->0 over fadeOutMs starting there to cut ringing tails."},
            "fadeOutStop": {"_doc": "evolveConfirm: ramp the music 'state' gain linearly to 0 over the given ms (400 = evolveFadeOutMs), then stop the scheduler and reset stepIndex to 0."},
            "restart": {"fadeInMs": 300, "_doc": "evolveTransitionEnd: set keyOffset from keyOffsetByEvolutions, set 'evolved' per its rule, start at step 0 (bar 1), and ramp the state gain 0->1 over 300 ms (evolveFadeInMs)."},
            "start": {"_doc": "audioUnlock (or the music toggle turned on): start at step 0 if never started; otherwise continue."},
            "fallback": "If a transition cannot be quantized (the scheduler is stopped), apply it immediately with the same ramp.",
        },
        "keyOffsetByEvolutions": {"table": [0, 2, 4, 5], "index": "evolutions % 4",
                                  "_doc": "Semitones added to every note of every tonal channel AND to SFX cues with followsKey:true, so taps stay in the song's key. Every Evolve lifts the key (the classic 'truck driver's modulation', played for laughs); every 4th Evolve the monkeys forget and it resets. Capped at +5 so the lead peaks at G5 and the tap pool at F7."},
    },
    "scheduler": {
        "lookaheadMs": 100, "timerMs": 25,
        "_doc": "Chris Wilson's 'A Tale of Two Clocks' pattern: a 25 ms setInterval schedules every step whose time is < ctx.currentTime + 0.100 with start(when). Never use setTimeout per note. On resume from a suspended context, if nextStepTime < currentTime then nextStepTime = currentTime + 0.05.",
    },
    "mix": {
        "_doc": "Measured with preview.html's offline meter (K-weighted, BS.1770 gating, stereo sum of the mono signal). See mix-bus-topology.md section 5.",
    },
}

# ---- validation ----
def check_bar(s, where):
    t = s.split()
    assert len(t) == STEPS, f"{where}: {len(t)} tokens: {s!r}"
    return t

for ch, spec in music["channels"].items():
    if ch.startswith("_"):
        continue
    for sec, bars in spec["sections"].items():
        assert len(bars) == 4, (ch, sec)
        for i, b in enumerate(bars):
            for tok in check_bar(b, f"{ch}.{sec}[{i}]"):
                if tok in (".", "-"):
                    continue
                if "kit" in spec:
                    kit = music["kits"][spec["kit"]]
                    assert all(c in kit for c in tok), (ch, sec, tok)
                else:
                    for n in tok.split("@")[0].split("+"):
                        midi(n)
                    if "@" in tok:
                        assert tok.split("@")[1] in music["instruments"], tok
# lead range guard (frequency-slot contract: lead never above D5)
for sec, bars in LEAD.items():
    for b in bars:
        for tok in b.split():
            if tok not in (".", "-"):
                assert midi(tok.split("@")[0]) <= midi("D5"), (sec, tok)
# the song must not start on a tie
for ch, spec in music["channels"].items():
    if ch.startswith("_"):
        continue
    first = spec["sections"][ORDER[0]][0].split()[0]
    assert first != "-", ch

with open(OUT, "w") as f:
    json.dump(music, f, indent=1)
    f.write("\n")
print("wrote", os.path.normpath(OUT))
for sec in CHORDS:
    print(sec, "bass:", BASS[sec])
