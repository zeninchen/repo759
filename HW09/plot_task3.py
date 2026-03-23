import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("task3.csv")

plt.plot(df["n"], df["time_ms"], marker='o')

plt.xscale("log")
plt.yscale("log")

plt.xlabel("n")
plt.ylabel("time (ms)")
plt.title("MPI Communication Time vs n")
plt.grid()

plt.savefig("task3.pdf")