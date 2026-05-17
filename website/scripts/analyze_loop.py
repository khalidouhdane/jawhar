"""
Analyze diamond frames to find the perfect loop.
Compares each frame to frame 1 to find where the rotation completes a full 360.
"""

import cv2
import numpy as np
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
FRAMES_DIR = os.path.join(SCRIPT_DIR, "..", "public", "diamond-frames")

def load_frame(path):
    """Load frame and extract just the alpha-masked content for comparison."""
    img = cv2.imread(path, cv2.IMREAD_UNCHANGED)
    if img is None:
        return None
    # Use alpha channel to mask, then compare RGB
    if img.shape[2] == 4:
        alpha = img[:, :, 3]
        # Zero out transparent pixels for fair comparison
        rgb = img[:, :, :3].copy()
        rgb[alpha < 128] = 0
        return rgb
    return img[:, :, :3]


def frame_similarity(f1, f2):
    """Compute normalized similarity between two frames (0=identical, 1=max different)."""
    diff = cv2.absdiff(f1, f2)
    return np.mean(diff) / 255.0


def main():
    # Load all frames
    frame_files = sorted([f for f in os.listdir(FRAMES_DIR) if f.endswith('.png')])
    print(f"Found {len(frame_files)} frames")

    frames = []
    for f in frame_files:
        img = load_frame(os.path.join(FRAMES_DIR, f))
        if img is not None:
            frames.append((f, img))

    if len(frames) < 2:
        print("ERROR: Not enough frames")
        return

    # Compare every frame to frame 1
    ref = frames[0][1]
    print(f"\nReference frame: {frames[0][0]}")
    print(f"{'Frame':<20} {'Similarity diff':<20} {'Notes'}")
    print("-" * 60)

    similarities = []
    for i, (name, frame) in enumerate(frames):
        diff = frame_similarity(ref, frame)
        similarities.append((i, name, diff))
        
        marker = ""
        if i == 0:
            marker = "<-- reference"
        elif diff < 0.02:
            marker = "<-- VERY SIMILAR to frame 1 (loop candidate)"
        elif diff < 0.04:
            marker = "<-- similar"
        
        print(f"{name:<20} {diff:<20.6f} {marker}")

    # Find the best loop point (skip frame 0 itself, find frame most similar to frame 1)
    # Look at frames in the second half to find where the rotation completes
    candidates = [(i, name, diff) for i, name, diff in similarities if i > len(frames) // 3]
    
    if candidates:
        best = min(candidates, key=lambda x: x[2])
        print(f"\n{'='*60}")
        print(f"BEST LOOP POINT: Frame {best[1]} (index {best[0]})")
        print(f"  Similarity to frame 1: {best[2]:.6f}")
        print(f"  Usable frames: 1 through {best[0]} ({best[0]} frames)")
        print(f"  At 8 FPS: {best[0] / 8:.1f}s per rotation")
        print(f"  At 10 FPS: {best[0] / 10:.1f}s per rotation")
        print(f"  At 12 FPS: {best[0] / 12:.1f}s per rotation")
        print(f"  At 15 FPS: {best[0] / 15:.1f}s per rotation")

    # Also show the similarity curve to visualize the rotation
    print(f"\n{'='*60}")
    print("SIMILARITY CURVE (lower = more similar to frame 1):")
    max_diff = max(d for _, _, d in similarities)
    for i, name, diff in similarities:
        bar_len = int((diff / max_diff) * 40) if max_diff > 0 else 0
        bar = "#" * bar_len
        print(f"  {i:3d} | {bar}")


if __name__ == "__main__":
    main()
