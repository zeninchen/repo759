import pandas as pd
import matplotlib.pyplot as plt

# Read the CSV file
df = pd.read_csv("task2_times.csv")

# Create the plot
plt.figure(figsize=(8, 6))
plt.plot(df["n"], df["time_ms"], marker='o')

# Log-log scale
plt.xscale("log", base=2)
plt.yscale("log")

# Labels and title
plt.xlabel("n")
plt.ylabel("Time (ms)")
plt.title("Task2 Runtime vs n")
plt.grid(True, which="both", linestyle="--", alpha=0.6)

# Save to PDF
plt.tight_layout()
plt.savefig("task2.pdf")

# Show plot
plt.show()