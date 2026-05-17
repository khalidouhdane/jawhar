"""
Re-extract ALL frames from the video (no subsampling, no blending).
Find the loop point, trim, rebuild the sprite sheet with real frames only.
"""

import cv2
import numpy as np
from PIL import Image
import os
import math
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PUBLIC_DIR = os.path.join(SCRIPT_DIR, "..", "public")
VIDEO_PATH = os.path.join(PUBLIC_DIR, "3D_diamond_gemstone_rotating_202605140429.mp4")
FRAMES_DIR = os.path.join(PUBLIC_DIR, "diamond-frames")
SPRITE_SHEET_PATH = os.path.join(PUBLIC_DIR, "diamond-spritesheet.png")

FRAME_SIZE = 500

# Green screen removal (HSV)
GREEN_LOWER = np.array([35, 80, 80])
GREEN_UPPER = np.array([85, 255, 255])
EDGE_FEATHER = 3


def remove_green_screen(frame, size):
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    green_mask = cv2.inRange(hsv, GREEN_LOWER, GREEN_UPPER)

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    bright_green = (rgb[:,:,1] > 150) & (rgb[:,:,0] < 100) & (rgb[:,:,2] < 100)
    green_mask[bright_green] = 255

    alpha = cv2.bitwise_not(green_mask)

    if EDGE_FEATHER > 0:
        alpha = cv2.GaussianBlur(alpha, (EDGE_FEATHER*2+1, EDGE_FEATHER*2+1), 0)

    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3,3))
    alpha = cv2.morphologyEx(alpha, cv2.MORPH_OPEN, kernel)
    alpha = cv2.morphologyEx(alpha, cv2.MORPH_CLOSE, kernel)

    bgra = cv2.cvtColor(frame, cv2.COLOR_BGR2BGRA)
    bgra[:,:,3] = alpha

    semi_mask = (alpha > 10) & (alpha < 245)
    if np.any(semi_mask):
        hsv_full = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV).astype(float)
        green_hue = (hsv_full[:,:,0] > 35) & (hsv_full[:,:,0] < 85)
        spill_mask = semi_mask & green_hue
        bgra[spill_mask, 1] = (bgra[spill_mask, 1] * 0.7).astype(np.uint8)

    h, w = bgra.shape[:2]
    if w != h:
        side = min(w, h)
        x_start = (w - side) // 2
        y_start = (h - side) // 2
        bgra = bgra[y_start:y_start+side, x_start:x_start+side]

    bgra = cv2.resize(bgra, (size, size), interpolation=cv2.INTER_AREA)
    return bgra


def frame_similarity(f1, f2):
    a1, a2 = f1[:,:,3], f2[:,:,3]
    rgb1, rgb2 = f1[:,:,:3].copy(), f2[:,:,:3].copy()
    rgb1[a1 < 128] = 0
    rgb2[a2 < 128] = 0
    return np.mean(cv2.absdiff(rgb1, rgb2)) / 255.0


def main():
    # Clear old frames
    if os.path.exists(FRAMES_DIR):
        shutil.rmtree(FRAMES_DIR)
    os.makedirs(FRAMES_DIR)

    # Extract ALL frames from video
    print("Step 1: Extracting ALL frames from video...")
    cap = cv2.VideoCapture(VIDEO_PATH)
    total_video_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    print(f"  Video: {total_video_frames} frames at {fps}fps")

    raw_frames = []
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        raw_frames.append(frame)
    cap.release()
    print(f"  Read {len(raw_frames)} raw frames")

    # Process all frames (remove green screen)
    print("\nStep 2: Removing green screen from all frames...")
    processed = []
    for i, frame in enumerate(raw_frames):
        result = remove_green_screen(frame, FRAME_SIZE)
        processed.append(result)
        if (i+1) % 20 == 0:
            print(f"  Processed {i+1}/{len(raw_frames)}")
    print(f"  Done: {len(processed)} frames processed")

    # Find loop point
    print("\nStep 3: Finding loop point...")
    ref = processed[0]
    best_idx = -1
    best_diff = 999

    for i in range(len(processed) // 3, len(processed)):
        diff = frame_similarity(ref, processed[i])
        if diff < best_diff:
            best_diff = diff
            best_idx = i

    print(f"  Best loop: frame {best_idx+1} (diff={best_diff:.6f})")
    loop_count = best_idx  # frames 0 through best_idx-1
    print(f"  Loop length: {loop_count} frames")

    # Save loop frames
    print(f"\nStep 4: Saving {loop_count} loop frames...")
    loop_frames = processed[:loop_count]
    for i, frame in enumerate(loop_frames):
        path = os.path.join(FRAMES_DIR, f"frame_{i+1:03d}.png")
        img = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGRA2RGBA))
        img.save(path, "PNG")
    print(f"  Saved frames 1-{loop_count}")

    # Build sprite sheet
    print(f"\nStep 5: Building sprite sheet...")
    cols = 10
    rows = math.ceil(loop_count / cols)
    sheet = np.zeros((rows * FRAME_SIZE, cols * FRAME_SIZE, 4), dtype=np.uint8)

    for i, frame in enumerate(loop_frames):
        row = i // cols
        col = i % cols
        y = row * FRAME_SIZE
        x = col * FRAME_SIZE
        sheet[y:y+FRAME_SIZE, x:x+FRAME_SIZE] = frame

    img = Image.fromarray(cv2.cvtColor(sheet, cv2.COLOR_BGRA2RGBA))
    img.save(SPRITE_SHEET_PATH, "PNG", optimize=True)

    file_size = os.path.getsize(SPRITE_SHEET_PATH) / (1024*1024)
    print(f"  Sprite sheet: {cols}x{rows}, {img.width}x{img.height}px, {file_size:.1f}MB")

    print(f"\n{'='*60}")
    print(f"RESULT: {loop_count} real frames (no blending)")
    print(f"  16 FPS = {loop_count/16:.1f}s per rotation")
    print(f"  20 FPS = {loop_count/20:.1f}s per rotation")
    print(f"  24 FPS = {loop_count/24:.1f}s per rotation")
    print(f"  Grid: {cols} cols x {rows} rows")


if __name__ == "__main__":
    main()
