# "עוד סבב" (Another Round): creative pack

**Kind:** `artifacts/creative-pack` (ad-hoc kind: the pre-build pitch pack a client brief asks
for before any build). **Slug:** `od-sevev`. Renamed from "הקוסם" by Bar on 2026-09-28; the
player character is still "הקוסם".

## Goal
The pre-build pack from `brief.md` §"What we'd like to see from you", items 1-3 and 5:
1. Creative pitch, changes, three alternative titles (title now fixed as "עוד סבב"; alternates
   kept as a record).
2. The look: character line-up, the four locations, title screen, app icon.
3. The voice: ~20 Hebrew jokes and headlines, Dubi's first story flash, source/spin/partner
   lines. **Top priority: native, genuinely funny Hebrew copy.**
5. Reference list of every real quote and affair used.

Inputs: `brief.md` (round 1 + fact sheet), `brief-round2.md` (expanded cast, easter eggs,
systems).

## Dispatch tree
- **game-designer**: `pitch.md` (concept, loop, systems, changes) + `voice/copy-deck.md` (all
  game-content Hebrew: headlines, Dubi, sources, spins, partners, events) + `references.md`.
- **2d-artist**: `art/style-guide.md` + pixel sketches (`art/*.png`): line-up, four locations,
  title screen, icon.
- **ux-designer**: `ux/first-minute.md`: title screen and first-10-seconds flow, disclaimer,
  coalition-chat and receipt share-card layout, RTL rules, UI microcopy in Hebrew.
- **Reconcile wave**: cross-review of Hebrew copy (natural? funny? on the red lines?) via
  objections; owners revise.

## Status (loop stopped by Bar, 2026-09-28)
- **Converged, with no objection outstanding:**
  - pitch + copy deck: 21 UX objections resolved, 9 designer objections on UX microcopy resolved;
  - the UX first-minute spec;
  - the sonic brief v1.1;
  - the engine feasibility review: 5 objections, all resolved.
- **Open:**
  - **Art:** the 2D Artist was stopped mid Bibi-v3. Next step: redraw the cast by copying the ChatGPT refs in `art/refs/` closely (Bar's direction).
  - **Missing font glyphs:** K M B T, + −, …, ־ ״ ׳, ← ×.
- **Before ship:**
  - verify the exact Hebrew wording of the Gotliv, Amsalem/Netanyahu and Illouz quotes;
  - add URLs for the round-2 sources.
