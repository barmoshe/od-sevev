"""Landmarks for the rest of the cast, in reference-image pixels (1024x1536 ChatGPT refs).

neck / waist : y of the cuts used for breathing (head lags the chest by a frame)
eyes         : (cx, cy, rx, ry) per eye, for the blink
arm          : optional (x0, y0, x1, y1, pivot_x, pivot_y) region that sways in idle and jabs in react
react        : 'hop' (pleased bounce) or 'jab' (angry arm jab + shake)
head         : avatar crop box
"""
CAST = {
    'regev': dict(neck=470, waist=900, eyes=[(455, 245, 27, 14), (585, 262, 32, 14)],
                  arm=None, react='hop', head=(330, 60, 730, 460)),
    'gotliv': dict(neck=450, waist=860, eyes=[(470, 250, 30, 13), (580, 236, 27, 13)],
                   arm=(720, 340, 1012, 600, 720, 520), react='jab', head=(340, 110, 700, 470)),
    'deri': dict(neck=530, waist=960, eyes=[(470, 275, 28, 11), (592, 243, 26, 12)],
                 arm=(140, 570, 450, 790, 330, 800), react='hop', head=(300, 20, 720, 440)),
    'levin': dict(neck=690, waist=980, eyes=[(598, 430, 28, 14), (715, 445, 26, 13)],
                  arm=([(0, 0), (445, 0), (445, 200), (335, 285), (285, 470), (345, 600), (230, 650), (90, 560), (0, 300)], (300, 600)), react='bang', head=(430, 190, 810, 570)),
    'ben-gvir': dict(neck=560, waist=1000, eyes=[(420, 230, 30, 15), (583, 272, 32, 15)],
                     arm=(20, 320, 275, 660, 250, 640), react='jab', head=(330, 20, 780, 470)),
    'goldknopf': dict(neck=560, waist=1000, eyes=[(403, 288, 26, 13), (530, 305, 28, 13)],
                      arm=None, react='hop', head=(300, 40, 740, 480)),
    'gafni': dict(neck=560, waist=950, eyes=[(514, 343, 30, 14), (644, 363, 30, 14)],
                  arm=None, react='sneak', head=(330, 60, 800, 530)),
    'smotrich': dict(neck=540, waist=1000, eyes=[(378, 316, 28, 13), (486, 337, 28, 13)],
                     arm=None, react='jab', head=(130, 40, 630, 540)),
    'amsalem': dict(neck=600, waist=1000, eyes=[(394, 272, 26, 12), (511, 292, 26, 12)],
                    arm=(40, 270, 272, 600, 170, 620), react='jab', head=(270, 50, 720, 500)),
    'lapid': dict(neck=520, waist=930, eyes=[(410, 286, 24, 12), (523, 321, 24, 12)],
                  arm=(790, 700, 1006, 880, 790, 820), react='hop', head=(170, 20, 700, 550)),
    'eisenkot': dict(neck=540, waist=1000, eyes=[(398, 290, 28, 13), (520, 285, 28, 13)],
                     arm=None, react='hop', head=(150, 20, 640, 510)),
    'gantz': dict(neck=440, waist=900, eyes=[(526, 257, 24, 11), (617, 270, 24, 11)],
                  arm=(235, 555, 412, 720, 380, 560), react='jab', head=(160, 0, 560, 440)),
    'liberman': dict(neck=520, waist=1000, eyes=[(378, 277, 28, 12), (520, 288, 28, 12)],
                     arm=None, react='no', head=(130, 20, 640, 530)),
    'golan': dict(neck=520, waist=950, eyes=[(459, 289, 26, 12), (574, 312, 26, 12)],
                  arm=None, react='hop', head=(170, 20, 700, 550)),
    'abbas': dict(neck=580, waist=1000, eyes=[(449, 328, 26, 12), (587, 346, 26, 12)],
                  arm=None, react='no', head=(150, 30, 690, 570)),
    'distel': dict(neck=460, waist=900, eyes=[(403, 232, 24, 11), (537, 259, 24, 11)],
                   arm=(80, 540, 262, 770, 250, 545), react='jab', head=(150, 0, 660, 510)),
    'karhi': dict(neck=540, waist=1000, eyes=[(402, 320, 26, 12), (519, 345, 26, 12)],
                  arm=([(70, 640), (335, 575), (335, 700), (255, 965), (70, 985)], (300, 620)), react='jab',
                  head=(140, 20, 640, 520)),
    'herzog': dict(neck=560, waist=980, eyes=[(542, 294, 26, 12), (659, 310, 26, 12)],
                   arm=(40, 215, 235, 640, 200, 650), react='bang', head=(180, 20, 760, 600)),
    'trump': dict(neck=520, waist=1000, eyes=[(428, 250, 26, 12), (563, 290, 26, 12)],
                  arm=(110, 510, 335, 800, 235, 820), react='jab', head=(140, 10, 720, 590)),
    # May Golan (Bar's pick, opt1, 2026-09-29): two phantom employees float beside her. The cuts sit
    # below each ghost (left ghost y 150-495, right 575-925) so a breath never tears one in half:
    # the left ghost rides the head band, the right one the body band.
    'may-golan': dict(neck=510, waist=945, eyes=[(445, 217, 23, 12), (542, 238, 26, 12)],
                      arm=None, react='hop', head=(330, 40, 710, 420)),
}

