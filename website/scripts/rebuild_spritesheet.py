"""
Rebuild the diamond sprite sheet using only the loop frames.
Also regenerates cleaner individual frames.
"""

import cv2
import numpy as np
from PIL import Image
import os
import math

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PUBLIC_DIR = os.path.join(SCRIPT_DIR, "..", "public")
FRAMES_DIR = os.path.join(PUBLIC_DIR, "diamond-frames")
SPRITE_SHEET_PATH = os.path.join(PUBLIC_DIR, "diamond-spritesheet.png")

# Loop config — from analysis: frames 1-38 make one clean rotation
LOOP_START = 1   # frame_001.png
LOOP_END = 38    # frame_038.png (frame 39 is near-identical to frame 1)
SPRITE_COLS = 8  # 8 columns for 38 frames = 5 rows (8*5=40, last 2 cells empty)
FRAME_SIZE = 500


def main():
    # Collect loop frames
    loop_frames = []
    for i in range(LOOP_START, LOOP_END + 1):
        path = os.path.join(FRAMES_DIR, f"frame_{i:03d}.png")
        img = cv2.imread(path, cv2.IMREAD_UNCHANGED)
        if img is not None:
            loop_frames.append(img)
        else:
            print(f"WARNING: Could not load {path}")

    total = len(loop_frames)
    print(f"Loop frames: {total} (frames {LOOP_START}-{LOOP_END})")

    # Remove extra frames beyond the loop
    for i in range(LOOP_END + 1, 100):
        path = os.path.join(FRAMES_DIR, f"frame_{i:03d}.png")
        if os.path.exists(path):
            os.remove(path)
            print(f"  Removed extra frame: frame_{i:03d}.png")

    # Build sprite sheet
    rows = math.ceil(total / SPRITE_COLS)
    sheet = np.zeros((rows * FRAME_SIZE, SPRITE_COLS * FRAME_SIZE, 4), dtype=np.uint8)

    for i, frame in enumerate(loop_frames):
        row = i // SPRITE_COLS
        col = i % SPRITE_COLS
        y = row * FRAME_SIZE
        x = col * FRAME_SIZE
        sheet[y:y + FRAME_SIZE, x:x + FRAME_SIZE] = frame

    # Save
    img = Image.fromarray(cv2.cvtColor(sheet, cv2.COLOR_BGRA2RGBA))
    img.save(SPRITE_SHEET_PATH, "PNG", optimize=True)
    
    file_size = os.path.getsize(SPRITE_SHEET_PATH) / (1024 * 1024)
    print(f"\nSprite sheet: {SPRITE_COLS}x{rows} grid, {img.width}x{img.height}px, {file_size:.1f}MB")
    print(f"Total frames in loop: {total}")
    print(f"\nPlayback speeds:")
    print(f"  6 FPS = {total/6:.1f}s per rotation (very slow, contemplative)")
    print(f"  8 FPS = {total/8:.1f}s per rotation (slow, premium)")
    print(f"  10 FPS = {total/10:.1f}s per rotation (moderate)")
    print(f"  12 FPS = {total/12:.1f}s per rotation (original-ish)")


if __name__ == "__main__":
    main()
