"""Generate the Daily W Play Store feature graphic (1024x500)."""
from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1024, 500
BG     = (13, 27, 42)       # #0D1B2A
ACCENT = (255, 77, 109)     # #FF4D6D
WHITE  = (255, 255, 255)
DIM    = (180, 195, 210)

canvas = Image.new("RGB", (W, H), BG)

# ── glow circle behind icon (left side) ──────────────────────────────────────
cx, cy = 260, 250
for r, a in [(190, 15), (150, 28), (110, 44)]:
    layer = Image.new("RGB", (W, H), ACCENT)
    mask  = Image.new("L",   (W, H), 0)
    ImageDraw.Draw(mask).ellipse([cx-r, cy-r, cx+r, cy+r], fill=a)
    canvas.paste(layer, (0, 0), mask)

# ── subtle dot-grid overlay ───────────────────────────────────────────────────
grid      = Image.new("RGB", (W, H), (30, 50, 70))
grid_mask = Image.new("L",   (W, H), 0)
gd        = ImageDraw.Draw(grid_mask)
step = 40
for x in range(step, W, step):
    for y in range(step, H, step):
        gd.ellipse([x-1, y-1, x+1, y+1], fill=40)
canvas.paste(grid, (0, 0), grid_mask)

draw = ImageDraw.Draw(canvas)

# ── left accent bar ───────────────────────────────────────────────────────────
draw.rectangle([0, 0, 5, H], fill=ACCENT)

# ── app icon ──────────────────────────────────────────────────────────────────
icon_path = os.path.join(
    os.path.dirname(__file__),
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
)
icon = Image.open(icon_path).convert("RGBA")
icon_size = 230
icon = icon.resize((icon_size, icon_size), Image.LANCZOS)
canvas.paste(icon, (cx - icon_size // 2, cy - icon_size // 2), icon)

# ── fonts ─────────────────────────────────────────────────────────────────────
fdir = r"C:\Windows\Fonts"
def load(name, size):
    for n in name:
        try:
            return ImageFont.truetype(os.path.join(fdir, n), size)
        except OSError:
            pass
    return ImageFont.load_default()

font_title = load(["segoeuib.ttf", "arialbd.ttf", "calibrib.ttf"], 92)
font_tag   = load(["segoeuil.ttf", "segoeui.ttf",  "arial.ttf"],   34)
font_sub   = load(["segoeuil.ttf", "segoeui.ttf",  "arial.ttf"],   22)

# ── text block ────────────────────────────────────────────────────────────────
tx = 430
ty = 148

# Title
draw.text((tx, ty), "Daily W", font=font_title, fill=WHITE)
bb = draw.textbbox((tx, ty), "Daily W", font=font_title)
th = bb[3] - bb[1]

# Accent underline
bar_y = ty + th + 12
draw.rectangle([tx, bar_y, tx + 110, bar_y + 5], fill=ACCENT)

# Tagline
draw.text((tx, bar_y + 20), "Your daily dose of W", font=font_tag, fill=ACCENT)

# Sub-line
draw.text((tx, bar_y + 20 + 52), "Motivation. Every. Day.", font=font_sub, fill=DIM)

# ── decorative dots (top-right corner) ───────────────────────────────────────
for dx, dy, r, col in [
    (905, 55,  5, ACCENT),
    (945, 90,  4, ACCENT),
    (920, 130, 3, WHITE),
    (960, 45,  3, WHITE),
    (880, 430, 4, ACCENT),
    (940, 455, 3, WHITE),
    (965, 415, 5, ACCENT),
]:
    draw.ellipse([dx-r, dy-r, dx+r, dy+r], fill=col)

# ── save ─────────────────────────────────────────────────────────────────────
out = os.path.join(os.path.dirname(__file__), "assets", "feature_graphic.png")
os.makedirs(os.path.dirname(out), exist_ok=True)
canvas.save(out, "PNG")
print(f"Saved {W}x{H} -> {out}")
