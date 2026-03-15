import csv
import matplotlib.pyplot as plt

threads = []
times = []

with open("hw8_task3_t.csv","r") as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        threads.append(int(row[0]))
        times.append(float(row[1]))

plt.figure()
plt.plot(threads, times, marker='o')

plt.xlabel("Threads (t)")
plt.ylabel("Time (ms)")
plt.title("Merge Sort Runtime vs Threads (n=1e6)")
plt.grid(True)

plt.savefig("hw8_task3_t.pdf")