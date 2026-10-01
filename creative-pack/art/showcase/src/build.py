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
# Density alternates (Bar, 2026-09-29: "sharp characters on every phone"): every rendered character
# and money source is also rendered at each of these densities, from the ref (a first-generation
# render at 96·d px, never a resample of the d = 3 strips). With d 2 beside the main d 3, a sprite px
# is a whole number of device px at every art scale k that is a multiple of 2 or 3.
ALT_DENSITIES = (2,)
DENSITIES = (D,) + ALT_DENSITIES
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


def put_render(char, d, anims):
    """Write one render of a character. anims = [(anim, frames, fps, loop, events, extra)] from a
    render function of d. The main render (d == D) is <char>_<anim>.png and atlas chars[char]; an
    alternate is <char>_<anim>_d<d>.png and chars[char].densities["<d>"], with its own frame size,
    anchor and per-frame tracks (extra), in its own sprite px."""
    alt = d != D
    entry = None
    for anim, frames, fps, loop, events, extra in anims:
        name = char + '_' + anim + ('_d%d' % d if alt else '')
        strip(frames).save(os.path.join(OUT, name + '.png'))
        w, h = frames[0].size
        if entry is None:
            entry = {'frameW': w, 'frameH': h, 'anchor': [w // 2, h - 1], 'density': d, 'anims': {}}
        elif (w, h) != (entry['frameW'], entry['frameH']):
            raise SystemExit(f'{name}: frame {w}x{h} differs from the other anims\' '
                             f'{entry["frameW"]}x{entry["frameH"]}')
        entry['anims'][anim] = {'file': name + '.png', 'frames': len(frames), 'fps': fps, 'loop': loop,
                                'events': events or {}, 'density': d, **(extra or {})}
    if alt:
        atlas['chars'][char].setdefault('densities', {})[str(d)] = entry
    else:
        atlas['chars'][char] = entry


TIMING = ('frames', 'fps', 'loop', 'events')


def point_tracks(anim):
    """The names of an anim's per-frame point tracks: every key whose value is one [x, y] per frame (hatMouth,
    temple, propMouth, ...). Any name works; nothing downstream hard-codes them (pipeline sprites.is_track)."""
    n = anim.get('frames')
    return sorted(k for k, v in anim.items()
                  if isinstance(v, list) and len(v) == n and n and
                  all(isinstance(p, (list, tuple)) and len(p) == 2 and all(isinstance(c, (int, float)) for c in p) for p in v))


def same_motion(what, main, alts):
    """Fail unless every density alternate plays exactly like the main render: the same anims with the
    same frames, fps, loop and events (only pixels and sprite-px data may differ), and the same named
    point tracks / points."""
    bad = []
    for dk, v in alts.items():
        if 'anims' in main:
            if set(v['anims']) != set(main['anims']):
                bad.append(f'd{dk} anims {sorted(v["anims"])} != {sorted(main["anims"])}')
            for an, m in main['anims'].items():
                a = v['anims'].get(an, {})
                bad += [f'd{dk}.{an}.{k}: {a.get(k)} != {m[k]}' for k in TIMING if a.get(k) != m[k]]
                bad += [f'd{dk}.{an}: {k} in one render only' for k in sorted(set(point_tracks(m)) ^ set(point_tracks(a)))]
        else:
            bad += [f'd{dk}.{k}: {v.get(k)} != {main.get(k)}' for k in ('frames', 'fps', 'loop') if v.get(k) != main.get(k)]
            if set(v.get('points', {})) != set(main.get('points', {})):
                bad.append(f'd{dk} points {sorted(v.get("points", {}))} != {sorted(main.get("points", {}))}')
    if bad:
        raise SystemExit(f'{what}: a density alternate differs from the main render:\n  ' + '\n  '.join(bad))


def render_char(char, fn, avatar_args=None):
    """Render a character at every density in DENSITIES from one render function fn(d) -> (rig, anims);
    the avatars come from the main render's rig (its palette), exactly as before the alternates. A launch leader
    (cast.LEADERS) also gets <char>_avatar_pick.png (32x32) and <char>_avatar24_pick.png (24x24): the chat avatars
    with one neutral rim ring instead of their react colour (red, gold, blue, grey would read as party or bloc colours
    on the leader picker, UX rtl-map §8.3). The picker tiles and the app icon's ring use them."""
    from cast import LEADERS
    for d in DENSITIES:
        rig, anims = fn(d)
        put_render(char, d, anims)
        if d == D and avatar_args:
            avatar(rig, *avatar_args)
            if char in LEADERS:
                avatar(rig, avatar_args[0], avatar_args[1], (214, 204, 236, 255), sizes=((32, 2, '_pick'), (24, 1, '24_pick')))
                avatar_pick_xl(rig, avatar_args[0], avatar_args[1])
    snap_tracks(atlas['chars'][char])
    same_motion(char, atlas['chars'][char], atlas['chars'][char].get('densities', {}))


LANDMARK_TOL = 0.5   # art px: an alternate's track point vs the main render's, relative to the feet (pipeline check)


def snap_tracks(entry):
    """Every density alternate's point tracks agree with the main render's within LANDMARK_TOL art px relative to the
    feet (leader-select-spec §9.1). Each render places its points on its own pixels, but the two canvases round their
    width (the anchor is w // 2) and their pixels independently, which can stack to ~0.8 art px. A point past the
    tolerance is snapped to the main render's point relative to the anchor, rounded to this render's sprite px (error
    <= 0.5 / d art px). Points already inside the tolerance (all of Bibi's) are left exactly as rendered."""
    ma, md = entry['anchor'], entry['density']
    for alt in entry.get('densities', {}).values():
        aa, ad = alt['anchor'], alt['density']
        for an, m in entry['anims'].items():
            a = alt['anims'].get(an, {})
            for k in point_tracks(m):
                if k not in a:
                    continue
                for i, (p, q) in enumerate(zip(a[k], m[k])):
                    rel = [(q[j] - ma[j]) / md for j in (0, 1)]
                    off = max(abs((p[j] - aa[j]) / ad - rel[j]) for j in (0, 1))
                    if off > LANDMARK_TOL:
                        a[k][i] = [aa[j] + int(round(rel[j] * ad)) for j in (0, 1)]


def breath(i, n):
    """0/1 breathing flag: chest drops for the middle half of the cycle."""
    return 1 if n // 4 <= i < 3 * n // 4 else 0


def avatar(rig, head_box_ref, name, ring, sizes=((32, 2, ''), (24, 1, '24'))):
    """Chat avatars: head crop from the rest pose, round mask, 1px ring. 32x32 (<name>_avatar.png)
    and, for the UX's 48-logical-px chat avatar at x2, 24x24 (<name>_avatar24.png)."""
    for size, fy, suffix in sizes:
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


PICK_XL = ((96, '_pick_d3'), (64, '_pick_d2'))   # (size, suffix): the picker's XL avatars (UX mobile-first A3)


def avatar_pick_xl(rig, head_box_ref, name, ring=(214, 204, 236, 255)):
    """The leader picker's large avatars (ux/mobile-first-layout.md §5.8, A3): the same head crop, neutral ring and
    cream disc as <name>_avatar_pick.png (32), rendered from the ref at 96 px (<name>_avatar_pick_d3.png, for the
    192-logical avatar) and 64 px (<name>_avatar_pick_d2.png, for the 128-logical one), each drawn at 2 logical px per
    sprite px, so crisp at every even k. First-generation crops from the ref (never an upscale of the 32), quantised
    to the character's locked d 3 palette, binary alpha. The ring is 4 px at both sizes (8 logical, the 32's 2 px at
    x4); the face sits where the 32's does, scaled (x offset size/32, y offset size/16)."""
    for size, suffix in PICK_XL:
        u = size / 32
        cv = rig.canvas()
        x0, y0 = rig.c(head_box_ref[0], head_box_ref[1])
        x1, y1 = rig.c(head_box_ref[2], head_box_ref[3])
        side = max(x1 - x0, y1 - y0)
        fw = round(30 * u)
        crop = cv.crop((x0, y0, x0 + side, y0 + side)).resize((fw, fw), Image.LANCZOS)
        a = crop.getchannel('A').point(lambda v: 255 if v > 118 else 0)
        rgb = crop.convert('RGB').quantize(palette=rig.palette, dither=Image.Dither.NONE).convert('RGBA')
        rgb.putalpha(a)
        r = 4
        out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        d = ImageDraw.Draw(out)
        d.ellipse([0, 0, size - 1, size - 1], fill=ring)
        d.ellipse([r, r, size - 1 - r, size - 1 - r], fill=(236, 228, 214, 255))
        face = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        face.alpha_composite(rgb, (round(u), round(2 * u)))
        m = Image.new('L', (size, size), 0)
        ImageDraw.Draw(m).ellipse([r, r, size - 1 - r, size - 1 - r], fill=255)
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


def paste_c(frame, im, cx, bottom):
    """Paste im with its bottom-centre at (cx, bottom) in art px."""
    frame.alpha_composite(im, (int(round(cx - im.width / 2)), int(round(bottom - im.height)))) \
        if cx - im.width / 2 >= 0 and bottom - im.height >= 0 else \
        frame.paste(im, (int(round(cx - im.width / 2)), int(round(bottom - im.height))), im)


# ================================================================ the tap rig, shared by every leader
# Bibi's approved tap table (the Magician's squash-stretch, finger angle and hat lift per frame). Every leader's
# `tap` (cast.py TAP_DOC) plays these 8 rows at 15 fps with coins on frame 3; only the arm, the lean and the prop's
# path differ per leader, so the tap feels the same in every round (leader-select-spec §4: shared feel numbers).
TAP_SQUASH = [dict(sx=1, sy=1, ang=0, lift=0), dict(sx=1.05, sy=0.94, ang=4, lift=0, squish=2),
              dict(sx=0.97, sy=1.05, ang=-7, lift=4), dict(sx=0.99, sy=1.02, ang=-4, lift=8),
              dict(sx=1, sy=1, ang=-2, lift=7), dict(sx=1.01, sy=0.99, ang=0, lift=4),
              dict(sx=1, sy=1, ang=1, lift=1), dict(sx=1, sy=1, ang=0, lift=0)]
TAP_LEAN = [0, 0, 1, 1, 1, 0, 0, 0]          # frames that carry the recipe's head lean (the stretch)
PROP_PATH = {'held': (0, 0), 'hop': (0, -0.5), 'push': (-0.5, 0)}   # art px per art px of the table's lift


def _inside(mask, p):
    x, y = int(round(p[0])), int(round(p[1]))
    return 0 <= x < mask.width and 0 <= y < mask.height and mask.getpixel((x, y)) > 0


def temple_px(frame, eye_tops):
    """Bibi's temple rule for any render: from the screen-right eye's top (the rightmost of the transformed eye
    tops, sprite px), step right to the first clear px. One [x, y] per frame."""
    x, y = max(eye_tops, key=lambda q: q[0])
    a = frame.getchannel('A')
    X, Y = int(round(x)), int(round(y))
    X, Y = min(max(X, 0), frame.width - 1), min(max(Y, 0), frame.height - 1)
    while X < frame.width - 1 and a.getpixel((X, Y)):
        X += 1
    return [X, Y]


def prop_anchor(rig, recipe, ref_alpha):
    """The rest-pose prop point in canvas px: the recipe's hand, or `beside` (gap art px screen-left of the body's
    left edge on edge_row, at row; row None = the feet line)."""
    if recipe.get('hand'):
        return rig.c(*recipe['hand'])
    edge_row, gap, row = recipe['beside']
    xs = [x for x in range(ref_alpha.width) if ref_alpha.getpixel((x, edge_row)) > 128]
    x = rig.c(xs[0], 0)[0] - gap * rig.density / rig.s
    y = rig.H - 1 if row is None else rig.c(0, row)[1]
    return (x, y)


def leader_tracks(rig, frames, hand_pts, eye_sets):
    """Per-frame propMouth and temple in sprite px from the tracked canvas points of each frame."""
    cl = lambda v, hi: min(max(int(round(v)), 0), hi - 1)       # a floor prop sits on the feet row, inside the frame
    pm = [[cl(x, f.width), cl(y, f.height)] for f, (x, y) in zip(frames, (rig.to_art(*p) for p in hand_pts))]
    tp = [temple_px(f, [rig.to_art(*q) for q in eyes]) for f, eyes in zip(frames, eye_sets)]
    return {'propMouth': pm, 'temple': tp}


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
    anims.append(('idle', idle, 10, True, None, {'hatMouth': idle_mouth, 'temple': temples(idle), 'propMouth': idle_mouth}))

    # tap: 8 frames @15fps, squash-stretch, the hat hops off the finger; coins burst on frame 3
    T = TAP_SQUASH
    tap, hatpos = [], []
    for k in T:
        f, tip = pose(ang=k['ang'], sx=k['sx'], sy=k['sy'])
        with_hat(f, tip, k['lift'], k.get('squish', 0))
        hatpos.append(hat_mouth(tip, k['lift']))
        tap.append(f)
    anims.append(('tap', tap, 15, False, {'coins': 3}, {'hatMouth': hatpos, 'temple': temples(tap), 'propMouth': hatpos}))

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
                  {'hatMouth': crit_mouth, 'temple': temples(crit), 'propMouth': crit_mouth}))
    return rig, anims


