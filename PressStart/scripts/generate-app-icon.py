#!/usr/bin/env python3
"""Generate the Press Start app icon.

Layout follows the B / A reference: two equal magenta buttons on a light
grey plate, B under the lower-left button and A under the upper-right one.
Letters are a step heavier than a regular bold.

Icon Composer layers stay flat. Xcode 26 applies Liquid Glass (specular,
translucency, refraction) to the button layers. The letters are a separate
non-glass layer so they stay solid black. Brand PNGs and the asset-catalog
fallback include a glass preview, because those files are what you see
without Icon Composer.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
PRESS = ROOT / "PressStart"
BRAND = ROOT / "brand"
APPICONSET = PRESS / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"
ICON_PKG = PRESS / "AppIcon.icon"
ASSETS = ICON_PKG / "Assets"

# Plate and face color sampled from the B/A reference, not the old wine circle.
BODY = (191, 191, 191, 255)  # #BFBFBF
FACE = (217, 95, 156, 255)  # #D95F9C
INK = (12, 12, 12, 255)
SIZE = 1024
FONT = "/usr/share/fonts/opentype/cantarell/Cantarell-ExtraBold.otf"

# Normalized centers on the reference plate (0–1).
B_BUTTON = (0.3118, 0.4643)
A_BUTTON = (0.6874, 0.3030)
BUTTON_R = 0.1444
B_LETTER = (0.3094, 0.7115)
A_LETTER = (0.6865, 0.5737)
LETTER_H = 0.1030


def srgb(color: tuple[int, int, int, int]) -> str:
    r, g, b, a = color
    return f"extended-srgb:{r / 255:.5f},{g / 255:.5f},{b / 255:.5f},{a / 255:.5f}"


def pt(pair: tuple[float, float]) -> tuple[float, float]:
    return pair[0] * SIZE, pair[1] * SIZE


def glass_disc(radius: float, albedo: tuple[int, int, int, int]) -> Image.Image:
    """Flat Liquid Glass puck for preview PNGs. Icon Composer layers stay unshaded."""
    r = radius
    pad = int(r * 0.45) + 4
    d = int(math.ceil(r * 2 + pad * 2))
    img = Image.new("RGBA", (d, d), (0, 0, 0, 0))
    px = img.load()
    cx = cy = d / 2
    ar, ag, ab, _ = albedo
    for y in range(d):
        for x in range(d):
            dx = x + 0.5 - cx
            dy = y + 0.5 - cy
            dist = math.hypot(dx, dy)
            if dist >= r + 0.8:
                continue
            coverage = 1.0 if dist <= r - 0.6 else max(0.0, (r + 0.8 - dist) / 1.4)
            nx, ny = dx / r, dy / r
            edge = dist / r
            # Thin top rim, like Liquid Glass, instead of a spherical highlight.
            sheen = math.exp(-((ny + 0.72) ** 2) / 0.012) * math.exp(-(nx ** 2) / 0.22)
            rim = max(0.0, (edge - 0.90) / 0.10)
            rim_light = rim * (0.15 + 0.85 * max(0.0, -ny))
            shade = 0.98 - 0.04 * max(0.0, ny)
            cr = min(255.0, ar * shade + 90 * sheen + 160 * rim_light)
            cg = min(255.0, ag * shade + 50 * sheen + 110 * rim_light)
            cb = min(255.0, ab * shade + 70 * sheen + 130 * rim_light)
            alpha = int(255 * coverage * 0.94)
            px[x, y] = (int(cr), int(cg), int(cb), alpha)
    return img


def paste_center(base: Image.Image, sprite: Image.Image, cx: float, cy: float) -> None:
    base.alpha_composite(
        sprite,
        dest=(int(round(cx - sprite.size[0] / 2)), int(round(cy - sprite.size[1] / 2))),
    )


def contact_shadow(canvas: Image.Image, cx: float, cy: float, radius: float) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rx, ry = radius * 0.92, radius * 0.28
    draw.ellipse(
        [cx - rx, cy + radius * 0.72 - ry, cx + rx, cy + radius * 0.72 + ry],
        fill=(0, 0, 0, 46),
    )
    layer = layer.filter(ImageFilter.GaussianBlur(radius=radius * 0.22))
    canvas.alpha_composite(layer)


def letter_mask(char: str, height: int) -> Image.Image:
    """ExtraBold glyph, then a small dilation so the stroke is a bit heavier."""
    font = ImageFont.truetype(FONT, 640)
    scratch = Image.new("L", (800, 800), 0)
    ImageDraw.Draw(scratch).text((40, 40), char, font=font, fill=255)
    bbox = scratch.getbbox()
    if bbox is None:
        raise RuntimeError(f"font produced no glyph for {char!r}")
    glyph = scratch.crop(bbox)
    scale = height / glyph.size[1]
    resized = glyph.resize(
        (max(1, int(round(glyph.size[0] * scale))), height),
        Image.Resampling.LANCZOS,
    )
    # Three 1px dilations: ExtraBold, then a little heavier than the reference letters.
    fat = resized
    for _ in range(3):
        fat = fat.filter(ImageFilter.MaxFilter(3))
    return fat


def paste_letter(canvas: Image.Image, char: str, center: tuple[float, float], height: float) -> None:
    mask = letter_mask(char, max(1, int(round(height))))
    sprite = Image.new("RGBA", mask.size, (0, 0, 0, 0))
    ink = Image.new("RGBA", mask.size, INK)
    sprite.paste(ink, mask=mask)
    paste_center(canvas, sprite, *center)


def draw_icon(preview_glass: bool) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), BODY)
    bcx, bcy = pt(B_BUTTON)
    acx, acy = pt(A_BUTTON)
    radius = BUTTON_R * SIZE
    if preview_glass:
        contact_shadow(img, bcx, bcy, radius)
        contact_shadow(img, acx, acy, radius)
        disc = glass_disc(radius, FACE)
        paste_center(img, disc, bcx, bcy)
        paste_center(img, disc, acx, acy)
    else:
        draw = ImageDraw.Draw(img)
        for cx, cy in ((bcx, bcy), (acx, acy)):
            draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=FACE)
    cap = LETTER_H * SIZE
    paste_letter(img, "B", pt(B_LETTER), cap)
    paste_letter(img, "A", pt(A_LETTER), cap)
    return img


def ios_squircle_mask(size: int = SIZE) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1],
        radius=size * 0.2237,
        fill=255,
    )
    return mask


def flat_circle_layer(cx: float, cy: float, radius: float) -> Image.Image:
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        fill=FACE,
    )
    return layer


def letters_layer() -> Image.Image:
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cap = LETTER_H * SIZE
    paste_letter(layer, "B", pt(B_LETTER), cap)
    paste_letter(layer, "A", pt(A_LETTER), cap)
    return layer


def write_svg_circle(path: Path, cx: float, cy: float, radius: float) -> None:
    r, g, b, _ = FACE
    path.write_text(
        f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <circle cx="{cx:.2f}" cy="{cy:.2f}" r="{radius:.2f}" fill="#{r:02X}{g:02X}{b:02X}"/>
</svg>
"""
    )


