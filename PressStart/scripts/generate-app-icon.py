#!/usr/bin/env python3
"""Generate Press Start app icon artwork.

Flat brand mark: GameSir shell grey background, charcoal angled pill +
magenta circle (Select + A metaphor). Also writes Icon Composer layers
for Liquid Glass in Xcode / Icon Composer.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
PRESS = ROOT / "PressStart"
BRAND = ROOT / "brand"
APPICONSET = PRESS / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"
ICON_PKG = PRESS / "AppIcon.icon"
ASSETS = ICON_PKG / "Assets"

# GameSir-matched palette (same as on-screen shells).
BODY = (214, 212, 208, 255)       # #D6D4D0
PILL = (72, 70, 68, 255)          # charcoal Select/Start
CIRCLE = (122, 28, 64, 255)       # magenta face button
SIZE = 1024


def srgb(color: tuple[int, int, int, int]) -> str:
    r, g, b, a = color
    return f"extended-srgb:{r/255:.5f},{g/255:.5f},{b/255:.5f},{a/255:.5f}"


def rounded_rect_path(x: float, y: float, w: float, h: float, r: float) -> str:
    r = min(r, w / 2, h / 2)
    return (
        f"M {x + r},{y} "
        f"H {x + w - r} "
        f"A {r},{r} 0 0 1 {x + w},{y + r} "
        f"V {y + h - r} "
        f"A {r},{r} 0 0 1 {x + w - r},{y + h} "
        f"H {x + r} "
        f"A {r},{r} 0 0 1 {x},{y + h - r} "
        f"V {y + r} "
        f"A {r},{r} 0 0 1 {x + r},{y} Z"
    )


def control_geometry() -> dict:
    """Shared geometry for pill + circle, centered as a pair."""
    pill_w, pill_h = 300.0, 108.0
    circle_r = 118.0
    gap = 56.0
    angle_deg = -28.0

    # Pair bounding box centered on canvas.
    # Approximate rotated pill width/height for layout.
    ang = math.radians(abs(angle_deg))
    rot_w = pill_w * math.cos(ang) + pill_h * math.sin(ang)
    pair_w = rot_w + gap + circle_r * 2
    pair_cx = SIZE / 2
    pair_cy = SIZE / 2
    pill_cx = pair_cx - pair_w / 2 + rot_w / 2
    circle_cx = pair_cx + pair_w / 2 - circle_r
    return {
        "pill_w": pill_w,
        "pill_h": pill_h,
        "pill_cx": pill_cx,
        "pill_cy": pair_cy,
        "circle_cx": circle_cx,
        "circle_cy": pair_cy,
        "circle_r": circle_r,
        "angle_deg": angle_deg,
        "gap": gap,
    }


def draw_flat_icon(with_background: bool = True) -> Image.Image:
    g = control_geometry()
    img = Image.new("RGBA", (SIZE, SIZE), BODY if with_background else (0, 0, 0, 0))

    # Angled charcoal pill
    pad = 8
    tile = Image.new("RGBA", (int(g["pill_w"]) + pad * 2, int(g["pill_h"]) + pad * 2), (0, 0, 0, 0))
    td = ImageDraw.Draw(tile)
    td.rounded_rectangle(
        [pad, pad, pad + g["pill_w"], pad + g["pill_h"]],
        radius=g["pill_h"] / 2,
        fill=PILL,
    )
    rot = tile.rotate(g["angle_deg"], resample=Image.Resampling.BICUBIC, expand=True)
    img.alpha_composite(
        rot,
        dest=(int(g["pill_cx"] - rot.size[0] / 2), int(g["pill_cy"] - rot.size[1] / 2)),
    )

    # Magenta circle
    d = ImageDraw.Draw(img)
    cx, cy, r = g["circle_cx"], g["circle_cy"], g["circle_r"]
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=CIRCLE)
    return img


def ios_squircle_mask(size: int = SIZE) -> Image.Image:
    """Approximate iOS continuous-corner squircle mask."""
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    # Continuous corner ≈ 22.37% of side for iOS icons.
    radius = size * 0.2237
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def write_svg_layers() -> None:
    """Flat unstyled layers for Icon Composer (full 1024 canvas, transparent bg)."""
    g = control_geometry()
    ASSETS.mkdir(parents=True, exist_ok=True)

    # Pill as axis-aligned rounded rect, then we bake rotation into SVG transform.
    # Icon Composer wants artwork already positioned on the 1024 canvas.
    pill_svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <g transform="translate({g['pill_cx']:.2f} {g['pill_cy']:.2f}) rotate({g['angle_deg']:.2f})">
    <rect x="{-g['pill_w']/2:.2f}" y="{-g['pill_h']/2:.2f}" width="{g['pill_w']:.2f}" height="{g['pill_h']:.2f}"
          rx="{g['pill_h']/2:.2f}" ry="{g['pill_h']/2:.2f}" fill="#484644"/>
  </g>
</svg>
"""
    circle_svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <circle cx="{g['circle_cx']:.2f}" cy="{g['circle_cy']:.2f}" r="{g['circle_r']:.2f}" fill="#7A1C40"/>
