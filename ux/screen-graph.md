> **Superseded for "עוד סבב" (2026-09-28):** this is the Monkey Bananas v2 record the fork inherited. Implement from rtl-map.md (layout) and ftue.md (prompts). Kept for engine history only.

# screen-graph + navigation-contract — Monkey Bananas

Owner: UX Designer. Consumers: Game Developer (scene/overlay state, input routing), 2D Artist (screen-set scope), Animator (overlay enter/exit motion).
Companion files: [`hud-layout.md`](hud-layout.md) (coordinates), [`ftue-flow.md`](ftue-flow.md), [`settings-and-a11y.md`](settings-and-a11y.md), [`number-and-copy.md`](number-and-copy.md) (every string).

## 1. IA pattern

**Hub-and-spoke, depth ≤ 2.** `MAIN` is the hub. Every overlay is a single spoke off it (depth 1). The only depth-2 node is `RESET_CONFIRM`, which is a child of `SETTINGS`. There are 7 player-visible surfaces in total, so `ceil(log_7(7)) = 1` is the natural depth. The one depth-2 node is defended because it is a destructive confirmation: it has to be a separate step from the Settings screen, by definition.

**The shop is not a node.** It is a persistent, non-modal panel inside `MAIN`, and its two tabs are *facets*, not screens. Why there is no drawer: buying is the #2 verb (2–6 purchases/min, per mechanic-spec §1). A drawer would add one tap before every purchase and hide the affordability state, which is the main decision signal of the genre. A persistent panel follows the "supplements without interrupting → non-modal" rule (NN/g).

## 2. Node inventory

| ID | Surface | Modal? | Why modal / non-modal | Entry | Exit (all paths) |
|---|---|---|---|---|---|
| `BOOT` | Black screen. Textures are baked here. After 300 ms it shows "LOADING" (×3, centred) | n/a (transient) | No player action exists | Page load | Auto → `TITLE` (no save) or `MAIN` (save exists) |
| `TITLE` | First-launch attract state: the wordmark, the Big Banana in its final position, and "TAP THE BANANA" | Full-screen state | It is needed for the WebAudio unlock gesture. It is the Main scene with the HUD hidden, so it is **not** a separate scene | `BOOT` with no save; after `RESET_CONFIRM` → Reset | Any pointer-down, **Space** or **Enter** → `MAIN`. If the pointer-down lands in the Big Banana hit area, it also counts as tap #1 (award + full juice). Esc: no-op |
| `MAIN` | Hub: top bar, stage, ticker, shop panel | Non-modal root | — | `TITLE`, `BOOT`, closing any overlay, end of `EVOLVE_TX` | Gear / **Esc** → `SETTINGS`; Evolve button → `EVOLUTION`; tab hidden ≥ 60 s then returns → `OFFLINE`; browser back → leaves the page (autosave on `pagehide` + `visibilitychange`) |
| `SETTINGS` | Settings overlay | Modal | Changes global state; the game keeps ticking behind it | Gear (top bar), Esc on `MAIN` | ✕ button, **backdrop tap**, **Esc**, browser back → `MAIN`. RESET SAVE row → `RESET_CONFIRM` |
| `RESET_CONFIRM` | "RESET SAVE?" confirmation | Modal (destructive) | Destructive action. **No backdrop dismiss** (destructive exception) | RESET SAVE row in `SETTINGS` | CANCEL / **Esc** / browser back → `SETTINGS` (default focus is CANCEL). RESET → wipe the save (settings kept) → `TITLE` |
| `EVOLUTION` | The Evolution overlay in one of two states: `preview` (gate not met; confirm disabled) or `ready` (gate met) | Modal | It interrupts for an informed, high-consequence decision | Evolve button (both states: disabled → `preview`, enabled → `ready`) | ✕, BACK, **backdrop tap**, **Esc**, browser back → `MAIN`. EVOLVE! (only in `ready`) → save → `EVOLVE_TX` |
| `EVOLVE_TX` | Evolve transition: fade → species card → fade in. At most 1,500 ms | Input-locked (not a node the player acts in) | Idempotency (mechanic E7) | EVOLVE! | Auto → `MAIN` (run N+1). Esc, back and taps are swallowed. Browser back: re-push the history state |
| `OFFLINE` | "WELCOME BACK!" receipt | Modal | Explains a state change the player did not cause | `BOOT` with a save, `elapsed ≥ 60 s` and award > 0; or an in-session return after hidden ≥ 60 s with award > 0 | COLLECT, **backdrop tap**, **Esc**, **Enter/Space**, browser back → the node underneath (`MAIN`, or the queued overlay). Every exit is a collect (see §5) |
| `ROTATE` | "TURN YOUR PHONE UPRIGHT" hint: a DOM element over the canvas | Blocking hint | The canvas at a landscape-phone scale (about 0.25×) is unreadable | CSS media query `(orientation: landscape) and (pointer: coarse) and (max-height: 500px)` | Rotating the device (automatic). No dead end: the only exit is the only fix, and the game keeps running underneath |

