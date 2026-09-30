"""Mordechai David, the protest blocker (Bar, session 5, 2026-09-30): the render-down rig.

refs/mordechai-david.png (1024x1536, Bar's ChatGPT ref, transparent): an orange cap, an orange tee, dark jeans, black
sneakers and a short beard, three-quarter view facing screen-RIGHT. The orange is his real-life signature and stays
(it is also clear of the v4 blue chrome). Every pose is cut and posed at ref resolution, then downscaled to 96·d px with
one palette locked from the rest pose (idle frame 0), exactly like the rest of the cast (rig.py).

Parts (ref px). The arms are cut WITH their sleeves and rotate about the shoulder; the legs are cut below the hem and
rotate about the hip. Positive degrees are PIL's counter-clockwise: a hanging limb swings its far end to the RIGHT
(forward, the way he faces).
  near arm   screen-left  (his right arm, turned toward us)   pivot (300, 520)
  far arm    screen-right (his left arm)                        pivot (722, 512)
  near leg   screen-left                                        pivot (405, 1012)
  far leg    screen-right                                       pivot (598, 1012)

Anims (all at 96·d; frame data in atlas.json; he faces right, flip for left):
  idle      20 @ 10 loop   breathing (head lags the chest a frame), a blink on 9-11
  walk       8 @ 10 loop   legs ±11°, counter arm swing, the passing frames 1 ap up; every frame grounded
  block_in   4 @ 12 once   feet step wide, arms rise to the spread; play it backwards to stand down
  block      3 @  6 loop   the hold: the outer arm up 42°, the leader-side arm out 12° (clear of the leader's slot),
                           feet planted, a 1-ap breath and a 2-3° arm give
  glance     10 @ 10 once  the smug look at the player: head 1 ap toward us, chin up, irises to camera, lids half down
"""
import math
import numpy as np
from PIL import Image, ImageDraw
from rig import Rig

NAME = 'mordechai-david'
NECK, WAIST = 398, 900
EYES = [(542, 219, 22, 8), (618, 206, 13, 9)]            # (cx, cy, rx, ry) for the blink
SKIN = (238, 150, 104, 255)                               # the lid (sampled under the eyes)
LINE = (20, 10, 8, 255)                                   # the ref's outline
SCLERA = (184, 176, 177, 255)
# the irises move to camera for the glance: (box x0, y0, x1, y1, dx) per eye, ref px
IRIS = [((520, 208, 567, 230), -11), ((602, 196, 634, 217), -7)]

ARM_N = ([(305, 452), (292, 482), (318, 560), (338, 640), (352, 690), (352, 800), (334, 900), (306, 960),
          (300, 1090), (180, 1090), (182, 900), (206, 690), (214, 560), (236, 470)], (300, 520))
ARM_F = ([(690, 440), (760, 462), (806, 540), (842, 640), (842, 700), (850, 820), (832, 950), (834, 1092),
          (686, 1092), (694, 950), (702, 700), (688, 640), (678, 560), (676, 470)], (722, 512))
LEG_N = ([(292, 1000), (506, 1000), (506, 1062), (484, 1150), (500, 1398), (516, 1528), (240, 1528), (272, 1398),
          (296, 1150)], (405, 1012))
LEG_F = ([(506, 1000), (706, 1000), (704, 1100), (742, 1250), (766, 1380), (806, 1530), (620, 1530), (636, 1400),
          (588, 1250), (522, 1100), (506, 1062)], (598, 1012))
