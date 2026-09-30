# UX merge review, 2026-09-30 (session 4's four slices, merged on `restore-s4`)

**Owner:** UX Designer · **Consumers:** orchestrator (dispatch), Game Developer, 2D Artist, Animator · **Build:** `restore-s4` at `a5963bc`, the strict `build/web` served on :8851. Earlier reviews: `review-2026-09-29.md` (R1-R26), `review-2026-09-30.md` (U1-U16). This one numbers its findings **M1-M8**.

**Reviewed against:** `HANDOFF.md`, "Manual test pass (2026-09-30 …)", items A1-A8, B9-B13, B15 and D19-D22 (B14, the pink signs, is Bar's call and is not reviewed); the after-shots in `ux/manual-test-2026-09-30/fixes/`; the before-shots one folder up; the merged `ux/mobile-first-layout.md` (D51-D61), `ux/rtl-map.md` and `ux/ftue.md`.

## How it was checked

- **The pre-tap shots (`dev2-*`) were regenerated** on the merged build with `node tools/web/pretap_shots.mjs http://127.0.0.1:8851/ ux/manual-test-2026-09-30/fixes` (the defaults: Ben Gvir; 390×844@3, 375×667@2 and 430×932@3). **PRETAP_SHOTS: PASS**, no page errors. They are committed with this review.
- **The orchestrator's `mobile_web.mjs` run** (9 devices, PASS): all 9 steps on all 9 devices, as per-step contact sheets.
- **My own drives** (Playwright, one job at a time), each with `?dev=1`:
  - a Bibi round 1 with 20 taps and a forced election (`odDevElect`), the ceremony, the story card, the picker and a Deri round 2 at 1.3, 4.3 and 9.3 s and after 3 taps, at 390×844@3 and 375×667@2, dumping `odDev.hud` / `odDev.shop` at each step;
  - `pretap_shots.mjs` at 375×548@2 and 390×664@3, for the `hud.toast` and `hud.leaderHit` rects on the short viewports.
- **Evidence crops** for the findings are in `ux/manual-test-2026-09-30/review/`.
- **The after-shots `art-*` and `dev1-*` predate the merge.** They were taken on the slice worktrees, and they still show the old name toast ("ביבי · הליכוד") in the stage-top dock and the old identical "מקור עלום" teasers. Each item below was checked on the merged build (M6).

## Findings

### M1. A toast covers the leader's head on the first screen of a round. Must-fix before redeploy.

- **Where:**
  - **Pre-tap, round 1, at 375×548, 375×667 and 390×664.** Dubi's pick toast ("דובי · דובר הלשכה" / `DUBI_LEARNED`, or `LEADER_PICK_RANDOM_LINE` after הפתעה) sits in the stage-top dock at `_top` y 188, 132 tall. It hides the whole head for about 1.6 s. The measured leader hits are:
    - 375×667: y 188-604;
    - 390×664: y 184-600;
    - 375×548: y 84-500.
  - At 390×844 and taller, the toast overlaps 16 px of the hit (the building's top, the kippah's edge). That is acceptable, but the rule below covers it too.
  - **Round 2's start on the SE:** the fresh toast "פנים חדשות: +10% לבסיס בסבב הבחירות הזה" hides the new leader's head, and Dubi's bubble sits on his torso. The engine shows the fresh toast at the pick itself (`main._on_pick_done`), not at ≈ 4.5 s as rtl-map §8.6 said.
- **Evidence:**
  - `ux/manual-test-2026-09-30/review/m1-pretap-toast-375x548-375x667-390x664-390x844.png`;
  - `ux/manual-test-2026-09-30/fixes/dev2-pretap-undo-375x667.png`;
  - `ux/manual-test-2026-09-30/review/m1-round2-start-375x667.png`.
- **What it breaks:**
  - **HANDOFF A7:** the name plate is gone, but the same failure is back, now caused by the toasts;
  - **`ftue.md` P0:** "the leader is still the one lit, moving object", yet his face is hidden on the first screen after the pick;
  - **the `hud-design` DOG:** the HUD must survive the smallest viewport without obscuring the play field;
  - **my own U9 (`review-2026-09-30.md`),** which put the pre-tap line in the dock "above the leader's head". That was right at 390, wrong on short stages.
- **Orchestrator's question 1:** Dubi's line right after the pick *is* the intended FTUE beat (U9, rtl-map §8.6), and it is the only words before tap 1. Its **placement** is the defect, and yes, it fights A7's "nothing over the leader".
- **Owner:** Game Developer.
- **Fix:** specced as **D62** and **S18** in `mobile-first-layout.md` §5.9 (this review; rtl-map §8.6 and ftue rev 6 follow it). Row B's slot, the old §5.9 proposal, does not clear the head at 375×548, so this uses the lane band instead.
  1. While `run_taps == 0` and nothing is bought, no toast rect may intersect `hud.leaderHit`.
  2. In that state, toasts dock in **the lane band under the leader's feet**, stage-local `Rect2(16, S − 136, cw − 32, 132)`. The leader's and the thermometer's hits end at S − 140, and before tap 1 the lane is free, because the undo chip is in the ticker-slot bar (D54). `_say_pick`'s pre-tap chat toast goes there.
  3. After an election, `LEADER_PICK_FRESH` **waits until the undo chip goes** (5 s, or the first tap or buy), then docks in the lane band. The +10% is only final once the undo is gone, so this is also the honest order.
  4. After the first tap, the dock returns to the stage top.
  5. Add S18 to `mobile_web.mjs` and `pretap_shots.mjs`: sample `hud.toast` every 250 ms from the pick to tap 1, and from round 2's pick to 7 s, and fail on any intersection with `hud.leaderHit`, on all 9 devices.

### M2. A round that starts with under 7.5 ₪ shows a locked card 1 and an empty white pane. Must-fix before redeploy.

- **Where:** the start of round 2 and every later round, at 390×844, 375×667 and 430×932, whenever the player carries less than 7.5 ₪ into the new round.
  - The pane shows the buy-mode row and then the first source as a *locked* priced row ("מקור עלום / יתגלה כשיהיה מספיק", ₪ 15), with no teaser rows. The white field below it is empty: about 40% (375×667) to 65% (430×932) of the pane.
  - **Cause:**
    - `producerReveal` reveals a source at `runBananas ≥ 0.5 × baseCost`, and `runBananas` restarts with the run;
    - the fill (D57) draws only "after the first reveal";
    - D51's "card 1 is up from the pick" is wired to round 1's pre-tap only.
  - My drive, which carried 23 ₪ into round 2, shows card 1 and the teasers correctly. `pretap_shots`, which carried 3 ₪, shows the defect. A player who pays a last demand to reach 61 and votes with an empty purse gets this screen.
- **Evidence:** `ux/manual-test-2026-09-30/fixes/dev2-round2-start-390x844.png`, `…-375x667.png`, `…-430x932.png`.
- **What it breaks:**
  - HANDOFF A2 (content on the first screen after a pick), in every round after the first;
  - `mobile-first-layout.md` §0 rule 4 and D51 (card 1 is up from the pick, so "nothing interactive moves");
  - S8, the dead band. S8 is only checked in round 1, which is why the matrix passed.
- **Owner:** Game Developer. The content value is co-signed by the Game Designer.
- **Fix:**
  1. The first source is revealed at every run start: set `revealAtRunEarned: 0` on `producers[0]` in `design/content.json`, and run `tools/sync_data.sh`.
  2. The teaser fill keys on "card 1 is shown", not on "a source was revealed by money".
  3. `mobile_web.mjs` adds S8 and S15's `hud.card1` check at round 2's start. It already forces an election for other steps; do it with ≤ 5 ₪ in hand.

### M3. Below the hint, the teaser rows still read as a stack of blank forms (B9). Polish.

- **Where:** the pre-tap screen and card 1, at 390×844, 393×852 and 430×932 (4-5 rows below the hint), and at 412×915.
- **Evidence:** `ux/manual-test-2026-09-30/review/m2-teasers-430x932.png`, `ux/manual-test-2026-09-30/fixes/dev2-pretap-390x844.png`.
- **What it breaks:**
  - B9 asked for "one or two, fading down". D57's fade gives 1.0, 0.62 and 0.38, then hits its 0.2 floor at j = 3 (0.62³ = 0.24).
  - From the fourth row on, every slip is identical: the same pale fill and the same outline. The varied silhouettes are too faint to tell apart. The eye reads a grid of empty fields, which is the "filler" B9 named.
  - **Orchestrator's question 2:** the hint row and the first two fading slips achieve B9's intent; the floor rows do not.
- **Owner:** Game Developer.
- **Fix:**
  - For j ≥ 3 (the rows at ≤ 0.24), draw **only the silhouette plate** at 0.2: no slip fill and no slip outline, on the ruled white field.
  - The pane then reads "one hint, two fading slips, then a few faint figures on the sheet".
  - S8 still passes: each plate covers about 11% of its rows' samples, above the band rule's 1.5%.
  - D57 gains one line when this is built.

### M4. The P0 hand points at the leader's head while the pulse is on his prop. Polish.

- **Where:** pre-tap at idle ≥ 9 s, for every leader but Bibi. Seen with Ben Gvir at 390×844.
  - `ftue.gd` points the hand at `ctx.hat`, which `main.gd:1179` sets to `magician_feet() − (0, 380)`: the head, for everyone.
  - The brightness pulse is on the tap object, which for a non-Bibi leader is the prop at `propMouth` (the phone).
  - So the player gets two signifiers on two spots, and the white glove lands on the kippah and forehead, where it reads as a white blob at phone size.
- **Evidence:** `ux/manual-test-2026-09-30/review/m3-hand-on-head-390x844.png`, `ux/manual-test-2026-09-30/fixes/dev2-pretap-390x844.png`.
- **What it breaks:** `ftue.md` P0 (the pulse is on "the hat for Bibi, the prop at `propMouth` for every other leader"; the hand points at that tap object).
- **Owner:** Game Developer.
- **Fix:**
  - Pass the pulse's own point as `ctx.hat`: `big_banana`'s tracked prop point (`propMouth`; Bibi `hatMouth`).
  - Keep the `upleft` hand at its right side.
  - H1's squawk anchor can keep the head point.

### M5. After an election, the undo chip still floats on the stone (B12). Polish.

- **Where:** the start of round 2, at 390×844 and 375×667. The chip "להחליף ראש רשימה" sits alone at the lane's left end, on the paving, as D54 keeps it after an election.
- **Evidence:** `ux/manual-test-2026-09-30/review/m4-round2-lane-undo-390x844.png`, `ux/manual-test-2026-09-30/fixes/dev2-round2-start-390x844.png`.
- **What it breaks:** B12's complaint ("floats on the stone"). The pre-tap half is fixed, but this half is not.
- **Owner:** Game Developer.
- **Fix:**
  - Dock the chip on a flat navy tab (`#072a7a`, the undo bar's colour) from the canvas's left edge (x 0) to the chip's right edge + 8, and the chip's height + 16, for the chip's 5 s.
  - Its timer line runs along the tab's bottom, as in the pre-tap bar.
  - It then reads as the same control in both variants.

### M6. The slice after-shots predate the merge. Accept.

- `art-*` and `dev1-*` were taken on the slice worktrees. `art-lane-*-390.png` and `dev1-ceremony-390-1-walkout-old-stage.png` still show the stage-top name toast and the old teaser rows.
- The merged build is the evidence of record: the regenerated `dev2-*`, the orchestrator's 9-device run and `review/`.
- **Owner:** none. No re-shoot is needed, but don't cite `art-*` / `dev1-ceremony-*` as merged-build proof in the redeploy notes.

### M7. The pre-tap undo bar and the plaza strip read as designed (D51/D54). Accept.

- **Orchestrator's question 3.**
- **Evidence:** `fixes/dev2-pretap-undo-390x844.png`, `…-375x667.png`, `fixes/dev2-pretap-390x844.png`.
- **What holds:**
  - The navy bar fills the ticker slot, full bleed, with the chip centred and the timer line draining along its bottom.
  - When the chip goes, the lane and the plaza strip form one stone band of about 11% of the height (was about 45%, A2), with card 1 directly under it.
  - At H1 the ticker takes the same slot in the same navy, so nothing moves.
  - The chip's rim on the bar is legible.
- **Owner:** none.

### M8. The settings switch's ON and OFF states read clearly (A8, D61). Accept.

- **Orchestrator's question 4.**
- **Evidence:** `fixes/dev1-settings-se-music-on.png`, `…-390-music-on.png`, `…-375x548-music-on.png`.
- **What holds:**
  - **ON** is a flag-blue track, the white knob **left** and "פועל" in flag.
  - **OFF** is a grey track, the knob right and "כבוי" in slate.
  - The state is carried three ways, so the switch does not rely on colour alone (WCAG 1.4.1), and the word contrast is ≥ 6.9:1.
  - "Knob left = ON" is the RTL mirror (rtl-map §7.4, R6). The HANDOFF note's "knob on the right" was the LTR habit, and the spec is right.
- **Owner:** none.

## Verdicts on the HANDOFF items

| Item | Verdict | On the merged build |
|---|---|---|
| A1 plaza reads as worms | **closed** | Random-length slabs, short mortar joints, no black lines, on every era (`art-lane-*`, the matrix run) |
| A2 lower half only stone | **partly** | Round 1: closed; Row A, card 1 and the teasers come up from the pick, and the stone is about 11%. Round 2+ with under 7.5 ₪: open (**M2**) |
| A3 picker caption on stone | **closed** | Full-bleed navy plate on the first and after-election pickers, on all 9 devices (`dev2-picker*`) |
| A4 ceremony card translucent over the ticker | **closed** | Opaque page; the ticker does not print through (`dev1-ceremony-*-3`, my 390 and SE drive) |
| A5 era changes before the walk-out | **closed** | The walk-out runs on the old stage, and the era swaps under the opaque page (my SE drive, `dev1-ceremony-*-1/2`) |
| A6 SE settings hide the reset row | **closed** | Every row, "איפוס התקדמות" included, and "סגור" on screen at 375×548, 375×667 and 390×664 (the matrix run's `settings`) |
| A7 the name plate covers the stage | **partly** | The plate is replaced by Row A's identity chip, clear of the hit on every device (S14). Toasts still cover the head on short stages and at round 2's start (**M1**) |
| A8 toggles don't show their state | **closed** | **M8** |
| B9 teaser rows read as filler | **partly** | The hint and the first two fading slips work; the floor rows don't (**M3**) |
| B10 HUD right side empty | **closed** | The identity chip (face and short name) holds Row A's right end from the pick |
| B11 chat: empty blue, loose reply chip | **closed** | The thread starts under the header with "היום"; the reply is headed by the leader's name (`dev3-chat-*`, the matrix `t3-chat`) |
| B12 the "להחליף ראש רשימה" chip floats | **partly** | Pre-tap: closed, in the navy bar. After an election: still on the stone (**M5**) |
| B13 the picker's top and booth | **closed** | A kraft-cardboard booth with a flag band on the tall phones and the frame. The logo and building fill the top band. The booth is off at the SE and on the toolbar viewports by design (§5.14.2) |
| B15 Dubi's story card is Bibi-only | **closed** | Every leader has their own `kit.story`, and the T4 archive rebuilds from `story_seen` (`d003bab`). Bibi's card reads as reported speech; the only direct quote is Dubi's (fictional) |
| D19 the ticker row is empty | **closed** | The standing line "מהדורה מיוחדת" at card 1, bought and C1 on all 9 devices |
| D20 white slivers along the list | **closed** | A flag rule on each edge plus the white margin, and the thumb is hidden when idle |
| D21 two tabs and two empty slots | **closed** | Four slots; the locked ones show a silhouette and a padlock (the matrix `c1-tabs`) |
| D22 the HUD's right side is empty | **closed** | As B10 |

## Spec fixes made in this change (UX-owned text)

- `ux/mobile-first-layout.md`:
  - **Revision lines:** the lower-pane slice's revision line (D55-D59) was missing; it is added, with a line for this review.
  - **§5.9:** the "Open, accepted" note on the SE toast was wrong, and M1's rule replaces it (D62, not yet built).
  - **§9.1:** gains S18.
  - **§10:** M1's stale "push from the left, 300 ms" is marked done (D47/D48).
  - **§11:** D51-D54 sat between D36 and D37, and a blank line split the table before D55. The rows are put back in order and the table is joined.
- `ux/rtl-map.md` §8.6: the fresh toast now comes when the undo chip goes, in the lane band; Dubi's pre-tap toast is placed in the lane band; "What follows" no longer says Rows, panel and tabs are hidden pre-tap (D51).
- `ux/ftue.md`: rev 6, the header note and the t = 0 timeline row.

## Objections

None. No build behaviour contradicts a spec in a way that I think is wrong on the spec side. The one spec error (the §5.9 accept on the toast, and U9's dock placement) was mine, and it is corrected above. The A8 knob side stands as specced.
