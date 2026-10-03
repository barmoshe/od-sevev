# 0007. The wizard overlay, and a roster that grows by round

- Date: 2026-10-03
- Status: Accepted (Bar: "אני לא רוצה שזה יתחיל מביבי ספציפית"; "שתי דקות הראשונות של המשחק יהיו
  ברורות עם wizard overlay tutorial וכל מכניקה חדשה שמצטרפת יהיה Wizard חדש"; on the questions: "בהתחלה
  שיהיה אופציה לבחור בין ביבי לבנט וכל סבב תוסיף עוד אופציות", the "Guided, do-it" style, merge and
  deploy). Supersedes ADR 0006's "the picker no longer opens on a first launch".

## Context

After the reveal ladder (ADR 0006) the first round was calm, but a new player still met it without a
guide: the FTUE (ux/ftue.md) teaches the first minute with a pulse, a hand after 9 s of idling and a
few of Dubi's bubbles, and nothing after that. Each later round opened a system with a one-line toast.
The first round was always Bibi's, which Bar did not want.

What we read (2026-10-03): teach by doing, not reading, with one sentence per step and the step ending
on the player's action; coach marks dim the screen and spotlight one element, always show a skip and a
progress count, and trigger when the user reaches the thing; later mechanics are taught just in time,
when they first matter (Andersen et al., CHI 2012: tutorials pay off in complex games, and
context-sensitive help beats front-loaded instruction); idle games start with the core loop and get out
of the way.

## Decision

- **The wizard overlay** (`ui/wizard.gd`, content `wizard`, the vocabulary in `ui/wizard_hooks.gd`):
  the screen dims, a hole sits on the one thing to touch (gold frame, the FTUE hand), Dubi's bubble
  says what and why, "דלג" and a step count sit top-left. A press in the hole passes through; anything
  else is swallowed. **Steps are triggered by state, not a forced chain**: a step shows only while its
  `when` holds and its `done` does not, so between steps the game plays undimmed. A step can be
  `soft` (a hint, nothing swallowed), `gone` (the moment passing counts), `sec` (expires) or `hold`
  (holds the round's clock).
- **The first round** (`first`): pick (Bibi or Bennett) → tap the leader ×3 → buy the first source →
  catch the first Suitcase → open the coalition → pay the first demand → the 61 bar → call the
  election. The old FTUE prompts (P0, P1, E1, the K3 toast) stand down while it runs; if the player
  skips it, they come back as the fallback.
- **One wizard per mechanic**: every reveal-ladder rung has a flow keyed to it (`on`), which waits for
  the moment the mechanic first shows up (the first ultimatum's cameo, Mordechai on his mark, the
  thermometer). Its bubble is the rung's `reveal.copy` line, so the round-start toast for that key goes.
  A new leader in the picker gets a soft hint the first time.
- **The roster ladder** (`leaderSelect.unlockRound`): the picker opens on the first launch again
  (`reveal.picker` 0) with Bibi and Bennett open; one more leader opens each round (Ben Gvir in round
  2 … Golan in round 7). Locked tiles stay in the grid, greyed with their round; the open ones sit
  first; הפתעה and the bench's mixed player pick only open leaders. Forced rounds (a challenge, the
  daily, the bench's per-leader runs) play any leader.
- **Measured**: each step done, a skip and a flow done go to the funnel as `wizard/<flow>/<step>`.
- **Wiped**: `saveEpoch` 2, so every player meets the wizard.

## Consequences

- Unit tests run with the wizard off (`run_tests.gd`); `test_wizard.gd` turns it on. The dev build
  (`?dev=1`) has it off unless `wiz=1`, so the browser drivers play as before; `tools/web/wizard_web.mjs`
  plays the first round through it.
- A new mechanic now needs a reveal rung, a `reveal.copy` line **and** a wizard flow (the complexity
  budget of ADR 0006 still holds).
- Leader balance in round 1 now matters for two leaders, not one; the bench's L1 still runs every
  leader's first round.
