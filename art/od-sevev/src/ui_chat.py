"""Coalition chat kit: bubbles (incoming / outgoing / ultimatum / system), header bar, pinned bar,
composer, small pixel icons (lock, chevron, pin, clock, mute), and the gold pay pill "סגרנו".

UX sources: creative-pack ux/first-minute.md section 4 (square-cornered pixel panels, incoming
#2E2250 right-aligned, player's #4A3A10 left-aligned, no WhatsApp green, no ticks) and 4.2
(pay pill 170x36 CSS = 78x17 art; ultimatum = hatched border + label + timer pill).
"""
from pix import Layer
from kit import save, panel, capsule, hatch, grid_layer, outline_inplace, chamfer

G = "chat"


# ------------------------------------------------------------------ bubbles
def _bubble(w, h, face, hi, lo, tail="right", tail_n=4):
    """Square-cornered bubble with a tail at the top corner on the sender's side."""
    bw = w - (tail_n - 1)
    L = Layer(w, h)
    x0 = 0 if tail == "right" else tail_n - 1
    L.rect(x0, 0, bw, h, face)
    for j in range(tail_n):                                  # tail: a right triangle, tip at the top
        n = tail_n - j
        for i in range(n):
            x = (x0 + bw - 1 + i) if tail == "right" else (x0 - i)
            L.set(x, j, face)
    # bevel on the body
    L.hline(x0 + 1, x0 + bw - 2, 1, hi)
    L.vline(x0 + 1, 1, h - 2, hi)
    L.hline(x0 + 1, x0 + bw - 2, h - 2, lo)
    L.vline(x0 + bw - 2, 2, h - 2, lo)
    outline_inplace(L)
    return L


def bubbles():
    W, H, T = 26, 16, 6
    inc = _bubble(W, H, "ui_bubble", "ui_bub_hi", "ui_panel", "right", T)
    save(inc, "chat_bubble_in", G, slice=[3, T, T + 2, 3], content=[4, 3, W - (T - 1) - 8, H - 6],
         label="white", notes="Incoming partner bubble, right-aligned; tail at top-right points at the avatar. "
         "Name line sits ABOVE the bubble (engine text, grey). white on ui_bubble 13.1:1.")
    out = _bubble(W, H, "ui_out", "ui_out_hi", "hair_dk", "left", T)
    save(out, "chat_bubble_out", G, slice=[T + 2, T, 3, 3], content=[T + 3, 3, W - (T - 1) - 8, H - 6],
         label="white", notes="The player's auto-reply, left-aligned, dark gold (UX). white on ui_out 10.0:1.")

    # ultimatum: incoming bubble with a 2px red/black hatched border band (shape channel)
    W2, H2 = 33, 24
    u = _bubble(W2, H2, "ui_bubble", "ui_bub_hi", "ui_panel", "right", T)
    bw = W2 - (T - 1)

    def in_band(x, y):
        if u.get(x, y) in (None, "outline"):
            return False
        inner = (4 <= x <= bw - 5) and (4 <= y <= H2 - 5)
        return not inner or x >= bw        # the tail is solid hazard too
    hatch(u, 0, 0, W2, H2, "red", "outline", period=4, on=2, mask=in_band)
    # re-bevel the inside of the band so the face still reads as a raised bubble
    u.hline(4, bw - 5, 4, "ui_bub_hi"); u.vline(4, 4, H2 - 5, "ui_bub_hi")
    u.hline(4, bw - 5, H2 - 5, "ui_panel"); u.vline(bw - 5, 5, H2 - 5, "ui_panel")
    save(u, "chat_bubble_ultimatum", G, slice=[8, 8, 8 + T - 1, 8], mode="tile",
         content=[6, 6, W2 - 6 - (T + 5), H2 - 12], label="white",
         notes="Ultimatum = hatched hazard border (shape) + 'אולטימטום' label (text) + timer chip (text) + red (4th channel). "
         "TILE_FIT on both axes: the hatch period is 4, keep the stretched centre a multiple of 4 or let TILE_FIT round it. "
         "No flashing: the band is static (UX: nothing above 3 Hz).")

    # system pill: neutral capsule, centred, no avatar
    s = capsule(20, 13, "suit_dk", "suit", "night", r=2)
    save(s, "chat_system_pill", G, slice=[4, 3, 4, 3], content=[3, 2, 14, 9], label="white",
         notes="System lines, day divider 'היום', unread divider, 'ההודעה נמחקה'. white on suit_dk 11.8:1. "
         "Text cell is 9 rows (5x9 cut): exactly the content height.")
    # the variant with a button inside ("להחזיר לקבוצה", "צאו החוצה") uses chat_system_pill + a
    # controls/button_secondary; no special art.


