"""產生「集換所」圖示資產（雙疊卡片，方向 B，深紫底）。

輸出：
  assets/icon.png             1024x1024  full-bleed，flutter_launcher_icons 的 image_path
  assets/icon_foreground.png  1024x1024  透明底、卡片縮在中央安全區，adaptive 前景
  store/play_icon_512.png        512x512    Play Console 商店圖示
  store/feature_graphic_1024x500.png 1024x500   Play 功能圖

需要 Pillow。以 4x 超取樣再縮，邊緣才乾淨。
"""

import os

from PIL import Image, ImageDraw, ImageFont

SS = 4  # supersample
BG = (75, 59, 166)          # #4B3BA6 深紫
CARD_FRONT = (255, 255, 255)
CARD_BACK = (201, 195, 242)  # #C9C3F2
BAND = BG

FONT_CJK = r"C:\Windows\Fonts\msjhbd.ttc"  # 微軟正黑體 Bold
FONT_CJK_ALT = r"C:\Windows\Fonts\msjh.ttc"


def _card(w, h, fill, band=False):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    r = int(min(w, h) * 0.13)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=r, fill=fill)
    if band:
        by = int(h * 0.78)
        bh = max(2, int(h * 0.055))
        pad = int(w * 0.16)
        d.rounded_rectangle(
            [pad, by, w - pad, by + bh], radius=bh // 2, fill=BAND
        )
    return im


def draw_cards(base, cx, cy, card_w):
    card_h = int(card_w * 1.42)
    back = _card(card_w * SS, card_h * SS, CARD_BACK).rotate(
        11, expand=True, resample=Image.BICUBIC
    )
    front = _card(card_w * SS, card_h * SS, CARD_FRONT, band=True).rotate(
        -11, expand=True, resample=Image.BICUBIC
    )
    dx = int(card_w * 0.30) * SS
    for img, sx in ((back, -dx), (front, dx)):
        x = cx * SS + sx - img.width // 2
        y = cy * SS - img.height // 2
        base.alpha_composite(img, (x, y))


def canvas(w, h, bg=None):
    return Image.new("RGBA", (w * SS, h * SS), bg + (255,) if bg else (0, 0, 0, 0))


def save(im, path, size):
    im.resize(size, Image.LANCZOS).save(path)
    print(f"   ✅ {path}  {size[0]}x{size[1]}")


def main():
    out = "../assets"
    os.makedirs(out, exist_ok=True)

    # 1. full-bleed 1024
    im = canvas(1024, 1024, BG)
    draw_cards(im, 512, 512, 300)
    save(im, f"{out}/icon.png", (1024, 1024))

    # 2. adaptive 前景：透明底、卡片縮在中央安全區
    im = canvas(1024, 1024)
    draw_cards(im, 512, 512, 250)
    save(im, f"{out}/icon_foreground.png", (1024, 1024))

    # 3. Play 512
    im = canvas(512, 512, BG)
    draw_cards(im, 256, 256, 150)
    save(im, "../store/play_icon_512.png", (512, 512))

    # 4. feature graphic 1024x500
    im = canvas(1024, 500, BG)
    draw_cards(im, 235, 250, 150)
    d = ImageDraw.Draw(im)
    fp = FONT_CJK if os.path.exists(FONT_CJK) else FONT_CJK_ALT
    f_big = ImageFont.truetype(fp, 92 * SS)
    f_sm = ImageFont.truetype(fp, 34 * SS)
    tx = 452 * SS
    d.text((tx, 96 * SS), "收藏 · 牌組 · 掃描", font=f_sm,
           fill=(201, 195, 242, 255))
    d.text((tx, 158 * SS), "繁中PTCG", font=f_big, fill=(255, 255, 255, 255))
    d.text((tx, 278 * SS), "集換所", font=f_big, fill=(255, 255, 255, 255))
    save(im, "../store/feature_graphic_1024x500.png", (1024, 500))


if __name__ == "__main__":
    main()
