# 0008. The leader picker is the ballot booth

- Date: 2026-10-03
- Status: Accepted (Bar: "תעצב מחדש לגמרי את מסך הבחירה טוב יותר... תהיה יצירתי"; on the questions: the
  ballot booth concept, select then confirm; earlier: the leaders not open yet "ממש מטושטש, לא סתם
  מעומעם", "לא צריך שיהיו חשוכים רק מטושטשים"). Supersedes the 3 × 3 grid of ux/rtl-map.md §8 and
  ux/mobile-first-layout.md §5.8.

## Context

With the roster ladder (ADR 0007) most of the 3 × 3 grid was locked tiles on the first launch, the
rule of the focused leader hid in a caption strip or behind a long-press, and one tap committed. What
we read: a character select is quick and intuitive when every option is the same size with a clear
state, and a large featured card shows the one in focus; and the Israeli voting booth itself: a tray
of party slips, a pile of blank slips, an envelope and the ballot box.

## Decision

- **The booth** (`ui/views/view_pick.gd`): the header on a navy plate (the title, a one- or two-line
  hint, the fresh-face chip after an election); a big card with the chosen slip (the face, the name and
  party, `rule.summary`, the ability); the booth frame with a tray of paper slips, five a row (the open
  leaders first, the two blocs taking turns; Gantz while he still fools; the blank slip for הפתעה);
  the vote button "לשים בקלפי: {short}".
- **Select, then vote.** A tap chooses a slip; the button, or a second tap on the chosen slip, votes;
  the slip flies into the box. Nothing is chosen for a new player (Dubi says what to do in the card);
  after an election the last leader is chosen ("עוד סבב עם …", Esc = again).
- **Slips in print** (not open yet): a really blurred face (the image shrunk and grown back by the GPU)
  and a smeared name, never darkened, with the round they open in; chosen, the card shows them blurred
  and the button stays off ("הפתק הזה בדפוס").
- The wizard's first step becomes two do-it steps: choose a slip, then vote.

## Consequences

- `PickView.plan(H, cw, variant, n)` replaces `grid_plan`; tests pin that the booth fits every device
  of the matrix and stacks inside the band. The browser drivers choose then vote (two taps).
- The leader card (long-press, `I`) stays; the caption strip is now the header's hint line.
