# Images to generate in ChatGPT (as of 2026-09-30)

Today these spots show a silhouette or a chunky 1× drawing next to the crisp cast. Each image
becomes a reference in `creative-pack/art/refs/`. The TA then adds landmarks in
`creative-pack/art/showcase/src/cast.py` and renders it down to pixel art at d3/d2 through the
pipeline (`pipeline/od-sevev/build.py`), the same way May Golan was done.

## How to generate (every image)
- **One image per chat.** Attach `refs/bibi.png` and `refs/regev.png` as the style reference
  (that's what worked for May Golan) and say: *"Same caricature style, line weight, shading and
  proportions as the attached images."*
- **Frame:** full body, standing, feet visible, facing slightly to screen-left, on a plain flat
  light background (no scenery, no shadow on the floor), portrait 1024×1536. One figure (or one
  pair where noted) centred with a margin.
- **Never:**
  - text, logos, party colours or symbols, flags, a star of David, the state emblem;
  - uniforms, weapons, vests, police or army gear;
  - anything related to October 7.
- **Fictional characters** (marked *fictional*) must not resemble any real person: ask for
  "a generic, made-up face".
- Save as the file name given, into `creative-pack/art/refs/` (candidates into `refs/candidates/`
  first if you want to choose), and tell the TA.

## Must-have: shown as a silhouette today

| # | File | Who / what | Where it shows | Prompt (English works best) |
|---|---|---|---|---|
| 1 | `almog.png` | **אלמוג כהן** (real MK; a partner in several leaders' coalitions) | Chat avatar, partner card, the stage | "Full-body caricature of Israeli politician Almog Cohen in a plain dark suit and white shirt, no tie, arms relaxed, a mild confident expression. Same caricature style as the attached images. No weapon, no vest, no uniform, no badge, no text." |
| 2 | `mk-switcher.png` | *fictional*: **ח״כ שעבר צד** | Chat and card for this generic MK | "A made-up, generic middle-aged male politician in a grey suit carrying a cardboard office box with a desk plant and a mug, glancing back over his shoulder. Generic face, not any real person." |
| 3 | `mk-undecided.png` | *fictional*: **ח״כית מתלבטת** (female) | Chat and card | "A made-up, generic female politician in her 40s in a navy blazer, holding a phone in each hand and looking from one to the other, undecided. Generic face, not any real person." |
| 4 | `mk-offer.png` | *fictional*: **ח״כ עם הצעה** | Chat and card | "A made-up, generic male politician in his 50s with a moustache and a brown suit, holding out a plain sealed envelope with a sly smile. Generic face, not any real person. The envelope is blank." |
| 5 | `mk-returner.png` | *fictional*: **ח״כ שחזר הביתה** (Liberman's extra seat) | Chat and card | "A made-up, generic older male politician in a slightly rumpled suit, pulling a small wheeled suitcase and waving hello, relieved to be back. Generic face, not any real person." |
| 6 | `aide.png` | *fictional*: **היועץ** (the aide who is dropped: "אני לא מכיר אותו") | The aide button and trophy, the court card | "A made-up, generic young male political aide in a slim dark suit with an earpiece, holding a maroon folder to his chest, looking nervous. Generic face, never a real aide." |

## Worth doing: sources that are chunky 1× next to the crisp ones
These money sources walk on the stage. The rest (taxpayer, hi-tech, VAT, cigars, Qatari aides,
advisers) are already crisp from refs; these five are still hand-drawn at 1×. Objects don't need
the cast style reference, only "the same cartoon style".

| # | File | Source | Prompt |
|---|---|---|---|
| 7 | `submarine.png` | הצוללת | "A small friendly cartoon submarine surfacing, coins spilling out of the open hatch, side view. No flags, no navy markings, no numbers, no text. Flat light background." |
| 8 | `poison.png` | מכונת הרעל | "A cartoon server rack holding rows of small smartphones, each screen showing a blank grey avatar and a tiny heart. No logos, no text. Flat light background." |
| 9 | `checkbook.png` | פנקס הצ׳קים הזהוב (Washington) | "A cartoon golden chequebook, slightly open, with a thick black marker clipped to it. No seals, no eagle, no flags, no text. Flat light background." |
| 10 | `donor.png` | the generic donor (the other leaders' rounds) | "A faceless figure in a dark suit, face in shadow, holding a plain envelope and a pen. No party colours, no logo, no text." |
| 11 | `funds.png` | the budget binder (the other leaders' rounds) | "A fat cartoon lever-arch budget binder with a blank tab, coins spilling from the top. No text." |

## Optional
| # | File | What | Why |
|---|---|---|---|
| 12 | `bibi-hat-rabbit.png` | Bibi's black top hat alone, plus a separate white rabbit peeking out of it (two poses: hat empty, rabbit half out) | The hat and rabbit are still 1× props; a ref lets the TA render them at 3× like the cast. |
| 13 | `sara.png` (v2), only if wanted | Already exists; regenerate only if Bar wants a new pose | — |

## After generating
Tell the orchestrator or TA which files landed. The TA adds each one to `cast.py` (landmarks:
neck, waist, eyes), renders d3 + d2, and swaps `avatar_nophoto` / `nophoto` in
`design/content.json` for the new ids. Check that the pipeline reports 0 drift on the approved
cast.
