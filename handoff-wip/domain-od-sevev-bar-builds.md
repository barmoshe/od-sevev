# Handoff: put the game on od-sevev.bar-builds.com (for the local agent, with Chrome)

Bar (2026-10-04): "I want the game to be in the url od-sevev.bar-builds.com", then: "let the local agent
do it all". You run on Bar's machine with Chrome. Do the whole thing: DNS, code, build, deploy, redirect.
Repo: `barmoshe/od-sevev`, branch `main` (pull first). Read `HANDOFF.md` §Deploy and `HOW-TO-RUN.md`.

## Where things stand (done from the cloud session)
- **Vercel:** `od-sevev.bar-builds.com` is already added to the project `od-sevev`
  (`prj_ZbQ1ubW0AU5hfhSVnVtcsgmm6BVA`, team `team_ok1MqoSMeupTyBE6CXAR91UT`) and shows **verified**
  (bar-builds.com is in the same Vercel team). It only needs DNS.
- **DNS for bar-builds.com is at GoDaddy** (nameservers ns75/ns76.domaincontrol.com), not at Vercel.
  `od-sevev.bar-builds.com` does not resolve yet. The apex and `www` already point at Vercel.
- **Live today:** https://od-sevev.vercel.app (build `4b0cdee`, save epoch 6).
- **No code is changed yet.** The address is one constant: `ShareKit.SITE_URL` in
  `game/scripts/ui/share_kit.gd`.

## 1. DNS in GoDaddy (Chrome, Bar's logged-in session)
1. GoDaddy → My Products → `bar-builds.com` → DNS → Add New Record.
2. **Type `CNAME`, Name `od-sevev`, Value `cname.vercel-dns.com`, TTL default.** Save.
   If the Vercel dashboard (project od-sevev → Settings → Domains → od-sevev.bar-builds.com) shows a
   different, project-specific CNAME value, use that one instead.
3. Do not edit or delete any other record (the apex A record, `www`, mail records).
4. Check: `https://dns.google/resolve?name=od-sevev.bar-builds.com&type=CNAME` returns the CNAME
   (allow a few minutes), and the Vercel Domains page shows "Valid Configuration".

## 2. Code (od-sevev, on `main`)
- `game/scripts/ui/share_kit.gd`: `const SITE_URL := "https://od-sevev.bar-builds.com/"`, and update the
  `display_host` comment (now 23 glyphs).
- `ux/tools/gen_strings.py`: the sample `"url": "od-sevev.bar-builds.com"`; then run
  `python3 ux/tools/gen_strings.py` (it rewrites `ux/string-budgets.json`) and `tools/lint_text.sh`.
  The cloud session ran this once: **0 errors, 0 warnings** with the new host, so the share-card footer
  fits; re-check anyway.
- Docs naming the live host: `HOW-TO-RUN.md` (OD_SITE_URL default), `HANDOFF.md` deploy section,
  `design/playtest-kit.md`, the defaults in `tools/web/share_web.mjs` and `tools/webtest.sh`.
  Tests that pass a vercel.app URL as a literal input can stay (they test link building).
- `tools/test.sh` must stay 612/612; `node design/sim/content-lint.mjs` 0.

## 3. Build and deploy
- `tools/build_web.sh` (strict). Check `build/web/index.html` has `og:url` = `https://od-sevev.bar-builds.com/`.
- Deploy as usual (`HANDOFF.md` §Deploy: `build/web/*` + `tools/web/vercel.json` + `.vercelignore` onto
  the `web-dist` branch, then the Vercel connector's `create_deployment` with `gitSource` ref `web-dist`;
  or on the Mac `OD_VERCEL_PROJECT=od-sevev tools/deploy_web.sh`).
- Open https://od-sevev.bar-builds.com in Chrome: the game loads, `window.mbBuild` is the new sha,
  no console errors, sound works after the first tap.

## 4. Redirect the old address (Bar's choice: redirect, not both)
Only after step 1 shows Valid Configuration and step 3 is live on the new host:
- Vercel → project od-sevev → Settings → Domains → `od-sevev.vercel.app` → Edit → Redirect to
  `od-sevev.bar-builds.com`, **308 Permanent**.
- Check: `https://od-sevev.vercel.app/s/bibi-leak/` lands on `https://od-sevev.bar-builds.com/s/bibi-leak/`
  (the path is kept, so share links already sent on WhatsApp still work).
- Note for Bar: browser saves are per address, so players start fresh on the new host (same as the
  wipe just deployed).

## 5. Search engines (Bar's Chrome)
- Google Search Console: add a URL-prefix property `https://od-sevev.bar-builds.com/`, verify with the
  HTML file method (the existing `google934215264611e5f3.html` is already served by every build), submit
  `https://od-sevev.bar-builds.com/sitemap.xml`. Bing Webmaster Tools can import it from Search Console.

## When done
Append one line to `STATUS.md` (date · agent · what · sha · deployment id), commit, push `main`, and tell
Bar the live URL.
