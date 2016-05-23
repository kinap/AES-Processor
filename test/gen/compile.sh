gcc -DAES_128 -Wall -Wextra -g -I/u/daniel28/libtomcrypt/src/headers -I/u/daniel28/libtomcrypt/src/ciphers -L/u/daniel28/libtomcrypt AESGen.c -ltomcrypt -o AESGen
