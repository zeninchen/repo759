#!/bin/bash

n=5040000
outfile="task1.csv"

echo "t,time_ms" > $outfile

for t in {1..10}
do
    total=0

    for i in {1..10}
    do
        # run and grab last line (time)
        time=$(./task1 $n $t | tail -n 1)
        total=$(echo "$total + $time" | bc -l)
    done

    avg=$(echo "$total / 10" | bc -l)

    echo "$t,$avg" >> $outfile
done