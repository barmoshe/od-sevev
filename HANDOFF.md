# HANDOFF: "עוד סבב" (2026-09-29)

Bar stopped the studio loop mid-wave. Every agent has been stopped. This is the state of the work and
how to pick it up.

## What it is
"עוד סבב" is a satirical Hebrew idle game about the 27.10.2026 Knesset election; it was renamed from
"הקוסם". The player is Netanyahu, "הקוסם". It's a fork of Monkey Bananas v2.1.0 (Godot 4.7.2, web
export, 720x1280 portrait).

| Where | What |
|---|---|
| `gamestudio/output/games/od-sevev/` | the game (this folder); `STATUS.md` is the full agent log plus open requests |
| `gamestudio/output/artifacts/creative-pack/od-sevev/` | approved inputs: pitch, copy deck, UX spec, sonic brief, engine review, the cast render pipeline (`art/showcase/src/`) and the ChatGPT refs (`art/refs/`, 28 files) |
| `asset-requests/REQUESTS.md` | the ChatGPT art queue and log |
| Cast sheet artifact | https://claude.ai/artifact/CoD5GQZYSiAkZomWa4RU6N (the 3-character approval page; v2 shows 9 characters) |

Nothing is committed yet. Both trees are untracked in the phaserbuilder repo. Nothing is deployed.

## Run it
```
cd gamestudio/output/games/od-sevev
tools/test.sh                  # 135/136 right now (see Broken)
tools/build_web.sh             # strict text lint; OD_LINT=warn for interim builds
python3 -m http.server 8747 --directory build/web   # or the "od-sevev-web" preview config
python3 pipeline/od-sevev/build.py --no-render      # re-import sprites/kit/font into the game
```

## Done and verified (as of the last green run, 136/136 plus a strict web build)
- **Engine:**
  - rebrand (`HK1:` saves, bundle `xyz.base67.odsevev`, Hebrew web shell with OG tags);
  - content-driven ids;
  - all Hebrew goes through TextServer with the Sevev 9 bitmap font;
  - RTL layout per `ux/rtl-map.md`: rows A/B, seats bar, ticker, tab bar at the bottom;
  - the **N1 legal disclaimer** in HTML while the engine loads;
  - the FTUE per `ux/ftue.md`, the shop (whole card is the buy target), the settings sheet, the title;
  - Magician SpriteStrip (hat, coins, rabbit), the Suitcase, small Dubi at the ticker, 8 money sources.
- **Sim:** coalition (partners, demands, ultimatums, transfer window, the chat-log model), investigation
  and court day, events, calendar and blackout. The data contract is in `game/scripts/sim/README.md`.
- **Content:** `design/content.json` has 620 Hebrew strings, 165 ticker lines, 15 partners, 15 spins,
  40 trophies and 12 perks. The first election comes at about 7 min.
  - Supporting files: `design/facts.json` (51 facts), `design/redlines.json`, `design/sim/content-lint.mjs`.
  - Checks: `Politics.validate()` and the content lint are both at 0 errors.
- **UX:** `ux/ui-strings.json` (476 keys), `string-budgets.json`, `rtl-map.md`, `ftue.md`. The lint
  measures with the real font and reports 0 errors.
- **Art:**
  - the 2D Artist's UI kit (`art/od-sevev/ui-kit.json`, 197 pieces), the wordmark, the icon and the OG
    image;
  - the hand-drawn Suitcase, small Dubi, submarine, poison machine and checkbook;
  - style guide v2.
- **Cast:** 24 characters rendered from ChatGPT refs by the render-down pipeline (idle plus a
  signature react, and 24/32 px avatars). **The cast is currently 1× density (96 px).**
