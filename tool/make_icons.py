"""Genereert het Regretto-logo (favicon + PWA-iconen) met Inter Black.

Merkteken: verloop koraal -> indigo, met een wit, licht gekanteld kaartje
en een "R". Gebruik: python3 tool/make_icons.py
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONT = 'assets/fonts/Inter-Black.ttf'
CORAL = (242, 97, 75)
INDIGO = (75, 74, 232)
INK = (27, 31, 42)
GREEN = (20, 184, 122)


def gradient(size):
    img = Image.new('RGB', (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size - 2)
            px[x, y] = tuple(int(CORAL[i] * (1 - t) + INDIGO[i] * t) for i in range(3))
    return img


def mark(size, maskable=False):
    s = size * 4  # supersample
    bg = gradient(s).convert('RGBA')
    mask = Image.new('L', (s, s), 0)
    d = ImageDraw.Draw(mask)
    if maskable:
        d.rectangle([0, 0, s, s], fill=255)
    else:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.27), fill=255)
    out = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    out.paste(bg, (0, 0), mask)

    scale = 0.72 if maskable else 1.0
    cw, ch = int(s * 0.50 * scale), int(s * 0.62 * scale)
    card = Image.new('RGBA', (cw, ch), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle([0, 0, cw - 1, ch - 1], radius=int(cw * 0.2), fill=(255, 255, 255, 255))
    font = ImageFont.truetype(FONT, int(ch * 0.62))
    bbox = cd.textbbox((0, 0), 'R', font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    cd.text(((cw - tw) / 2 - bbox[0], (ch - th) / 2 - bbox[1] - ch * 0.03), 'R', font=font, fill=INK)
    r = int(cw * 0.09)
    cd.ellipse([cw - r * 3.2, ch - r * 3.2, cw - r * 1.2, ch - r * 1.2], fill=GREEN)
    card = card.rotate(-10, resample=Image.BICUBIC, expand=True)
    shadow = Image.new('RGBA', card.size, (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 90), (0, 0), card.split()[3])
    shadow = shadow.filter(ImageFilter.GaussianBlur(s * 0.02))
    x, y = (s - card.width) // 2, (s - card.height) // 2
    out.alpha_composite(shadow, (x, y + int(s * 0.025)))
    out.alpha_composite(card, (x, y))
    return out.resize((size, size), Image.LANCZOS)


mark(32).save('web/favicon.png')
mark(192).save('web/icons/Icon-192.png')
mark(512).save('web/icons/Icon-512.png')
mark(192, maskable=True).save('web/icons/Icon-maskable-192.png')
mark(512, maskable=True).save('web/icons/Icon-maskable-512.png')
mark(1024).save('assets/brand_regretto_mark.png')
print('ok')
