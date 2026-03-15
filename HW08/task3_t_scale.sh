#!/usr/bin/env zsh

N=1000000
TS=512
OUTFILE=hw8_task3_t.csv

echo "threads,time_ms" > $OUTFILE

for t in {1..20}
do
    result=$(./task3 $N $t $TS)
    time=$(echo "$result" | tail -n 1)

    echo "$t,$time" >> $OUTFILE
done