import os, glob
import numpy as np
from PIL import Image

SRC = r"D:\flutter_proj\Wingwhirl_Run\assets"

def top_colors(path, k=6, sample=120):
    im = Image.open(path).convert("RGB").resize((sample, sample))
    a = np.array(im).reshape(-1, 3).astype(float)
    # simple k-means
    idx = np.random.RandomState(0).choice(len(a), k, replace=False)
    cent = a[idx]
    for _ in range(12):
        d = ((a[:, None, :] - cent[None, :, :]) ** 2).sum(2)
        lab = d.argmin(1)
        for j in range(k):
            if (lab == j).any():
                cent[j] = a[lab == j].mean(0)
    counts = np.bincount(lab, minlength=k)
    order = np.argsort(-counts)
    return [(tuple(cent[j].round().astype(int)), counts[j] / len(a)) for j in order]

for f in ["Horizontal_Loading_Screen.webp", "bg1_asset.webp", "bg7_asset.webp",
          "bg8_asset.webp", "coins_asset.webp"]:
    print("\n" + f)
    for (r, g, b), frac in top_colors(os.path.join(SRC, f)):
        print(f"  #{r:02X}{g:02X}{b:02X}  {frac*100:5.1f}%")
