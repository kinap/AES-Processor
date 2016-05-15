#
# Makefile for AES Encryptor/Decryptor Project
# ECE 571 SP2016
#

MODE ?= puresim
#MODE ?= veloce

SRC_DIR ?= src
TST_DIR ?= test/bench

SIM_LOG_FILE ?= sim_log.log
SIM_ERROR_FIND_STR ?= AES_SIM_ERROR
BAR_START_LINE = "\n\n\n**********************************************"
SIM_FAIL ?= "\n***     Simulation Error. Check Log.       ***\n"
SIM_PASS ?= "\n*** Simulation completed without failures. ***\n"
BAR_END_LINE = "**********************************************\n\n\n"

COMPILE_CMD = vlog
COMPILE_FLAGS = -mfcu

SIMULATE_CMD = vsim
SIMULATE_FLAGS = -c  -do "run -all"

VLOG = \
        $(SRC_DIR)/AESDefinitions.sv    \
        $(SRC_DIR)/ExpandKey.sv         \
        $(SRC_DIR)/AddRoundKey.sv       \
        $(SRC_DIR)/BufferedRound.sv     \
        $(SRC_DIR)/Buffer.sv            \
        $(SRC_DIR)/ExpandKey.sv         \
        $(SRC_DIR)/MixColumns.sv        \
        $(SRC_DIR)/Round.sv             \
        $(SRC_DIR)/ShiftRows.sv         \
        $(SRC_DIR)/SubBytes.sv			\
		\
		$(TST_DIR)/AESTestDefinitions.sv	\
		$(TST_DIR)/AddRoundKeyTestBench.sv  \
		$(TST_DIR)/MixColumnsTestBench.sv	\
		$(TST_DIR)/RoundTestBench.sv		\
		$(TST_DIR)/ShiftRowsTestBench.sv	\
		$(TST_DIR)/SubBytesTestBench.sv

compile:
	$(COMPILE_CMD) $(COMPILE_FLAGS) $(VLOG)

sim_subbytes:
	$(SIMULATE_CMD) SubBytesTestBench $(SIMULATE_FLAGS)

sim_shiftrows:
	$(SIMULATE_CMD) ShiftRowsTestBench $(SIMULATE_FLAGS)

sim_mixcolumns:
	$(SIMULATE_CMD) MixColumnsTestBench $(SIMULATE_FLAGS)

sim_addroundkey:
	$(SIMULATE_CMD) AddRoundKeyTestBench $(SIMULATE_FLAGS)

sim_round:
	$(SIMULATE_CMD) RoundTestBench $(SIMULATE_FLAGS)

sim_all:
	$(MAKE) sim_subbytes sim_shiftrows sim_mixcolumns sim_addroundkey sim_round | tee $(SIM_LOG_FILE)
	@printf $(BAR_START_LINE)
	@grep $(SIM_ERROR_FIND_STR) $(SIM_LOG_FILE) > /dev/null;  \
		if [ $$? -eq 0 ]; then printf $(SIM_FAIL); else printf $(SIM_PASS); fi
	@printf $(BAR_END_LINE)

all: clean compile sim_all

clean:
	rm -rf work transcript $(SIM_LOG_FILE)



# Commenting out original makefile - we'll want to keep it for reference later
#
#all: clean compile sim
#
##MODE ?= puresim
#MODE ?= veloce
#
#VLOG = \
#        hdl/top.sv \
#        hdl/pipe.sv
#
#compile:
#	vlib $(MODE)work
#	vmap work $(MODE)work
#	vlog -f $(VMW_HOME)/tbx/questa/hdl/scemi_pipes_sv_files.f 
#	vlog hvl/hello.sv
#ifeq ($(MODE),puresim)
#	vlog $(VLOG)
#else
#	velanalyze hdl/top.sv hdl/pipe.sv
#	strace -f velcomp -top top 2>&1 | tee logtrace.txt
#endif
#	velhvl -sim $(MODE)
#
#build:
#	velhvl -sim $(MODE)
#
#sim:
#	vsim -c top TESTBENCH TbxSvManager -do "run -all; quit" +tbxrun+"$(QUESTA_RUNTIME_OPTS)" -l output.log
#
#clean:
#	rm -rf work transcript vsim.wlf dpi.so modelsim.ini output.log result.TBX tbxsvlink.log
#	rm -rf waves.wlf vsim_stacktrace.vstf sc_dpiheader.h hdl.* debussy.cfg  dmTclClient.log  partition.info 
#	rm -rf tbxbindings.h  tbx.dir  tbx.map   veloce_c_transcript dmslogdir    ECTrace.log      Report.out      tbx.log  tbxsim.v  vlesim.log


