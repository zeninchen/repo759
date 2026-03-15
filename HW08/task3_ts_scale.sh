#!/usr/bin/env zsh

N=1000000
T=8
OUTFILE=hw8_task3_ts.csv

echo "ts,time_ms" > $OUTFILE

for p in {1..10}
do
    ts=$((2**p))

    result=$(./task3 $N $T $ts)
    time=$(echo "$result" | tail -n 1)

    echo "$ts,$time" >> $OUTFILE
done