Surfaces that are **not** nodes (they live inside `MAIN` and never capture navigation): the shop tabs (PRODUCERS / UPGRADES), the buy-mode toggle, the Golden Banana, the buff banners and chip, FTUE pointer prompts, and the ticker.

## 3. Graph

```
            (no save)                 (save)
BOOT ───────────────► TITLE     BOOT ────────► MAIN ◄──────────────┐
                        │ tap / Space / Enter    ▲  │               │
                        └────────────────────────┘  │               │
                                                    │               │
      ┌───────────── gear / Esc ───────────────────┤               │
      ▼                                            │               │
  SETTINGS ── ✕/backdrop/Esc/back ────────────────►┤               │
      │ RESET SAVE                                 │               │
      ▼                                            │               │
  RESET_CONFIRM ── CANCEL/Esc/back ──► SETTINGS    │               │
      │ RESET                                      │               │
      └──────────► TITLE ───────────────────────► MAIN             │
                                                   │               │
  EVOLUTION ◄──── Evolve button ──────────────────┤               │
      │  ✕/BACK/backdrop/Esc/back ────────────────►┤               │
      │ EVOLVE! (ready only)                       │               │
      ▼                                            │               │
  EVOLVE_TX ── auto ≤1.5 s ───────────────────────►┘               │
                                                                   │
  OFFLINE ◄── load w/ save & away ≥60 s | tab return ≥60 s         │
      └── COLLECT/backdrop/Esc/Enter/back ─────────────────────────┘
```

## 4. Reachability proof (no dead ends, no modal traps)

