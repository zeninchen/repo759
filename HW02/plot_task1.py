#!/usr/bin/env python3
import csv
import sys
import matplotlib
matplotlib.use("Agg")  # required on clusters (no display)
import matplotlib.pyplot as plt

def read_csv(path: str):
    ns = []
    ts = []
    with open(path, "r", newline="") as f:
        reader = csv.DictReader(f)
        if "n" not in reader.fieldnames or "time_ms" not in reader.fieldnames:
            raise ValueError(f"CSV must have headers 'n' and 'time_ms'. Found: {reader.fieldnames}")
        for row in reader:
            ns.append(int(row["n"]))
            ts.append(float(row["time_ms"]))
    return ns, ts

def main():
    # Usage: python3 plot_task1.py task1_times.csv task1.pdf
    csv_in = sys.argv[1] if len(sys.argv) > 1 else "task1_times.csv"
    pdf_out = sys.argv[2] if len(sys.argv) > 2 else "task1.pdf"

    ns, ts = read_csv(csv_in)

    plt.figure()
    plt.plot(ns, ts, marker="o")

    # n values are powers of 2, so log2 x-axis is a natural view
    plt.xscale("log", base=2)

    plt.xlabel("n (number of elements)")
    plt.ylabel("Time (ms)")
    plt.title("Task1 Scaling Analysis: Inclusive Scan Time vs n")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.tight_layout()
    plt.savefig(pdf_out)

if __name__ == "__main__":
    main()
