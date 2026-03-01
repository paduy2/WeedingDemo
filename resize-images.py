#!/usr/bin/env python3
"""
Resize all images in assets/images/ to 1920x1080 max size
Keeps aspect ratio and converts to progressive JPEG with 85% quality
"""

from PIL import Image
import os
from pathlib import Path

# Configuration
IMAGE_DIR = Path("assets/images")
MAX_WIDTH = 1920
MAX_HEIGHT = 1080
QUALITY = 85

def resize_image(image_path):
    """Resize image to fit within MAX_WIDTH x MAX_HEIGHT while keeping aspect ratio"""
    print(f"Processing: {image_path.name}")

    # Open image
    img = Image.open(image_path)
    original_size = img.size

    # Convert RGBA to RGB if needed
    if img.mode == 'RGBA':
        img = img.convert('RGB')

    # Calculate new size keeping aspect ratio
    img.thumbnail((MAX_WIDTH, MAX_HEIGHT), Image.Resampling.LANCZOS)

    # Save with optimization
    img.save(
        image_path,
        'JPEG',
        quality=QUALITY,
        optimize=True,
        progressive=True
    )

    new_size = Image.open(image_path).size
    original_mb = original_size[0] * original_size[1] * 3 / (1024 * 1024)
    new_mb = os.path.getsize(image_path) / (1024 * 1024)

    print(f"  {original_size[0]}x{original_size[1]} -> {new_size[0]}x{new_size[1]}")
    print(f"  Size: {new_mb:.2f}MB")

def main():
    # Find all JPG/JPEG files
    image_files = list(IMAGE_DIR.glob("*.jpg")) + list(IMAGE_DIR.glob("*.JPG")) + \
                  list(IMAGE_DIR.glob("*.jpeg")) + list(IMAGE_DIR.glob("*.JPEG"))

    if not image_files:
        print("No images found in assets/images/")
        return

    print(f"Found {len(image_files)} images to resize")
    print(f"Target: max {MAX_WIDTH}x{MAX_HEIGHT}, quality {QUALITY}%\n")

    for img_path in image_files:
        try:
            resize_image(img_path)
            print()
        except Exception as e:
            print(f"  ERROR: {e}\n")

    print("Done!")

if __name__ == "__main__":
    main()