import sys as _sys
_only = [a for a in _sys.argv[1:]]           # build.py [name ...]: re-render only these (atlas.json keeps the rest)

# Every rendered character goes through render_char: its render function takes the density d, the
# main render (D) and each ALT_DENSITIES alternate come from the same function (same motion, own pixels).
if not _only or 'bibi' in _only:
    render_char('bibi', magician, ((285, 150, 745, 610), 'bibi', (0, 56, 184, 255)))


# ================================================================ SARA
def sara(d):
    rig = Rig('sara', ART_H * d, pad=(0.20, 0.12), ncolors=NC)
    rig.density = d
    S = dict(neck=rig.c(0, 640)[1], waist=rig.c(0, 1000)[1],
             hand=(*rig.c(140, 360), *rig.c(283, 800)), pivot=rig.c(236, 815),
             eyes=[(*rig.c(440, 283), 42, 20), (*rig.c(577, 305), 50, 19)], skin=(246, 156, 108, 255))
    st = round(d / rig.s)
    spark = xd(SPARK, d)

    def pose(body=0, head=0, ang=0.0, sx=1.0, sy=1.0, blink=0.0, lift=0):
        cv = rig.canvas()
        if blink:
            rig.eyelids(cv, S['eyes'], S['skin'], amount=blink)
        cv = rig.rotate_region(cv, S['hand'], S['pivot'], ang)
        if lift:  # chin up: raise everything above the neck, stretch the seam row to close the gap
            cut = S['neck']; dy = lift * st
            upper = Rig.band(cv, 0, cut); lower = Rig.band(cv, cut, cv.height)
            seam = cv.crop((0, cut, cv.width, cut + 1)).resize((cv.width, dy + 1))
            cv = Image.new('RGBA', cv.size, (0, 0, 0, 0))
            cv.alpha_composite(lower); cv.alpha_composite(seam, (0, cut - dy))
            cv.paste(upper, (0, -dy), upper)
        cv = rig.shift_above(cv, S['neck'], head * st)
        cv = rig.shift_above(cv, S['waist'], body * st)
        cv = rig.squash(cv, sx, sy)
        return rig.down(cv)

    N = 20
    idle = []
    for i in range(N):
        b = breath(i, N)
        ang = -6 * max(0, math.sin(2 * math.pi * i / N))  # a slow sip-ward lift of the glass
        blink = {6: 0.5, 7: 1.0, 8: 0.5}.get(i, 0)
        f = pose(body=b, head=breath((i - 1) % N, N), ang=ang, blink=blink)
        if i in (2, 3, 12, 13):  # glint on the champagne glass (1x art, a d x d block per art px)
            g = rig.to_art(*rig.c(200, 400))
            paste_c(f, spark, g[0], g[1] + 2 * d)
        idle.append(f)
    # offended: chin up, a little huff, eyes shut in disdain. 12 frames @12fps
    OFF = [(0, 0, 0, 1, 1), (0, 0, 4, 1.03, 0.96), (1, 0.5, 6, 0.98, 1.03), (1, 1, 8, 1, 1.01),
           (1, 1, 8, 1, 1), (1, 1, 8, 1, 1), (1, 1, 8, 1, 1), (1, 1, 8, 1, 1), (1, 0.5, 6, 1, 1),
           (0, 0, 3, 1, 1), (0, 0, 1, 1, 1), (0, 0, 0, 1, 1)]
    off = [pose(lift=l, blink=bl, ang=a, sx=sx, sy=sy) for l, bl, a, sx, sy in OFF]
    return rig, [('idle', idle, 10, True, None, None), ('offended', off, 12, False, {'huff': 2}, None)]