def write_layers() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    for stale in (
        "01-select-pill.svg",
        "01-select-pill.png",
        "02-action-circle.svg",
        "02-action-circle.png",
    ):
        target = ASSETS / stale
        if target.exists():
            target.unlink()

    bcx, bcy = pt(B_BUTTON)
    acx, acy = pt(A_BUTTON)
    radius = BUTTON_R * SIZE
    write_svg_circle(ASSETS / "01-b-button.svg", bcx, bcy, radius)
    write_svg_circle(ASSETS / "02-a-button.svg", acx, acy, radius)
    flat_circle_layer(bcx, bcy, radius).save(ASSETS / "01-b-button.png")
    flat_circle_layer(acx, acy, radius).save(ASSETS / "02-a-button.png")
    letters_layer().save(ASSETS / "03-letters.png")


def write_icon_json() -> None:
    doc = {
        "fill": {"solid": srgb(BODY)},
        "features": ["refractivity", "specular-location"],
        "groups": [
            {
                "name": "Buttons",
                "lighting": "individual",
                "specular": True,
                "specular-highlight-placement": "outside",
                "shadow": {"kind": "neutral", "opacity": 0.35},
                "translucency": {"enabled": True, "value": 0.22},
                "refractivity": {"enabled": True, "depth": 0.55, "strength": 0.7},
                "blur-material": 0.35,
                "layers": [
                    {"name": "B button", "image-name": "01-b-button.svg", "glass": True},
                    {"name": "A button", "image-name": "02-a-button.svg", "glass": True},
                ],
            },
            {
                "name": "Letters",
                "specular": False,
                "shadow": {"kind": "none", "opacity": 0},
                "translucency": {"enabled": False, "value": 0},
                "layers": [
                    {"name": "B and A", "image-name": "03-letters.png", "glass": False},
                ],
            },
        ],
        "supported-platforms": {"squares": ["iOS"]},
    }
    ICON_PKG.mkdir(parents=True, exist_ok=True)
    (ICON_PKG / "icon.json").write_text(json.dumps(doc, indent=2) + "\n")


def write_favicon() -> None:
    # 64px mark: same two buttons and heavier letters, no glass (too small).
    (ROOT / "favicon.svg").write_text(
        """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <rect width="64" height="64" rx="14" fill="#BFBFBF"/>
  <circle cx="20.0" cy="29.7" r="9.2" fill="#D95F9C"/>
  <circle cx="44.0" cy="19.4" r="9.2" fill="#D95F9C"/>
  <text x="19.8" y="49.6" text-anchor="middle" font-family="Arial Black, Cantarell, sans-serif" font-size="9.2" font-weight="800" fill="#0C0C0C">B</text>
  <text x="43.9" y="40.8" text-anchor="middle" font-family="Arial Black, Cantarell, sans-serif" font-size="9.2" font-weight="800" fill="#0C0C0C">A</text>
</svg>
"""
    )


def apply_squircle(src: Image.Image) -> Image.Image:
    out = src.convert("RGBA")
    out.putalpha(ios_squircle_mask(src.size[0]))
    return out


def main() -> None:
    BRAND.mkdir(parents=True, exist_ok=True)
    APPICONSET.mkdir(parents=True, exist_ok=True)

    preview = draw_icon(preview_glass=True)
    preview.convert("RGB").save(APPICONSET / "AppIcon.png", optimize=True)
    preview.convert("RGB").save(BRAND / "press-start-icon.png", optimize=True)
    preview.convert("RGB").save(BRAND / "press-start-logo.png", optimize=True)

    squircle = apply_squircle(preview)
    squircle.save(BRAND / "press-start-icon-squircle.png", optimize=True)
    pad = 38
    readme = Image.new("RGBA", (SIZE + pad * 2, SIZE + pad * 2), (0, 0, 0, 0))
    readme.paste(squircle, (pad, pad), squircle)
    readme.save(BRAND / "press-start-icon-readme.png", optimize=True)

    write_layers()
    write_icon_json()
    write_favicon()
    print(f"wrote {APPICONSET / 'AppIcon.png'}")
    print(f"wrote {ICON_PKG}")


if __name__ == "__main__":
    main()
