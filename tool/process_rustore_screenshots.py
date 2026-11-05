import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

project_root = r'C:\Users\abdulla\Desktop\Mubeen_Quran_Pure'
out_clean_dir = os.path.join(project_root, 'rustore_screenshots', 'clean')
out_promo_dir = os.path.join(project_root, 'rustore_screenshots', 'promo')
os.makedirs(out_clean_dir, exist_ok=True)
os.makedirs(out_promo_dir, exist_ok=True)

# 4 authentic slides from Mubeen Quran Pure app
slides = [
    {
        'num': '01',
        'tag': '01 · СВЯЩЕННЫЙ КОРАН',
        'title': 'БЛАГОРОДНЫЙ МУСХАФ\nИ СМЫСЛОВОЙ ПЕРЕВОД',
        'subtitle': 'Арабский текст, переводы Кулиева и Абу Аделя',
        'chips': ['БЕЗ РЕКЛАМЫ', '100% ОФЛАЙН', 'ТАФСИР СААДИ'],
        'input_file': os.path.join(project_root, 'd9d41396-2d7c-4399-9099-43ce5869b5b7.png'),
        'crop_top': 78,
        'crop_bottom': 2240,
        'filename': '01_mushaf_reading.png',
    },
    {
        'num': '02',
        'tag': '02 · 114 СУР',
        'title': 'УДОБНАЯ НАВИГАЦИЯ\nПО ВСЕМ СУРАМ И ДЖУЗАМ',
        'subtitle': 'Мекканские и мединские суры, закладки и прогресс',
        'chips': ['114 СУР', '30 ДЖУЗОВ', 'ЗАКЛАДКИ'],
        'input_file': os.path.join(project_root, '7bfee300-0160-48d5-859f-72c63b2ce0c9.png'),
        'crop_top': 78,
        'crop_bottom': 2240,
        'filename': '02_surah_navigation.png',
    },
    {
        'num': '03',
        'tag': '03 · ПОИСК ПО КОРАНУ',
        'title': 'МГНОВЕННЫЙ ПОИСК\nПО ТЕКСТУ И СМЫСЛУ',
        'subtitle': 'Поиск аятов на русском и арабском языках',
        'chips': ['УМНЫЙ ПОИСК', 'РУССКИЙ & ARABIC', 'ИСТОРИЯ'],
        'input_file': os.path.join(project_root, 'play_store_screenshots', '03_search.png'),
        'crop_top': 78,
        'crop_bottom': 2240,
        'filename': '03_smart_search.png',
    },
    {
        'num': '04',
        'tag': '04 · ПЕРСОНАЛИЗАЦИЯ',
        'title': 'НАСТРОЙКИ ЧТЕНИЯ\nПОД ВАШИ ПРЕДПОЧТЕНИЯ',
        'subtitle': 'Выбор шрифта, размера текста, темы и защита глаз',
        'chips': ['ШРИФТЫ МУСХАФА', 'ЗАЩИТА ГЛАЗ', 'ТЕМНАЯ ТЕМА'],
        'input_file': os.path.join(project_root, '66c75448-03ad-4692-9896-83f447f7c4c2.png'),
        'crop_top': 78,
        'crop_bottom': 2240,
        'filename': '04_app_settings.png',
    },
]

W, H = 1080, 1920

# Fonts
font_bold_path = r'C:\Windows\Fonts\segoeuib.ttf'
font_reg_path = r'C:\Windows\Fonts\segoeui.ttf'

tag_font = ImageFont.truetype(font_bold_path, 21)
title_font = ImageFont.truetype(font_bold_path, 48)
sub_font = ImageFont.truetype(font_reg_path, 23)
chip_font = ImageFont.truetype(font_bold_path, 15)

def round_all_corners(img, radius):
    mask = Image.new('L', img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, img.width, img.height], radius=radius, fill=255)
    out = img.copy()
    out.putalpha(mask)
    return out

