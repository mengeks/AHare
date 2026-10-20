"""Extract numeric cells from the explicitly supplied 27Sep PDF via pdftotext.

Run from AHare/: python3 audit/extract_old_pdf_tables.py ../AH-ARE-27Sep2026.pdf
The old PDF uses R=RMST, A=RAH; exported metric names use D=RMST, R=RAH.
"""
import csv
import hashlib
import re
import subprocess
import sys
from pathlib import Path

pdf = Path(sys.argv[1])
text = subprocess.check_output(["pdftotext", "-layout", str(pdf), "-"], text=True)
metrics = ["are_drmst_cox", "are_rah_cox", "are_rah_drmst",
           "ere_drmst_cox", "ere_rah_cox", "ere_rah_drmst"]
cells = []
def add(table, setting, values, names=metrics):
    assert len(values) == len(names), (table, setting, values)
    for name, value in zip(names, values):
        cells.append(dict(table=table, setting=setting, metric=name, old=float(value)))
def section(start, end):
    return text.split(start, 1)[1].split(end, 1)[0]
def decimals(line):
    return re.findall(r"(?<![\w.])-?\d+\.\d+", line.replace("−", "-"))

rows=[]
for line in section("Table 1:","Consequently, two trials").splitlines():
    m=re.search(r"\b(Cox|D-RMST|RAH)\b",line)
    values=decimals(line)
    if m and len(values)==4:
        dataset="original" if len(rows)<3 else "sensitivity"
        add(1,dataset+";"+m.group(1),values,["estimate","ci_lo","ci_hi","pval"])
        rows.append(line)
assert len(rows)==6

lines = section("Table 2:", "4.3    Non-PH").splitlines()
rows = [line for line in lines if re.search(r"(?:ARE|ERE)\([RA]/[CR]\)", line)]
assert len(rows) == 12
for i, line in enumerate(rows):
    values = decimals(line)
    assert len(values) == 5, line
    for survival, value in zip([.1,.3,.5,.7,.9], values):
        add(2, f"s0={survival:.2f};{'light' if i<6 else 'heavy'}",
            [value], [metrics[i % 6]])

for table, start, end, count in [
    (3,"Table 3:","RAH-based test, with",10),
    (8,"Table 8:","Table 9:",18),
    (9,"Table 9:","Table 10:",10),
]:
    rows = []
    for line in section(start,end).splitlines():
        m = re.match(r"\s*(\d+\.\d+)\s+(light|heavy|L|H)\s+(.+)",line)
        if not m: continue
        parameter, censor, tail = m.groups()
        censor = {"L":"light","H":"heavy"}.get(censor,censor)
        setting = f"{'s0' if table==8 else 'shape'}={float(parameter):.3f};{censor}"
        values = decimals(tail)
        names = metrics
        if table == 9:
            # Old power columns are Cox, RAH, RMST.
            values = values[:3]+[values[3],values[5],values[4]]+values[6:]
            names = metrics[:3]+["power_cox","power_drmst","power_rah"]+metrics[3:]
        add(table,setting,values,names); rows.append(line)
    assert len(rows) == count, (table,len(rows))

rows=[]
for line in section("Table 4:","to the trial data").splitlines():
    m=re.match(r"\s*Case [23] \((fading|delayed)\)\s+([LH])\s+(.+)",line)
    if m:
        pattern,censor,tail=m.groups()
        add(4,f"{pattern};{'light' if censor=='L' else 'heavy'}",decimals(tail)); rows.append(line)
assert len(rows)==4

for line in section("Table 5:","Beyond the efficiency").splitlines():
    if "vs" not in line: continue
    values=decimals(line)
    if len(values)==2:
        metric="drmst_cox" if "D-RMST vs Cox" in line else "rah_drmst" if "vs D-RMST" in line else "rah_cox"
        add(5,"baseline",values,["are_"+metric,"ere_"+metric])
for line in section("Table 6:","We now assess").splitlines():
    m=re.match(r"\s*(Cox|D-RMST|RAH)\s+(0\.\d+)\s+(\d+)\s*$",line)
    if m:
        method,power,n=m.groups(); add(6,method,[power,n],["power","n80"])

settings=["tau=18","tau=21","tau=24","dropout=0.001","dropout=0.005","dropout=0.020","nonph","ph"]
rows=[line for line in section("Table 7:","benefits, a pattern").splitlines() if len(decimals(line))>=6]
assert len(rows)==8
for setting,line in zip(settings,rows): add(7,setting,decimals(line)[-6:])

rows=[]
for line in section("Table 10:","E     Additional").splitlines():
    m=re.match(r"\s*(Exp\(.*?\)|Weibull\(.*?\))\s+([LH])\s+(.+)",line)
    if m:
        label,censor,tail=m.groups()
        shape=1. if label.startswith("Exp") else float(re.search(r"(0\.7|1\.5)",label).group(1))
        add(10,f"shape={shape:.3f};{'light' if censor=='L' else 'heavy'}",decimals(tail)); rows.append(line)
assert len(rows)==6
rows=[]
for line in section("Table 11:","References").splitlines():
    m=re.match(r"\s*([LH])\s+(.+)",line)
    if m and len(decimals(m.group(2)))==6:
        add(11,"light" if m.group(1)=="L" else "heavy",decimals(m.group(2))); rows.append(line)
assert len(rows)==2

out=Path("audit/old27_table_cells.csv")
with out.open("w",newline="") as file:
    writer=csv.DictWriter(file,fieldnames=["table","setting","metric","old"],lineterminator="\n")
    writer.writeheader(); writer.writerows(cells)
Path("audit/old27_pdf_sha256.txt").write_text(hashlib.sha256(pdf.read_bytes()).hexdigest()+"  "+pdf.name+"\n")
print(f"Extracted {len(cells)} cells from {pdf.name}")