if not _only or 'sara' in _only:
    render_char('sara', sara, ((300, 120, 720, 540), 'sara', (224, 96, 150, 255)))


# ================================================================ BENNETT
def bennett(d):
    from cast import BENNETT_TAP as TP
    rig = Rig('bennett', ART_H * d, pad=(0.20, 0.12), ncolors=NC)
    rig.density = d
    N_ = dict(neck=rig.c(0, 675)[1], waist=rig.c(0, 1050)[1],
              hand=(*rig.c(80, 640), *rig.c(262, 880)), pivot=rig.c(250, 880),
              eyes=[(*rig.c(390, 356), 32, 19), (*rig.c(545, 389), 36, 19)], skin=(238, 166, 118, 255))
    st = round(d / rig.s)
    hand_mask = Rig.mask(rig.canvas(), N_['hand'])
    grip = rig.c(*TP['hand'])
    log = []          # per pose: (the pen grip, the eye tops) in canvas px, for the point tracks

    def track(p, body=0, head=0, ang=0.0, sx=1.0, sy=1.0, flip=False, **_):
        x, y = p
        if ang and _inside(hand_mask, (x, y)):
            x, y = Rig.rot_pt((x, y), N_['pivot'], ang)
        if y < N_['neck']:
            y += head * st
        if y < N_['waist']:
            y += body * st
        if flip:
            x = rig.W - x
        return rig.squash_pt((x, y), sx, sy)

    def pose(body=0, head=0, ang=0.0, sx=1.0, sy=1.0, blink=0.0, flip=False, lift=0):
        k = dict(body=body, head=head, ang=ang, sx=sx, sy=sy, flip=flip)
        g = track(grip, **k)
        off = lift * d / rig.s
        log.append(((g[0] + PROP_PATH[TP['path']][0] * off, g[1] + PROP_PATH[TP['path']][1] * off),
                    [track((ex, ey - ry), **k) for ex, ey, rx, ry in N_['eyes']]))
        cv = rig.canvas()
        if blink:
            rig.eyelids(cv, N_['eyes'], N_['skin'], amount=blink)
        cv = rig.rotate_region(cv, N_['hand'], N_['pivot'], ang)
        cv = rig.shift_above(cv, N_['neck'], head * st)
        cv = rig.shift_above(cv, N_['waist'], body * st)
        if flip:
            cv = rig.mirror(cv)
        cv = rig.squash(cv, sx, sy)
        return rig.down(cv)

    def tracks(frames):
        got = log[:len(frames)]
        del log[:len(frames)]
        return leader_tracks(rig, frames, [g for g, _ in got], [e for _, e in got])

    N = 20
    idle = []
    for i in range(N):
        b = breath(i, N)
        ang = 8 * math.sin(4 * math.pi * i / N)  # the "let me explain" hand, twice per loop
        blink = {12: 0.5, 13: 1.0, 14: 0.5}.get(i, 0)
        idle.append(pose(body=b, head=breath((i - 1) % N, N), ang=ang, blink=blink))
    idle_t = tracks(idle)
    # the pledge flip: he signs, then turns to face the other way. 10 frames @12fps (play forward, then reverse)
    FL = [(1, False), (0.75, False), (0.45, False), (0.22, False),
          (0.22, True), (0.45, True), (0.75, True), (1, True)]
    flip = [pose(sx=s, sy=1 + (1 - s) * 0.04, flip=m) for s, m in FL]
    flip_t = tracks(flip)
    # tap (leader-select): the shared squash table; the explaining hand makes a signing stroke with the pen
    tap = [pose(ang=k['ang'] * TP['swing'], sx=k['sx'], sy=k['sy'], lift=k['lift']) for k in TAP_SQUASH]
    tap_t = tracks(tap)
    return rig, [('idle', idle, 10, True, None, idle_t), ('flip', flip, 12, False, {'whoosh': 3}, flip_t),
                 ('tap', tap, 15, False, {'coins': 3}, tap_t)]


