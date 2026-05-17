"""
Quick WebP optimization — faster encoding method.
"""

import os
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PUBLIC_DIR = os.path.join(SCRIPT_DIR, "..", "public")
PNG_PATH = os.path.join(PUBLIC_DIR, "diamond-spritesheet.png")
WEBP_PATH = os.path.join(PUBLIC_DIR, "diamond-spritesheet.webp")


def mb(path):
    return os.path.getsize(path) / (1024 * 1024)


def main():
    img = Image.open(PNG_PATH)
    png_size = mb(PNG_PATH)
    print(f"Source: {img.width}x{img.height}, {png_size:.1f}MB (PNG)")

    # WebP quality 90, method=4 (fast but still good compression)
    print("Encoding WebP q=90...")
    img.save(WEBP_PATH, "WEBP", quality=90, method=4)
    webp_size = mb(WEBP_PATH)
    reduction = (1 - webp_size / png_size) * 100
    print(f"  WebP: {webp_size:.1f}MB ({reduction:.0f}% smaller)")
    print(f"\nDone: {PNG_PATH} -> {WEBP_PATH}")
    print(f"  {png_size:.1f}MB -> {webp_size:.1f}MB (saved {reduction:.0f}%)")


if __name__ == "__main__":
    main()
