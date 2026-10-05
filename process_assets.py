import os
import cv2
import numpy as np
from PIL import Image

assets_dir = r"C:\Users\HP\.gemini\antigravity\scratch\KitchenChaos\assets"
out_dir = r"C:\Users\HP\.gemini\antigravity\scratch\KitchenChaos\assets\processed"
os.makedirs(out_dir, exist_ok=True)

# 1. Process Backgrounds (resize/crop to 960x540)
def process_backgrounds():
    # Kitchen Day
    day_src = os.path.join(assets_dir, "pdf1_p1_2_X8.png")
    if os.path.exists(day_src):
        im = Image.open(day_src)
        # Resize to 960x540 with high quality Lanczos
        im_resized = im.resize((960, 540), Image.Resampling.LANCZOS)
        im_resized.save(os.path.join(out_dir, "bg_day.png"))
        print("Saved bg_day.png (960x540)")

    # Kitchen Night
    night_src = os.path.join(assets_dir, "pdf1_p2_2_X13.png")
    if os.path.exists(night_src):
        im = Image.open(night_src)
        im_resized = im.resize((960, 540), Image.Resampling.LANCZOS)
        im_resized.save(os.path.join(out_dir, "bg_night.png"))
        print("Saved bg_night.png (960x540)")

    # Xiangling Grand Banquet
    xian_src = os.path.join(assets_dir, "pdf1_p3_1_X16.png")
    if os.path.exists(xian_src):
        im = Image.open(xian_src)
        im_resized = im.resize((960, 540), Image.Resampling.LANCZOS)
        im_resized.save(os.path.join(out_dir, "bg_xiangling.png"))
        print("Saved bg_xiangling.png (960x540)")

    # Rotoven Map
    rot_src = os.path.join(assets_dir, "pdf1_p3_2_X17.png")
    if os.path.exists(rot_src):
        im = Image.open(rot_src)
        im_resized = im.resize((960, 540), Image.Resampling.LANCZOS)
        im_resized.save(os.path.join(out_dir, "bg_rotoven.png"))
        print("Saved bg_rotoven.png (960x540)")

process_backgrounds()
