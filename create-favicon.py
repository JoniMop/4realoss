#!/usr/bin/env python3

from PIL import Image, ImageDraw, ImageFont
import sys
import os

def create_4realoss_favicon():
    # Create a 32x32 favicon (standard size)
    size = 32
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))  # Transparent background
    draw = ImageDraw.Draw(img)
    
    # Use a modern color scheme - purple/blue gradient like 4RealOSS branding
    # Create a circle background
    margin = 2
    draw.ellipse([margin, margin, size-margin, size-margin], 
                fill=(147, 51, 234),  # Purple color (#9333EA)
                outline=(59, 130, 246), width=1)  # Blue outline (#3B82F6)
    
    # Draw "4R" text in white
    try:
        # Try to use a default font
        font_size = 12
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
        except:
            try:
                font = ImageFont.truetype("arial.ttf", font_size)
            except:
                font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()
    
    # Draw "4R" in the center
    text = "4R"
    
    # Get text size and center it
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - 1  # Slight adjustment for better centering
    
    # Draw text with white color
    draw.text((x, y), text, fill=(255, 255, 255), font=font)
    
    return img

def main():
    favicon_path = "/home/kali/Desktop/4realoss/public/img/favicon.png"
    
    # Backup the original favicon
    if os.path.exists(favicon_path):
        backup_path = favicon_path.replace('.png', '-gogs-backup.png')
        os.rename(favicon_path, backup_path)
        print(f"✅ Backed up original favicon to {backup_path}")
    
    # Create new 4RealOSS favicon
    favicon = create_4realoss_favicon()
    favicon.save(favicon_path, 'PNG')
    print(f"✅ Created new 4RealOSS favicon at {favicon_path}")
    
    # Also create a 16x16 version for better compatibility
    favicon_16 = favicon.resize((16, 16), Image.LANCZOS)
    favicon_16_path = favicon_path.replace('.png', '-16.png')
    favicon_16.save(favicon_16_path, 'PNG')
    print(f"✅ Created 16x16 version at {favicon_16_path}")
    
    print("🎨 New 4RealOSS favicon created successfully!")

if __name__ == "__main__":
    main()