- **Font:** 171 glyphs, including 12 pixel pictograms. **The ₪ was redrawn at 7×6** at Bar's request.
- **Audio v1.2:** HaTikva's minor (Bar's direction).
  - The 4 era themes, the leitmotif (the anthem's rise, unresolved) and the fanfare; 279 files, 10.87 MB,
    −16 LUFS, deterministic.
  - Mock-ups to listen to are in `gamestudio/output/tmp/od-sevev-audio/`.
  - It is wired through `od_manifest.json` in `audio.gd`.
- **Motion specs:** `motion/` holds the Magician, cast and Dubi state graphs, `motion-spec.yaml`,
  event markers and the diorama.

## In flight when stopped (half-done; check before trusting)
1. **Resolution: Bar chose 3× character density.** The proof is in
   `creative-pack/.../showcase/_test/res-compare.png`.
   - **The Technical Artist was re-rendering the cast at H=288** with `density: 3` in `sprites.json`.
     It was stopped; `sprites.json` still shows density 1.
   - **The engine lead was about to do integer art scaling**, `k = floor(device_px_width / 180)`.
     Today the 720 canvas maps to 750 device px, a fractional 4.17 px per art px, and pixels wobble.
     Neither change has landed.
2. **Chat tab (T3), the coalition group chat.** The engine lead was about to start it. It's the biggest
   missing view.
3. **Missing views** (a views developer had just started; only `game/scripts/ui/views/view_rules.gd`
   exists): the dossier tab (T4), the suspicion thermometer, the cottage cup, the court card (the
   postponement excuse, the aide drop, the pardon stamps), Dubi's news-flash card (`chars["dubi-mic"]`),
   and a desktop phone frame.
4. **Sim developer:** it was stopped mid-fix (a `%g` format bug). Its open asks:
   - 5 held spin effects (s02, s05, s07, s08, s10);
   - `linesVariants` rotation;
   - Gotliv's card-only blackout;
   - the "מס׳ N" title;
   - trophy counters.

## Broken right now
- `test_input.gd::test_buy_a_producer_by_touch` fails. It's most likely the engine lead's interrupted
  layout or scaling edit. Check `git diff`-free: compare it against the last strict build at 00:41
  (`build/web/`).

## Open objection (not resolved)
- **O-A3, Audio Director → audio dev.** The first-tap Dubi squawk currently plays *under* the motif.
  With v1.2 the motif is the anthem's opening, so it should start after `musicalSeconds` (2.33 s in D).
  It's a 1-line change in `audio.gd`.

## Decisions Bar made (keep them)
- **Title:** "עוד סבב".
- **Engine:** the Godot fork, placed in gamestudio/output (not ~/hakosem).
- **Art:** copy the ChatGPT refs closely (the render-down pipeline); 3× character density.
- **Distel:** v2 approved. **May Golan: still waiting for Bar to pick 1/2/3**
  (`~/Downloads/odsevev-maygolan-opt{0,1,2}.png`); not built yet.
- **The ₪ glyph redrawn.** **Music references HaTikva**, played straight and never mocked; the
  guardrail is enforced in `compose_od.py`.
- **Maroon waiver** for the Qatari aides' folder (Qatar thread).
- **The stage/UI stays 1× chunky;** only the cast gets higher density.

## ChatGPT assets
- **Usage is nearly gone:** Bar's account showed "5% remaining".
- **Downloads:** Chrome blocks repeated automatic downloads. Allow chatgpt.com under
  `chrome://settings/content/automaticDownloads`.
- **Still wanted:**
  - May Golan (choose from the 3);
  - `aide`, `almog` avatar, `mk-generic` (defector);
  - photobomber grey/white (post-launch; can be hand-drawn).
- **Convention:** every ref goes to `creative-pack/od-sevev/art/refs/<slug>.png`, and its landmarks go
  to `showcase/src/cast.py`.

## Before ship (Bar's calls, not code)
- **Sources:** 13 facts need a URL and 4 quotes need exact Hebrew (Trump, Gotliv, the brawl, Illouz).
  The request to do this, sent to a peer session ("Monkey banana game improvements"), was **held for
  Bar's approval and never delivered**, so this is still open. The scope: `url` and verified-Hebrew
  fields in `design/facts.json`, notes in `design/facts-verification.md`, content lint at 0.
- **Launch:** the publisher name and contact (disclaimer placeholders), the domain, a gated Vercel
  deploy (`OD_VERCEL_PROJECT`), and the Mordechai David and Yair flags (off by default).
- **Listen:** the HaTikva mock-ups on a phone.

## Suggested next steps, in order
1. Fix the failing input test. Land integer scaling (engine) and the 3× cast (TA), with a before/after
   screenshot on 390×844 at DPR 2 and 3.
2. Build the chat tab (T3), then the missing views list above.
3. Resolve O-A3. The sim developer's open asks.
4. UX re-review of the full build (the UX agent asked for a ping after the layout landed).
5. Commit (conventional: `feat(gamestudio): …`), then go through Bar's before-ship list.
