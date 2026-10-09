"""Gera Support/AppIcon.icns a partir de base.svg e patch.svg.

Uso:  pip install cairosvg pillow && python3 Support/icon/make_icon.py
"""
import io
from pathlib import Path

import cairosvg
from PIL import Image, ImageChops, ImageFilter

HERE = Path(__file__).parent
SIZE = 1024


def render(name: str) -> Image.Image:
    png = cairosvg.svg2png(url=str(HERE / name), output_width=SIZE, output_height=SIZE)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def shadow(layer: Image.Image, blur: int, dx: int, dy: int, opacity: float) -> Image.Image:
    alpha = layer.getchannel("A").filter(ImageFilter.GaussianBlur(blur))
    alpha = alpha.point(lambda a: int(a * opacity))
    out = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    out.putalpha(alpha)
    return ImageChops.offset(out, dx, dy)


base = render("base.svg")
patch = render("patch.svg")

icon = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
icon.alpha_composite(shadow(base, 14, 0, 12, 0.35))
icon.alpha_composite(base)

# Sombra do remendo, presa dentro do fundo
patch_shadow = shadow(patch, 12, 4, 16, 0.45)
clip = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
clip.paste(patch_shadow, mask=base.getchannel("A"))
icon.alpha_composite(clip)
icon.alpha_composite(patch)

icon.save(HERE / "AppIcon-1024.png")
icon.save(HERE.parent / "AppIcon.icns")
print("OK:", HERE.parent / "AppIcon.icns")
