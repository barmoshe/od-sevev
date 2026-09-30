"""Wave 8 (palette v4, 2026-09-29, Bar: "more Israel theme and palette"): Israeli election material culture.

  hemicycle_track   72x38   the 120-seat Knesset hemicycle on a white plate: 120 empty seats, the majority line
  hemicycle_fill    72x38   the same seats filled (flag blue, lit top-left), transparent elsewhere
                            + `seats`: the 120 seat rects in FILL ORDER (RTL: from the right end of the arc,
                            sweeping left by angle), `goal` 61
  booth_frame       40x40   the cardboard voting booth (קלפי) as a 9-slice frame for the picker grid
  envelope_blue     14x10   the blue ballot envelope (המעטפה הכחולה), a prop for confetti and the share card

A new widget, not a restyle: the horizontal seats bar stays (seats_track / seats_fill). UX and the engine decide
whether the hemicycle replaces it (Row B, the ≥ 61 moment, the result card). Nothing here is lettered: no party
ballot letters, no emblem, no Knesset menorah.
"""
import math

from pix import Layer
from kit import save, outline_inplace, panel

HW, HH = 72, 38
CX, CY = 35.5, 36.5            # the arc's centre: the bottom middle of the plate
ROWS = (13.0, 17.0, 21.0, 25.0, 29.0, 33.0)   # seat-row radii, inner to outer


def _seats():
    """120 seat centres on six rows, each row's count proportional to its radius, sorted into fill order: by angle
    from the right end (0 deg) to the left end (180 deg), inner row first within a column (a parliament chart)."""
    total = sum(ROWS)
    counts = [round(120 * r / total) for r in ROWS]
    counts[-1] += 120 - sum(counts)
    seats = []
    for r, n in zip(ROWS, counts):
        for i in range(n):
            a = math.pi * (i + 0.5) / n                       # 0 = right end, pi = left end
            x = CX + r * math.cos(a)
            y = CY - r * math.sin(a)
            seats.append((a, r, int(round(x - 0.5)), int(round(y - 0.5))))
    seats.sort(key=lambda s: (round(s[0], 2), s[1]))
    return [(x, y) for _, _, x, y in seats]


SEATS = _seats()
assert len(SEATS) == 120 and len(set(SEATS)) == 120


def hemicycle():
    T = Layer(HW, HH)
    for y in range(HH):                                       # the white plate: a half-disc with a flat base
        for x in range(HW):
            if math.hypot(x + 0.5 - CX, y + 0.5 - CY) <= 35.5 and y <= HH - 1:
                T.set(x, y, "white")
    for y in range(HH):                                       # a paper shade on the right / bottom band
        for x in range(HW):
            d = math.hypot(x + 0.5 - CX, y + 0.5 - CY)
            if T.get(x, y) == "white" and 34.0 < d <= 35.5 and (x > CX or y > HH - 3):
                T.set(x, y, "paper")
    # the majority line: seat 61 is the first past the middle; a gold-rimmed tick on the plate's top centre
    for y in range(1, 5):
        T.set(35, y, "gold_sh"); T.set(36, y, "gold_sh")
    for (x, y) in SEATS:
        T.rect(x, y, 2, 2, "silver")
        T.set(x + 1, y + 1, "grey")                           # an empty seat: pale, a shaded corner
    outline_inplace(T)
    F = Layer(HW, HH)
    for (x, y) in SEATS:
        F.rect(x, y, 2, 2, "flag")
        F.set(x, y, "flag_hi")                                # a taken seat: flag blue, lit top-left
    rects = [[x, y, 2, 2] for (x, y) in SEATS]
    note = ("The 120-seat Knesset hemicycle (v4, Israeli election material culture), 72x38 at d 1, x4 = 288x152 "
            "logical. A white plate (the flag's field), 120 seats on six rows, the majority tick at the top centre "
            "(gold_sh on white). `seats` lists each seat's [x, y, w, h] in FILL ORDER: seat 1 is the right end of the "
            "arc (RTL), sweeping left by angle; the coalition's n seats = draw hemicycle_fill's rects seats[0:n] "
            "(region-per-seat, or AtlasTexture), `goal` = 61. Filled flag on white 8.5:1, empty silver vs filled flag "
            "4.4:1 and a different shape (lit corner vs shaded corner). Seats are never gold (money) or red (danger). "
            "No party colours: the fill is the coalition's, whoever leads it.")
    save(T, "hemicycle_track", "meters", notes=note, extra={"seats": rects, "goal": 61})
    save(F, "hemicycle_fill", "meters", notes="The taken seats for hemicycle_track (same size, same `seats`): draw "
         "seats[0:n] of this image over the track.", extra={"seats": rects, "goal": 61})