# the hands overlap the jeans' edge: inside these boxes every skin px (r > 150, r - b > 40) belongs to the arm
HANDS = {'an': (176, 930, 334, 1096), 'af': (664, 930, 852, 1096)}
# the shoulder caps stay on the torso too (the arm turns in its joint; the shoulder does not), so a sleeve swinging
# out never opens a gap between the neckline and the sleeve
CAPS = [[(236, 470), (305, 452), (322, 575), (212, 575)], [(676, 470), (690, 440), (760, 462), (800, 540), (684, 575)]]
HULL = [(300, 470), (322, 575), (345, 690), (352, 800), (338, 905), (694, 905), (700, 700), (684, 575), (690, 470)]
FLANKS = [[(322, 575), (345, 690), (352, 800), (338, 905)], [(684, 575), (700, 700), (694, 905)]]
SHIRT_SH = (232, 55, 3, 255)                              # the tee's fold shade (the ref at 650, 600)
PELVIS = (280, 960, 720, 1075)                            # holes a swinging leg opens here refill from the legs at rest
HEAD_BOX = (330, 20, 720, 410)                            # the avatar crop


def _low(img):
    """The lowest row with an opaque px (alpha > 128, the rig's threshold)."""
    rows = np.nonzero((np.asarray(img.getchannel('A')) > 128).any(axis=1))[0]
    return int(rows[-1])


def _main_part(img, seed):
    """Keep only the 4-connected opaque region holding `seed` (canvas px): the ref's outline strokes that a cut polygon
    leaves on the wrong side (a sliver of a sleeve's edge beside the hip) would otherwise float as dashes."""
    m = img.getchannel('A').point(lambda v: 255 if v > 128 else 0)
    ImageDraw.floodfill(m, seed, 128)
    keep = m.point(lambda v: 255 if v == 128 else 0)
    out = Image.new('RGBA', img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), keep)
    return out


SEEDS = {'an': (260, 800), 'af': (760, 800), 'ln': (400, 1250), 'lf': (660, 1300), 'torso': (520, 700)}


def _clean(fr, d):
    """Drop opaque specks under 4·d² sprite px that touch nothing (the ref's outline crumbs a rotated cut leaves)."""
    a = np.asarray(fr.getchannel('A')) > 0
    m = Image.fromarray((a * 255).astype('uint8'), 'L')
    out = np.asarray(fr).copy()
    for _ in range(400):
        ys, xs = np.nonzero(np.asarray(m) == 255)
        if not len(ys):
            break
        ImageDraw.floodfill(m, (int(xs[0]), int(ys[0])), 1)
        comp = np.asarray(m) == 1
        if comp.sum() < 4 * d * d:
            out[comp] = 0
        ImageDraw.floodfill(m, (int(xs[0]), int(ys[0])), 2)
    return Image.fromarray(out, 'RGBA')


