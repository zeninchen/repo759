#!/usr/bin/env bash
set -euo pipefail

# Compile the two programs.
# Adjust include/library flags here if Euler needs anything extra for CUB/Thrust.
nvcc -O3 -std=c++14 task1_thrust.cu -o task1_thrust
nvcc -O3 -std=c++14 task1_cub.cu    -o task1_cub

# Output CSV files
THRUST_CSV="task1_thrust_times.csv"
CUB_CSV="task1_cub_times.csv"

echo "n,time_ms" > "$THRUST_CSV"
echo "n,time_ms" > "$CUB_CSV"

# Sweep n = 2^10, 2^11, ..., 2^20
for exp in $(seq 10 20); do
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
