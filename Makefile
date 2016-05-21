#
# Makefile for AES Encryptor/Decryptor Project
# ECE 571 SP2016
#

MODE ?= puresim
#MODE ?= veloce

KEY_WIDTH ?= 128
ifeq ($(KEY_WIDTH),128)
    KEY_WIDTH_MACRO := AES_128
else ifeq ($(KEY_WIDTH),192)
    KEY_WIDTH_MACRO := AES_192
else ifeq ($(KEY_WIDTH),256)
    KEY_WIDTH_MACRO := AES_256
else
    $(error "Invalid key width specified")
endif

SRC_DIR ?= src
TST_DIR ?= test/bench

SIM_LOG_FILE ?= sim_log.log
ERROR_REGEX ?= "Errors: [1-9]\|Warnings: [1-9]"
BAR_START_LINE = "\n\n\n**********************************************"
SIM_FAIL = "\n***  Simulation Error/Warning. Check Log.  ***\n"
SIM_PASS = "\n*** Simulation completed without failures. ***\n"
BAR_END_LINE = "**********************************************\n\n\n"

COMPILE_CMD = vlog
COMPILE_FLAGS = -mfcu 

SIMULATE_CMD = vsim
SIMULATE_FLAGS = -c  -do "run -all"

SRC_FILES = \
        $(SRC_DIR)/AESDefinitions.sv \
        $(SRC_DIR)/*.sv

TST_FILES = \
	$(TST_DIR)/AESTestDefinitions.sv \
	$(TST_DIR)/*.sv

HVL_FILES = $(TST_DIR)/EncoderDecoderTestBench.sv

ALL_FILES = $(SRC_FILES) $(TST_FILES)

define check_sim
	@printf $(BAR_START_LINE);	\
	grep $(ERROR_REGEX) $(SIM_LOG_FILE) > /dev/null;  \
               if [ $$? -eq 0 ]; then printf $(SIM_FAIL); else printf $(SIM_PASS); fi; \
	printf $(BAR_END_LINE)
endef

compile:
	vlib $(MODE)work
	vmap work $(MODE)work
	$(COMPILE_CMD) -f $(VMW_HOME)/tbx/questa/hdl/scemi_pipes_sv_files.f
ifeq ($(MODE),puresim)
	$(COMPILE_CMD) $(COMPILE_FLAGS) +define+$(KEY_WIDTH_MACRO) $(SRC_FILES) $(TST_FILES)
else
	velanalyze $(COMPILE_FLAGS) +define+$(KEY_WIDTH_MACRO) $(SRC_FILES)
        velcomp -top EncoderDecoderTestBench
endif
	$(COMPILE_CMD) $(HVL_FILES)
	velhvl -sim $(MODE)

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

sim_buffered_round:
	$(SIMULATE_CMD) BufferedRoundTestBench $(SIMULATE_FLAGS)

sim_expandkey:
	$(SIMULATE_CMD) ExpandKeyTestBench $(SIMULATE_FLAGS)

sim_encoder_decoder:
	$(SIMULATE_CMD) EncoderDecoderTestBEnch Transactor TbxSvManager $(SIMULATE_FLAGS) +tbxrun+"$(QUESTA_RUNTIME_OPTS)"

sim_all:
	$(MAKE) sim_subbytes sim_shiftrows sim_mixcolumns sim_addroundkey sim_round sim_buffered_round sim_encoder_decoder \
		| tee $(SIM_LOG_FILE)
	$(call check_sim)

all:
	$(MAKE) clean 
	
	for KEY_MACRO in AES_128 AES_192 AES_256 ; do	\
		printf "\n$$KEY_MACRO\n" | tee -a $(SIM_LOG_FILE) ; \
		$(COMPILE_CMD) $(COMPILE_FLAGS) +define+$$KEY_MACRO $(ALL_FILES) ; \
		$(MAKE) sim_subbytes sim_shiftrows sim_mixcolumns sim_addroundkey sim_round sim_buffered_round |  tee -a $(SIM_LOG_FILE) ; \
	done

	$(call check_sim)

clean:
	rm -rf work transcript $(SIM_LOG_FILE)
	rm -rf velocework puresimwork


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


