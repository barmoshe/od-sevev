# Leaders v3: a storyline and real gameplay for every leader

Bar, 2026-10-01: "אני רוצה לשפר את ה־storyline והמשחקיות של כל אחד מהמנהיגים… אל תתמקד רק בביבי".
Bar's answers to the planning questions:
- each leader gets an **active ability** on top of today's rule;
- **±10%** round length stays (equal footing, spec §4);
- it ships **in phases**, each one deployed.

Assets: `creative-pack/art/briefs/leaders-v3-gpt.md`.

## What was wrong
- **Only Liberman (לא אשב) and Golan (איחוד) make the player decide anything.** The other rules run on
  their own:
  - Bennett's self card fires on a timer;
  - Ben Gvir: threats ×0.5;
  - Smotrich: VAT ×1.18 and demands −10%;
  - Deri: a buff for each paid demand;
  - Eisenkot: crits removed.
- **Bibi has far more than everyone else:** 5 beats, 5 unique events, the court walk-off, the aide drop
  and pardon desk, Sara, 5 extra spins and 8 extra trophies. Every other leader is about 103 strings of
  reskin.
- **The story is text after the election, unrelated to play.** All 7 non-Bibi first beats used the "61 X…"
  template, so a player who switches leader each round saw only that template.
- **On the press day (no taps) every leader but Bibi stayed on stage and bounced on taps** that did
  nothing.

## Phase 1 (this change)
1. **The busy moment, for every leader.**
   - On the hazard day the leader zips off like Bibi does: `BigBanana.wants_court` is no longer Bibi
     only.
   - What holds the mark is `LeaderUi.stage_skin`: Bibi's hat (`court`), a press podium (`podium`, 6
     leaders) or Deri's corridor bench (`bench`). The podium and bench are drawn by `PressDesk` until
     the GPT art lands (brief B1, B2).
   - A tap wiggles what's on the mark and never plays the leader's strip.
   - The toast is the leader's own line, `kit.hazard.tapPaused`, for example "סמוטריץ׳ מחפש תקציב לתגובה.
     להקשות אין תקציב."
2. **Story v3.**
   - Every leader has 6 beats; Bibi has 7.
   - The 7 templated beat 1s are rewritten.
   - Beats 5–6 come from true 2025–26 arcs (14 new facts in `design/facts.json`).
   - A beat can wait for the player's own deed (`kit.story.when {"3": {stat, atLeast}}`, read by
     `Story.beat_unlocked`): `Story.flash` shows the first unseen beat whose `when` holds.
     - Bennett 3, the big pledge: after 20 flips (crits).
     - Ben Gvir 3, his own group: after 20 threats (crits).
     - Liberman 3, the document: after 5 declines.
     - Golan 3, approved again: after a merge.
   - Every non-Bibi leader has an encore of their own (`kit.story.encore`).
   - Main books the card once per election (`stats.flashedAt`) and hands it to `FlashCard.card`, because
     the next call would move on.
3. **Leftover copy.**
   - Deri's words no longer lean on coffee: the tap is "סגירה", the frenzy banner "טורבו במסדרון!" and
     Dubi says "נסגור!". The cup stays only as the prop.
   - Smotrich's crit is "קיצוץ!"; his trophy is "יש כסף. לא לך."; the demand tag is "לא להם · −10%";
     Dubi's buy squawk is "תקציב!".
   - Eisenkot's story no longer repeats "ישר! ישר!".

## The arcs (what each leader's new beats say, all sourced)

