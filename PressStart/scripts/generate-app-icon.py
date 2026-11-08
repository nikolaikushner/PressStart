#!/usr/bin/env python3
"""Generate the Press Start app icon from the Game Boy reference photo.

Shell, D-pad, and face buttons use colors sampled from that photo. Select and
Start are the larger light-grey pills, tilted so the right end sits higher.
The face buttons are the only Liquid Glass layers. The D-pad and pills stay
matte so Icon Composer does not turn them into glass.

Brand PNGs, the asset-catalog fallback, and PressStart/AppIcon.icon all come
from this script. The pocket shell is the photo itself.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
PRESS = ROOT / "PressStart"
BRAND = ROOT / "brand"
APPICONSET = PRESS / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"
ICON_PKG = PRESS / "AppIcon.icon"
ASSETS = ICON_PKG / "Assets"

# Sampled from the Game Boy photo: shell face, button body, blue-black cross.
BODY = (196, 195, 191, 255)  # #C4C3BF
FACE = (140, 22, 78, 255)  # #8C164E
FACE_HI = (210, 70, 130, 255)
DPAD = (32, 34, 42, 255)  # near-black, a cool hair lighter
DPAD_HI = (54, 56, 66, 255)
DPAD_LO = (14, 16, 22, 255)
PILL = (148, 146, 144, 255)  # light grey recess, not black
PILL_HI = (196, 194, 190, 255)
SIZE = 1024

# Control cluster from the photo, kept in proportion and centered on the square.
# Select/Start are larger than the old slivers and tilt the other way (right end up).
DPAD_C = (0.197, 0.428)
DPAD_ARM = 0.127
DPAD_THICK_RATIO = 0.80
B_BUTTON = (0.705, 0.456)
A_BUTTON = (0.870, 0.379)
BUTTON_R = 0.060
PILL_L = (0.354, 0.658)
PILL_R = (0.534, 0.657)
PILL_W = 0.150
PILL_H = 0.046
# PIL rotates counter-clockwise. Positive lifts the right end.
PILL_ANGLE = 24.0


def srgb(color: tuple[int, int, int, int]) -> str:
    r, g, b, a = color
    return f"extended-srgb:{r / 255:.5f},{g / 255:.5f},{b / 255:.5f},{a / 255:.5f}"


def pt(pair: tuple[float, float]) -> tuple[float, float]:
    return pair[0] * SIZE, pair[1] * SIZE


def hex_rgb(color: tuple[int, int, int, int]) -> str:
    r, g, b, _ = color
    return f"#{r:02X}{g:02X}{b:02X}"


def glass_disc(radius: float, albedo: tuple[int, int, int, int]) -> Image.Image:
    """Flat glass puck for preview PNGs. Icon Composer layers stay unshaded."""
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
            sheen = math.exp(-((ny + 0.72) ** 2) / 0.012) * math.exp(-(nx ** 2) / 0.22)
            rim = max(0.0, (edge - 0.90) / 0.10)
            rim_light = rim * (0.15 + 0.85 * max(0.0, -ny))
            mix = min(1.0, 0.55 * sheen + 0.70 * rim_light)
            shade = 0.96 - 0.10 * max(0.0, ny)
            px[x, y] = (
                int(min(255.0, ar * shade * (1.0 - mix) + FACE_HI[0] * mix)),
                int(min(255.0, ag * shade * (1.0 - mix) + FACE_HI[1] * mix)),
                int(min(255.0, ab * shade * (1.0 - mix) + FACE_HI[2] * mix)),
                int(255 * coverage * 0.96),
            )
    return img


def paste_center(base: Image.Image, sprite: Image.Image, cx: float, cy: float) -> None:
    base.alpha_composite(
        sprite,
        dest=(int(round(cx - sprite.size[0] / 2)), int(round(cy - sprite.size[1] / 2))),
    )


def contact_shadow(canvas: Image.Image, cx: float, cy: float, radius: float) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rx, ry = radius * 0.92, radius * 0.22
    draw.ellipse(
        [cx - rx, cy + radius * 0.55 - ry, cx + rx, cy + radius * 0.55 + ry],
        fill=(0, 0, 0, 40),
    )
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius=radius * 0.18)))


def dpad_box() -> tuple[float, float, float, float]:
    cx, cy = pt(DPAD_C)
    arm = DPAD_ARM * SIZE
    thick = arm * DPAD_THICK_RATIO
    return cx, cy, arm, thick


def draw_dpad(canvas: Image.Image, *, molded: bool) -> None:
    """Chunky Game Boy cross: broad arms, rounded ends, center dish."""
    cx, cy, arm, thick = dpad_box()
    radius = thick * 0.24
    if molded:
        shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow)
        sd.rounded_rectangle(
            [cx - thick / 2 + 4, cy - arm + 8, cx + thick / 2 + 4, cy + arm + 8],
            radius=radius,
            fill=(0, 0, 0, 70),
        )
        sd.rounded_rectangle(
            [cx - arm + 4, cy - thick / 2 + 8, cx + arm + 4, cy + thick / 2 + 8],
            radius=radius,
            fill=(0, 0, 0, 70),
        )
        canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(radius=thick * 0.12)))
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(
        [cx - thick / 2, cy - arm, cx + thick / 2, cy + arm],
        radius=radius,
        fill=DPAD,
    )
    draw.rounded_rectangle(
        [cx - arm, cy - thick / 2, cx + arm, cy + thick / 2],
        radius=radius,
        fill=DPAD,
    )
    if molded:
        lip = thick * 0.16
        draw.rounded_rectangle(
            [cx - thick / 2 + lip, cy - arm + lip, cx + thick / 2 - lip, cy - arm + thick * 0.42],
            radius=radius * 0.6,
            fill=DPAD_HI,
        )
        draw.rounded_rectangle(
            [cx - arm + lip, cy - thick / 2 + lip, cx - arm + thick * 0.42, cy + thick / 2 - lip],
            radius=radius * 0.6,
            fill=DPAD_HI,
        )
    dish = thick * 0.20
    draw.ellipse([cx - dish, cy - dish, cx + dish, cy + dish], fill=DPAD_LO)
    if molded:
        draw.ellipse(
            [cx - dish * 0.45, cy - dish * 0.55, cx + dish * 0.28, cy + dish * 0.12],
            fill=DPAD_HI,
        )


def draw_pill(
    canvas: Image.Image,
    center: tuple[float, float],
    color: tuple[int, int, int, int],
    highlight: tuple[int, int, int, int] | None = None,
) -> None:
    cx, cy = pt(center)
    w, h = PILL_W * SIZE, PILL_H * SIZE
    pad = 6
    tile = Image.new("RGBA", (int(w) + pad * 2, int(h) + pad * 2), (0, 0, 0, 0))
    td = ImageDraw.Draw(tile)
    td.rounded_rectangle([pad, pad, pad + w, pad + h], radius=h / 2, fill=color)
    if highlight is not None:
        td.rounded_rectangle(
            [pad + 2, pad + 1, pad + w - 2, pad + h * 0.46],
            radius=h * 0.35,
            fill=highlight,
        )
    rot = tile.rotate(PILL_ANGLE, resample=Image.Resampling.BICUBIC, expand=True)
    paste_center(canvas, rot, cx, cy)


def draw_icon(preview_glass: bool) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), BODY)
    draw_dpad(img, molded=preview_glass)
    draw_pill(img, PILL_L, PILL, PILL_HI if preview_glass else None)
    draw_pill(img, PILL_R, PILL, PILL_HI if preview_glass else None)
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
    return img


def ios_squircle_mask(size: int = SIZE) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1],
        radius=size * 0.2237,
        fill=255,
    )
    return mask


def svg_doc(body: str) -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">\n'
        f"{body}</svg>\n"
    )


def write_layers() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    for stale in ASSETS.iterdir():
        if stale.is_file():
            stale.unlink()

    cx, cy, arm, thick = dpad_box()
    radius = thick * 0.24
    dish = thick * 0.20
    dpad = svg_doc(
        f'  <rect x="{cx - thick / 2:.2f}" y="{cy - arm:.2f}" width="{thick:.2f}" height="{arm * 2:.2f}" rx="{radius:.2f}" fill="{hex_rgb(DPAD)}"/>\n'
        f'  <rect x="{cx - arm:.2f}" y="{cy - thick / 2:.2f}" width="{arm * 2:.2f}" height="{thick:.2f}" rx="{radius:.2f}" fill="{hex_rgb(DPAD)}"/>\n'
        f'  <circle cx="{cx:.2f}" cy="{cy:.2f}" r="{dish:.2f}" fill="{hex_rgb(DPAD_LO)}"/>\n'
    )
    (ASSETS / "01-dpad.svg").write_text(dpad)

    bcx, bcy = pt(B_BUTTON)
    acx, acy = pt(A_BUTTON)
    br = BUTTON_R * SIZE
    (ASSETS / "02-b-button.svg").write_text(
        svg_doc(f'  <circle cx="{bcx:.2f}" cy="{bcy:.2f}" r="{br:.2f}" fill="{hex_rgb(FACE)}"/>\n')
    )
    (ASSETS / "03-a-button.svg").write_text(
        svg_doc(f'  <circle cx="{acx:.2f}" cy="{acy:.2f}" r="{br:.2f}" fill="{hex_rgb(FACE)}"/>\n')
    )

    def pill_svg(center: tuple[float, float]) -> str:
        px, py = pt(center)
        w, h = PILL_W * SIZE, PILL_H * SIZE
        return (
            f'  <g transform="translate({px:.2f} {py:.2f}) rotate({-PILL_ANGLE:.2f})">\n'
            f'    <rect x="{-w / 2:.2f}" y="{-h / 2:.2f}" width="{w:.2f}" height="{h:.2f}" rx="{h / 2:.2f}" fill="{hex_rgb(PILL)}"/>\n'
            f"  </g>\n"
        )

    (ASSETS / "04-pills.svg").write_text(svg_doc(pill_svg(PILL_L) + pill_svg(PILL_R)))

    flat = draw_icon(preview_glass=False)
    # Split the flat mark into the layer PNGs Icon Composer can use as fallbacks.
    transparent = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    dpad_png = transparent.copy()
    draw_dpad(dpad_png, molded=False)
    dpad_png.save(ASSETS / "01-dpad.png")
    for name, center in (("02-b-button.png", B_BUTTON), ("03-a-button.png", A_BUTTON)):
        layer = transparent.copy()
        x, y = pt(center)
        ImageDraw.Draw(layer).ellipse([x - br, y - br, x + br, y + br], fill=FACE)
        layer.save(ASSETS / name)
    pills = transparent.copy()
    draw_pill(pills, PILL_L, PILL)
    draw_pill(pills, PILL_R, PILL)
    pills.save(ASSETS / "04-pills.png")
    # Keep `flat` referenced so a future edit doesn't drop the composite check.
    assert flat.getpixel((int(cx), int(cy)))[0] < 80


def write_icon_json() -> None:
    matte = {
        "specular": False,
        "shadow": {"kind": "neutral", "opacity": 0.18},
        "translucency": {"enabled": False, "value": 0},
    }
    doc = {
        "fill": {"solid": srgb(BODY)},
        "features": ["refractivity", "specular-location"],
        "groups": [
            {
                "name": "Matte controls",
                **matte,
                "layers": [
                    {"name": "D-pad", "image-name": "01-dpad.svg", "glass": False},
                    {"name": "Select and Start", "image-name": "04-pills.svg", "glass": False},
                ],
            },
            {
                "name": "Face buttons",
                "lighting": "individual",
                "specular": True,
                "specular-highlight-placement": "outside",
                "shadow": {"kind": "neutral", "opacity": 0.35},
                "translucency": {"enabled": True, "value": 0.22},
                "refractivity": {"enabled": True, "depth": 0.55, "strength": 0.7},
                "blur-material": 0.35,
                "layers": [
                    {"name": "B button", "image-name": "02-b-button.svg", "glass": True},
                    {"name": "A button", "image-name": "03-a-button.svg", "glass": True},
                ],
            },
        ],
        "supported-platforms": {"squares": ["iOS"]},
    }
    ICON_PKG.mkdir(parents=True, exist_ok=True)
    (ICON_PKG / "icon.json").write_text(json.dumps(doc, indent=2) + "\n")


def write_favicon() -> None:
    body = hex_rgb(BODY)
    dpad = hex_rgb(DPAD)
    dish = hex_rgb(DPAD_LO)
    face = hex_rgb(FACE)
    pill = hex_rgb(PILL)
    (ROOT / "favicon.svg").write_text(
        f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <rect width="64" height="64" rx="14" fill="{body}"/>
  <rect x="8.6" y="18.6" width="6.4" height="18.2" rx="2.0" fill="{dpad}"/>
  <rect x="2.7" y="24.5" width="18.2" height="6.4" rx="2.0" fill="{dpad}"/>
  <circle cx="11.8" cy="27.7" r="1.3" fill="{dish}"/>
  <circle cx="45.1" cy="29.2" r="3.8" fill="{face}"/>
  <circle cx="55.7" cy="24.3" r="3.8" fill="{face}"/>
  <g transform="translate(22.7 42.1) rotate(-24)">
    <rect x="-4.8" y="-1.5" width="9.6" height="2.9" rx="1.45" fill="{pill}"/>
  </g>
  <g transform="translate(34.2 42.0) rotate(-24)">
    <rect x="-4.8" y="-1.5" width="9.6" height="2.9" rx="1.45" fill="{pill}"/>
  </g>
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
