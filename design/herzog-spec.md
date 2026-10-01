# Herzog: "מתווה הנשיא" (the president's outline)

Bar, 2026-10-01: two new Herzog refs (rest and shrug). Bring him in, animated, with a game role.

## Art
- `creative-pack/art/refs/herzog.png` is the rest pose (hands clasped). `herzog-shrug.png` is the
  shrug (palms out, a sweat drop). The ChatGPT originals are in `refs/candidates/`, and the old
  v1 stamp ref is kept there as `herzog-v1-stamp.png`.
- The rig is `cast.py` `herzog`, with `react='shrug'`:
  - `build.py` pastes the second ref in the rest pose's ref coordinates. Both crops run y 39/40 to
    1494, so one scale fits both.
  - The react is: dip, pop into the shrug, hold about 0.5 s, settle back. 12 frames at 12 fps, event `shrug` on frame 2.
  - `pad=(0.53, 0.10)` gives the shrug's arms room: frameW 190 at d3.
- Idle is generic: breathing plus a blink. The avatars come from the rest pose, so the pardon desk's
  avatar24 is the new face.

## The event (content `events.herzog`)
- **Data:** `kind` stage, `effect` `mediation` (`sec` 15, `pct` 30), `weight` 2, `cooldownSec` 600,
  `when` `membersAtLeast: 2`.
- **Rounds:** a shared event, so it plays in every leader's round, coalition and opposition.
- **Fires:** `HerzogFigure` (`game/scripts/ui/herzog_figure.gd`) walks in from the right to the
  front-right mark, which is Sara's (she steps off while he stands). A chat-style toast carries his
  face, name and `copy.text`, and `copy.ticker` crawls.
- **A tap on him:** `main._accept_mediation` calls `Events.act("mediation", "accept")`, then
  `Coalition.discount_open`.
  - Every open demand and ultimatum drops by `pct`, rounded to a whole shekel, never below 1.
  - The chat signature includes the price, so the pills re-render.
  - The toast is `acceptText`, or `acceptNone` when nothing was open. He walks out.
- **Ignored:** the effect lapses (`eventEnd` `mediation`, toast `rejectText`). He shrugs (the react)
  and leaves.
- **No penalty:** the cost of ignoring him is the missed discount.
- **Reduced motion:** no walk. He appears and leaves in place.

## Truth
- Fact `herzog-framework`: on 15 Mar 2023 he presented the People's Framework. The coalition
  rejected it the same day as "one-sided"; most opposition leaders backed it.
- The game keeps the shape (a compromise offer, often rejected) and never the reform's contents.
- Ambient lines:
  - `h01`, unity: plain satire.
  - `h02`, the pardon at mediation: fact `pardon-shelved`.

## Tests
`game/tests/unit/test_event_copy.gd`:
- the discount on accept, and that it can't be accepted twice;
- the lapse;
- the scene: he walks in, Sara steps off, a tap accepts, the pill drops 30%, he walks out;
- the shrug when ignored.
