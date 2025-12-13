#!/usr/bin/env python3
"""
Fix App Icons for iOS
- Scales up the icon content to fill the entire square
- Cuts off the pre-rendered rounded corners
- Generates all required sizes for iOS
"""

from PIL import Image
import os

# Paths
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE_ICON = os.path.join(PROJECT_ROOT, "Resources/Branding/NestlingAppIcon-1024.png")
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "ios/Nuzzle/Nestling/Assets.xcassets/AppIcon.appiconset")

# Required icon sizes for iOS
ICON_SIZES = {
    "AppIcon-20@2x.png": 40,
    "AppIcon-20@3x.png": 60,
    "AppIcon-29@2x.png": 58,
    "AppIcon-29@3x.png": 87,
    "AppIcon-40@2x.png": 80,
    "AppIcon-40@3x.png": 120,
    "AppIcon-60@2x.png": 120,
    "AppIcon-60@3x.png": 180,
    "AppIcon-1024.png": 1024,
}


def get_background_color_at_edge(img, position='top'):
    """Sample background color from inside the rounded rect at an edge."""
    width, height = img.size
    
    # Sample from just inside the visible content area
    # The rounded corners typically extend about 15-20% into the image
    inset = int(width * 0.22)
    
    if position == 'top':
        return img.getpixel((width // 2, inset))
    elif position == 'bottom':
        return img.getpixel((width // 2, height - inset))
    elif position == 'left':
        return img.getpixel((inset, height // 2))
    elif position == 'right':
        return img.getpixel((width - inset, height // 2))
    elif position == 'top_left':
        return img.getpixel((inset, inset))
    elif position == 'top_right':
        return img.getpixel((width - inset, inset))
    elif position == 'bottom_left':
        return img.getpixel((inset, height - inset))
    elif position == 'bottom_right':
        return img.getpixel((width - inset, height - inset))


def scale_and_crop_icon(source_path, output_path, final_size=1024):
    """
    Scale up the icon and crop to remove rounded corners.
    """
    img = Image.open(source_path).convert('RGBA')
    width, height = img.size
    
    # Get edge colors for filling corners
    edge_colors = {
        'top': get_background_color_at_edge(img, 'top'),
        'bottom': get_background_color_at_edge(img, 'bottom'),
        'left': get_background_color_at_edge(img, 'left'),
        'right': get_background_color_at_edge(img, 'right'),
        'top_left': get_background_color_at_edge(img, 'top_left'),
        'top_right': get_background_color_at_edge(img, 'top_right'),
        'bottom_left': get_background_color_at_edge(img, 'bottom_left'),
        'bottom_right': get_background_color_at_edge(img, 'bottom_right'),
    }
    
    print(f"  Edge colors sampled:")
    print(f"    Top: RGB{edge_colors['top'][:3]}")
    print(f"    Bottom: RGB{edge_colors['bottom'][:3]}")
    
    # Scale factor - we need to scale up enough to push the rounded corners outside
    # iOS corner radius is about 22.37% on modern devices
    # We need to scale by about 1.15-1.2x to cut off the rounded corners
    scale_factor = 1.18
    
    new_size = int(width * scale_factor)
    
    # Scale up the image
    scaled = img.resize((new_size, new_size), Image.LANCZOS)
    
    # Calculate crop box to center crop back to original size
    offset = (new_size - width) // 2
    crop_box = (offset, offset, offset + width, offset + height)
    cropped = scaled.crop(crop_box)
    
    # Now we need to fill any remaining transparent pixels at the edges
    # Create a background with interpolated edge colors
    background = Image.new('RGBA', (width, height))
    bg_pixels = background.load()
    
    for y in range(height):
        for x in range(width):
            # Bilinear interpolation of edge colors
            tx = x / (width - 1) if width > 1 else 0
            ty = y / (height - 1) if height > 1 else 0
            
            # Interpolate corners
            top_color = interpolate_color(edge_colors['top_left'][:3], edge_colors['top_right'][:3], tx)
            bottom_color = interpolate_color(edge_colors['bottom_left'][:3], edge_colors['bottom_right'][:3], tx)
            final_color = interpolate_color(top_color, bottom_color, ty)
            
            bg_pixels[x, y] = (*final_color, 255)
    
    # Composite the cropped icon onto the background
    background.paste(cropped, (0, 0), cropped)
    
    # Convert to RGB (no alpha) and resize to final size
    result = background.convert('RGB')
    if final_size != width:
        result = result.resize((final_size, final_size), Image.LANCZOS)
    
    result.save(output_path, 'PNG')
    print(f"  Saved: {os.path.basename(output_path)} ({result.size[0]}x{result.size[1]})")
    
    return result


def interpolate_color(c1, c2, t):
    """Linearly interpolate between two RGB colors."""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def main():
    print("=" * 60)
    print("iOS App Icon Fixer - Scale & Crop Method")
    print("=" * 60)
    
    if not os.path.exists(SOURCE_ICON):
        print(f"ERROR: Source icon not found: {SOURCE_ICON}")
        return False
    
    print(f"\nSource: {SOURCE_ICON}")
    print(f"Output: {OUTPUT_DIR}\n")
    
    # Create the 1024x1024 icon by scaling and cropping
    print("Step 1: Creating 1024x1024 icon (scale up & crop corners)...")
    fixed_1024 = scale_and_crop_icon(SOURCE_ICON, os.path.join(OUTPUT_DIR, "AppIcon-1024.png"))
    
    # Generate all other sizes
    print("\nStep 2: Generating all required sizes...")
    
    for filename, size in ICON_SIZES.items():
        if filename == "AppIcon-1024.png":
            continue
        
        output_path = os.path.join(OUTPUT_DIR, filename)
        resized = fixed_1024.resize((size, size), Image.LANCZOS)
        resized.save(output_path, 'PNG')
        print(f"  Saved: {filename} ({size}x{size})")
    
    # Verify the result
    print("\nStep 3: Verification...")
    test_img = Image.open(os.path.join(OUTPUT_DIR, "AppIcon-1024.png"))
    print(f"  Image mode: {test_img.mode}")
    print(f"  Image size: {test_img.size}")
    
    # Check corners for transparency
    corners = [
        test_img.getpixel((0, 0)),
        test_img.getpixel((1023, 0)),
        test_img.getpixel((0, 1023)),
        test_img.getpixel((1023, 1023)),
    ]
    print(f"  Corner pixels: {corners}")
    
    print("\n" + "=" * 60)
    print("SUCCESS! All icons have been fixed.")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Open Xcode and clean the build folder (Cmd+Shift+K)")
    print("2. Delete the app from your device")
    print("3. Build and run again")
    
    return True


if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
