"""生成渗透系数 App 图标 (地球+水滴主题)"""
import os, math
from PIL import Image, ImageDraw

OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'android', 'app', 'src', 'main', 'res')
BLUE_BG = (13, 71, 161)       # #0D47A1 深蓝背景
CYAN = (79, 195, 247)          # #4FC3F7 水滴色
WHITE = (255, 255, 255)
WHITE_30 = (255, 255, 255, 76)

def create_foreground(size):
    """绘制前景：地球经纬网 + 水滴"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = cy = size / 2
    r = size * 0.42  # 地球半径

    # 地球圆（白色细边）
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=WHITE, width=max(1, int(size * 0.012)))

    # 经线（竖线 + 弧线）
    w = max(1, int(size * 0.008))
    # 中央经线
    draw.arc([cx - r, cy - r, cx + r, cy + r], 270, 90, fill=WHITE_30[:3], width=w)
    # 左侧经线
    lr = r * 0.5
    draw.ellipse([cx - lr, cy - r, cx + lr, cy + r], outline=WHITE_30[:3], width=w)
    # 右侧经线
    draw.ellipse([cx - r, cy - r * 0.55, cx + r, cy + r * 0.55], outline=WHITE_30[:3], width=w)

    # 纬线（水平线）
    for frac in [-0.5, 0, 0.5]:
        y = cy + frac * r * 0.7
        half_w = math.sqrt(max(0, r * r - (frac * r * 0.7) ** 2))
        draw.line([cx - half_w, y, cx + half_w, y], fill=WHITE_30[:3], width=w)

    # 水滴形状（中央）
    drop_r = r * 0.32
    drop_cx = cx
    drop_cy = cy - drop_r * 0.15
    # 用椭圆 + 三角近似水滴
    # 上半圆
    draw.pieslice(
        [drop_cx - drop_r, drop_cy - drop_r, drop_cx + drop_r, drop_cy + drop_r],
        180, 360, fill=CYAN
    )
    # 下半三角（用多边形）
    tri_points = [
        (drop_cx - drop_r, drop_cy),
        (drop_cx + drop_r, drop_cy),
        (drop_cx, drop_cy + drop_r * 1.4),
    ]
    draw.polygon(tri_points, fill=CYAN)

    # 水滴高光
    highlight_r = drop_r * 0.25
    hx = drop_cx - drop_r * 0.28
    hy = drop_cy - drop_r * 0.3
    draw.ellipse([hx - highlight_r, hy - highlight_r, hx + highlight_r, hy + highlight_r], fill=WHITE)

    return img


def create_background(size):
    """纯色深蓝背景"""
    return Image.new('RGB', (size, size), BLUE_BG)


def create_legacy_icon(size):
    """传统图标 = 背景 + 前景合并"""
    bg = create_background(size)
    fg = create_foreground(size)
    bg.paste(fg, (0, 0), fg)
    return bg


def create_adaptive_foreground(size):
    """自适应图标前景（108dp = 432px * density/4），内容需在中心 72dp 安全区内"""
    # 安全区占 66.67% = 72/108
    # 我们把内容画在中心 80% 区域内以保证安全
    safe_margin = int(size * 0.15)
    inner_size = size - 2 * safe_margin
    fg_full = create_foreground(inner_size)
    fg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    fg.paste(fg_full, (safe_margin, safe_margin))
    return fg


def main():
    # ---- 传统图标 (legacy) ----
    legacy_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    for folder, size in legacy_sizes.items():
        path = os.path.join(OUT_DIR, folder)
        os.makedirs(path, exist_ok=True)
        icon = create_legacy_icon(size)
        icon.save(os.path.join(path, 'ic_launcher.png'), 'PNG')
        print(f'  {folder}/ic_launcher.png ({size}x{size})')

    # ---- 自适应图标 (Android 8.0+) ----
    adaptive_bg_dir = os.path.join(OUT_DIR, 'drawable')
    os.makedirs(adaptive_bg_dir, exist_ok=True)

    # 生成各密度的自适应前景 PNG
    adaptive_sizes = {
        'mipmap-mdpi': 108,
        'mipmap-hdpi': 162,
        'mipmap-xhdpi': 216,
        'mipmap-xxhdpi': 324,
        'mipmap-xxxhdpi': 432,
    }
    for folder, size in adaptive_sizes.items():
        path = os.path.join(OUT_DIR, folder)
        os.makedirs(path, exist_ok=True)
        fg = create_adaptive_foreground(size)
        fg.save(os.path.join(path, 'ic_launcher_foreground.png'), 'PNG')
        print(f'  {folder}/ic_launcher_foreground.png ({size}x{size})')

    # 背景色 drawable
    bg_color_xml = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0D47A1</color>
</resources>'''
    values_dir = os.path.join(OUT_DIR, 'values')
    os.makedirs(values_dir, exist_ok=True)
    with open(os.path.join(values_dir, 'ic_launcher_background.xml'), 'w') as f:
        f.write(bg_color_xml)

    # 自适应图标主 XML
    anydpi_dir = os.path.join(OUT_DIR, 'mipmap-anydpi-v26')
    os.makedirs(anydpi_dir, exist_ok=True)
    adaptive_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>'''
    with open(os.path.join(anydpi_dir, 'ic_launcher.xml'), 'w') as f:
        f.write(adaptive_xml)
    print(f'  mipmap-anydpi-v26/ic_launcher.xml')

    # 背景色
    bg_drawable = '''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="#0D47A1"/>
</shape>'''
    os.makedirs(os.path.join(OUT_DIR, 'drawable'), exist_ok=True)
    with open(os.path.join(OUT_DIR, 'drawable', 'ic_launcher_background.xml'), 'w') as f:
        f.write(bg_drawable)
    print(f'  drawable/ic_launcher_background.xml')

    print('\n✅ 图标生成完成！')


if __name__ == '__main__':
    main()
