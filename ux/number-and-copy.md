> **Superseded for "עוד סבב" (2026-09-28):** this is the Monkey Bananas v2 record the fork inherited. Implement from ui-strings.json, string-budgets.json and rtl-map.md §0 (number and bidi rules). Kept for engine history only.

# number-and-copy — Monkey Bananas

Owner: UX Designer. Consumers: Game Developer (formatters, string module), Technical Artist (glyph set), 2D Artist (text sizes on panels).
**Canonical copy for code: [`ui-strings.json`](ui-strings.json).** It was generated and budget-checked by the UX Designer: every string, content name and upgrade effect is checked against its region's character budget, with 0 violations. This file is the review mirror; if the two disagree, the JSON wins.

## 1. Font and width maths

- 5×7 glyphs plus 1 font-px spacing give an **advance of 6 font px**. The width of *n* chars is `6·s·n − s` logical px at scale ×s (no trailing gap). Rule: all rendered text is **UPPERCASE** (apply `toUpperCase()` to content strings), so the font needs only one case.
- **Required glyphs** (Technical Artist): the full `A–Z` (J included, although no current string uses it), `0–9`, and `space ! " % ' ( ) + , - . / : = ?` plus `×` (U+00D7) and `→` (U+2192). Fallbacks if they are absent: `×` → `X`, `→` → `>`. Normalize curly quotes to straight quotes before rendering.

| Region | Width available | Scale | **Max chars** |
|---|---|---|---|
| Canvas line (24-px margins) | 672 | ×2 / ×3 / ×4 / ×6 / ×8 | 56 / 37 / 28 / 18 / 14 |
| Modal inner (624 panel − 64) | 560 | ×3 / ×4 | 31 / 23 |
| Confirm modal inner (560 − 64) | 496 | ×3 / ×4 | 27 / 20 |
| Bank (x 64 → 376) | 312 | ×4 | **7** (budgeted; the bank never exceeds 7) |
| bps line | 312 | ×3 | **17** |
| Thumbs chip (x 64 → 376) | 312 | ×3 | **13** (budgeted) |
| Evolve button inner (216 − 16), after the 40-px icon on line 1 | 200 / 160 | ×3 | line 1 **8**, line 2 **11** |
| Row name / row line 2 (x 112 → 508) | 396 | ×3 | **22** |
| Cost pill inner (168 − 16) | 152 | ×3 | **8** (verb) / **6** (cost) |
| Tab label, PRODUCERS (248 − 16) | 232 | ×3 | 13 |
| Tab label, UPGRADES (232 − 48 badge) | 184 | ×3 | 10 |
| Buy toggle (168 − 16) | 152 | ×3 | 8 |
| Buff chip (352 − 16) | 336 | ×3 | **18** |
| Buff banner (528 − 32) | 496 | ×4 | **20** |
| Ticker clip (v1.1: x112–704) | 592 | ×3 | 33 visible (33 chars = 591 px); **paged mode wraps at 33** |
| Evolution columns | 280 | ×3 | 15 |
| Species name (overlay / card) | 560 / 672 | ×3 / ×4 | 31 / 28. The longest title, "PEEL-DWELLING PHILOSOPHERS", is 26 ✓ |

## 2. Number formatting (display only; the maths stays in raw doubles)

Suffix tiers come from `content.json` `numberFormat`: tier 1 K, 2 M, 3 B, 4 T, then tier ≥ 5 is a letter pair `A+floor(n/26)`, `A+n%26` with `n = tier − 5`, rendered **uppercase** (`1.00AA`). Compute the tier with integer comparisons (`while v >= 1000**(t+1) t++`), never `log10` alone, to avoid 999.9999 edge errors. Any non-finite value renders `"MAX"` (mechanic E3 clamps before this).