if not _only or 'bennett' in _only:
    render_char('bennett', bennett, ((330, 60, 830, 560), 'bennett', (40, 70, 140, 255)))

# ================================================================ the rest of the cast (generic rig)
REFS_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'refs')
from cast import CAST


def _sh(rig, shape):
    """A landmark shape (polygon or rect, ref px) in canvas px."""
    if isinstance(shape[0], (tuple, list)):
        return [rig.c(*q) for q in shape]
    return (*rig.c(shape[0], shape[1]), *rig.c(shape[2], shape[3]))


from PIL import Image as _I

RINGS = {'hop': (242, 193, 78, 255), 'jab': (208, 42, 54, 255), 'bang': (122, 74, 40, 255),
         'sneak': (60, 60, 70, 255), 'no': (90, 90, 100, 255), 'shrug': (90, 90, 100, 255)}


def generic(name, cfg, d):
    rig = Rig(name, ART_H * d, pad=cfg.get('pad', (0.14, 0.10)), ncolors=NC)
    rig.density = d
    st = round(d / rig.s)
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
    TP = cfg.get('tap')                      # the leader's tap recipe (cast.py TAP_DOC), or None: no tap, no tracks
    blank = rig.canvas()
    arm_mask = Rig.mask(blank, box) if arm else None
    moves = [(Rig.mask(blank, _sh(rig, shp)), _sh(rig, shp), dys) for shp, dys in (TP or {}).get('moves', [])]
    grip = prop_anchor(rig, TP, _I.open(os.path.join(REFS_DIR, name + '.png')).getchannel('A')) if TP else None
    log = []

    def track(p, body=0, head=0, ang=0.0, sx=1.0, sy=1.0, dx=0, dy=0, hdx=0, mv=None, **_):
        """A canvas point through the same ops as pose(), in the same order."""
        x, y = p
        if hdx and y < neck:
            x += hdx * st
        if arm and ang and _inside(arm_mask, (x, y)):
            x, y = Rig.rot_pt((x, y), piv, ang)
        for (m, _s, _d), k in zip(moves, mv or []):
            if k and _inside(m, p):
                y += k * st
        if y < neck:
            y += head * st
        if y < waist:
            y += body * st
        x, y = rig.squash_pt((x, y), sx, sy)
        return (x + dx * st, y - dy * st)

    def pose(body=0, head=0, ang=0.0, sx=1.0, sy=1.0, blink=0.0, dx=0, dy=0, hdx=0, mv=None, lift=0):
        if TP:
            k = dict(body=body, head=head, ang=ang, sx=sx, sy=sy, dx=dx, dy=dy, hdx=hdx, mv=mv)
            g = track(grip, **k)
            off = lift * d / rig.s
            pth = PROP_PATH[TP.get('path', 'held')]
            log.append(((g[0] + pth[0] * off, g[1] + pth[1] * off),
                        [track((ex_, ey_ - ry_), **k) for ex_, ey_, rx_, ry_ in eyes]))
        cv = rig.canvas()
        if hdx:  # head turn: slide everything above the neck sideways
            up = Rig.band(cv, 0, neck); lo = Rig.band(cv, neck, cv.height)
            cv = _I.new('RGBA', cv.size, (0, 0, 0, 0)); cv.alpha_composite(lo); cv.paste(up, (hdx * st, 0), up)
        if blink:
            rig.eyelids(cv, eyes, skin, amount=blink)
        if arm and ang:
            cv = rig.rotate_region(cv, box, piv, ang)
        for (m, shp, _d), k in zip(moves, mv or []):
            if k:
                cv = rig.move_region(cv, shp, 0, k * st, keep=shp)
        cv = rig.shift_above(cv, neck, head * st)
        cv = rig.shift_above(cv, waist, body * st)
        cv = rig.squash(cv, sx, sy)
        if dx or dy:
            sh = _I.new('RGBA', cv.size, (0, 0, 0, 0)); sh.paste(cv, (dx * st, -dy * st), cv); cv = sh
        return rig.down(cv)

    def tracks(frames):
        if not TP:
            return None
        got = log[:len(frames)]
        del log[:len(frames)]
        return leader_tracks(rig, frames, [g for g, _ in got], [e for _, e in got])

    n = 20
    idle = []
    for i in range(n):
        ang = 3 * math.sin(2 * math.pi * i / n) if arm else 0
        blink = {9: 0.5, 10: 1.0, 11: 0.5}.get(i, 0)
        idle.append(pose(body=breath(i, n), head=breath((i - 1) % n, n), ang=ang, blink=blink))
    anims = [('idle', idle, 10, True, None, tracks(idle))]
    if cfg['react'] == 'no':  # a slow, final head shake
        seq = [0, 1, 1, 0, -1, -1, 0, 1, 1, 0, -1, 0]
        react = [pose(hdx=h, blink=1.0 if i in (5, 6) else 0) for i, h in enumerate(seq)]
        anims.append(('react', react, 10, False, {'no': 1}, tracks(react)))
    elif cfg['react'] == 'sneak':  # tiptoes out of the plenum, peeks back, returns
        seq = [(0, 0), (1, 1), (2, 0), (3, 1), (4, 0), (5, 1), (6, 0), (6, 0), (6, 0), (4, 0), (2, 1), (0, 0)]
        react = [pose(dx=dx, dy=dy) for dx, dy in seq]
        anims.append(('react', react, 10, False, {'step': 1}, tracks(react)))
    elif cfg['react'] == 'bang':
        seq = [(0, 1, 1), (-10, 1, 1.02), (-16, 1, 1.03), (8, 1.04, .95), (12, 1.05, .94), (6, 1, 1),
               (-10, 1, 1.02), (8, 1.04, .95), (12, 1.05, .94), (4, 1, 1), (0, 1, 1), (0, 1, 1)]
        react = [pose(ang=a, sx=sx, sy=sy) for a, sx, sy in seq]
        anims.append(('react', react, 14, False, {'bang': 4, 'bang2': 8}, tracks(react)))
    elif cfg['react'] == 'shrug':  # a second ref (cfg['shrug']) in the rest pose's ref coordinates: dip, pop into the shrug, hold, settle back
        sim = _I.open(os.path.join(REFS_DIR, cfg['shrug'] + '.png')).convert('RGBA')
        sbb = sim.getchannel('A').point(lambda v: 255 if v > 128 else 0).getbbox()
        shrug_cv = rig.canvas().copy()
        shrug_cv.paste((0, 0, 0, 0), (0, 0, *shrug_cv.size))
        shrug_cv.alpha_composite(sim.crop(sbb), (sbb[0] - rig.ox + rig.padx, sbb[1] - rig.oy + rig.padt))

        def shrug(sx=1.0, sy=1.0, dy=0):
            cv = rig.squash(shrug_cv.copy(), sx, sy)
            if dy:
                sh = _I.new('RGBA', cv.size, (0, 0, 0, 0)); sh.paste(cv, (0, -dy * st), cv); cv = sh
            return rig.down(cv)
        react = [pose(), pose(sx=1.03, sy=.96), shrug(.98, 1.03, 1), shrug(), shrug(1.0, 1.01), shrug(), shrug(),
                 shrug(1.0, 1.01), shrug(), pose(sx=1.02, sy=.98), pose(), pose()]
        anims.append(('react', react, 12, False, {'shrug': 2}, tracks(react)))
    elif cfg['react'] == 'jab':
        seq = [(0, 0, 1, 1, 0), (-6, 0, 1.02, .97, 0), (8, 0, 1, 1.01, 1), (-4, 0, 1, 1, -1), (8, 0, 1, 1.01, 1),
               (-4, 0, 1, 1, -1), (8, 0, 1, 1.01, 1), (2, 0, 1, 1, 0), (0, 0, 1, 1, 0), (0, 0, 1, 1, 0)]
        react = [pose(ang=a, sx=sx, sy=sy, dx=dx) for a, _, sx, sy, dx in seq]
        anims.append(('react', react, 14, False, {'shout': 2}, tracks(react)))
    else:
        seq = [(1, 1, 0), (1.05, .94, 0), (.97, 1.05, 2), (.99, 1.02, 4), (1, 1, 3), (1, 1, 1), (1.04, .95, 0), (1, 1, 0)]
        react = [pose(sx=sx, sy=sy, dy=dy) for sx, sy, dy in seq]
        anims.append(('react', react, 14, False, {'land': 6}, tracks(react)))
    if TP:  # the leader's tap: Bibi's table, this leader's arm, lean, nudges and prop path
        sw = TP.get('swing', 0) if arm else 0
        tap = [pose(ang=k['ang'] * sw, sx=k['sx'], sy=k['sy'], hdx=TP.get('lean', 0) * TAP_LEAN[i], lift=k['lift'],
                    mv=[dys[i] for _m, _s, dys in moves]) for i, k in enumerate(TAP_SQUASH)]
        anims.append(('tap', tap, 15, False, {'coins': 3}, tracks(tap)))
    return rig, anims