# ------------------------------------------------------------------ bars
def bars():
    # header: 56 CSS = 26 art. Title + lock + status line are engine text; chevron sits right.
    Hh = 26
    h = Layer(180, Hh)
    h.rect(0, 0, 180, Hh, "ui_panel")
    h.hline(0, 179, 0, "ui_bub_hi")
    h.hline(0, 179, Hh - 3, "flag")                 # v3: a flag-blue and a white stripe under the header (the national
    h.hline(0, 179, Hh - 2, "white")                # frame; the header body stays navy so the grey status line keeps 7:1)
    h.hline(0, 179, Hh - 1, "outline")
    save(h, "chat_header", G, slice=[2, 2, 2, 3], content=[4, 3, 172, 20], label="white",
         notes="Full-width tall-tab header (UX 4.1). Right 22 px: collapse chevron (chat_icon_chevron) centred in a "
         "20x26 hit column (hit area 44 CSS = 20 art). Title line y=4, status line y=14 (both 9-row cells). v3: flag + white stripes in the bottom slice (rows 23-24).")
    # pinned bar: 30 CSS = 14 art
    p = Layer(180, 14)
    p.rect(0, 0, 180, 14, "ui_scrim")
    p.hline(0, 179, 13, "outline")
    p.vline(178, 1, 12, "stamp")                     # a violet 'pinned' edge on the right (RTL start)
    p.vline(179, 1, 12, "stamp")
    save(p, "chat_pinned", G, slice=[2, 2, 3, 2], content=[3, 2, 172, 10], label="grey",
         notes="'נעוץ: ההסכם הקואליציוני · טיוטה {n}'. Pin icon right, text right-aligned after it. grey on ui_scrim 8.5:1.")
    # composer (disabled): 44 CSS ~ 20 art + 2
    c = Layer(180, 22)
    c.rect(0, 0, 180, 22, "ui_panel")
    c.hline(0, 179, 0, "outline")
    c.hline(0, 179, 1, "ui_bub_hi")
    well = Layer(168, 14)
    well.rect(0, 0, 168, 14, "ui_scrim")
    well.hline(1, 166, 1, "outline")              # inner shadow = sunken = not typeable
    chamfer(well, 0, 0, 168, 14, 2)
    outline_inplace(well)
    c.paste(well, 6, 4)
    save(c, "chat_composer_disabled", G, slice=[9, 6, 9, 6], content=[9, 6, 162, 10], label="slate",
         notes="Disabled composer: sunken well, no send button. Placeholder 'פה מדברים רק בשקלים' in slate "
         "(4.2:1 on ui_scrim: it is deliberately a disabled-hint colour, still >= 3:1).")


# ------------------------------------------------------------------ icons (9 rows tall = one text cell)
LEG = {"k": "outline", "s": "silver", "g": "grey", "l": "slate", "w": "white", "b": "sky", "B": "flag_hi",
       "r": "red", "R": "red_dk", "i": "ink", "v": "stamp_lt"}

ICONS = {
    "lock": [
        "..kkk..",
        ".kgkgk.",
        ".kg.gk.",
        "kkkkkkk",
        "kssssgk",
        "ksskssk",
        "ksskslk",
        "kssslgk",
        "kkkkkkk",
    ],
    "chevron": [
        "kk....",
        "ksk...",
        ".ksk..",
        "..ksk.",
        "...ksk",
        "..ksk.",
        ".ksk..",
        "ksk...",
        "kk....",
    ],
    "pin": [
        "...kkk...",
        "..kvvvk..",
        "..kvwvk..",
        "..kvvvk..",
        ".kkvvvkk.",
        ".kvvvvvk.",
        "..kkgkk..",
        "....g....",
        "....g....",
    ],
    "mute": [
        "...k.....",
        "..kk.....",
        "kkgk.k..k",
        "kggk..kk.",
        "kggk..kk.",
        "kkgk.k..k",
        "..kk.....",
        "...k.....",
        ".........",
    ],
}