BOOTH = {"light": "stone", "face": "blonde_sh", "shade": "stone_sh", "crease": "wood", "band": "flag"}


def booth_art(W, H, band, top):
    """The cardboard voting booth (קלפי) as a 9-slice, read as a tabletop folding screen: a back panel with a blank
    flag-blue printed band across its top, two side wings folded toward the viewer (2 rows lower than the back panel,
    unprinted; the left one in the key light, the right one in shade, a crease where each folds), the back panel's
    face IN shadow behind the grid, and the shelf at the bottom. Kraft cardboard (2026-09-30, manual test B13: the
    v4 off-white frame with a transparent opening read as a thin brown line at x4: the gaps between the tiles showed
    the stage). band = the printed band's rows (a range), top = the back panel's first row. Every stretched row and
    column is flat, so the 9-slice never smears."""
    c = BOOTH
    L = Layer(W, H)
    L.rect(0, 0, W, H, c["face"])
    L.hline(5, W - 6, 1, c["light"])                         # the back panel's top edge, catching the light
    for y in band:
        L.hline(5, W - 6, y, c["band"])                      # the printed band (blank: no text, no emblem)
    L.hline(5, W - 6, top - 1, c["shade"])                   # the band's shadow on the panel
    L.rect(5, top, W - 10, H - top - 3, c["shade"])          # the back panel's face, in the wings' shadow
    L.hline(5, W - 6, top, c["crease"])                      # ... darkest right under the header
    L.vline(5, 2, H - 4, c["crease"])                        # the left fold (the lit wing meets the panel)
    L.vline(W - 6, 2, H - 4, c["crease"])                    # the right fold
    for y in range(3, H - 3):                                # the wings: left lit, right in shade
        L.set(1, y, c["light"])
        L.set(4, y, c["shade"])
        L.hline(W - 5, W - 2, y, c["shade"])
    L.hline(1, 4, 2, c["light"])                             # the wings' top edges
    L.hline(W - 5, W - 2, 2, c["face"])
    for y in range(0, 2):                                    # the wings stand 2 rows lower than the back panel
        for x in list(range(0, 5)) + list(range(W - 5, W)):
            L.px[y][x] = None
    L.hline(1, W - 2, H - 3, c["light"])                     # the shelf: its lit edge and face
    L.hline(1, W - 2, H - 2, c["face"])
    outline_inplace(L)
    return L


def booth():
    """The cardboard voting booth (קלפי) around the picker grid. 9-slice [6, 10, 6, 4], content [5, 9, 30, 28]."""
    W, H = 40, 40
    L = booth_art(W, H, range(2, 7), 9)
    save(L, "booth_frame", "picker", slice=[6, 10, 6, 4], mode="stretch", content=[5, 9, W - 10, H - 12],
         notes="The picker frame as the cardboard voting booth (קלפי): a 9-slice [6, 10, 6, 4] drawn around the tile "
               "grid, content [5, 9, 30, 28] (the tiles). Kraft cardboard (2026-09-30, manual test B13: the off-white "
               "frame with a transparent opening read as a thin brown line), a tabletop folding screen: the back panel "
               "with a lit top edge and a blank flag-blue printed band (rows 2-6, cols 5-34), the two side wings "
               "folded forward, 2 rows lower and unprinted (left lit, right in shade, a crease at each fold), the back "
               "panel in shadow INSIDE the frame (opaque: the gaps between the tiles are cardboard, so the grid stands "
               "in the booth), the shelf at the bottom. Tiles on the back panel: their outline 7.5:1, their ui_bubble face "
               "3.1:1. No text, no emblem, no letters, no party colour: the booth, not the committee.")
    return L


def envelope():
    """The blue ballot envelope (המעטפה הכחולה), 14x10: flag blue, the flap's V in flag_hi, blank."""
    W, H = 14, 10
    L = Layer(W, H)
    L.rect(0, 0, W, H, "flag")
    for x in range(W):
        y = int(round(4 - abs(x - (W - 1) / 2) * 4 / ((W - 1) / 2)))
        if 0 <= y < H:
            L.set(x, y + 1, "flag_hi")
    L.hline(1, W - 2, H - 2, "flag_dk")
    outline_inplace(L)
    save(L, "envelope_blue", "props", notes="The blue ballot envelope (המעטפה הכחולה, v4): 14x10, blank (no text, no "
         "emblem). Confetti with the white slips (OG, the ceremony), the share card's corner.")


def build():
    hemicycle()
    booth()
    envelope()
