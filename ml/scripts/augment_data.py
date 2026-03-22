"""
Image augmentation pipeline for training data.
Takes raw captured images and creates augmented versions to improve model robustness.

Usage:
    python augment_data.py --input ../data/raw --output ../data/augmented --copies 5
"""

import argparse
import os
import random
from pathlib import Path

try:
    from PIL import Image, ImageEnhance, ImageFilter
except ImportError:
    print("Install Pillow: pip install Pillow")
    exit(1)


def augment_image(image: Image.Image) -> Image.Image:
    """Apply random augmentations to an image."""
    augmented = image.copy()

    # Random brightness (0.7 - 1.3)
    if random.random() > 0.5:
        enhancer = ImageEnhance.Brightness(augmented)
        augmented = enhancer.enhance(random.uniform(0.7, 1.3))

    # Random contrast (0.8 - 1.2)
    if random.random() > 0.5:
        enhancer = ImageEnhance.Contrast(augmented)
        augmented = enhancer.enhance(random.uniform(0.8, 1.2))

    # Random rotation (-15 to 15 degrees)
    if random.random() > 0.5:
        angle = random.uniform(-15, 15)
        augmented = augmented.rotate(angle, expand=False, fillcolor=(128, 128, 128))

    # Random horizontal flip
    if random.random() > 0.5:
        augmented = augmented.transpose(Image.FLIP_LEFT_RIGHT)

    # Random blur
    if random.random() > 0.7:
        augmented = augmented.filter(ImageFilter.GaussianBlur(radius=random.uniform(0.5, 1.5)))

    # Random color jitter
    if random.random() > 0.5:
        enhancer = ImageEnhance.Color(augmented)
        augmented = enhancer.enhance(random.uniform(0.8, 1.2))

    return augmented


def main():
    parser = argparse.ArgumentParser(description="Augment training images")
    parser.add_argument("--input", required=True, help="Input directory with raw images")
    parser.add_argument("--output", required=True, help="Output directory for augmented images")
    parser.add_argument("--copies", type=int, default=5, help="Number of augmented copies per image")
    args = parser.parse_args()

    input_dir = Path(args.input)
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    image_extensions = {".jpg", ".jpeg", ".png", ".bmp"}
    images = [f for f in input_dir.iterdir() if f.suffix.lower() in image_extensions]

    print(f"Found {len(images)} images in {input_dir}")

    for img_path in images:
        image = Image.open(img_path)

        # Copy original
        image.save(output_dir / img_path.name)

        # Create augmented copies
        for i in range(args.copies):
            augmented = augment_image(image)
            stem = img_path.stem
            suffix = img_path.suffix
            augmented.save(output_dir / f"{stem}_aug{i}{suffix}")

    total = len(images) * (args.copies + 1)
    print(f"Generated {total} images in {output_dir}")


if __name__ == "__main__":
    main()
