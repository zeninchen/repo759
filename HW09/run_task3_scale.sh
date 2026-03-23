#!/bin/bash

outfile="task3.csv"

echo "n,time_ms" > $outfile

mpicxx task3.cpp -Wall -O3 -o task3

for exp in {1..25}
do
    n=$((2**exp))
    time=$(srun -n 2 ./task3 $n | tail -n 1)
    echo "$n,$time" >> $outfile
done