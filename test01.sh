#!/bin/sh

# Tests variable assignment to another variable
# Expected output: hello

variable1=hello
variable2=$variable1
echo $variable2