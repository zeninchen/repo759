import csv
import matplotlib.pyplot as plt

threads = []
times = []

# read csv
with open("hw8_task1.csv", "r") as f:
    reader = csv.reader(f)
    next(reader)  # skip header
    for row in reader:
        threads.append(int(row[0]))
        times.append(float(row[1]))

# plot
plt.figure()
plt.plot(threads, times, marker='o')

plt.xlabel("Number of Threads (t)")
plt.ylabel("Time (ms)")
plt.title("mmul Runtime vs Threads (n = 1024)")
plt.grid(True)

plt.savefig("hw8_task1.pdf")