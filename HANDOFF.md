# HANDOFF: "עוד סבב" (2026-09-29, end of session 2)

Bar stopped the studio loop. No agent is running and the loop lock is released. Everything below
is committed and pushed to `claude/magical-ride-ntn3u5` (last commit `8d28ac1`).
`STATUS.md` is the full agent log: every request, objection and decision, newest at the bottom.

## Where things are

| What | Where |
|---|---|
| Source (this repo) | `barmoshe/od-sevev`, branch `claude/magical-ride-ntn3u5` (94 commits since `d366061`) |
| Live game | **https://od-sevev.vercel.app**. Public; it serves build `e067444`, which is older than the branch (see "Deploy") |
| Vercel | team "barmoshe's projects" (`team_ok1MqoSMeupTyBE6CXAR91UT`), project `od-sevev` (`prj_ZbQ1ubW0AU5hfhSVnVtcsgmm6BVA`). Vercel Authentication is on for previews only |
| Deploy branch | `web-dist`: the static output of `tools/build_web.sh`. It holds generated files only; never edit it |
| Leader-select design | `design/leader-select-spec.md` (the designer's spec; §10 is the replacement checklist, §12 Bar's calls) |
| Picker UX | `ux/rtl-map.md` §8 (the `LEADER_PICK` screen), §4.3 (HUD per leader); `ux/screen-graph.md` §0 |
| UX review | `ux/review-2026-09-29.md` (R1-R26; all closed) |
| Sources | `design/facts.json` (72 facts), `design/facts-verification.md` |

**Health at `8d28ac1`:**
- `tools/test.sh`: 301/301.
- Strict `tools/build_web.sh`: green (content lint and text lint 0).
- `node design/sim/content-lint.mjs --strict`: 0 errors, 0 warnings.
- `tools/balance.sh`: last verified green (5/5) at `5f64cf2`. **It was not re-run after the leader sim merged** (see Next).

## Run it
```
tools/test.sh                       # headless unit tests (Godot 4.7.2 via tools/godot.sh)
tools/build_web.sh                  # strict: content lint (red lines) + pixel text lint, then export to build/web
python3 -m http.server 8801 --directory build/web
node tools/web/res_web.mjs  http://127.0.0.1:8801/ <dir>    # scaling + first squawk
node tools/web/views_web.mjs http://127.0.0.1:8801/ <dir>   # flash, cottage, phone frame
node tools/web/modals_web.mjs / share_web.mjs / round_web.mjs  # modals, share cards, a full round
tools/balance.sh                    # pacing bench, about 11 min
xvfb-run -a python3 pipeline/od-sevev/build.py --no-render --godot   # re-import art (the --godot pass needs a display)
```

**Environment notes:**
- **Godot:** in a cloud container, download 4.7.2 into the scratchpad, where `tools/godot.sh` looks. Export templates install into `~/.local/share/godot/`.
- **Network:** the container can't reach `vercel.app`. Check a deployment with the Vercel connector's `web_fetch_vercel_url`.
- **Parallel agents:** use git worktrees and a unique http port each; two agents on one port once read each other's build. `STATUS.md` conflicts are append-only, so keep both sides.
- **Generated files** (`sprites.json`, `budget.json`, `ui-strings.json`): resolve conflicts by re-running the generator or pipeline, never by hand.

## Deploy
There is no Vercel CLI token in the container, and the connector can't upload the 40 MB wasm, so the deploy goes through git:
1. Run `tools/build_web.sh`. It is strict, and `OD_SITE_URL` defaults to `https://od-sevev.vercel.app/`, so the OG tags come out absolute.
2. Replace the `web-dist` branch's files with `build/web/*` + `tools/web/vercel.json` and a README, commit and push. A worktree of `web-dist` works well for this.
3. Vercel connector `create_deployment`, team above, `name: "od-sevev"`, `gitSource {type: github, org: barmoshe, repo: od-sevev, ref: web-dist, sha: <commit>}`, `projectSettings {framework: null, buildCommand: "", installCommand: "", outputDirectory: "."}`. A deploy to the project goes to production.

On Bar's Mac, `OD_VERCEL_PROJECT=od-sevev tools/deploy_web.sh` still works with the CLI.

## What changed this session (all merged)
- **Resolution:**
  - Integer device scaling, with k restricted to multiples of 2 or 3, so the cast is whole-pixel on every phone.
  - The whole cast at d=3 and d=2.
  - Sevev 9 @2, a double-density Hebrew font, for reading text.
  - The scrim, the dim and the flash were invisible and are fixed.
- **Screens:** the coalition chat (T3) and the partner card; the dossier (T4) with the pardon desk; the thermometer with sweat; the court card and chip; Dubi's news flash; the cottage cup; the desktop phone frame; the election, return and reset modals; the share cards (receipt and result) with WhatsApp; the pending chip; the brawl cue; the spin-end toast.
- **Sim:**
  - The 5 held spins, trophy stats and pacing re-tuned to the pitch's gates (first election 7-9 min).
  - The brawl trap is fixed in the view.
  - **The leader-select core** (`game/scripts/sim/leaders.gd`: install per leader, knobs, filters, save v4, per-leader bench). **Dormant:** it defaults to Bibi until the picker exists.
