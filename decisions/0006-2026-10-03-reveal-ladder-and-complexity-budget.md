# 0006. The reveal ladder, and a complexity budget

- Date: 2026-10-03
- Status: Accepted (Bar: "המשחק הזה טוב. באמת. אבל הוא מאוד מורכב והוא מאוד overwhelming"; then, on
  the plan: one new system per round, Sara stays but gentler, implement all of it, merge and deploy)

## Context

The whole-game report (`design/overwhelm-report-2026-10-03.html`) found about 38 systems, about 33 of
them live by the end of round 1, and every unlock keyed to lifetime state, so round 2 opened fully
loaded. Eight leaders were eight rule books with the rules behind a long-press; "בסיס" meant three
things; about 20 kinds of timer ran and only the election card stopped the clock (a five-round browser
playthrough lost 8-20 seats to unseen ultimatums while reading menus); the FTUE covered minute one
and no help existed; events went out on two or three channels at once. The 7-9 minute pacing gate had
only ever been met by a bench bot that answers every demand on the frame it lands.

## Decision

- **The reveal ladder** (content `reveal`, `sim/reveal.gd`): systems open by election count. Round 1
  is the tap, the sources, the chat's demands, 61 and the Suitcase, as the default leader (no picker).
  Round 2 adds spins and the picker; round 3 suspicion, the court and the dossier; round 4
  ultimatums, events and leader abilities; round 5 missions, perks, Mordechai David, the share chip
  and card milestones. Each opening is announced once at the round's start (`reveal.copy`), with the
  leader's one-line rule (`rule.summary`) the first round they lead. Every gate asks `Reveal.on`.
- **The clock holds under menus** (`main.clock_held`): any overlay that is a menu, the dossier and the
  share drawer. Play keeps running: the chat, the shop tabs, the summons card, play overlays.
- **One channel per message**, a 25 s ambient ticker, pages of whole sentences.
- **Softer politics** where it now arrives (round 4): ultimatum 150 s, patience 90 s, demands every
  90-150 s, the big partner's threat 0.25. Sara leaves after 9 s and comes once a round.
- **Explain**: an "איך זה עובד" sheet (settings, dossier), the rule on the picker strip, one income
  number ("כל ההכנסה ×N"), a recap line on the return card; copy that says what buttons do
  ("לשלם", "לדחות", "גביע חדש"), and "בסיס" means only the permanent count ("בונוס בחירות" for a
  round's payout bonus).
- **Measure people, not bots**: the bench has a "slow" player (chat every 45 s) whose first election
  must land within 12 minutes; `design/playtest-kit.md` is the script for 3-5 real players.
- **Complexity budget**: until after election day (27.10) a new system goes in only if another goes
  out, and it gets a rung on the ladder and a line in `reveal.copy`.

## Consequences

- Unit tests pin each system with the ladder off (`run_tests.gd` sets `Reveal.force_all` for the unit
  folder); `test_reveal.gd` covers the ladder. The bench plays the game as shipped, ladder on, so its
  first-round numbers moved (STATUS 2026-10-03 has the new medians).
- A returning player whose save is past round 5 sees no difference in what is open; earlier saves see
  systems disappear until their round. Lifetime counters are unchanged.
- The picker no longer opens on a first launch: the first round is Bibi's (`leaderSelect.defaultLeader`).
