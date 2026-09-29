"""Render-down rig: animate a hi-res reference caricature, then downscale each frame to pixel art.

Every transform runs at reference resolution (1024x1536 ChatGPT refs), so each frame is a clean
downscale of a posed hi-res image. One palette per character, locked from the rest pose, keeps
colours from flickering between frames.
"""
import math, os
from PIL import Image, ImageDraw

ART = os.path.join(os.path.dirname(__file__), '..', '..')
REFS = os.path.join(ART, 'refs')


class Rig:
    def __init__(self, name, height_px, pad=(0.18, 0.22, 0.30), ncolors=44, ref=None, edits=None, recolor=None):
        """pad = (side, top-extra over crop height, unused) as fractions of crop size.
        ref   = the ref file stem when it differs from name (two figures from one ref).
        edits = [(shape, rgba | None)] applied to the ref before cropping: shape is a rect
                (x0, y0, x1, y1) or a polygon [(x, y), ...] in ref px; None erases, a colour fills
                (e.g. drop a mic stand, patching the sleeve it covered)."""
        self.name = name
        im = Image.open(os.path.join(REFS, (ref or name) + '.png')).convert('RGBA')
        for shape, col in (edits or []):
            m = Image.new('L', im.size, 0)
            if isinstance(shape[0], (tuple, list)):
                ImageDraw.Draw(m).polygon(shape, fill=255)
            else:
                ImageDraw.Draw(m).rectangle([shape[0], shape[1], shape[2] - 1, shape[3] - 1], fill=255)
            im.paste(col or (0, 0, 0, 0), (0, 0), m)
        for shape, col in (recolor or []):
            im = self._recolor(im, shape, col)
        a = im.getchannel('A').point(lambda v: 255 if v > 128 else 0)
        bb = a.getbbox()
        self.ox, self.oy = bb[0], bb[1]
        self.src = im.crop(bb)
        self.cw, self.ch = self.src.size
        self.s = height_px / self.ch                      # ref px -> art px
        self.padx = int(self.cw * pad[0])
        self.padt = int(self.ch * pad[1])
        self.W = self.cw + 2 * self.padx                  # hi-res canvas
        self.H = self.ch + self.padt
        self.aw = round(self.W * self.s)                  # art canvas
        self.ah = round(self.H * self.s)
        self.ncolors = ncolors
        self.palette = None

    @staticmethod
    def _recolor(im, shape, col):
        """Inside shape (ref px), every maroon-hued px (hue within 0.025-0.07 of red, saturation > 0.3, value < 0.75: a
        maroon folder, never the skin, whose value is higher) takes col's hue and saturation at its own value x 1.25,
        so the shading survives the swap. Additive (recolor=None changes nothing)."""
        import colorsys
        m = Image.new('L', im.size, 0)
        if isinstance(shape[0], (tuple, list)):
            ImageDraw.Draw(m).polygon(shape, fill=255)
        else:
            ImageDraw.Draw(m).rectangle([shape[0], shape[1], shape[2] - 1, shape[3] - 1], fill=255)
        th, ts, tv = colorsys.rgb_to_hsv(*[c / 255 for c in col[:3]])
        out = im.copy()
        px, mp = out.load(), m.load()
        x0, y0, x1, y1 = m.getbbox()
        for y in range(y0, y1):
            for x in range(x0, x1):
                if not mp[x, y]:
                    continue
                r, g, b, a = px[x, y]
                if not a:
                    continue
                h, s_, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
                if (h < 0.025 or h > 0.93) and s_ > 0.3 and v < 0.75:
                    nr, ng, nb = colorsys.hsv_to_rgb(th, ts, min(1.0, v * 1.25))
                    px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
        return out

    # --- coordinates: ref (original image) -> canvas (hi-res padded) -> art
    def c(self, x, y):
        return (x - self.ox + self.padx, y - self.oy + self.padt)

    def to_art(self, x, y):
        return (x * self.s, y * self.s)

    def canvas(self):
        cv = Image.new('RGBA', (self.W, self.H), (0, 0, 0, 0))
        cv.alpha_composite(self.src, (self.padx, self.padt))
        return cv

    # --- hi-res ops (operate on canvas-space images and points)
    @staticmethod
    def band(img, y0, y1):
        """Keep only rows y0 <= y < y1 (alpha-masked)."""
        m = Image.new('L', img.size, 0)
        ImageDraw.Draw(m).rectangle([0, max(0, y0), img.width, min(img.height, y1) - 1], fill=255)
        out = Image.new('RGBA', img.size, (0, 0, 0, 0))
        out.paste(img, (0, 0), m)
        return out

    def shift_above(self, img, y_cut, dy):
        """Move everything above y_cut down by dy (it overlaps what's below, so no gap opens)."""
        if dy == 0:
            return img
        lower = self.band(img, y_cut, img.height)
        upper = self.band(img, 0, y_cut)
        out = Image.new('RGBA', img.size, (0, 0, 0, 0))
        out.alpha_composite(lower)
        out.alpha_composite(upper, (0, dy))
        return out

    def rotate_region(self, img, box, pivot, deg):
        """Cut a region (rect x0,y0,x1,y1 or polygon [(x,y),...]), erase it, rotate about pivot, paste on top."""
        if deg == 0:
            return img
        m = Image.new('L', img.size, 0)
        if isinstance(box[0], (tuple, list)):
            ImageDraw.Draw(m).polygon(box, fill=255)
        else:
            ImageDraw.Draw(m).rectangle([box[0], box[1], box[2] - 1, box[3] - 1], fill=255)
        part = Image.new('RGBA', img.size, (0, 0, 0, 0))
        part.paste(img, (0, 0), m)
        base = img.copy()
        base.paste((0, 0, 0, 0), (0, 0), m)
        rot = part.rotate(deg, resample=Image.BICUBIC, center=pivot)
        base.alpha_composite(rot)
        return base

    @staticmethod
    def rot_pt(p, pivot, deg):
        a = math.radians(-deg)  # PIL rotates counter-clockwise for positive deg in screen space
        dx, dy = p[0] - pivot[0], p[1] - pivot[1]
        return (pivot[0] + dx * math.cos(a) - dy * math.sin(a),
                pivot[1] + dx * math.sin(a) + dy * math.cos(a))

    def squash(self, img, sx, sy):
        """Scale about the feet (bottom centre)."""
        if sx == 1 and sy == 1:
            return img
        w, h = img.size
        nw, nh = max(1, round(w * sx)), max(1, round(h * sy))
        sc = img.resize((nw, nh), Image.BICUBIC)
        out = Image.new('RGBA', img.size, (0, 0, 0, 0))
        out.paste(sc, ((w - nw) // 2, h - nh), sc)
        return out

    def squash_pt(self, p, sx, sy):
        cx, by = self.W / 2, self.H
        return (cx + (p[0] - cx) * sx, by + (p[1] - by) * sy)

    def mirror(self, img):
        return img.transpose(Image.FLIP_LEFT_RIGHT)

    def eyelids(self, img, eyes, skin, line=(40, 22, 18, 255), amount=1.0):
        """Close eyes: eyes = list of (cx, cy, rx, ry) in canvas space. amount 1 = shut, .5 = half."""
        d = ImageDraw.Draw(img)
        for cx, cy, rx, ry in eyes:
            top = cy - ry
            bot = cy - ry + 2 * ry * amount
            d.ellipse([cx - rx, top, cx + rx, top + 2 * ry], fill=None)
            d.rectangle([cx - rx, top, cx + rx, bot], fill=skin)
            if amount >= 0.99:
                d.line([cx - rx, cy + ry * 0.2, cx + rx, cy + ry * 0.35], fill=line, width=max(3, int(ry * 0.35)))
        return img

    # --- wave-2 ops (Dubi, the money sources). Additive: nothing above changed.
    @staticmethod
    def mask(img, shape):
        m = Image.new('L', img.size, 0)
        if isinstance(shape[0], (tuple, list)):
            ImageDraw.Draw(m).polygon(shape, fill=255)
        else:
            ImageDraw.Draw(m).rectangle([shape[0], shape[1], shape[2] - 1, shape[3] - 1], fill=255)
        return m

    def move_region(self, img, shape, dx, dy, keep=None):
        """Cut a region and paste it back offset by (dx, dy) canvas px. Holes the move opens inside
        `keep` (a shape: where the region sat over the body, not over the background) are refilled
        from the original, so a hand lowered over a torso never leaves a see-through gap."""
        if dx == 0 and dy == 0:
            return img
        m = self.mask(img, shape)
        part = Image.new('RGBA', img.size, (0, 0, 0, 0))
        part.paste(img, (0, 0), m)
        out = img.copy()
        out.paste((0, 0, 0, 0), (0, 0), m)
        moved = Image.new('RGBA', img.size, (0, 0, 0, 0))
        moved.paste(part, (dx, dy), part)
        out.alpha_composite(moved)
        if keep is not None:
            k = self.mask(img, keep)
            hole = Image.eval(out.getchannel('A'), lambda v: 255 if v == 0 else 0)
            fill = Image.composite(hole, Image.new('L', img.size, 0), k)
            out.paste(img, (0, 0), fill)
        return out

    def head_shift(self, img, y_cut, dx, dy):
        """Move everything above y_cut by (dx, dy). Upward moves stretch the seam row to close the
        gap (Sara's chin-up technique), so the neck never opens."""
        if dx == 0 and dy == 0:
            return img
        upper = self.band(img, 0, y_cut)
        lower = self.band(img, y_cut, img.height)
        out = Image.new('RGBA', img.size, (0, 0, 0, 0))
        out.alpha_composite(lower)
        if dy < 0:
            seam = img.crop((0, y_cut, img.width, y_cut + 1)).resize((img.width, -dy + 1))
            out.alpha_composite(seam, (0, y_cut + dy))
        out.paste(upper, (dx, dy), upper)
        return out

    def hinge(self, img, jaw, pivot, deg, cover, fill):
        """Rotate a jaw region about its hinge (positive = open, PIL counter-clockwise), refill the
        area it vacates with `fill`, and re-lay the `cover` region (the upper beak) from the input on
        top, so a closing jaw tucks behind it."""
        if deg == 0:
            return img
        m = self.mask(img, jaw)
        part = Image.new('RGBA', img.size, (0, 0, 0, 0))
        part.paste(img, (0, 0), m)
        out = img.copy()
        out.paste(fill, (0, 0), m)
        out.alpha_composite(part.rotate(deg, resample=Image.BICUBIC, center=pivot))
        cm = self.mask(img, cover)
        out.paste(img, (0, 0), Image.composite(img.getchannel('A'), Image.new('L', img.size, 0), cm))
        return out

    def rim(self, im, col=(214, 204, 236, 255)):
        """1 px pale rim around an art-px frame (same rule as build.py outlined(): 4-connected)."""
        a = im.getchannel('A')
        w, h = im.size
        out = Image.new('RGBA', (w + 2, h + 2), (0, 0, 0, 0))
        m = Image.new('L', out.size, 0)
        for ddx, ddy in ((0, 1), (2, 1), (1, 0), (1, 2)):
            m.paste(a, (ddx, ddy), a)
        out.paste(Image.new('RGBA', out.size, col), (0, 0), m)
        out.alpha_composite(im, (1, 1))
        return out

    # --- downscale
    def down(self, img):
        sm = img.resize((self.aw, self.ah), Image.LANCZOS)
        a = sm.getchannel('A').point(lambda v: 255 if v > 118 else 0)
        rgb = Image.new('RGB', sm.size, (0, 0, 0))
        rgb.paste(sm.convert('RGB'), (0, 0), a)
        if self.palette is None:
            self.palette = rgb.quantize(colors=self.ncolors, method=Image.MEDIANCUT)
        q = rgb.quantize(palette=self.palette, dither=Image.Dither.NONE).convert('RGBA')
        q.putalpha(a)
        return q


def strip(frames):
    w, h = frames[0].size
    s = Image.new('RGBA', (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        s.alpha_composite(f, (i * w, 0))
    return s


def pixmap(rows, pal):
    """Draw a sprite from a char grid; '.' = transparent."""
    h, w = len(rows), max(len(r) for r in rows)
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    px = im.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != '.' and ch != ' ':
                px[x, y] = pal[ch]
    return im
