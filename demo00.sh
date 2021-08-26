#!/bin/dash

# Demo code adapted from provided examples

echo My first argument is $1
echo My second argument is $2
echo My third argument is $3
echo My fourth argument is $4
echo My fifth argument is $5

variable="Hello there"

if test $variable = great
then
    echo correct
elif test "Jim Beam" = fantastic 
then
    echo yes
else
    echo error
fi