#!/bin/dash

# Demo code adapted from provided examples

for c_file in *.c
do
    echo gcc -c $c_file
done

for word in Hello there General Kenobi
do
    read line
    echo $word
    exit 0
done

file=$1
echo "$file"