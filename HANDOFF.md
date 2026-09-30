# HANDOFF: "עוד סבב" (2026-09-30, end of session 4)

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
  - the brawl and Illouz lines stay reported speech.
- **Device checks:** on a real iPhone, check the share sheet (only the download/clipboard fallback was browser-tested) and listen to the HaTikva-based audio.
- **Art wanted from ChatGPT:** see `creative-pack/art/CHATGPT-REQUESTS.md` (12 images, with prompts). Tell the TA if you want Bibi's hat and rabbit at 3× (it needs a cast re-render).
- **Old flags:** decide the Mordechai David and Yair flags (off by default).
- **Pro Max pixel scale:** the orchestrator chose to drop k 7 to 6 (crisp, about 14% smaller), part of Bar's "sharp on every phone" request. Revert the crisp-k rule in `display.gd` if you'd rather have the bigger, softer picture.
- **App icon:** it is now the ring of eight heads. Revert `art/od-sevev/out/key/icon-128-art.png` and re-run the pipeline if you prefer the old one.
