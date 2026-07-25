#!/usr/bin/env python3
"""Generates the Prismabrique App Store icon (1024x1024, no alpha, no rounded corners —
Xcode/App Store apply the mask automatically) entirely with Pillow so the asset can be
produced locally without any external/paid design tools. Re-run this script any time the
color palette in Resources/GameBalance.json changes to keep the icon in sync.

Usage: python3 scripts/generate_icon.py
"""
import os
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT_PATH = os.path.join(
    os.path.dirname(__file__), "..", "Prismabrique", "Assets.xcassets", "AppIcon.appiconset", "AppIcon-1024.png"
)


def lerp(a, b, t):
    return a + (b - a) * t


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def main():
    top = hex_to_rgb("#1a1a2e")
    bottom = hex_to_rgb("#16213e")
    paddle_color = hex_to_rgb("#00ff88")
    ball_color = hex_to_rgb("#00d4ff")
    brick_colors = ["#ff477e", "#ff9f45", "#ffd166", "#a06cd5", "#4d96ff", "#00d4ff"]

    img = Image.new("RGB", (SIZE, SIZE), top)
    px = img.load()

    for y in range(SIZE):
        t = y / SIZE
        r = int(lerp(top[0], bottom[0], t))
        g = int(lerp(top[1], bottom[1], t))
        b = int(lerp(top[2], bottom[2], t))
        for x in range(SIZE):
            px[x, y] = (r, g, b)

    img = img.convert("RGBA")

    glow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    cx, cy = SIZE * 0.5, SIZE * 0.40
    for radius, alpha in [(360, 40), (260, 70), (170, 110)]:
        glow_draw.ellipse(
            [cx - radius, cy - radius, cx + radius, cy + radius],
            fill=(ball_color[0], ball_color[1], ball_color[2], alpha),
        )
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(40))
    img = Image.alpha_composite(img, glow_layer)
    draw = ImageDraw.Draw(img, "RGBA")

    rows = 3
    cols = 6
    margin_x = SIZE * 0.10
    margin_top = SIZE * 0.16
    gap = SIZE * 0.018
    brick_w = (SIZE - margin_x * 2 - gap * (cols - 1)) / cols
    brick_h = SIZE * 0.09
    for row in range(rows):
        for col in range(cols):
            color_hex = brick_colors[(row * cols + col) % len(brick_colors)]
            color = hex_to_rgb(color_hex)
            x0 = margin_x + col * (brick_w + gap)
            y0 = margin_top + row * (brick_h + gap)
            x1 = x0 + brick_w
            y1 = y0 + brick_h
            radius = brick_h * 0.22
            draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=(*color, 235))

    ball_r = SIZE * 0.095
    bx, by = SIZE * 0.5, SIZE * 0.565
    draw.ellipse([bx - ball_r, by - ball_r, bx + ball_r, by + ball_r], fill=(*ball_color, 255))
    highlight_r = ball_r * 0.35
    draw.ellipse(
        [bx - ball_r * 0.35 - highlight_r, by - ball_r * 0.4 - highlight_r,
         bx - ball_r * 0.35 + highlight_r, by - ball_r * 0.4 + highlight_r],
        fill=(255, 255, 255, 160),
    )

    paddle_w = SIZE * 0.34
    paddle_h = SIZE * 0.052
    px0 = SIZE * 0.5 - paddle_w / 2
    py0 = SIZE * 0.78
    draw.rounded_rectangle(
        [px0, py0, px0 + paddle_w, py0 + paddle_h],
        radius=paddle_h * 0.5,
        fill=(*paddle_color, 255),
    )

    final = img.convert("RGB")
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    final.save(OUT_PATH, "PNG")
    print(f"Wrote {OUT_PATH} ({final.size[0]}x{final.size[1]})")


if __name__ == "__main__":
    main()
