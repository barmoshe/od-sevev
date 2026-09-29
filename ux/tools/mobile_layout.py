#!/usr/bin/env python3
"""Mobile-first layout calculator (ux/mobile-first-layout.md): the per-device numbers of §2-§4.

    python3 ux/tools/mobile_layout.py            # markdown tables for the spec
    python3 ux/tools/mobile_layout.py --json     # the same numbers as JSON (tools/web/mobile_web.mjs
                                                 # re-implements the same rule in JS; keep them equal)

Everything is in logical px (1 art px = 4 logical) unless a column says CSS. The rules are the
spec's; this file is the reference implementation the Game Developer can test against.
"""
import json
import math
import sys

ART_W = 180
MIN_ART_H = 267
# rtl-map §1 fixed rows (unchanged by this spec)
ROW_A, ROW_B, TICKER, TABS = 96, 84, 84, 104
FIXED = ROW_A + ROW_B + TICKER + TABS           # 368
CARD, PEEK = 120, 40
S_PREF, S_FULL, S_MIN = 640, 560, 460
BASE_W = 720


def floor4(v):
    return int(math.floor(v / 4.0)) * 4


def ceil4(v):
    return int(math.ceil(v / 4.0)) * 4


def crisp_k(k):
    if k <= 1:
        return max(0, k)
    while k % 2 and k % 3:
        k -= 1
    return k


# name, CSS w, CSS h, DPR, safe top / bottom (CSS), kind
DEVICES = [
    ("SE 375×667@2", 375, 667, 2, 0, 0, "phone"),
    ("390×844@3", 390, 844, 3, 0, 0, "phone"),
    ("393×852@3", 393, 852, 3, 0, 0, "phone"),
    ("430×932@3", 430, 932, 3, 0, 0, "phone"),
    ("360×780@3", 360, 780, 3, 0, 0, "phone"),
    ("412×915@2.625", 412, 915, 2.625, 0, 0, "phone"),
    ("frame 390×844@1", 390, 844, 1, 0, 0, "frame"),
    ("frame 390×844@2", 390, 844, 2, 0, 0, "frame"),
    # the same phones as a browser shows them (toolbars) or as a home-screen app (insets)
    ("390×664@3 Safari bars", 390, 664, 3, 0, 0, "phone"),
    ("SE 375×548@2 Safari bars", 375, 548, 2, 0, 0, "phone"),
    ("360×640@3 Chrome bars", 360, 640, 3, 0, 0, "phone"),
    ("393×852@3 home screen", 393, 852, 3, 59, 34, "phone"),
]


def device_px(css_w, css_h, dpr):
    # shell.html odFit: floor(inner × DPR) on a phone; the frame rounds the width
    return math.floor(css_w * dpr + 1e-9), math.floor(css_h * dpr + 1e-9)


