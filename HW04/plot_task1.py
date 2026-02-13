#!/usr/bin/env python3
import sys
import pandas as pd
import matplotlib.pyplot as plt

def main():
    # Usage:
    #   python plot_task1.py task1_1024.csv task1_256.csv
    # If no args: defaults to these filenames.
    csv_1024 = "task1_1024.csv"
    csv_256  = "task1_256.csv"
    if len(sys.argv) >= 3:
        csv_1024 = sys.argv[1]
        csv_256  = sys.argv[2]

    df1 = pd.read_csv(csv_1024)
    df2 = pd.read_csv(csv_256)

    # Expect columns: n,time_ms
    for df, name in [(df1, csv_1024), (df2, csv_256)]:
        if "n" not in df.columns or "time_ms" not in df.columns:
            raise ValueError(f"{name} must have columns: n,time_ms")

    df1 = df1.sort_values("n")
    df2 = df2.sort_values("n")

    plt.figure()
    plt.plot(df1["n"], df1["time_ms"], marker="o", label="threads_per_block = 1024")
    plt.plot(df2["n"], df2["time_ms"], marker="o", label="threads_per_block = 256")

    plt.xlabel("n (matrix dimension)")
    plt.ylabel("Time (ms)")
    plt.title("Task1 MatMul Runtime vs n")
    plt.xscale("log", base=2)   # since n = 2^k
    plt.yscale("log")           # optional but usually helpful for scaling plots
    plt.grid(True, which="both")
    plt.legend()

    plt.tight_layout()
    plt.savefig("task1_overlay.pdf")
    plt.savefig("task1_overlay.png", dpi=200)
    print("Saved: task1_overlay.pdf and task1_overlay.png")

if __name__ == "__main__":
    main()
