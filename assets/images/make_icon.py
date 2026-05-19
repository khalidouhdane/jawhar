from PIL import Image, ImageDraw

def create_composite_icons():
    # Base setup
    size = 1024
    bg_color = (235, 235, 235, 255) # EBEBEB
    
    # 1. Prepare the scaled logo
    logo = Image.open("assets/images/diamond_logo.png").convert("RGBA")
    
    # Crop to bounding box to remove extra padding before scaling
    bbox = logo.getbbox()
    if bbox:
        logo = logo.crop(bbox)
        
    # Scale up the logo to ~75% of 1024 = 768 (was 614)
    target_size = 768
    
    # Calculate aspect ratio
    aspect = logo.width / logo.height
    if logo.width > logo.height:
        new_w = target_size
        new_h = int(target_size / aspect)
    else:
        new_h = target_size
        new_w = int(target_size * aspect)
        
    logo_scaled = logo.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # Calculate centered position
    x = (size - new_w) // 2
    y = (size - new_h) // 2
    
    # --- Create iOS Icon (Solid Square, no transparency) ---
    ios_bg = Image.new("RGBA", (size, size), bg_color)
    ios_bg.alpha_composite(logo_scaled, (x, y))
    ios_bg.convert("RGB").save("assets/images/diamond_bg_ios.png")
    print("Created diamond_bg_ios.png")
    
    # --- Create Desktop/Web Icon (Rounded Rectangle, transparent corners) ---
    desktop_bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(desktop_bg)
    
    # Draw rounded rectangle (radius ~22.5% of size = 230)
    radius = 230
    draw.rounded_rectangle([(0, 0), (size-1, size-1)], radius=radius, fill=bg_color)
    
    # Composite logo
    desktop_bg.alpha_composite(logo_scaled, (x, y))
    desktop_bg.save("assets/images/diamond_bg_desktop.png")
    print("Created diamond_bg_desktop.png")

    # --- Create Android Padded Logo (Transparent bg) ---
    # We want the logo to be larger relative to the frame.
    # The current logo inside diamond_logo_padded is ~59% width. Let's make it ~75% width.
    android_size = 1024
    android_bg = Image.new("RGBA", (android_size, android_size), (0, 0, 0, 0))
    android_bg.alpha_composite(logo_scaled, (x, y))
    android_bg.save("assets/images/diamond_logo_padded.png")
    print("Created diamond_logo_padded.png")

if __name__ == "__main__":
    create_composite_icons()
