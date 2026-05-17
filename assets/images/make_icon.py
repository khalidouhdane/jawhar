from PIL import Image, ImageDraw

def create_composite_icons():
    # Base setup
    size = 1024
    bg_color = (235, 235, 235, 255) # EBEBEB
    
    # 1. Prepare the scaled logo
    logo = Image.open("diamond_logo.png").convert("RGBA")
    
    # Crop to bounding box to remove extra padding before scaling
    bbox = logo.getbbox()
    if bbox:
        logo = logo.crop(bbox)
        
    # Scale up the logo to ~60% of 1024 = 614
    target_size = 614
    
    # Calculate aspect ratio
    aspect = logo.width / logo.height
    if logo.width > logo.height:
        new_w = target_size
        new_h = int(target_size / aspect)
    else:
        new_h = target_size
        new_w = int(target_size * aspect)
        
    logo = logo.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Calculate centered position
    x = (size - new_w) // 2
    y = (size - new_h) // 2
    
    # --- Create iOS Icon (Solid Square, no transparency) ---
    ios_bg = Image.new("RGBA", (size, size), bg_color)
    ios_bg.alpha_composite(logo, (x, y))
    ios_bg.convert("RGB").save("diamond_bg_ios.png")
    print("Created diamond_bg_ios.png")
    
    # --- Create Desktop/Web Icon (Rounded Rectangle, transparent corners) ---
    desktop_bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(desktop_bg)
    
    # Draw rounded rectangle (radius ~22.5% of size = 230)
    radius = 230
    draw.rounded_rectangle([(0, 0), (size-1, size-1)], radius=radius, fill=bg_color)
    
    # Composite logo
    desktop_bg.alpha_composite(logo, (x, y))
    desktop_bg.save("diamond_bg_desktop.png")
    print("Created diamond_bg_desktop.png")

if __name__ == "__main__":
    create_composite_icons()
