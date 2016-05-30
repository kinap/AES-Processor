#!/bin/bash
lib_dir=~/libtomcrypt
gcc -Wall -Wextra -g -I${lib_dir}/src/headers -L${lib_dir} AESGen.c -ltomcrypt -o AESGen
