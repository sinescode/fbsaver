import os
from PIL import Image

# Path to your Flutter project
PROJECT_PATH = "android/app/src/main/res"

# Input logo (must be square, recommended 1024x1024)
INPUT_IMAGE = "logo.png"

# Output icon name
ICON_NAME = "ic_launcher.png"

# Icon sizes for Android
sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

def generate_icons():
    if not os.path.exists(INPUT_IMAGE):
        print(f"❌ {INPUT_IMAGE} not found. Put your photo in this folder.")
        return

    img = Image.open(INPUT_IMAGE).convert("RGBA")

    for folder, size in sizes.items():
        out_dir = os.path.join(PROJECT_PATH, folder)
        os.makedirs(out_dir, exist_ok=True)

        resized = img.resize((size, size), Image.LANCZOS)
        output_path = os.path.join(out_dir, ICON_NAME)
        resized.save(output_path, format="PNG")

        print(f"✅ Saved {output_path} ({size}x{size})")

if __name__ == "__main__":
    generate_icons()
