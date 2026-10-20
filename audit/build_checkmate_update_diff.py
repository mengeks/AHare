"""Freeze macro-expanded tables/text before numerical manuscript latexdiff.

The baseline is the manuscript before this edit with the pulled d4b42e4
GitHub outputs, not the older pre-pull private result batch.
Run from the manuscript directory after the pipeline has completed.
"""
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[2]
backup = root / "local-history/hajime-censoring-before-20261005-pfkWdM"
out = root / "AHare/output/pdf"
out.mkdir(parents=True, exist_ok=True)

def strip_comments(text):
    lines = []
    for line in text.splitlines():
        content = re.split(r"(?<!\\)%", line, maxsplit=1)[0]
        # A comment-only line does not insert a paragraph break in TeX.
        if not content.strip() and "%" in line:
            continue
        lines.append(content.rstrip())
    return "\n".join(lines)

def freeze(source, output_tree):
    numbers = (output_tree / "numbers.tex").read_text()
    macros = dict(re.findall(r"\\newcommand\{\\([A-Za-z]+)\}\{([^{}]*)\}", numbers))
    def expand(text):
        text = strip_comments(text)
        def include(match):
            name = match.group(1)
            if name == "AHare/output/numbers.tex":
                return ""
            if name.startswith("AHare/output/"):
                path = output_tree / name.removeprefix("AHare/output/")
            else:
                path = root / name
            if not path.suffix:
                path = path.with_suffix(".tex")
            return expand(path.read_text())
        text = re.sub(r"\\input\{([^}]+)\}", include, text)
        return re.sub(r"\\([A-Za-z]+)(?![A-Za-z])",
                      lambda m: macros.get(m.group(1), m.group(0)), text)
    text = expand(source.read_text())
    # latexdiff treats resizebox's table argument as opaque. Unwrap frozen
    # review inputs so its token comparison can see each numerical cell.
    return re.sub(r"\\resizebox\{\\textwidth\}\{!\}\{\s*"
                  r"(\\begin\{tabular\}.*?\\end\{tabular\})\s*\}",
                  r"\1", text, flags=re.S)

old = freeze(backup / "paper.tex", backup / "github-output")
new = freeze(root / "paper.tex", root / "AHare/output")
old_path = out / "checkmate-update-before-expanded.tex"
new_path = out / "checkmate-update-after-expanded.tex"
old_path.write_text(old)
new_path.write_text(new)
diff = subprocess.run(["latexdiff", "--type=CFONT", "--graphics-markup=none",
    "--math-markup=whole", str(old_path), str(new_path)],
    capture_output=True, text=True, check=True).stdout
# Marked-up cells before a booktabs noalign rule can make latexdiff invalid.
# Remove rules only in this review copy, keeping every old/new cell value.
diff = re.sub(r"\\(?:toprule|midrule|bottomrule)\b(?:\[[^]]*\])?", "", diff)
diff = re.sub(r"\\cmidrule(?:\([^)]*\))?\{[^}]*\}", "", diff)
# Restore width control in the review copy after numerical markup is made.
def resize_wide_table(match):
    return (r"\resizebox{\textwidth}{!}{" + match.group(0) + "}"
            if len(match.group(1)) >= 8 else match.group(0))
diff = re.sub(r"\\begin\{tabular\}\{([^}]+)\}.*?\\end\{tabular\}",
              resize_wide_table, diff, flags=re.S)
assert r"\DIFdel{0.664" in diff and r"\DIFadd{0.534" in diff, \
    "Sensitivity table numerical changes must be visible in the redline"
(out / "AH-ARE-05Oct2026-diff.tex").write_text(diff)
# Literal manuscript-source diff is separate from changed generated numbers.
source_diff = subprocess.run(["diff", "-u", "--label=paper.tex (before)",
    "--label=paper.tex (after)", str(backup / "paper.tex"), str(root / "paper.tex")],
    capture_output=True, text=True)
if source_diff.returncode not in (0, 1):
    raise RuntimeError(source_diff.stderr)
(root / "AHare/audit/PAPER_05OCT2026.diff").write_text(source_diff.stdout)
refs_diff = subprocess.run(["diff", "-u", "--label=refs.bib (before)",
    "--label=refs.bib (after)", str(backup / "refs.bib"), str(root / "refs.bib")],
    capture_output=True, text=True)
if refs_diff.returncode not in (0, 1):
    raise RuntimeError(refs_diff.stderr)
(root / "AHare/audit/REFS_05OCT2026.diff").write_text(refs_diff.stdout)
print("Frozen GitHub-baseline/new tables and number macros; generated both diffs.")
