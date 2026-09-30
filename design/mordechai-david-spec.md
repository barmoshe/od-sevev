# mechanic-spec: Mordechai David, "החסימה" (a stage event)

**Owner:** Game Designer · **Date:** 2026-09-30 (session 5) · **Status:** designed; content and facts
landed behind the flag; the engine effect and the presenter are for the Game Developer.
**Consumers:** Game Developer (effect, presenter, flag flip), 2D Artist (sprite, §10), Animator (beats, §9),
Audio Director (cue intent, §11), UX Designer (card header, toast keys, §8).
**Data:** `design/content.json` `events[]` id `mordechai`; `design/facts.json` refs 73-75 and 47;
`design/redlines.json` (the narrowed entry and four scoped allows).

**Bar's call (2026-09-30):** "add Mordechai David, satirically, about the fact that he blocks Kaplanists and
leftists", as **a blocking character on the stage**, on for launch. This **reverses** the creative pack's drop
recommendation (`creative-pack/pitch.md` §2.10 and its table, `brief-round2.md` "Mordechai David",
`voice/copy-deck.md` §F). Those docs stay as the record; this spec supersedes them for him. The one thing that
stays dropped is the Eisenkot beach exchange (fact 47, §12).

---

## 1. The joke, and why it is safe to tell

**Documented conduct (all sourced, §12):**
- He stands in the way. On 21 Nov 2025 he stood in front of MK Gilad Kariv's car in the exit lane of a protest.
  In Jan 2026 he and others blocked the car of retired Supreme Court President Aharon Barak in a parking lot.
- His stated reason, reported by Ynet (1 Feb 2026): just as roads were blocked in the Kaplan protest, he blocks
  in his own protest.
- Since 31 Aug 2026 he has had a paid role in Otzma Yehudit's youth HQ, in Ben Gvir's campaign.

**The joke:** *the blocker of the blockers.* He copies Kaplan's road-blocking in order to block Kaplan, and a
blockade blocks everybody. So in the game he stands in front of the protest crowd, and the one who gets stuck
is **your own minister**, in the traffic behind the blockade. The satire lands on the method (a blockade has
collateral) and on his own stated logic. It does not land on the protesters, and it does not land on him as a
person.

**Why this answers the pitch §2.10 objection:**
- "Streaming at an opposition figure is too close to harassment as a player action." Here **there is no player
  action**: no button, no tap target, no reward for aiming him at anyone. He is weather, like Kaia or the defector.
- "The legal risk is high." Every claim the game makes is one of three sourced facts, rendered as reported speech
  where it is his argument. None of the risky material appears: no conviction, no restraining orders, no Shin Bet,
  no minors, no family, nothing about the hostage protests. The legal read stays on Bar's list (HANDOFF).
- "His only good line is about military service." That line stays out (§12). He doesn't need it.

**Not endorsed:** the effect is a small cost to the player in **every** leader's round, including Ben Gvir's.
His blockade is never a buff, so the game never pays the player for blocking protesters.

## 2. Where he appears: Balfour only

- **Balfour is the only stage with a protest crowd.** It has two baked groups of generic protesters behind
  police barriers, at art x 2-56 and 126-178 with the floor at y 216 (`creative-pack/art/src/locations.py`
  `balfour()`; wings in `art/od-sevev/src/wave7.py`). The Knesset, courthouse and Washington stages have no crowd.
- **Stages follow the global election count** (`leader-select-spec.md` §5.10: "the 4 stages stay shared and follow the global election count").
  Balfour is `fromEvolutions: 0`, so Balfour is **the first round of a save** only, whoever the leader is.
- **So he is a first-round cameo:** at most once per save, and again after a reset. That is the right dose for
  a real private-ish activist with legal risk. It is a moment the player remembers, not a recurring bit.
  The bench (§6) measures how often he shows.
- **Rejected for launch: the Knesset.** A crowd there means either a stage re-render or a "portable crowd" (three
  protester sprites that walk in first). Both cost art, motion and a new beat, for a character whose dose should
  stay small. This is kept as an option for Bar (§13, D2), not as a spec.