| Formatter | Used for | Rounding | < 1,000 | ≥ 1,000 | Examples | **Max chars** |
|---|---|---|---|---|---|---|
| `fmtBank(v)` | top-bar bank | **floor** | integer | **< 1,000,000: full integer with commas**. ≥ 1M: **4 significant digits**, truncated | 999 · 12,345 · 999,999 · 1.234M · 12.34M · 123.4B · 1.000AA | **7** |
| `fmtCost(v)` | pill cost, silhouette cost | **ceil** at display precision (if the ceil reaches 1000 at a tier, roll to `1.00` of the next tier) | integer (ceil) | 3 significant digits | 15 · 1.10K · 12.4K · 124K · 1.40M · 330AA | **6** |
| `fmtRate(v)` | bps | round half-up | < 10: 1 decimal ("0.4"); else integer | 3 significant digits | 0.4 · 2.8 · 16 · 4.86K · 1.23AA | **6** |
| `fmtAmount(v)` | floaters, Lucky Bunch, offline amount | round | integer | 3 significant digits | +1 · +10 · +4.86K · +291K | **6** (+ sign = 7) |
| `fmtThumbs(v)` | Thumbs chip, pending/needed | pending **floor**, needed **ceil** | exact integer below **10,000** | ≥ 10,000: 3 significant digits | 12 · 959 · 4319 · 43.1K | **5** |
| `fmtMult(m)` | prestige ×, Evolution preview | round | m < 1000: exactly 1 decimal (`toFixed(1)`) | 3 significant digits | ×1.0 · ×2.2 · ×96.9 · ×432.9 · ×4.31K | **6** incl. × |
| `fmtQty(n)` | pill "BUY ×n" | — | integer | never reaches 1000 in practice (costGrowth 1.15); clamp display to 999 | ×10 · ×23 | 3 |
| `fmtOwned(n)` | "OWNED n" | — | integer, no commas | 3 significant digits above 99,999 | 23 · 1234 | 5 |
| `fmtDur(sec)` | offline "away" | floor | < 3600: "12M" | "3H 12M" (≥ cap → use `OFF_AWAY_CAPPED`) | 1M · 59M · 7H 59M | 6 |
| `fmtSecs(sec)` | buff chip countdown | **ceil** | "12S" | — | 15S · 1S | 3 |

**Why the bank departs from 3 significant digits.** At "1.23K" a +1 or +4 tap does not change the displayed bank until about 10 bananas accumulate. The feel-spec `bankPopScale` would then pop a number that did not move, so the counter would under-report the action it is animating. Showing the full integer below 1M means every early tap visibly ticks the counter. From 1M, 4 digits keep passive income visibly ticking: at 1.5M with 4.86K/s, the 4th digit moves every 0.2 s. Costs keep 3 digits (content.json), because costs are static and are read against the BUY/NEED label, not against the bank digit by digit. See OBJ-5.

**Honesty invariant (from mechanic E4).** The displayed bank is always ≤ the true bank and a displayed cost is always ≥ the true cost. So if the displayed bank ≥ the displayed cost, the item really is affordable. The reverse window (it looks short by about 1% but is actually affordable) is resolved by the row's **BUY** label, which is computed from raw values.

## 3. Content strings (from content.json, uppercased; all within budget)

| id | Row name (≤ 22) | Display plural (for effects) |
|---|---|---|
| intern | INTERN MONKEY (13) | INTERNS |
| tree | BANANA TREE (11) | TREES |
| hardhat | HARD-HAT CREW (13) | HARD-HATS |
| bureaucrat | BANANA BUREAUCRAT (17) | BUREAUCRATS |
| catapult | BANANA CATAPULT (15) | CATAPULTS |
| rocket | MONKEY SPACE PROGRAM (20) | ROCKETS |
| timechimp | TIME-TRAVELING CHIMP (20) | TIME CHIMPS |
| moon | THE BANANA MOON (15) | MOONS |

**Upgrade effect strings** are generated from `effect.type` and put in row line 2 (≤ 22):

| Type | Template |
|---|---|
| `tapMult` | `TAP VALUE ×{mult}` |
| `tapPctOfBps` | `TAP +{add·100}% OF PER SEC` |
| `critChance` | `CRIT CHANCE {set·100}%` |
| `goldenIntervalMult` | `GOLDENS {(1−mult)·100}% SOONER` |
| `globalMult` | `ALL PRODUCTION ×{mult}` |
| `producerMult` | `{PLURAL} ×{mult}` |

