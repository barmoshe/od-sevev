# "עוד סבב" (Another Round): sonic brief

**Artifact:** `sonic-brief` | **Version:** v1.2 (see the amendment below) | **Locked:** 2026-09-28 | **Owner:** Audio Director
**v1.1 (2026-09-28):**
- Accepted O-A1: no alt-B stems; variety comes from zero-byte layer mutes.
- Accepted O-A2: court day crossfades to the Courthouse track.
- Confirmed A3, A12, A13 and A14 from `../engine/feasibility.md`.
**v1.2 (2026-09-29): client direction from Bar, relayed by the orchestrator. It overrides this brief where the two conflict.**
- **The mode:** hijaz/freygish is replaced as the shared language by **HaTikva's minor**: natural minor, with the leading tone raised at cadences.
  - §3's modes, §4's motif and §5's era keys (D, E, G minor) change accordingly.
  - Washington stays Mixolydian, with a minor turn at its cadences only.
- **The no-go on quoting HaTikva is lifted for this use,** as allusion. The melody is public domain (Cohen, 1888).
  - Every other quote on the §2 list stays banned.
  - The sirens and bugle rules are unchanged.
- **§4, the motif:** the "עוד סבב" leitmotif is now the anthem's rise, **pickup 1 | 2 (OD) ♭3 (s') 4 (VAV) 5 (held)**.
  - It lands on 5 over V. The next round's downbeat on i is the only resolution.
  - Pillar 3 holds: the round never closes.
  - The v1.1 motif (5 | 1 5 3 ♭2) is retired.
- **§5, the fanfare tags** carry the anthem's two other gestures, one more per round: ♭6-5, ♭6-5, the octave leap 5-5′, ♭6′-5′.
- **Every era's A-section** opens with the contour.
- **The guardrail (new, binding):**
  - The anthem is **never mocked**: no detune, no comic bend, no kazoo or BLIP voice on its contour, no fail or loss sting, no staccato tiptoe on it.
  - It is played straight. The deadpan satire is the sincerity against the absurd numbers.
  - At most about 2 bars of verbatim contour (10 intervals) in any one place. This is checked by `audio/tools/compose_od.py`.
- **Engine consequences:**
  - Coalition collapse is now silence, with no motif.
  - The trophy and Dubi's stingers carry non-anthem material.
  - `courtIn` is a legato rise.
  - Everything is realised in `output/games/od-sevev/audio/od/` (see its `cue-spec.md` §6). The v1.1 text below stays as the record.

**Voice:** project (satire). **Inputs:** `../brief.md`, `../brief-round2.md` (round 2 wins on conflicts).
**Visual coherence:** paired against the brief's retro-pixel, big-head direction. Countersign against `../art/style-guide.md` v1 when it lands.
**Runtime (confirmed):** the Monkey Bananas fork, a Godot 4.7.2 web export (see `../engine/feasibility.md`).
- The chip synth renders **offline**, through `tools/lib_dsp.gd`, driven by `audio/music.json` and `audio/cues.json`.
- Cues ship as WAV, one file per pitch. Music ships as looping QOA stems at about 12.2 KB per second per layer.
- The number of voices is free. Anything that changes continuously at runtime must be either a bus effect or a separate file.
- There are no samples and no reverb bus. The only ambience is the slapback baked into the Courthouse stems.

## 1. Pillars
1. **A deadpan magic act.** Every sound is a trick done with a straight face. The "ta-da" is polite, never triumphant. The numbers get absurd, but the sound does not grow with them (§6).
2. **The mode is the country, not a character.** Hijaz/freygish is the game's shared language for *everyone*. No character, community or party ever gets an ethnic or religious musical tag. Each character's signature sound comes from their prop or their act.
3. **The round never closes.** The leitmotif ends on the ♭2, and only the downbeat of the next round resolves it. That is the endless-elections joke, written as harmony.
4. **Polite in the pocket.** The game is played on the bus, so it has short cues and no alarms. It mixes under the player's own podcast, and the phone's silent switch wins.

