"""Render every manuscript/redline page and make numbered QA contact sheets."""
from pathlib import Path
import subprocess
import sys
from PIL import Image, ImageDraw

out = Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=True)
for arg in sys.argv[2:]:
    pdf = Path(arg)
    prefix = out / pdf.stem
    subprocess.run(["pdftoppm", "-r", "90", "-png", str(pdf), str(prefix)],
                   check=True, stdout=subprocess.DEVNULL)
    pages = sorted(out.glob(pdf.stem + "-*.png"))
    for start in range(0, len(pages), 6):
        batch = pages[start:start + 6]
        sheet = Image.new("RGB", (1030, 2070), "#dedede")
        draw = ImageDraw.Draw(sheet)
        for j, page in enumerate(batch):
            im = Image.open(page).convert("RGB")
            im.thumbnail((490, 635))
            x, y = 15 + (j % 2) * 515, 35 + (j // 2) * 690
            sheet.paste(im, (x, y))
            draw.text((x, y - 22), f"{pdf.stem}: page {start+j+1}", fill="black")
        sheet.save(out / f"{pdf.stem}-contact-{start//6+1}.png")
    print(pdf.name, len(pages), "pages rendered")
