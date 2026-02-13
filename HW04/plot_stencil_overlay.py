#!/usr/bin/env python3
import sys
import pandas as pd
import matplotlib.pyplot as plt

def main():
    # Usage:
    #   python plot_stencil_overlay.py task2_1024.csv task2_256.csv
    # If no args, defaults below.
    csv_1024 = "task2_1024.csv"
    csv_256  = "task2_256.csv"
    if len(sys.argv) >= 3:
        csv_1024 = sys.argv[1]
        csv_256  = sys.argv[2]

    df1 = pd.read_csv(csv_1024).sort_values("n")
    df2 = pd.read_csv(csv_256).sort_values("n")

    for df, name in [(df1, csv_1024), (df2, csv_256)]:
        if "n" not in df.columns or "time_ms" not in df.columns:
            raise ValueError(f"{name} must have columns: n,time_ms")

    plt.figure()
    plt.plot(df1["n"], df1["time_ms"], marker="o", label="threads_per_block = 1024")
    plt.plot(df2["n"], df2["time_ms"], marker="o", label="threads_per_block = 256")

    plt.xlabel("n (signal length)")
    plt.ylabel("Time (ms)")
    plt.title("Stencil Runtime vs n")
    plt.xscale("log", base=2)   # works great for n = 2^10 ... 2^29
    plt.yscale("log")           # optional but usually helpful
    plt.grid(True, which="both")
    plt.legend()

    plt.tight_layout()
    plt.savefig("task2_overlay.pdf")
    plt.savefig("task2_overlay.png", dpi=200)
    print("Saved: task2_overlay.pdf and task2_overlay.png")

if __name__ == "__main__":
    main()
