# leader-select-spec: every round, a different leader

`mechanic-spec` + `content-inventory` + `progression-curve` delta for "עוד סבב".

- **Owner:** Game Designer.
- **Date:** 2026-09-29.
- **Status:** design complete; content ready for **all 8 leaders** (wave 2 landed 2026-09-29); **pending engine** (nothing here runs in the current build).
- **Consumers:**
  - Game Developer (sim, engine, views);
  - UX Designer;
  - Technical Artist, 2D Artist, Animator;
  - Audio Director.
- **Inputs:**
  - Bar, 2026-09-29: "There's too much emphasis on Bibi. In each round you are a different politician heading a different party. At the start of every round you're asked which character to pick."
  - `creative-pack/pitch.md` (§4-§11), `brief.md`, `brief-round2.md`.
  - `design/content.json`, `facts.json`, `redlines.json`, `progression-curve.md` §0.
  - `game/scripts/sim/README.md`, `game/assets/sprites/CONTRACT.md`, `ux/rtl-map.md`, `ux/ftue.md`.
- **Data:** `design/content.json` → `leaderSelect` (shared config, cast profiles, Bibi-only lists) and `leaders[]` (one kit per leader). Both blocks are additive. The current engine ignores them, so the Bibi-only game keeps building and passing its tests (270/270 on this change) until the picker ships.
- **Lint:** `node design/sim/content-lint.mjs` §9 checks every kit, reference, lineup and leader ticker line. It reports 0 errors and 0 warnings in `--strict` mode.

---

## 0. The decisions on one page

| # | Decision | Why |
|---|---|---|
| D1 | **Launch roster of 8, 4 per side:** ביבי (הליכוד), בן גביר (עוצמה יהודית), סמוטריץ׳ (הציונות הדתית), דרעי (ש״ס) · בנט (ביחד), אייזנקוט (ישר), ליברמן (ישראל ביתנו), גולן (הדמוקרטים) | Equal opportunity you can count. Every leader has art. The four left out each carry a risk or a factual problem (§2). |
| D2 | **לפיד is not a pick: he is No. 2 on Bennett's list "ביחד"** (Apr 2026, fact `beyachad-list`), and he plays inside Bennett's round as a list-mate who can't walk out | Making him head of a party would be a false fact in the game's own frame. |
| D3 | **Content shipped in two waves.** Wave 1: ביבי (the shipped game re-keyed), בנט, בן גביר, ליברמן (2 per side). Wave 2 (done): אייזנקוט, סמוטריץ׳, דרעי, גולן | The brief's "too large for one pass" clause. The picker can ship with any leader whose kit passes the lint; all 8 do. |
| D4 | **The picker comes before the first tap**, and it is the title screen. Picking a face is the gesture that unlocks audio, so it costs 0 extra taps. After every election, the picker follows the election card. | "At the start of every round." A face grid needs no reading; the choice is the first laugh. §3. |
| D5 | **Equal footing: every number is shared.** That means own seats, the economy, spin prices, the coalition slot numbers, the hazard and the gate. Leaders differ in **words, art and one signature rule** each. | If one leader got more seats or faster money, the game would be a poll or an endorsement (red line). It also keeps one balance bench and the 7-9 min first election for everyone. §4. |
| D6 | **Bloc logic:** the other cast members become partners or rival cards, relative to who you play. A lineup deals shared **coalition slots** to people. Outside Bibi's round the slots are **reshuffled every round**. | The coalition stays the core system for every leader. Reshuffled seats can't read as polls. §5.5. |
| D7 | **The court is Bibi's. Everyone else gets "the press".** Same meter and numbers, relabelled "כותרות / יום תחקיר", plus a per-leader postponement gag. The aide drop and the pardon desk stay Bibi-only. | The trial is his real record. A generic press heat is fair to everyone and invents nothing. §5.6. |
| D8 | **Dubi is the office's parrot, not Bibi's.** At each pick he learns the new leader's talking points ("דובי למד מסרים חדשים."). | The narrator carries across leaders, and the joke (a spokesperson who repeats whatever he's told) gets sharper. §5.7. |
| D9 | **The base (הבסיס) is shared across leaders.** A leader you didn't play last round adds **+10% to this round's base** ("פנים חדשות"). | A per-leader base would punish switching, and players would stick to one leader forever. The small bonus rewards variety without forcing it. §6. |
| D10 | **No leader is locked, and the picker order is shuffled.** | Locking a politician or pinning one first reads as ranking them. |
| D11 | **No leader motifs.** The HaTikva-derived leitmotif stays non-partisan. | Tying the anthem to one party would be a partisan use of it. §9.5. |

---

## 1. Goals and the player model (F1)

- **Ownership:** "I'm playing *my* guy this round." Self-determination: meaningful choice and identity. The pick also makes the share card personal ("שרדתי 6 סבבים בתור ליברמן").
- **Replay variety:** the prestige loop is already the joke ("עוד סבב"). A new face each round turns *reset fatigue* into *what does this guy's round look like?*: novelty on a fixed loop, Lazzaro's easy fun.
- **Roasts everyone:** every leader's round mocks that leader in the first person, and their rivals in the ticker and on cards. Nobody is exempt, and no leader is stronger.
- **Keep the verb learnable in seconds:** each leader keeps the same verbs (tap, buy, pay, catch, call an election). Only the *nouns* change: the prop, the crit, the sources, the excuses.
- **Shaky claim, named:** a first-time player facing 8 faces may stall. Mitigations:
  - the "הפתעה" tile;
  - no text to read;
  - the 5 s undo.

  The bench can't measure this; UX should watch the first playtest recording.

---

## 2. Roster

### 2.1 Launch 8

