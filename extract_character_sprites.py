import os
import cv2
import numpy as np

assets_dir = r"C:\Users\HP\.gemini\antigravity\scratch\KitchenChaos\assets"
out_dir = r"C:\Users\HP\.gemini\antigravity\scratch\KitchenChaos\assets\processed"
os.makedirs(out_dir, exist_ok=True)

def make_transparent_sprite(cell, bg_min=180, bg_max=255, max_diff=14):
    h, w = cell.shape[:2]
    diff = np.max(cell, axis=2) - np.min(cell, axis=2)
    mean_v = np.mean(cell, axis=2)
    is_bg = (diff < max_diff) & (mean_v >= bg_min) & (mean_v <= bg_max)

    flood_mask = np.zeros((h + 2, w + 2), dtype=np.uint8)
    bg_u8 = is_bg.astype(np.uint8) * 255

    # Flood fill from perimeter
    for x in range(0, w, 5):
        for y in [0, h - 1]:
            if is_bg[y, x] and bg_u8[y, x] == 255:
                cv2.floodFill(bg_u8, flood_mask, (x, y), 100)
    for y in range(0, h, 5):
        for x in [0, w - 1]:
            if is_bg[y, x] and bg_u8[y, x] == 255:
                cv2.floodFill(bg_u8, flood_mask, (x, y), 100)

    is_outside = (bg_u8 == 100)
    rgba = cv2.cvtColor(cell, cv2.COLOR_BGR2BGRA)
    rgba[is_outside, 3] = 0

    # Auto crop excess transparent margins
    coords = cv2.findNonZero(rgba[:, :, 3])
    if coords is not None:
        x, y, cw, ch = cv2.boundingRect(coords)
        # Pad by 2px
        x1 = max(0, x - 2)
        y1 = max(0, y - 2)
        x2 = min(w, x + cw + 2)
        y2 = min(h, y + ch + 2)
        return rgba[y1:y2, x1:x2]
    return rgba

# 1. Extract Jeff Sprites
jeff_src = os.path.join(assets_dir, "pdf2_p3_1_X12.jpg")
if os.path.exists(jeff_src):
    jeff_im = cv2.imread(jeff_src)
    # Jeff is 2048 x 1309
    # Idle front: x ~ 100..235, y ~ 110..325
    jeff_idle = make_transparent_sprite(jeff_im[105:325, 105:235])
    cv2.imwrite(os.path.join(out_dir, "jeff_idle.png"), jeff_idle)

    # Jeff walk: x ~ 105..235, y ~ 340..580
    jeff_walk = make_transparent_sprite(jeff_im[340:580, 105:235])
    cv2.imwrite(os.path.join(out_dir, "jeff_walk.png"), jeff_walk)

    # Jeff cook: x ~ 1300..1600, y ~ 850..1150
    jeff_cook = make_transparent_sprite(jeff_im[850:1150, 1330:1580])
    cv2.imwrite(os.path.join(out_dir, "jeff_cook.png"), jeff_cook)

    # Jeff victory: x ~ 1050..1320, y ~ 850..1150
    jeff_victory = make_transparent_sprite(jeff_im[850:1150, 1060:1310])
    cv2.imwrite(os.path.join(out_dir, "jeff_victory.png"), jeff_victory)

    # Jeff recipe reading: x ~ 1600..1850, y ~ 850..1150
    jeff_recipe = make_transparent_sprite(jeff_im[850:1150, 1610:1850])
    cv2.imwrite(os.path.join(out_dir, "jeff_recipe.png"), jeff_recipe)

    print("Saved Jeff sprites!")

# 2. Extract Xiangling Sprites
xian_src = os.path.join(assets_dir, "pdf2_p1_1_X5.jpg")
if os.path.exists(xian_src):
    xian_im = cv2.imread(xian_src)
    # Xiangling is 1315 x 800
    # Idle front: col 0, row 0
    xian_idle = make_transparent_sprite(xian_im[110:280, 35:140])
    cv2.imwrite(os.path.join(out_dir, "xiangling_idle.png"), xian_idle)

    # Angry with fire aura: row 2, col 1 (x ~ 150..260, y ~ 270..420)
    xian_angry = make_transparent_sprite(xian_im[280:430, 150:270])
    cv2.imwrite(os.path.join(out_dir, "xiangling_angry.png"), xian_angry)

    # Writing / judging: row 2, col 3 (x ~ 390..500, y ~ 280..430)
    xian_writing = make_transparent_sprite(xian_im[280:430, 390:510])
    cv2.imwrite(os.path.join(out_dir, "xiangling_writing.png"), xian_writing)

    # Knocked out: bottom row (x ~ 900..1200, y ~ 600..750)
    xian_defeated = make_transparent_sprite(xian_im[600:750, 950:1200])
    cv2.imwrite(os.path.join(out_dir, "xiangling_defeated.png"), xian_defeated)

    print("Saved Xiangling sprites!")

# 3. Extract Rotoven Sprites
rot_src = os.path.join(assets_dir, "pdf2_p2_1_X9.png")
if os.path.exists(rot_src):
    rot_im = cv2.imread(rot_src)
    # Rotoven grid 6 x 7 (160 x 156)
    cw, ch = 160, 156

    # Idle (row 0, col 2)
    rot_idle = make_transparent_sprite(rot_im[0:ch, cw*2:cw*3], bg_min=115, bg_max=195, max_diff=14)
    cv2.imwrite(os.path.join(out_dir, "rotoven_idle.png"), rot_idle)

    # Attack fire blast (row 4, col 4: flame breath)
    rot_attack = make_transparent_sprite(rot_im[ch*4:ch*5, cw*3:cw*5], bg_min=115, bg_max=195, max_diff=14)
    cv2.imwrite(os.path.join(out_dir, "rotoven_attack.png"), rot_attack)

    # Roar laugh (row 2, col 1)
    rot_laugh = make_transparent_sprite(rot_im[ch*2:ch*3, cw:cw*2], bg_min=115, bg_max=195, max_diff=14)
    cv2.imwrite(os.path.join(out_dir, "rotoven_laugh.png"), rot_laugh)

    # Defeated cold furnace (row 6, col 5)
    rot_defeated = make_transparent_sprite(rot_im[ch*6:ch*7, cw*4:cw*6], bg_min=115, bg_max=195, max_diff=14)
    cv2.imwrite(os.path.join(out_dir, "rotoven_defeated.png"), rot_defeated)

    print("Saved Rotoven sprites!")
