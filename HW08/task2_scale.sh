#!/usr/bin/env zsh

N=1024
OUTFILE=hw8_task2.csv

echo "threads,time_ms" > $OUTFILE

for t in {1..20}
do
    result=$(./task2 $N $t)
    time=$(echo "$result" | tail -n 1)

    echo "$t,$time" >> $OUTFILE
done