## 2. No-go list (each with its reason)
- **No sirens of any kind (hard red line).** No sustained tone over 800 ms with a pitch glide, no oscillating wail, and no steady unison tone over 1 s. In Israel these read as the Red Alert or the memorial siren. Any glide is capped at 200 ms and moves in one direction only.
- **No booms, explosions, interceptions or aircraft roar,** and no low-frequency impact with more than 250 ms of decay. The 2026 war stays out (brief-round2, "Still out").
- **No rapid noise-burst trains at 6 Hz or faster that have low-frequency body.** On a phone speaker these read as gunfire. Shutter, stamp and zipper noise is high-passed at 2.5 kHz or more.
- **No military bugles or IDF-evoking calls.** No melody built only on triad or harmonic-series notes on one voice, which is what a bugle call is. No 2/4 march-snare cadences with rudimental rolls. Every fanfare must contain stepwise chromatic motion and the hijaz augmented second, so it cannot be heard as a bugle. The pre-reveal roll is a darbuka roll, not a snare.
- **No quoted melodies,** including public-domain ones, because they read as stock:
  - Israeli songs: HaTikva, "Yerushalayim Shel Zahav", "Shir LaShalom", "Hava Nagila", "Hevenu Shalom Aleichem".
  - Anything political or borrowed from satire: any party jingle or campaign song, and Eretz Nehederet's theme.
  - US and Washington-flavoured tunes: "Hail to the Chief", "Stars and Stripes Forever", "Yankee Doodle".
  - Circus and film clichés: Looney Tunes' "Merrily We Roll Along" (the Bugs Bunny link makes this tempting), "Entry of the Gladiators", "Misirlou".
  - **The quote check:** any 5 or more consecutive intervals that match a listed tune in the same rhythm means a rewrite.
- **Nothing religious and nothing that mocks chant:** no cantillation contours, nigun vocables, shofar, adhan, church bells or liturgical choir pads. In a satire context any of these reads as mockery.
- **No crowd chants of names or slogans** ("Bi-bi!" and the like). They read as campaign material or put a crowd in the punchline.
- **No imitation of real notification tones or news idents.** That rules out WhatsApp, Telegram, iOS or Android pings, and the Kan 11, Channel 12 or Channel 14 news chimes. A ping that sounds like a real phone sends players to their pocket, and a news-ident copy breaks "all original".
- **No speech synthesis and no realistic voices.** This is a brief red line. Dubi babbles in chip blips only.
- **No pads, no reverb tails and no detuned "supersaw".** They blur the pixel-hard attack (§7). The only ambience is one slapback in the courthouse.

## 3. Palette: the requested chip channels
The whole game is 12-TET. There are no quarter-tones, because they are the usual "exotic" signifier. The local flavour comes from mode and ornament.

| # | Voice | Role | Params | Visual pair | Fallback if missing |
|---|---|---|---|---|---|
| 1 | **P1** pulse 25% | Lead: "the Magician's hand" | range D4–A6; 0 ms attack; mordents; ≤1-semitone slides of 60 ms or less; vibrato 5.5 Hz ±15 cents after 250 ms | hard pixel edge → hard square attack | none (required) |
| 2 | **P2** pulse 12.5% / 50% | Counter-line. 12.5% gives a nasal zurna-like colour for mizrahi answers; 50% is the "brass" for fanfares | range A3–E6; never the same duty as P1 at the same moment | two-tone costume palette → two pulses of distinct colour | P1 with a duty switch |
| 3 | **TRI** triangle | Bass, plus the darbuka "dum" as a pitch-drop kick (110→55 Hz over 60 ms) | bass register A2–C4 only (phone translation, §8) | heavy outline of the big heads | none (required) |
| 4 | **NOI-L** long noise | Darbuka "tek", rolls, gavel crack, stamp | decays 20–120 ms | dithered shadow | none (required) |
| 5 | **NOI-S** short/metallic noise | Riq jingles and hats, zipper, shutter, coin shimmer | high-passed at 2.5 kHz or more | 1-px sparkle highlights | NOI-L plus a high-pass |
| 6 | **OUT** (tri + noise) | Balfour protest drum line "outside the window" | its own sub-bus with an LPF | protest in the parallax background layer | NOI-L plus a filter automation |
| 7 | **BLIP** pulse 12.5% | Dubi's babble | octaves 5–6; blip length 55 ms | beak-flap frame = one blip | P2 |

