#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="task2_times.csv"
echo "n,time_ms" > "$CSV_FILE"

# Sweep n = 2^5, 2^6, ..., 2^20
for exp in $(seq 5 20); do
    n=$((2**exp))
    echo "Running n=$n"

    # task2 output:
    # line 1 = last value
    # line 2 = last count
    # line 3 = elapsed time in ms
    output=$(./task2 "$n")
    time_ms=$(echo "$output" | sed -n '3p')

    echo "$n,$time_ms" >> "$CSV_FILE"
done

echo "Wrote $CSV_FILE"