"""
Interpolate diamond frames to create smoother animation.
Takes existing 38 frames and generates in-between frames by blending
adjacent pairs, resulting in 76 frames for smoother slow playback.
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

FRAME_SIZE = 500
SPRITE_COLS = 10  # 10 cols for 76 frames = 8 rows


def blend_frames(f1, f2, alpha=0.5):
    """Blend two BGRA frames together at the given alpha ratio."""
    return cv2.addWeighted(f1, 1.0 - alpha, f2, alpha, 0).astype(np.uint8)


def main():
    # Load existing loop frames
    frame_files = sorted([f for f in os.listdir(FRAMES_DIR) if f.endswith('.png')])
    print(f"Loading {len(frame_files)} source frames...")

    frames = []
    for f in frame_files:
        img = cv2.imread(os.path.join(FRAMES_DIR, f), cv2.IMREAD_UNCHANGED)
        if img is not None:
            frames.append(img)

    n = len(frames)
    print(f"  Loaded {n} frames")

    # Generate interpolated sequence: between each pair, insert 1 blended frame
    # Frame order: original_0, blend(0,1), original_1, blend(1,2), ...
    interpolated = []
    for i in range(n):
        # Original frame
        interpolated.append(frames[i])
        # Blended midpoint with next frame (wrapping to create seamless loop)
        next_i = (i + 1) % n
        mid = blend_frames(frames[i], frames[next_i], 0.5)
        interpolated.append(mid)

    total = len(interpolated)
    print(f"  Interpolated: {n} -> {total} frames (2x)")

    # Clear old frames and save new ones
    for f in frame_files:
        os.remove(os.path.join(FRAMES_DIR, f))

    for i, frame in enumerate(interpolated):
        path = os.path.join(FRAMES_DIR, f"frame_{i+1:03d}.png")
        img = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGRA2RGBA))
        img.save(path, "PNG")

    print(f"  Saved {total} frames to {FRAMES_DIR}/")

    # Build sprite sheet
    rows = math.ceil(total / SPRITE_COLS)
    sheet = np.zeros((rows * FRAME_SIZE, SPRITE_COLS * FRAME_SIZE, 4), dtype=np.uint8)

    for i, frame in enumerate(interpolated):
        row = i // SPRITE_COLS
        col = i % SPRITE_COLS
        y = row * FRAME_SIZE
        x = col * FRAME_SIZE
        sheet[y:y + FRAME_SIZE, x:x + FRAME_SIZE] = frame

    img = Image.fromarray(cv2.cvtColor(sheet, cv2.COLOR_BGRA2RGBA))
    img.save(SPRITE_SHEET_PATH, "PNG", optimize=True)

    file_size = os.path.getsize(SPRITE_SHEET_PATH) / (1024 * 1024)
    print(f"\nSprite sheet: {SPRITE_COLS}x{rows} grid, {img.width}x{img.height}px, {file_size:.1f}MB")
    print(f"Total frames: {total}")
    print(f"\nPlayback speeds:")
    print(f"  12 FPS = {total/12:.1f}s per rotation (smooth + slow)")
    print(f"  15 FPS = {total/15:.1f}s per rotation (smooth + moderate)")
    print(f"  16 FPS = {total/16:.1f}s per rotation (smooth + moderate)")


if __name__ == "__main__":
    main()