**Modes and harmony:**
- **Hijaz / freygish** (1 ♭2 3 4 5 ♭6 ♭7) is the primary mode. Its chord vocabulary is I, ♭II, iv and ♭vii, and the home cadence is always ♭II→I.
- **Harmonic minor** colours the B-sections.
- **Mixolydian** is for Washington only.
- **Plain major** appears only as the resolution chord that opens a new round.

**Grooves:**
- **Hora pulse:** bass on 1 and 3, P2 stabs on every off-beat eighth, and the lead phrased 3+3+2.
- **Maqsum:** D T . T D . T . over 8 eighths.
- **Stride:** bass on 1 and 3, chords on 2 and 4.

## 4. Motif lock: "עוד סבב"
The rhythm follows the spoken words: **OD** (long), **s'** (short), **VAV** (long), then a shrug. It is 5 notes over 4.5 beats: an eighth-note pickup and one 4/4 bar.

```
ABC (D hijaz, L:1/8, K:none):   A, | D2 A ^F3 _E2 |
degrees:  5 | 1 (OD) - 5 (s') - 3 (VAV) - ♭2 (shrug, held)
MIDI:     57 | 62 - 69 - 66 - 63      durations (beats): 0.5 | 1, 0.5, 1.5, 1
intervals: +P4, +P5, -m3, -aug2
```

The 1→5 leap is the vaudeville "presto!" arm-raise. The descending augmented second, F#→Eb, is the hijaz fingerprint, and it avoids the ascending 1-♭2-3 snake-charmer and Misirlou cliché. The phrase hangs on the ♭2, the leading tone of ♭II→I, which is the leitmotif carrying the idea that the round never ends.

**Transformation map.** The motif always sits in the degrees of the current or incoming era key.

| Where it appears | Treatment |
|---|---|
| Election fanfare | full, harmonised (§5, cue 11) |
| Title screen | Plays on the first tap only (the audio unlock). The first sound a player ever hears is the motif on P1. |
| Every era loop | Bar 32 is the motif (pickup on bar 31, beat 4&). The ♭2 resolves into the loop's own bar 1, so the loop seam hides inside a cadence. |
| Court day | Augmented to double durations, on TRI alone, at Courthouse tempo (88 BPM, G). A pre-rendered stinger that plays on entry. |
| Coalition collapse / loss | Played once, ending on the ♭2, then nothing: no resolution, deadpan |
| Dubi's news flash | Head only (5-1-5), on BLIP, one octave up, staccato |
| Order-of-magnitude milestone (₪ million → billion → …) | Head only (5-1) on P2 at 50% duty, -3 dB under the rabbit crit |

## 5. Music (in `music.json`) and cues (in `cues.json`)

**Every era loop:**
- **Form:** 32 bars: A(8) A′(8) B(8) T(8), ending in the motif turnaround.
- **Layers, each faded in or out over 1 bar at bar lines:**
  - L0 bed (TRI + NOI): always playing.
  - L1 (P2): enters after the first money source is bought.
  - L2 lead (P1): plays while the player has tapped within the last 3 s. The melody arrives when you play and recedes when you idle.
- **Anti-fatigue, at 0 bytes:** a 4-loop cycle of runtime layer mutes, driven by a loop counter and applied at bar lines.
  - Loop 1: full.
  - Loop 2: L2 muted for bars 17–24. The B-section is carried by the P2 counter-line alone, which makes a second "B".
  - Loop 3: full.
  - Loop 4: bars 9–16 (A′) are the breather, L0 only.
  - *Composer note:* write L1's B-section as a complete melody that stands without L2. Loop 2 depends on it.
  - There are no alternate-section stems (O-A1).
- **Court day** (any era): at the next bar line, an equal-power crossfade to the **Courthouse track** (G hijaz, 88 BPM) with L2 muted. It reuses the existing era switch (O-A2).
  - The augmented TRI motif stinger plays on entry.
  - In the Courthouse era itself, court day is only the L2 mute plus that stinger.
  - The drop from 116, 132 or 144 BPM to 88 BPM is the mock-solemn slowdown.