| Node | Visible exit affordance | Backdrop | Esc | Browser back | Steps to `MAIN` | Steps to resume play |
|---|---|---|---|---|---|---|
| `BOOT` | none needed (auto) | — | — | leaves page | 0 (auto) | 0–1 |
| `TITLE` | "TAP THE BANANA" (the whole screen is the target) | n/a | no-op | leaves page | 1 | 1 (the same tap is tap #1) |
| `MAIN` | — | — | opens Settings | leaves page | 0 | 0 |
| `SETTINGS` | ✕ (104×104 hit) | yes | yes | yes | 1 | 1 |
| `RESET_CONFIRM` | CANCEL (104 hit) | **no** (destructive) | yes = Cancel | yes = Cancel | 2 (Cancel → ✕) | 2 |
| `EVOLUTION` | ✕ and BACK | yes | yes | yes | 1 | 1 |
| `EVOLVE_TX` | none (auto, ≤ 1.5 s) | — | swallowed | swallowed | 0 (auto) | 0 |
| `OFFLINE` | COLLECT | yes | yes | yes | 1 | 1 |
| `ROTATE` | the text itself explains the fix | — | — | — | rotate device | rotate device |

Every node reaches `MAIN` in ≤ 2 player steps. Every modal except `RESET_CONFIRM` has a visible close control, a backdrop close, Esc, and browser back. `RESET_CONFIRM` has an explicit CANCEL, plus Esc and back. No modal can open on top of another modal except `RESET_CONFIRM` over `SETTINGS`. The **only** terminal action (RESET) lands on `TITLE`, which itself exits in one tap.

## 5. Navigation contract

**Overlay slot rule.** Only one overlay is open at a time, apart from the pair `SETTINGS → RESET_CONFIRM`. If an overlay is requested while another one is open (for example an `OFFLINE` return while `SETTINGS` is open), the request is queued and shown the moment the current overlay closes. The Evolve button and the gear are covered by the scrim while an overlay is open, so they cannot be pressed.

**Input capture.** An open overlay swallows every pointer event, including backdrop taps, which close the overlay but **never** fall through to the Big Banana, the Golden or the shop. Space never taps the banana while an overlay is open; it activates the focused button instead.

**Esc** (`keydown`, `repeat === false`):
- On `MAIN` with no overlay: open `SETTINGS`.
- With an overlay open: close the top overlay (the same as its cancel or close path; on `OFFLINE` it collects).
- On `TITLE`: no-op. During `EVOLVE_TX`: swallowed.

**Host back button** (Android system back, browser back arrow). Default: pop one node.
- Opening an overlay calls `history.pushState({mbOverlay: id}, '')`.
- On `popstate` while an overlay is open: close the **top** overlay only, and do not call `history.back()`.
- Closing an overlay through the UI (✕, backdrop, Esc, buttons) calls `history.back()` with a one-shot `ignoreNextPop` flag, so that the history stack and the overlay stack stay the same depth.
- On `popstate` during `EVOLVE_TX`: `pushState` again to swallow it.
- On `MAIN` or `TITLE` with no overlay: do nothing, and the browser leaves the page. The save flushes on `pagehide` and `visibilitychange → hidden` (mechanic-spec rule 10).

**Evolve is idempotent.** EVOLVE! locks input on its first frame, the save completes, and then `EVOLVE_TX` starts (mechanic E7). A second press is ignored.

**Offline = credit, then receipt (data-integrity rule).** Credit the award to `bananas/runBananas/allTimeBananas` and **save at the moment it is detected**, before the modal renders. The modal is a receipt, and every exit path is a "collect" that only plays feedback.

**Offline roll timing (accepted from the Audio Director).**
- **Cold load:** the modal opens with the amount showing **+0** and the COLLECT button ready. The COLLECT press (pointer, Enter or Space) is the gesture that resumes the AudioContext. That same press starts the 800 ms roll (0 → award, display only, because the credit already happened) and `offlineCollect` fires when the roll ends. The modal closes 300 ms later, or immediately if the player taps again during the roll (the cue still plays).
- **Backdrop tap on a cold load:** the modal closes immediately and `offlineCollect` plays as it closes (pointerup/touchend grant user activation, so the context can run).
- **Esc or browser back on a cold load:** the modal closes **silently**. Neither grants user activation. The award is already credited, so nothing is lost; audio unlocks on the next gesture.
- **In-session return:** audio is already unlocked, so the roll starts automatically when the modal opens (as before). COLLECT closes it, and `offlineCollect` fires at the end of the roll. Why: autosave runs every 10 s and rewrites `lastSaveTime`. If the award waited for a COLLECT tap, a player who closes the tab while the modal is open would lose the whole award.

**Golden and modals.** While any modal is open, the Golden spawn timer and the on-screen Golden's lifetime **pause**; buffs and production keep running (see Objection OBJ-4 in the handback). A Golden is never lost behind a modal.

## 6. Entry-point matrix

| Entry | Condition | Lands on | Back-stack |
|---|---|---|---|
| Cold launch, first time | no save in localStorage | `BOOT → TITLE` | `[TITLE]` |
| Cold launch, returning, short gap | save, `elapsed < 60 s` or award = 0 | `BOOT → MAIN` | `[MAIN]` |
| Cold launch, returning, away | save, `elapsed ≥ 60 s`, award > 0 | `BOOT → MAIN + OFFLINE` | `[MAIN, OFFLINE]` |
| Tab return in session | hidden ≥ 60 s, award > 0 | `OFFLINE` over the current node (queued if an overlay is open) | `[…, OFFLINE]` |
| Reload during `EVOLVE_TX` | the save was already written before the transition | `MAIN` (run N+1) | `[MAIN]` |
| After RESET | save wiped (settings kept) | `TITLE` | `[TITLE]` |
| Save unreadable or corrupt | JSON parse or version fails | `TITLE` (treated as first launch); ticker line `F_SAVE_CORRUPT` after start | `[TITLE]` |
| localStorage unavailable | `setItem` throws | Normal flow; ticker line `F_NO_SAVE` once per session | as above |
| Deep link / share / ad return | none exist (single URL, no monetization) | n/a | n/a |

**Audio unlock:** see `audio/legacy/audio-cue-spec.md` §5 (U1–U10). Every gesture retries until the context runs, and the unlocking tap sounds its own cue. Returning players do **not** see `TITLE`: an idle game lives on short check-ins, so skipping it saves one tap every session.

## 7. Locatedness (per node)

| Node | "Where am I?" cue | "Where did I come from?" | What back does |
|---|---|---|---|
| `MAIN` | The Big Banana, the top bar, and the active tab drawn raised with an underline | — | leaves the site |
| `SETTINGS` | Title "SETTINGS" (×4); scrim over Main | Main is visible under a 60% scrim | → `MAIN` |
| `RESET_CONFIRM` | Title "RESET SAVE?"; Settings visible under a second scrim | Settings | → `SETTINGS` |
| `EVOLUTION` | Title "EVOLUTION" | Main under the scrim | → `MAIN` |
| `OFFLINE` | Title "WELCOME BACK!" | Main under the scrim | → `MAIN` |

## 8. Funnel and navigation events (names only; the developer plumbs them, I6)

`nav_overlay_open{id, via: pointer|key|auto}`, `nav_overlay_close{id, via: close|backdrop|esc|back|confirm}`, `evolve_preview_opened{pending, needed}`, `evolve_confirmed{pending, thumbsOwned}`, `offline_shown{awaySec, award, capped}`, `reset_confirmed`, `reset_cancelled`. The FTUE events are in `ftue-flow.md` §6.
