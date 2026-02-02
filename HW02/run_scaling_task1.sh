#!/bin/bash
#SBATCH --job-name=ece759_task1_scaling
#SBATCH --output=task1_scaling.out
#SBATCH --error=task1_scaling.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=20G

set -euo pipefail

# (Optional) load modules if Euler uses them
# module load gcc
# module load python

# Go to the folder containing scan.cpp/task1.cpp
cd "$(dirname "$0")"

# Compile
g++ scan.cpp task1.cpp -Wall -O3 -std=c++17 -o task1

# Output CSV
out_csv="task1_times.csv"
echo "n,time_ms" > "$out_csv"

# Loop over n = 2^10 ... 2^30
for p in $(seq 10 30); do
  n=$((1<<p))
  echo "Running n=$n (2^$p)..."

  # task1 prints:
  # line1: time_ms
  # line2: first element
  # line3: last element
  # We only want line1.
  time_ms=$(./task1 "$n" | head -n 1)

  echo "${n},${time_ms}" >> "$out_csv"
done

# Plot to PDF (on the compute node)
python3 plot_task1.py "$out_csv" task1.pdf
echo "Wrote $out_csv and task1.pdf"