CLOCK = [
    "..kkkkk..",
    ".kwwwwwk.",
    "kwwwwwwwk",
    "kwwwwwwwk",
    "kwwwiwwwk",
    "kwwwwwwwk",
    "kwwwwwwwk",
    ".kwwwwwk.",
    "..kkkkk..",
]
HANDS = {12: [(4, 3), (4, 2)], 3: [(5, 4), (6, 4)], 6: [(4, 5), (4, 6)], 9: [(3, 4), (2, 4)]}


def icons():
    for name, rows in ICONS.items():
        L = grid_layer(rows, LEG)
        save(L, "chat_icon_" + name, G, notes={
            "lock": "Title lock (UX: 🔒 is a pixel icon, never emoji).",
            "chevron": "Collapse chevron › at the header's right edge (RTL start).",
            "pin": "Pinned-bar pin (📌 as pixel icon). Head in stamp_lt: the 'official' violet.",
            "mute": "Muted advisers system line (Distel). The crossed wave carries it, not colour.",
        }[name])
    frames = []
    for pos in (12, 3, 6, 9):
        L = grid_layer(CLOCK, LEG)
        L.set(4, 3, "ink"); L.set(4, 2, "ink")        # the long hand always points to 12 (reads 'clock' at 9px)
        L.set(5, 4, "ink")                            # short hand at 3: an 'L' is the universal clock read
        for (x, y) in HANDS[pos]:
            L.set(x, y, "red")                        # the sweep hand steps 12/3/6/9
        frames.append(L)
    from kit import strip
    save(strip(frames), "icon_clock", G, frames=4, frame_w=9,
         notes="Timer clock (⏱ as pixel icon) for the ultimatum chip and the court chip. 4 static hand states "
         "(the red sweep hand at 12/3/6/9); the Animator owns whether/when it steps. Reduced motion: frame 0.")


# ------------------------------------------------------------------ pay pill "סגרנו"
def pay_pill():
    W, H = 24, 17
    d = capsule(W, H, "gold", "gold_hi", "gold_sh", lip=2, lip_c="gold_dk", r=2)
    save(d, "pay_pill_default", G, state="afford", slice=[3, 3, 3, 5], content=[4, 2, W - 8, 11], label="ink",
         notes="'סגרנו · {price} ₪' — affordable. Raised gold (gold = money). ink on gold 11.0:1. "
         "Visual 78x17 art (UX 170x36 CSS); hit 84x22 art (182x48 CSS).")
    p = Layer(W, H)
    face = capsule(W, H - 2, "gold_sh", "gold_dk", "gold_sh", r=2)
    p.paste(face, 0, 2)
    save(p, "pay_pill_pressed", G, state="pressed", slice=[3, 5, 3, 3], content=[4, 4, W - 8, 11], label="ink",
         notes="Pressed: the face drops 2 art px (label y +2), no lip, inner shadow on top. ink on gold_sh 5.8:1.")
    t = Layer(W, H)
    well = capsule(W, H - 2, "ui_scrim", "outline", "ui_panel", r=2)
    t.paste(well, 0, 2)
    save(t, "pay_pill_track", G, state="cant_afford", slice=[3, 5, 3, 3], content=[4, 4, W - 8, 11], label="white",
         notes="Can't afford yet: a SUNKEN well (shape), label 'חסר {n} ₪' in white. The fill below grows from the RIGHT "
         "(RTL, UX 3.5) inside content x 2..W-3, y 4..H-3. white on ui_scrim 17.3:1, on the fill 6.4:1.")
    f = Layer(6, 11)
    f.rect(0, 0, 6, 11, "gold_dk")
    f.hline(0, 5, 0, "gold_sh")
    f.vline(0, 0, 10, "gold_sh")                      # leading edge: the fill advances leftward
    save(f, "pay_pill_fill", G, slice=[1, 1, 1, 1], label="white",
         notes="Progress fill for pay_pill_track (and the source-card price pill). Anchor RIGHT; width = inner_w x progress. "
         "Deliberately DIM gold: the pill only turns bright gold when it is payable.")


def build():
    bubbles(); bars(); icons(); pay_pill()


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