Results:
- GRIPPY GLOVES / TAP VALUE ×2
- TWO-HANDED TECHNIQUE / TAP VALUE ×2
- THUMB WORKOUT / TAP +2% OF PER SEC
- LUCKY PEEL / CRIT CHANCE 10%
- GOLDEN BANANA RADAR / GOLDENS 25% SOONER
- BANANA FUTURES MARKET / ALL PRODUCTION ×1.5
- BANANA HAMMER / TAP +4% OF PER SEC
- COFFEE FOR INTERNS / INTERNS ×2
- BANANA FERTILIZER / TREES ×2
- TALLER LADDERS / HARD-HATS ×2
- FORM B-4-NANA / BUREAUCRATS ×2
- **DOUBLE-BARREL CATAPULT (22, the longest)** / CATAPULTS ×2
- BANANA FUEL / ROCKETS ×2
- PARADOX INSURANCE / TIME CHIMPS ×2
- A SECOND MOON / MOONS ×2

**Flavor text** has no permanent home in the MVP layout. It pays off through the ticker: buying an upgrade queues `F_UPGRADE_FLAVOR` = `"{NAME}: {FLAVOR}"` at milestone priority. Producer flavor is already covered by the `firstOwned` headlines. Species titles are shown only in the Evolution overlay and the EVOLVE_TX card; "ASCENDED BUNCH MK 99" is 20 chars ✓.

## 4. Fixed UI copy (the mirror of `ui-strings.json` → `strings`)

`{…}` placeholders are budgeted at their formatter's max width (§2).

**Boot and title**

| ID | ×s | Max | Len | Text |
|---|---|---|---|---|
| BOOT_LOADING | 3 | 37 | 7 | LOADING |
| TITLE_WORDMARK_1 / _2 | 8 | 14 | 6/7 | MONKEY / BANANAS (fallback only) |
| TITLE_TAGLINE | 3 | 37 | 28 | BUILD A BANANA CIVILIZATION. |
| TITLE_CTA | 4 | 28 | 14 | TAP THE BANANA |
| TITLE_KEYHINT | 3 | 37 | 14 | OR PRESS SPACE |
| TITLE_FOOTER | 3 | 37 | 29 | PROGRESS SAVES ON THIS DEVICE |

**HUD and stage**

| ID | ×s | Max | Worst | Text |
|---|---|---|---|---|
| HUD_BPS | 3 | 17 | 14 | {rate} PER SEC |
| HUD_BPS_FRENZY | 3 | 17 | 17 | {rate} PER SEC ×{mult}. The Frenzy multiplier is 1 digit (content.json: 5); if it ever reaches 10+, render `{rate}/S ×{mult}` |
| HUD_THUMBS | 3 | 13 | 13 | {thumbs}  ×{pmult} (two spaces) |
| EVOLVE_BTN / _READY | 3 | 8 | 6/7 | EVOLVE / EVOLVE! |
| EVOLVE_BTN_PROGRESS | 3 | 11 | 11 | {pending}/{needed} |
| EVOLVE_BTN_GAIN | 3 | 11 | 6 | +{pending} |
| FLOATER / FLOATER_CRIT | 4 / 6 | 9 | 7/8 | +{n} / +{n}! |
| BUFF_CHIP_FRENZY | 3 | 18 | 14 | FRENZY ×{mult} {s}S |
| BUFF_CHIP_TAPFRENZY | 3 | 18 | 18 | TAP FRENZY ×{mult} {s}S |
| BANNER_BUNCH | 4 | 20 | 20 | LUCKY BUNCH! +{n} |
| BANNER_FRENZY | 4 | 20 | 18 | BANANA FRENZY ×{mult}! |
| BANNER_TAPFRENZY | 4 | 20 | 15 | TAP FRENZY ×{mult}! |
| CALLOUT_GOLDEN | 3 | 16 | 9 | CATCH IT! |
| TICKER_TAG | 3 | 4 | 4 | NEWS |

**Shop**

| ID | ×s | Max | Worst | Text |
|---|---|---|---|---|
| TAB_PRODUCERS / TAB_UPGRADES | 3 | 13/10 | 9/8 | PRODUCERS / UPGRADES |
| TAB_BADGE | 3 | 2 | 2 | {count} (shows "9+" above 9) |
| BUYMODE_1 / _10 / _MAX | 3 | 8 | 6/7/7 | BUY ×1 / BUY ×10 / BUY MAX |
| ROW_BUY / ROW_BUY_N / ROW_NEED | 3 | 8 | 3/8/4 | BUY / BUY ×{qty} / NEED |
| ROW_OWNED | 3 | 22 | 11 | OWNED {owned} |
| ROW_LOCKED_NAME | 3 | 22 | 3 | ??? |
| UPG_EMPTY_1 / _2 | 3 | 37 | 15 | NO UPGRADES YET / KEEP HARVESTING |

