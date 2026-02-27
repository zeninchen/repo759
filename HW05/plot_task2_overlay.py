# plot_task2_overlay.py
# Reads task2_1024.csv and task2_256.csv and overlays runtime vs N.
# Usage:
#   python3 plot_task2_overlay.py
# Outputs:
#   task2_overlay.png

import csv
import math
import matplotlib.pyplot as plt

def read_csv(path):
    Ns, Ts = [], []
    with open(path, "r", newline="") as f:
        r = csv.DictReader(f)
        for row in r:
            N = int(float(row["N"]))          # in case N is written as 1.073741824e+09 etc.
            t = float(row["time_ms"])
            Ns.append(N)
            Ts.append(t)
    return Ns, Ts

def to_log2(Ns):
    return [math.log2(n) for n in Ns]

# Change filenames here if yours differ
f1024 = "task2_1024.csv"
f256  = "task2_256.csv"

N1, T1 = read_csv(f1024)
N2, T2 = read_csv(f256)

x1 = to_log2(N1)
x2 = to_log2(N2)

plt.figure()
plt.plot(x1, T1, marker="o", label="threads_per_block = 1024")
plt.plot(x2, T2, marker="o", label="threads_per_block = 256")

plt.xlabel("log2(N)")
plt.ylabel("Time (ms)")
plt.title("Reduction runtime vs N (overlay)")
plt.grid(True)
plt.legend()

plt.tight_layout()
plt.savefig("task2_overlay.png", dpi=300)
plt.show()