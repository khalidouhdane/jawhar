"""
Extract a single diamond frame for use as the nav logo icon.
Picks a visually interesting angle and exports at small size.
"""

from PIL import Image
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PUBLIC_DIR = os.path.join(SCRIPT_DIR, "..", "public")
SPRITE_PATH = os.path.join(PUBLIC_DIR, "diamond-spritesheet.webp")

# Sprite sheet config
COLS = 10
ROWS = 19
TOTAL_FRAMES = 184

# Pick a few candidate frames at different rotation angles
CANDIDATES = [1, 10, 25, 46, 70, 92, 120, 138, 160]
LOGO_SIZE = 64  # Export at 64px — crisp at 32px display with 2x retina


def extract_frame(sprite, frame_idx, size):
    """Extract a single frame from the sprite sheet."""
    frame_w = sprite.width // COLS
    frame_h = sprite.height // ROWS
    
    col = frame_idx % COLS
    row = frame_idx // COLS
    
    x = col * frame_w
    y = row * frame_h
    
    frame = sprite.crop((x, y, x + frame_w, y + frame_h))
    return frame.resize((size, size), Image.LANCZOS)


def main():
    sprite = Image.open(SPRITE_PATH)
    print(f"Sprite sheet: {sprite.width}x{sprite.height}")
    
    # Export candidates for visual review
    for idx in CANDIDATES:
        frame = extract_frame(sprite, idx, LOGO_SIZE)
        path = os.path.join(PUBLIC_DIR, f"diamond-logo-candidate-{idx}.png")
        frame.save(path, "PNG")
    
    # Also export the best one (frame 1 — the "hero" angle) as final
    best = extract_frame(sprite, 0, LOGO_SIZE)
    final_path = os.path.join(PUBLIC_DIR, "diamond-logo.png")
    best.save(final_path, "PNG")
    
    size_kb = os.path.getsize(final_path) / 1024
    print(f"Logo exported: {final_path} ({size_kb:.1f}KB)")
    print(f"Candidates exported for review: diamond-logo-candidate-*.png")


if __name__ == "__main__":
    main()
