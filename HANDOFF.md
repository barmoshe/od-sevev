# HANDOFF: idle-genre upgrade + reinvented sharing, LIVE (2026-10-02 evening; read this first)

**Live: `293d85a`** (web-dist `7159192`, Vercel `dpl_2bVnZjN47Q481iLDqyZnm5ymbvBX`). All four WIP branches are merged
into main and deployed: missions and ranks, "תעבור אותי" and "הסבב היומי", the share platform (drawer, cards, OG
stubs), faster later rounds; plus card milestones, live ₪/s and the coalition chat UX. Details: `STATUS.md` (2026-10-02).

## Open
1. **The full bench** (`tools/balance.sh`) ran during the deploy: read its result (S1-S8, L1, G1, the browser replay).
   Missions (rank income bonus) and faster rounds both move pacing; if a gate is red, root-cause before tuning.
2. **Election silence** (Fri 23.10 to 27.10 22:00): the daily grid swaps 61 for ✅ and the breaking card hides 61,
   but the challenge return lines (`CHALLENGE_SHARE_LOSE` "הגעתי ל־61…") still print 61; decide whether the
   gate count counts as a seat number there.
3. **Visual pass on a phone** (Bar): the 📣 chip under the missions chip, the drawer, the missions sheet.
4. Older items below (unwired props, the Ben Gvir walk-out pose, Bar-only items) still stand.

# HANDOFF (history): idle-genre upgrade + reinvented sharing, paused mid-flight (2026-10-02)

Bar stopped the session ("תעצור הכל, תרשום handoff, נמשיך עוד מעט"). Four agents were stopped mid-task;
their work is pushed as **WIP branches** (not merged, not deployed).

## Live (od-sevev.vercel.app)
**Update, same day:** `c18c982` is live (web-dist `fef4282`, Vercel `dpl_AYHHV1YKofHCTLfmsVPLnNTzezhx`): main's milestones, live ₪/s and coalition UX, plus `wip/missions` and `wip/challenge-daily` merged. `wip/share-platform` is merged on main after it (`d07ed78`), not deployed. The list below is the state before.

**`38f6916`** (web-dist `cc38ead`, Vercel `dpl_ByzTLVU8T2DE6WiXHWoF4SJEkkJ5`):
- the postpone floor at 25 s of income (G1 fixed);
- the LayerHistory race fix;
- the bench green 11/11 (G1 is now the median of seeds 11-19, on a split politics rng stream);
- the browser trace re-recorded.

## On `main`, not deployed yet (merged and tested: `tools/test.sh` 528/528)
- **Card milestones** (`20db7f3`): each source card shows "12/25 ← ×2" with a bar, a gold ×N chip
  and a celebration when the milestone lands; an all-sources ×1.25 row sits on the buy-mode row.
- **Live ₪/s** (`656c8d4`): Row A's rate = passive + the live tap rate (2 s window, smoothed, back to
  passive within 3 s); display only.
- **Coalition chat UX** (`3864d4f`, `e29405f`):
  - every open pill says what it is worth ("+12 מנדטים לקואליציה", "יפרוש עם 12 מנדטים",
    "אולטימטום בעוד 0:42" with a bar);
  - "נסגור בעוד 0:42" when it can't be afforded yet;
  - pay-all "לסגור עם כולם · X ₪";
  - a brawl shows the seats it froze;
  - the pending chip flags an ultimatum;
  - the pinned agreement bar is a real button with ‹ and a free-base badge;
  - "i" badges on avatars;
  - real perk icons;
  - the one-time perks toast.
  - Helper: `ui/views/chat_stakes.gd`.
- Store Reels from the store session (merged as-is).

**To deploy main now:** `tools/build_web.sh` → commit `build/web` onto `web-dist` (keep its
README; copy `tools/web/vercel.json` and `.vercelignore`) → push → Vercel connector
`create_deployment` (team `team_ok1MqoSMeupTyBE6CXAR91UT`, project `prj_ZbQ1ubW0AU5hfhSVnVtcsgmm6BVA`,
target production, gitSource github barmoshe/od-sevev ref `web-dist` sha <the real web-dist sha>) →
`get_deployment` until READY.

## WIP branches (pushed; each from `38f6916` or `7003dd0`; merge into main, finish, test)
1. **`wip/missions`**: AdCom-style missions and ranks.
   - `efcb378` is the feature (3 concurrent missions, claim, ranks with a permanent income bonus,
     content `missions`, `sim/missions.gd`, HUD entry, sheet).
   - `d6b7a6c` is bench pacing notes.
   - `6a29e75` is the WIP tail: the agent was building the web export for screenshots.
   - **Left:** a visual check of the HUD entry and sheet on a phone layout; run `tools/test.sh` and
     the bench S-gates after merging.
2. **`wip/faster-rounds`**: make each election faster than the last (rounds 6+ currently stretch to
   about 10 min).
   - `13e689b` is only WIP: probes plus content edits mid-way. **Not validated.**
   - Next: finish tuning `coalition.unlockScalePerElection` (5), `unlockTimeScalePerElection` (0.9)
     and prestige.
   - Add the bench gate "rounds 2-8 each ≤ the previous + 15 s, rounds 6-8 ≤ 6:00".
   - Run `tools/balance.sh` (25-40 min, background).
   - Update `design/progression-curve.md` §0.
3. **`wip/challenge-daily`**: "תעבור אותי" challenge links and "הסבב היומי".
   - `7ebc649` is the feature: seeded fresh rounds, ghost timer, return link, the daily emoji grid,
     streak.
   - `92b89ed` holds fixes plus a STATUS line.
   - `8863e99` is the WIP tail: it was fixing a template literal in a web driver (rounds_web).
   - It talks to the share platform through an adapter (`ShareKit.request` if present, else the old
     text path) and reads `window.odArrival` if present, else parses `location.hash`.
   - **Left:** finish the web driver, run the tests, take screenshots.
4. **`wip/share-platform`**: the reinvented sharing. This is the biggest piece and is mid-build.
   - `33429c4` is RoundLog: a per-round history for the share cards.
   - `82bdc71` is a large WIP (26 files): the HTML share drawer, `ShareKit.request`, cards, stubs. The
     agent was adding funnel tests for the drawer's channel results.
   - **Left:** finish and verify everything below.

## The sharing design Bar approved (from three research reports; build against this)
- **Platform:**
  - a persistent **📣 "הדלף"** button;
  - in-chat prompts from the coalition's media advisor ("יש לנו כותרת. להדליף?"), at most 1
    proactive prompt per session, never during tapping;
  - an **HTML share drawer** over the canvas: pre-rendered PNG, a live preview plus a
    WhatsApp-bubble mock, formats square 1080×1350 / story 1080×1920 / text-only, a
    neutral/family-safe toggle;
  - navigator.share with files, then fallbacks wa.me / t.me / X / copy / save;
  - in-app-browser detection (Android WebViews have no `navigator.share`);
  - iOS drops the caption on image shares, so print the URL and hook on the image and copy the
    caption to the clipboard.
