"""Build the approval showcase: Bibi (the Magician), Sara, Bennett.

Output (art/showcase/out/):
  <char>_<anim>.png   horizontal frame strips (art px, 1x)
  <char>_avatar.png   32x32 chat avatar
  atlas.json          frame size, fps, loop, anchor, events per animation
  props.png + props   hat, coin, bill, rabbit, sparkle, shadow
Run: python3 build.py
"""
import json, math, os
from PIL import Image, ImageDraw
from rig import Rig, strip, pixmap

OUT = os.path.join(os.path.dirname(__file__), '..', 'out')
os.makedirs(OUT, exist_ok=True)
ART_H = 96   # every character is 96 art px tall in its rest pose
D = 3        # density: sprite px per art px for the rendered cast (Bar, 2026-09-29: 3x, a 288-px source)
NC = 96      # palette size per character at 3x (quantisation error -38% vs 44; flattens past 96)
H = ART_H * D
atlas = {'artHeight': ART_H, 'density': D, 'chars': {}, 'props': {}}


def save(name, frames, fps, loop, rig, events=None, extra=None):
    strip(frames).save(os.path.join(OUT, name + '.png'))
    w, h = frames[0].size
    char, anim = name.split('_', 1)
    dens = getattr(rig, 'density', 1)
    a = atlas['chars'].setdefault(char, {'frameW': w, 'frameH': h, 'anchor': [w // 2, h - 1], 'density': dens,
                                         'anims': {}})
    a['anims'][anim] = {'file': name + '.png', 'frames': len(frames), 'fps': fps, 'loop': loop,
                        'events': events or {}, 'density': dens}
    if extra:
        a['anims'][anim].update(extra)


def breath(i, n):
    """0/1 breathing flag: chest drops for the middle half of the cycle."""
    return 1 if n // 4 <= i < 3 * n // 4 else 0


def avatar(rig, head_box_ref, name, ring):
    """Chat avatars: head crop from the rest pose, round mask, 1px ring. 32x32 (<name>_avatar.png)
    and, for the UX's 48-logical-px chat avatar at x2, 24x24 (<name>_avatar24.png)."""
    for size, fy, suffix in ((32, 2, ''), (24, 1, '24')):
        cv = rig.canvas()
        x0, y0 = rig.c(head_box_ref[0], head_box_ref[1])
        x1, y1 = rig.c(head_box_ref[2], head_box_ref[3])
        side = max(x1 - x0, y1 - y0)
        crop = cv.crop((x0, y0, x0 + side, y0 + side)).resize((size - 2, size - 2), Image.LANCZOS)
        a = crop.getchannel('A').point(lambda v: 255 if v > 118 else 0)
        rgb = crop.convert('RGB').quantize(palette=rig.palette, dither=Image.Dither.NONE).convert('RGBA')
        rgb.putalpha(a)
        out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        bg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        d = ImageDraw.Draw(bg)
        d.ellipse([0, 0, size - 1, size - 1], fill=ring)
        d.ellipse([2, 2, size - 3, size - 3], fill=(236, 228, 214, 255))
        out.alpha_composite(bg)
        face = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        face.alpha_composite(rgb, (1, fy))
        m = Image.new('L', (size, size), 0)
        ImageDraw.Draw(m).ellipse([2, 2, size - 3, size - 3], fill=255)
        out.paste(face, (0, 0), Image.composite(face.getchannel('A'), Image.new('L', (size, size), 0), m))
        out.save(os.path.join(OUT, name + '_avatar' + suffix + '.png'))


# ---------------------------------------------------------------- props (drawn at art resolution)
P = {'K': (20, 16, 24, 255), 'D': (42, 36, 51, 255), 'M': (61, 53, 71, 255), 'H': (98, 88, 112, 255),
     'I': (8, 6, 12, 255), 'B': (0, 56, 184, 255), 'b': (58, 104, 222, 255),
     'Y': (242, 193, 78, 255), 'y': (201, 138, 27, 255), 'O': (92, 58, 16, 255), 'L': (255, 236, 160, 255),
     'W': (196, 192, 206, 255), 'w': (150, 145, 163, 255), 'P': (240, 150, 170, 255), 'E': (30, 22, 30, 255),
     'G': (120, 190, 110, 255), 'g': (70, 140, 80, 255), 'C': (240, 130, 40, 255), 'S': (255, 255, 255, 255)}

HAT = pixmap([          # upside-down top hat, opening up: the Magician levitates it over his finger
    '....KKKKKKKKKKKK....',
    '..KKHHHHHHHHHHHHKK..',
    '.KHMIIIIIIIIIIIIMHK.',
    'KHMIIIIIIIIIIIIIIMHK',
    'KMIIIIIIIIIIIIIIIIMK',
    '.KMMIIIIIIIIIIIIMMK.',
    '..KKMMMMMMMMMMMMKK..',
    '...KDBBBBBBBBBBDK...',
    '...KDbbBBBBBBBBDK...',
    '...KDDDDDDDDDDDHK...',
    '...KMDDDDDDDDDDHK...',
    '...KMDDDDDDDDDDHK...',
    '...KMMDDDDDDDDHHK...',
    '....KKKKKKKKKKKK....'], P)
HAT_DX, HAT_DY = -7, -6   # hover offset from the fingertip, art px (x D in sprite px)
COIN = [pixmap(r, P) for r in (
    ['.OOO.', 'OYLYO', 'OYYyO', 'OyYyO', '.OOO.'],
    ['.OO.', 'OYyO', 'OYyO', 'OYyO', '.OO.'],
    ['.O.', 'OyO', 'OyO', 'OyO', '.O.'],
    ['.OO.', 'OyYO', 'OyYO', 'OyYO', '.OO.'])]
RABBIT = pixmap([       # our own grey rabbit (not Bugs): peeks out of the hat
    '..K.......K..',
    '.KWK.....KWK.',
    '.KWK.....KPK.',
    '.KWPK...KPWK.',
    '.KWPK...KPWK.',
    '..KWK...KWK..',
    '.KKWWWWWWWKK.',
    'KWWWWWWWWWWWK',
    'KWWEWWWWWEWWK',
    'KWWWWWPWWWWWK',
    'KwWWWKWKWWWwK',
    '.KwWWWWWWWwK.',
    '..KKKKKKKKK..'], P)
def outlined(im, col=(214, 204, 236, 255)):
    """1px pale rim around a prop so it separates from dark stages."""
    a = im.getchannel('A')
    w, h = im.size
    out = Image.new('RGBA', (w + 2, h + 2), (0, 0, 0, 0))
    rim = Image.new('RGBA', out.size, col)
    m = Image.new('L', out.size, 0)
    for dx, dy in ((0, 1), (2, 1), (1, 0), (1, 2)):
        m.paste(a, (dx, dy), a)
    out.paste(rim, (0, 0), m)
    out.alpha_composite(im, (1, 1))
    return out


HAT = outlined(HAT)
RABBIT = outlined(RABBIT)
SPARK = pixmap(['..S..', '..S..', 'SSYSS', '..S..', '..S..'], P)
BILL = pixmap(['KKKKKKKK', 'KGGgGGGK', 'KGgYYgGK', 'KGGgGGGK', 'KKKKKKKK'], P)
for n, im in [('hat', HAT), ('rabbit', RABBIT), ('spark', SPARK), ('bill', BILL)] + \
        [('coin%d' % i, c) for i, c in enumerate(COIN)]:
    im.save(os.path.join(OUT, 'prop_' + n + '.png'))
    atlas['props'][n] = {'file': 'prop_' + n + '.png', 'w': im.width, 'h': im.height}


def x3(im):
    """A 1x art prop at the cast's density (nearest), so it matches the stage's pixel size."""
    return im.resize((im.width * D, im.height * D), Image.NEAREST)


SPARK3 = x3(SPARK)


def paste_c(frame, im, cx, bottom):
    """Paste im with its bottom-centre at (cx, bottom) in art px."""
    frame.alpha_composite(im, (int(round(cx - im.width / 2)), int(round(bottom - im.height)))) \
        if cx - im.width / 2 >= 0 and bottom - im.height >= 0 else \
        frame.paste(im, (int(round(cx - im.width / 2)), int(round(bottom - im.height))), im)


# ================================================================ BIBI, the Magician
def xd(im, d):
    """A 1x art prop at density d (nearest): one art px = a d x d block, the stage's pixel size."""
    return im.resize((im.width * d, im.height * d), Image.NEAREST)


def magician(d):
    """The Magician's three anims at density d (sprite px per art px), rendered from the ref like the
    rest of the cast: the rig works at ref resolution and downsamples to 96·d px, so a d = 2 alternate
    is a first-generation render, not a resample of the d = 3 strips. Motion amplitudes stay in art
    px (one art px = STEP ref px at any d); the hat, rabbit, motes and coins are 1x art as d x d
    blocks. Returns (rig, [(anim, frames, fps, loop, events, extra)]); hatMouth / temple are derived
    from this render's own geometry, in its sprite px."""
    rig = Rig('bibi', ART_H * d, pad=(0.30, 0.30), ncolors=NC)
    rig.density = d
    B = dict(neck=rig.c(0, 562)[1], waist=rig.c(0, 922)[1],
             hand=(*rig.c(118, 392), *rig.c(298, 662)), pivot=rig.c(215, 682), tip=rig.c(238, 418),
             eyes=[(*rig.c(403, 318), 32, 19), (*rig.c(525, 334), 34, 19)], skin=(236, 146, 100, 255))
    STEP = round(d / rig.s)  # one ART pixel in ref px (motion amplitudes stay in art px)
    HATd, RABBITd = xd(HAT, d), xd(RABBIT, d)
    eye_tops = []   # per pose call: the screen-right eye's top, in sprite px (for the temple landmark)

    def pose(body=0, head=0, ang=0.0, sx=1.0, sy=1.0, blink=0.0, wink=0.0):
        ex, ey = B['eyes'][1][0], B['eyes'][1][1] - B['eyes'][1][3]
        ey += (head * STEP if ey < B['neck'] else 0) + (body * STEP if ey < B['waist'] else 0)
        eye_tops.append(rig.to_art(*rig.squash_pt((ex, ey), sx, sy)))
        cv = rig.canvas()
        if blink:
            rig.eyelids(cv, B['eyes'], B['skin'], amount=blink)
        if wink:
            rig.eyelids(cv, B['eyes'][1:], B['skin'], amount=wink)
        cv = rig.rotate_region(cv, B['hand'], B['pivot'], ang)
        cv = rig.shift_above(cv, B['neck'], head * STEP)
        cv = rig.shift_above(cv, B['waist'], body * STEP)
        tip = Rig.rot_pt(B['tip'], B['pivot'], ang)
        tip = (tip[0], tip[1] + body * STEP)
        cv = rig.squash(cv, sx, sy)
        tip = rig.squash_pt(tip, sx, sy)
        return rig.down(cv), rig.to_art(*tip)

    def hat_anchor(tip, lift=0):
        return tip[0] + HAT_DX * d, tip[1] + (HAT_DY - lift) * d

    def hat_mouth(tip, lift=0):
        """The hat's opening, sprite px: 2 art rows below the hat's top."""
        cx, bt = hat_anchor(tip, lift)
        return [round(cx), round(bt - HATd.height + 3 * d)]

    def with_hat(frame, tip, lift=0, squish=0, glow=True):
        hat = HATd if not squish else xd(HAT.resize((HAT.width + squish, HAT.height - squish), Image.NEAREST), d)
        cx, bottom = hat_anchor(tip, lift)
        if glow:  # two magic motes between the finger and the hat, one art px each
            dr = ImageDraw.Draw(frame)
            for t in (0.35, 0.7):
                x = round(tip[0] + (cx - tip[0]) * t); y = round(tip[1] - 2 * d + (bottom - tip[1] + 2 * d) * t)
                dr.rectangle([x, y, x + d - 1, y + d - 1], fill=(255, 236, 160, 255))
        paste_c(frame, hat, cx, bottom + d)
        return frame

    def temples(frames):
        """The temple landmark (animator render-requests §B): per frame, the first transparent px right of
        the screen-right eye, on the row of that eye's top. Consumes the eye tops recorded for these frames."""
        tops = eye_tops[:len(frames)]
        del eye_tops[:len(frames)]
        out = []
        for f, (x, y) in zip(frames, tops):
            a = f.getchannel('A')
            X, Y = int(round(x)), int(round(y))
            while X < f.width - 1 and a.getpixel((X, Y)):
                X += 1
            out.append([X, Y])
        return out

    anims = []
    # idle: 20 frames @10fps, breathe, lecturing finger sways, blink near the end
    N = 20
    idle, idle_mouth = [], []
    for i in range(N):
        b = breath(i, N)
        hb = breath((i - 1) % N, N)
        ang = 5 * math.sin(2 * math.pi * i / N)
        blink = {16: 0.5, 17: 1.0, 18: 0.5}.get(i, 0)
        f, tip = pose(body=b, head=hb, ang=ang, blink=blink)
        idle.append(with_hat(f, tip))
        idle_mouth.append(hat_mouth(tip))
    anims.append(('idle', idle, 10, True, None, {'hatMouth': idle_mouth, 'temple': temples(idle)}))

    # tap: 8 frames @15fps, squash-stretch, the hat hops off the finger; coins burst on frame 3
    T = [dict(sx=1, sy=1, ang=0, lift=0), dict(sx=1.05, sy=0.94, ang=4, lift=0, squish=2),
         dict(sx=0.97, sy=1.05, ang=-7, lift=4), dict(sx=0.99, sy=1.02, ang=-4, lift=8),
         dict(sx=1, sy=1, ang=-2, lift=7), dict(sx=1.01, sy=0.99, ang=0, lift=4),
         dict(sx=1, sy=1, ang=1, lift=1), dict(sx=1, sy=1, ang=0, lift=0)]
    tap, hatpos = [], []
    for k in T:
        f, tip = pose(ang=k['ang'], sx=k['sx'], sy=k['sy'])
        with_hat(f, tip, k['lift'], k.get('squish', 0))
        hatpos.append(hat_mouth(tip, k['lift']))
        tap.append(f)
    anims.append(('tap', tap, 15, False, {'coins': 3}, {'hatMouth': hatpos, 'temple': temples(tap)}))

    # crit: the rabbit pops out of the hat, the Magician winks. 14 frames @12fps
    crit, crit_mouth = [], []
    RB = [0, 0, 0, 4, 8, 11, 13, 13, 13, 13, 11, 7, 3, 0]
    for i in range(14):
        k = T[min(i, 3)] if i < 4 else dict(sx=1, sy=1, ang=-3 if i < 11 else 0, lift=8 if i < 11 else [5, 2, 0][i - 11])
        wink = 1.0 if 5 <= i <= 9 else (0.5 if i in (4, 10) else 0)
        f, tip = pose(ang=k['ang'], sx=k['sx'], sy=k['sy'], wink=wink)
        cx, bt = hat_anchor(tip, k['lift'])
        mouth = bt + d - HATd.height + 5 * d     # y of the hat's front rim
        if RB[i]:
            r = RABBITd.crop((0, 0, RABBITd.width, min(RABBITd.height, RB[i] * d)))
            paste_c(f, r, cx, mouth)
        with_hat(f, tip, k['lift'], k.get('squish', 0))
        if RB[i]:  # the rabbit sits inside the opening: redraw only the rabbit rows above the rim
            top = r.crop((0, 0, r.width, max(d, r.height - 3 * d)))
            paste_c(f, top, cx, mouth - 3 * d)
        crit.append(f)
        crit_mouth.append(hat_mouth(tip, k['lift']))
    anims.append(('crit', crit, 12, False, {'coins': 3, 'rabbit': 4, 'sting': 5},
                  {'hatMouth': crit_mouth, 'temple': temples(crit)}))
    return rig, anims


bibi, _anims = magician(D)
for _a, _fr, _fps, _loop, _ev, _ex in _anims:
    save('bibi_' + _a, _fr, _fps, _loop, bibi, events=_ev, extra=_ex)
avatar(bibi, (285, 150, 745, 610), 'bibi', (0, 56, 184, 255))

# The d = 2 alternate (engine request, 2026-09-29): every DPR-2 phone runs at k 4 (and a few at k 8, the
# desktop at k 2), where a d = 3 sprite px is a fractional 4/3 device px. A d = 2 render is 2 device px
# per sprite px at k 4: crisp. Files bibi_<anim>_d2.png; atlas chars.bibi.densities["2"] carries its own
# frame size, anchor and per-frame tracks (the engine's SpriteStrip.pick_variant merges it over the main
# entry). Bibi only: he is always on screen; partners stay on the "aa" path (their VRAM, not worth it).
ALT_DENSITIES = (2,)
for _d in ALT_DENSITIES:
    _rig, _anims = magician(_d)
    _alt = None
    for _a, _fr, _fps, _loop, _ev, _ex in _anims:
        _name = 'bibi_%s_d%d' % (_a, _d)
        strip(_fr).save(os.path.join(OUT, _name + '.png'))
        w, h = _fr[0].size
        _alt = _alt or {'frameW': w, 'frameH': h, 'anchor': [w // 2, h - 1], 'density': _d, 'anims': {}}
        _alt['anims'][_a] = {'file': _name + '.png', 'frames': len(_fr), 'fps': _fps, 'loop': _loop,
                             'events': _ev or {}, 'density': _d, **_ex}
    atlas['chars']['bibi'].setdefault('densities', {})[str(_d)] = _alt

# ================================================================ SARA
sara = Rig('sara', H, pad=(0.20, 0.12), ncolors=NC)
sara.density = D
S = dict(neck=sara.c(0, 640)[1], waist=sara.c(0, 1000)[1],
         hand=(*sara.c(140, 360), *sara.c(283, 800)), pivot=sara.c(236, 815),
         eyes=[(*sara.c(440, 283), 42, 20), (*sara.c(577, 305), 50, 19)], skin=(246, 156, 108, 255))
STEP_S = round(D / sara.s)


def sara_pose(body=0, head=0, ang=0.0, sx=1.0, sy=1.0, blink=0.0, lift=0):
    cv = sara.canvas()
    if blink:
        sara.eyelids(cv, S['eyes'], S['skin'], amount=blink)
    cv = sara.rotate_region(cv, S['hand'], S['pivot'], ang)
    if lift:  # chin up: raise everything above the neck, stretch the seam row to close the gap
        cut = S['neck']; dy = lift * STEP_S
        upper = Rig.band(cv, 0, cut); lower = Rig.band(cv, cut, cv.height)
        seam = cv.crop((0, cut, cv.width, cut + 1)).resize((cv.width, dy + 1))
        cv = Image.new('RGBA', cv.size, (0, 0, 0, 0))
        cv.alpha_composite(lower); cv.alpha_composite(seam, (0, cut - dy))
        cv.paste(upper, (0, -dy), upper)
    cv = sara.shift_above(cv, S['neck'], head * STEP_S)
    cv = sara.shift_above(cv, S['waist'], body * STEP_S)
    cv = sara.squash(cv, sx, sy)
    return sara.down(cv)


N = 20
idle = []
for i in range(N):
    b = breath(i, N)
    ang = -6 * max(0, math.sin(2 * math.pi * i / N))  # a slow sip-ward lift of the glass
    blink = {6: 0.5, 7: 1.0, 8: 0.5}.get(i, 0)
    f = sara_pose(body=b, head=breath((i - 1) % N, N), ang=ang, blink=blink)
    if i in (2, 3, 12, 13):  # glint on the champagne glass
        g = sara.to_art(*sara.c(200, 400))
        paste_c(f, SPARK3, g[0], g[1] + 2 * D)
    idle.append(f)
save('sara_idle', idle, 10, True, sara)

# offended: chin up, a little huff, eyes shut in disdain. 12 frames @12fps
OFF = [(0, 0, 0, 1, 1), (0, 0, 4, 1.03, 0.96), (1, 0.5, 6, 0.98, 1.03), (1, 1, 8, 1, 1.01),
       (1, 1, 8, 1, 1), (1, 1, 8, 1, 1), (1, 1, 8, 1, 1), (1, 1, 8, 1, 1), (1, 0.5, 6, 1, 1),
       (0, 0, 3, 1, 1), (0, 0, 1, 1, 1), (0, 0, 0, 1, 1)]
off = [sara_pose(lift=l, blink=bl, ang=a, sx=sx, sy=sy) for l, bl, a, sx, sy in OFF]
save('sara_offended', off, 12, False, sara, events={'huff': 2})
avatar(sara, (300, 120, 720, 540), 'sara', (224, 96, 150, 255))

# ================================================================ BENNETT
ben = Rig('bennett', H, pad=(0.20, 0.12), ncolors=NC)
ben.density = D
N_ = dict(neck=ben.c(0, 675)[1], waist=ben.c(0, 1050)[1],
          hand=(*ben.c(80, 640), *ben.c(262, 880)), pivot=ben.c(250, 880),
          eyes=[(*ben.c(390, 356), 32, 19), (*ben.c(545, 389), 36, 19)], skin=(238, 166, 118, 255))
STEP_B = round(D / ben.s)


def ben_pose(body=0, head=0, ang=0.0, sx=1.0, sy=1.0, blink=0.0, flip=False):
    cv = ben.canvas()
    if blink:
        ben.eyelids(cv, N_['eyes'], N_['skin'], amount=blink)
    cv = ben.rotate_region(cv, N_['hand'], N_['pivot'], ang)
    cv = ben.shift_above(cv, N_['neck'], head * STEP_B)
    cv = ben.shift_above(cv, N_['waist'], body * STEP_B)
    if flip:
        cv = ben.mirror(cv)
    cv = ben.squash(cv, sx, sy)
    return ben.down(cv)


N = 20
idle = []
for i in range(N):
    b = breath(i, N)
    ang = 8 * math.sin(4 * math.pi * i / N)  # the "let me explain" hand, twice per loop
    blink = {12: 0.5, 13: 1.0, 14: 0.5}.get(i, 0)
    idle.append(ben_pose(body=b, head=breath((i - 1) % N, N), ang=ang, blink=blink))
save('bennett_idle', idle, 10, True, ben)

# the pledge flip: he signs, then turns to face the other way. 10 frames @12fps (play forward, then reverse)
FL = [(1, False), (0.75, False), (0.45, False), (0.22, False),
      (0.22, True), (0.45, True), (0.75, True), (1, True)]
flip = [ben_pose(sx=s, sy=1 + (1 - s) * 0.04, flip=m) for s, m in FL]
save('bennett_flip', flip, 12, False, ben, events={'whoosh': 3})
avatar(ben, (330, 60, 830, 560), 'bennett', (40, 70, 140, 255))

# ================================================================ the rest of the cast (generic rig)
from cast import CAST
from PIL import Image as _I


def generic(name, cfg):
    rig = Rig(name, H, pad=(0.14, 0.10), ncolors=NC)
    rig.density = D
    st = round(D / rig.s)
    neck, waist = rig.c(0, cfg['neck'])[1], rig.c(0, cfg['waist'])[1]
    eyes = [(*rig.c(x, y), rx, ry) for x, y, rx, ry in cfg['eyes']]
    src = _I.open(os.path.join(os.path.dirname(__file__), '..', '..', 'refs', name + '.png')).convert('RGB')
    ex = (cfg['eyes'][0][0] + cfg['eyes'][1][0]) // 2
    ey = (cfg['eyes'][0][1] + cfg['eyes'][1][1]) // 2 + 30
    skin = tuple(cfg['skin']) + (255,) if cfg.get('skin') else src.getpixel((ex, ey)) + (255,)
    arm = cfg.get('arm')
    if arm and isinstance(arm[0], (tuple, list)):
        box = [rig.c(x, y) for x, y in arm[0]]
        piv = rig.c(*arm[1])
    elif arm:
        box = (*rig.c(arm[0], arm[1]), *rig.c(arm[2], arm[3]))
        piv = rig.c(arm[4], arm[5])

    def pose(body=0, head=0, ang=0.0, sx=1.0, sy=1.0, blink=0.0, dx=0, dy=0, hdx=0):
        cv = rig.canvas()
        if hdx:  # head turn: slide everything above the neck sideways
            up = Rig.band(cv, 0, neck); lo = Rig.band(cv, neck, cv.height)
            cv = _I.new('RGBA', cv.size, (0, 0, 0, 0)); cv.alpha_composite(lo); cv.paste(up, (hdx * st, 0), up)
        if blink:
            rig.eyelids(cv, eyes, skin, amount=blink)
        if arm and ang:
            cv = rig.rotate_region(cv, box, piv, ang)
        cv = rig.shift_above(cv, neck, head * st)
        cv = rig.shift_above(cv, waist, body * st)
        cv = rig.squash(cv, sx, sy)
        if dx or dy:
            sh = _I.new('RGBA', cv.size, (0, 0, 0, 0)); sh.paste(cv, (dx * st, -dy * st), cv); cv = sh
        return rig.down(cv)

    n = 20
    idle = []
    for i in range(n):
        ang = 3 * math.sin(2 * math.pi * i / n) if arm else 0
        blink = {9: 0.5, 10: 1.0, 11: 0.5}.get(i, 0)
        idle.append(pose(body=breath(i, n), head=breath((i - 1) % n, n), ang=ang, blink=blink))
    save(name + '_idle', idle, 10, True, rig)
    if cfg['react'] == 'no':  # a slow, final head shake
        seq = [0, 1, 1, 0, -1, -1, 0, 1, 1, 0, -1, 0]
        react = [pose(hdx=h, blink=1.0 if i in (5, 6) else 0) for i, h in enumerate(seq)]
        save(name + '_react', react, 10, False, rig, events={'no': 1})
    elif cfg['react'] == 'sneak':  # tiptoes out of the plenum, peeks back, returns
        seq = [(0, 0), (1, 1), (2, 0), (3, 1), (4, 0), (5, 1), (6, 0), (6, 0), (6, 0), (4, 0), (2, 1), (0, 0)]
        react = [pose(dx=dx, dy=dy) for dx, dy in seq]
        save(name + '_react', react, 10, False, rig, events={'step': 1})
    elif cfg['react'] == 'bang':
        seq = [(0, 1, 1), (-10, 1, 1.02), (-16, 1, 1.03), (8, 1.04, .95), (12, 1.05, .94), (6, 1, 1),
               (-10, 1, 1.02), (8, 1.04, .95), (12, 1.05, .94), (4, 1, 1), (0, 1, 1), (0, 1, 1)]
        react = [pose(ang=a, sx=sx, sy=sy) for a, sx, sy in seq]
        save(name + '_react', react, 14, False, rig, events={'bang': 4, 'bang2': 8})
    elif cfg['react'] == 'jab':
        seq = [(0, 0, 1, 1, 0), (-6, 0, 1.02, .97, 0), (8, 0, 1, 1.01, 1), (-4, 0, 1, 1, -1), (8, 0, 1, 1.01, 1),
               (-4, 0, 1, 1, -1), (8, 0, 1, 1.01, 1), (2, 0, 1, 1, 0), (0, 0, 1, 1, 0), (0, 0, 1, 1, 0)]
        react = [pose(ang=a, sx=sx, sy=sy, dx=dx) for a, _, sx, sy, dx in seq]
        save(name + '_react', react, 14, False, rig, events={'shout': 2})
    else:
        seq = [(1, 1, 0), (1.05, .94, 0), (.97, 1.05, 2), (.99, 1.02, 4), (1, 1, 3), (1, 1, 1), (1.04, .95, 0), (1, 1, 0)]
        react = [pose(sx=sx, sy=sy, dy=dy) for sx, sy, dy in seq]
        save(name + '_react', react, 14, False, rig, events={'land': 6})
    ring = {'hop': (242, 193, 78, 255), 'jab': (208, 42, 54, 255), 'bang': (122, 74, 40, 255), 'sneak': (60, 60, 70, 255), 'no': (90, 90, 100, 255)}[cfg['react']]
    avatar(rig, cfg['head'], name, ring)


import sys as _sys
_only = [a for a in _sys.argv[1:]]
for _n, _cfg in CAST.items():
    if not _only or _n in _only:
        generic(_n, _cfg)

# ================================================================ DUBI (motion/state-graph-dubi.md §1)
from cast import DUBI as DB, SOURCES, SOURCE_ALIASES


def _sh(rig, shape):
    """A landmark shape (polygon or rect, ref px) in canvas px."""
    if isinstance(shape[0], (tuple, list)):
        return [rig.c(*q) for q in shape]
    return (*rig.c(shape[0], shape[1]), *rig.c(shape[2], shape[3]))


def _keep(before, after, rig, shape):
    """Refill holes `after` opened inside `shape` from `before` (a rotated wing never punches the sleeve)."""
    k = Rig.mask(before, shape)
    hole = _I.eval(after.getchannel('A'), lambda v: 255 if v == 0 else 0)
    after.paste(before, (0, 0), _I.composite(hole, _I.new('L', before.size, 0), k))
    return after


def dubi_small():
    """18 art px, full body, no mic stand. Signs follow the spec: wing + = raised, beak + = open,
    head (hx, hy) in ap with - x = forward (he faces screen-left)."""
    rig = Rig('dubi', 18, pad=(0.30, 0.30), ncolors=24, edits=DB['no_mic'])
    st = round(1 / rig.s)
    waist = rig.c(0, DB['waist'])[1]
    eyes = [(*rig.c(x, y), rx, ry) for x, y, rx, ry in DB['eyes']]
    skin = tuple(DB['skin']) + (255,)
    jaw, upper, hinge = _sh(rig, DB['jaw']), _sh(rig, DB['upper']), rig.c(*DB['hinge'])
    head, wing, wpiv = _sh(rig, DB['head']), _sh(rig, DB['wing']), rig.c(*DB['wing_pivot'])
    sleeve = _sh(rig, (290, 470, 430, 840))

    def pose(body=0, hx=0, hy=0, blink=0.0, beak=0, wing_deg=0, sx=1.0, sy=1.0):
        cv = rig.canvas()
        if blink:
            rig.eyelids(cv, eyes, skin, amount=blink)
        cv = rig.hinge(cv, jaw, hinge, DB['closed'] + beak, upper, skin)
        if wing_deg:
            cv = _keep(cv, rig.rotate_region(cv, wing, wpiv, -wing_deg), rig, sleeve)
        cv = rig.move_region(cv, head, hx * st, hy * st, keep=head)
        cv = rig.shift_above(cv, waist, body * st)
        cv = rig.squash(cv, sx, sy)
        return rig.down(cv)

    n = 16
    idle = [pose(body=1 if 4 <= i <= 11 else 0, hy=-1 if i in (6, 7) else 0,
                 blink={12: 0.5, 13: 1.0}.get(i, 0), wing_deg=3 * math.sin(2 * math.pi * i / n)) for i in range(n)]
    save('dubi_idle', idle, 8, True, rig)
    save('dubi_talk', [pose(), pose(beak=20)], 16, False, rig)
    save('dubi_squawk', [pose(), pose(hy=-1, sx=0.96, sy=1.06, beak=30, wing_deg=15), pose(beak=10, sy=1.02), pose()],
         12, False, rig, events={'squawk': 1})
    fly = [pose(sx=1.04, sy=0.96, wing_deg=w) for w in (35, 10, -30, 10)]
    save('dubi_fly', fly, 12, True, rig, events={'flap': 2})
    # land.f0 IS fly.f0 (the spec's MUST; its 'sy 1.05' flare is dropped so takeoff reverses seamlessly)
    save('dubi_land', [fly[0], pose(sx=1.08, sy=0.92, wing_deg=10), pose()], 12, False, rig, events={'touch': 1})
    save('dubi_peck', [pose(), pose(hx=1, hy=-1), pose(hx=-2, hy=2), pose(hx=-2, hy=2, sx=1.04, sy=0.96),
                       pose(hx=-1, hy=1), pose()], 12, False, rig, events={'peck': 2})


def dubi_mic():
    """96 art px, the O3b flash-card pose, mic kept. The rest pose has the beak closed; talk.f1 is the ref."""
    rig = Rig('dubi-mic', H, pad=(0.14, 0.10), ref='dubi', ncolors=NC)
    rig.density = D
    st = round(D / rig.s)
    neck, waist = rig.c(0, DB['neck'])[1], rig.c(0, DB['waist'])[1]
    eyes = [(*rig.c(x, y), rx, ry) for x, y, rx, ry in DB['eyes']]
    skin = tuple(DB['skin']) + (255,)
    jaw, upper, hinge = _sh(rig, DB['jaw']), _sh(rig, DB['upper']), rig.c(*DB['hinge'])
    arm, apiv = _sh(rig, DB['mic_arm'][0]), rig.c(*DB['mic_arm'][1])

    def pose(body=0, head=0, ang=0.0, blink=0.0, beak=0):
        cv = rig.canvas()
        if blink:
            rig.eyelids(cv, eyes, skin, amount=blink)
        cv = rig.hinge(cv, jaw, hinge, DB['closed'] + beak, upper, skin)
        if ang:
            cv = rig.rotate_region(cv, arm, apiv, ang)
        cv = rig.shift_above(cv, neck, head * st)
        cv = rig.shift_above(cv, waist, body * st)
        return rig.down(cv)

    n = 20
    idle = [pose(body=breath(i, n), head=breath((i - 1) % n, n), ang=3 * math.sin(2 * math.pi * i / n),
                 blink={9: 0.5, 10: 1.0, 11: 0.5}.get(i, 0)) for i in range(n)]
    save('dubi-mic_idle', idle, 10, True, rig)
    save('dubi-mic_talk', [pose(), pose(beak=-DB['closed'])], 16, False, rig)
    avatar(rig, DB['avatar_head'], 'dubi', (40, 70, 140, 255))


# ================================================================ the money sources (diorama-motion.md §1)
SIL_FILL, RIM = (69, 74, 96, 255), (214, 204, 236, 255)
atlas.setdefault('sources', {})
MISSING = []


def source(sid, cfg):
    if not os.path.exists(os.path.join(os.path.dirname(__file__), '..', '..', 'refs', sid + '.png')):
        MISSING.append(sid)
        return
    rig = Rig(sid, 38 * D, pad=(0.14, 0.0), ncolors=64)   # 38 art + the 2-art-px rim = 40 art tall (120 sprite px)
    rig.density = D
    st = round(D / rig.s)
    def rimD(im):                                          # a 1-art-px rim = D sprite px
        for _ in range(D):
            im = rig.rim(im)
        return im
    cut = lambda k: rig.c(0, cfg[k])[1]
    ops = sorted(cfg['f1'], key=lambda o: o[0] != 'eyelids')      # eyelids use unshifted landmarks
    f0 = rimD(rig.down(rig.canvas()))
    cv, post = rig.canvas(), []
    for op in ops:
        k = op[0]
        if k == 'eyelids':
            eyes = [(*rig.c(x, y), rx, ry) for x, y, rx, ry in cfg['eyes']]
            src = _I.open(os.path.join(REFS_DIR, sid + '.png')).convert('RGB')
            ex = (cfg['eyes'][0][0] + cfg['eyes'][1][0]) // 2
            ey = (cfg['eyes'][0][1] + cfg['eyes'][1][1]) // 2 + 30
            rig.eyelids(cv, eyes, src.getpixel((ex, ey)) + (255,), amount=op[1])
        elif k == 'body':
            cv = rig.shift_above(cv, cut('waist'), op[1] * st)
        elif k == 'head':
            cv = rig.shift_above(cv, cut('neck'), op[1] * st)
        elif k == 'headx':
            cv = rig.head_shift(cv, cut('neck'), op[1] * st, 0)
        elif k == 'move':
            cv = rig.move_region(cv, _sh(rig, op[1]), op[2] * st, op[3] * st, keep=_sh(rig, op[4]) if op[4] else None)
        elif k == 'px':
            post.append(op)
    f1 = rig.down(cv)
    for _, (x, y), rgb, (adx, ady) in post:
        ax, ay = rig.to_art(*rig.c(x, y))
        X, Y = int(ax) // D * D + adx * D, int(ay) // D * D + ady * D     # one art px, on the art grid
        ImageDraw.Draw(f1).rectangle([X, Y, X + D - 1, Y + D - 1], fill=tuple(rgb) + (255,))
    f1 = rimD(f1)
    w, h = f0.size
    strip([f0, f1]).save(os.path.join(OUT, f'source_{sid}.png'))
    # the shop icon + silhouette are UI (Bar: the UI stays 1x chunky), so they come from a 1x render of
    # f0 (a 38-art-px rig of the same ref, the pre-density pipeline's 32 colours, so the approved icons
    # reproduce pixel for pixel): a 24x24 crop, density 1
    r1 = Rig(sid, 38, pad=(0.14, 0.0), ncolors=32)
    i0 = r1.rim(r1.down(r1.canvas()))
    iw, ih = i0.size
    S_ = 24
    cx, cy = r1.to_art(*r1.c(*cfg['icon']))
    x0 = min(max(int(round(cx)) + 1 - S_ // 2, 0), max(iw - S_, 0)) if iw >= S_ else (iw - S_) // 2
    y0 = min(max(int(round(cy)) + 1 - S_ // 2, 0), ih - S_)
    icon = _I.new('RGBA', (S_, S_), (0, 0, 0, 0))
    icon.alpha_composite(i0.crop((max(x0, 0), y0, max(x0, 0) + min(S_, iw), y0 + S_)), (max(-x0, 0), 0))
    icon.save(os.path.join(OUT, f'source_{sid}_icon.png'))
    import numpy as _np
    al = _np.asarray(icon.getchannel('A')) > 0
    near_clear = _np.zeros_like(al)            # 4-connected to a transparent px (the approved rim rule)
    pad = _np.pad(~al, 1, constant_values=False)
    for a_, b_ in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        near_clear |= pad[1 + a_:1 + a_ + S_, 1 + b_:1 + b_ + S_]
    sa = _np.zeros((S_, S_, 4), _np.uint8)
    sa[al] = SIL_FILL
    sa[al & near_clear] = RIM
    sil = _I.fromarray(sa, 'RGBA')
    sil.save(os.path.join(OUT, f'source_{sid}_icon_sil.png'))
    pts = {}
    for name, (x, y) in cfg.get('points', {}).items():
        ax, ay = rig.to_art(*rig.c(x, y))
        pts[name] = [int(round(ax)) + D, int(round(ay)) + D]
    atlas['sources'][sid] = {'file': f'source_{sid}.png', 'frames': 2, 'frameW': w, 'frameH': h, 'fps': None, 'density': D,
                             'loop': True, 'anchor': [w // 2, h - 1], 'icon': f'source_{sid}_icon.png',
                             'sil': f'source_{sid}_icon_sil.png', 'iconDensity': 1, 'points': pts,
                             'recipe': [o[0] for o in cfg['f1']], 'fallback': cfg.get('fallback')}


REFS_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'refs')
if not _only or 'dubi' in _only:
    dubi_small()
    dubi_mic()
for _n, _cfg in SOURCES.items():
    if not _only or _n in _only:
        source(_n, _cfg)
atlas['sourceAliases'] = SOURCE_ALIASES
if MISSING:
    print('money sources waiting for a ref in refs/:', ', '.join(MISSING))

_ap = os.path.join(OUT, 'atlas.json')
if os.path.exists(_ap):
    _old = json.load(open(_ap))
    for _k, _v in _old['chars'].items():
        atlas['chars'].setdefault(_k, _v)
    for _k, _v in _old.get('sources', {}).items():
        atlas['sources'].setdefault(_k, _v)
with open(_ap, 'w') as fh:
    json.dump(atlas, fh, indent=1)
print('built', {c: list(v['anims']) for c, v in atlas['chars'].items()})