| Era | Tempo | Key and mode | Groove | Mood (one line) |
|---|---|---|---|---|
| Balfour | 116 BPM | D hijaz | hora pulse, lead 3+3+2 | Smug domestic comfort, pistachio-and-champagne cheer, with protest drums leaking through the window. |
| Knesset | 132 BPM | E hijaz, B-section in A harmonic minor | maqsum | A bazaar-plenum haggle: P1 and P2 argue in 2-bar call-and-response and never finish each other's phrase. |
| Courthouse | 88 BPM | G hijaz | half-time swing, staccato "tiptoe" TRI quarters | Mock-solemn cartoon noir: sneaking past the bench. The only room in the game with a slapback (180 ms, -12 dB). |
| Washington | 144 BPM | F Mixolydian; hijaz ♭2 (G♭) only in the motif bar | stride / ragtime | Showbiz glitz, golden pager on Broadway. The local mode follows him abroad in exactly one bar per loop. |

**Balfour's OUT layer (the protest outside):**
- **Pattern:** a 2-bar drum line at the same tempo and on the same grid. TRI thump at 80 Hz on 1, 2& and 4; noise snare on 2 and 4 with ghost 16ths.
- **Filtering and level:** LPF 800 Hz, mono, pan -0.3, starting at -14 dB under L0. It rises by up to +6 dB across the era.
- **Pink Front easter egg** (Saturday night by device clock): the window opens. The LPF sweeps to 4 kHz over 2 bars, the layer gets +8 dB, and tap-to-beat judges against OUT's downbeats.
- **What it depicts:** the drums are the movement and are never mocked. There are no chants and no megaphone.

**Key cues.**
- **Latency:** the play call goes out within 1 frame of the trigger. That is the *scheduling* guarantee; the web output buffer, about 50 ms, is added on top (A14). Tap feel comes from the squash that lands on the same frame.
- **Pitch:** given in scale degrees of the key that is currently playing. That is the era key, or G during court day. Washington's taps and blips use F Mixolydian.
- **Files:** every pitched cue is pre-rendered once per key.

