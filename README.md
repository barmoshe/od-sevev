# עוד סבב: studio build

A satirical Hebrew idle game about the 27.10.2026 Knesset election. The player is Netanyahu, "הקוסם",
pulling shekels out of a hat, paying coalition partners, dodging court days, and calling elections
forever. Everything here is **Hebrew, RTL, portrait, mobile-first web**.

**Engine:** a fork of Monkey Bananas v2.1.0 (Godot 4.7.2, web export). The original README is
`README.monkey-bananas.md`, and the engine notes are in `HOW-TO-RUN.md` and `decisions/`.

**Location:** Bar's plan said `~/hakosem`. The studio's output rule (I13) puts it here instead.
Deploy is out of studio scope (I5): the gated Vercel deploy stays Bar's call.

## This repo
This is the standalone repo for the game (Bar's sibling-repo convention, like `spellwright`).
- **Where it was built:** by the base67 studio in `phaserbuilder/gamestudio/output/games/od-sevev/`.
- **`creative-pack/`:** a copy of the studio's approved creative pack: the pitch, copy deck, UX spec,
  sonic brief, the ChatGPT refs and the cast render-down pipeline. `pipeline/od-sevev/` finds it
  automatically; set `ODS_CREATIVE_PACK` to override.
- **Not committed:** `build/` and the Godot `.godot/` cache, both regenerated. Also the fork's old
  Monkey Bananas audio.
- **Start with `HANDOFF.md`.** It's the current state, what's in flight, and the next steps.

## Inputs: approved, do not re-litigate
All of these live in `gamestudio/output/artifacts/creative-pack/od-sevev/`:
- **The brief:** `brief.md` + `brief-round2.md`, including the fact sheet and the red lines.
- **The design:** `pitch.md`, the design and launch spine, including §11 with the tuning numbers
  answered for UX.
- **Copy:** `voice/copy-deck.md`, all game-content Hebrew, reviewed; `references.md` has the
  sources.
- **UX:** `ux/first-minute.md`, covering the screen graph, FTUE, HUD, coalition chat, share cards,
  disclaimer, settings and the microcopy table.
- **Audio:** `audio/sonic-brief.md` v1.1.
- **Engine:** `engine/feasibility.md`, the Godot-reality verdicts and resolutions.
- **Cast art:** `art/showcase/out/`.
  - The **approved cast sprites** (96 px tall PNG strips plus `atlas.json`), the avatars, the
    props (hat, rabbit, coins, bill, spark) and the four stage backgrounds (180x320).
  - Bar approved these; the look is locked.
- **Earlier art:** `art/` holds the style guide, the Hebrew pixel font draft (`art/src/hebfont.py`)
  and the four locations source (`art/src/locations.py`).

## Asset requests
See `asset-requests/REQUESTS.md`. Agents file ChatGPT art needs there; the orchestrator fulfils
them.

## Dispatch tree (wave 1)
Each agent owns a slice of files, and nobody edits another's slice. Changes to someone else's
slice go through an objection or a note in `STATUS.md`.

| Agent | Owns |
|---|---|
| game-developer | `game/scripts/**`, `game/scenes/**`, `game/project.godot`, `game/export_presets.cfg`, `game/web/**`, `tools/**`, `game/tests/**` |
| game-designer | `design/**` |
| ux-designer | `ux/**` |
| technical-artist | `game/assets/**`, `pipeline/**`, `art/tools/**`, `game/data/art.json` |
| 2d-artist | `art/od-sevev/**` (new non-character art source) |
| audio-director | `audio/**` (data only; generator code changes go through the developer) |
| animator | `motion/**` |
