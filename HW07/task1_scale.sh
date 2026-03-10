#!/usr/bin/env bash
set -euo pipefail

# Output CSV files
THRUST_CSV="task1_thrust_times.csv"
CUB_CSV="task1_cub_times.csv"

echo "n,time_ms" > "$THRUST_CSV"
echo "n,time_ms" > "$CUB_CSV"

# Sweep n = 2^10, 2^11, ..., 2^40
for exp in $(seq 10 40); do
    n=$((2**exp))
    echo "Running n=$n"

    # Each program prints:
    # line 1 = reduction result
    # line 2 = elapsed time in ms
    thrust_output=$(./task1_thrust "$n")
    thrust_time=$(echo "$thrust_output" | sed -n '2p')
    echo "$n,$thrust_time" >> "$THRUST_CSV"

    cub_output=$(./task1_cub "$n")
    cub_time=$(echo "$cub_output" | sed -n '2p')
    echo "$n,$cub_time" >> "$CUB_CSV"
done

echo "Wrote $THRUST_CSV and $CUB_CSV"
