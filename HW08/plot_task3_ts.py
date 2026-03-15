import csv
import matplotlib.pyplot as plt

ts = []
times = []

with open("hw8_task3_ts.csv","r") as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        ts.append(int(row[0]))
        times.append(float(row[1]))

plt.figure()
plt.plot(ts, times, marker='o')

plt.xscale("log")

plt.xlabel("Threshold (ts)")
plt.ylabel("Time (ms)")
plt.title("Merge Sort Runtime vs Threshold (n=1e6, t=8)")
plt.grid(True)

plt.savefig("hw8_task3_ts.pdf")