# ---------------------------------------------------------------- Dubi (motion/state-graph-dubi.md §1)
# Two figures from refs/dubi.png (parrot at a mic stand, wing raised, facing screen-left).
# 'dubi' = small full body (18 art px) with the mic stand removed; 'dubi-mic' = the 96-px flash-card pose.
DUBI = dict(
    neck=560, waist=1000,
    eyes=[(505, 215, 38, 38), (640, 255, 62, 55)],            # the eye whites (a blink covers them)
    skin=(132, 204, 33),                                        # feather green, for eyelids and the jaw fill
    jaw=[(448, 345), (605, 335), (625, 345), (622, 420), (595, 478), (545, 500), (470, 500), (445, 470)],
    upper=[(380, 300), (410, 250), (470, 225), (545, 230), (585, 265), (605, 320), (605, 345), (560, 358),
           (490, 352), (450, 370), (430, 405), (395, 405), (378, 350)],
    hinge=(600, 345),
    closed=-38,                                                 # the rest pose: jaw rotated shut (PIL degrees)
    head=[(330, 40), (820, 40), (820, 560), (560, 590), (330, 560)],   # the small figure's head (never the wing)
    wing=[(20, 270), (260, 270), (300, 470), (300, 590), (330, 640), (410, 700), (410, 820), (150, 820), (20, 600)],
    wing_pivot=(290, 560),
    mic_arm=([(15, 280), (235, 300), (235, 720), (15, 720)], (225, 600)),   # the 96-px pose's sway (as before)
    avatar_head=(360, 30, 880, 550),
    # the mic stand, off for the small figure: (shape, fill); None erases
    no_mic=[([(300, 425), (445, 425), (445, 560), (400, 600), (300, 610)], None),   # mic head + holder
            ((318, 560, 358, 745), (15, 25, 63, 255)),                            # pole over the sleeve: patch navy
            ((318, 745, 358, 1395), None),                                         # pole below
            ((190, 1420, 480, 1500), None), ((190, 1380, 395, 1420), None)],       # the base (claws stay)
)

# ---------------------------------------------------------------- the money sources (motion/diorama-motion.md §1)
# 40 art px tall including a 1-px pale rim (the 2D Artist's hand-drawn sources match). f1 = one rig op list:
#   ('body', n)  shift_above(waist, n ap)       ('head', n) shift_above(neck, n ap)
#   ('headx', n) everything above neck, n ap sideways   ('eyelids', a)
#   ('move', shape, dx, dy, keep)  a region moved n ap; `keep` refills holes over the body
#   ('px', (x, y), rgb, (adx, ady))  one art px set after the downscale (a glint), offset in ap
# A source whose recipe landmark does not exist in its ref falls back to the bob ('body', 1) and says why.
# 'icon' = the centre of the 24x24 shop-icon crop of f0; 'points' = named landmarks exported in frame px.
SOURCES = {
    'taxpayer': dict(neck=520, waist=900, eyes=[(446, 295, 34, 20), (555, 313, 33, 19)],
                     f1=[('body', 1), ('head', 1), ('eyelids', 0.5)], points={'hand': (300, 1040)}, icon=(490, 560)),
    'hitech': dict(neck=520, waist=970,
                   f1=[('move', [(40, 550), (330, 550), (335, 690), (515, 730), (515, 800), (300, 860), (95, 860), (40, 800)],
                        0, 1, (300, 550, 520, 870)),
                       ('px', (150, 640), (214, 224, 240), (0, 1))],
                   points={'laptop': (180, 680)}, icon=(390, 560)),
    'vat': dict(waist=1400, f1=[('body', 1)], icon=(480, 700),
                fallback='the ref has no hanging "18%" tag (the plate is bolted on): bob'),
    'cigars': dict(waist=980, f1=[('body', 1)], icon=(520, 520),
                   fallback='the ref has no smoke wisp or champagne bubbles: bob'),
    'qatari': dict(neck=460, f1=[('headx', 1)], icon=(510, 480),
                   fallback='two aides, no phone: the glance is both heads leaning 1 ap toward the whisper'),
}
SOURCE_ALIASES = {'washington': 'checkbook'}       # content id -> hand-drawn source id (2D Artist)