| Leader | Party | Side | Art (idle + react) | Signature (the one rule) | Tap prop · verb · crit | Wave |
|---|---|---|---|---|---|---|
| ביבי | הליכוד | coalition | `bibi` (idle, tap, crit, hat and rabbit tracks) | **המשפט**: the court, postpone, aide drop, pardon desk (shipped; `rule` names it for the picker and T4, no new knob) | hat · שליפה · ארנב | 1 (shipped) |
| בנט | ביחד (לפיד No. 2) | opposition | `bennett` (react `flip`, event `whoosh`) | **ההתחייבות**: his own pledge card fires at 2× weight. The gate goes to 62 for 45 s, then the pledge flips and adds +1 base (reuses the shipped `pledge` effect). | pen · חתימה · היפוך | 1 |
| בן גביר | עוצמה יהודית | coalition | `ben-gvir` (react, event `shout`) | **לוח הזמנים**: nobody out-threatens the threatener. Partners' `threatChance` ×0.5. | phone · העברה · איום | 1 |
| ליברמן | ישראל ביתנו | opposition | `liberman` (react, event `no`) | **לא יושב**: dismiss an open member demand for free. Cooldown 90 s; never on an ultimatum. His lineup excludes the partners he says he won't sit with (fact `liberman-wont-sit`). | chair · סירוב · לא מוחלט | 1 |
| אייזנקוט | ישר | opposition | `eisenkot` (react, `land`) | **ישר**: no crits at all; every tap is paid the crits' average up front, × (1 + c × (critMult − 1)): ×1.18 base, ×1.63 with slot E. EV-neutral by construction (was a flat ×2, +69% tap value) | ruler · יישור קו · (none: tap 7 shows "בלי קסמים. רק ישר.") | 2 |
| סמוטריץ׳ | הציונות הדתית | coalition | `smotrich` (react, `shout`) | **שר האוצר**: VAT ×1.18 moves from his partner trait onto him; "אין כסף" makes every demand price ×0.9 (the p_deal knob `demandDiscountPct` 10) | calculator · חישוב · אין כסף! (not העברה: Ben Gvir's verb) | 2 |
| דרעי | ש״ס | coalition | `deri` (react, `land`) | **המסדרון** (was ידידי, Ben Gvir's tic; renamed 2026-10-01): walked-out partners rejoin at 1.0× instead of 1.5× (`rejoinMult` override); each paid demand gives a 30 s ☕ tap buff ×1.2 (the spin effect `tapBuff`, refreshed, not stacked) | coffee (prop) · מסדרון · השקופים | 2 |
| גולן | הדמוקרטים | opposition | `golan` (react, `land`) | **איחוד**: two members of 60 s+ may merge (seats and upkeep summed, one demand stream at the higher price, a walkout takes both; 2 per round, 120 s apart; never the stand-in or an open ultimatum) | stapler · איחוד · עוד איחוד | 2 |

**Why this 8:**
- **Balanced 4/4** across the government and opposition blocs.
- **Every one has a clean, sourced, politics-only joke** that becomes a rule.
- **Every one has art** (idle + react at d 3/d 2).
- **Each reuses a react anim whose event is already an audio/FX hook:** whoosh, shout, no, land.
- **Wave 1 is 2+2 and has the three most distinct rules:**
  - Bennett adds a gate twist;
  - Ben Gvir changes the chat's pressure;
  - Liberman adds a new chat verb and the tightest coalition.
- **Wave 2's rules are all built from existing effect types,** except Golan's merge (already requested for his card in `events.golan.copy.designerEffect`).

### 2.2 Not at launch (Bar's calls, `leaderSelect.later`)

| Who | Why not now | What would unlock it |
|---|---|---|
| **גנץ** | His best joke is as everyone's stand-in (the 99% rotation), and he stays that in every lineup. As a lead his public story is war-adjacent. | Bar's call. A version where Bibi is *his* 99% rotation partner is funny and safe. |
| **עבאס** | Playing the Ra'am leader raises the group-as-punchline risk (redlines `reviewTerms`). His current joke targets Bibi's slogan, not him. | A human review of his kit, and Bar's call. He stays a partner in Bennett's round (fact `raam-2021`). |
| **יהדות התורה (גולדקנופף / גפני)** | One pick for a two-faction list needs a decision on who heads it. The price-tag joke works best as partners. | Bar's call on the head. |
| **לפיד** | Not a party head in 2026 (D2) | If "ביחד" splits, he becomes a pick with the "איפה הכסף?" audit rule. |

---

## 3. The pick moment

### 3.1 When

| Moment | Screen | Default | Exits |
|---|---|---|---|
| **First launch** (no save) | `LEADER_PICK` **replaces** `TITLE`. The wordmark goes on top and the tiles below. Picking = the audio-unlock gesture (ux/screen-graph `TITLE` rule). | none; "הפתעה" for the undecided | A tile pick starts round 1 at once. For **5 s**, until the first tap, a small "להחליף" chip reopens the picker. |
| **After each election** | `EVOLUTION` → `EVOLVE_TX` → **`LEADER_PICK`** → round N+1 | "עוד סבב עם {short}" (the last leader) as the big button | a tile, the big button, or Esc/back (= same leader). **Never a dead end.** |
| **Returning player, mid-round** | no picker | — | — |
| **Save migrated from v3** (§6.3) | no picker until the next election | Bibi keeps the current round | — |

**Why before the first tap, not after the first minute:**
- The TITLE state already needs one gesture (WebAudio), and a face tap is that gesture.
- A player who meets the game as Bibi for 7 minutes learns that this is "the Bibi game", which is the exact perception Bar wants to end.
- The risk is a decision before the verb. It is contained because the tiles are faces (no reading) and the verb is the same for every leader.
- UX's FTUE clocks start at the hand-off. The pick happens before it, so no FTUE timer changes.

**The round clock doesn't run while the picker is open.** `playtimeSec` only ticks in the economy step, the Suitcase timer is paused (modal rule), and away income is unaffected.

### 3.2 The tiles
- One tile per leader in `leaderSelect.roster` whose kit passes the lint (`shipRule`). Wave 1 shows 4, plus הפתעה.
- A tile has:
  - the leader's d 2 idle frame (or the 32 avatar at ×3 when space is short);
  - `short`;
  - `party`;
  - the one-line `pick.blurb` (the reading-text cut, optional to read).
- **Order is shuffled on every open** (D10). "עוד סבב עם {short}" is a separate button, so a repeat pick keeps muscle memory.
- **הפתעה** picks uniformly among the tiles. It shows `randomLine` "דובי בחר. הוא יחזור על זה."
- **No numbers anywhere on the picker** (no seats, no polls). It is safe in the 23.10-27.10 blackout as is.
- **Footer** (`copy.disclaimer`): "כולם מקבלים אותו משחק. אף אחד לא מנצח." This is the equal-footing promise in one line, and it matches the brief's "Nobody wins this game."

### 3.3 On pick
1. Dubi flies to the stage and says `copy.dubiLearned` "דובי למד מסרים חדשים.", then the leader's `pick.line` (their `firsttap` squawk, doubled).
2. The leader walks in to the Magician's feet point. The old leader, if any, walks out (Animator, §9.3).
3. **Fresh face:** if `leader != leaderHistory[-1]`, a toast shows `copy.freshFace` "פנים חדשות: +10% לבסיס בסבב הבחירות הזה", and `basePctThisRound += freshFaceBasePct`.
4. **FTUE, first time after election 1:** the toast `copy.ftueAfterFirstElection` "בכל סבב בחירות אפשר להחליף ראש רשימה. הבסיס נשאר." (UX: `ftue.lp` flag).

### 3.4 What carries over between rounds (and across leaders)
| Carries | Resets |
|---|---|
| the base (הבסיס), allTimeEarned, evolutions (the global round count), trophies, perks (ההסכם הקואליציוני), stats, settings, album, s06-style persistent buys, `aideDrops` (a Bibi-only −3% that stays on the shared base; the confirm says so) | everything `prestige.resets` already lists, **plus the leader** (re-picked). Suspicion resets to the round's floor for any leader: the floor is "the cases don't close". For non-Bibi leaders the meter just says כותרות. |

---

## 4. Equal footing (the numbers every leader shares)

**Shared and unchanged:**
- **Tap:** base 1, crit 2% ×10, first crit at tap 7 ×4.
- **The 8 source tiers:** cost, bps, growth, shady, suspicionPerBuy, slots.
- **Spin prices and effects** (slots A-I).
- **The Suitcase:** timings and outcome weights.
- **Coalition:** gate 61, own seats, demand pricing, ultimatums, the slot template.
- **Investigation:** meter, floor, court or press day ×0.5, postpone 5% × 2ⁿ, cooldowns.
- **Everything else:** base payout, perks, milestones, the Cottage Index, the calendar and blackout.

**Different per leader:**
- words;
- the stage figure, tap prop and crit anim;
- source and spin names;
- the coalition lineup (who, not how much);
- rival cards;
- one rule.

The leaders' rules are deliberately small: each moves round length by ≤ ±10% by prediction (§7), and the bench confirms it.

---

## 5. The per-leader kit (what is per leader vs shared)

### 5.0 Content volume per leader (wave 1 measured by the lint)

| Part | Per leader | Shared by all | Wave 1 actual |
|---|---|---|---|
| Identity + picker | 5 strings (name, short, party, blurb, line) | picker copy 10 | ✓ |
| One rule | 1 rule (+0-3 strings) | — | ✓ |
| Tap | 7 strings (verb, plural, crit, plural, frenzy banner) + 4 headlines | — | ✓ |
| Sources t4-t8 | 5 × (name, flavor, levelUp, first-owned headline) = 20 | tiers 1-3 as shipped | ✓ |
| Spins | 8 skins × (name, flavor) = 16 | slot F shared (s12) | ✓ |
| Hazard | postpone verb + 6 excuses | the press skin (13 strings) | ✓ |
| Dubi | 4 squawks + 6 talking points | — | ✓ |
| Suitcase | 4 lines | — | ✓ |
| Story | 3 titles + 3 beats (≈10 lines) | the encore | ✓ |
| Ticker | 12 lines | rival ticker 8, leak screenshots 2 | ✓ |
| Trophy | 1 | 2 global | ✓ |
| Cast profiles | a partner profile (6-8 strings) and/or a rival card (2) for each cast member the lineups need | — | 9 profiles, 4 cards |
| **Total** | **≈100 strings + 3-5 facts per leader** | ≈75 shared | **502 new Hebrew strings, 12 new facts** |

The lint counts: bennett 102, bengvir 103, liberman 104 strings; wave 2: eisenkot 104, smotrich 104, deri 103, golan 106; plus shared profiles, cards, leak, rival ticker and picker copy.

### 5.1 The rule
- One `rule` per leader: `{id, name, text, effect}`.
- The effect uses an existing effect type, or one named, one-line sim knob. Wave 1 needs exactly two new knobs:
  - `partnerThreatMult` (Ben Gvir);
  - `declineDemand` (Liberman).
- Bennett's rule reuses `pledge` as a self-event: `selfEvent {event: "bennett", weightMult 2, firstAfterPlaySec 240}`.
- Wave 2 adds two knobs, `straightTaps` (Eisenkot) and `mergeMembers` (Golan, `Coalition.merge`), and two leader-level uses of existing ones: `leaderEffects` (Smotrich's `producerMult` + `demandDiscountPct`; Deri's `coalition.rejoinMult` override + `onDemandPaid: tapBuff`). Each rule's `_note` in `content.json` is the sim contract.
- `rule.text` is the one sentence the picker's long-press and T4 show.

### 5.2 Tap: prop + verb + crit
- **Tap:**
  - Bibi keeps his `tap` anim (hat, coins at `hatMouth`).
  - Every other leader plays **idle**, and the tap drives the **prop** (a d 1 sprite like the hat, drawn at the leader's new `propMouth` point).
  - The prop squashes on the pointer-down frame, and coins spawn from its mouth.
  - Same feel numbers as the hat (feel-spec).
- **Crit:** the leader's existing **react anim** (`kit.tap.critAnim`), with its event as the crit cue. The floater word is `critName` (Bibi: the rabbit prop plus "ארנב").
- The tap never waits for the react: taps during a react still register (prop only), exactly like Bibi's taps during `crit`.
- **Words:** `verb` / `verbPlural` replace "שליפה/שליפות" in the HUD (HUD_BPS_POUR, buff chips, the dossier stats). `frenzyBanner` replaces "טורבו בכובע!".

### 5.3 Money sources
- Tiers 1-3 are **shared** (משלם המסים, ההייטקיסט, המע״מ): every government collects them.
- Tiers 4-8 keep Bibi's numbers, with a **per-leader skin** in `kit.sources.t4..t8` = {name, flavor, levelUp, src, firstOwned headline}.
- **Sprites:** Bibi keeps his five. Every other leader uses a **shared generic set** (`leaderSelect.sourceTiers.genericSprites`):
  - t4 `source_donor` (new);
  - t5 `source_funds` (new);
  - t6 `source_advisers` (a palette swap of qatari);
  - t7 `source_poison` (reused: a phone rack reads as any digital campaign);
  - t8 `source_checkbook` (reused).

  So **all 7 other leaders cost 2 new drawings + 1 recolour.**
- `shady` means "draws heat". For non-Bibi leaders the heat is press criticism, not a criminal suspicion. Every source skin that names a real matter carries its `src`.

### 5.4 Spins
- **Slots** (`leaderSelect.spinSlots`): A s01 tapAdd, B s02 tapBuff, C s03 offlineMult, D s04 heat ×0.75, E s11 crit chance, F s12 freeze (**shared as-is**), G s13 +10% base this round (no follow-up invoice), H s06 ×1.5 income, I s05 base per rival card.
- A leader skins A-E and G-I (8 skins). The price, effect, unlock and kind come from the base spin.
- **Bibi-only spins** (their facts are his): s07, s09, s10, s14, s15.
- **s08 "השלט"** is Karhi's line, so it is on the shelf in any round where Karhi is a member (Bibi's and Ben Gvir's).
- **Icons:** a skin may name its own; otherwise it uses the generic `spin_slot_<slot>` (8 new icons shared by all leaders; F keeps s12's).

### 5.5 Coalition, bloc logic, rivals

**Slots** (`leaderSelect.coalitionSlots`):
- S1-S5 are the early slots, SK the round-2 early slot, L1-L8 the late slots (money and time gated), and SI the stand-in.
- Each slot holds seats, upkeep, demand weight, threat chance and unlock, **copied from the Bibi partner who holds it today**. The lint proves Bibi's lineup equals `content.partners`.

**Lineup** (`leaders[].coalition.lineup`):
- A list of `{id, slot, traits?, lines?}`.
- The person brings the *traits* (Goldknopf's growth, Gafni's abstain, Regev's ceremony, Deri's no-leave, Abbas's and Liberman's excludes, Gantz's stand-in, and so on) and the *voice*. The slot brings the *numbers*.
- A lineup entry may override a trait (Gotliv in Ben Gvir's round has no transfer and can't leave) or a line.

**Rules** (`lineupRules`, linted):
- S1 (the FTUE C1 partner, variant 0 first), S3 and a stand-in are required.
- At least 2 late slots.
- Seat capacity ≥ 40.
- Outside Bibi's round, **the non-S1 slots are dealt at random each round** (seeded by the round). Bibi's lineup ships unshuffled (tuned, and the C1 beats name Ben Gvir).

**Cast profiles** (`leaderSelect.partnerProfiles`):
- New partner voices: ביבי, לפיד, ליברמן, גולן, אייזנקוט, בנט.
- Four **generic MKs** (the no-photo stand-in, never real people): "ח״כ שעבר צד", "ח״כית מתלבטת", "ח״כ עם הצעה", "ח״כ שחזר הביתה" (added 2026-09-29 for Liberman's SK seat, §7.2). They fill slots a bloc can't. The joke of defection culture is equal-opportunity.

**Rival cards** (`leaders[].coalition.rivals`):
- The shipped opposition cards, plus new `cardProfiles` for the coalition side:
  - ביבי: seatDrain, "מציע רוטציה…";
  - בן גביר: a brawl in *your* group;
  - סמוטריץ׳: noCrit, "אין כסף";
  - דרעי: seatDrain, coffee.
- A rival never appears in the lineup.
- **The leak event** uses `leakRight` (the coalition's screenshot) when the player's side is the opposition.

**Wave-1 lineups:**

| Leader | S1 (C1) | Others | Excluded / notes | Rivals |
|---|---|---|---|---|
| ביבי | בן גביר | as shipped (15) | as shipped | לפיד, אייזנקוט, ליברמן, בנט, גולן |
| בנט | ליברמן | לפיד (list-mate, can't leave), אייזנקוט, גולן, ח״כ עם הצעה, עבאס (thanks: "כמו ב־2021"), ח״כית מתלבטת, גפני, ח״כ שעבר צד, גנץ | Liberman's excludes create a real choice: keep him, or let him walk and take עבאס + גפני | ביבי, בן גביר, סמוטריץ׳, דרעי |
| בן גביר | ביבי ("תעביר לליכוד. אין כלום, רק תעביר.") | גוטליב (list No. 2, no transfer), סמוטריץ׳, רגב, אמסלם, קרעי, גולדקנופף, גפני, דרעי, אלמוג ("הוסרתי מהקבוצות שלך"), גנץ | עבאס out (his own excludes) | the shipped five |
| ליברמן | בנט | לפיד, גולן, אייזנקוט, ח״כ עם הצעה (L4), ח״כית מתלבטת, ח״כ שעבר צד, ח״כ שחזר הביתה (SK, from round 2), גנץ | ביבי, דרעי, גולדקנופף, גפני, עבאס (his stated line) | ביבי, בן גביר, סמוטריץ׳, דרעי |

**Wave-2 lineups:**

| Leader | S1 (C1) | Others | Excluded / notes | Rivals |
|---|---|---|---|---|
| אייזנקוט | בנט | לפיד, גולן, ליברמן, ח״כ עם הצעה, ח״כית מתלבטת, גפני, עבאס, ח״כ שעבר צד, גנץ | Liberman's excludes: the same keep-him-or-take-Abbas-and-Gafni choice as Bennett's round | ביבי, בן גביר, סמוטריץ׳, דרעי (card_smotrich's noCrit suspends his straight bonus) |
| סמוטריץ׳ | ביבי | רגב, בן גביר, לוין, אמסלם, קרעי, גולדקנופף, גוטליב, גפני, דרעי, מאי גולן, גנץ | עבאס out (his excludes); Karhi is a member, so s08 is on the shelf; the brawl pair needs §10.1's any-two fix | the shipped five |
| דרעי | ביבי | רגב, סמוטריץ׳, לוין, אמסלם, קרעי, גולדקנופף, גוטליב, גפני, בן גביר (his own L6), מאי גולן, גנץ | עבאס out (his excludes) | the shipped five |
| גולן | אייזנקוט (his ×1.25 tap trait runs from C1) | לפיד, בנט, ליברמן, ח״כ עם הצעה, ח״כית מתלבטת, גפני, עבאס, ח״כ שעבר צד, גנץ | as Eisenkot's round; the merge rule wants several mid-size members | ביבי, בן גביר, סמוטריץ׳, דרעי |

**Seat capacity:** Bibi 57, Bennett 50, Ben Gvir 49, Liberman 46 (44 in round 1: SK opens after election 1; was 42 before the §7.2 levers), Eisenkot 50, Smotrich 51, Deri 51, Golan 50. Liberman's is the tightest on purpose, and his decline pill pays for it (§7.3).

### 5.6 Hazard: the court (Bibi) vs the press (everyone else)
- **Same Investigation module and numbers.** For non-Bibi leaders:
  - the meter word is **כותרות**;
  - court day is **יום תחקיר**;
  - testify is **להגיב**;
  - the chip is **תחקיר** (`hazardSkins.press`, 13 strings).
- **Per leader:** `postponeVerb` + 6 `excuses`, each one sentence longer (the lint checks the growth):
  - Bennett's pledges to respond tomorrow;
  - Ben Gvir's escalating quit threat;
  - Liberman won't sit in the studio;
  - Eisenkot will answer straight, after a check of the check;
  - Smotrich has no budget for a response;
  - Deri invites the story to coffee (then a lawyer joins);
  - Golan answers once the answer has merged with the next one.
- **Bibi-only:** the aide drop (it is Qatargate), the pardon desk, the DOHA sticker, the trial excuses and the courthouse ticker.
- `court.floorPerRoundPct` applies to every leader.

### 5.7 Dubi
- Per leader: `dubi.squawks` {firsttap, buy, elect, miss} and `talkingPoints` (≥ 4, for word salad).
- Dubi only repeats. His squawks are slogans, list names or the leader's catchphrase, never an invented quote. `dubi-mic` is shared.

### 5.8 Ticker
- Per leader: 12 lines in `kit.ticker` + 4 kit headlines + 5 first-owned source headlines.
- Shared: every ambient line not in `bibiOnly.ambient` / `ambientPolitics`.
- `rivalTicker` (8) roasts coalition-side rivals in opposition rounds. A line shows when its `rival` is a rival card this round.
- Ticker rules (≤ 60 chars, quote rule, unique id, poll_like) are linted for all of these.

### 5.9 The Suitcase
- **Shared object and numbers.** The DOHA sticker is Bibi's only. Others get `suitcase_plain`.
- `aide` and `laundry` outcomes are Bibi-only, and cash absorbs their weight.
- Per leader: 4 lines (catch cash / frenzy / tap frenzy / miss).

### 5.10 Eras and story
- **The 4 stages stay shared and follow the global election count** (one art set). Their names stay (the Knesset, the courthouse and Washington are everyone's; Balfour is the PM's residence).
- **Story:** the flash after an election plays the beat of the leader **just played**, indexed by that leader's own election count (`leaders.<id>.elections`). Bibi has 5 beats; wave-1 leaders have 3 each; then the shared encore.
- The archive in T4 lists flashes by round with the leader's name.

---

## 6. Prestige, stats, trophies, saves

### 6.1 Prestige
- The base is shared (D9).
- Fresh face: +`freshFaceBasePct` (10) to `basePctThisRound` when the leader differs from last round's (§3.3).
- The election card shows the leader's name in the title: "סבב בחירות מס׳ {n} · {short}".

### 6.2 Stats and trophies
- **Per leader, persistent:** `leaders.<id> = {rounds, elections, taps, crits, declines, merges, bestRunSec, playSec}` (`merges`: Golan's trophy). The dossier (T4) gets a "ראשי רשימה" section: one row per played leader.
- **Global stats:** `leaderSwitches` (+1 when a pick differs from the last leader).
- **Trophies:**
  - The shipped 40 stay. Those in `bibiOnly.trophies` can only be earned in Bibi's round; `neutralCopy` rewrites the tap and perk ones to neutral words.
  - **Per leader:** one each (`kit.trophy`, trigger `leaderStat`).
  - **Global:** "כולם היו ראש ממשלה" (a round with every leader) and "פנים חדשות" (10 switches).

### 6.3 Save v4 (co-spec with the Game Developer's `save-schema`)
```
leader: "<id>"                 # the round's leader; fixed for the round
leaderPickPending: bool        # true from EVOLVE_TX until a pick; on load → show the picker
leaderHistory: ["<id>", …]     # last 10 picks; fresh face reads [-1]
leaders: {<id>: {rounds, elections, taps, crits, declines, merges, bestRunSec, playSec}}
seatDeal: {<partnerId>: "<slot>"}   # this round's shuffled slots (so a reload can't reroll)
stats.leaderSwitches
```

**Migration v3 → v4** (additive):
- `leader = "bibi"`, `leaderHistory = ["bibi"]`, `leaderPickPending = false`.
- `leaders.bibi` is seeded as `{rounds: evolutions + 1, elections: evolutions, taps: tapsLifetime, crits: critsLifetime}`; the rest start at 0.
- The current round stays Bibi's. The next election shows the picker and the FTUE line.

**Guards:**
- An unknown `leader` id at load (a roster change) falls back to `defaultLeader`, with `leaderPickPending = true` if the round hasn't started (runTaps 0), else it stays that leader's round.
- A v4 file loaded by a v3 build is kept aside (the existing SaveStore rule).

---

## 7. Tunables and pacing

### 7.1 Tunables (all in `content.json`)
| Key | Value | Range to tune |
|---|---|---|
| `leaderSelect.pick.freshFaceBasePct` | 10 | 0-20 (0 turns it off) |
| `leaderSelect.pick.undoSec` | 5 | 3-8 |
| `leaderSelect.lineupRules.minSeatCapacity` / `minLateSlots` | 40 / 2 | lint floor |
| Bennett `rule.effect.weightMult` / `firstAfterPlaySec` | 2 / 240 | 1-3 / 180-300 |
| Ben Gvir `rule.effect.mult` | 0.5 | 0.3-0.7 |
| Liberman `rule.effect.cooldownSec` | 90 | 60-150 |
| Lapid partner `onPay.suspicion` | 2 | 0-4 |
| Eisenkot partner `effects[tapMult]` | 1.25 | 1.1-1.5 |
| Eisenkot `rule.effect` | EV conversion (×1.18 base) | fixed by the formula; a flat bonus on top only if his bench median > 9:00 |
| Smotrich `rule.effect.demandDiscountPct` / VAT `mult` | 10 / 1.18 | 0-15 / 1.18 (the joke) |
| Deri `rule.effect.coalition.rejoinMult` / `onDemandPaid.mult`, `durationSec` | 1.0 / 1.2, 30 | 1.0-1.25 / 1.1-1.3, 20-45 |
| Golan `rule.effect.minMemberSec` / `maxPerRound` / `cooldownSec` | 60 / 2 / 120 | 45-90 / 1-3 / 90-180 |

### 7.2 Pacing targets (the bench stays authoritative, progression-curve §0)
- Every leader must pass **S0-S7 on its own**. That includes the median first election at 7:00-9:00 and the median rounds 1-5 at ≥ 3:00 each.
- `tools/balance.sh --leader <id>` runs `PacingSim` with that leader's lineup, rule and shuffle (seeds 1-9).
- **A mixed session** (a random leader per round) must also pass S5-S7.
- **Predictions** (paper; the bench decides):

| Leader | First election (median) | Why |
|---|---|---|
| ביבי | 8:01 (measured) | unchanged |
| בנט | 7:45-8:30 | early capacity like Bibi's; the pledge gate +1 for 45 s is small; Liberman's excludes cost late seats until he walks |
| בן גביר | 7:15-8:00 | fewer threats mean fewer walkouts; capacity 49 |
| ליברמן | 8:15-9:00 (**risk**) | capacity 42 and no Haredi or Abbas late seats; the decline pill saves money. **Lever if > 9:00:** add the L3 slot (a 1-seat generic MK) and/or give `mk_undecided` L4. **Never** raise his own seats (D5). **Applied (2026-09-29), see §7.2.1.** |
| אייזנקוט | 7:50-8:30 | the same money as everyone (EV-neutral taps); Bennett's lineup shape; Eisenkot loses only the tap-7 ×4 (4 ₪ once) |
| סמוטריץ׳ | 7:30-8:15 | VAT ×1.18 from t 0 and 10% cheaper demands; capacity 51 |
| דרעי | 7:30-8:15 | cheap rejoins remove the walkout penalty; the ☕ buff is taps only |
| גולן | 7:40-8:20 | merges cut the number of demands, a merged walkout costs double; capacity 50 |

### 7.2.1 Measured (tools/balance.sh, 2026-09-29, Game Designer)

Median player, first election, median of seeds 1-9 (one seat deal per seed); the spread is the deal's.

| Leader | First election (median) | Seeds 1-9 range | Engaged / casual / idle | Median hour (S5-S7) |
|---|---|---|---|---|
| ביבי | 8:01 | 7:34-8:25 | the shipped gates (test_session.gd) | pass |
| בנט | 8:08 | 7:29-10:30 | 7:12 / 8:06 / 10:41 | pass |
| בן גביר | 8:19 | 7:45-10:05 | 7:18 / 8:14 / 10:27 | pass |
| ליברמן | 7:51 | 7:16-8:32 | 6:59 / 8:02 / 9:54 | pass (was S5 fail: round 2 9:09 > round 1 7:09) |
| אייזנקוט | 8:50 | 7:47-10:07 | 7:39 / 9:00 / 11:34 | pass (casual on the 9:00 edge) |
| סמוטריץ׳ | 8:06 | 7:38-9:01 | 7:11 / 8:02 / 10:16 | pass |
| דרעי | 8:05 | 7:21-8:24 | 7:11 / 7:56 / 10:13 | pass |
| גולן | 8:30 | 7:29-9:40 | 7:51 / 8:34 / 11:18 | pass |

**Liberman's levers, both applied:**
1. **Round 1 (game-developer sim):** `mk_offer` on L4 instead of S5. With S5 his round-1 gate waited for L6's 360K (median 8:55, casual 9:13).
2. **Rounds 2+ (Game Designer):** a fourth generic MK, "ח״כ שחזר הביתה" (`mk_returner`), on SK.
   - His lineup had no seat that unlocks after election 1, so every later round waited for L6: own 28 + 40 without L6 is < 61.
   - The median hour's round 2 ran longer than round 1 (7:09, then 9:09; S5 failed).
   - SK (2 seats, the round-2 early slot the coalition leaders already hold) closes 61 with L1 + L4, like the other lineups.
   - Round 1 is untouched (SK is locked until election 1), and his own seats never changed (D5).
   - Better than the spec's L3 lever: L3 is 1 seat, one short of 61 without L6.

**Watch:** Eisenkot's median (8:50) and casual (9:00) sit on the edge. Bennett's and Ben Gvir's worst deals run past 10:00 (a late-slot-heavy early deal). If the picker playtest shows long first rounds for them, the lever is to keep S2/S3 out of the shuffle (a fixed early core); it is not a number change.

### 7.2.2 Bennett's trap: a pill never trades seats down (Game Designer, 2026-09-30)

**Found by** `picker_web`, whose Bennett round never held 61. The bench's attentive player hides
the trap: before paying a join, it checks who would walk (`PacingSim._join_costs_seats`).

**The trap.** Liberman (S1, 12 seats) "won't sit with" Gafni and Abbas. Their join demands came
while he sat. Paying one threw him out on the spot, with no rejoin pill. He could only come back
once both were gone, and after that any pill of theirs threw him out again. In the tighter deals
neither side of the lineup reaches 61 without a fast player's own seats.

A player who simply pays every pill never held 61 in 5 of 9 of Bennett's deals within 45 minutes.
Every other leader needed 8:42-10:21 median for the same player. The slow browser driver never got
there in those deals within an hour; every other leader took it 19-29 minutes.

**The rules** (sim `Coalition._excluded` / `_on_joined`, content):
1. **Won't-sit-with holds both ways, and the bigger side comes first.** A partner's weight is its
   seats plus half its abstentions.
   - The smaller side does not ask to join while the bigger sits. Its open offer (a join demand or
     a rejoin pill) closes when the bigger comes in.
   - The bigger side may ask, or come back, while the smaller sits. Paying it sends the smaller out.
     This is "Abbas leaves when Ben Gvir returns", as shipped.

   So a pill never trades seats down. The lineup's choice is still there, and it is made in the
   open: Liberman walks (a visible ultimatum), Gafni asks, and Liberman's rejoin pill stays in the
   thread next to Gafni's join demand. The player pays one of them.
2. **Liberman no longer excludes Abbas.** They sat in one coalition in June 2021 (fact
   `raam-2021`; Abbas's own line in Bennett's round is "כמו ב־2021"). His sourced line
   (`liberman-wont-sit`) is about Netanyahu. His refusal of the Haredi parties (Gafni, Goldknopf,
   Deri) stays.

Bibi's round is unchanged: Abbas never asks while Ben Gvir sits, and Ben Gvir's return sends him
out. The one new detail is that Abbas's own rejoin pill closes when Ben Gvir returns. Before, paying
it seated them together.

**Measured (median of seeds 1-9):**

| | ביבי | בנט | בן גביר | ליברמן | אייזנקוט | סמוטריץ׳ | דרעי | גולן |
|---|---|---|---|---|---|---|---|---|
| Median player, before | 8:01 | 8:08 (worst 10:30) | 8:19 | 7:51 | 8:50 | 8:06 | 8:05 | 8:30 |
| Median player, after | 8:01 | **8:03** (worst 10:11) | 8:19 | 7:51 | **8:10** | 8:06 | 8:05 | **7:59** |
| Pays every pill, before | 8:46 | **never ×5** | 10:21 | 8:42 | 9:44 (1 never) | 9:14 | 9:25 | 9:24 (worst 24:26) |
| Pays every pill, after | 8:46 | **9:58** (worst 13:11) | 10:21 | 8:42 | **9:44** (worst 11:29) | 9:14 | 9:25 | **8:52** (worst 13:55) |

Only the three change-bloc rounds move (Bennett, Eisenkot and Golan: Liberman with Gafni and Abbas).
Eisenkot leaves the 9:00 edge that §7.2.1 watched: casual 9:00 becomes 8:29. The slow driver-like
player (0.1 taps/s, the priciest card every 72 s, the chat every 49 s) now reaches Bennett's gate
in 19:36-24:30 on all 9 deals (before: never in 3 of 5), in line with the other leaders.

### 7.3 Dominant strategies and edge cases
| # | Case | Closing rule |
|---|---|---|
| L1 | **Always the same leader** | Legitimate. No penalty; the fresh-face bonus is only +10% of one round's base. |
| L2 | **Alternate two leaders for fresh face** | Allowed and legible. It is the cheapest variety incentive, and the bonus never compounds (per round, not per streak). |
| L3 | **Pick the "easiest" leader** | Numbers are equal; the rules are ≤ ±10% by bench. If a leader's median leaves 7-9 min, tune its rule, not the economy. |
| L4 | **Reroll the seat shuffle by re-picking** | The deal is made at pick and saved (`seatDeal`). Undo (≤ 5 s, before tap 1) keeps the same seed. |
| L5 | **Liberman decline spam** | 90 s cooldown; member demands only (never a join demand, never an ultimatum). The partner's next demand arrives on the normal gap. |
| L6 | **Ben Gvir never pays** | Threats halve, but demands still come and upkeep still drains; an unpaid demand still escalates after `patienceSec`. |
| L7 | **Bennett's gate 62** | The gate only rises while his own pledge card is up (45 s), and it never fires when seats ≥ 61 already. The +1 base pays for it. |
| L8 | **A partner who is also a leader** (ביבי, בן גביר, בנט, ליברמן) | A lineup never holds the player (linted). Gotliv's transfer target is the player in Ben Gvir's round, so the lineup turns it off. Abbas's excludes keep him out of Ben Gvir's round by themselves. |
| L9 | **Blackout 23.10-27.10** | The picker shows no numbers. Partner cards with `pollLike` hide as today. Shuffled seats are game values, never polls. |
| L10 | **Aide drops then switching** | The −3% is on the shared base and persists; the aide drop only exists in Bibi's round. |
| L11 | **Karhi's s08 line** | Available whenever Karhi is a member. It resets with the round as today. |
| L12 | **The gate slips under the open election card** | "The vote stops the clock" (§7.4). |
| L13 | **A pill that trades seats down** (Gafni's join throwing Liberman out) | Won't-sit-with holds both ways, bigger side first (§7.2.2). |

### 7.4 The vote stops the clock (Game Designer, 2026-09-30)

**The issue.** A player reaches 61, taps "עוד סבב!", and reads O3. Before today the round kept
running under the card: an ultimatum ran out, a partner walked, a card fired, and "לפזר את הכנסת"
went grey while the card covered the chat that would have shown why. The browser drivers hit it
at ×10 ("seats dropped under the open election card"), and it is not only a fast-clock artefact.
The bench measured it at ×1 for the median player on every leader, seeds 1-9 (72 first elections),
reading the card with no other input after the gate first opened:

| Time on the card | 3 s | 10 s | 30 s | 60 s |
|---|---|---|---|---|
| The gate fell under it (of 72) | 3 | 6 | 15 | 27 |

Ben Gvir lost it in 4 of 9 deals within 30 s. When the gate opens there is almost always an
ultimatum running (61 of 72 deals), because the last seats come from paying a demand while
another partner is still threatening.

**The rule.** While the election card (O3) is open and not yet confirmed, the round holds:
- No ultimatum counts down or runs out. No demand ages into one.
- No partner joins, and Gotliv's meter stands still.
- No card fires, and every live card's timer stops (the pledge, a seat drain, a nip).
- The court waits.
- The economy holds too: no income, no timed buffs running out, no automation.
- Only the calendar follows the real clock (it is the real date).

The seats the player opened the card with are the seats they vote on. Closing the card ("עוד לא",
✕, the backdrop, Esc, back) resumes everything where it stood. The card can still open without a
majority (E, a stale CTA): it is then a pause with the button disabled, which gains nothing.

**The window before the card** (UX saw the gate slip once between "עוד סבב!" and O3). Three parts
cover it, from the moment the gate opens to the press:
1. **The hold starts at the press.** A finger down on "עוד סבב!" already holds the round
   (`vote_open()` sees the CTA press). The card opens on release, so nothing can move between the
   press and the card.
2. **The finish grace.** On the frame the gate opens, a running ultimatum gets at least
   `ultimatum.finishGraceSec` (10 s) left, once per ultimatum. That is time to see the CTA and
   reach it. It is not a shield: after the 10 s the timer runs out as ever if the vote isn't called,
   and a flapping gate never tops the same ultimatum up again.
3. **The finish line is quiet.** While the gate is open, no card that costs seats fires: the
   brawl's frozen pair, the pledge's raised gate, a seat drain, a lost partner, Kaia
   (`Events.SEAT_COSTS`). The rival Bennett pledge in other leaders' rounds 2+ was the one card
   that could raise the gate at 61.

After these, between the gate opening and the press, only an ultimatum that was already counting
down and had its grace can take a seat. With the median player reading nothing at the gate (bench,
72 first elections), the gate fell within 3 s in 3 of 72 before, and in 0 of 72 after.

**Why this rule.**
- **Fairness.** The card covers the chat. A loss the player cannot see and cannot answer is not a
  decision; it is a tax on reading. Every other timer loss in the game is visible and recoverable
  (pitch §11 Q4); this one was neither.
- **Feel.** The election is the round's climax. The press should be the payoff of the round, not
  a race against a hidden clock. Nothing moving on the card also makes its numbers ("×now ← ×after")
  stable while they are read.
- **No exploit.** Because the money stops as well, holding the card open farms nothing: no income,
  no growth of the pending base, no demand skipped. It is strictly worse than closing the card and
  playing on, and worse than hiding the tab (which still earns the away income).

**Rejected.**
- **Freeze only the politics.** Ultimatums would stop while income ran. An idle player at 61 could
  leave the card open and skip about half the coalition's cost while the pending base grew: a
  dominant AFK strategy.
- **A latch on the gate** (61 counts for N s after it slips, or for as long as the card is open).
  Walkouts would still happen behind the card, so the player would call an election on 55 while the
  HUD reads "מנדטים 55/61". That breaks the gate's one fiction, and a latch that lasts while the card
  is open is the same free farm as above. The finish grace above gives time to the timer, not to
  the gate: the seats stay true.
- **Close the card when the gate slips.** It is honest, but the player still loses the moment to
  something they could not see.
- **Keep the live grey-out** (the status quo). It is the issue itself.

**Per leader.** The rule is leader-neutral, and every rule effect is covered by it. Bench V1
(`test_leaders_balance.gd`): the gate after 30 s on the card, seeds 1-9, with the hold / without it
(the rest of the rules as shipped, finish grace included):

| ביבי | בנט | בן גביר | ליברמן | אייזנקוט | סמוטריץ׳ | דרעי | גולן |
|---|---|---|---|---|---|---|---|
| 9/9 · 8/9 | 9/9 · 6/9 | 9/9 · 5/9 | 9/9 · 8/9 | 9/9 · 8/9 | 9/9 · 8/9 | 9/9 · 7/9 | 9/9 · 7/9 |

- **Liberman** (the tightest lineup): his last seats are often a join demand paid on the edge.
- **Golan:** a merged pair walks out together and costs double. Under the card no ultimatum
  expires, so no merged walkout happens there. The merge itself needs the chat, so it cannot happen
  under the card either.
- **Bennett:** his pledge card raises the gate by 1 while it is up. In his own round it only fires
  below 61 (L7, `seatsBelow`). As a rival card in rounds 2+ of other leaders it had no such guard;
  now no seat-costing card fires while the gate is open, and a pledge already up keeps its timer
  frozen under the card.
- **Ben Gvir** (halved threats; an unpaid demand still escalates) was the worst case without the hold.

**Pacing is unchanged by this rule.** The bench calls the election the moment the gate opens, so
the hold, the grace and the quiet finish line move no median (§7.2.2's lineup fix is what moved
Bennett, Eisenkot and Golan). `test_leaders_balance.gd` V1 now checks every leader and deal:
the gate holds after 30 s on the card, and it prints the no-hold count for contrast.

**Where it lives.**
- The sim: `Politics.tick(ctx.vote)` and `Politics.holds_for_vote`.
- The controller: `main.gd` `vote_open()` (a press on the CTA, or the top overlay being an
  unconfirmed `ElectionCard`), and `_step_economy(…, vote)`.
- The window: `Coalition._finish_grace` (`ultimatum.finishGraceSec`) and `Events.SEAT_COSTS`.
- The browser drivers check it live: `odDev.coal.vote`, and `runSec` and the seats unchanged over
  1.5 s on the card.
- Tests: `test_vote_hold.gd` (sim: the hold, the quiet finish line, the grace) and `test_modals.gd`
  (scene: the card, the CTA press).

**Open for UX (optional).** Nothing on the card says the round is paused. The counter stops moving,
which reads naturally as "the vote". If playtest shows confusion, a muted line under the title
("הספירה עוצרת עד ההצבעה") is the lever. It is a UX string, not a rule change.

---

## 8. What stays Bibi's (`leaderSelect.bibiOnly`)
- **Headlines 9 and ambient 43:** the hat, the rabbit, DOHA, Balfour, the courthouse trial, Washington, the Bibi source lines, "אין כלום".
- **Political ambient 7:** the court phase, the suspicion lines, s13, cal04.
- **Spins:** s07, s09, s10, s14, s15.
- **Suitcase outcomes:** aide, laundry.
- **Events:** pardon, kaia, pinkfront, defector.
- **Trophies 8.**
- **Systems:** the aide drop, the pardon desk, his story, his Dubi, the DOHA sticker, Sara's mark, and the hat, rabbit and sweat tracks.

Everything else is shared. `neutralCopy` holds the neutral wording for shared strings that assume the hat (taps, perks, the tap trophies, p02).

---

## 9. Asks per role

### 9.1 Technical Artist (render-down pipeline)
1. **`propMouth` landmark** on `idle` and on the crit anim for `bennett`, `ben-gvir`, `liberman` (wave 2: `eisenkot`, `smotrich`, `deri`, `golan`). It is the point where the tap prop sits, in the same form as `hatMouth`: a per-frame track, own sprite px per density (d 3 and d 2), and within ½ art px across densities.
   - **Placement:** the prop is held in the screen-left hand at hand height. Where the ref has no visible hand, it goes at the chest line, 6 art px screen-left of the body edge.
2. **`temple` track** for the same characters, so the heat-meter sweat (`view_thermo` "magician-sweat") works for every leader. Optional; without it the sweat is skipped.
3. **`source_advisers`:** a palette swap of `source_qatari`, with the maroon folder → slate grey (the maroon waiver is Qatar-only). Same frames, points, and d 3 + d 2 strips.
4. **Later polish (wave 2):** an 8-frame `tap` anim per leader through the render-down rig (coins event at frame 3, like Bibi's):
   - Bennett: a signing stroke;
   - Ben Gvir: a thumb push on the phone;
   - Liberman: a palm pushing the chair away.

   Until then the prop squash carries the tap.
5. **Budget note:** no new character renders. Wave 1 adds 3 props (d 1, ≈1 KB each) and 2 hand-drawn sources (≈5 KB with icons).

### 9.2 2D Artist
1. **Tap props** (d 1, ≤ 20×20 art px, 2 frames: rest + squash, `mouth` point):
   - `prop_pen`: a fat black pen over a small signed sheet;
   - `prop_phone`: a plain phone with a curved forward arrow on screen, no app marks or colours;
   - `prop_chair`: an empty office chair.
   - Wave 2: `prop_ruler`, `prop_calculator`, `prop_coffee` (the ☕ cup), `prop_stapler`.
2. **Generic sources** (40 art px, d 1, 2-frame idle, 24×24 icon + silhouette):
   - `source_donor`: a faceless figure in a suit with a plain envelope and a pen;
   - `source_funds`: a fat budget binder with a blank tab and coins.
3. **`suitcase_plain`:** the kit suitcase without the DOHA sticker.
4. **`spin_slot_A`…`spin_slot_I` (8 icons: A-E and G-I; F keeps s12's own binder):** generic spin icons at the shipped spin-icon size, one per effect:
   - A: a coin with a plus;
   - B: a stopwatch;
   - C: a moon;
   - D: a meter with a down arrow;
   - E: a star;
   - G: a mic;
   - H: a "×1.5" arrow;
   - I: a card with a plus.
5. **Picker kit:** `pick_tile` (9-slice, selected and pressed states), `pick_random` (a folded ballot slip with a question mark).

### 9.3 Animator
1. **Prop tap:**
   - the prop squashes on the pointer-down frame (the hat's squash timing, feel-spec);
   - coins leave from the prop's `mouth` → the leader's `propMouth`;
   - taps during the react only drive the prop.
2. **Crit:**
   - the react anim plays at its data fps from the crit frame and returns to idle;
   - the floater word is `critName` in the crit tint;
   - the react's event (`whoosh` / `shout` / `no` / `land`) is the crit cue frame.
3. **Picker motion:**
   - tiles idle at low amplitude (reduced motion: static);
   - selection pop is 120 ms;
   - Dubi's fly-in reuses `fly`/`land`.
4. **Leader swap in `EVOLVE_TX`** (≤ 1.5 s budget, input locked): the old leader walks out screen-right on the fade, and the new one walks in to the feet point on the fade-in.

   A new-round start after a pick reuses the fade-in only.

### 9.4 UX Designer
1. **Screen graph:**
   - a new `LEADER_PICK` node: first launch replaces `TITLE`; after elections it follows `EVOLVE_TX`;
   - exits: a tile, the "again" button, or Esc/back = again;
   - the 5 s "להחליף" chip on round 1.
2. **Layout:**
   - 2 columns × 3 rows at wave 1 (4 + הפתעה + the "again" button after round 1); 3×3 at 8 leaders;
   - the tile is ≥ 88 logical on both axes;
   - the blurb uses the reading cut;
   - no numbers.
3. **Strings** (`ui-strings.json`, from `leaderSelect.pick.copy`): PICK_TITLE, PICK_TITLE_AFTER, PICK_AGAIN, PICK_RANDOM, PICK_RANDOM_LINE, PICK_UNDO, PICK_FRESH, PICK_DISCLAIMER, F9_PICK (= `ftueAfterFirstElection`), DUBI_LEARNED. Plus the Liberman pill: CHAT_PILL_DECLINE, CHAT_PILL_DECLINE_CD, CHAT_SYS_DECLINED.
4. **HUD and screens:**
   - the thermometer word per hazard skin;
   - the court card from the skin;
   - `ELECT_TITLE` gains `· {short}`;
   - T4 gets a "ראשי רשימה" stats section;
   - share cards show the round's leader and name;
   - `CHAT_SYS_CREATED` names the leader;
   - the Row A counter is unchanged.
5. **FTUE:**
   - the `ftue.lp` flag for the post-election-1 toast;
   - P0 "tap the hat" becomes "tap the leader" (the same hit rect);
   - H1's squawk is the leader's `firsttap`.
6. **Neutral rewrites** of the UI strings listed in §10.3.

### 9.5 Audio Director
- **No leader motifs** (D11).
- One shared **`leaderPick`** sting (≤ 1 s, from the existing fanfare material).
- **Crit cues** are keyed by the react event: whoosh, shout, no, land. Map them to existing cues where they exist; the tap stays the shared coin cue.
- Dubi's babble already takes any text.
- `leaderSwap` is optional (the walk-out/walk-in); it may be silent.

### 9.6 Game Developer (sim)

In `Politics.install(state, leader)`:
- build the roster from `lineup` + `coalitionSlots` + profiles (merge the person's traits, then the slot's numbers, then the lineup overrides; deal the shuffled slots into `seatDeal`);
- read `firstPartner` from the leader;
- the rivals come from `coalition.rivals` (events or `cardProfiles`);
- `leakRight` applies when `side == opposition`.

New knobs:
- `partnerThreatMult`;
- `declineDemand` (`Coalition.decline(state, seq)`, cooldown, member demands only);
- `selfEvent` (weight × and first-after on a shipped event);
- wave 2: `straightTaps` (crit chance 0, tap × the crits' expected value, a noCrit card suspends it), `mergeMembers` (`Coalition.merge(state, a, b)`), `leaderEffects` (a leader-level list of existing economy effects plus `demandDiscountPct`, a `coalition` config override and an `onDemandPaid` spin effect).

Filters:
- `Spins`: the shelf = skins over the slot base spins, minus `bibiOnly.upgrades`, plus s08 when Karhi is a member.
- Golden outcomes: filter by `bibiOnly.goldenOutcomes` (renormalize).
- `Investigation`: the copy comes from the hazard skin; the aide drop and pardon are gated to Bibi.
- `Story`: the per-leader beat index; the ambient filter uses `bibiOnly` + the leader ticker + `rivalTicker`.
- `Meta`: `leaderStat`, `leadersPlayedAll`, `leaderSwitches`.

Save v4 (§6.3). `PacingSim` gets a `leader` param and a `mixed` mode.

### 9.7 Game Developer (engine/views)
The checklist is §10.

---

## 10. Replacement plan: every place the build assumes Bibi is "you"

Tick each one when the picker lands. File:line as of e8f636d.

### 10.1 Engine and views
- [x] `ui/big_banana.gd:84`: **Done (game-developer engine, 2026-09-29):** `BigBanana.set_leader(LeaderUi.art(), LeaderUi.tap())`: the round's figure, only its strips resident; every leader now has a `tap` anim (CONTRACT §4c), so a tap plays it and a loose prop (pen, phone, ruler, chair, stapler) is drawn at `propMouth` and squashes on the pointer-down frame; baked props (hat, calculator, cup) draw none; the crit plays `kit.tap.critAnim`; coins leave the prop's `mouth`, else the track.
  - The hero id comes from `Content.data().hero.char` (default "bibi"); it should be `leaders[leader].art`.
  - With no `tap` anim, play idle and drive the prop (§5.2).
  - The crit anim is `kit.tap.critAnim`.
  - `hatMouth` → `propMouth` (fallback: a fixed offset until the TA lands it).
- [x] `ui/prop_fx.gd:3,36`: `prop_hat` / `prop_rabbit` are Bibi's. For other leaders, spawn coins from the leader's prop and skip the rabbit. **Done (game-developer engine, 2026-09-29):** coins spawn at `BigBanana.mouth_point()`; the rabbit only fires on Bibi's crit event. A leader's react event bursts the crit coins.
- [x] `ui/floaters.gd`: the crit floater label → `critName`. **Done (game-developer engine, 2026-09-29):** a non-Bibi crit adds the `critName` floater (main.gd `_handle_tap`); Eisenkot's tap 7 shows `rule.copy.tap7` with his react.
- [x] `ui/title_view.gd`: TITLE becomes `LEADER_PICK` on first launch (§3.1). **Done (game-developer engine, 2026-09-29):** `ui/views/view_pick.gd` (PickView, rtl-map §8) replaces it on a fresh game and after RESET; the title lines are not drawn when leader select is active (D26).
- [x] `ui/ftue.gd:14-17`: P0 targets the leader; H1 shows the leader's `firsttap` squawk. **Done (game-developer engine, 2026-09-29):** P0 keeps the leader's hit (the pulse also lights the prop); H1 / H1L say `LeaderUi.firsttap()`.
- [x] `main.gd:198-201`: the brawl is started with the hard-coded pair amsalem/smotrich. It should use any two members (or keep that pair only if both are members). **Done (game-developer engine, 2026-09-29):** the dev brawl (`_dev_chat`) keeps the pair only when both are in the lineup, else any two members.
- [x] `main.gd:552,911,985,1457,1466,2092`: the Magician's hit and feet points. Geometry only; keep it, and rename optionally. **Done (game-developer engine, 2026-09-29):** kept (geometry).
- [x] `main.gd` / `ui/overlays.gd`: after `EVOLVE_TX`, open `LEADER_PICK` and then start the round. The election card title includes `short`. **Done (game-developer engine, 2026-09-29):** one rule in `_check_pick`: whenever `Leaders.pick_pending` and no transition or overlay is up (a new game, O3 → EVOLVE_TX → [O3b], a reload mid-pick, the undo), `mode = "pick"`; the economy is frozen while it is pending. O3 shows `ELECT_LEADER` under `ELECT_TITLE`.
- [x] `ui/views/view_share.gd:255`: `SpriteStrip.resolve("bibi")` → the round's leader; the result card names them. **Done (game-developer engine, 2026-09-29):** the result card draws the round's leader and names them (`LEADER_PICK_PLATE` in the sub-line).
- [x] `ui/views/view_thermo.gd:4,390`: the sweat uses `temple` (Bibi only). Skip it when the leader has none; the meter word comes from the hazard skin. **Done (game-developer engine, 2026-09-29):** every leader has `temple` now, so the sweat stays; the word is `LeaderUi.s` (חשד / כותרות), the hot icon the gavel or `thermo_icon_press`.
- [x] `ui/views/view_court.gd:695`: the court/press card copy comes from the skin. The aide button and pardon row are Bibi-only. **Done (game-developer engine, 2026-09-29):** every card and chip string goes through `LeaderUi.s` (the PRESS_* twins, the kit's postpone verb, prefix and excuses); the chip icon is `chip_icon_press`; the aide button follows `Investigation.can_drop_aide` (court only).
- [x] `ui/views/view_flash.gd:161,177`: titles and beats come from the leader just played (`leaders.<id>.elections`). **Done (game-developer engine, 2026-09-29):** a live flash plays `Story.flash` (the leader just played, their own count); `_show_story_beat` marks its id.
- [x] `ui/views/view_dossier.gd`: add the per-leader stats section; the stat labels use the leader's verb (ST_TAPS, ST_CRITS, ST_ALLTIME). **Done (game-developer engine, 2026-09-29):** "ראשי רשימה" rows (DOS_LEADERS, DOS_LEADER_ROUNDS_*, DOS_LEADER_TAPS in the kit's nouns) once a second leader has played; PRESS_DAYS / the court days by skin; the pardon row only in the court's round; PRESS_REVEAL for K2.
- [x] `ui/views/view_chat.gd`: **Done (game-developer engine, 2026-09-29):** CHAT_SYS_CREATED is second person (UX D32, no {name}); Liberman's "לא יושב" pill under the pay pill (disabled with the seconds in the cooldown); Golan's "לאחד" on the partner card opens the pair prompt (MergeCard; CHAT_SYS_MERGED); the new profiles resolve their `art` (the generic MKs draw `nophoto`).
  - `CHAT_SYS_CREATED` gets `{name}`;
  - add the decline pill (Liberman);
  - avatars for the new profiles (bibi, lapid, liberman, golan, eisenkot, bennett; generics → `nophoto`).
- [x] `ui/diorama.gd`: critter sprites for tiers 4-8 come from the skin (or the generic set); Sara's mark only in Bibi's round. **Done (game-developer engine, 2026-09-29):** tiers 4-8 draw the skin (`LeaderUi.producer_art`: the kit's or the generic set). Sara's mark is not drawn anywhere in the build yet, so there is nothing to gate. **Update 2026-09-30:** Sara's mark is drawn (`ui/sara_mark.gd`, Bar's option B, right of the leader on the Balfour stage) and gated to Bibi's round in `SaraMark.wanted`. **Update 2026-10-01 (Bar):** not on stage the whole round: short visits (9 s), on the S01 bottle-deposit huff and as a cameo every 90 s of Balfour play (first after 45 s).
- [x] `ui/golden.gd`: `suitcase_plain` outside Bibi's round. **Done (game-developer engine, 2026-09-29):**
- [x] `ui/shop.gd`: source and spin names come from the skin; the spin icon falls back to `spin_slot_<slot>`. **Done (game-developer engine, 2026-09-29):** names, flavors and effect lines through `Strings` (the skin first; slots A, B, E use the _LEADER keys); the spin icon is the skin's or `spin_slot_<slot>`.
- [x] `ui/ticker.gd:159`: the court chip label comes from the skin. **Done (game-developer engine, 2026-09-29):** the chip is CourtView's (`LeaderUi.s`).
- [x] `autoload/audio.gd`, `audio/od_audio.gd`: crit cue by react event; `leaderPick`; Dubi's squawk from the leader. **Done (game-developer engine, 2026-09-29):** (engine side) the controller sends `leaderPick` (arg: the leader) on the commit frame and `critCue` (arg: whoosh / shout / no / land) on a leader's react event; the Audio plays a cue by that name when its table has one, else silence. Dubi's first-tap babble is the leader's squawk. The cue tables are the Audio Director's.
- [ ] `sim/economy.gd`, `sim/spins.gd`, `sim/coalition.gd`, `sim/investigation.gd`, `sim/events.gd`, `sim/story.gd`, `sim/meta.gd`, `sim/game_state.gd`, `sim/save_store.gd`, `sim/pacing_sim.gd`: §9.6.

### 10.2 Content (`design/content.json`, applied when the picker ships)
- [ ] Apply `leaderSelect.neutralCopy` (taps, perks p_autotap/p_toolbelt, tap trophies, p02, `golden.miss.dubi`).
- [ ] Flip `notUsed` to false on the 12 facts with `launchWith: "leaderSelect"` (the About page then lists them).
- [x] `hero.char` (the engine default) → driven by `leader`. **Done (game-developer engine, 2026-09-29):** `LeaderUi.art()`; `hero.char` is only the fallback for content without leader select.

### 10.3 UI strings (UX owns `ux/ui-strings.json`; these read "ביבי", the hat or the rabbit today)

| Key | Today | Neutral / per leader |
|---|---|---|
| `HUD_BPS_POUR` | הכסף הולך לשליפה | "הכסף הולך ל{verb}" |
| `BUFF_CHIP_TAPFRENZY` | שליפה ×{mult} | "{verb} ×{mult}" |
| `BANNER_FRENZY` | טורבו בכובע! | `kit.tap.frenzyBanner` |
| `SET_KEYS` | רווח: שליפה | "רווח: הקשה" |
| `EVO_RULE_2` | וגדל עם כל שקל שנשלף בסבב. | "וגדל עם כל שקל שנכנס בסבב הבחירות." |
| `OFF_NOTE_1`, `OFF_NOTE_1_PCT`, `RET_CAP`, `SYS_OFFLINE`, `LOAD_2` | הכובע… | "הקופה…" / "מחממים את הקלפי…" |
| `F1_TAP`, `F1_TAP_IDLE` | כובע נצפה… | the leader's `firstTap` / an idle line per verb |
| `ST_ALLTIME`, `ST_TAPS`, `ST_CRITS`, `DOS_TOTAL` | נשלף מהכובע, שליפות, ארנבים | "סה״כ נכנס לקופה", `verbPlural`, `critPlural` |
| `SPLASH_LOADING` | רגע, ביבי מתלבש… | "רגע, מסדרים את הרשימה…" |
| `CHAT_SYS_CREATED`, `CHAT_SYS_CLEARED` | ביבי יצר / ניקה | `{name}` |
| `COURT_BODY`, `COURT_SUMMONS_BODY` | ביבי בדוכן… | Bibi as is; others from `hazardSkins.press` |
| `SYS_ROTATE_CAP`, `SYS_ERA_PACK_LATE` | ביבי עובד… | "{short} עובד…" (or neutral) |
| `SHARE_TEXT_INVITE` | תורכם להיות ביבי. | "תורכם להקים ממשלה." |
| `DAYS_*` (result card, deep-link toast) | ו־{n} ימי משפט (court days) | **done 2026-09-29:** "ו־{n} ימים בכותרות", {n} = court + press days (`Investigation.hazard_days`) |
| `OG_DESCRIPTION` | שולפים שקלים מהכובע… | "בוחרים ראש רשימה, משלמים לשותפים ודוחים את מה שאפשר. סאטירה על כולם, לא קשורה לאף מפלגה." |
| `OG_IMAGE_ALT` | ביבי בפיקסלים… | describe the new key art (below) |
| spin effect lines `s01`, `s02`, `s07`, `s11` | …לכל שליפה, סיכוי לארנב | "{verb}" / "{critName}" |

**Key art and OG image:** today's shows Bibi with the hat alone. Ask the 2D Artist for a lineup shot (the 4-8 leaders shoulder to shoulder, the ballot box in the middle) before launch.

### 10.4 Docs to refresh
- `HANDOFF.md` ("The player is Netanyahu").
- `creative-pack/pitch.md` §1, §4 (the "Magician" framing).
- `ux/rtl-map.md` §4 (the Magician row → "the leader").
- `motion/state-graph-magician.md` (still valid for Bibi; add the prop-tap graph).
- `game/scripts/sim/README.md` (the install contract).

---

## 11. Content status

**Done** (`design/content.json`, lint 0/0 strict). Wave 2 landed on 2026-09-29; the backlog table below is kept as the record of what it had to cover.
- **Shared:** `leaderSelect` = picker copy, slots, lineup rules, source tiers + generic sprite asks, spin slots, the press skin, the Suitcase rule, `bibiOnly`, `neutralCopy`, 9 partner profiles, 4 rival cards, `leakRight`, `rivalTicker` (8), 2 global trophies.
- **ביבי:** re-keyed; the lineup is proven equal to the shipped partners.
- **בנט, בן גביר, ליברמן:** full kits (≈103 strings each) with lineups and rivals.
- **אייזנקוט, סמוטריץ׳, דרעי, גולן (wave 2):** full kits (lint: 104, 104, 103, 106 strings), lineups and rivals; `contentReady` lists all 8 and `backlog` is empty.
- **Facts, wave 2, 9 new** (`launchWith: "leaderSelect"`, notUsed until ship, aboutHe linted; table in `facts-verification.md`):
  - eisenkot-quit-unity, yashar-founded, yashar-horowitz;
  - smotrich-feiglin, coalition-funds-2025;
  - deri-tax-plea (label F, worded as a plea conviction), deri-law;
  - golan-labor-primary, democrats-merger-2026.

  Reused: yashar, vat-18, liberman-finance-taxes, budget-2026, deri-disqualified, haredi-left-gov, labor-meretz-merger, golan-democrats.
- **Facts (`design/facts.json`), 12 new, all found by search and marked `launchWith: "leaderSelect"` (notUsed until ship; aboutHe written and linted):**
  - beyachad-list
  - rotation-2022
  - bennett-raanana [A]
  - bennett-cyota
  - raam-2021
  - bengvir-ministry-rename
  - otzma-vote-boycott
  - otzma-budget-2025
  - liberman-finance-taxes
  - liberman-2019
  - liberman-wont-sit [Q, Hebrew unverified → reported speech only]
  - liberman-no-minority

**Backlog, wave 2** (per leader: ≈100 strings + 3-5 facts, the same schema, lint-enforced):

| Leader | Must add | Facts to research (never invent; mark unverified and don't use) |
|---|---|---|
| אייזנקוט | full kit; lineup (S1 suggestion: בנט); rivals = the coalition cards; the FTUE tap-7 line for a no-crit leader ("בלי קסמים. רק ישר.") | Yashar's list name (have `yashar`); one money or party fact from 2026 politics only. **Guardrail:** nothing before politics, nothing personal, never bereavement. |
| סמוטריץ׳ | full kit; lineup (S1: ביבי); `card_smotrich` stays for opposition rounds | the RZP + Zehut joint list (8 Sep 2026); his budget/"אין כסף" record; vat-18 and liberman-finance-taxes are on file. **Guardrail:** money only. |
| דרעי | full kit; lineup (S1: ביבי); coffee buff | deri-disqualified and haredi-left-gov are on file; the 2022 tax plea needs a label and wording check. **Guardrail:** the price tag and coffee, never the community. |
| גולן | full kit; lineup (S1: אייזנקוט or בנט); the merge rule (sim) | labor-meretz-merger and golan-democrats are on file. **Guardrail:** politics and mergers only; the Sep 2026 disqualification bid is out. |

Wave 2 also needs partner profiles for סמוטריץ׳'s and דרעי's lineups where missing (all their likely partners exist), and a `card_*` for every wave-2 leader who is a rival in an opposition round (אייזנקוט and גולן have shipped cards; סמוטריץ׳ and דרעי have new ones).

---

## 12. Needs Bar's call
1. **The roster:** confirm the 8, the 4 left out (גנץ / עבאס / יהדות התורה / לפיד), and that Lapid rides inside Bennett's round.
2. **Picker before the first tap** (D4) vs after the first round. My recommendation is before; it is the whole point of the direction.
3. **Fresh-face +10%** (D9): keep it, or set it to 0.
4. **Seat shuffle** for Bibi's lineup too (poll-safety everywhere, at the cost of his tuned C1 beats).
5. **A far-right leader as the protagonist** (בן גביר): the kit is politics-only (threats, budgets, the ministry rename, group chats). Confirm the legal read is the same as for the other leaders.
6. **Key art:** from Bibi-with-hat to a lineup shot (§10.3).