| Leader | New beats | Facts |
|---|---|---|
| Bibi | 6 החנינה (the president shelved it and called for plea talks); 7 השמורים (8 of the top 30 slots reserved) | pardon-request, pardon-shelved, likud-primaries-2026 |
| Bennett | 1 העט חזר; 5 רק ציוניות + "לא כרגע" with Eisenkot; 6 מקום שלישי (Lapid's offer) | bennett-zionist-only, bennett-eisenkot-not-now, lapid-third-spot |
| Ben Gvir | 1 resigned in January, back in March (no reason given: red line); 6 מסגרת עקרונות (the High Court deadline that failed) | bengvir-resign-return, bengvir-hcj-framework |
| Liberman | 1 שיתהפך העולם; 5 ראש הממשלה הבא + no merger with ישר; 6 תכלס | liberman-next-pm, liberman-no-yashar-merger, liberman-decide |
| Eisenkot | 1 the ruler; 5 שולחן עגול (invited the heads to coordinate); 6 לבד, ישר (ran alone) | eisenkot-invites-opposition, lists-filed-2026 |
| Smotrich | 1 יש כסף. לא לך.; 5 בדקה ה־90 (the budget hours before automatic dissolution); 6 חיזור (Winter ran alone) | budget-2026-deadline, smotrich-winter |
| Deri | 2 now has a joke turn; 5 חוק דרעי 2; 6 חצי בפנים (resigned and stayed; one minister reversed it for a day) | deri-law-2, shas-half-in |
| Golan | 1 two parties on the table; 5 שמאלה (the Tinder line, reported); 6 איחוד גדול (Lapid not interested) | golan-tinder, golan-big-merger |

**Red lines kept:**
- no reason for the 2025 resignations (Ben Gvir: a red-line topic; Shas: the draft law);
- no community named in the budget beat;
- no poll numbers;
- reported speech without quote marks.

## Phase 2: active abilities
- **One engine and one chip.**
  - `game/scripts/sim/ability.gd` (`Ability`) reads `leaders[].rule.active {type, numbers, copy, src}`.
  - `game/scripts/ui/ability_chip.gd` sits at the stage's bottom right, below the toast lane, at x 572 or more, right of the
    leader's hit box, so rapid taps never land on it.
  - It shows the leader's verb, a number (cooldown, countdown, or clauses 3/5) and a bar.
  - The leader card in the picker shows `copy.desc`.
- **A "quiet" partner** (`Coalition.quiet` / `is_quiet`): busy elsewhere for X seconds. Their open demand
  doesn't age or count down, and they post no new one. It never removes seats.

| Leader | Ability | Numbers |
|---|---|---|
| Bibi | **תתאחדו** (once per round): Ben Gvir and Smotrich refuse each other and both go quiet | 60 s (fact bengvir-no-merger) |
| Bennett | **לחתום / להפוך**: sign = the pledge (gate +1, then base); flip = the gate drops now, cash and headlines, no base | cooldown 150 s, cash = bps × 20, headlines +8 |
| Ben Gvir | **אני פורש**: walks off the stage (the walk-off, a cardboard box on the mark), income ×0.6 and no taps; **חזרתי**: demands −40%, patience full, taps ×1.3 | out 20 s, cooldown 150 s, buff 30 s |
| Liberman | **המסמך**: every "לא אשב" writes a clause; 5 clauses = +5% to the round's base | nothing to press |
| Eisenkot | **שולחן עגול** ("לכנס"): every partner quiet, open demands −20% | 30 s, cooldown 150 s |
| Smotrich | **תקציב בדקה ה־90**: a budget every 3 min for 60 s at bps × 20. Approve: +3%; in the last 10 s: +5%. Not approved: the gate +1 for 30 s | not on an open gate or the court day |
| Deri | **למסדרון**: the oldest demand waits, taps ×1.2 | quiet 45 s, buff 15 s, cooldown 60 s |
| Golan | **שמאלה**: a unity offer from Netanyahu every 2.5 min for 20 s; a swipe = +2% base | — |

- **Bench:** `PacingSim._play_ability` plays a median player: Bennett signs on a closed gate and never
  flips; Ben Gvir, Eisenkot and Deri act when a demand is open; Smotrich approves what he can afford;
  Golan swipes.
- **Bench (2026-10-01):** the median player's median first election over seeds 1–9, before → after the
  abilities. ±10% is about ±48 s.

| Leader | Before | After | Change |
|---|---|---|---|
| Bibi | 8:01 | 8:07 | +1% |
| Bennett | 8:03 | 7:19 (cooldown 300 s; 7:07 at 150 s was out of range) | −9% |
| Ben Gvir | 8:19 | 8:55 | +7% |
| Liberman | 7:51 | 7:58 | +1.5% |
| Eisenkot | 8:10 | 8:42 | +6.5% |
| Smotrich | 8:06 | 8:05 | 0% |
| Deri | 8:05 | 8:20 | +3% |
| Golan | 7:59 | 8:28 (worst 11:50) | +6% |

## Phase 3: shared events, the art, and Bar's playtest fixes (deployed 2026-10-01, `c726a5e`)
- **Unity offer** (3a): Netanyahu's offer for Bennett, Liberman and Eisenkot (`leaderSelect.unityOffer`);
  the chip reads "לא" while it is open; a tap refuses it (+1% base and the leader's line).
- **The countdown to 27.10** (3b): two `priorityOnce` lines per leader, a countdown until 22.10 and a
  negotiation line (Bibi's in `listPolitics` + bibiOnly). `Ambient.pick` shows the first unseen one
  once a round (`leader_round.tickOnce`), which also wakes `calendar.negotiation.opener` (cal08).
- **Ability trophies**: `kit.abilityTrophy` (abilityUses: Bibi 5, Liberman 5, Deri 25, Golan 15,
  the rest 10). **Dubi** squawks `kit.dubi.squawks.ability` on a use (every 20 s at most).
- **The GPT art**: each ability plays the leader's pose (`rule.active.poses`, `BigBanana.flash_pose`);
  the chip shows the cut icon; PressDesk draws the podium, bench and box; Kaia is a sprite.
- **Mordechai David by leader** (Bar): he never blocks Ben Gvir (taps ×3 while he stands), Bibi (×2) or
  Smotrich (he just stands there): `effect.byLeader`. Everyone else: approach 2 s, block 6 s, exit 2 s.
- **The chip** moved to the top-right sky; toasts dock in the lane while it is up.
- **Gantz** is on the picker as a joke (`leaderSelect.decoy`): the first time he stands in for הפתעה as a
  regular tile; picking him gets a line about the threshold, the cell turns back into הפתעה, pick again.

**Bench (2026-10-01):** the median player's median first election over seeds 1-9 (Mordechai's roll
seeded since this phase). ±10% is about ±48 s.

| Leader | Phase 2 | Phase 3 |
|---|---|---|
| Bibi | 8:07 | 8:17 |
| Bennett | 7:19 | 7:27 |
| Ben Gvir | 8:55 | 8:55 |
| Liberman | 7:58 | 8:21 |
| Eisenkot | 8:42 | 8:36 |
| Smotrich | 8:05 | 8:03 |
| Deri | 8:20 | 8:31 |
| Golan | 8:28 | 8:15 |

## Next
- Four rigged props wait for a hook: `prop_round-table`, `prop_pledge-scroll`, `prop_budget-book`,
  `prop_clause-doc`.
- Ben Gvir's walk-out pose is not played (the court walk ends any pose at once).