- **Cards:**
  - **הדלפה:** a fake coalition WhatsApp-group crop with real lines from the round;
  - **מבזק:** a red ticker, invented channel "ערוץ 61";
  - **סיכום קדנציה:** Wrapped-style story cards on "עוד סבב";
  - **סיכום כל הסבבים** (Bar's own ask): a career card across all rounds, from round 3+, also in
    📣 and the dossier;
  - every card carries a "סאטירה · עוד סבב" stamp and the short URL; preset lines only.
- **Previews and attribution:**
  - pre-rendered static stubs `/s/<leader>-<kind>/index.html` with their own og:title/og:image
    (≤ 250 KB, 1200×630, the key content in the centre square, title starting with a Hebrew
    word);
  - no @vercel/og (Satori can't do Hebrew bidi);
  - state goes in the URL **hash** (`#k=…&r=<ref>&…`), with `?via=wa|tg|x|copy|img`;
  - the shell parses arrivals into `window.odArrival` and sends `arrive/<kind>/<via>` and
    `share/<kind>/<channel>/<result>` (cancel included) as virtual page views within the Hobby 50K
    cap.
- **Mechanics:**
  - **"תעבור אותי":** same leader + seed, ghost timer, "שלח לו בחזרה";
  - **"הסבב היומי":** Israel-date seed, the same for everyone, a spoiler-free emoji grid as text,
    one official try a day, streak.
- **Rules:**
  - election silence from Fri 23.10 to 27.10 22:00: no seat or poll numbers framed as public
    opinion;
  - no "who I vote for": the copy says "שיחקתי את…";
  - Hebrew copy starts with a Hebrew word, link alone on the last line, ≤ 200 chars, no em dashes.

## Order to resume
1. Merge `wip/challenge-daily` and `wip/missions` (most complete) into main. Resolve conflicts in
   `main.gd`, `content.json` (round-trip with `json.dumps(indent=1, ensure_ascii=False)`, no
   trailing newline), `gen_strings.py` / `ui-strings.json` (re-run `python3 ux/tools/gen_strings.py`)
   and the shell analytics allowlist.
2. Finish `wip/share-platform` on top. Wire challenge/daily to `ShareKit.request`.
3. Finish `wip/faster-rounds`.
4. Full checks: `tools/test.sh`, content lint, gen_strings, lint_text, `tools/balance.sh`
   (background), the web drivers.
5. Deploy. Log in STATUS.md. Tell Bar.
- Godot 4.7.2 goes in the scratchpad (`tools/godot.sh` finds it). Pillow + numpy for art.
- `.claude/worktrees/` is excluded locally (`.git/info/exclude`). Never `git add` those
  directories.

# HANDOFF: leaders v3 phase 3 + Bar's playtest asks, all live (2026-10-01 night, cloud session; read this first)

**Live: `c726a5e`** (web-dist `3e8ed88`, Vercel `dpl_5aWgDf3DQSifGJU3ZSSB4CR54Wj4`). Tests 497/497, content lint 0,
gen_strings 0, lint_text 0. The L1 bench is within ±10% for all 8 leaders (table in `design/leaders-v3.md`).
Every item of the leaders-v3 handoff below (phases 3a/3b, trophies and squawks, the deploy, the art rig) is
**done**; that section is history now.

## Done this session (details and hashes in `STATUS.md`)
- **Blocks and interruptions** (Bar's bug: "מרדכי דוד חוסם" with him off the stage):
  - Mordechai's block has 3 phases: walk in 2 s (taps work), block 6 s, walk out 2 s.
  - Toasts carry an `alive` check (`Toasts.show_toast(..., alive)`, `prune`), so a stale line is dropped.
  - One stage interruption at a time (`Events.STAGE_INTERRUPTS`, `stage_busy`).
  - Reaction timers wait out the block (Politics dt 0).
  - A blocked tap shakes the chip, which counts the block down.
  - Back, keys and hold-to-buy obey the block.
- **Mordechai by leader** (`effect.byLeader`): Ben Gvir taps ×3 while he stands, Bibi ×2, Smotrich no
  block.
- **The ability chip** is in the top-right sky with the GPT icon; toasts dock in the lane while it's up.
- **Phase 3b:** a countdown and a negotiation line per leader (`priorityOnce`; it also wakes cal08).
- **Ability trophies** (`kit.abilityTrophy`) and Dubi's ability squawk.
- **The GPT art** is rigged (no drift):
  - 9 pose chars, played on each use via `rule.active.poses` / `BigBanana.flash_pose`;
  - 7 props (PressDesk draws the podium, bench and box);
  - 8 icons;
  - Kaia (still flag-off).
- **The boot loading screen:** a progress bar in `#od-gate` for new and returning players, then
  "סופר את הקולות…" while the engine starts.
- **Gantz on the picker:** the first time, he is a normal-looking tile in place of הפתעה. Picking him
  gets a threshold line, the cell turns into הפתעה, pick again. He fools a save once (stat
  `gantzFooled`).

## How to deploy from a cloud container (no Vercel CLI login)
1. `tools/build_web.sh`. Godot 4.7.2 goes in the scratchpad; `tools/godot.sh` finds it.
2. Commit `build/web/*` onto `web-dist` in a worktree. Keep its README, and copy `tools/web/vercel.json`
   and `.vercelignore` in.
3. Push, then deploy with the Vercel connector: `create_deployment` with team
   `team_ok1MqoSMeupTyBE6CXAR91UT`, project `prj_ZbQ1ubW0AU5hfhSVnVtcsgmm6BVA`, `target: production`,
   and `gitSource {type: github, org: barmoshe, repo: od-sevev, ref: web-dist, sha: <the real sha>}`.
4. `get_deployment` until it's READY on od-sevev.vercel.app.

## Art pipeline notes (cloud)
- Set up with `pip install --user pillow numpy`.
- Re-render a character with `cd creative-pack/art/showcase/src && python3 build.py <char>`, then
  import with `xvfb-run -a python3 pipeline/od-sevev/build.py --no-render`.
- This Pillow re-encodes untouched PNGs. After an import:
  - restore HEAD bytes for every pixel-identical PNG;
  - put `sprites.json`'s `files` entries for those back to HEAD's;
  - leave `budget.json` and the proofs at HEAD unless they really changed.

## Open
1. **Bar plays the build.** Then run the full test pass: the web drivers (`tools/web/*.mjs`,
   Playwright with the pre-installed Chromium) and `tools/balance.sh`. Its last run was cut short by a
   container restart; L1 passed.
2. **The full bench** is green (11/11, 2026-10-02): the G1 and browser-replay failures are fixed
   (STATUS 2026-10-02).
3. **Unwired art:**
   - `prop_round-table`, `prop_pledge-scroll`, `prop_budget-book` and `prop_clause-doc` have no hook
     yet.
   - Ben Gvir's walk-out pose isn't played, because the court walk ends a pose.
4. **Bar only** (from the analytics handoff):
   - Search Console indexing for `/` and `/about.html`;
   - the press pitch;
   - deleting `dpl_aas8f96abYdAJdkMHYQp21BrCws8`;
   - the domain (not now);
   - the smaller web engine (the Mac's disk).

# HANDOFF: leaders v3, a storyline and gameplay for every leader (2026-10-01, the character-copy session)

Bar asked to improve each leader's storyline and gameplay ("אל תתמקד רק בביבי"), and said yes to more
assets made with GPT ("אל תתקמצן"). Bar's planning answers:
- an active ability on top of each rule;
- ±10% round length stays;
- it ships in phases, each one deployed.

Design and tables: **`design/leaders-v3.md`**. GPT assets: **`creative-pack/art/briefs/leaders-v3-gpt.md`**.
**Live: `5eaecd5`** (web-dist `ad28161`, Vercel `dpl_9q8R6t3GMYgppFgGfNagwbJBMHgw`). **`main` is ahead:** the GPT art and
phase 3a WIP (`1790c43`), not deployed. Hashes and bench numbers: `STATUS.md`.
Tests 484/484, content lint 0, gen_strings 0, lint_text 0. The bench (L1) is within ±10% for all 8 leaders.

## Done (on main)
- **Phase 1** (`7276e30`, live):
  - Every leader leaves the stage on the press day. The mark holds a podium (Deri: a bench); the
    drawn placeholder is `PressDesk`. A tap only wiggles it, and the toast is the leader's own line
    (`kit.hazard.tapPaused`).
  - Story v3: 6 beats per leader (Bibi 7), new beat 1s, beats 5–6 from true 2025–26 arcs, 14 facts.
  - `kit.story.when`: a beat waits for the leader's own deed.
  - Every leader has an encore of their own.
  - Leftovers: Deri's coffee, Smotrich's "אין כסף".
- **Phase 2:**
  - **Engine and chip:** an active ability for every leader (`sim/ability.gd`, content
    `leaders[].rule.active`). `AbilityChip` sits at the stage's bottom right; the picker card explains
    it (`copy.desc`).
  - **Abilities:**
    - Bibi: תתאחדו
    - Bennett: לחתום/להפוך
    - Ben Gvir: אני פורש (walks off, leaves his box)
    - Liberman: המסמך
    - Eisenkot: לכנס
    - Smotrich: תקציב בדקה ה־90
    - Deri: למסדרון
    - Golan: שמאלה
  - **Quiet partners:** `Coalition.quiet`.
  - **Bibi's pardon desk:** the "הסדר טיעון" stamp brings Herzog.
  - **Bench:** `PacingSim._play_ability` plays the abilities.

## Open, in order (2026-10-01, handed to a CLOUD agent)

**Read first:** you run in a cloud environment, not on Bar's Mac. You have no Chrome, no ChatGPT, no
`~/Downloads` and no scratchpad from earlier sessions. Everything you need is pushed to `main`. Work on
`main` (or a branch Bar names), commit each step, push, and log hashes in `STATUS.md`. Earlier phases were
built, tested and deployed from a container, so `tools/test.sh`, the L1 bench and `tools/deploy_web.sh`
should work for you. If Godot or the Vercel token is missing, say so in `STATUS.md` and leave that step
for Bar's Mac. Don't block on it.

**Where it stands:** live is still `5eaecd5` (phase 2). On `main` and not deployed:
- `c6a90ec` and the art commits before it: all the GPT art, not rigged;
- `1790c43`: phase 3a as WIP.

1. **Finish phase 3a, the shared unity offer** (`1790c43`, WIP).
   - **Built:** Netanyahu's offer for every opposition leader but Golan, whose swipe already is one.
     - Content: `leaderSelect.unityOffer`, first at 150 s, then every 240 s, open 20 s, +1%.
     - Each leader's refusal: `kit.unity.refuse` for bennett, liberman and eisenkot.
     - The chip shows "לא" while the offer is open; a tap refuses it, for +1% base, the leader's toast
       and `stats.unityRefusals`. Ignoring it does nothing (Bar's call, 2026-10-01).
     - The offer waits out the court day and the leader's own live ability (a walk-off, a pledge he
       can still flip).
     - Code: `Ability.unity_*`, `_tick_unity`, `_refuse_unity` in `sim/ability.gd`, all in the same
       state dict (`uPhase`, `uT`, `uNext`). `main.gd _on_ability_event` handles the `unityOffer` and
       `unityRefuse` toasts. `PacingSim._play_ability` refuses every offer. `gen_strings.py` now
       measures `kit.unity.refuse` and `unityOffer.copy`.
   - **Checked:** `test_abilities` 14/14 (4 new unity tests), content lint 0, gen_strings 0.
   - **Not checked:**
     - Run the full `tools/test.sh`. Expect 488+ tests. `test_data_sync` needs `tools/sync_data.sh`,
       which `test.sh` runs.
     - Add an in-scene chip test in `test_event_copy.gd`, after the pattern of
       `test_the_ability_chip_walks_ben_gvir_out`: force `uNext` to 0, tick, tap the chip, expect the
       refusal toast.
   - **Bench:** run L1 for bennett, liberman and eisenkot (the median first election, seeds 1–9, as in
     `design/leaders-v3.md`). Bennett was at −9% before this, and +1% per refusal pushes him faster.
     If he falls out of ±10%, lengthen `unityOffer.everySec`, or exclude him via a `skip` list in
     `unityOffer`. Never touch the shared economy.
2. **Phase 3b, the countdown to 27.10 with a line per leader.** Not started. The design is in
   `design/leaders-v3.md` ("Next phases"), and Bar answered (2026-10-01):
   - **Countdown line:** two lines per leader in `kit.ticker[]`. The countdown is shaped like `cal01`:
     `icu: true` with `{d, plural…}`, `when {mode: [campaign], dateTo: "2026-10-22"}` (it stops
     before the blackout), and `poll_like`.
   - **Negotiation line:** `when {mode: [negotiation]}`, and it never shows results.
   - **Placement:** each line shows **once at the start of a round**, then joins the random pool. Wire
     `priorityOnce` in `game/scripts/core/ambient.gd pick()`: take the first eligible unseen
     `priorityOnce` line, tracked per round in `s.leader_round`. Nothing reads `priorityOnce` today.
     Wiring it also wakes `calendar.negotiation.opener` (`cal08`); that's intended, so mention it in
     `STATUS.md`.
   - **Copy rules:** the leader's own voice, ≤ 60 chars (content-lint `checkTick`), no poll numbers,
     no em dashes, no quote marks on reported speech, nothing true in the 23.10–27.10 blackout.
   - **Lint:** `checkTick` must accept `priorityOnce`; allow at most 2 per kit.
   - **Test:** extend `test_calendar.gd` or an ambient test: picked first, once per round, never in
     the blackout.
3. **Ability trophies + Dubi squawks.** Not started.
   - **Trophies:** a new `kit.abilityTrophy` per leader (8),
     `trigger {type: "leaderStat", leader, key: "abilityUses", value: N}`.
     - Proposed N: Bibi 5 (his is once a round), Liberman 5 documents, Smotrich 10, Bennett / Ben Gvir /
       Eisenkot 10, Deri 25, Golan 15.
     - Names and descriptions in the leader's joke voice, `icon_folder` like the others.
     - `Leaders.trophies()` (`leaders.gd:805`) must also append `kit.abilityTrophy`.
     - Lint: unique ids against shipped trophies and `kit.trophy` (`content-lint.mjs:440`).
     - Test: `test_trophy_stats.gd`.
   - **Squawks:** `kit.dubi.squawks.ability` per leader, fired from `_on_ability_event` on a use via
     `Audio.squawk_text(id, "ability")` (`audio.gd:532`, which falls back to a shared `dubi.ability`).
     Throttle to one per 20 s. `gen_strings.py` already measures every squawk key.
4. **Deploy phase 3** once 1–3 are green: `tools/build_web.sh` (strict), then `tools/deploy_web.sh`
   following the last deploy entries in `STATUS.md`. Verify that the live `mbBuild` matches. Log it in
   `STATUS.md`, `design/leaders-v3.md` (a Phase 3 section with the bench table) and this file.
5. **Rig the GPT art** (all in `creative-pack/art/refs/`; the run log with every chat is
   `creative-pack/art/briefs/leaders-v3-gpt-runs.md`).
   - **The files:**
     - poses: `bennett-sign`, `ben-gvir-walkout`, `ben-gvir-back`, `liberman-document`,
       `eisenkot-summit`, `smotrich-budget`, `deri-bench`, `golan-swipe`, `bibi-matchmaker`;
     - props: `podium`, `corridor-bench`, `round-table`, `cardboard-box`, `pledge-scroll`,
       `budget-book`, `clause-doc`;
     - icons: `ability-icons` (a 4×2 grid in the brief's order, 1254×1254);
     - Kaia: `kaia` and `kaia-happy`.
   - **The rig:**
     - Poses are a second ref per leader, like `herzog-shrug` over `herzog` (pose react in
       `creative-pack/art/showcase/src/cast.py`, built by `showcase/src/build.py`; the game sprites
       come out of `pipeline/od-sevev/build.py`).
       Check that the feet line and head size match the first ref. `golan-swipe` came out smaller in
       frame than the rest.
     - Props go in the props block of those same scripts.
     - `PressDesk` (`game/scripts/ui/press_desk.gd`) swaps its drawn map for the `podium` and
       `corridor-bench` sprites.
     - `AbilityChip` swaps its letter for the cut icon.
     - `kaia_figure.gd` swaps the drawn dog for `kaia` / `kaia-happy`.
   - **Caution:** the earlier "scratchpad `import.sh`" lived in a local session. Use the repo's own art
     pipeline (`art/`, `pipeline/`, `node art/tools/export-godot-data.mjs`; see `HOW-TO-RUN.md`). If a
     step needs a local-only tool, stop and note it.
6. **The full bench** (`tools/balance.sh`, profiles and the median hour) timed out at 25 min in a
   container. Try it in the background. If it times out again, leave it for Bar's Mac. Golan's worst
   seed is 11:50.

**Can't be done from the cloud:** anything in ChatGPT (new art or retries: give Bar a prompt instead),
Bar's Chrome, Bing Webmaster sign-in.

## How to change an ability
- **Numbers and copy:** `design/content.json` `leaders[].rule.active`, then `tools/sync_data.sh`.
- **Lints:** `node design/sim/content-lint.mjs --strict` and `python3 ux/tools/gen_strings.py` (`btn*`
  ≤ 120 px at ×3, toasts in `stage.toast`, `desc` in `pick.card`).
- **Tests:** `game/tests/unit/test_abilities.gd` (a sim test per type),
  `test_event_copy.gd::test_the_ability_chip_walks_ben_gvir_out`, and
  `test_every_leader_leaves_the_stage_on_the_hazard_day`.
- **A new type:** `Ability.TYPES`, `block`/`use`/`tick`/`view`, then `_play_ability` in PacingSim.

# HANDOFF: analytics and search (2026-10-01, the analytics session; parallel, not ordered)

Live at `7578546` (web-dist `5dab84a`). Details and hashes in `STATUS.md` (2026-10-01, analytics session).

## How the analytics work
- **Vercel Web Analytics, Hobby plan:** page views only (custom events are Pro). Play milestones are sent as **virtual page views** under `/play/`. Read them in Analytics → Pages, with Routes showing the family totals.
- **Code:**
  - `game/web/shell.html`, the "Analytics" block: `window.odTrack(step)` holds a step until the script's own page view has been sent.
  - The allowlist is `STEP`, and once-per-device steps are deduped in localStorage `odsevev.seen`.
  - `window.odTrackFunnel` maps `main.gd _funnel()` events (signal `funnel_sent`) to steps.
  - Nothing is sent on localhost or with `?dev=1`. `window.odTrackLog` keeps every step for the drivers.
- **Steps:**
  - `loaded/<new|back>/<time>s`, `load-error`
  - `return/d1|d2-7|d8-30|d30+`
  - `first-tap/<on|off|na>`, `first-election/<time>`, `elections-5`
  - `picked|switch|stay/<leader>`
  - `quit/disclaimer|loading` or `session/<len>m` (one per page)
  - `feature/chat|court|mordechai`
  - `share/<kind>/<result>`
  - `reload-after-crash`, `ctx-lost`
- **Constraints:**
  - The 50K events a month are shared across Bar's whole Vercel account. Add new steps sparingly.
  - No seat or poll numbers in any path (the 23.10 blackout).
  - Speed Insights is off: Hobby allows it on one project only, and enabling it here needs Plus (CLI, 01/10). The script was removed from the shell; `loaded/<new|back>/<time>s` covers load time.
- **Don't retry:**
  - A `vercel.json` rewrite into `/_vercel/*` returns 404 on this static deploy.
  - The Vercel analytics API/MCP returns 404 on Hobby. Read the numbers in the dashboard instead.
- **Test:** `tools/web/analytics_web.mjs` (Playwright; it also checks the head and `about.html`), plus `game/tests/unit/test_funnel.gd`.

## Search (SEO/AEO)
- **Head:**
  - Title: "עוד סבב: משחק הבחירות שלא נגמרות | סאטירה 2026".
  - `META_DESCRIPTION`, canonical, VideoGame + WebApplication JSON-LD (author בר משה, dateModified).
  - The maker line "מאת בר משה · לפניות: 1barmoshe1@gmail.com" (Bar's call, `render_shell.py` defaults).
- **`game/web/about.html`:** a static page rendered by `render_shell.py`, so crawlers that run no JS can read it. It has the direct answer, a 5-question FAQ (`FAQ_*` keys in `ux/tools/gen_strings.py`) and FAQPage JSON-LD. It's linked from About and `<noscript>`.
- **Files from `build_web.sh`:** `robots.txt` (all bots), `sitemap.xml` (`/`, `/about.html`), the Search Console file `tools/web/google934215264611e5f3.html` (**keep it**) and the IndexNow key file `tools/web/27bc5ef5ff8e4f8b98acf2f714e15c3c.txt`.
- **Search Console:** the URL-prefix property is verified in Bar's account and the sitemap is submitted. As of 01/10 nothing was indexed yet.
- **Bing Webmaster Tools** (imported from Search Console, 01/10): `/` and `/about.html` are **indexed in Bing**, the sitemap reads Success (2 URLs), and the live test shows no SEO/GEO issues. Bing flagged "more than one h1" and a missing alt; both fixed in `ca86932`. ChatGPT search draws on Bing's index.
- **Ping IndexNow after content changes:** `https://api.indexnow.org/indexnow?url=<url>&key=27bc5ef5ff8e4f8b98acf2f714e15c3c`.

## Open
1. **02/10:** request indexing for `/` and `/about.html` in Bar's Chrome (Search Console → URL Inspection). It hit the daily quota on 01/10.
2. **Bar only:**
   - Send the press pitch: `bar_builds/lab/personal/od-sevev/press-pitch.md`, a draft.
   - Delete the throwaway preview deploy `dpl_aas8f96abYdAJdkMHYQp21BrCws8` (a stub page).
3. **Domain:** not now (Bar, 01/10). odsevev.com was free at $11.25 a year.
4. **Smaller web engine template:** custom Godot build without 3D/XR/navigation, wasm about 9.5 → 5 MB brotli. Blocked: the Mac's disk was full (4.4 GB free).

---

> **Copy audit, 2026-10-01 (character-copy session): done and live (`a9e5aa9`).** Every signature was checked against sources; the before/after table, the parallel research cross-check and the open items (store videos still show Deri's "ידידי" and the coffee; optional swaps: Deri's "הדלת והחלון", Smotrich's "יש כסף, לא לך") are in `design/copy-audit-2026-10-01.md`.

> **Two sessions ran at the same time on 2026-09-30 and both handed off:** the store-videos session
> (this first section) and the character-copy session (the next section). Neither is newer; both are
> current. Read both before starting.

# HANDOFF: "עוד סבב" store videos (2026-09-30, the store-videos session, parallel to character copy)

Bar stopped here: "write a handoff and push to main". Nothing in this session touched the live
site's build; the game changes it made are dev-only (the capture driver) plus the HaTikva tap and
mix work already logged in `STATUS.md` and deployed earlier.

## State at the stop

- **Branch `tap-hatikva` merged into `main`**, both pushed. `vercel.json` has git deploys off, so
  the push deploys nothing.
- **Deliverables** (all in `store/`, each with a cover = its last frame, also in frames 0-1):
  - `instagram/profile-b-hd.png`: the profile picture Bar picked.
  - `teaser/od-sevev-teaser.mp4` (30 s) and `teaser/od-sevev-teaser-2.mp4` (41 s, Mordechai David "חוסם").
  - `gameplay/od-sevev-gameplay.mp4` (v3, Ben Gvir, bare screen on velvet).
  - `gameplay/od-sevev-gameplay-iphone.mp4` (v4.1, Ben Gvir on a drawn iPhone): Bar's reference
    for the look. Rendered before the v4.2 drift fix (see Next 2).
  - `gameplay/od-sevev-liberman.mp4` (Liberman on the iPhone, `music/glitch-warfare.wav`).
    **The committed mp4 still has the OLD captions.** Bar: "הקופירייט גרוע". The new copy is in
    `src/reel_liberman.py` (rewritten against `creative-pack/voice/review-rubric.md`: every line a
    named mechanism, punch on the last word; the punch lands 0.75 s after the setup) but was never
    rendered: Bar stopped the render.
- **Takes are gone.** The Movie Maker frames lived in the session scratchpad. Re-render = recapture
  first (`store/gameplay/README.md`, about 7 min per 2,250 frames), then the reel script (about 8 min).

## Next, in order

1. **Bar's next demo video: several leaders, in segments, on the iPhone, not one character.**
   - One continuous take can pass through leaders: the forced `elect` now works, and after the
     ceremony the picker opens again, so a plan can pick A, play ~20 s, elect, pick B, and so on.
     Or one short plan per leader. Either way, reuse `gameplay_iphone.py` as the base, the way
     `reel_liberman.py` configures it (clips, captions, camera keys, `TAP_AT`, end card, music offset).
   - Each leader's joke comes from their kit in `game/data/content.json` (`leaders[].kit`: tap verb,
     crit name, rule, sources, ticker). Roast coalition and opposition about equally (rubric balance check).
   - Copy: short, native, a mechanism per line, punch last; true where it claims truth; no polls,
     no groups as the punchline, nothing copied from Eretz Nehederet (rubric gate 5).
   - Music: ask Bar (`music/soundtrack.wav` 98.4 BPM, bar = 0.092 + 2.438k; `music/glitch-warfare.wav`
     ~132.7 BPM, bar = 1.554 + 1.808k).
   - Mordechai David: little or none (Bar). The game fires his event by itself around 24-25 s into a
     take (1:00 of play at dev speed 3); cut around it.
2. **Re-render the Liberman reel with the new copy**, and the Ben Gvir iPhone reel with the v4.2 drift
   fix, if Bar still wants them. The new Liberman captions no longer name t4 ("תומך ותיק" is gone), so
   the character-copy session's open item 2 below is settled in the source; they lean on what its
   rewrite kept ("לא מוחלט", "לא יושב", the dishes tax). A recapture now also shows his rewritten kit.

## Tools and lessons (this session)

- Capture driver `game/tests/dev/gameplay_capture.gd` (dev only, loaded through a temporary
  `game/override.cfg` that must never be committed): pick, hat, grant, buy, event, tab, pay,
  **decline** (Liberman's "לא יושב", read from the chat's hits), **demand** (the next member demand
  now; a decline needs a member demand, join offers have no decline pill), **elect** (works now: the
  dev flag is on for the call), esc, tapxy, speed, log. The log prints buy rows, pay and decline
  positions; a pay that found no pill prints nothing, so pin taps per plan step (`TAP_AT`).
- The election's "הכנסת פוזרה" card is up only ~0.4 s; hold it with a slow clip speed. After it the
  game shows the era story card (about Bibi's hat), not the leader's.
- Flicker, two real bugs fixed: frame caches keyed by `id()` (Python reuses ids, stale frames
  flashed in) and drift rounded apart from the camera (the phone hopped a pixel and back). The A-B-A
  frame scan in the session log is the check; run it on every render.
- Handheld rotation and bar-line zoom kicks shimmer pixel text: keep them off.
- Files over 30 MB cannot be sent to Bar through the chat: send a 3.2 Mbps copy.
# HANDOFF: "עוד סבב" (2026-09-30, the character-copy session, stopped by Bar again)

**For the next agent:** this session reworked character copy and brought in the ChatGPT candidates,
**one character at a time** (Bar: "do all in loop, each character, each work we have"). Bar stopped it
twice. The second time was "stop, update the handoff, push to main". Everything below is on `main`.
**Not deployed:** the live site still serves the last deploy logged in `STATUS.md`.

## Done (all on main)
| Character / asset | Commit | What |
|---|---|---|
| Liberman | `daf077c` | The drawer government, a PM run from 8 seats, rotation talk with Bennett, the bloc pact |
| Generic MKs | `b8d67f8` | mk-offer, mk-undecided and mk-switcher rendered; `cutout.py` added |
| Eisenkot, Bennett, Lapid | `fdccfc8` | The "אין ישר" sign, no rotation, Tropper, Together as an "acquisition", Lapid offering No. 3 |
| Golan + Lazimi + Kariv | `df2e56e` | Both rendered, in Golan's round in the generic S5/L1 seats (same numbers); the "million votes" beat |
| Bibi + Herzog + Trump | `57cdd67` | Herzog's avatar on the pardon desk; a Washington-era Trump card (effect none, Bibi only); Bibi partner lines and rival ticker |
| Ben Gvir + Almog | `3258fbd` | The ministry shopping list, the merger with Smotrich he refused, the Gotliv/Almog "transfer window"; Almog rendered |
| Smotrich, Deri, Gafni, the partner bench, Tibi | `2c322e6` | Smotrich runs alone; Deri's corridor bench; Gafni off the next slate; sourced variants for Levin, Karhi, Distel, Abbas, Gantz and others. Tibi rendered, in Golan's round in the poach-only L6 seat |
| The 5 money sources | `f4dfaad` | submarine, poison, checkbook, donor and funds rendered (replacing the 1x drawings; 15 ui-kit rows removed); `iconFit` and a per-source `pad` in `build.py` |

**Totals:**
- about 38 new sourced facts;
- every leader-select fact launched on the About page;
- 11 candidates rendered.

**Last clean run:** `tools/test.sh` 439/439 and lint 0/0, on `f4dfaad` before main's parallel merge
(`59a04bf`, which added a `main.gd` line and picker tests). **Re-run the suite on main first.**

## Part 3 (Bar: "read the updated main and continue")
- `29a7dc8`: the ambient `target` filter. It was the untested patch; now tested and on main. A roast
  skips the round of the leader it roasts, and the "all" roasts skip the opposition leaders' rounds.
- `0184419`: Sara on the Balfour stage.
  - **Placement:** Bibi's round only, Bar's option B, right of the leader (mocks in
    `creative-pack/art/sara-options/`).
  - **Behaviour:** she huffs 150 ms after the S01 purchase, with an 8 s cooldown, and is off stage
    during the blockade.
  - **Code:** `ui/sara_mark.gd`; tested by `test_sara_mark`.
- This commit: `leaderSelect.neutralCopy` is finally read. `Meta.perks()` and `Meta.achievements()`
  give neutral names outside Bibi's round: no wand and no DOHA sticker for the opposition.
- `4fbb852` and `682af64`: partner lines that had no reader now show:
  - Gafni's `onPaidTicker` on a paid demand;
  - Almog's `poachTicker` on the poach pill;
  - Amsalem's no-exclamation-mark line (moved to `onPaidTicker`);
  - Bennett's `flipText` toast when a pledge runs out.
- **Browser check:** the full `mobile_web` matrix passed on this build (0/0/0 on all 9 devices, 16 min;
  strict `build_web.sh` green). The in-game shot is `creative-pack/art/sara-options/in-game-390x844.png`.
  - Sara reads well right of Bibi.
  - In the early round the taxpayer stands at her feet. Bar may want her 1-2 art px further right, or
    the taxpayer's slot moved.
- **Last run:** `tools/test.sh` 447/447 and lint 0/0 on main.

## Open items, in order
1. **Art still waiting:**
   - `mk-returner` looks like Netanyahu: regenerate it with a made-up face.
   - `aide` has no engine slot.
   - Elharrar, Vaturi, Zohar, Bismuth and Boaron were never generated.
2. **Unread copy:**
   - `neutralCopy`'s `ambient.*` and `golden.*` keys;
   - `copy.*` fields no code reads: Gotliv's transfer script, the brawl scripts, the partners'
     `copy.card` (there is no partner-card UI yet), `maygolan.cardLabel`.
3. **Before the next deploy:** `round_web` / `picker_web` / `motion_web`. `mobile_web` passed.
4. **Bar's calls:**
   - legal read of the new facts (`arab-lists-barred`, `gotliv`, `trump-herzog-ashamed`, `eisenkot-eight-seats`, `gafni-off-list`);
   - Kariv, Lazimi and Tibi in other lineups (run `tools/balance.sh`);
   - review of the renders (`pipeline/od-sevev/proofs/sprites-contact.png`).

## The loop (per character)
1. **Copy:** dump the character (leader kit, partner profile, event card, lineup overrides in other
   rounds), then rewrite. Keep the signature gag and add 2-3 **sourced** threads that cross into
   other characters' rounds, using per-lineup `lines` overrides so partners answer each other.
   Drop the shared templates: "X did 61 things" beat 1, "אם זה לא עובר…" threats.
2. **Facts:** each new thread gets a `design/facts.json` entry (url, date, label F/A/Q, a one-sentence
   `aboutHe`, reported speech when the Hebrew is unverified), and `usedIn` is filled in. The
   character's leader-select facts were never switched on after the picker shipped: flip
   `notUsed` to false.
3. **Art** (when a candidate exists):
   - `creative-pack/art/showcase/src/cutout.py` keys out the opaque RGB field (`--clear` boxes for
     hair pockets). Save the result to `refs/`.
   - Add `cast.py` landmarks (check them with an overlay), then `build.py <id>`.
   - Import with `pipeline/od-sevev/build.py --no-render --godot`.
   - Restore the pixel-identical PNG re-encodes and resync `budget.json` source sizes.
4. **Check:** `node design/sim/content-lint.mjs --strict` (0/0), `tools/test.sh`. Then commit one
   character per commit.

**Limits the rewrite obeys** (redlines.json + brief):
- nothing military or war-related, and no October 7 or hostages;
- the draft law is deliberately out;
- no group of people as the punchline;
- no invented quote marks on real people;
- ticker ≤ 60 characters, flavor ≤ 60, story lines ≤ 50;
- Eretz Nehederet's bits stay theirs (their spirit is fine).

The research behind the rewrite (Eretz Nehederet portrayals per character, the 2025-26 cross-party
arcs, fresh angles) was done this session by web search; the sources are in each fact's URLs.

---


---

# HANDOFF: "עוד סבב" (2026-09-30, end of session 6)

**For the next agent:** work directly, never through the base67 studio (Bar: "dont use base67 studio").
The repo is now a **bar_builds sibling at `~/od-sevev`** (moved out of `~/base67/`; pointer folder
`bar_builds/lab/personal/od-sevev/`, registered in `bar_builds/.repos.json`).

## State at the stop

- **Live:** https://od-sevev.vercel.app serves the build of **`e668348`** (web-dist `b4c9126`, Vercel
  `dpl_7XGqyhEBfokqa2JASf2C6PATLXpp`; live `index.html` + `index.pck` match the build byte for byte).
- **Branches:** `main`, `claude/magical-ride-ntn3u5` and `s5-mordechai` all point at `e668348`, pushed.
- **Worktrees on this Mac:** `~/od-sevev-s5` (`s5-mordechai`) and `~/od-sevev-webdist` (`web-dist`).
  Remove them with `git worktree remove` when done, never by deleting the folders.
- **Running at the stop:** `tools/balance.sh` in `~/od-sevev-s5` (the last step of the check chain;
  about 95 min; log `…/scratchpad/verify2/balance.log`, summary `verify2/summary.txt` in session
  467e07fc's scratchpad). If the scratchpad is gone, re-run `tools/balance.sh` on `main`.

## What session 6 did

1. **Mordechai David, built and on for launch** (spec `design/mordechai-david-spec.md`; §2, §4, §7.2, §9
   now say how it landed):
   - `blockade` effect (`events.gd`): a counting partner of 1-4 seats is benched 20 s; in `SEAT_COSTS`.
   - **He comes on at 1:00 of play** in the save's first round (Balfour), Bar's call: per-event
     `atPlaySec: 60`, fired ahead of the scheduler, never from the weighted pool; the two-member
     condition is gone, so at 1:00 the card usually reads `aloneText`.
   - `StreetFigure` (`game/scripts/ui/street_figure.gd`): walk in from the right (flip_h), plant at art
     x 150 in front of the right crowd, hold, one glance, walk out as the effect ends; a diorama layer
     behind the sources and the leader. The sprite faces screen-right as drawn (spec §2 fixed).
   - His toasts dock in the **lane band** (face + two lines, then who is stuck, then the end toast);
     a top-dock toast covered the leader's head on the SE. Ticker headline names him.
   - Dev hook: `?dev=1` + `window.odDevEvent = "mordechai"`.
   - Tests 438/438 (`test_events` blockade ×4, `test_street_figure` ×4; `test_progression`'s brawl
     test now starts its brawl explicitly), content lint 0/0, strict build green.
2. **Checks** (chain on `cf3e58b`, before the 1:00 change): `round_web` 2/3 (run 2: see "LayerHistory"
   below), `picker_web` 3/3, **full `mobile_web` matrix PASS**, strict build green.
3. **ChatGPT image batch** (Claude in Chrome, Bar's account): 16 refs in
   `creative-pack/art/refs/candidates/`, contact sheet `creative-pack/art/b14-options/chatgpt-batch-2026-09-30.png`:
   almog, kariv, lazimi, tibi, mk-switcher, mk-undecided, mk-offer, mk-returner, aide, donor, submarine,
   poison, checkbook, funds. **Not reviewed by Bar yet; none is rendered into the game.**

## Next, in order

1. **Read the balance result** and fill spec §6 (`RESULTS_PLACEHOLDER`): the per-leader first-election
   medians must stay 7-9 min, and the bench now prints "Mordechai David before the first election:
   n of 9 seeds" (expect 9/9 with the 1:00 timer).
2. **Run the full `mobile_web` matrix on `e668348`**: he now walks on at 1:00 in every fresh round, so
   every browser driver meets his toasts in the lane band. Serve `build/web` on a free port, one job at a time.
3. **Fix the LayerHistory back-button race.** `round_web` run 2: after "testify" while the chat layer
   was closing, a `go(-1)` fired with no layer left and the page navigated to `about:blank` (log in
   `verify2/round2.log`; the history calls are printed there). A player's back gesture can hit it.
4. **Image review with Bar, then render-down** (`creative-pack/art/CHATGPT-REQUESTS.md` "After generating"):
   - **mk-returner looks like Bibi** (the style ref's face leaked): regenerate with only `regev.png`
     attached, or with a note "must not resemble the attached men".
   - **kariv**: the prompt described glasses and a beard from memory; check the likeness before use.
   - Approved files move from `refs/candidates/` to `refs/`, then `cast.py` landmarks, d3 + d2 render,
     swap `avatar_nophoto`/`nophoto` for the four generic MKs, pipeline 0 cast drift.
5. **New MKs need game content, not only art** (Bar asked for Kariv and more MKs from both sides):
   a partner profile per leader lineup, facts with sources in `design/facts.json`, the red-lines and
   quote rules, and a place in the rosters. Kariv also ties to fact 73 (Mordechai David blocked his car).
   Design this with Bar before building (it changes lineups and balance).
6. **Still to generate** (stopped by Bar mid-batch): Karine Elharrar, Nissim Vaturi, Miki Zohar,
   Boaz Bismuth, Avichai Boaron, and the optional `bibi-hat-rabbit.png`.

## How the ChatGPT batch was driven (works; reuse it)

- One chat per image at chatgpt.com (Chat mode). Refs come from a folder this session can read (the
  upload tool rejects `~/od-sevev`; copy the refs into the session's scratchpad first).
- People: attach `refs/bibi.png` + `refs/regev.png`. Objects: attach `refs/hitech.png` + `refs/cigars.png`
  (the crisp sources) so they match the stage sources.
- **Keystrokes go to whichever tab is in front**, so typing into a background tab lands elsewhere. Insert
  the prompt by script: focus `.ProseMirror[contenteditable="true"]`, `execCommand('insertText', …)`,
  then click the button whose `aria-label` is `Send`. Wait about 9 s after an upload first.
- Download: fetch the last `img[alt^="Generated image"]` blob in the page and click an `<a download>`;
  Chrome saves to `~/Downloads`. Space the downloads a few seconds apart (three fired together were dropped).
- Real people: ask for "true to his/her real public likeness" and don't describe features.

## Bar's calls (don't decide them)
- Legal reads, now including Mordechai David's three facts and copy, and any new MK.
- Spec §14 D2 (Balfour only, or also the Knesset) and D3 (his orange).
- Which ChatGPT images are approved; which new MKs join which lineups.
- The pre-launch list (publisher and mail, domain).

---

# HANDOFF: "עוד סבב" (2026-09-30, end of session 5)

**For the next agent:** Bar stopped the studio loop and asked for a plain handoff. **Work directly.**
- Don't run the base67 gamestudio loop, and don't write a `/tmp/gamestudio-loop-active.lock`.
- No agent is running, and no lock is held.
- Everything below is on `claude/magical-ride-ntn3u5`, which was pushed.
- **The live site still serves `d73c206`.** Session 5 did not deploy.

## State at the stop

**Code:** `claude/magical-ride-ntn3u5` holds the four session-4 slices, merged, plus all of session 5's fixes. Its source HEAD for the next deploy is `c935f51`; the handoff commit only adds docs and patches on top.
- `main` is still behind: fast-forward it at the deploy (step 2).
- The session-4 patches are merged and deleted from `handoff-wip/`.

**Health at `c935f51`** (this Mac, one run at a time):

| Check | Result |
|---|---|
| `tools/test.sh` | 430/430 |
| `node design/sim/content-lint.mjs --strict` | 0 errors, 0 warnings |
| Strict `tools/build_web.sh` | green |
| `tools/web/mobile_web.mjs`, full default matrix | **PASS in one run.** 0/0/0 on all 9 devices: 375×667@2, 390×844@3, 393×852@3, 430×932@3, 360×780@3, 412×915@2.625, frame-1440×900@1, 390×664@3, 375×548@2. Includes S17 (settings reach), S18 (no toast over the leader) and the round-2 M2/S8 checks |
| `tools/web/motion_web.mjs` | **PASS** (936 s; the old 15-min cap problem is gone) |
| `round_web` / `picker_web` ×3 each | **NOT RUN.** Stopped at `round_web` run 1 |
| `tools/balance.sh` | **NOT RUN after M2.** It takes about 95 min here. The Game Developer argues M2's pacing delta is 0 by invariant (`bananas ≤ run_bananas`); the bench was 11/11 before M2 |

## What session 5 did (details in `STATUS.md` and the commit messages)
**The session-4 merge:**
- The four patches went in with `git am --3way`.
- Conflicts were only in `STATUS.md` and `tools/web/mobile_web.mjs`; both sides were kept.
- The pane slice's deviations were renumbered D51-D55 → **D55-D59**. Pre-tap keeps D51-D54.
- The generated strings came out identical.

**A6/A8 (settings):**
- The sheet can rise to Row A, the headers shrink 48→36, then it scrolls (D60, S17).
- A three-cue switch (D61).
- **The ON knob sits on the LEFT:** the RTL mirror, rtl-map §7.4 / R6. The dev objected to the old note "knob on the right", and Bar confirmed left.

**The UX merge review:** `ux/review-2026-09-30-merge.md` (M1-M8). Every HANDOFF A/B/D item is closed.

**M1-M5:**
- toasts dock in the lane band before tap 1 and hold for the undo chip at round 2 (D62/D63, S18);
- card 1 at every round start (`producers[0].revealAtRunEarned: 0`);
- the teaser floor rows show silhouette only;
- the P0 hand points at the tap prop;
- the after-election undo chip sits on a navy tab.

**D64:** a balanced picker caption break (it fixed an S8 flake at 360×780).

**After-shots:**
- The fresh `dev2-*` in `ux/manual-test-2026-09-30/fixes/` are the merged build's evidence.
- `review/*-after.png` are the M1-M5 crops.
- The `art-*` and `dev1-ceremony-*` shots predate the merge (M6), so don't cite them as proof.

## Next, in order

### 1. Finish verification (quiet machine, one job at a time)
```
python3 -m http.server 8872 --directory build/web &
export PLAYWRIGHT_MODULE=/Users/barmoshe/fretboard-897887/node_modules/playwright/index.mjs
node tools/web/round_web.mjs  http://127.0.0.1:8872/ <out>/round1    # ×3
node tools/web/picker_web.mjs http://127.0.0.1:8872/ <out>/picker1   # ×3
tools/balance.sh                                                     # ~95 min
```
- Rebuild first (strict `tools/build_web.sh`) if `build/web` is older than `c935f51`.
- A runner that does all of this in sequence: see "Environment".

### 2. Deploy #1: this build
Bar's standing instruction: deploy and push automatically when everything is green.
1. Run strict `tools/build_web.sh` from `c935f51` (or the branch HEAD; the handoff commit is docs only).
2. Follow "Deploy" below:
   - replace the `web-dist` files with `build/web/*` + `tools/web/vercel.json` + `tools/web/.vercelignore` and a README naming the source sha;
   - commit `chore(od-sevev): web build of <sha> for Vercel` and push `web-dist`;
   - run the Vercel connector's `create_deployment` from `web-dist`.
   There's no Vercel CLI on this Mac, and `tools/deploy_web.sh` needs one (`npx vercel` + `vercel login`).
3. Check https://od-sevev.vercel.app serves the new build.
4. Fast-forward `main` to the branch and push both.

### 3. Mordechai David + B14 signs: the next slice, deploy #2
Bar's decisions this session:
- **B14 = option D'**: handmade kraft cardboard, with ink and flag-blue marker lines.
- **Mordechai David is IN**: a satirical blocker who walks onto the Balfour stage and stands in front of the protest crowd. This reverses the pitch's "drop".
- Ship it *after* deploy #1.

Two patches hold the work, based on `eb14e83`, the merge-review commit on this branch:
```
git checkout -b s5-mordechai claude/magical-ride-ntn3u5
git am --3way "handoff-wip/s5-art (B14 D' + Mordechai sprite).patch"      # 2 commits
git am --3way "handoff-wip/s5-design (Mordechai spec + content).patch"    # 2 commits
```
- **Expected conflicts:**
  - `STATUS.md` (append-only: keep both);
  - `HANDOFF.md` (keep this session-5 text, and add the design patch's legal-reads line);
  - generated `game/assets/sprites/sprites.json` / `pipeline/od-sevev/budget.json`: re-run `pipeline/od-sevev/build.py --no-render --godot`, never hand-merge;
  - `design/content.json` → `tools/sync_data.sh`.
- **The art patch** (`61a29f8`, `f4431a6`):
  - the D' signs in `creative-pack/art/src/locations.py` `balfour()` and `art/od-sevev/src/wave7.py`, with the approved showcase `stage_balfour.png` updated;
  - Mordechai rendered down from Bar's ref (`creative-pack/art/refs/mordechai-david.png`; rig in `creative-pack/art/showcase/src/mordechai.py`).
  - **His anims:**

    | Anim | Frames | fps | Loop | Events |
    |---|---|---|---|---|
    | `idle` | 20 | 10 | yes | — |
    | `walk` | 8 | 10 | yes | step 0/4 |
    | `block_in` | 4 | 12 | no | plant 1 |
    | `block` | 3 | 6 | yes | — |
    | `glance` | 10 | 10 | no | smirk 4 |

  - Frame sizes: 210×292 at d3, anchor [85,291]; d2 is 141×195 [57,194]. Placement is in `pipeline/od-sevev/CONTRACT.md` §4.
  - Pipeline: 0 cast drift; tests 421/421 on its base.
  - The sheet: `creative-pack/art/b14-options/s5-art-sheet-signs-and-mordechai.png`. The options and references: `creative-pack/art/b14-options/B14-options.md`.
- **The design patch** (`83b73b4`, wip `505ec85`):
  - the `mordechai` event in `design/content.json`, with effect `none` and `designerEffect: "blockade"` and the flag still false;
  - facts 73-75 with URLs; fact 47 stays out;
  - the name in `design/redlines.json` is **narrowed, not lifted**;
  - the spec `design/mordechai-david-spec.md`: Balfour-only, so a first-round cameo, at most once per save; all 8 leaders with three copy skins; the effect `blockade`, a small cost in every round and never a buff.
- **To do:**
  1. **The spec's §6 bench is unfinished** (`RESULTS_PLACEHOLDER`). Implement §7.1's effect, run the leader bench with `flags.mordechaiDavid: true`, and fill in §6. The first-election medians must stay 7-9 min per leader.
  2. Implement §7.1 (the effect), §7.2 (the presenter; there is no event view today), §7.3 and the §7.4 lint.
  3. Wire the sprite: walk in from the right edge, `block_in` → `block` hold, `glance`, then walk out, per spec §9 and CONTRACT §4. Draw him **behind** the leader, and never stop him inside art x 66-114.
  4. **Reconcile the facing.** Spec §2 says "the ref faces screen-left, toward the leader". The artist's sprite faces **screen-right as drawn**, facing the right crowd at feet x 150, and uses `flip_h` for the left crowd at x 28. Check the real frames (the sheet) and fix the spec's line to match the sprite.
  5. Turn it on (§7.5: `mordechaiDavid: true`). Then run the lint, `test.sh`, the strict build, `mobile_web` (the full matrix) and a forced-event look at 390 and SE.
  6. Deploy #2 the same way as step 2.

### 4. Bar's calls (don't decide them)
- **Legal reads**, now including Mordechai David's three facts and copy (spec §14 D1).
- **Spec §14:**
  - D2, the dose: Balfour-only, or also the Knesset with a portable crowd;
  - D3, his orange: keep it, as recommended, or neutralise it.
- The pre-launch list at the bottom: publisher and mail, domain. Bar said "not yet".

## Environment (this Mac)
- **Godot:** 4.7.2 at `/usr/local/bin/godot`; `tools/godot.sh` finds it. The export templates are in `~/Library/Application Support/Godot/export_templates/4.7.2.stable`.
- **Playwright:** `mobile_web.mjs` and friends default to `/opt/node22/...`. Set `PLAYWRIGHT_MODULE=/Users/barmoshe/fretboard-897887/node_modules/playwright/index.mjs` (v1.62.1, which matches the installed chromium-headless-shell).
- **Run times:**

  | Job | Time |
  |---|---|
  | `test.sh` | about 3 min |
  | strict build | a few min |
  | full `mobile_web` | about 40 min |
  | `motion_web` | about 16 min |
  | `balance.sh` | about 95 min |

  Use a unique http port per job, and never run two browser jobs at once.
- **The Pillow encoder** on this Mac writes PNGs byte-differently from the repo's. After a pipeline import, restore HEAD bytes for pixel-identical files so the diff only holds real changes.

---

## HANDOFF: "עוד סבב" (2026-09-30, end of session 4)

*Session 4's handoff (superseded where session 5 above says so; its patches are merged).*

No agent is running and the studio loop lock is released. `main` and `claude/magical-ride-ntn3u5` are unchanged since session 3, apart from docs. **Session 4's work is NOT merged:** it is four patches in `handoff-wip/`. The live site still serves build `d73c206`.

## Session 4: where it stopped (Bar: "update the handoff and stop")

**Goal:** the manual-test work list below (A1-A8, B9-B13, B15, D19-D21). B14, the pink signs, stays Bar's call.

**How it ran:** Bar said "use the studio". The loop ran as the base67 studio: the lock was at `/tmp/gamestudio-loop-active.lock`, and each agent worked under its `gamestudio/.claude/agents/<role>.md` prompt and returned an artifact or a typed objection. No objection was raised before the stop.
- **Baseline:** `tools/test.sh` 393/393 at `2cc33b1`.
- **Environment:** Godot 4.7.2 went into the scratchpad and the export templates into `~/.local/share/godot/export_templates/4.7.2.stable/`.

**The four slices** (git worktrees off `2cc33b1`; local branches `worktree-agent-*`, this container only):

| Slice (studio role) | Items | State at the stop | Patch |
|---|---|---|---|
| 2D Artist + TA | A1 plaza + lane, B13 booth | **Done.** It reported test 393/393, a green strict build and `mobile_web` PASS on 390 and SE. It had not yet reported back. Its wip commit carries its STATUS/style-guide lines and after-shots | `handoff-wip/2D-Artist-+-TA.commits.patch` (3 commits) |
| Game Developer (+ Animator, + Game Designer for B15) | A4, A5, B15 committed; A6 settings reach, A8 toggle states in the wip commit | A4/A5/B15 committed with tests. **A6/A8 unfinished:** it was waiting on the full `mobile_web` matrix | `handoff-wip/Game-Developer-(ceremony+settings).commits.patch` (3 commits) |
| UX Designer + Game Developer (pre-tap) | A2, A3, A7, B10/D22, B12 | Committed with `test_pretap_hud.gd` (9) and `mobile_web` S13-S16. Its last `mobile_web.mjs` / `pretap_shots.mjs` edits are in the wip commit. It was waiting on the full matrix | `handoff-wip/Game-Developer-(pre-tap+HUD).commits.patch` (2 commits) |
| UX Designer + Game Developer (pane) | D19, D20, D21, B9, B11 | Committed (3 commits, nothing uncommitted). It was waiting on the full `mobile_web` matrix | `handoff-wip/Game-Developer-(pane).commits.patch` (3 commits) |

**What each slice changed** (details in the patches' commit messages and their `STATUS.md` lines):
- **A1:** one Jerusalem-stone paving per era (`wave5.Paving`). Random-length slabs in 2-3 tones, short broken mortar joints (never black), no press cable (that cable was the "worms" and the black line above the ticker). The plaza goes 192x192 and the lane 192x28 (+0.47 MB VRAM).
- **B13:** `booth_frame` / `_tall` become a kraft-cardboard folding screen with a blank flag-blue band. Same size and 9-slice.
- **A4/A5:**
  - the walk-out is the ceremony's f0, on the old stage;
  - the card dims in over the empty stage, and the era swaps under the fully opaque page;
  - the lines step out before the page lifts empty;
  - `motion/state-graph-magician.md` §9 is at rev 2.
- **B15:** all 8 leaders already had their own flash cards. The T4 story archive replayed Bibi's beats for everyone; it now rebuilds from `story_seen` (`Story.archive`). The content lint gains §6b, and three lines move to reported speech.
- **A2/A7/B10/B12/A3:**
  - card 1 (dim) and Row A are up from the pick, and the plaza is an 84-px strip;
  - Row A's right end shows the leader's medallion and short name, replacing the name toast over the stage;
  - the undo chip sits on a navy bar;
  - the picker caption sits on a navy plate;
  - ux decisions D51-D54, `ux/ftue.md` rev 5.
- **D19:** root cause: the pager rolled in an empty page when nothing was queued. A one-page headline now holds for up to 15 s, else the pager shows the standing line `TICKER_IDLE` ("מהדורה מיוחדת").
- **D20/D21/B9/B11:**
  - the white field becomes a ruled margin;
  - the tab bar always shows four slots, with padlock silhouettes;
  - the first teaser carries "עוד מקורות ייפתחו" and the rest fade;
  - the chat starts under the header with a "היום" chip;
  - ux decisions D51-D55.

**Merge notes (expected conflicts):**
- **The pre-tap and pane slices both number new deviations D51+** in `ux/mobile-first-layout.md`. Renumber one set (pane → D55-D59) and its references.
- **Shared files:**
  - `tools/web/mobile_web.mjs` (three slices), `game/scripts/ui/dev_probe.gd` and `game/scripts/main.gd`: keep both sides;
  - `STATUS.md`: append-only, keep both sides;
  - the generated `ux/ui-strings.json`, `ux/string-budgets.json` and `game/data/ui-strings.json`: re-run `ux/tools/gen_strings.py` and `tools/sync_data.sh`; `design/content.json` → `tools/sync_data.sh`.
- **Merge order:** art first, then pane, then pre-tap (Row A and the pane both use the ticker slot, so check the pre-tap plaza strip against D19's standing line), then ceremony.

**Restore:**
```
git checkout -b restore-s4 claude/magical-ride-ntn3u5
git am --3way "handoff-wip/2D-Artist-+-TA.commits.patch"
git am --3way "handoff-wip/Game-Developer-(pane).commits.patch"
git am --3way "handoff-wip/Game-Developer-(pre-tap+HUD).commits.patch"
git am --3way "handoff-wip/Game-Developer-(ceremony+settings).commits.patch"
```
The patches include binaries. All four are based on `2cc33b1`, and the commits after it on this branch are docs only.

## Next, in order (session 5)
1. Restore and merge the four patches (merge notes above). Finish A6/A8 in the ceremony slice.
2. Run `tools/test.sh`, `node design/sim/content-lint.mjs --strict`, strict `tools/build_web.sh`, and `tools/web/mobile_web.mjs` on the **full matrix**, one run at a time. None of the slices got a full-matrix pass before the stop.
3. A studio UX Designer review of the merged build against the after-shots in `ux/manual-test-2026-09-30/fixes/`, then fixes.
4. The C16 re-runs on a quiet machine: `motion_web.mjs` (A5 changed the ceremony timing), `round_web`/`picker_web` 3× each, the full `tools/balance.sh`.
5. Redeploy (see "Deploy" below), then delete `handoff-wip/` in the final handoff.

**Still waiting on Bar:**
- B14, the pink protest signs;
- the pre-launch list at the bottom;
- permission to push agents' wip branches to GitHub (so far only patches).

---

## HANDOFF: "עוד סבב" (2026-09-30, end of session 3)

*Session 3's handoff (still accurate except where session 4 above supersedes it):* no agent was running at its end. Everything was committed and pushed to
`claude/magical-ride-ntn3u5`. `STATUS.md` is the full agent log, newest at the bottom.
`HANDOFF-LIVE.md` is the last minute-by-minute snapshot of the loop (agents, slices, notes).

## Session 3, final state (2026-09-30; Bar stopped the loop to test the deploy)

Everything is merged into `claude/magical-ride-ntn3u5` and into `main`. No agent is running, the loop lock is released and `handoff-wip/` is gone. Tests: 393/393. Content lint: 0/0. The strict build is green, and it is deployed to https://od-sevev.vercel.app.

**What's in the build:**
- **The leader picker:** all 8 leaders playable, with per-leader views, the walk-out and walk-in, and the audio.
- **The mobile-first layout** (`ux/mobile-first-layout.md`):
  - it fills the whole phone, height and width (Bar's width rule, checked by `tools/web/mobile_web.mjs`);
  - the ticker pages, with a roll between pages.
- **Palette v4, Israeli blue and white** (Bar approved it): a flag-blue HUD, a white card field, ballot-slip icons, the blue-envelope flap on modals, the booth around the picker, the 120-seat hemicycle on the election card, Jerusalem-stone floors, and official-notice settings, gate and election screens.
- **UX review 2** (`ux/review-2026-09-30.md`): U1-U16 fixed.
- **The election gate holds:** the vote stops the clock under the election card, including the window after "עוד סבב!". Balance is 7:51-8:19 median per leader.

**Open (session 4):**
- **`tools/web/motion_web.mjs`** exceeded its 15-min cap after the walk-out step on a loaded machine. It waits for the flash or picker at `slow=40`. Probably slowness, not a game bug (the unit tests cover the flow), but confirm on an idle machine.
- **`round_web` / `picker_web`** now share one player (`tools/web/round_play.mjs`). They were not re-confirmed 3× before the stop.
- **The full balance run** was stopped mid-suite: the per-leader medians and the Bennett, Ben Gvir, Liberman and Eisenkot player-type lines were green, and the rest was not re-run after the gate rule.
- The optional M3 (the hemicycle fill-in motion); A5's tall booth header is wired only if it fits.
- **Bar's pre-launch list** below still stands.

## Manual test pass (2026-09-30, orchestrator by hand, no agents) and the recommended work

**What I ran:** build `d73c206`, the one deployed. I played it by hand in headless Chromium at 390×844@3 (iPhone 14) and 375×667@2 (SE), and forced one election with `?dev=1` + `window.odDevElect = 1`:
- disclaimer → picker → pick → tap 1 → card 1 → first buy → C1 tabs → C2 seats row → coalition chat → settings;
- the election ceremony → Dubi's story card → the picker after the election (with the +10% chip and "עוד סבב עם ביבי").

**Result:** `mobile_web.mjs` PASS on both phones, no page errors, and the whole flow works end to end. The screenshots are in `ux/manual-test-2026-09-30/` (half size). What still looks bad or rough, most important first:

### A. Visible defects (fix first)
1. **The Jerusalem-stone plaza reads as worms, not stone** (`01`, `02`, `09`). The plaza tile's long black wavy joints line up across tiles into big snake shapes. They fill about 45% of the screen before tap 1 and sit behind the picker's footer.
   - *Fix (2D):* redraw `plaza_<era>` with short, sparse, low-contrast joints (mortar tone, never black), break the repeat with 2-3 tile variants, and add a few stone details.
2. **Before tap 1 and until card 1, the lower half of the screen is only stone** (`01`, `02`). There's no content, no hint and no card. It's the first thing a new player sees after the pick.
   - *Fix (UX + dev):* show the first card (or the teaser rows) from the first frame, or a clear "tap him" hint card. Keep the floor to a strip.
3. **The picker's footer caption is white text straight on light stone**: "בכל סבב בחירות אפשר להחליף ראש רשימה. הבסיס נשאר." has low contrast and the cracks run behind the letters (`09`).
   - *Fix:* put it on a navy plate or a white notice card, like the ticker.
4. **The election ceremony card is translucent over the ticker** (`07`). Its lines ("סבב בחירות מס׳ 2", "תחנה חדשה: הכנסת", "×1.0 → ×1.0", "+0 לבסיס") print over the ticker's own text, so two texts overlap and neither reads.
   - *Fix (dev):* make the EVOLVE_TX card opaque (the v4 notice) or hide the ticker under it.
5. **The era changes before the old leader walks out** (`07`). About 0.9 s into the ceremony, the stage is already the next era (Knesset) with the old leader on it.
   - *Fix (Animator + dev):* the walk-out runs on the old stage; swap the stage under the opaque card afterwards.
6. **The SE settings sheet hides "איפוס התקדמות"** (`06`). The sheet ends at "אודות ומקורות" and "סגור", and the reset row isn't reachable.
   - *Fix (dev):* scroll the sheet, or tighten the rows on short screens. Add a `mobile_web` check that every settings row is on screen.
7. **The leader's name plate covers the stage** (`01`, `02`). At 390 it covers the top of the building, and on the SE it sits on the leader's head.
   - *Fix (UX + dev):* a slim plate under Row A, or in the stage's sky clear of the hit box. Check it on the SE.
8. **The settings toggles don't show their state** (`05`, `06`): a dark/white half-block labelled only "כבוי".
   - *Fix (2D + dev):* a clear ON look (flag-blue fill with a knob on the right, labelled "פועל") vs OFF (grey, "כבוי").

### B. Rough, worth polishing
9. **Teaser rows:** 5-6 identical pale "מקור עלום" rows (`03`) read as filler. Show one or two, fading down, with varied silhouettes, or a one-line hint ("עוד מקורות ייפתחו").
10. **The HUD's right side is empty in round 1:** only the settings and mute icons sit on the left, and the money and rate are crowded in the centre. Consider the leader's mini-portrait and name there (which also answers item 7).
11. **Chat** (`04`):
    - a large empty blue area sits above the first messages;
    - the gold "העברה:" chip floats alone at the left edge;
    - fix: anchor the thread under the header, or fill it with the date or system line, and give the chip a row.
12. **The "להחליף ראש רשימה" button before tap 1** floats on the stone. Give it a proper bar or chip position.
13. **The picker's top** is an empty sky band over the title, and the `booth_frame` reads as a thin brown line rather than a קלפי. Try `booth_frame_tall` with a header, or a cardboard colour, so it reads as a polling booth.
14. **The stage protest signs are still pink and white** (v2 accents). v4 moved pink off the UI only because the stages were frozen. *Bar's call:* recolour the Balfour crowd signs to blue and white (a stage re-render, no cast drift).
15. **Dubi's post-election story card** ("הכובע שלא נגמר") is Bibi-specific. Check that every leader gets their own story card, and re-run the quote lint on the story lines ("בלשכה מסרו", "דובי:") under the reported-speech rule.

### D. From Bar's real iPhone (in-app browser, 10:38; `10-bar-iphone-inapp.png`)
The layout holds on a real device inside an in-app browser with its own top and bottom bars: full width, the tab bar above the browser bar, a sharp cast. What it shows:
19. **The ticker row is empty.** The "מבזק" plate, Dubi and the date show, but there's no headline text. The same gap appears in the headless `card1` shot. Between pages or headlines, the pager leaves the strip blank, so it looks broken.
    - *Fix (dev + Animator):* never show an empty strip. Hold the last page until the next one rolls in, or show a standing line (the date or "עוד סבב · 27.10").
20. **White slivers along the card list.** The v4 white field shows as thin white strips left and right of the blue cards, and a grey scroll line runs at the far left. On the phone it reads as a rendering gap, not a design.
    - *Fix (UX + 2D):* either make the cards full-bleed (the pane edge-to-edge in blue, with gutters in `ui_panel`), or make the white field clearly intentional: a wider margin, with a ruled edge like a ballot sheet. Style the scroll line, or hide it when idle.
21. **The tab bar shows 2 tabs and 2 empty slots with dividers.** Unrevealed slots look missing.
    - *Fix:* hide the dividers of empty slots, or draw locked silhouettes (like the teaser rows), so the bar looks complete.
22. **The HUD's right side is empty,** confirming item 10.
23. **Pink protest signs,** confirming item 14.

### E. Images to generate in ChatGPT
The full list, with prompts and rules, is in **`creative-pack/art/CHATGPT-REQUESTS.md`**. In short:
- **Must-have** (today a silhouette):
  - אלמוג כהן;
  - the four generic MKs (switcher, undecided, offer, returner);
  - the aide.
- **Worth doing** (chunky 1× next to the crisp cast): the submarine, the poison machine, the golden chequebook, the generic donor, the budget binder.
- **Optional:** Bibi's hat and rabbit as a hi-res ref.

### C. Verification still open
16. Re-run on an idle machine:
    - `tools/web/motion_web.mjs` (it hit a 15-min cap after the walk-out at `slow=40`);
    - `round_web` and `picker_web` 3× each;
    - the full `tools/balance.sh`, after the gate rule.
17. Real-device checks on an iPhone: the share sheet, audio (the first sound is now `leaderPick`), the safe areas, and the Safari toolbar heights.
18. Bar's pre-launch list below: publisher and mail, domain, source links, the legal reads.

## Session 3: where it stopped

**Health of the branch:** `tools/test.sh` 340/340; `node design/sim/content-lint.mjs --strict`
0/0; strict `tools/build_web.sh` green at the last merges. Live site: https://od-sevev.vercel.app
serves build `d13256e` (Bibi only; the picker is not deployed yet).

**Merged today:**
- Audio v1.3: `leaderPick` (safe as the first iOS sound), `Audio.crit_for`, per-leader squawks, coverage of every view.
- Animator: Bibi's court-day exit and return, the `court_window` echo, the motion audit, the brawl boil, and the web reduced-motion fix. The `LeaderWalk` helper is ready but not wired.
- **The leader picker** (`ui/views/view_pick.gd`, `ui/leader_ui.gd`): all 8 leaders playable end to end, with per-leader views and the press skin for non-Bibi. `tools/web/picker_web.mjs` passes.
- Designer:
  - leader-sim fixes (Liberman's `mk_returner`, the G1 median);
  - every leader's median first election is 7:51-8:50;
  - R17 slots, Bibi's rule, the "רוב" lint, neutral `DAYS_*`;
  - the web-driver bench, which explains the 34-vs-8 minutes: the browser script is a slow player.
- UX: `ux/mobile-first-layout.md` (Bar: "the mobile layout isn't good, it must be mobile first") and `tools/web/mobile_web.mjs`. Today's build fails its 108 layout checks; the baseline passes.
- The live site was redeployed from `d13256e`. It fixes the relative `og:image` (WhatsApp previews had no image) and a dirty old build.

**Stopped mid-slice (work is NOT merged; restore it first):**

| Slice | Branch (local, this container only) | Patch in this repo |
|---|---|---|
| Game Developer: implement the mobile-first layout (spec §8, §3-§7, §5) | `worktree-agent-a8bd968153c51c052` (4 commits after the merges) | `handoff-wip/Game-Developer-(mobile).commits.patch` |
| 2D Artist + TA: lane tile, plaza, stage wings, XL pick avatars, brawl cut, court spots | `worktree-agent-ab7cb5f96a4c16bc8` (last commit a wip checkpoint) | `handoff-wip/2D-Artist-+-TA.commits.patch` |

- **The developer** committed the art grid, the split and the fluid chrome core, the tall tabs, modals and sheets, the merge-ready chat line (`CHAT_SYS_MERGE_READY`) and the per-device layout tests. It was about to build and run the full `mobile_web.mjs` matrix. Not done:
  - the matrix pass;
  - the picker's bottom-anchored layout check;
  - the before/after sheet;
  - the crowd x-clamp and right-wing slots (the Designer's R17 objection, accepted by the orchestrator).
- **The artist** made the art. Its final merge, `tools/test.sh` and the strict build were not re-run.

**Restore:** if the branches still exist locally, merge them. Otherwise:
```
git checkout -b restore-mobile claude/magical-ride-ntn3u5
git am --3way "handoff-wip/Game-Developer-(mobile).commits.patch"
git am --3way "handoff-wip/2D-Artist-+-TA.commits.patch"
```
The patches include binaries, and they include merge-base commits already on the branch, so skip any that `am` reports as already applied. Then run the tests, the strict build and `mobile_web.mjs` on the whole matrix.

## Next, in order (session 4)
1. Restore both stopped slices, then finish the mobile implementation until `tools/web/mobile_web.mjs` passes all its layout checks on the whole matrix. Review the §9.2 visual checklist at 375×667@2, 390×844@3, 430×932@3 and 412×915@2.625.
2. The Animator's second slice: wire `LeaderWalk` (walk-out at the election, walk-in on the pick; it currently fights the court-pose code, which sets the position every frame), and M1, the ticker page transition.
3. A UX review of the picker and the mobile build on the full build; fix what it finds.
4. Strict build, a browser pass (the picker, the mobile matrix, the share cards), then redeploy (see "Deploy" below). Only then does the live site show all 8 leaders.
5. A final handoff, releasing the lock and deleting `handoff-wip/`.

**Watch:** Eisenkot's casual first election is at 9:00, the gate's edge. The worst partner seats for Bennett and Ben Gvir run past 10:00.

**Waiting on Bar:**
- permission to push the agents' wip branches to GitHub as backup (so far only patches in `handoff-wip/`);
- whether to document the od-sevev external-repo exception to the studio's I13 in `gamestudio/`;
- the pre-launch list at the bottom.

**Studio notes:** `validate`, `dog-audit` and `cross-ref-audit` are all clean. The gamestudio Stop hook isn't loaded when the session runs outside `gamestudio/`, so the orchestrator keeps the loop by discipline. Agent work is snapshotted every minute into `HANDOFF-LIVE.md` and `handoff-wip/` by a scratchpad script. Recreate it next session if wanted.

---
*Session 2's handoff follows; it is still accurate except where session 3 above supersedes it (its "Next" items 1-3 are done).*

## Where things are

| What | Where |
|---|---|
| Source (this repo) | `barmoshe/od-sevev`, branch `claude/magical-ride-ntn3u5` (94 commits since `d366061`) |
| Live game | **https://od-sevev.vercel.app**. Public; it serves build `e067444`, which is older than the branch (see "Deploy") |
| Vercel | team "barmoshe's projects" (`team_ok1MqoSMeupTyBE6CXAR91UT`), project `od-sevev` (`prj_ZbQ1ubW0AU5hfhSVnVtcsgmm6BVA`). Vercel Authentication is on for previews only |
| Deploy branch | `web-dist`: the static output of `tools/build_web.sh`. It holds generated files only; never edit it |
| Leader-select design | `design/leader-select-spec.md` (the designer's spec; §10 is the replacement checklist, §12 Bar's calls) |
| Picker UX | `ux/rtl-map.md` §8 (the `LEADER_PICK` screen), §4.3 (HUD per leader); `ux/screen-graph.md` §0 |
| UX review | `ux/review-2026-09-29.md` (R1-R26; all closed) |
| Sources | `design/facts.json` (72 facts), `design/facts-verification.md` |

**Health at `8d28ac1`:**
- `tools/test.sh`: 301/301.
- Strict `tools/build_web.sh`: green (content lint and text lint 0).
- `node design/sim/content-lint.mjs --strict`: 0 errors, 0 warnings.
- `tools/balance.sh`: last verified green (5/5) at `5f64cf2`. **It was not re-run after the leader sim merged** (see Next).

## Run it
```
tools/test.sh                       # headless unit tests (Godot 4.7.2 via tools/godot.sh)
tools/build_web.sh                  # strict: content lint (red lines) + pixel text lint, then export to build/web
python3 -m http.server 8801 --directory build/web
node tools/web/res_web.mjs  http://127.0.0.1:8801/ <dir>    # scaling + first squawk
node tools/web/views_web.mjs http://127.0.0.1:8801/ <dir>   # flash, cottage, phone frame
node tools/web/modals_web.mjs / share_web.mjs / round_web.mjs  # modals, share cards, a full round
tools/balance.sh                    # pacing bench, about 11 min
xvfb-run -a python3 pipeline/od-sevev/build.py --no-render --godot   # re-import art (the --godot pass needs a display)
```

**Environment notes:**
- **Godot:** in a cloud container, download 4.7.2 into the scratchpad, where `tools/godot.sh` looks. Export templates install into `~/.local/share/godot/`.
- **Network:** the container can't reach `vercel.app`. Check a deployment with the Vercel connector's `web_fetch_vercel_url`.
- **Parallel agents:** use git worktrees and a unique http port each; two agents on one port once read each other's build. `STATUS.md` conflicts are append-only, so keep both sides.
- **Generated files** (`sprites.json`, `budget.json`, `ui-strings.json`): resolve conflicts by re-running the generator or pipeline, never by hand.

## Deploy
There is no Vercel CLI token in the container, and the connector can't upload the 40 MB wasm, so the deploy goes through git:
1. Run `tools/build_web.sh`. It is strict, and `OD_SITE_URL` defaults to `https://od-sevev.vercel.app/`, so the OG tags come out absolute.
2. Replace the `web-dist` branch's files with `build/web/*` + `tools/web/vercel.json` and a README, commit and push. A worktree of `web-dist` works well for this.
3. Vercel connector `create_deployment`, team above, `name: "od-sevev"`, `gitSource {type: github, org: barmoshe, repo: od-sevev, ref: web-dist, sha: <commit>}`, `projectSettings {framework: null, buildCommand: "", installCommand: "", outputDirectory: "."}`. A deploy to the project goes to production.

On Bar's Mac, `OD_VERCEL_PROJECT=od-sevev tools/deploy_web.sh` still works with the CLI.

## What changed this session (all merged)
- **Resolution:**
  - Integer device scaling, with k restricted to multiples of 2 or 3, so the cast is whole-pixel on every phone.
  - The whole cast at d=3 and d=2.
  - Sevev 9 @2, a double-density Hebrew font, for reading text.
  - The scrim, the dim and the flash were invisible and are fixed.
- **Screens:** the coalition chat (T3) and the partner card; the dossier (T4) with the pardon desk; the thermometer with sweat; the court card and chip; Dubi's news flash; the cottage cup; the desktop phone frame; the election, return and reset modals; the share cards (receipt and result) with WhatsApp; the pending chip; the brawl cue; the spin-end toast.
- **Sim:**
  - The 5 held spins, trophy stats and pacing re-tuned to the pitch's gates (first election 7-9 min).
  - The brawl trap is fixed in the view.
  - **The leader-select core** (`game/scripts/sim/leaders.gd`: install per leader, knobs, filters, save v4, per-leader bench). **Dormant:** it defaults to Bibi until the picker exists.
- **Content:**
  - The player character is "ביבי", never "הקוסם".
  - Every launch fact has a source and a public Hebrew `aboutHe`.
  - Full kits for all 8 leaders.
- **Guardrails:**
  - **No October 7, anywhere:** the lint covers content, UI strings and About, plus the 7.10 date forms. `tools/build_web.sh` fails on any hit. An art sweep ran too.
  - **Quotes:** invented quotes of real people are forbidden. Use reported speech unless the quote has a sourced [Q] fact.
- **Art:**
  - Tap animations and props for all 8 leaders.
  - The lineup key art, OG image and app icon.
  - The UI kit (242 pieces), the spin icons, and a no-photo silhouette for partners without art.
  - Yair Golan re-rendered from Bar's ref.

## Bar's decisions (keep them)
- **Protagonist:** ביבי is named, never הקוסם. No mention of October 7, direct or by date or image.
- **Leader select:** each round the player picks one of 8 party heads:
  - ביבי, בן גביר, סמוטריץ׳, דרעי · בנט, אייזנקוט, ליברמן, גולן;
  - Lapid rides inside Bennett's round; Gantz, Abbas and UTJ are out;
  - the picker comes before the first tap and replaces the title;
  - +10% base for switching leaders;
  - the lineup key art replaces Bibi-with-hat;
  - Bibi's lineup keeps today's partner numbers.
- **May Golan:** option 1. The new Yair Golan ref is `creative-pack/art/refs/golan.png`.
- **Kept on purpose:**
  - spin s12's name "הוחלט להקים ועדה" (its icon was redrawn without chairs);
  - s09 "פייג׳ר זהב";
  - the "ידיים של קוסם!" idiom.
- **WhatsApp:** "לשתף בוואטסאפ" is allowed as a functional label only. There is a scoped exception in `design/redlines.json`, and no WhatsApp styling.

## Next, in order
1. **Build the leader picker (views and engine).**
   - Implement `ux/rtl-map.md` §8 against the sim API in `game/scripts/sim/README.md` (`Leaders` / `Politics.install`, `start_round`, undo).
   - Work through spec §10's checklist.
   - Swap in the `_LEADER` / `_NEXT` string keys.
   - Switch `SHARE_TEXT_INVITE` to `_NEXT` and update `test_share_view.gd:99`.
   - Draw the tap props at `propMouth`, per CONTRACT §4c.
   - Hide the Bibi-only views (court, pardon, aide, Sara, DOHA, spins s07/s09/s10/s14/s15) for everyone else; they get the press skin.
   - Add Liberman's "לא יושב" pill and Golan's "לאחד" pill.
2. **Verify the leader sim.** Run `tools/balance.sh` and the per-leader bench (`game/tests/bench/test_leaders_balance.gd`). Liberman's lineup is the tightest, so apply the spec's fix if he runs over 9 min. The sim developer was stopped before reporting: review `leaders.gd` and its 31 tests.
3. **Re-run the three cancelled slices.** Bar stopped them; nothing from them was kept.
   - **Audio:** the cue coverage audit and a mix pass on every new view, plus the `leaderPick` sting (the new first sound) and the crit-cue mapping by react event (spec §9.5).
   - **Animator:** Bibi's court-day exit/return and the `court_window` echo; the motion audit of the new views; the leader walk-out in the election transition and walk-in on the pick; the brawl cloud boil.
   - **Designer:**
     - Why a scripted browser round took 34 min to the first election while the bench says about 8.
     - R17: re-place `producers[].slot` so money sources clear the thermometer and the Magician's hit box.
     - Also: a one-line `rule` for ביבי; a poll-number lint on "רוב"; a leader-neutral count for the result card's `DAYS_*`.
4. **UX review** of the picker build, then a strict build and redeploy (see Deploy).

## Before a real launch (Bar's calls, not code)
- **Publisher and contact.** The disclaimer shows "מאת base67" with no mail. Set `OD_PUBLISHER` / `OD_CONTACT_MAIL` for the build.
- **Domain.** Today it is `od-sevev.vercel.app`, and `OD_SITE_URL` and `ShareKit.SITE_URL` must follow a change.
- **Sources.** All launch facts plus the 21 new leader facts were verified from search results only, because the sandbox blocked opening pages. Open each link once.
- **Legal reads:**
  - Deri's kit (the 2022 tax plea and "חוק דרעי");
  - בן גביר as a playable protagonist;
  - the brawl and Illouz lines stay reported speech;
  - **מרדכי דוד** (session 5, Bar reversed the drop): his stage event "החסימה" and its three facts (refs 73-75: the cars he blocked, his Kaplan rationale as reported speech, his paid youth-HQ role). A private but newsworthy activist; the satire rests on documented public conduct only. Read `design/mordechai-david-spec.md` §8 and §12 before the flag goes on.
- **Device checks:** on a real iPhone, check the share sheet (only the download/clipboard fallback was browser-tested) and listen to the HaTikva-based audio.
- **Art wanted from ChatGPT:** see `creative-pack/art/CHATGPT-REQUESTS.md` (12 images, with prompts). Tell the TA if you want Bibi's hat and rabbit at 3× (it needs a cast re-render).
- **Old flags:** Mordechai David is decided (Bar, 2026-09-30: on for launch; it flips in the change-set that wires his event, `design/mordechai-david-spec.md` §7.5). The Yair flag stays off by default.
- **Pro Max pixel scale:** the orchestrator chose to drop k 7 to 6 (crisp, about 14% smaller), part of Bar's "sharp on every phone" request. Revert the crisp-k rule in `display.gd` if you'd rather have the bigger, softer picture.
- **App icon + logo (session 7):** the icon is now the hat with the gold loop (`art/od-sevev/src/logo.py`); the ring of eight heads is retired but still in `keyart.icon()`. The logo lockups are in `art/od-sevev/out/key/logo-*.png`. The in-game title still uses the plain v2 wordmark: swap in `wordmark-loop` if you want the loop ס in the game too.
