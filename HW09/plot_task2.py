import pandas as pd
import matplotlib.pyplot as plt

df_no = pd.read_csv("task2_no_simd.csv")
df_simd = pd.read_csv("task2_simd.csv")

plt.plot(df_no["t"], df_no["time_ms"], marker='o', label="without simd")
plt.plot(df_simd["t"], df_simd["time_ms"], marker='o', label="with simd")

plt.xlabel("t (number of threads)")
plt.ylabel("time (ms)")
plt.title("Monte Carlo Runtime vs Threads")
plt.grid()
plt.legend()

plt.savefig("task2.pdf")