for _n, _cfg in CAST.items():
    if not _only or _n in _only:
        render_char(_n, lambda d, n=_n, c=_cfg: generic(n, c, d), (_cfg['head'], _n, RINGS[_cfg['react']]))

# ================================================================ MORDECHAI DAVID (session 5, Bar): the protest blocker
# A custom rig (mordechai.py): cut limbs posed at ref resolution for a walk, a block and a smug glance, not generic()'s
# breathing-only set. 96·d px like the rest of the cast; a neutral ring on his avatars (he is no party's partner).
from mordechai import mordechai as _mordechai, HEAD_BOX as _MD_HEAD
if not _only or 'mordechai-david' in _only:
    render_char('mordechai-david', lambda d: _mordechai(d, ART_H, NC, breath), (_MD_HEAD, 'mordechai-david', RINGS['no']))

# ================================================================ DUBI (motion/state-graph-dubi.md §1)
from cast import DUBI as DB, SOURCES, SOURCE_ALIASES


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


def dubi_mic(d):
    """96 art px, the O3b flash-card pose, mic kept. The rest pose has the beak closed; talk.f1 is the ref."""
    rig = Rig('dubi-mic', ART_H * d, pad=(0.14, 0.10), ref='dubi', ncolors=NC)
    rig.density = d
    st = round(d / rig.s)
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
    talk = [pose(), pose(beak=-DB['closed'])]
    return rig, [('idle', idle, 10, True, None, None), ('talk', talk, 16, False, None, None)]


