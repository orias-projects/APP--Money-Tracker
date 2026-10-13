"""Đệm ảnh chụp màn hình về tỉ lệ 9:16 cho Google Play.

Play bắt buộc ảnh chụp điện thoại có tỉ lệ 16:9 hoặc 9:16. Máy Android hiện đại
phần lớn là 20:9 (1080x2400), tức chụp ra là sai tỉ lệ và Play từ chối.

Cắt bớt thì mất nội dung (thanh điều hướng dưới hoặc thanh trạng thái trên), thu
nhỏ thì mờ chữ. Cách ở đây: giữ NGUYÊN từng điểm ảnh, dán vào giữa một khung
1350x2400 (đúng 16/9) và đệm hai bên bằng chính màu nền của app — nhìn liền mạch
chứ không ra viền đen.

    pip install Pillow
    python tool/pad_screenshots.py

Đọc từ store_assets/screenshots_raw/, ghi ra store_assets/screenshots/.
"""

import collections
import glob
import os

from PIL import Image

SRC_DIR = 'store_assets/screenshots_raw'
OUT_DIR = 'store_assets/screenshots'
RATIO = 16 / 9


def pad(path: str) -> None:
    src = Image.open(path).convert('RGB')
    w, h = src.size
    if abs(h / w - RATIO) < 0.001:
        canvas = src  # đã đúng tỉ lệ, giữ nguyên
    else:
        width = round(h / RATIO)
        assert width >= w, f'{path}: ảnh quá cao, đệm không đủ — cần cắt thủ công'
        # Màu nền lấy từ cột ngoài cùng bên trái: đó là nền app, không phải thẻ nội dung.
        column = [src.getpixel((1, y)) for y in range(0, h, 7)]
        bg = collections.Counter(column).most_common(1)[0][0]
        canvas = Image.new('RGB', (width, h), bg)
        canvas.paste(src, ((width - w) // 2, 0))

    out = os.path.join(OUT_DIR, os.path.basename(path))
    canvas.save(out, 'PNG', optimize=True)
    print(f'{os.path.basename(path):28s} {w}x{h} -> {canvas.size[0]}x{canvas.size[1]}')


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    files = sorted(glob.glob(os.path.join(SRC_DIR, '*.png')))
    assert files, f'Không thấy ảnh nào trong {SRC_DIR}'
    for f in files:
        pad(f)


if __name__ == '__main__':
    main()
