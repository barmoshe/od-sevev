# HANDOFF-LIVE: the studio loop's live state (auto, every minute)

Read `HANDOFF.md` first; this file is the minute-by-minute addendum while the loop runs.
If the session died, restore unmerged agent work from `handoff-wip/` (see below).

- Branch head: `7a82e8a` docs(od-sevev): live handoff snapshot 20:40
- Loop lock: ACTIVE (loop running)

## Orchestrator notes
- Session 3 goal: HANDOFF.md "Next" 1-4. Wave A (4 agents, parallel) dispatched from 76c8926.
- Audio merged (d13256e). Live site redeployed from d13256e (web-dist 96064c8): fixes the relative og:image and the dirty 5df9291+ build that was live.
- After wave A: merge dev (picker) + designer + animator; then wave B = Animator walk-out/walk-in on the pick, UX review of the picker; strict build; redeploy.
- Studio check: validate/dog-audit/cross-ref all clean. The gamestudio Stop hook is NOT loaded in this session (settings live in gamestudio/.claude); the loop is kept by the orchestrator. Recommended: document the od-sevev external-repo exception to I13 (awaiting Bar).
- Bar asked (session 3): update the handoff every minute (this file). Pushing agents' wip branches to GitHub still needs Bar's OK; until then text patches of agent work are saved in handoff-wip/.
- Animator wave A merged (323/323). Its asks for the 2D Artist (in STATUS.md): court_window spots to art row >=110; a 26x20 brawl-cloud cut at x4. Wave B Animator: wire LeaderWalk into the pick + election transition.
- Bar (session 3): "the mobile layout is not good; it must be mobile first". Observed: dead bands on tall phones (fixed 180x267 column), list cut on SE, ticker text truncated, small money/buy. UX Designer dispatched for ux/mobile-first-layout.md; the Game Developer implements it right after the picker merges (same files). Shots: scratchpad/shots/mobile/.

## Agents
| Role | Slice | Worktree branch | Commits not on claude/magical-ride-ntn3u5 | Uncommitted files | Saved patch |
|---|---|---|---|---|---|
| Game Developer | build the leader picker (LEADER_PICK) + spec §10 views/engine; wire audio hooks | `worktree-agent-a5ac76f3d34023987` | 6 | 1 | `Game-Developer.commits.patch` `Game-Developer.patch` |
| Game Designer | review leaders.gd; balance.sh + per-leader bench; 34-vs-8 min gap; R17 slots; ביבי rule; "רוב" poll lint; neutral DAYS_* | `worktree-agent-aaa48164b1454821d` | 3 | 4 | `Game-Designer.commits.patch` `Game-Designer.patch` |
| Animator | DONE, merged (court day, motion audit, brawl boil, reduced-motion fix; LeaderWalk helper ready, unwired) | `worktree-agent-a4cee2a31acb16b09` | 0 | 0 | - |
| Audio Director | DONE, merged in d13256e (audio v1.3: leaderPick, crit_for, coverage) | `worktree-agent-a1284a1d8c4b3dc94` | 0 | 0 | - |
| UX Designer | mobile-first layout spec (ux/mobile-first-layout.md) + tools/web/mobile_web.mjs; Bar: "the mobile layout is not good, must be mobile first" | `worktree-agent-afa76d8266b2e2b6f` | 0 | 0 | - |

Restore: `git checkout -b restore-<role> claude/magical-ride-ntn3u5 && git am --3way handoff-wip/<Role>.commits.patch; git apply --3way handoff-wip/<Role>.patch`.
`*.commits.patch` carries committed work in full, binaries included. `*.patch` (uncommitted work) is text-only: binary files are listed in its header.