**Settings and reset**

| ID | ×s | Max | Len | Text |
|---|---|---|---|---|
| SET_TITLE | 4 | 16 | 8 | SETTINGS |
| SET_GROUP_* | 3 | 22 | ≤ 13 | SOUND · ACCESSIBILITY · GAME |
| SET_SFX · SET_MUSIC · SET_REDUCED_MOTION · SET_FULLSCREEN · SET_RESET | 3 | 22 | ≤ 14 | SOUND EFFECTS · MUSIC · REDUCED MOTION · FULLSCREEN · RESET SAVE |
| SET_ON / SET_OFF / SET_RESET_BTN | 3 | 7 | ≤ 5 | ON / OFF / RESET |
| SET_KEYS | 3 | 31 | 29 | KEYS: SPACE = TAP, ESC = MENU |
| SET_VERSION | 2 | 46 | 36 | MONKEY BANANAS V1.1 - MADE BY BASE67 |
| RST_TITLE | 4 | 20 | 11 | RESET SAVE? |
| RST_BODY_1..3 | 3 | 27 | ≤ 24 | THIS ERASES ALL BANANAS, / THUMBS AND EVOLUTIONS. / IT CAN'T BE UNDONE. |
| RST_NOTE | 3 | 27 | 18 | SETTINGS ARE KEPT. |
| RST_CANCEL / RST_CONFIRM | 4 | 9 | 6/5 | CANCEL / RESET |

**Evolution**

| ID | ×s | Max | Worst | Text |
|---|---|---|---|---|
| EVO_TITLE | 4 | 16 | 9 | EVOLUTION |
| EVO_NEXT | 3 | 31 | 12 | NEXT SPECIES |
| EVO_THUMBS_GAIN | 4 | 20 | 13 | +{pending} THUMBS |
| EVO_THUMBS_PROGRESS | 4 | 20 | 18 | {pending}/{needed} THUMBS |
| EVO_BONUS / EVO_BONUS_PREVIEW | 3 | 31 | 12/16 | BANANA BONUS / BONUS WHEN READY |
| EVO_MULT | 4 | 23 | 15 | ×{now} → ×{after} |
| EVO_RESETS / EVO_KEEPS | 3 | 15 | 6/5 | RESETS / KEEPS |
| EVO_R1..R4 | 3 | 15 | ≤ 12 | BANANAS · PRODUCERS · UPGRADES · ACTIVE BUFFS |
| EVO_K1..K4 | 3 | 15 | ≤ 14 | THUMBS · ALL-TIME TOTAL · LIFETIME STATS · SETTINGS |
| EVO_NEED | 3 | 31 | 31 | NEED {needed} NEW THUMBS TO EVOLVE |
| EVO_RULE_1 / _2 | 3 | 31 | 28/19 | EACH EVOLUTION MUST AT LEAST / DOUBLE YOUR THUMBS. |
| EVO_GROW | 3 | 31 | 27 | THUMBS GROW AS YOU HARVEST. |
| EVO_BACK / EVO_CONFIRM | 4 | 10 | 4/7 | BACK / EVOLVE! |
| EVO_NOT_READY | 3 | 13 | 9 | NOT READY |
| EVOTX_LINE | 3 | 37 | 23 | YOUR TROOP EVOLVED INTO |

**Evolve explanation** (the words that teach the doubling gate, EVO_NEED + EVO_RULE_1/2): *"NEED 10 NEW THUMBS TO EVOLVE — EACH EVOLUTION MUST AT LEAST DOUBLE YOUR THUMBS."* `needed = max(10, thumbsOwned)`, so the number itself visibly doubles run to run (10 → 10 → 20 → 40…). The rule sentence names the pattern the player is seeing, and nothing else is said.

**Offline**

