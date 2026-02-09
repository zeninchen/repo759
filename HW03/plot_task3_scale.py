# plot_task3_scale.py
# Usage:
#   python3 plot_task3_scale.py task3_scale.csv task3_16.csv task3.pdf
#
# Produces an overlaid plot of time (ms) vs n from two CSV files.

import sys
import math
import pandas as pd
import matplotlib.pyplot as plt

def read_csv(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    # Expect columns: n, threads_per_block, blocks, ms
    required = {"n", "ms"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"{path} missing columns: {missing}. Found: {list(df.columns)}")
    df = df.sort_values("n")
    return df

def label_from_df(df: pd.DataFrame, fallback: str) -> str:
    if "threads_per_block" in df.columns and df["threads_per_block"].nunique() == 1:
        t = int(df["threads_per_block"].iloc[0])
        return f"{t} threads/block"
    return fallback

def main():
    if len(sys.argv) != 4:
        print("Usage: python3 plot_task3_scale.py task3_scale.csv task3_16.csv task3.pdf")
        sys.exit(1)

    csv1, csv2, out_pdf = sys.argv[1], sys.argv[2], sys.argv[3]

    df1 = read_csv(csv1)
    df2 = read_csv(csv2)

    # Build labels
    label1 = label_from_df(df1, "run 1")
    label2 = label_from_df(df2, "run 2")

    # Plot
    plt.figure()
    plt.plot(df1["n"], df1["ms"], marker="o", label=label1)
    plt.plot(df2["n"], df2["ms"], marker="o", label=label2)

    # Log scale on x is usually best for powers of two
    plt.xscale("log", base=2)

    plt.xlabel("n (elements)")
    plt.ylabel("Kernel time (ms)")
    plt.title("vscale scaling: time vs n")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.legend()

    plt.tight_layout()
    plt.savefig(out_pdf)
    print(f"Wrote {out_pdf}")

if __name__ == "__main__":
    main()
