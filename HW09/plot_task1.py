import pandas as pd
import matplotlib.pyplot as plt

# read csv
df = pd.read_csv("task1.csv")

# plot
plt.plot(df["t"], df["time_ms"], marker='o')

plt.xlabel("t (number of threads)")
plt.ylabel("time (ms)")
plt.title("Cluster Runtime vs Threads")

plt.grid()

# save
plt.savefig("task1.pdf")