# HANDOFF-LIVE: the studio loop's live state (auto, every minute)

Read `HANDOFF.md` first; this file is the minute-by-minute addendum while the loop runs.
If the session died, restore unmerged agent work from `handoff-wip/` (see below).

- Branch head: `a55673f` chore(od-sevev): merge the animator slice (court day, motion audit, brawl boil, reduced-motion fix)
- Loop lock: ACTIVE (loop running)

## Orchestrator notes
- Session 3 goal: HANDOFF.md "Next" 1-4. Wave A (4 agents, parallel) dispatched from 76c8926.
- Audio merged (d13256e). Live site redeployed from d13256e (web-dist 96064c8): fixes the relative og:image and the dirty 5df9291+ build that was live.
- After wave A: merge dev (picker) + designer + animator; then wave B = Animator walk-out/walk-in on the pick, UX review of the picker; strict build; redeploy.
- Studio check: validate/dog-audit/cross-ref all clean. The gamestudio Stop hook is NOT loaded in this session (settings live in gamestudio/.claude); the loop is kept by the orchestrator. Recommended: document the od-sevev external-repo exception to I13 (awaiting Bar).
- Bar asked (session 3): update the handoff every minute (this file). Pushing agents' wip branches to GitHub still needs Bar's OK; until then text patches of agent work are saved in handoff-wip/.

## Agents
| Role | Slice | Worktree branch | Commits not on claude/magical-ride-ntn3u5 | Uncommitted files | Saved patch |
|---|---|---|---|---|---|
| Game Developer | build the leader picker (LEADER_PICK) + spec §10 views/engine; wire audio hooks | `worktree-agent-a5ac76f3d34023987` | 4 | 0 | `Game-Developer.commits.patch`  |
| Game Designer | review leaders.gd; balance.sh + per-leader bench; 34-vs-8 min gap; R17 slots; ביבי rule; "רוב" poll lint; neutral DAYS_* | `worktree-agent-aaa48164b1454821d` | 0 | 22 | `Game-Designer.patch` |
| Animator | Bibi court-day exit/return + court_window echo; motion audit of session-2 views; brawl cloud boil | `worktree-agent-a4cee2a31acb16b09` | 0 | 0 | - |
| Audio Director | DONE, merged in d13256e (audio v1.3: leaderPick, crit_for, coverage) | `worktree-agent-a1284a1d8c4b3dc94` | 0 | 0 | - |

Restore: `git checkout -b restore-<role> claude/magical-ride-ntn3u5 && git am --3way handoff-wip/<Role>.commits.patch; git apply --3way handoff-wip/<Role>.patch`.
`*.commits.patch` carries committed work in full, binaries included. `*.patch` (uncommitted work) is text-only: binary files are listed in its header.