| # | Cue | Meaning | Recipe | Slot | Bus / priority | Variation |
|---|---|---|---|---|---|---|
| 1 | **Tap / hat trick** | "The trick worked; money came out." | 15 ms NOI-S cloth "fff", then a 40 ms P1 blip. The blip's pitch walks **up the era's hijaz scale** from degree 5, one step per tap, while taps come within 400 ms of each other; it wraps after 8 steps and resets after 400 ms idle. **Tapping plays the mode.** | 1.5–4 kHz | SFX-Frequent; poly 4, steal oldest; **ducks nothing** | Duty alternates 25/12.5% per tap; gain ±1.5 dB. **Files:** 8 steps × 4 keys (D, E, G, F Mixolydian) × 2 duties = **64 WAVs**, each 80 ms with the puff baked in, so a tap is one stream. At 16-bit mono and ≤ 32 kHz each is about 5.1 KB, **about 0.33 MB total**. |
| 2 | **Rabbit crit** | "The trick went spectacularly right" (rare). | TRI "boing" (440→220 Hz over 200 ms with a 12 Hz vibrato), then a 150 ms P1 upward slide from 5 to 1′, then the motif head 5-1-5 in 16ths on P1 and P2 in octaves. 600 ms or less in total. | 0.2–3 kHz | SFX-Critical; never stolen | 3 slide-length variants (120/150/180 ms), round-robin |
| 3 | **Suitcase zipper** | Spawn: "a catchable opportunity is on screen." Catch: "got it." | **Spawn:** NOI-S gated at 28 Hz for 300 ms with a rising high-pass, panned to the suitcase's x position (±0.4). **Catch:** the zipper reversed (120 ms), then a P2 50% "cha-ching" (5, 1′) plus a noise tick. **Miss:** one quiet TRI "bwomp" down a semitone under the ticker line and nothing else (deadpan). | 2.5–8 kHz | Spawn and catch: SFX-Critical. Miss: SFX-Frequent. | Gate rate ±3 Hz |
| 4 | **Coalition-chat ping** | "A partner posted a demand." | Two P2 12.5% notes of 60 ms each. Default ♭2→1 (a sigh). The interval is per partner and comes from their act, not their identity. Ben Gvir's ping repeats the same note twice, because he threatens more than once. **Left the group:** 1→♭2 upwards, unresolved, plus a 10 ms door-click. | 1.2–2.5 kHz, pitched in key | UI; poly 1 | Bursts coalesce: at most 1 ping per 700 ms; a burst becomes one 3-note "×3" ping |
| 5 | **Ultimatum tick** | "Pay before zero or they walk." | NOI-S tick/tock (8 ms, two filter settings), one per displayed second. In the last 3 s the rate doubles and **L2 drops out**: tension by subtraction. **At zero:** a TRI deflate falling a minor third, then the "left the group" ping. **No alarm beep, ever.** | 3–6 kHz | SFX-Critical, -6 dB under the tap | tick/tock alternation only |
| 6 | **Gavel** | "Court day starts." | Two knocks 180 ms apart. Each knock is a TRI thud (110→45 Hz over 80 ms) plus a 20 ms NOI-L crack. The music moves to the court-day variant at the next bar. **Postponement granted:** one weak knock at half gain and an octave up, a tiny "tik". | 80–400 Hz body, 2 kHz crack | SFX-Critical | ±0.5 dB |
| 7 | **Rubber stamp "נדרשים מסמכים נוספים"** | "Request bounced. Again." | A 30 ms NOI-L thump, a 60 ms TRI hit at 90 Hz, then a short P1 "ink squelch" that falls 2 semitones. Every 5th stamp adds a P2 50% typewriter-bell ding (2 kHz, 200 ms decay). | 90 Hz–2 kHz | SFX-Frequent | **Deliberately identical** (±0.5 dB). The sameness is the joke, and this is the one sanctioned exception to anti-fatigue. |
| 8 | **Transfer-window whistle** | "A partner switched jerseys (Gotliv)." | A referee pea-whistle on P2 50% at about 2.8 kHz with a 28 Hz warble (±30 cents). Pattern short-short-long (120/120/400 ms). Pitch-stable with no glide, and 800 ms or less in total, so it stays siren-safe. | 2.5–3.2 kHz | SFX-Critical | warble rate ±2 Hz |
| 9 | **Camera shutter (photobomb)** | "You caught the people who live in our cameras." | Two NOI-S bursts of 12 ms each, 70 ms apart and high-passed at 3 kHz (no body, so it cannot read as a shot), plus a P1 "pip" at 4 kHz. For the **"שלום בית בפריים"** trophy, the shutter is followed by the full motif on BLIP. | 3–8 kHz | UI | ±1 semitone on the pip |
| 10 | **Dubi squawk-babble** | "Dubi is speaking (headline or flash)." | **Squawk:** a BLIP chirp of ±7 semitones over 80 ms plus a NOI-S rasp. **Babble:** one 55 ms blip per displayed syllable (about 1 per 2 Hebrew letters), with pitch drawn from the era mode's degrees 1, 3, 4, 5 and ♭7 in octaves 5–6. A final "!" rises. **Canned lines have fixed contours**, because the parrot only repeats what he was told: "אין כלום!" is 5-5-1 falling, and "ציד מכשפות!" is 5-5-♭7-1. | 1.2–3 kHz | Voice; poly 1 | Capped at 1.6 s. The ticker babbles on at most 1 headline per 20 s; the rest are silent. **Files:** an era-keyed bank, 5 degrees × 2 octaves × 4 keys = 40 blips (about 0.2 MB, A13). It replaces the F-pentatonic bank. Canned contours live in `babble_plan`. |
| 11 | **Election fanfare** | "Another round: prestige." | 1 bar of NOI-L darbuka roll (32nds, crescendo). Then the motif: P1 lead, P2 a sixth below at 50% duty, TRI on 1 and 5, and an 800 ms NOI-L crash, all in the **incoming** era's key. The phrase hangs on the ♭2, and **the new loop's bar-1 downbeat is the resolution.** | full band | Music (a stinger that replaces the bed at a bar line) | Each round adds a half-bar P2 "ta-da" tag, capped at +4, so the fanfare gets one step longer each time, like Dubi's excuses. **Files:** 5 lengths × 4 keys = 20 stingers (about 1 MB, A12). Tags are never appended at runtime. |

**Everything else inherits a family.** Purchases use the tap blip plus the motif's first note. UI clicks are single P2 blips at 1–2 kHz. The "while you were away" return is cue 3's cha-ching followed by the motif head.

## 6. Emotional register
Two axes. **X** is the size of the trick, from petty to absurdly grand. **Y** is the face, from straight-faced cheerful to mock-solemn.