# ================================================================ the money sources (diorama-motion.md §1)
SIL_FILL, RIM = (69, 74, 96, 255), (214, 204, 236, 255)
atlas.setdefault('sources', {})
MISSING = []


def source(sid, cfg):
    """A money source at every density in DENSITIES (the main D strip + its icons, then each alternate)."""
    if not os.path.exists(os.path.join(os.path.dirname(__file__), '..', '..', 'refs', cfg.get('ref', sid) + '.png')):
        MISSING.append(sid)
        return
    for d in DENSITIES:
        source_at(sid, cfg, d)
    main = atlas['sources'][sid]
    same_motion('source ' + sid, main, main.get('densities', {}))


def source_at(sid, cfg, d):
    """One render of a source's 2-frame strip at density d (40·d sprite px tall). The main render (d == D)
    is source_<id>.png plus the 1x icon + silhouette; an alternate is source_<id>_d<d>.png in
    atlas sources[id].densities["<d>"] with its own frame size, anchor and points."""
    D = d                                                  # this render's density (the module's D is the main)
    rig = Rig(sid, 38 * D, pad=(cfg.get('pad', 0.14), 0.0), ncolors=64,   # 38 art + the 2-art-px rim = 40 art tall (120 sprite px at 3); a wide source narrows its side pad
              ref=cfg.get('ref'), recolor=cfg.get('recolor'))
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
            src = _I.open(os.path.join(REFS_DIR, cfg.get('ref', sid) + '.png')).convert('RGB')
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
    pts = {}
    for name, (x, y) in cfg.get('points', {}).items():
        ax, ay = rig.to_art(*rig.c(x, y))
        pts[name] = [int(round(ax)) + D, int(round(ay)) + D]
    if d != DENSITIES[0]:                                  # an alternate: the strip and its own geometry only
        strip([f0, f1]).save(os.path.join(OUT, f'source_{sid}_d{d}.png'))
        atlas['sources'][sid].setdefault('densities', {})[str(d)] = {
            'file': f'source_{sid}_d{d}.png', 'frames': 2, 'frameW': w, 'frameH': h, 'fps': None, 'density': d,
            'loop': True, 'anchor': [w // 2, h - 1], 'points': pts}
        return
    strip([f0, f1]).save(os.path.join(OUT, f'source_{sid}.png'))
    # the shop icon + silhouette are UI (Bar: the UI stays 1x chunky), so they come from a 1x render of
    # f0 (a 38-art-px rig of the same ref, the pre-density pipeline's 32 colours, so the approved icons
    # reproduce pixel for pixel): a 24x24 crop, density 1
    S_ = 24
    if cfg.get('iconFit'):
        # a wide object (the submarine, the chequebook): a 24-px crop of it reads as a patch of colour, so the
        # icon is the whole object re-rendered small enough to fit (never a downscale of the 38-px render)
        for hh in range(22, 8, -1):
            r1 = Rig(sid, hh, pad=(0.0, 0.0), ncolors=32, ref=cfg.get('ref'), recolor=cfg.get('recolor'))
            i0 = r1.rim(r1.down(r1.canvas()))
            if i0.width <= S_ and i0.height <= S_:
                break
        icon = _I.new('RGBA', (S_, S_), (0, 0, 0, 0))
        icon.alpha_composite(i0, ((S_ - i0.width) // 2, S_ - i0.height))
    else:
        r1 = Rig(sid, 38, pad=(0.14, 0.0), ncolors=32, ref=cfg.get('ref'), recolor=cfg.get('recolor'))
        i0 = r1.rim(r1.down(r1.canvas()))
        iw, ih = i0.size
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
    atlas['sources'][sid] = {'file': f'source_{sid}.png', 'frames': 2, 'frameW': w, 'frameH': h, 'fps': None, 'density': D,
                             'loop': True, 'anchor': [w // 2, h - 1], 'icon': f'source_{sid}_icon.png',
                             'sil': f'source_{sid}_icon_sil.png', 'iconDensity': 1, 'points': pts,
                             'recipe': [o[0] for o in cfg['f1']], 'fallback': cfg.get('fallback')}


REFS_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'refs')
if not _only or 'dubi' in _only:
    dubi_small()                                  # 18 art px, d 1 (replaced by the 2D Artist's hand-drawn strips)
    render_char('dubi-mic', dubi_mic, (DB['avatar_head'], 'dubi', (40, 70, 140, 255)))
for _n, _cfg in SOURCES.items():
    if not _only or _n in _only:
        source(_n, _cfg)
atlas['sourceAliases'] = SOURCE_ALIASES
if MISSING:
    print('money sources waiting for a ref in refs/:', ', '.join(MISSING))

# the leaders' tap prop (leader-select-spec §5.2): which kit prop sits at which track, and whether it is baked
from cast import BENNETT_TAP, BIBI_TAP
for _n, _tp in [('bibi', BIBI_TAP), ('bennett', BENNETT_TAP)] + [(n, c['tap']) for n, c in CAST.items() if c.get('tap')]:
    if _n in atlas['chars']:
        atlas['chars'][_n]['prop'] = {'id': _tp['prop'], 'baked': bool(_tp.get('baked')),
                                      'track': _tp.get('track', 'propMouth'), 'path': _tp.get('path', 'held')}

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
