# HANDOFF-LIVE: the studio loop's live state (auto, every minute)

Read `HANDOFF.md` first; this file is the minute-by-minute addendum while the loop runs.
If the session died, restore unmerged agent work from `handoff-wip/` (see below).

- Branch head: `ba0b21e` docs(od-sevev): live handoff snapshot 23:26
- Loop lock: ACTIVE (loop running)

## Orchestrator notes
- Session 3 goal: HANDOFF.md "Next" 1-4. Wave A (4 agents, parallel) dispatched from 76c8926.
- Audio merged (d13256e). Live site redeployed from d13256e (web-dist 96064c8): fixes the relative og:image and the dirty 5df9291+ build that was live.
- After wave A: merge dev (picker) + designer + animator; then wave B = Animator walk-out/walk-in on the pick, UX review of the picker; strict build; redeploy.
- Studio check: validate/dog-audit/cross-ref all clean. The gamestudio Stop hook is NOT loaded in this session (settings live in gamestudio/.claude); the loop is kept by the orchestrator. Recommended: document the od-sevev external-repo exception to I13 (awaiting Bar).
- Bar asked (session 3): update the handoff every minute (this file). Pushing agents' wip branches to GitHub still needs Bar's OK; until then text patches of agent work are saved in handoff-wip/.
- Animator wave A merged (323/323). Its asks for the 2D Artist (in STATUS.md): court_window spots to art row >=110; a 26x20 brawl-cloud cut at x4. Wave B Animator: wire LeaderWalk into the pick + election transition.
- Bar (session 3): "the mobile layout is not good; it must be mobile first". Observed: dead bands on tall phones (fixed 180x267 column), list cut on SE, ticker text truncated, small money/buy. UX Designer dispatched for ux/mobile-first-layout.md; the Game Developer implements it right after the picker merges (same files). Shots: scratchpad/shots/mobile/.
- Picker merged (337/337). Open from its report: Liberman's blurb shows "61" on the picker (spec §3.2: no numbers), for the Designer. LeaderWalk is unwired because the court pose sets the position every frame, so it needs Animator wave B. Golan's pill sits on the partner card; UX to confirm. §10.2 neutralCopy/notUsed facts are the Designer's.
- Next: when UX delivers ux/mobile-first-layout.md, dispatch the Game Developer to implement it; Animator wave B (LeaderWalk into pick/election); Designer pending.
- UX spec ux/mobile-first-layout.md committed on worktree-agent-afa76d8266b2e2b6f (UX still running its matrix check). Game Developer dispatched to implement it from that branch (port 8816).
- UX spec merged. 2D Artist+TA dispatched for the spec's art asks. Designer got G1 (fillSilhouettes) + the Liberman '61' blurb. Later: Animator wave B = M1 ticker page transition + LeaderWalk wiring (after the mobile implementation merges).
- Designer merged. Balance: every leader's median first election is 7:51-8:50; watch Eisenkot casual 9:00 and the worst seats for Bennett/Ben Gvir >10:00. The 34-vs-8 gap = the browser script is a slow player (tooling fixed). Designer objection vs R17 resolved: accept back-row sources behind the leader; the crowd x-clamp + right-wing slots go to the mobile Game Developer.
- 22:20 Bar: stop for today, continue tomorrow. Both running agents stopped; their work is committed on their branches and carried in handoff-wip/*.commits.patch. HANDOFF.md has the session-3 stop section and session 4's order. Lock released.
- 22:21 Bar: continue the loop. Lock re-taken; both stopped agents resumed with their context (artist: finish + verify; dev: finish the mobile matrix, then merge the artist's branch).
- Art merged. The snapshot script now has a pause switch (/tmp/claude-0/-home-user/8fc63aec-cb0c-55e7-b2d4-be5e5ff14015/scratchpad/live/pause): touch it before merging into the main worktree, remove after (a snapshot git add raced a merge once).
- 22:40 Bar: the design must be more in Israel's palette, blue and white. The orchestrator's scope: chrome and the HTML shell go blue/white on navy; gold stays for money/buy; red for alerts only; stages keep their identity (Balfour's sky goes navy); cast untouched; flag colours as the frame, no party-logo look. The code colour map is applied after the mobile merge.

## Agents
| Role | Slice | Worktree branch | Commits not on claude/magical-ride-ntn3u5 | Uncommitted files | Saved patch |
|---|---|---|---|---|---|
| Game Developer | DONE, merged (leader picker + per-leader views, 337 tests) | `worktree-agent-a5ac76f3d34023987` | 0 | 0 | - |
| Game Designer | DONE, merged (sim fixes, all 8 leaders 7-9 min median, R17 slots, lints, web-driver bench; 340 tests) | `worktree-agent-aaa48164b1454821d` | 0 | 0 | - |
| Animator | DONE, merged (court day, motion audit, brawl boil, reduced-motion fix; LeaderWalk helper ready, unwired) | `worktree-agent-a4cee2a31acb16b09` | 0 | 0 | - |
| Audio Director | DONE, merged in d13256e (audio v1.3: leaderPick, crit_for, coverage) | `worktree-agent-a1284a1d8c4b3dc94` | 0 | 0 | - |
| UX Designer | DONE, merged (ux/mobile-first-layout.md, tools/web/mobile_web.mjs: baseline PASS, 108 layout checks open until the implementation lands) | `worktree-agent-afa76d8266b2e2b6f` | 0 | 0 | - |
| Game Developer (mobile) | RESUMED, finishing: core grid/split/fluid chrome, tall tabs, modals, sheets, merge-ready line and layout tests are committed; the full mobile_web matrix run, picker layout check and before/after sheet were not done | `worktree-agent-a8bd968153c51c052` | 12 | 1 | `Game-Developer-(mobile).commits.patch` `Game-Developer-(mobile).patch` |
| 2D Artist + TA | DONE, merged (lane, plaza, wings, XL pick heads avatar_pick_<c>_d3/_d2, brawl_cloud_cue x4, court spots as kit data) | `worktree-agent-ab7cb5f96a4c16bc8` | 0 | 0 | - |
| 2D Artist + TA (palette) | Bar: "more Israel palette, blue and white": palette v3 (flag blue #0038b8, white, navy replacing plum; gold kept for money/buy), UI kit + shell + icons + OG re-render, palette-v3-map.json for code (applied after the mobile merge) | `worktree-agent-a5e8cafeb35582361` | 2 | 131 | `2D-Artist-+-TA-(palette).commits.patch` `2D-Artist-+-TA-(palette).patch` |

Restore: `git checkout -b restore-<role> claude/magical-ride-ntn3u5 && git am --3way handoff-wip/<Role>.commits.patch; git apply --3way handoff-wip/<Role>.patch`.
`*.commits.patch` carries committed work in full, binaries included. `*.patch` (uncommitted work) is text-only: binary files are listed in its header.
