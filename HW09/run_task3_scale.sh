#!/bin/bash

outfile="task3.csv"

echo "n,time_ms" > $outfile

for exp in {1..25}
do
    n=$((2**exp))
    time=$(srun -n 2 ./task3 $n | tail -n 1)
    echo "$n,$time" >> $outfile
done