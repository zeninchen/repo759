#!/bin/bash

n=1000000

out_no_simd="task2_no_simd.csv"
out_simd="task2_simd.csv"

echo "t,time_ms" > $out_no_simd
echo "t,time_ms" > $out_simd

# ------------------------
# compile NO SIMD version
# ------------------------
g++ task2.cpp montecarlo.cpp -O3 -std=c++17 -fopenmp -fno-tree-vectorize -o task2_no_simd

# ------------------------
# compile SIMD version
# ------------------------
g++ task2.cpp montecarlo.cpp -O3 -std=c++17 -fopenmp -o task2_simd

# ------------------------
# run for t = 1..10
# ------------------------
for t in {1..10}
do
    total_no=0
    total_simd=0

    for i in {1..10}
    do
        # no simd
        time_no=$(./task2_no_simd $n $t | tail -n 1)
        total_no=$(echo "$total_no + $time_no" | bc -l)

        # simd
        time_simd=$(./task2_simd $n $t | tail -n 1)
        total_simd=$(echo "$total_simd + $time_simd" | bc -l)
    done

    avg_no=$(echo "$total_no / 10" | bc -l)
    avg_simd=$(echo "$total_simd / 10" | bc -l)

    echo "$t,$avg_no" >> $out_no_simd
    echo "$t,$avg_simd" >> $out_simd
done