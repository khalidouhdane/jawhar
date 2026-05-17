"""
Diamond Frame Processor
========================
Extracts frames from green-screen diamond video,
removes green background → transparent PNGs,
then generates a WebP sprite sheet for the web loader.
"""

import cv2
import numpy as np
from PIL import Image
import os
import sys
import math

# ── Config ──────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PUBLIC_DIR = os.path.join(SCRIPT_DIR, "..", "public")
VIDEO_PATH = os.path.join(PUBLIC_DIR, "3D_diamond_gemstone_rotating_202605140429.mp4")
OUTPUT_DIR = os.path.join(PUBLIC_DIR, "diamond-frames")
SPRITE_SHEET_PATH = os.path.join(PUBLIC_DIR, "diamond-spritesheet.png")
FRAME_SIZE = 500        # Output frame size (square)
TARGET_FRAMES = 60      # Number of frames to extract (evenly spaced)
SPRITE_COLS = 10        # Sprite sheet columns

# Green screen removal thresholds (HSV)
GREEN_LOWER = np.array([35, 80, 80])
GREEN_UPPER = np.array([85, 255, 255])
EDGE_FEATHER = 3        # Pixels of edge feathering for smooth edges


def extract_frames(video_path, target_count):
    """Extract evenly-spaced frames from video."""
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"ERROR: Cannot open video: {video_path}")
        sys.exit(1)

    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    print(f"Video: {total_frames} frames, {fps:.1f}fps, {width}x{height}")
    print(f"Extracting {target_count} evenly-spaced frames...")

    # Calculate which frames to grab
    indices = [int(i * total_frames / target_count) for i in range(target_count)]

    frames = []
    for idx in indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
        ret, frame = cap.read()
        if ret:
            frames.append(frame)
        else:
            print(f"  Warning: Failed to read frame {idx}")

    cap.release()
    print(f"  Extracted {len(frames)} frames")
    return frames


def remove_green_screen(frame, size):
    """
    Remove green screen background and return RGBA image.
    Uses HSV color space for robust green detection,
    with edge feathering for smooth anti-aliased edges.
    """
    # Convert BGR → HSV for color-based masking
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)

    # Create green mask
    green_mask = cv2.inRange(hsv, GREEN_LOWER, GREEN_UPPER)

    # Also catch very bright greens that might be outside HSV range
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    bright_green = (
        (rgb[:, :, 1] > 150) &
        (rgb[:, :, 0] < 100) &
        (rgb[:, :, 2] < 100)
    )
    green_mask[bright_green] = 255

    # Invert: white = keep, black = remove
    alpha = cv2.bitwise_not(green_mask)

    # Feather edges for smooth anti-aliasing
    if EDGE_FEATHER > 0:
        alpha = cv2.GaussianBlur(alpha, (EDGE_FEATHER * 2 + 1, EDGE_FEATHER * 2 + 1), 0)

    # Clean up: remove tiny noise islands
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    alpha = cv2.morphologyEx(alpha, cv2.MORPH_OPEN, kernel)
    alpha = cv2.morphologyEx(alpha, cv2.MORPH_CLOSE, kernel)

    # Convert to RGBA
    bgra = cv2.cvtColor(frame, cv2.COLOR_BGR2BGRA)
    bgra[:, :, 3] = alpha

    # Remove green spill on edges (desaturate green from semi-transparent pixels)
    semi_mask = (alpha > 10) & (alpha < 245)
    if np.any(semi_mask):
        hsv_full = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV).astype(float)
        green_hue = (hsv_full[:, :, 0] > 35) & (hsv_full[:, :, 0] < 85)
        spill_mask = semi_mask & green_hue
        bgra[spill_mask, 1] = (bgra[spill_mask, 1] * 0.7).astype(np.uint8)  # Reduce green channel

    # Crop to square (center crop)
    h, w = bgra.shape[:2]
    if w != h:
        side = min(w, h)
        x_start = (w - side) // 2
        y_start = (h - side) // 2
        bgra = bgra[y_start:y_start + side, x_start:x_start + side]

    # Resize to target size
    bgra = cv2.resize(bgra, (size, size), interpolation=cv2.INTER_AREA)

    return bgra


def create_sprite_sheet(frames, cols, output_path):
    """Combine frames into a single sprite sheet image."""
    if not frames:
        print("ERROR: No frames to create sprite sheet")
        return

    frame_h, frame_w = frames[0].shape[:2]
    rows = math.ceil(len(frames) / cols)

    # Create blank RGBA canvas
    sheet = np.zeros((rows * frame_h, cols * frame_w, 4), dtype=np.uint8)

    for i, frame in enumerate(frames):
        row = i // cols
        col = i % cols
        y = row * frame_h
        x = col * frame_w
        sheet[y:y + frame_h, x:x + frame_w] = frame

    # Save via Pillow for proper PNG with alpha
    img = Image.fromarray(cv2.cvtColor(sheet, cv2.COLOR_BGRA2RGBA))
    img.save(output_path, "PNG", optimize=True)
    
    file_size = os.path.getsize(output_path) / (1024 * 1024)
    print(f"  Sprite sheet: {cols}x{rows} grid, {img.width}x{img.height}px, {file_size:.1f}MB")


def main():
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Step 1: Extract frames
    print("\n═══ Step 1: Extracting frames ═══")
    raw_frames = extract_frames(VIDEO_PATH, TARGET_FRAMES)

    # Step 2: Remove green screen
    print("\n═══ Step 2: Removing green screen ═══")
    processed_frames = []
    for i, frame in enumerate(raw_frames):
        result = remove_green_screen(frame, FRAME_SIZE)
        processed_frames.append(result)

        # Save individual frame as PNG
        frame_path = os.path.join(OUTPUT_DIR, f"frame_{i + 1:03d}.png")
        img = Image.fromarray(cv2.cvtColor(result, cv2.COLOR_BGRA2RGBA))
        img.save(frame_path, "PNG")

        if (i + 1) % 10 == 0:
            print(f"  Processed {i + 1}/{len(raw_frames)} frames")

    print(f"  ✓ All {len(processed_frames)} frames saved to {OUTPUT_DIR}/")

    # Step 3: Create sprite sheet
    print("\n═══ Step 3: Creating sprite sheet ═══")
    create_sprite_sheet(processed_frames, SPRITE_COLS, SPRITE_SHEET_PATH)

    # Summary
    print("\n═══ Done! ═══")
    print(f"  Individual frames: {OUTPUT_DIR}/frame_001.png → frame_{len(processed_frames):03d}.png")
    print(f"  Sprite sheet:      {SPRITE_SHEET_PATH}")
    print(f"  Frame size:        {FRAME_SIZE}x{FRAME_SIZE}px")
    print(f"  Total frames:      {len(processed_frames)}")


if __name__ == "__main__":
    main()