**His mark:** in front of the **right** crowd group, feet on the floor line (art y 216), centred on art x ≈ 150
(the group spans 126-178). That is clear of the leader's hit box, which ends near art x 137. The ref faces
screen-left, toward the leader, so he needs no mirroring. He enters from beyond the right edge of the canvas
(the wing on wide screens), in front of the barrier and behind every money source and the leader (z-order §9.3).

## 3. Which rounds: all 8 leaders, with three copy skins

The event is **shared**: it isn't in `bibiOnly.events`, and it has no `side`, so `Leaders.build_events` keeps it
for every leader. Having no `side` also means S05 "ציד מכשפות" never pays base for it, which is correct: he is
not an opposition card.

| Leader's round | Skin | The satirical read |
|---|---|---|
| ביבי, סמוטריץ׳, דרעי | default | His own logic, reported: "they blocked roads at Kaplan, so he blocks." Your minister is stuck in it. |
| בן גביר | `bengvir` | He is **your** paid youth-HQ staffer (fact md-otzma-youth). Your own man goes out to block, and your own minister is stuck behind him. |
| בנט, אייזנקוט, ליברמן, גולן | `opposition` | He has already blocked an opposition MK's car (Kariv, md-blocks-cars). Today it is a whole street, and yours is in it. |

Skin lookup, for the developer: `copy.skins[leaderId]`, then `copy.skins[side]` (the leader's `side`), then the
default `copy`. The skin overrides only the keys it has (`role`, `text`, `textSrc`).

## 4. Trigger, frequency and cooldown

In `content.json` `events[]` (landed):

| Field | Value | Why |
|---|---|---|
| `kind` | `stage` | He is a figure on the stage (like `defector`, `kaia`), with a card |
| `flag` | `mordechaiDavid` | Declared in `flags`; **false until the change-set that wires it** (§7.5) |
| `when` | `{era: "balfour", membersAtLeast: 2}` | Balfour's crowd (§2). Two members means there is usually a small partner to strand |
| `weight` | 5 | Round 1's eligible pool is small (brawl 3, interview 2, lapid 2, pardon 1 when it applies). At weight 5 he is the likeliest pick without being certain (§6) |
| `oncePerRound` | true | Once, full stop. Balfour is one round anyway |
| `cooldownSec` | 900 | Kept from the stub; it only matters after a save reset |
| `pollLike` | false | No numbers, no seats in copy |
| `effect` | `{type: "none", sec: 20}` **today** | The engine has no `blockade` yet; the golan-card pattern (`designerEffect`) |
| `designerEffect` | `{type: "blockade", sec: 20, maxSeats: 4}` | The real effect (§5). The developer moves it into `effect` |

`Events.eligible` already applies: the flag, the `when`, `oncePerRound`, the cooldown, and (once `blockade` is
in `SEAT_COSTS`, §7.1) **never while the 61 gate is open**. The scheduler fires one event every 150-210 s from
240 s of play (`eventsConfig`), so round 1 has 2-3 event slots.

## 5. The effect: `blockade`

**Rule.** On fire, pick one **counting** partner (`Coalition.counts`: a member, not frozen, not benched) whose
seats are 1..`maxSeats` (4), uniformly at random. That partner is **benched for `sec` (20 s)**:
`Coalition.bench(s, id, sec)`, the same mechanism as Kaia's nip. A benched partner:
- doesn't count toward the 61 (the seats bar drops by 1-4 and comes back);
- pays no upkeep and makes no new demands while stuck (existing bench behaviour in `Coalition.tick`). This is a
  small silver lining, and it's funny: stuck in traffic, not at work.

The live effect `{type: "blockade", partner, leftSec}` runs for the same 20 s. That is the figure's hold, so the
blockade and the bench end together (`eventEnd {type: "blockade"}`).

**If no partner qualifies** (only big partners are in, or everyone small is already benched): no bench, the result
is `{partner: ""}`, and the card uses `aloneText`. He still walks in, blocks and leaves. There is no retry and
no fallback target: he never strands a 5+ seat partner (Ben Gvir's 12 would be a spike, not a joke).

**Edge cases:**
| Case | Outcome |
|---|---|
| The 61 gate is open | Not eligible (`SEAT_COSTS`); the finish line stays quiet (spec §7.4) |
| The gate would have opened during the 20 s | It opens up to 20 s later. That is the whole cost ceiling |
| The benched partner leaves or is poached during the bench | Bench state belongs to that partner row; leaving clears it as today. The blockade effect just runs out |
| An election during the blockade | Not possible (the gate is shut while it runs, and the vote needs the gate). `Events.on_election` clears `active` anyway |
| Save and load mid-blockade | `benchSec` and `active` are both saved and sanitized today; the figure is re-placed on its mark in the hold pose, with no walk-in |
| Reduced motion | Same sim; the figure fades in and out on the mark (§9.4) |
| Offline progress | Events don't fire offline; nothing to do |

**No dominant strategy exists,** because the player makes no choice here. **Degenerate risk:** with Deri
(`cannotLeave`) the pool rule is by seats only. Deri has 9 seats, so he is never picked. That is fine.

## 6. Balance: bench result

Method: the full bench (`tests/bench`) on a local prototype copy with `flags.mordechaiDavid: true` and the
`blockade` effect implemented as in §7.1, against the leader bench on the committed content (flag off).
The prototype stays out of the commit (the engine is the developer's). A local probe counted his fires per
leader over seeds 1-9.

RESULTS_PLACEHOLDER

## 7. For the Game Developer

### 7.1 The effect (the exact prototype the bench ran)
In `game/scripts/sim/events.gd` `EFFECTS`:
```gdscript
"blockade": func(s: GameState, e: Dictionary, _d: Economy.Derived, r: Callable) -> Dictionary:
	# Mordechai David (design/mordechai-david-spec.md §5): a counting partner of 1..maxSeats seats is
	# stuck behind the blockade and misses the vote for `sec`; none in range: the card only.
	var pool: Array = []
	for p: Dictionary in Coalition.partners():
		var seats := int(Coalition.partner(p["id"]).get("seats", 0))
		if Coalition.counts(s, p["id"]) and seats > 0 and seats <= int(e.get("maxSeats", 4)):
			pool.append(p["id"])
	var id := ""
	if not pool.is_empty():
		id = pool[int(float(r.call()) * pool.size()) % pool.size()]
		Coalition.bench(s, id, float(e.get("sec", 20.0)))
	_activate(s, "blockade", e, {"partner": id})
	return {"partner": id},
```
Also add `"blockade"` to `SEAT_COSTS`. Then set `events[mordechai].effect` to the `designerEffect` value and
delete `designerEffect`. Mirror the stub in `game/tests/fixtures/politics.json` the same way. Suggested tests:
the partner is benched and uncounted for 20 s; it never picks more than 4 seats; `{partner: ""}` when none
qualifies; it isn't eligible with the gate open; it isn't eligible outside Balfour.

### 7.2 The presenter (there is no event view today)
**Finding:** no view consumes `{ev: "event"}` today. `main.gd` `_on_politics_event` routes only to the chat,
court and thermometer, so **every shipped card (Lapid, Eisenkot, Liberman, Bennett, Golan) and every stage
event (the defector, Kaia) fires silently** in the live build: their sim effects apply with no card, and the
kit's `card_opposition` art is unused. That is outside this spec, and it is flagged to the orchestrator. For
him, the presenter is:
1. **Stage figure:** walk in, block, hold, walk out (§9), on `event id == "mordechai"`.
2. **Card:** the kit's opposition-card template (`card_opposition`, `opp_timer_fill` counting down `leftSec`), but
   with a **neutral header**. He is not the opposition, so the header is not `OPP_HEADER`. Proposed UX key
   `STREET_HEADER` "מהרחוב". Lines: `name` · `role`, `text` (skinned), then `blockedText` or `aloneText`.
   The card has **no buttons**. It auto-dismisses at `eventEnd`, and ✕ closes it early (the effect runs on).
3. **Ticker:** `copy.ticker` enqueued as a headline on fire.
4. **Toast on end:** `endText`, only when a partner was benched, on `eventEnd {type: "blockade"}`.
5. **Seats bar:** nothing new. The bench already drops the effective seats. Optional: the benched partner's
   chat avatar greys for the 20 s (the `benched` row field exists in `Coalition.rows`).

### 7.3 Runtime variables
`{name}`: the benched partner's display name for this round (`Coalition.partner(id).name`, or the leader's
partner profile). `{sec}`: `designerEffect.sec` (20).

### 7.4 Lint (proposed, `design/sim/content-lint.mjs`)
Add `'מרדכי דוד'` to `realNames` (rule 6), so a quoted line in his name fails unless it has a [Q] src. He has
no [Q] fact, so any quote in his mouth would fail, which is what we want.

### 7.5 Turning it on (Bar: on for launch)
In **the same change-set** that lands §7.1 and §7.2:
- `flags.mordechaiDavid: true` in `design/content.json` (the `tests/fixtures/politics.json` flag stays false:
  the fixture tests rules, not launch state);
- `facts.json` md-blocks-cars, md-kaplan-method, md-otzma-youth: `notUsed: false` (their `aboutHe` is already
  written and linted, `launchWith: "mordechaiDavid"`);
- `tools/sync_data.sh`, then `tools/test.sh`, `node design/sim/content-lint.mjs --strict`, the full
  `tools/balance.sh`.

It is **not** turned on here. With the flag on and no presenter, he would fire invisibly and take a round-1
event slot, and the About page would list his facts for an event nobody sees.

## 8. Copy (landed in `content.json`, proposed for wiring)

Widths are measured in Sevev 9 at ×4 with the worst-case partner name "גלית דיסטל אטבריאן". The toast box is 644 px × 2 lines.

| Key | Hebrew | Chars | px ×4 | Src / rule |
|---|---|---|---|---|
| `copy.name` | מרדכי דוד | | | redlines allow `mordechai` |
| `copy.role` | פעיל ימין | | | |
| `copy.text` (default) | לדבריו, בקפלן חסמו כבישים, אז גם הוא חוסם. את כולם. | 51 | 960 | md-kaplan-method, **reportedSpeech** |
| `skins.bengvir.role` | מטה הצעירים שלך | | | md-otzma-youth |
| `skins.bengvir.text` | העובד שלך במטה הצעירים יצא לחסום. השר שלך בפקק. | | 956 | md-otzma-youth |
| `skins.opposition.text` | כבר חסם רכב של ח״כ מהאופוזיציה. היום: רחוב שלם. | | 904 | md-blocks-cars |
| `copy.blockedText` | {name} תקוע בחסימה. לא נספר בהצבעה {sec} שניות. | | 1104 | game fiction (the partner) |
| `copy.aloneText` | חסם את ההפגנה. הפעם אף שר שלך לא עבר שם. | 40 | 824 | |
| `copy.endText` (toast) | החסימה התפזרה. {name} חזר להצבעה. | 45 | 904 | fits `stage.toast` in 2 lines |
| `copy.ticker` | מרדכי דוד חוסם את החוסמים. השר תקוע באמצע. | 42 | 840 | md-blocks-cars, md-kaplan-method; ≤ 45 ideal |

**Rules the copy keeps:**
- **No quote marks, anywhere.** His argument is reported speech ("לדבריו"). He has no [Q] fact and gets no quote.
- **No invented factual claims about him.** Every line about him restates a fact: he blocks, he gave the Kaplan
  rationale, he has the youth-HQ job. The partner stuck in traffic is plainly game fiction, the same kind as
  Kaia's nip. The partner is collateral in the traffic, never his target: the copy never says he blocked that
  minister.
- **Dubi only repeats:** the ticker is his newsroom's script line, with no Dubi squawk.
- **"חוסמים"** refers to road blocking (his own framing), never to a group as a punchline. No group term from
  `reviewTerms` is used.
- **Masculine second person** ("שלך"), per the deck.
- **Never used:** "נוער", "ילדים", "צבא", "שירות", "מילואים", "חטופים", any date form of 7.10, his record, his
  family, "מכונת הרעל" (TheMarker's opinion framing is not a fact).

## 9. Motion beats (Animator)

The runtime is frame-by-frame cast strips (`motion/state-graph-cast.md` conventions). He needs **no walk strip**:
he uses the `LeaderWalk` approach, carrying the idle strip with a 1-ap bob every other 125 ms beat.

| # | Beat | Duration | What | Event marker |
|---|---|---|---|---|
| 1 | Walk-in | about 900 ms at the `LeaderWalk` pace (4 bobs/s), from off-canvas right to the mark x ≈ 150; Sine.Out, last beat flat | Idle strip carried, facing screen-left, phone down | `mdEnter` on the first visible frame |
| 2 | Plant | `block` strip, 8 f @ 14 fps (571 ms), entered at f1 | A side-step onto the mark, arms swing out wide, the right hand brings the phone up to selfie height | `mdBlock` on f5 (arms fully out) |
| 3 | Hold | 20 s minus beats 1-2 and 4-5 (about 17 s) | `blockHold` loop, 4 f @ 6 fps: arms out, mouth open/close as if he's live-streaming, the phone jiggles 1 ap, 2 blinks per loop | none (no loop audio beyond a light bed) |
| 4 | Release | `block` played reversed, 8 f @ 14 fps | Arms come down, phone lowered | `mdRelease` on the first frame |
| 5 | Walk-out | about 900 ms, Sine.In, back off-canvas right | Idle strip carried | `mdExit` when fully off |

**Timing rule:** beat 4 starts at `leftSec = 1.5` (1.5 s before `eventEnd`), so he is gone about when the
partner returns and the end toast appears.

**The crowd's reaction.** The crowd is baked into the background and cannot move. Its reaction is an optional
overlay, `md_crowd_phones`:
- 3-4 tiny phone screens (2×3 ap, `white` with a `paper` edge) rise above the right group's heads 400 ms after
  `mdBlock` (2 frames: up, glint);
- they stay up for the hold (the crowd films him back), and drop on `mdRelease`.

It's everyone filming everyone, with no confrontation. If the overlay isn't drawn, nothing else changes.

**Never:** a push, a shove, a raised fist, the crowd surging, him touching a protester or a barrier, running,
or any shake or impact FX. He stands. The only "action" is the arms-out pose.

**9.3 Layering:** crowd and barrier (background) < him < the money sources on the ground rows < the leader < FX
and toasts. He never overlaps the leader's hit box. The developer and UX confirm against R17 slot placement
on the SE (375×667).

**9.4 Reduced motion:** there is no walk. He fades in over 150 ms directly in the hold pose, with the phone loop
frozen on f0 and no crowd phones, and fades out at `eventEnd`.

## 10. Sprite brief (2D Artist)

**Ref:** `scratchpad/refs/mordechai-david.png` (Bar's caricature: an orange cap, an orange T-shirt, dark jeans,
dark sneakers, a short beard, facing screen-left 3/4). Render it down through the cast pipeline like the other
cast (`creative-pack/art/showcase/src/cast.py` landmarks, d3 and d2).
- **Scale:** the generic cast rig's density, but **shorter on stage than the leader**: at most 75% of the
  leader's idle height, so the leader stays the focal figure. He stands at the barrier line, mid-ground.
  Suggested 36-40 ap tall, feet at art y 216.
- **Prop: a phone, and only a phone** (he films himself). A short selfie stick is optional. **No** flag, sign,
  party logo, text on the shirt or cap, megaphone, or anything that could read as a weapon.
- **Palette:** his orange is the ref's. Check it against Balfour's `orange` lit windows and lamp glow: he must not
  merge into the lamp cone. A 1 px `outline` rim does it.

| Strip | Frames @ fps | Pose | Notes |
|---|---|---|---|
| `idle` | 20 @ 10 | The ref pose: weight on one leg, arms relaxed, phone in the right hand at his side | The generic rig: breath-down f5-f15, blink f9-f11. f0 is the rest pose. The walk carries this strip |
| `block` | 8 @ 14 | f0 = idle.f0 → f1-f3 side-step and plant → f4-f5 arms swing out to a wide T (palms open, flat, not fists), the right hand holds the phone up at head height facing himself → f6-f7 settle | Last frame = `blockHold.f0`. Entered at f1 (cast seam rule). Played reversed for the release |
| `blockHold` | 4 @ 6 | Arms out, mouth closed → open → closed → open (talking to his camera); the phone 1 ap up on f2 | Loops seamlessly into itself. The silhouette must read as "arms out, in the way" at 1× |
| `avatar` | 1 (32×32) | Head crop with the cap, for the card | A neutral `rim` ring (no react colour: he isn't a partner) |
| `md_crowd_phones` (optional) | 2 | Phone glints for the right crowd group (§9) | An environment overlay, positioned over the art's right group |

**Readability test:** at 1× on the SE, his arms-out silhouette must read against the night crowd. The crowd is
`night` bodies and `skin_sh` heads; his orange shirt carries the contrast.

## 11. Audio cue intent (Audio Director picks the sounds)

| Event | Intent |
|---|---|
| `mdEnter` | Light sneaker steps on asphalt, panned right. Not comic, not menacing |
| `mdBlock` | A short "phone starts recording" tick (a generic UI tick, **no** real-app sound), plus a small crowd murmur swell |
| Hold | A low, ducked crowd murmur bed, under the music. No chanting (no words, and no slogans of any side) |
| `mdRelease` / `mdExit` | The murmur settles; steps out |
| End toast | The standard toast cue |

**Never:** sirens, police radio, crowd screaming, or anything from the military category.

## 12. Facts, sources and guardrails

All facts were **opened and read** on 2026-09-30 from the design worktree, unlike earlier sessions, which saw
search results only. "Search-result only" marks the URLs that were not opened.

| Ref | id | Claim (public `aboutHe`) | Sources |
|---|---|---|---|
| 73 | `md-blocks-cars` (F) | בנובמבר 2025 עמד פעיל הימין מרדכי דוד מול רכבו של ח״כ גלעד קריב ביציאה מהפגנה, ובינואר 2026 חסם עם אחרים את רכבו של נשיא בית המשפט העליון בדימוס אהרן ברק בחניון בתל אביב. | [Walla 21.11.2025](https://www.walla.co.il/news/politics/3795837) (opened) · [ToI 29.1.2026](https://www.timesofisrael.com/cops-reportedly-probing-right-wing-agitator-who-blocked-ex-judge-aharon-baraks-car/) (opened) · [Ynet](https://www.ynet.co.il/news/article/by7bp9hgwe) (opened) · [N12](https://www.mako.co.il/news-law/e9f61eb3e8509910/Article-fec913f2c91aa91026.htm) (search-result only) |
| 74 | `md-kaplan-method` (F, reported) | בפברואר 2026 טען מרדכי דוד, לפי הדיווח, שכמו שבמחאת קפלן נחסמו כבישים, כך הוא עושה במחאה שלו. | [Ynet 1.2.2026](https://www.ynet.co.il/news/article/rjbo0qtlzl) (opened) · [C14](https://www.c14.co.il/article/1374337) (opened; opinion, context only) |
| 75 | `md-otzma-youth` (F, **corrected**) | בסוף אוגוסט 2026 הודיע מרדכי דוד שהוא מצטרף לעוצמה יהודית, ולפי הדיווחים יקבל תפקיד בשכר במטה הצעירים של המפלגה בקמפיין. | [Kipa 31.8.2026](https://kipa.co.il/%D7%97%D7%93%D7%A9%D7%95%D7%AA/1230632-0) (opened) · [Srugim](https://www.srugim.co.il/101009894-%D7%9E%D7%A8%D7%93%D7%9B%D7%99-%D7%93%D7%95%D7%93-%D7%9E%D7%A6%D7%98%D7%A8%D7%A3-%D7%9C%D7%9E%D7%A4%D7%9C%D7%92%D7%AA-%D7%94%D7%99%D7%9E%D7%99%D7%9F) (opened) · [C14](https://www.c14.co.il/article/1686564) (search-result only) |
| 47 | `eisenkot-quote` (Q) | **Stays not used, now for good.** | [Ynet](https://www.ynet.co.il/news/article/bkxbhdqife) (opened) · Maariv, Walla, N12, Israel Hayom (search-result only) |

- **The "co-chair" correction:** the brief said "co-chair of Otzma's youth campaign HQ from 1 Sep 2026". The
  sources say "a paid role in the youth HQ", announced 31 Aug 2026. The game says only what the sources say.
- **Why the Eisenkot exchange stays out:** it happened on a beach in Aug 2026. David's question was about the war
  weeks after October 7 and a hostage deal "at any price". Eisenkot's answer was "go serve in the army and come
  back to me". The question is in the `oct7-hostages` category and the answer in `military`: two red lines at
  once. Its URL is now recorded (`urlNeeded` is cleared), and its `notUsedWhy` says so.
- **Deliberately out, and never to be used** (all public, all tempting, all outside the guardrails):
  - his 2021 conviction;
  - the restraining orders (Alon-Lee Green, Kariv's home, journalist Guy Peleg);
  - the Shin Bet warnings;
  - that minors are in his group ("brothers for justice" / "נוער");
  - that his daughter drove in the Barak incident;
  - the "Khamenei" remark about Barak;
  - the hostage-protest confrontations;
  - the Lucy Aharish home protest;
  - the Attorney General restaurant incident (18 Sep 2026);
  - reports that he pays activists;
  - TheMarker's "poison machine" framing.

  These are recorded in `md-blocks-cars._guardrail`.

## 13. Changes in this change-set

- **`design/facts.json`:**
  - +3 facts (refs 73-75), each `notUsed: true`, `launchWith: "mordechaiDavid"`, with `aboutHe` linted and
    `usedIn` filled;
  - fact 47 gets its URLs and a hardened `notUsedWhy`.
- **`design/redlines.json`:**
  - "מרדכי דוד" **stays** in `private-people-and-off-cast`, with the category's `why` rewritten as narrowed, not
    lifted;
  - four scoped `allow` entries: `mordechai` (his event's strings: path segment `.mordechai.`) and
    `facts.md-blocks-cars`, `facts.md-kaplan-method`, `facts.md-otzma-youth`. Anywhere else (a ticker, story
    card, kit, chat, UI string or share text) his name still fails the build.
- **`design/content.json`:** `events[]` + `mordechai` (the §4 fields, the §8 copy, `_note`, `_guardrail`).
  `flags.mordechaiDavid` stays `false` (§7.5).
- **`HANDOFF.md`:** Bar's legal reads + Mordechai David; the "old flags" line updated.
- **Lint:** `node design/sim/content-lint.mjs --strict`: no errors.

## 14. For Bar

- **D1, the legal read (pre-launch):** his three facts and the four copy lines above. He is a private citizen
  who is newsworthy, with a paid party role. The satire rests on documented public conduct only.
- **D2, the dose:** Balfour only, so he shows once per save at most (§6 gives how often). If you want him more
  often, the option is the Knesset with a "portable crowd" (three protester sprites walk in first; about 3 new
  strips plus one beat). We don't recommend it for launch.
- **D3, the orange:** his ref's orange cap and shirt are close to Otzma's campaign orange. Keep it (it is his
  real look, and the ref is yours), or tone it to a neutral colour to keep party colours off the stage (the
  style guide excludes party colours from key art and the UI, not from caricature clothing). We recommend keeping
  it: it is what makes him recognisable, and the game never names the colour.
