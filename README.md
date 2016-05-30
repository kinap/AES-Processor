# AES Crypto Processor

### Authors

Alex Pearson, Scott Lawson, Daniel Collins

### Description

Parameterized AES encryptor and decryptor written in System Verilog. Supports the three standardized key sizes (128 bits, 192 bits, and 256 bits), chosen at compile time. Adheres to the Advanced Encryption Standard (AES) published by the National Institute of Standards and Technology (NIST), AES FIPS PUB 197. Verified using test vectors provided by the standard and produced by the [LibTomCrpyt C library](https://github.com/libtom/libtomcrypt). Verification done in simulation with [Mentor Graphics ModelSim&reg;](https://www.mentor.com/products/fv/modelsim/) and emulation on the [Mentor Graphics Veloce&reg;](https://www.mentor.com/products/fv/emulation-systems/).

### Repository Contents

| Path                      | Description
|---------------------------|------------
| /                         | Makefile, README, Veloce config file
| &emsp; docs/              | Project documentation
| &emsp;&emsp; src/         | Documentation source files for editing
| &emsp;&emsp; third_party/ | Reference documentation used in the design and verification of this project
| &emsp; src/               | AES Processor source code
| &emsp;&emsp; mem/         | Veloce memory-modeled lookup tables
| &emsp; test/              | Verification resources
| &emsp;&emsp; bench/       | System Verilog testbenches
| &emsp;&emsp; gen/         | Source code for C program to generate test vectors, scripts to obtain LibTomCrypt for building
| &emsp;&emsp; hvl/         | Top-level System Verilog testbench for Veloce emulation
| &emsp;&emsp; vectors/     | Text files containing test vectors for all test benches

### Makefile

All of the recipes in the provided Makefile assume the user is on a Linux system that supports ModelSim in both puresim and veloce modes, and that the current working directory is the root of this repository.

| Recipe        | Action
|---------------| ------
| compile       | Compiles all source and testbench files
| sim_<module\> | Simulates the specified module using its testbench (note: the recipe names do not exactly match the module names - see Makefile contents for the recipe to run a specific testbench)
| all           | Compiles all modules for all valid key widths, and runs all testbenches for each key width. All output is tee'd into all.log. After everything is complete, grep is used to search the log file for reported errors and warnings. A note is displayed to inform the user if any warnings or errors are present in the log file.

##### Options

**KEY_WIDTH**  
Specifies the key width to compile/simulate for. Valid widths are 128, 192, and 256. This option must be specified at compile time in order to run simulates for a key width besides 128. Has no effect during simulation, only during compilation. If unspecified, default is 128.

**MODE**  
Specifies the simulation mode. Valid modes are:

| Mode     ||
|----------|---
| standard | No Veloce support or dependencies. Cannot run top-level testbench, only sub-module testbenches.
| puresim  | Veloce simulation 
| veloce   | Veloce emulation (only the top-level testbench is run on the emulator)

If simulating for any mode besides puresim, this option must be specified for both compilation and simulation. If unspecified, default is puresim.

##### Examples

    # compiles all modules configured for a 128-bit key, run ExpandKey testbench in puresim mode
    make compile
    make sim_expandkey
    
    # compile all modules configured for a 256-bit key, run MixColumns testbench in standard mode
    make compile KEY_WIDTH=256 MODE=standard
    make sim_mixcolumns MODE=standard

    # compile all modules and testbenches for all key widths and run all testbenches on the Veloce emulator
    make all MODE=veloce