| Quadrant | Anchor | Beats that land here |
|---|---|---|
| Cheerful × petty | cue 1 (tap) | tap stream, bottle-deposit upgrade, UI |
| Cheerful × grand | cue 11 (fanfare) | rabbit crit, catching the suitcase, Washington |
| Mock-solemn × petty | cue 7 (stamp) | stamp, weak postponement gavel, "left the group" |
| Mock-solemn × grand | cue 6 (gavel) | court day, ultimatum countdown, coalition collapse |

**The ceiling rule.** No beat reaches real dread (drones, clusters, horror minor) or real triumph (a major brass swell with timpani).

**The deadpan rule.** Payout size never scales loudness or density: at most 6 coin blips per tap, whether the payout is ₪4 or ₪4 trillion. Absurd numbers are shown in digits, and the sound stays polite.

## 7. Differentiation
**Named baselines:**
- Kenney "Music Jingles" (8-bit set).
- SubspaceAudio (Juhani Junkala) "5 Chiptunes (Action)", on OpenGameArt.
- A stock "Arabian bazaar" loop from Pond5: the orientalist trap we are avoiding.

**Two decisions that mark us apart:**
1. The tap stream plays the era's hijaz scale.
2. The motif hangs on the ♭2 and resolves only when the next round starts.

**Test status:** pending the first 30-second mock-up.

**References.** Take the listed quality and reject the rest.
- **Shovel Knight** (Kaufman), "Strike the Earth!": take its melodic density from 4–5 chip voices; reject its heroic major register.
- **Papers, Please** (Pope), main theme: take its deadpan state-satire monotony; reject its march pulse.
- **Reigns** (Disasterpeace): take the understated political-satire restraint; reject the ambient pads.
- **Balkan Beat Box**, "Hermetico": take hijaz with party-electronic drive; reject the brass samples and vocals.
- **Carl Stalling's Looney Tunes scoring**: take the mickey-mousing, where every rabbit crit is a musical hit point; reject any quote (see §2).

## 8. Mix intent (for `mix-bus-topology` and `cue-spec`)
**Loudness targets:**
- The full mix sits at **-16 LUFS integrated**, measured over 60 s of typical play: all layers plus 5 taps/s. It is allowed up to -14.
- **True peak is ≤ -1 dBTP,** held by the fork's master chain: a compressor, then an `AudioEffectHardLimiter` at -1 dB (A18). LUFS is measured on the offline renders.
- **Solo targets:** music -19 LUFS, the tap stream -22 LUFS, Dubi -18 LUFS-S, and each critical SFX -12 LUFS-M at most.

**Buses and ducking:**
- The buses are Music (with the OUT sub-bus), SFX-Critical, SFX-Frequent, UI and Voice (Dubi).
- Voice ducks Music by -6 dB (attack 30 ms, release 250 ms).
- SFX-Critical ducks Music by -4 dB (50/200 ms).
- **Taps and UI duck nothing.** A 5 Hz tap stream would pump the music into fatigue.
- The fanfare replaces the bed rather than ducking it.

**Translating to phone speakers:**
- Bass lives in A2–C4 (110–260 Hz).
- Every beat-1 bass note also gets a 20 ms P2 12.5% click one octave up, so the bass line survives phone speakers that roll off around 300 Hz.
- The oscillators must be band-limited (PeriodicWave, ≤ 32 harmonics).
- Pulse leads stop at A6, to avoid aliasing grit.

**Mute defaults (UX owns placement; the behaviour requested here):**
- Sound is on by default, but **nothing plays before the first tap**. That tap unlocks audio and plays the motif.
- Request `navigator.audioSession.type = 'ambient'` where it is supported. That way the game mixes under the player's podcast and obeys the silent switch.
- Separate Music and SFX toggles, plus a one-tap master mute that is visible on the title screen and in the HUD. The setting persists.
- Suspend the AudioContext when the page's visibility becomes hidden.
- Reduced-motion never mutes audio.

## 9. Hand-off
- [ ] Composition (the four era loops and the fanfare against §4 and §5)
- [ ] Adaptive structure (layers L0–L2, OUT, court-day tempo)
- [ ] Sound design (the cues in §5)
- [ ] Mix (§8)
- [ ] 2D Artist countersign on the §3 visual pairs
- [x] Game Developer confirmed the seven-voice set (`../engine/feasibility.md` A1). O-A1 and O-A2 were resolved in v1.1.
