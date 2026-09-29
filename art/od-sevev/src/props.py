"""Hand-drawn props that stay graphic-tier: the DOHA Suitcase (24x18, rim -> 26x20) and the Dubi
placeholder slots (Dubi himself is a ChatGPT-queue request: asset-requests/REQUESTS.md 'dubi').

Why the Suitcase is hand-drawn, not rendered down: its whole read is a 4-letter sticker. At 24 px
wide a render-down of a painted reference turns 'DOHA' into 4 smudges; a 3x5 micro-font keeps it
crisp. Its other anchors (maroon, straps, handle, corner guards) are flat shapes that pixel
authoring does better than a downscale.
"""
from pix import Layer
from kit import save, outline_inplace, micro, with_rim, grid_layer

G = "props"


def suitcase():
    W, H = 24, 18
    L = Layer(W, H)
    # handle (behind the body top)
    L.rect(9, 0, 6, 1, "grey"); L.vline(8, 1, 3, "grey"); L.vline(15, 1, 3, "grey")
    L.set(9, 0, "silver"); L.set(10, 0, "silver")
    # body
    L.rect(0, 3, W, H - 3, "maroon")
    L.hline(1, W - 2, 4, "pink_sh")                                     # top light edge
    L.vline(1, 4, H - 3, "pink_sh")
    L.rect(W - 4, 4, 3, H - 6, "maroon_dk")                             # shadow side
    L.rect(1, H - 3, W - 2, 2, "maroon_dk")
    # straps with buckles
    for sx in (5, 18):
        L.vline(sx, 3, H - 2, "maroon_dk")
        L.vline(sx + 1, 3, H - 2, "maroon_dk")
        L.rect(sx, 5, 2, 2, "grey"); L.set(sx, 5, "silver")
    # corner guards
    for (x, y) in [(1, 4), (W - 3, 4), (1, H - 3), (W - 3, H - 3)]:
        L.rect(x, y, 2, 2, "slate")
        L.set(x, y, "grey")
    # DOHA sticker: label 17x7, text 15x5 in the micro font
    L.rect(4, 8, 17, 7, "white")
    L.hline(4, 20, 14, "paper"); L.vline(20, 8, 14, "paper")
    micro(L, "DOHA", 5, 9, "ink", gap=1)
    L.set(4, 8, "paper")                                                 # a peeling corner
    # luggage tag on the handle
    L.rect(16, 0, 3, 3, "paper"); L.set(16, 0, "white")
    L.set(15, 1, "slate")
    outline_inplace(L)
    return L


def build_suitcase():
    s = suitcase()
    save(s, "suitcase_norim", G, notes="The DOHA Suitcase without the rim (for cards/icons on light grounds).")
    r = with_rim(s)
    save(r, "suitcase", G, pivot=[r.w // 2, r.h // 2],
         notes="THE running gag: maroon (reserved: nothing else is maroon), DOHA sticker, 24x18 + 1px pale rim = 26x20. "
               "Rim = 'you can touch this' (same rim as the Magician, hat and rabbit). UX hit area 72x64 CSS = 33x30 art, centred. "
               "Crosses right-to-left; the bob and drift are the Animator's. Mirror it only if the sticker is re-drawn "
               "(never flip text).")


def dubi_placeholders():
    # 32x32 avatar slot: dashed ring + parrot silhouette + '?'
    A = Layer(32, 32)
    import math
    for a in range(0, 360, 4):
        if (a // 12) % 2 == 0:
            x = 15.5 + 15 * math.cos(math.radians(a)); y = 15.5 + 15 * math.sin(math.radians(a))
            A.set(int(round(x)), int(round(y)), "slate")
    parrot = [
        "....kkkkk.....",
        "...kssssskk...",
        "..kssssssssk..",
        "..kssksssssskk",
        "..ksssssssskkk",
        "..kssssssssk..",
        "...kssssssk...",
        "...ksssssk....",
        "..kssssssk....",
        "..ksssssssk...",
        ".kssssssssk...",
        ".kssssssssk...",
        ".kssssssssk...",
        "..kssssssk....",
        "...kkkkkk.....",
    ]
    P = grid_layer(parrot, {"k": "outline", "s": "slate"})
    A.paste(P, 9, 8)
    micro(A, "?", 22, 6, "grey")
    save(A, "dubi_placeholder_avatar", G, notes="PLACEHOLDER until the ChatGPT 'dubi' request lands: 32x32, same slot as the "
         "cast avatars (showcase/out/*_avatar.png). Grey on purpose: it must never ship looking finished.")
    B = Layer(64, 100)
    for x in range(64):
        if (x // 3) % 2 == 0:
            B.set(x, 0, "slate"); B.set(x, 99, "slate")
    for y in range(100):
        if (y // 3) % 2 == 0:
            B.set(0, y, "slate"); B.set(63, y, "slate")
    big = Layer(P.w * 3, P.h * 3)                     # a slot marker, not art: scaled silhouette is fine here
    for y in range(big.h):
        for x in range(big.w):
            big.px[y][x] = P.px[y // 3][x // 3]
    B.paste(big, (64 - big.w) // 2, 100 - big.h - 6)
    micro(B, "?", 44, 30, "grey")
    save(B, "dubi_placeholder_body", G, pivot=[32, 96],
         notes="PLACEHOLDER full-body slot, 64x100 with the pivot at the feet line (96 art px tall, like the cast). "
               "Replace with the rendered-down ChatGPT Dubi (REQUESTS.md 'dubi'). Dashed border = not final.")


def build():
    build_suitcase(); dubi_placeholders()


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
