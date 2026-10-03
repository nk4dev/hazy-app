# Regenerates every launcher/app icon from the Hazy mark. Run from the repo root:
#   python3 tool/gen_icons.py   (requires Pillow)
import glob, os
from PIL import Image, ImageDraw

MID, LIGHT, DARK = (145, 132, 217, 255), (181, 171, 252, 255), (122, 108, 201, 255)
WHITE = (255, 255, 255, 255)

def logo(size, bg, scale):
    """Hazy mark redrawn from the web app's 63px hazy.png, centred, where
    `scale` is the fraction of the canvas the 63-unit artboard occupies."""
    ss = 4
    S = size * ss
    im = Image.new('RGBA', (S, S), bg)
    d = ImageDraw.Draw(im)
    k = S * scale / 63.0
    # artwork's visual centre in the 63-unit artboard
    cx, cy = 31.5, 30.5
    def P(pts):
        return [((x - cx) * k + S / 2, (y - cy) * k + S / 2) for x, y in pts]
    hole = bg if bg[3] else (0, 0, 0, 0)
    d.polygon(P([(18.5, 30), (7, 50), (30.5, 50)]), fill=LIGHT)
    d.polygon(P([(44.5, 30), (56, 50), (32.5, 50)]), fill=DARK)
    d.polygon(P([(16, 28), (47, 28), (31.5, 53)]), fill=MID)
    d.polygon(P([(31.5, 8), (17.5, 30), (45.5, 30)]), fill=MID)
    d.polygon(P([(22, 31), (41, 31), (31.5, 47)]), fill=hole)
    return im.resize((size, size), Image.LANCZOS)

def save(im, path, alpha=True):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (im if alpha else im.convert('RGB')).save(path)

master = logo(1024, WHITE, 0.80)
save(master, 'assets/branding/app_icon.png', alpha=False)

res = 'android/app/src/main/res'
for name, px in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    save(master.resize((px, px), Image.LANCZOS), f'{res}/mipmap-{name}/ic_launcher.png', alpha=False)
    # adaptive foreground: 108dp canvas, artwork inside the 66dp safe zone
    fg = px * 108 // 48
    save(logo(fg, (0, 0, 0, 0), 0.62), f'{res}/mipmap-{name}/ic_launcher_foreground.png')

for path in glob.glob('ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png'):
    w = Image.open(path).size[0]
    save(master.resize((w, w), Image.LANCZOS), path, alpha=False)

for path in glob.glob('web/icons/*.png') + ['web/favicon.png']:
    w = Image.open(path).size[0]
    im = logo(w, WHITE, 0.62) if 'maskable' in path else master.resize((w, w), Image.LANCZOS)
    save(im, path, alpha=False)

# --- Splash ---------------------------------------------------------------
CLEAR = (0, 0, 0, 0)

# In-app splash logo (Flutter asset, see lib/features/auth/splash_screen.dart).
save(logo(512, CLEAR, 1.0), 'assets/branding/app_logo.png')

# Android pre-12 native launch image, centred by launch_background.xml (96dp).
for name, px in [('mdpi', 96), ('hdpi', 144), ('xhdpi', 192), ('xxhdpi', 288), ('xxxhdpi', 384)]:
    save(logo(px, CLEAR, 1.0), f'{res}/mipmap-{name}/launch_image.png')

# iOS launch image, centred by LaunchScreen.storyboard (120pt).
for suffix, px in [('', 120), ('@2x', 240), ('@3x', 360)]:
    save(logo(px, CLEAR, 1.0),
         f'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png')
