#!/usr/bin/env python3
"""Generate the 1024x500 Google Play feature graphic for Calvin Chess Trainer.

Requires Pillow.  Run from the repo root:
    python3 scripts/make_feature_graphic.py

Writes: resources/store/android/feature-graphic-1024x500.png

Brand colours are sampled from the shipped app icon and home screen, so the
graphic stays in sync with the app's real palette.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1024, 500

# --- brand palette (sampled from assets/images/app_icon.png + home screen) ---
GREEN_DARK = (18, 58, 21)
GREEN_MID = (29, 88, 32)
GREEN_LIGHT = (44, 126, 48)
CREAM = (247, 251, 241)
CREAM_DIM = (206, 224, 203)
# Chips hint at the four trainers. Chess Notation's real card colour is a dark
# green (30, 96, 35) which vanishes against this green background, so the chip
# uses a brightened tint of the same hue purely for contrast.
TRAINER_COLORS = [(5, 121, 190), (124, 199, 88), (108, 30, 155), (230, 83, 3)]

TITLE_FONT = "assets/fonts/BradBunR.ttf"
BODY_FONT = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"
ICON_SRC = "assets/images/app_icon.png"
OUT = "resources/store/android/feature-graphic-1024x500.png"


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def diagonal_gradient(w, h, c0, c1, small=(128, 64)):
    """Smooth diagonal gradient, computed small then upscaled."""
    sw, sh = small
    g = Image.new("RGB", (sw, sh))
    px = g.load()
    for y in range(sh):
        for x in range(sw):
            px[x, y] = lerp(c0, c1, (x / (sw - 1) + y / (sh - 1)) / 2)
    return g.resize((w, h), Image.BICUBIC)


def fit_font(path, text, max_w, start=110, floor=28):
    """Largest font size at which `text` fits within max_w."""
    for size in range(start, floor, -2):
        f = ImageFont.truetype(path, size)
        if f.getbbox(text)[2] - f.getbbox(text)[0] <= max_w:
            return f
    return ImageFont.truetype(path, floor)


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *[s - 1 for s in img.size]], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def main():
    base = diagonal_gradient(W, H, GREEN_DARK, GREEN_LIGHT)

    # subtle chessboard texture
    tex = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    td = ImageDraw.Draw(tex)
    sq = 50
    for row in range(H // sq + 1):
        for col in range(W // sq + 1):
            if (row + col) % 2 == 0:
                td.rectangle([col * sq, row * sq, col * sq + sq, row * sq + sq],
                             fill=(255, 255, 255, 10))
    base = Image.alpha_composite(base.convert("RGBA"), tex)

    # --- app icon badge, left ---
    ICON, IX, IY = 300, 62, 100
    icon = Image.open(ICON_SRC).convert("RGB").resize((ICON, ICON), Image.LANCZOS)
    icon = rounded(icon, 56)

    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [IX + 6, IY + 10, IX + ICON + 6, IY + ICON + 10], 56, fill=(0, 0, 0, 130))
    base = Image.alpha_composite(base, shadow.filter(ImageFilter.GaussianBlur(14)))

    # cream ring so the green tile separates from the green background
    ring = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(ring).rounded_rectangle(
        [IX - 5, IY - 5, IX + ICON + 5, IY + ICON + 5], 61, fill=(*CREAM, 235))
    base = Image.alpha_composite(base, ring)
    base.paste(icon, (IX, IY), icon)

    d = ImageDraw.Draw(base)

    # --- text block, right ---
    TX = 430
    avail = W - TX - 50
    f1 = fit_font(TITLE_FONT, "Calvin Chess", avail, start=104)
    f2 = fit_font(TITLE_FONT, "Trainer", avail, start=104)
    f_tag = fit_font(BODY_FONT, "Master the fundamentals!", avail, start=40, floor=20)

    y = 96
    for text, f in ((("Calvin Chess"), f1), (("Trainer"), f2)):
        b = f.getbbox(text)
        d.text((TX - b[0], y - b[1]), text, font=f, fill=CREAM)
        y += (b[3] - b[1]) + 22

    y += 12
    b = f_tag.getbbox("Master the fundamentals!")
    d.text((TX - b[0], y - b[1]), "Master the fundamentals!", font=f_tag, fill=CREAM_DIM)
    y += (b[3] - b[1]) + 30

    # --- four trainer colour chips ---
    cw, ch, gap = 78, 12, 14
    for i, c in enumerate(TRAINER_COLORS):
        x0 = TX + i * (cw + gap)
        d.rounded_rectangle([x0, y, x0 + cw, y + ch], ch // 2, fill=c)

    base.convert("RGB").save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT}  {Image.open(OUT).size}")


if __name__ == "__main__":
    main()
