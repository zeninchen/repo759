import pandas as pd
import matplotlib.pyplot as plt
import os

N_CSV = "n_sweep.csv"
BD_CSV = "blockdim_sweep_n16384.csv"

def load_csv(path):
    if not os.path.exists(path):
        raise FileNotFoundError(f"Missing {path}. Put it in the same directory as this script.")
    return pd.read_csv(path)

def to_numeric(df, cols):
    for c in cols:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")
    return df

def plot_time_vs_n(df):
    # Expect columns: n, int_ms, float_ms, double_ms
    df = df.sort_values("n")
    plt.figure()
    plt.plot(df["n"], df["int_ms"], marker="o", label="int")
    plt.plot(df["n"], df["float_ms"], marker="o", label="float")
    plt.plot(df["n"], df["double_ms"], marker="o", label="double")
    plt.xscale("log", base=2)
    plt.xlabel("n (matrix dimension)")
    plt.ylabel("Time (ms)")
    plt.title("MatMul Time vs n (2^5 to 2^14)")
    plt.grid(True, which="both")
    plt.legend()
    plt.tight_layout()
    plt.savefig("time_vs_n.png", dpi=200)
    plt.close()

def plot_time_vs_blockdim(df):
    # Expect columns: block_dim, int_ms, float_ms, double_ms
    df = df.sort_values("block_dim")
    plt.figure()
    plt.plot(df["block_dim"], df["int_ms"], marker="o", label="int")
    plt.plot(df["block_dim"], df["float_ms"], marker="o", label="float")
    plt.plot(df["block_dim"], df["double_ms"], marker="o", label="double")
    plt.xlabel("block_dim (tile size, 2D blocks)")
    plt.ylabel("Time (ms)")
    plt.title("MatMul Time vs block_dim (n = 2^14)")
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    plt.savefig("time_vs_blockdim.png", dpi=200)
    plt.close()

def main():
    n_df = load_csv(N_CSV)
    bd_df = load_csv(BD_CSV)

    n_df = to_numeric(n_df, ["n", "int_ms", "float_ms", "double_ms"])
    bd_df = to_numeric(bd_df, ["block_dim", "int_ms", "float_ms", "double_ms"])

    # Drop rows with missing timing values
    n_df = n_df.dropna(subset=["n", "int_ms", "float_ms", "double_ms"])
    bd_df = bd_df.dropna(subset=["block_dim", "int_ms", "float_ms", "double_ms"])

    plot_time_vs_n(n_df)
    plot_time_vs_blockdim(bd_df)

    print("Wrote: time_vs_n.png")
    print("Wrote: time_vs_blockdim.png")

if __name__ == "__main__":
    main()