#!/usr/bin/env python3
"""Generate Press Start on-screen shells in GameSir reference colors.

Palette sampled from the physical GameSir controller photo:
  shell light grey, near-black D-pad (only a hair lighter than black),
  deep magenta face buttons, dark-grey utility controls, dark navy labels.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Resources" / "Skins"

# Exact GameSir-matched palette (photo + on-screen readability).
BODY = (214, 212, 208, 255)
BODY_DEEP = (186, 184, 180, 255)
BODY_EDGE = (156, 154, 150, 255)
MAGENTA = (122, 28, 64, 255)       # ~#7A1C40 from photo median, nudged for UI
MAGENTA_HI = (158, 48, 92, 255)
MAGENTA_LO = (86, 16, 44, 255)
DPAD = (38, 36, 34, 255)          # near-black, a hair lighter than black
DPAD_HI = (58, 56, 54, 255)
DPAD_LO = (18, 16, 14, 255)
UTILITY = (98, 96, 94, 255)       # dark grey, not black
UTILITY_HI = (128, 126, 124, 255)
SHOULDER = (88, 86, 84, 255)
SHOULDER_HI = (118, 116, 114, 255)
LABEL = (26, 28, 46, 255)


def load_layout(name: str) -> dict:
    return json.loads((OUT / f"{name}.json").read_text())


def centers(layout: dict, size: tuple[int, int]) -> dict[str, tuple[float, float, float, float]]:
    w, h = size
    out = {}
    for b in layout["buttons"]:
        out[b["btn"]] = (
            (b["x"] + b["w"] / 2) * w,
            (b["y"] + b["h"] / 2) * h,
            b["w"] * w,
            b["h"] * h,
        )
    return out


def font(size: int) -> ImageFont.ImageFont:
    for path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ):
        if Path(path).exists():
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default()


def soft_shadow(size: tuple[int, int], draw_fn, blur: float = 2.5) -> Image.Image:
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(layer))
    return layer.filter(ImageFilter.GaussianBlur(blur))


def draw_dpad(base: Image.Image, cx: float, cy: float, arm: float) -> None:
    thick = arm * 0.72

    def shadow(d: ImageDraw.ImageDraw) -> None:
        d.rounded_rectangle(
            [cx - thick / 2 + 3, cy - arm + 5, cx + thick / 2 + 3, cy + arm + 5],
            radius=thick * 0.22,
            fill=(0, 0, 0, 75),
        )
        d.rounded_rectangle(
            [cx - arm + 3, cy - thick / 2 + 5, cx + arm + 3, cy + thick / 2 + 5],
            radius=thick * 0.22,
            fill=(0, 0, 0, 75),
        )

    base.alpha_composite(soft_shadow(base.size, shadow, 3))
    d = ImageDraw.Draw(base)
    d.rounded_rectangle(
        [cx - thick / 2, cy - arm, cx + thick / 2, cy + arm],
        radius=thick * 0.22,
        fill=DPAD,
    )
    d.rounded_rectangle(
        [cx - arm, cy - thick / 2, cx + arm, cy + thick / 2],
        radius=thick * 0.22,
        fill=DPAD,
    )
    d.rounded_rectangle(
        [cx - thick / 2 + 4, cy - arm + 4, cx + thick / 2 - 7, cy - 8],
        radius=thick * 0.16,
        fill=DPAD_HI,
    )
    d.rounded_rectangle(
        [cx - arm + 4, cy - thick / 2 + 4, cx - 8, cy + thick / 2 - 7],
        radius=thick * 0.16,
        fill=DPAD_HI,
    )
    r = thick * 0.22
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=DPAD_LO)
    d.ellipse([cx - r * 0.55, cy - r * 0.55, cx + r * 0.3, cy + r * 0.15], fill=DPAD_HI)


def draw_magenta_button(base: Image.Image, cx: float, cy: float, r: float, letter: str | None) -> None:
    def shadow(d: ImageDraw.ImageDraw) -> None:
        d.ellipse([cx - r + 3, cy - r + 6, cx + r + 3, cy + r + 6], fill=(0, 0, 0, 85))

    base.alpha_composite(soft_shadow(base.size, shadow, 2.2))
    d = ImageDraw.Draw(base)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=MAGENTA_LO)
    d.ellipse([cx - r + 2, cy - r + 2, cx + r - 2, cy + r - 2], fill=MAGENTA)
    d.ellipse(
        [cx - r * 0.72, cy - r * 0.78, cx + r * 0.48, cy + r * 0.12],
        fill=MAGENTA_HI,
    )
    if letter:
        d.text((cx, cy), letter, font=font(22), fill=(255, 236, 244, 255), anchor="mm")


def draw_pill(base: Image.Image, cx: float, cy: float, w: float, h: float, angle: float = -28) -> None:
    pad = 10
    tile = Image.new("RGBA", (int(w) + pad * 2, int(h) + pad * 2), (0, 0, 0, 0))
    td = ImageDraw.Draw(tile)
    td.rounded_rectangle(
        [pad + 2, pad + 3, pad + w + 2, pad + h + 3],
        radius=h / 2,
        fill=(0, 0, 0, 70),
    )
    td.rounded_rectangle([pad, pad, pad + w, pad + h], radius=h / 2, fill=UTILITY)
    td.rounded_rectangle(
        [pad + 2, pad + 1, pad + w - 4, pad + h * 0.42],
        radius=h / 3,
        fill=UTILITY_HI,
    )
    rot = tile.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    base.alpha_composite(rot, dest=(int(cx - rot.size[0] / 2), int(cy - rot.size[1] / 2)))


def draw_circle_utility(base: Image.Image, cx: float, cy: float, r: float) -> None:
    def shadow(d: ImageDraw.ImageDraw) -> None:
        d.ellipse([cx - r + 2, cy - r + 3, cx + r + 2, cy + r + 3], fill=(0, 0, 0, 70))

    base.alpha_composite(soft_shadow(base.size, shadow, 1.6))
    d = ImageDraw.Draw(base)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=UTILITY)
    d.ellipse(
        [cx - r * 0.65, cy - r * 0.7, cx + r * 0.42, cy + r * 0.08],
        fill=UTILITY_HI,
    )


def draw_shoulder(base: Image.Image, box: tuple[float, float, float, float], label: str) -> None:
    cx, cy, bw, bh = box
    coords = [cx - bw / 2 + 8, cy - bh / 2 + 4, cx + bw / 2 - 8, cy + bh / 2 - 2]

    def shadow(d: ImageDraw.ImageDraw) -> None:
        d.rounded_rectangle(
            [coords[0] + 2, coords[1] + 3, coords[2] + 2, coords[3] + 3],
            radius=14,
            fill=(0, 0, 0, 65),
        )

    base.alpha_composite(soft_shadow(base.size, shadow, 1.8))
    d = ImageDraw.Draw(base)
    d.rounded_rectangle(coords, radius=14, fill=SHOULDER)
    d.rounded_rectangle(
        [coords[0] + 3, coords[1] + 2, coords[2] - 3, coords[1] + (coords[3] - coords[1]) * 0.4],
        radius=10,
        fill=SHOULDER_HI,
    )
    d.text((cx, cy), label, font=font(20), fill=LABEL, anchor="mm")


def paint_body(size: tuple[int, int], *, pocket: bool) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, BODY)
    # soft top-lit plastic
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for y in range(h):
        t = y / max(h - 1, 1)
        od.line([(0, y), (w, y)], fill=(0, 0, 0, int(22 * t)))
    img = Image.alpha_composite(img, overlay)
    d = ImageDraw.Draw(img)

    if pocket:
        d.line([(48, 28), (200, 28)], fill=(168, 64, 72, 255), width=2)
        d.line([(48, 32), (200, 32)], fill=(64, 84, 150, 255), width=2)
        d.line([(440, 28), (592, 28)], fill=(168, 64, 72, 255), width=2)
        d.line([(440, 32), (592, 32)], fill=(64, 84, 150, 255), width=2)
        d.text((w / 2, 30), "DOT MATRIX WITH STEREO SOUND", font=font(11), fill=LABEL, anchor="mm")
        d.text((w / 2, 58), "PRESS START", font=font(22), fill=LABEL, anchor="mm")
        for i in range(6):
            x0 = w * 0.78 + i * 10
            y0 = h * 0.72
            d.line([(x0, y0), (x0 + 28, y0 + 70)], fill=BODY_EDGE, width=5)

    # embossed brand plate (GameSir-style inset)
    plate = [w * 0.33, h * 0.89, w * 0.67, h * 0.965]
    d.rounded_rectangle(plate, radius=10, fill=BODY_DEEP)
    d.rounded_rectangle(
        [plate[0] + 2, plate[1] + 2, plate[2] - 2, plate[3] - 2],
        radius=8,
        fill=BODY,
    )
    d.text(
        ((plate[0] + plate[2]) / 2, (plate[1] + plate[3]) / 2),
        "PRESS START",
        font=font(12),
        fill=BODY_EDGE,
        anchor="mm",
    )
    return img


def generate_pocket() -> Image.Image:
    size = (640, 524)
    c = centers(load_layout("pocket"), size)
    img = paint_body(size, pocket=True)
    d = ImageDraw.Draw(img)

    dpad_cx = c["up"][0]
    dpad_cy = c["left"][1]
    arm = (c["right"][0] - c["left"][0]) / 2 + c["left"][2] * 0.15
    draw_dpad(img, dpad_cx, dpad_cy, arm)

    for key in ("a", "b"):
        cx, cy, bw, bh = c[key]
        r = min(bw, bh) * 0.38
        draw_magenta_button(img, cx, cy, r, None)
        d.text((cx + r * 0.9, cy + r * 0.95), key.upper(), font=font(20), fill=LABEL, anchor="lt")

    for key, caption in (("menu", "MENU"), ("select", "SELECT"), ("start", "START")):
        cx, cy, bw, bh = c[key]
        draw_pill(img, cx, cy, bw * 0.92, bh * 0.95, angle=-28)
        d.text((cx + 6, cy + bh * 0.95), caption, font=font(14), fill=LABEL, anchor="mt")

    return img


def generate_advance() -> Image.Image:
    size = (640, 548)
    c = centers(load_layout("advance"), size)
    img = paint_body(size, pocket=False)
    d = ImageDraw.Draw(img)

    draw_shoulder(img, c["l"], "L")
    draw_shoulder(img, c["r"], "R")

    dpad_cx = c["up"][0]
    dpad_cy = c["left"][1]
    arm = (c["right"][0] - c["left"][0]) / 2 + c["left"][2] * 0.15
    draw_dpad(img, dpad_cx, dpad_cy, arm)

    for key in ("a", "b"):
        cx, cy, bw, bh = c[key]
        r = min(bw, bh) * 0.38
        draw_magenta_button(img, cx, cy, r, key.upper())

    for key, caption in (("menu", "MENU"), ("select", "SELECT"), ("start", "START")):
        cx, cy, bw, bh = c[key]
        r = min(bw, bh) * 0.42
        draw_circle_utility(img, cx, cy, r)
        d.text((cx, cy + r + 14), caption, font=font(13), fill=LABEL, anchor="mt")

    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    pocket = generate_pocket()
    advance = generate_advance()
    pocket.save(OUT / "pocket.png")
    advance.save(OUT / "advance.png")
    print(f"wrote {OUT / 'pocket.png'} {pocket.size}")
    print(f"wrote {OUT / 'advance.png'} {advance.size}")


if __name__ == "__main__":
    main()
