"""Freeze both LaTeX input trees before latexdiff, including table bodies.

The supplied 27Sep PDF is the numerical authority for the cell audit.
The nearest preserved editable source is the pre-Phase-2 snapshot.
Run from AHare/: python3 audit/build_redline.py
"""
from pathlib import Path
import re
import subprocess

repo=Path(__file__).resolve().parents[1]
root=repo.parent
def strip_comments(text):
    lines=[]
    for line in text.splitlines():
        content=re.split(r"(?<!\\)%",line,maxsplit=1)[0]
        if not content.strip() and "%" in line: continue
        lines.append(content.rstrip())
    return "\n".join(lines)
def expand(text):
    text=strip_comments(text)
    def include(match):
        path=root/match.group(1)
        if not path.suffix: path=path.with_suffix(".tex")
        if not path.exists(): raise FileNotFoundError(path)
        return expand(path.read_text())
    return re.sub(r"\\input\{([^}]+)\}",include,text)
old=expand((root/"old/paper-2026-09-30-pre-phase2.tex").read_text())
new=expand((root/"paper.tex").read_text())
for name,text in [("old-source-expanded.tex",old),("new-source-expanded.tex",new)]:
    text=text.replace("AHare/output/","output/")
    text=text.replace(r"\bibliography{refs}",r"\bibliography{manuscript/refs}")
    (repo/"audit"/name).write_text(text)
output=repo/"output/pdf/AH-ARE-redline.tex"
with output.open("w") as file:
    subprocess.run(["latexdiff","--type=CFONT","--graphics-markup=none","--math-markup=whole",
                    str(repo/"audit/old-source-expanded.tex"),str(repo/"audit/new-source-expanded.tex")],
                   stdout=file,check=True)
# Latexdiff can place deleted cell text before a booktabs noalign rule.
# Remove rules in the redline only; preserve all old/new cell text and colors.
diff=output.read_text()
diff=re.sub(r"\\(?:toprule|midrule|bottomrule)\b(?:\[[^]]*\])?", "", diff)
diff=re.sub(r"\\cmidrule(?:\([^)]*\))?\{[^}]*\}", "", diff)
# Old and new inline cells can make the small crossing table wider than a page.
# Scale only this redline table; the two manuscript versions retain normal type.
table_start=diff.index(r"\label{tab:sim-crossing}")
prefix,tail=diff[:table_start],diff[table_start:]
tail=tail.replace(r"\begin{tabular}{lcccccc}",
                  r"\resizebox{\textwidth}{!}{\begin{tabular}{lcccccc}",1)
tail=tail.replace(r"\end{tabular}",r"\end{tabular}}",1)
diff=prefix+tail
output.write_text(diff)
print("Frozen old/new input trees and generated a redline including table contents")
