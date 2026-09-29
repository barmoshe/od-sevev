# HANDOFF-LIVE: the studio loop's live state (auto, every minute)

Read `HANDOFF.md` first; this file is the minute-by-minute addendum while the loop runs.
If the session died, restore unmerged agent work from `handoff-wip/` (see below).

- Branch head: `e6d17d9` docs(od-sevev): live handoff snapshot 22:01
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

## Agents
| Role | Slice | Worktree branch | Commits not on claude/magical-ride-ntn3u5 | Uncommitted files | Saved patch |
|---|---|---|---|---|---|
| Game Developer | DONE, merged (leader picker + per-leader views, 337 tests) | `worktree-agent-a5ac76f3d34023987` | 0 | 0 | - |
| Game Designer | DONE, merged (sim fixes, all 8 leaders 7-9 min median, R17 slots, lints, web-driver bench; 340 tests) | `worktree-agent-aaa48164b1454821d` | 0 | 0 | - |
| Animator | DONE, merged (court day, motion audit, brawl boil, reduced-motion fix; LeaderWalk helper ready, unwired) | `worktree-agent-a4cee2a31acb16b09` | 0 | 0 | - |
| Audio Director | DONE, merged in d13256e (audio v1.3: leaderPick, crit_for, coverage) | `worktree-agent-a1284a1d8c4b3dc94` | 0 | 0 | - |
| UX Designer | DONE, merged (ux/mobile-first-layout.md, tools/web/mobile_web.mjs: baseline PASS, 108 layout checks open until the implementation lands) | `worktree-agent-afa76d8266b2e2b6f` | 0 | 0 | - |
| Game Developer (mobile) | implement ux/mobile-first-layout.md §8 + screens §3-§7 (from the UX branch worktree-agent-afa76d8266b2e2b6f) | `worktree-agent-a8bd968153c51c052` | 6 | 0 | `Game-Developer-(mobile).commits.patch`  |
| 2D Artist + TA | mobile art asks A1 lane tile + plaza, A2 stage wings, A3 96x96 d3 pick avatars; court_window spots row>=110; 26x20 brawl cut x4 | `worktree-agent-ab7cb5f96a4c16bc8` | 0 | 111 | `2D-Artist-+-TA.patch` |

Restore: `git checkout -b restore-<role> claude/magical-ride-ntn3u5 && git am --3way handoff-wip/<Role>.commits.patch; git apply --3way handoff-wip/<Role>.patch`.
`*.commits.patch` carries committed work in full, binaries included. `*.patch` (uncommitted work) is text-only: binary files are listed in its header.
