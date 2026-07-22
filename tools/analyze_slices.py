import os, glob
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

SRC = r"D:\flutter_proj\Wingwhirl_Run\assets"
OUT = r"D:\flutter_proj\Wingwhirl_Run\_slices_analysis"
os.makedirs(OUT, exist_ok=True)

def components(name, alpha_thresh=12, dilate=3, min_area=400):
    path = os.path.join(SRC, name + ".webp")
    im = Image.open(path).convert("RGBA")
    a = np.array(im)[:, :, 3]
    mask = a > alpha_thresh
    if dilate > 0:
        struct = np.ones((dilate * 2 + 1, dilate * 2 + 1), dtype=bool)
        d = ndimage.binary_dilation(mask, structure=struct)
    else:
        d = mask
    lbl, n = ndimage.label(d)
    boxes = []
    for i in range(1, n + 1):
        ys, xs = np.where(lbl == i)
        if len(xs) < min_area:
            continue
        boxes.append((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
    boxes.sort(key=lambda b: (round(b[1] / 80), b[0]))
    return im, boxes

def overlay(name, **kw):
    im, boxes = components(name, **kw)
    ov = im.copy()
    dr = ImageDraw.Draw(ov)
    for idx, b in enumerate(boxes):
        dr.rectangle(b, outline=(255, 0, 0, 255), width=4)
    ov.convert("RGB").save(os.path.join(OUT, name + "_overlay.png"))
    return len(boxes)

for name, kw in [
    ("chickens_asset", dict(dilate=2)),
    ("collection_fish_asset", dict(dilate=2)),
    ("egg_asset", dict(dilate=3)),
    ("coins_asset", dict(dilate=2)),
]:
    c = overlay(name, **kw)
    print(name, "->", c, "objects")