def create_rich_background(w, h):
    base = Image.new('RGBA', (w, h), (4, 10, 7, 255))
    draw = ImageDraw.Draw(base)

    top_c = (14, 48, 36)
    mid_c = (7, 24, 18)
    bot_c = (3, 10, 7)

    for y in range(h):
        if y < 700:
            f = y / 700.0
            r = int(top_c[0] * (1 - f) + mid_c[0] * f)
            g = int(top_c[1] * (1 - f) + mid_c[1] * f)
            b = int(top_c[2] * (1 - f) + mid_c[2] * f)
        else:
            f = (y - 700) / float(h - 700)
            r = int(mid_c[0] * (1 - f) + bot_c[0] * f)
            g = int(mid_c[1] * (1 - f) + bot_c[1] * f)
            b = int(mid_c[2] * (1 - f) + bot_c[2] * f)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

    # Radial golden/emerald glow
    glow_w, glow_h = w, 520
    glow = Image.new('RGBA', (glow_w, glow_h), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    cx, cy = glow_w // 2, 140
    max_r = 460
    for r in range(max_r, 0, -6):
        alpha = int(36 * (1.0 - (r / max_r) ** 1.5))
        gdraw.ellipse([cx - r, cy - int(r * 0.58), cx + r, cy + int(r * 0.58)], fill=(215, 185, 115, alpha))
    glow_blurred = glow.filter(ImageFilter.GaussianBlur(32))
    base.alpha_composite(glow_blurred, (0, 0))

    return base

print("=== 1. Generating Variant A: Clean Fullscreen (1080x1920) ===")
for idx, spec in enumerate(slides):
    raw_img = Image.open(spec['input_file']).convert('RGB')
    cropped = raw_img.crop((0, spec['crop_top'], raw_img.width, spec['crop_bottom']))
    resized = cropped.resize((W, H), Image.Resampling.LANCZOS)
    sharpened = resized.filter(ImageFilter.UnsharpMask(radius=1.0, percent=35, threshold=2))
    
    clean_out_path = os.path.join(out_clean_dir, spec['filename'])
    sharpened.save(clean_out_path, format='PNG', optimize=True)
    print(f"  [Clean] Saved: {spec['filename']} -> {sharpened.size} (aspect ratio {sharpened.size[0]/sharpened.size[1]:.4f})")

print("\n=== 2. Generating Variant B: Store Marketing Showcase (1080x1920) ===")
for idx, spec in enumerate(slides):
    canvas = create_rich_background(W, H)
    draw = ImageDraw.Draw(canvas)

    # 1. Tag Pill
    tag_text = spec['tag']
    tag_bbox = draw.textbbox((0, 0), tag_text, font=tag_font)
    tag_tw = tag_bbox[2] - tag_bbox[0]
    tag_th = tag_bbox[3] - tag_bbox[1]

    pill_w = tag_tw + 44
    pill_h = 38
    pill_x0 = (W - pill_w) // 2
    pill_y0 = 50
    pill_x1 = pill_x0 + pill_w
    pill_y1 = pill_y0 + pill_h

    draw.rounded_rectangle(
        [pill_x0, pill_y0, pill_x1, pill_y1],
        radius=19,
        fill=(15, 48, 37, 240),
        outline=(205, 172, 102, 230),
        width=2
    )

    draw.text(
        (pill_x0 + (pill_w - tag_tw) // 2, pill_y0 + (pill_h - tag_th) // 2 - 2),
        tag_text,
        font=tag_font,
        fill=(245, 224, 165, 255)
    )

    # 2. Main Title (2 lines)
    title_lines = spec['title'].split('\n')
    title_y = 106
    line_spacing = 60
    for line in title_lines:
        t_bbox = draw.textbbox((0, 0), line, font=title_font)
        t_w = t_bbox[2] - t_bbox[0]
        draw.text(((W - t_w) // 2, title_y + 2), line, font=title_font, fill=(0, 0, 0, 120))
        draw.text(((W - t_w) // 2, title_y), line, font=title_font, fill=(255, 255, 255, 255))
        title_y += line_spacing

    # 3. Subtitle
    sub_text = spec['subtitle']
    s_bbox = draw.textbbox((0, 0), sub_text, font=sub_font)
    s_w = s_bbox[2] - s_bbox[0]
    sub_y = title_y + 4
    draw.text(((W - s_w) // 2, sub_y + 1), sub_text, font=sub_font, fill=(0, 0, 0, 100))
    draw.text(((W - s_w) // 2, sub_y), sub_text, font=sub_font, fill=(188, 206, 198, 255))

    # 4. Chips / Pills
    chips = spec['chips']
    chip_spacing = 14
    chip_h = 28
    chip_padding_x = 18
    total_chips_w = 0
    chip_sizes = []
    for chip in chips:
        c_bbox = draw.textbbox((0, 0), chip, font=chip_font)
        cw = c_bbox[2] - c_bbox[0] + (chip_padding_x * 2)
        chip_sizes.append((cw, c_bbox))
        total_chips_w += cw
    total_chips_w += chip_spacing * (len(chips) - 1)

    chips_x = (W - total_chips_w) // 2
    chips_y = sub_y + 40

    for chip, (cw, c_bbox) in zip(chips, chip_sizes):
        draw.rounded_rectangle(
            [chips_x, chips_y, chips_x + cw, chips_y + chip_h],
            radius=14,
            fill=(10, 32, 24, 210),
            outline=(160, 140, 85, 180),
            width=1
        )
        ct_w = c_bbox[2] - c_bbox[0]
        ct_h = c_bbox[3] - c_bbox[1]
        draw.text(
            (chips_x + (cw - ct_w) // 2, chips_y + (chip_h - ct_h) // 2 - 2),
            chip,
            font=chip_font,
            fill=(220, 205, 160, 255)
        )
        chips_x += cw + chip_spacing

    # 5. Screen Mockup
    raw_img = Image.open(spec['input_file']).convert('RGBA')
    cropped_screen = raw_img.crop((0, spec['crop_top'], raw_img.width, spec['crop_bottom']))

    screen_w = 680
    orig_aspect = cropped_screen.height / float(cropped_screen.width)
    screen_h = int(screen_w * orig_aspect) # ~ 1361 px

    screen_resized = cropped_screen.resize((screen_w, screen_h), Image.Resampling.LANCZOS)
    screen_sharpened = screen_resized.filter(ImageFilter.UnsharpMask(radius=1.1, percent=65, threshold=2))
    screen_rounded = round_all_corners(screen_sharpened, 26)

    # Phone chassis
    bezel_side = 9
    bezel_top = 18
    bezel_bottom = 18
    phone_w = screen_w + (bezel_side * 2)
    phone_h = screen_h + bezel_top + bezel_bottom
    phone_corner_radius = 36

    phone_x = (W - phone_w) // 2
    phone_y = chips_y + 42

    # Drop shadows
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        [phone_x - 4, phone_y + 8, phone_x + phone_w + 4, phone_y + phone_h + 20],
        radius=phone_corner_radius + 4,
        fill=(0, 0, 0, 160)
    )
    shadow_blurred = shadow.filter(ImageFilter.GaussianBlur(32))
    canvas.alpha_composite(shadow_blurred)

    shadow_tight = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    stdraw = ImageDraw.Draw(shadow_tight)
    stdraw.rounded_rectangle(
        [phone_x, phone_y + 4, phone_x + phone_w, phone_y + phone_h + 8],
        radius=phone_corner_radius,
        fill=(0, 0, 0, 140)
    )
    tight_blurred = shadow_tight.filter(ImageFilter.GaussianBlur(12))
    canvas.alpha_composite(tight_blurred)

    # Phone body chassis
    chassis = Image.new('RGBA', (phone_w, phone_h), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(chassis)
    cdraw.rounded_rectangle(
        [0, 0, phone_w, phone_h],
        radius=phone_corner_radius,
        fill=(20, 26, 23, 255),
        outline=(48, 68, 56, 255),
        width=2
    )

    # Punch-hole camera
    cam_x = phone_w // 2
    cam_y = bezel_top // 2 + 1
    cam_r = 4
    cdraw.ellipse([cam_x - cam_r, cam_y - cam_r, cam_x + cam_r, cam_y + cam_r], fill=(10, 14, 12, 255), outline=(28, 38, 32, 255), width=1)
    cdraw.point((cam_x - 1, cam_y - 1), fill=(70, 90, 80, 255))

    canvas.alpha_composite(chassis, (phone_x, phone_y))

    # Paste screen content
    screen_x = phone_x + bezel_side
    screen_y = phone_y + bezel_top
    canvas.alpha_composite(screen_rounded, (screen_x, screen_y))

    # Inner display rim
    display_rim = Image.new('RGBA', (screen_w, screen_h), (0, 0, 0, 0))
    drdraw = ImageDraw.Draw(display_rim)
    drdraw.rounded_rectangle(
        [0, 0, screen_w - 1, screen_h - 1],
        radius=26,
        outline=(36, 52, 42, 140),
        width=1
    )
    canvas.alpha_composite(display_rim, (screen_x, screen_y))

    # Save final promo
    promo_out_path = os.path.join(out_promo_dir, spec['filename'])
    final_rgb = canvas.convert('RGB')
    final_rgb.save(promo_out_path, format='PNG', optimize=True)
    print(f"  [Promo] Saved: {spec['filename']} -> {final_rgb.size} (aspect ratio {final_rgb.size[0]/final_rgb.size[1]:.4f})")

print("\nDone! All screenshots generated successfully with exact 1080x1920 (9:16) resolution.")
