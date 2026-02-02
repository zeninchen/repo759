import sys
import csv
import matplotlib
matplotlib.use("Agg")  # important on clusters (no display)
import matplotlib.pyplot as plt

csv_path = sys.argv[1]
pdf_path = sys.argv[2]

ns = []
ts = []

with open(csv_path, newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        ns.append(int(row["n"]))
        ts.append(float(row["time_ms"]))

plt.figure()
plt.plot(ns, ts, marker="o")
plt.xscale("log", base=2)  # n is powers of 2
plt.yscale("log")          # often helpful for scaling (optional)
plt.xlabel("n (number of elements)")
plt.ylabel("Time (ms)")
plt.title("Task1 Scaling Analysis (Inclusive Scan)")
plt.grid(True, which="both", linestyle="--", linewidth=0.5)
plt.tight_layout()
plt.savefig(pdf_path)