def split(R, top=0, vh=None):
    """§3.2: the pane gets whole cards plus a 40-px peek; the stage gets the rest."""
    if R - (3 * CARD + PEEK) >= S_MIN:
        n = max(3, (R - S_PREF - PEEK) // CARD)   # extra height beyond S_PREF buys whole cards
    else:
        n = 2
    # reach guard (§6): the leader's hit bottom (stage bottom − 140) stays ≥ 40% of the height
    while vh and n > 3 and top + ROW_A + ROW_B + (R - n * CARD - PEEK) - 140 < 0.40 * vh:
        n -= 1
    P = n * CARD + PEEK
    S = R - P
    if S < S_MIN:
        S = S_MIN
        P = R - S
    return S, P, n


def picker(H, cw, k, variant):
    """§5.8: LEADER_PICK, 3 × 3 at n = 8, fluid tiles, bottom-anchored grid."""
    wm = 116 if H >= 1280 else 64
    header = (12 + wm + 12 + 44 + 12) if variant == "first" else (12 + 44 + 8 + 56 + 12)
    strip = 112
    foot = 16 if variant == "first" else 116
    avail = H - header - strip - foot
    tw = floor4((cw - 32 - 40) / 3)
    sizes = ([192] if k % 2 == 0 else []) + [128, 96, 64]
    A = 64
    for a in sizes:
        if a + 24 <= tw and 3 * (156 + a) + 24 <= avail:
            A = a
            break
    th = max(156 + A, min(floor4((avail - 24) / 3), floor4(1.6 * tw)))
    gh = 3 * th + 24
    spare = avail - gh
    return {"header": header, "avail": avail, "tw": tw, "A": A, "th": th, "grid": gh, "spare": spare}


def layout(d):
    name, w, h, dpr, it, ib, kind = d
    W, Hd = device_px(w, h, dpr)
    fit = min(W // ART_W, Hd // MIN_ART_H)
    k = crisp_k(fit)
    f = k / 4.0
    vsx, vsy = W / f, Hd / f
    cw = floor4(vsx)
    delta = cw - BASE_W
    a_css = k / dpr                      # CSS px per art px
    lpc = 4 / a_css                      # logical px per CSS px
    ins_t = ceil4(it * lpc)
    ins_b = ceil4(ib * lpc)
    R = floor4(vsy) - ins_t - ins_b - FIXED
    S, P, n = split(R, ins_t, floor4(vsy))
    top = ins_t
    stage_top = top + ROW_A + ROW_B
    lower = stage_top + S
    tabs_y = lower + TICKER + P
    leader_scale = 4 if S >= S_FULL else 3
    if leader_scale == 4:
        hit = (stage_top + S - 556, stage_top + S - 140)
    else:
        hit = (stage_top + S - 452, stage_top + S - 140)
    css = lambda y: y / lpc
    H = floor4(vsy) - ins_t - ins_b
    clip = 324 + delta
    return {
        "name": name, "css": [w, h], "dpr": dpr, "device": [W, Hd], "k": k, "f": f, "artCss": round(a_css, 3),
        "logical": [round(vsx, 2), round(vsy, 2)], "cw": cw, "delta": delta, "cols": W // k, "rows": Hd // k,
        "insets": [ins_t, ins_b], "R": R, "S": S, "P": P, "rowsWhole": n, "peek": P - n * CARD,
        "stageTop": stage_top, "lowerY": lower, "tabsY": tabs_y, "leaderScale": leader_scale,
        "hit": hit, "hitCenterCss": round(css((hit[0] + hit[1]) / 2), 1), "hitCenterPct": round(100 * (hit[0] + hit[1]) / 2 / vsy), "hitBottomCss": round(css(hit[1])), "hitBottomPct": round(100 * hit[1] / vsy),
        "listCss": [round(css(lower + TICKER)), round(css(tabs_y))], "tabsCss": round(css(tabs_y)),
        "pane_before_c1": P + TABS, "rows_before_c1": (P + TABS) // CARD,
        "tallTab": S + TICKER + P, "chatThread": S + TICKER + P - 248,
        "clip": clip, "floor88Css": round(88 / lpc, 1),
        "pickFirst": picker(H, cw, k, "first"), "pickAfter": picker(H, cw, k, "after"),
        "modalW": 624 + min(max(delta, 0), 64),
        "sheet": floor4(vsy) - ins_t,
        "sharePreview": share_a(cw, floor4(vsy) - ins_t, f),
    }


def share_a(cw, sheet_h, f):
    # §5.12: the largest a (logical px per card art px) with a·f whole, 216·a ≤ cw − 32, 270·a ≤ sheet − 520
    best = 0
    for m in range(1, 40):
        a = m / f
        if 216 * a <= cw - 32 and 270 * a <= sheet_h - 520:
            best = a
    return round(best, 3)


def main():
    rows = [layout(d) for d in DEVICES]
    if "--json" in sys.argv:
        print(json.dumps(rows, ensure_ascii=False, indent=1))
        return
    print("| Device | device px | k | CSS/art | logical | cw (Δ) | R | **S** | **P** | whole rows + peek | leader | stage top / lowerY / tabsY | leader hit centre · bottom, CSS y (% of H) | list CSS y | 88 logical = CSS |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for r in rows:
        print(f"| {r['name']} | {r['device'][0]}×{r['device'][1]} | {r['k']} | {r['artCss']} | {r['logical'][0]:g}×{r['logical'][1]:g} | {r['cw']} ({r['delta']:+d}) | {r['R']} | **{r['S']}** | **{r['P']}** | {r['rowsWhole']} + {r['peek']} | ×{r['leaderScale']} | {r['stageTop']} / {r['lowerY']} / {r['tabsY']} | {r['hitCenterCss']:g} ({r['hitCenterPct']}%) · {r['hitBottomCss']} ({r['hitBottomPct']}%) | {r['listCss'][0]}-{r['listCss'][1]} | {r['floor88Css']} |")
    print()
    print("| Device | pane before C1 (rows) | tall tab H_T / chat thread | ticker clip | modal card w | sheet h | share preview a | picker first: avail / tw / A / th / spare | picker after: avail / A / th / spare |")
    print("|---|---|---|---|---|---|---|---|---|")
    for r in rows:
        pf, pa = r["pickFirst"], r["pickAfter"]
        print(f"| {r['name']} | {r['pane_before_c1']} ({r['rows_before_c1']}) | {r['tallTab']} / {r['chatThread']} | {r['clip']} | {r['modalW']} | {r['sheet']} | {r['sharePreview']:g} | {pf['avail']} / {pf['tw']} / {pf['A']} / {pf['th']} / {pf['spare']} | {pa['avail']} / {pa['A']} / {pa['th']} / {pa['spare']} |")


if __name__ == "__main__":
    main()
