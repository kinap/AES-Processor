# ECE571Project
AES crypto processor.

Alex Pearson, Scott Lawson, Daniel Collins

Parameterized AES processor written in System Verilog and emulated on the PSU Veloce Solo. 
Supports the three standardized key sizes (128 | 192 | 256) chosen at compile time.

Verified bottom up. Intermediate results of rounds and round submodules were verified using known answer tests from NIST. Random vectors were generated and results from the top level were tested against a golden model (TomCrypt C library).