</svg>
"""
    (ASSETS / "01-select-pill.svg").write_text(pill_svg)
    (ASSETS / "02-action-circle.svg").write_text(circle_svg)

    # Also PNG copies (flat) for tools that prefer raster.
    pill_png = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    circle_png = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    # reuse draw helpers
    pad = 8
    tile = Image.new("RGBA", (int(g["pill_w"]) + pad * 2, int(g["pill_h"]) + pad * 2), (0, 0, 0, 0))
    td = ImageDraw.Draw(tile)
    td.rounded_rectangle(
        [pad, pad, pad + g["pill_w"], pad + g["pill_h"]],
        radius=g["pill_h"] / 2,
        fill=PILL,
    )
    rot = tile.rotate(g["angle_deg"], resample=Image.Resampling.BICUBIC, expand=True)
    pill_png.alpha_composite(
        rot,
        dest=(int(g["pill_cx"] - rot.size[0] / 2), int(g["pill_cy"] - rot.size[1] / 2)),
    )
    cd = ImageDraw.Draw(circle_png)
    cx, cy, r = g["circle_cx"], g["circle_cy"], g["circle_r"]
    cd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=CIRCLE)
    pill_png.save(ASSETS / "01-select-pill.png")
    circle_png.save(ASSETS / "02-action-circle.png")


def write_icon_json() -> None:
    """Icon Composer document with Liquid Glass on both controls."""
    doc = {
        "fill": {"solid": srgb(BODY)},
        "features": ["refractivity", "specular-location"],
        "groups": [
            {
                "name": "Controls",
                "lighting": "individual",
                "specular": True,
                "specular-highlight-placement": "outside",
                "shadow": {"kind": "neutral", "opacity": 0.35},
                "translucency": {"enabled": True, "value": 0.22},
                "refractivity": {"enabled": True, "depth": 0.55, "strength": 0.7},
                "blur-material": 0.35,
                "layers": [
                    {
                        "name": "Select pill",
                        "image-name": "01-select-pill.svg",
                        "glass": True,
                    },
                    {
                        "name": "Action circle",
                        "image-name": "02-action-circle.svg",
                        "glass": True,
                    },
                ],
            }
        ],
        "supported-platforms": {"squares": ["iOS"]},
    }
    ICON_PKG.mkdir(parents=True, exist_ok=True)
    (ICON_PKG / "icon.json").write_text(json.dumps(doc, indent=2) + "\n")


def write_favicon() -> None:
    fav = ROOT / "favicon.svg"
    fav.write_text(
        """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <rect width="64" height="64" rx="14" fill="#D6D4D0"/>
  <g transform="translate(20 32) rotate(-28)">
    <rect x="-11" y="-4.2" width="22" height="8.4" rx="4.2" fill="#484644"/>
  </g>
  <circle cx="42" cy="32" r="9.5" fill="#7A1C40"/>
</svg>
"""
    )


def apply_squircle(src: Image.Image) -> Image.Image:
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    out.paste(src, (0, 0))
    out.putalpha(ios_squircle_mask(src.size[0]))
    return out


def main() -> None:
    BRAND.mkdir(parents=True, exist_ok=True)
    APPICONSET.mkdir(parents=True, exist_ok=True)
    ASSETS.mkdir(parents=True, exist_ok=True)

    flat = draw_flat_icon(with_background=True).convert("RGB")
    flat_rgba = draw_flat_icon(with_background=True)

    # Asset catalog + brand masters (flat).
    flat.save(APPICONSET / "AppIcon.png", optimize=True)
    flat.save(BRAND / "press-start-icon.png", optimize=True)
    flat.save(BRAND / "press-start-logo.png", optimize=True)

    squircle = apply_squircle(flat_rgba)
    squircle.save(BRAND / "press-start-icon-squircle.png", optimize=True)

    # README badge: squircle on transparent with a little padding.
    pad = 38
    readme = Image.new("RGBA", (SIZE + pad * 2, SIZE + pad * 2), (0, 0, 0, 0))
    readme.paste(squircle, (pad, pad), squircle)
    readme.save(BRAND / "press-start-icon-readme.png", optimize=True)

    write_svg_layers()
    write_icon_json()
    write_favicon()

    print(f"wrote flat AppIcon → {APPICONSET / 'AppIcon.png'}")
    print(f"wrote brand icons → {BRAND}")
    print(f"wrote Icon Composer package → {ICON_PKG}")
    print(f"wrote favicon → {ROOT / 'favicon.svg'}")


if __name__ == "__main__":
    main()
