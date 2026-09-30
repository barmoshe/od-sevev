"""Decode the game's Godot AudioStreamWAV .res files (QOA inside) to plain .wav.

    python3 store/teaser/src/res2wav.py <in.res> <out.wav>
"""
import struct
import sys
import wave

SF = [1, 7, 21, 45, 84, 138, 211, 304, 421, 562, 731, 928, 1157, 1419, 1715, 2048]
DQT = [0.75, -0.75, 2.5, -2.5, 4.5, -4.5, 7, -7]


def _round(x):
    return int(x + 0.5) if x >= 0 else -int(-x + 0.5)


DEQ = [[_round(s * q) for q in DQT] for s in SF]


def decode_qoa(b):
    assert b[:4] == b"qoaf", b[:4]
    total = struct.unpack(">I", b[4:8])[0]
    p = 8
    out, rate, chans = [], None, None
    while p < len(b) and (total == 0 or len(out) < total * (chans or 1)):
        ch = b[p]; rate = int.from_bytes(b[p + 1:p + 4], "big")
        fs, fsize = struct.unpack(">HH", b[p + 4:p + 8])
        chans = ch
        q = p + 8
        hist, wts = [], []
        for c in range(ch):
            hist.append(list(struct.unpack(">4h", b[q:q + 8]))); q += 8
            wts.append(list(struct.unpack(">4h", b[q:q + 8]))); q += 8
        frame = [0] * (fs * ch)
        for s0 in range(0, fs, 20):
            for c in range(ch):
                sl = int.from_bytes(b[q:q + 8], "big"); q += 8
                deq = DEQ[sl >> 60]
                h, w = hist[c], wts[c]
                for i in range(s0, min(s0 + 20, fs)):
                    r = deq[(sl >> 57) & 7]
                    sl = (sl << 3) & 0xFFFFFFFFFFFFFFFF
                    pred = (w[0] * h[0] + w[1] * h[1] + w[2] * h[2] + w[3] * h[3]) >> 13
                    v = max(-32768, min(32767, pred + r))
                    d = r >> 4
                    w[0] += -d if h[0] < 0 else d
                    w[1] += -d if h[1] < 0 else d
                    w[2] += -d if h[2] < 0 else d
                    w[3] += -d if h[3] < 0 else d
                    h[0], h[1], h[2], h[3] = h[1], h[2], h[3], v
                    frame[i * ch + c] = v
        out.extend(frame)
        p += fsize
    return out, rate, chans


def main(src, dst):
    d = open(src, "rb").read()
    i = d.index(b"qoaf")
    samples, rate, ch = decode_qoa(d[i:])
    with wave.open(dst, "wb") as w:
        w.setnchannels(ch); w.setsampwidth(2); w.setframerate(rate)
        w.writeframes(struct.pack("<%dh" % len(samples), *samples))
    print(f"{dst}: {len(samples)//ch/rate:.2f}s {rate}Hz x{ch}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