def mordechai(d, art_h=96, nc=96, breath=None):
    rig = Rig(NAME, art_h * d, pad=(0.62, 0.06), ncolors=nc)
    rig.density = d
    ap = round(d / rig.s)                                 # ref px per art px (the rig's step)
    c = rig.c
    neck, waist = c(0, NECK)[1], c(0, WAIST)[1]
    eyes = [(*c(x, y), rx, ry) for x, y, rx, ry in EYES]
    parts = {}
    base = rig.canvas()
    rest = base.copy()
    for key, (poly, piv) in (('an', ARM_N), ('af', ARM_F), ('ln', LEG_N), ('lf', LEG_F)):
        shp = [c(*p) for p in poly]
        m = Rig.mask(base, shp)
        part = Image.new('RGBA', base.size, (0, 0, 0, 0))
        part.paste(rest, (0, 0), m)
        parts[key] = (_main_part(part, c(*SEEDS[key])), c(*piv), shp)
    torso = rest.copy()
    for key in parts:
        torso.paste((0, 0, 0, 0), (0, 0), Rig.mask(torso, parts[key][2]))
    for key, (x0, y0, x1, y1) in HANDS.items():             # hand px on the wrong side of the cut go with the hand
        arr = np.asarray(rest).astype(int)
        skin = (arr[:, :, 0] > 150) & (arr[:, :, 0] - arr[:, :, 2] > 40) & (arr[:, :, 3] > 128)
        box = np.zeros(skin.shape, bool)
        X0, Y0 = c(x0, y0)
        X1, Y1 = c(x1, y1)
        box[Y0:Y1, X0:X1] = True
        m = Image.fromarray(((skin & box) * 255).astype('uint8'), 'L')
        part, piv, shp = parts[key]
        part.paste(rest, (0, 0), m)
        for other in ('ln', 'lf'):
            parts[other][0].paste((0, 0, 0, 0), (0, 0), m)
        torso.paste((0, 0, 0, 0), (0, 0), m)
    for cap in CAPS:
        torso.paste(rest, (0, 0), Rig.mask(rest, [c(*p) for p in cap]))
    torso = _main_part(torso, c(*SEEDS['torso']))
    # the torso under the arms: where a lifted or swung arm uncovers the body, the shirt's shaded side shows (a darker
    # tee tone from the ref's own folds) with the ref's outline weight (8 ref px) down both flanks. Drawn UNDER the
    # torso, so the rest pose never shows it.
    under = Image.new('RGBA', base.size, (0, 0, 0, 0))
    ud = ImageDraw.Draw(under)
    ud.polygon([c(*p) for p in HULL], fill=SHIRT_SH)
    for side in FLANKS:
        ud.line([c(*p) for p in side], fill=LINE, width=8)
    pel = Rig.mask(base, (*c(PELVIS[0], PELVIS[1]), *c(PELVIS[2], PELVIS[3])))
    floor = _low(rest)
    hips = Image.new('RGBA', base.size, (0, 0, 0, 0))           # the legs at rest (no hand px): the hip refill source
    hips.alpha_composite(parts['lf'][0])
    hips.alpha_composite(parts['ln'][0])

    def rot(key, deg):
        part, piv, _ = parts[key]
        return part if not deg else part.rotate(deg, resample=Image.BICUBIC, center=piv)

    def iris_to_camera(cv):
        for (x0, y0, x1, y1), dx in IRIS:
            X0, Y0 = c(x0, y0)
            X1, Y1 = c(x1, y1)
            box = cv.crop((X0, Y0, X1, Y1))
            w, h = box.size
            m = Image.new('L', box.size, 0)
            ImageDraw.Draw(m).ellipse([0, 0, w - 1, h - 1], fill=255)
            moved = Image.new('RGBA', box.size, SCLERA)
            moved.paste(box, (dx, 0))
            cv.paste(moved, (X0, Y0), m)
        return cv

    def pose(an=0.0, af=0.0, ln=0.0, lf=0.0, body=0, head=0, blink=0.0, dy=0, sx=1.0, sy=1.0,
             hdx=0, chin=0.0, look=False):
        cv = Image.new('RGBA', base.size, (0, 0, 0, 0))
        legs = Image.new('RGBA', base.size, (0, 0, 0, 0))
        legs.alpha_composite(rot('lf', lf))
        legs.alpha_composite(rot('ln', ln))
        cv.alpha_composite(legs)
        cv.alpha_composite(under)
        cv.alpha_composite(torso)
        # a swinging leg opens slivers at the hip: refill them from the rest pose, inside the pelvis only
        hole = Image.eval(cv.getchannel('A'), lambda v: 255 if v == 0 else 0)
        cv.paste(hips, (0, 0), Image.composite(Image.composite(hole, Image.new('L', cv.size, 0), pel),
                                                Image.new('L', cv.size, 0), hips.getchannel('A')))
        cv.alpha_composite(rot('af', af))
        cv.alpha_composite(rot('an', an))
        if look:
            cv = iris_to_camera(cv)
        if blink:
            rig.eyelids(cv, eyes, SKIN, amount=blink)
        if chin:  # chin up (right-facing head: counter-clockwise) about the neck, the seam kept closed
            hb = Rig.band(cv, 0, neck + 2 * ap)
            lo = Rig.band(cv, neck + 2 * ap, cv.height)
            piv = c(520, NECK)
            cv = Image.new('RGBA', base.size, (0, 0, 0, 0))
            cv.alpha_composite(lo)
            cv.alpha_composite(Rig.band(rest, neck - 4 * ap, neck + 2 * ap))
            cv.alpha_composite(hb.rotate(chin, resample=Image.BICUBIC, center=piv))
        if hdx:
            cv = rig.head_shift(cv, neck, hdx * ap, 0)
        cv = rig.shift_above(cv, neck, head * ap)
        cv = rig.shift_above(cv, waist, body * ap)
        # ground: the lowest opaque row goes back to the rest pose's floor (a rotated leg lifts both feet)
        low = _low(cv)
        if low != floor:
            g = Image.new('RGBA', cv.size, (0, 0, 0, 0))
            g.paste(cv, (0, floor - low), cv)
            cv = g
        cv = rig.squash(cv, sx, sy)
        if dy:
            g = Image.new('RGBA', cv.size, (0, 0, 0, 0))
            g.paste(cv, (0, -dy * ap), cv)
            cv = g
        return _clean(rig.down(cv), d)

    anims = []
    # idle: 20 @ 10, the cast's breathing and blink (generic() in build.py), the arms still
    n = 20
    idle = [pose(body=breath(i, n), head=breath((i - 1) % n, n), blink={9: 0.5, 10: 1.0, 11: 0.5}.get(i, 0))
            for i in range(n)]
    anims.append(('idle', idle, 10, True, None, None))
    # walk: 8 @ 10. Contact on 0 and 4 (legs at full spread), passing on 2 and 6 (1 ap up). Arms counter-swing.
    A = 11.0
    walk = []
    for i in range(8):
        s_ = math.sin(2 * math.pi * i / 8 + math.pi / 2)             # 1 on frame 0: the near leg forward
        walk.append(pose(ln=A * s_, lf=-A * s_, an=-0.55 * A * s_, af=0.55 * A * s_,
                         dy=1 if i in (2, 6) else 0, head=1 if i in (1, 5) else 0))
    anims.append(('walk', walk, 10, True, {'step': 0, 'step2': 4}, None))
    # block: arms spread from the shoulders, feet planted wide. ASYMMETRIC on purpose: he faces the crowd (right, as
    # drawn), so the leader is behind his screen-left shoulder; that arm spreads low (LO) and keeps his reach out of
    # the leader's slot (x 66-114), the outer arm spreads high (HI) over the crowd. Flipped for the left crowd, the
    # same arm is still the leader-side one.
    LO, HI, FT = 12.0, 42.0, 7.0
    bin_ = [pose(an=-LO * t, af=HI * t, ln=-FT * min(1, 2 * t), lf=FT * min(1, 2 * t),
                 sx=1 + 0.02 * t, sy=1 - 0.02 * t, blink=0.5 if k == 1 else 0)
            for k, t in enumerate((0.2, 0.5, 0.85, 1.0))]
    anims.append(('block_in', bin_, 12, False, {'plant': 1}, None))
    hold = [pose(an=-LO, af=HI, ln=-FT, lf=FT, sx=1.02, sy=0.98),
            pose(an=-LO - 2, af=HI + 3, ln=-FT, lf=FT, sx=1.02, sy=0.98, body=1),
            pose(an=-LO - 1, af=HI + 1, ln=-FT, lf=FT, sx=1.02, sy=0.98, body=1, head=1)]
    anims.append(('block', hold, 6, True, None, None))
    # glance: the smug look at the player. 0-2 turn, 3-7 hold (smirk on 4), 8-9 back
    G = [dict(), dict(hdx=-1), dict(hdx=-1, chin=2.0, look=True, blink=0.2),
         dict(hdx=-1, chin=4.0, look=True, blink=0.4), dict(hdx=-1, chin=4.0, look=True, blink=0.45),
         dict(hdx=-1, chin=4.0, look=True, blink=0.45, head=1), dict(hdx=-1, chin=4.0, look=True, blink=0.45),
         dict(hdx=-1, chin=3.0, look=True, blink=0.4), dict(hdx=-1, chin=1.0, blink=0.2), dict()]
    anims.append(('glance', [pose(**g) for g in G], 10, False, {'smirk': 4}, None))
    return rig, anims