- **Content:**
  - The player character is "ביבי", never "הקוסם".
  - Every launch fact has a source and a public Hebrew `aboutHe`.
  - Full kits for all 8 leaders.
- **Guardrails:**
  - **No October 7, anywhere:** the lint covers content, UI strings and About, plus the 7.10 date forms. `tools/build_web.sh` fails on any hit. An art sweep ran too.
  - **Quotes:** invented quotes of real people are forbidden. Use reported speech unless the quote has a sourced [Q] fact.
- **Art:**
  - Tap animations and props for all 8 leaders.
  - The lineup key art, OG image and app icon.
  - The UI kit (242 pieces), the spin icons, and a no-photo silhouette for partners without art.
  - Yair Golan re-rendered from Bar's ref.

## Bar's decisions (keep them)
- **Protagonist:** ביבי is named, never הקוסם. No mention of October 7, direct or by date or image.
- **Leader select:** each round the player picks one of 8 party heads:
  - ביבי, בן גביר, סמוטריץ׳, דרעי · בנט, אייזנקוט, ליברמן, גולן;
  - Lapid rides inside Bennett's round; Gantz, Abbas and UTJ are out;
  - the picker comes before the first tap and replaces the title;
  - +10% base for switching leaders;
  - the lineup key art replaces Bibi-with-hat;
  - Bibi's lineup keeps today's partner numbers.
- **May Golan:** option 1. The new Yair Golan ref is `creative-pack/art/refs/golan.png`.
- **Kept on purpose:**
  - spin s12's name "הוחלט להקים ועדה" (its icon was redrawn without chairs);
  - s09 "פייג׳ר זהב";
  - the "ידיים של קוסם!" idiom.
- **WhatsApp:** "לשתף בוואטסאפ" is allowed as a functional label only. There is a scoped exception in `design/redlines.json`, and no WhatsApp styling.

## Next, in order
1. **Build the leader picker (views and engine).**
   - Implement `ux/rtl-map.md` §8 against the sim API in `game/scripts/sim/README.md` (`Leaders` / `Politics.install`, `start_round`, undo).
   - Work through spec §10's checklist.
   - Swap in the `_LEADER` / `_NEXT` string keys.
   - Switch `SHARE_TEXT_INVITE` to `_NEXT` and update `test_share_view.gd:99`.
   - Draw the tap props at `propMouth`, per CONTRACT §4c.
   - Hide the Bibi-only views (court, pardon, aide, Sara, DOHA, spins s07/s09/s10/s14/s15) for everyone else; they get the press skin.
   - Add Liberman's "לא יושב" pill and Golan's "לאחד" pill.
2. **Verify the leader sim.** Run `tools/balance.sh` and the per-leader bench (`game/tests/bench/test_leaders_balance.gd`). Liberman's lineup is the tightest, so apply the spec's fix if he runs over 9 min. The sim developer was stopped before reporting: review `leaders.gd` and its 31 tests.
3. **Re-run the three cancelled slices.** Bar stopped them; nothing from them was kept.
   - **Audio:** the cue coverage audit and a mix pass on every new view, plus the `leaderPick` sting (the new first sound) and the crit-cue mapping by react event (spec §9.5).
   - **Animator:** Bibi's court-day exit/return and the `court_window` echo; the motion audit of the new views; the leader walk-out in the election transition and walk-in on the pick; the brawl cloud boil.
   - **Designer:**
     - Why a scripted browser round took 34 min to the first election while the bench says about 8.
     - R17: re-place `producers[].slot` so money sources clear the thermometer and the Magician's hit box.
     - Also: a one-line `rule` for ביבי; a poll-number lint on "רוב"; a leader-neutral count for the result card's `DAYS_*`.
4. **UX review** of the picker build, then a strict build and redeploy (see Deploy).

## Before a real launch (Bar's calls, not code)
- **Publisher and contact.** The disclaimer shows "מאת base67" with no mail. Set `OD_PUBLISHER` / `OD_CONTACT_MAIL` for the build.
- **Domain.** Today it is `od-sevev.vercel.app`, and `OD_SITE_URL` and `ShareKit.SITE_URL` must follow a change.
- **Sources.** All launch facts plus the 21 new leader facts were verified from search results only, because the sandbox blocked opening pages. Open each link once.
- **Legal reads:**
  - Deri's kit (the 2022 tax plea and "חוק דרעי");
  - בן גביר as a playable protagonist;
  - the brawl and Illouz lines stay reported speech.
- **Device checks:** on a real iPhone, check the share sheet (only the download/clipboard fallback was browser-tested) and listen to the HaTikva-based audio.
- **Art wanted from ChatGPT:** `almog` (he shows the no-photo silhouette), `aide`, `mk-generic`. Tell the TA if you want Bibi's hat and rabbit at 3× (it needs a cast re-render).
- **Old flags:** decide the Mordechai David and Yair flags (off by default).
- **Pro Max pixel scale:** the orchestrator chose to drop k 7 to 6 (crisp, about 14% smaller), part of Bar's "sharp on every phone" request. Revert the crisp-k rule in `display.gd` if you'd rather have the bigger, softer picture.
- **App icon:** it is now the ring of eight heads. Revert `art/od-sevev/out/key/icon-128-art.png` and re-run the pipeline if you prefer the old one.