| ID | ×s | Max | Worst | Text |
|---|---|---|---|---|
| OFF_TITLE | 4 | 16 | 13 | WELCOME BACK! |
| OFF_AWAY | 3 | 31 | 21 | YOU WERE AWAY {dur}. |
| OFF_AWAY_CAPPED | 3 | 31 | 27 | YOU WERE AWAY OVER 8 HOURS. |
| OFF_HARVESTED | 3 | 31 | 20 | YOUR TROOP HARVESTED |
| OFF_AMOUNT | 4 | 20 | 7 | +{n} |
| OFF_NOTE_1 / _2 | 3 | 31 | 26/22 | AWAY EARNINGS: HALF SPEED, / COUNTED UP TO 8 HOURS. |
| OFF_COLLECT | 4 | 11 | 7 | COLLECT |

**Rotate hint** (a DOM element, CSS font): `ROTATE` = TURN YOUR PHONE UPRIGHT.

## 5. Ticker rules

Queue priority: **FTUE lines > milestone headlines (content.json `headlines`, once ever, persisted in `headlinesSeen`) > `F_UPGRADE_FLAVOR` > ambient** (content.json `ambientHeadlines`, one every `ambientIntervalSec`, no immediate repeat).

- **Marquee (default).** Enter from the right edge of the clip at x = 704 and scroll left at 90 px/s until fully past x = 112. The next item starts 48 px behind the tail of the previous one. The longest content headline (73 chars = 1,311 px) takes (1311 + 592)/90 ≈ 21 s. `headlineHoldSec` (6 s) is used only in paged mode.
- **Paged (reduced motion).** Word-wrap at 33 chars and show each page for 3 s (instant swap). Every FTUE line fits in ≤ 2 pages, and the longest headline takes 3 pages (9 s).
- **Pre-emption.** A higher-priority item interrupts the current one; the interrupted item goes back to the front of its own queue. A milestone flash (feel-spec, 120 ms) is shown in marquee mode only.

## 6. FTUE ticker lines (≤ 66 chars = ≤ 2 paged pages)

| ID | Len | Text |
|---|---|---|
| F1_TAP | 52 | BREAKING: LOCAL BANANA IS HUGE. EXPERTS SAY: TAP IT. |
| F1_TAP_IDLE | 49 | THE BIG BANANA IS STILL WAITING. IT HAS FEELINGS. |
| F2_HIRE | 59 | HELP WANTED: ONE INTERN. PAY: BANANAS. TAP THE ROW TO HIRE. |
| F2_HIRE_NUDGE | 48 | INTERN STILL UNHIRED. TAP THE ROW THAT SAYS BUY. |
| F3_UPGRADE | 57 | NEW GEAR IN THE UPGRADES TAB. MONKEYS CAUTIOUSLY EXCITED. |
| F4_GOLDEN | 47 | GOLDEN BANANA SIGHTED! TAP IT BEFORE IT LEAVES. |
| F4_MISSED | 45 | IT GOT AWAY. GOLDEN BANANAS ALWAYS COME BACK. |
| F5_EVOLVE_SEEN | 59 | ELDERS WHISPER OF EVOLUTION. SEE THE NEW BUTTON, TOP RIGHT. |
| F6_EVOLVE_READY | 57 | THE TROOP IS READY TO EVOLVE. EVOLVING KEEPS YOUR THUMBS. |
| F7_RUN2 | ≤ 44 | NEW SPECIES! EVERY BANANA NOW COUNTS ×{pmult}. |
| F7_RUN2_GATE | ≤ 56 | NEXT EVOLUTION NEEDS {needed} NEW THUMBS. ALWAYS DOUBLE UP. |
| F8_BULK | 49 | BULK BUYING APPROVED. TAP BUY ×1 TO SWITCH MODES. |
| F_NO_SAVE | 62 | NOTICE: THIS BROWSER WON'T SAVE. PROGRESS ENDS WHEN YOU LEAVE. |
| F_SAVE_CORRUPT | 57 | OLD SAVE COULD NOT BE READ. A FRESH TROOP HAS BEEN HIRED. |
| F_UPGRADE_FLAVOR | — | {UPGRADE NAME}: {FLAVOR} |

**Localization note (deferred; the MVP is English only).** Every string lives in `ui-strings.json` keyed by ID, and each region's budget is in §1. A future locale must meet those per-region max chars, or the region gets a documented fallback (for example `HUD_BPS_FRENZY` → `/S`). A German-length pass (+30%) would overflow the row names (22 → about 29). The plan for that is the ×2 fallback for row names only, pending a legibility review. RTL is out of scope.
