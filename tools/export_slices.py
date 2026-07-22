"""Slice source sprite sheets (transparent-bg collections) into individual PNG
sprites using alpha connected-component detection. Row-major ordering."""
import os, json
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = r"D:\flutter_proj\Wingwhirl_Run\assets"
OUT = r"D:\flutter_proj\Wingwhirl_Run\assets\sprites"

# per-sheet: (folder, dilate, min_area, row_height_for_sort, expected)
CONFIG = {
    "chickens_asset":                 ("chickens", 2, 400, 200, 30),
    "collection_fish_asset":          ("fish",     2, 400, 100, 48),
    "egg_asset":                      ("eggs",     3, 400, 300, 10),
    "coins_asset":                    ("coins",    2, 300, 150, None),
    "fishing_equipment_asset":        ("equipment",2, 300, 120, None),
    "collectible_rewards_asset":      ("rewards",  2, 400, 200, None),
    "water_effects_and_objects_asset":("water",    2, 200, 70,  None),
    "nature_objects_asset":           ("nature",   3, 400, 170, None),
    "shoreline_objects_asset":        ("shore",    3, 400, 120, None),
    "wooden_objects_asset":           ("wooden",   3, 400, 130, None),
}

def slice_sheet(name, folder, dilate, min_area, row_h, pad=6):
    im = Image.open(os.path.join(SRC, name + ".webp")).convert("RGBA")
    arr = np.array(im)
    a = arr[:, :, 3]
    mask = a > 12
    struct = np.ones((dilate * 2 + 1, dilate * 2 + 1), dtype=bool)
    d = ndimage.binary_dilation(mask, structure=struct)
    lbl, n = ndimage.label(d)
    boxes = []
    for i in range(1, n + 1):
        ys, xs = np.where(lbl == i)
        if len(xs) < min_area:
            continue
        boxes.append([int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1])
    boxes.sort(key=lambda b: (round(b[1] / row_h), b[0]))
    outdir = os.path.join(OUT, folder)
    os.makedirs(outdir, exist_ok=True)
    manifest = []
    W, H = im.size
    for idx, (x0, y0, x1, y1) in enumerate(boxes):
        x0 = max(0, x0 - pad); y0 = max(0, y0 - pad)
        x1 = min(W, x1 + pad); y1 = min(H, y1 + pad)
        crop = im.crop((x0, y0, x1, y1))
        fn = f"{folder}_{idx:02d}.png"
        crop.save(os.path.join(outdir, fn))
        manifest.append({"index": idx, "file": f"assets/sprites/{folder}/{fn}",
                         "w": x1 - x0, "h": y1 - y0})
    return manifest

os.makedirs(OUT, exist_ok=True)
full = {}
for name, (folder, dilate, min_area, row_h, expected) in CONFIG.items():
    m = slice_sheet(name, folder, dilate, min_area, row_h)
    full[folder] = m
    status = ""
    if expected is not None:
        status = "OK" if len(m) == expected else f"WARN expected {expected}"
    print(f"{name:38s} -> {len(m):3d} sprites  {status}")

with open(os.path.join(OUT, "manifest.json"), "w") as f:
    json.dump(full, f, indent=1)
print("manifest.json written")
