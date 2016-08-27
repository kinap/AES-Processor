#
# Makefile for AES Encryptor/Decryptor Project
#

#MODE ?= standard
MODE ?= puresim
#MODE ?= veloce

INFER_RAM ?= n

SRC_DIR ?= src
TST_DIR ?= test/bench
HVL_DIR ?= test/hvl

COMPILE_CMD = vlog
COMPILE_FLAGS = -mfcu 
ifeq ($(INFER_RAM),y)
COMPILE_FLAGS += +define+INFER_RAM
endif

SIMULATE_CMD = vsim

ifeq ($(MODE),standard)
SIMULATE_FLAGS = -c  -do "run -all"
else
SIMULATE_FLAGS = -c  -do "run -all" +tbxrun+"$(QUESTA_RUNTIME_OPTS)"
SIMULATE_MANAGER = TbxSvManager 
endif

ALL_LOG ?= all.log

SRC_FILES = \
	$(SRC_DIR)/AESDefinitions.sv \
	$(SRC_DIR)/*.sv

TST_FILES = \
	$(TST_DIR)/AESTestDefinitions.sv \
	$(TST_DIR)/*.sv

HVL_FILES = $(HVL_DIR)/EncoderDecoderTestBench.sv

SIM_TARGETS = sim_subbytes sim_shiftrows sim_mixcolumns sim_addroundkey \
              sim_round sim_bufferedround sim_expandkey sim_encoderdecoder

compile:

	vlib $(MODE)work
	vmap work $(MODE)work

ifeq ($(MODE),standard) # Compiling in standard mode: no Veloce dependencies
	$(COMPILE_CMD) $(COMPILE_FLAGS) $(SRC_FILES) $(TST_FILES)

else # Compiling either for Veloce, or Veloce puresim
	$(COMPILE_CMD) -f $(VMW_HOME)/tbx/questa/hdl/scemi_pipes_sv_files.f
	$(COMPILE_CMD) $(COMPILE_FLAGS) $(SRC_FILES) $(TST_FILES) $(HVL_FILES)

ifeq ($(MODE),veloce) # Compiling for puresim
	velanalyze $(COMPILE_FLAGS) $(SRC_FILES) $(TST_DIR)/Transactor.sv
	velcomp -top Transactor
	velcp -o criticalpath.txt -cfgDir ./veloce.med

endif # Compiling either for Veloce or Veloce puresim
	velhvl -enable_profile_report -sim $(MODE)

endif

sim_subbytes:
	$(SIMULATE_CMD) SubBytesTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_shiftrows:
	$(SIMULATE_CMD) ShiftRowsTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_mixcolumns:
	$(SIMULATE_CMD) MixColumnsTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_addroundkey:
	$(SIMULATE_CMD) AddRoundKeyTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_round:
	$(SIMULATE_CMD) RoundTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_bufferedround:
	$(SIMULATE_CMD) BufferedRoundTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_expandkey:
	$(SIMULATE_CMD) ExpandKeyTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_encoderdecoder:
ifneq ($(MODE),standard)
	$(SIMULATE_CMD) EncoderDecoderTestBench Transactor $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)
endif

define check_log
       @grep $(1) $(ALL_LOG) > /dev/null;  \
               if [ $$? -eq 0 ]; then printf $(2); else printf $(3); fi;
endef

PRINT_BAR = "\n***********************************************"

all:
	$(MAKE) clean 
	
	printf $(PRINT_BAR) | tee -a $(ALL_LOG); \
	printf "\n" | tee -a $(ALL_LOG); \
	$(MAKE) compile | tee -a $(ALL_LOG) ; \
	$(MAKE) $(SIM_TARGETS) | tee -a $(ALL_LOG) ;

	@printf "\n\n"; printf $(PRINT_BAR); printf "\nLog file: $(ALL_LOG)\n"
	$(call check_log,"Errors: [1-9]","\nExecution Errors:\tYES","\nExecution Errors:\tNo")
	$(call check_log,"Assertion error","\nAssertion Errors:\tYES","\nAssertion Errors:\tNo")
	$(call check_log,"Warnings: [1-9]","\nWarnings:\t\tYES","\nWarnings:\t\tNo")
	@printf $(PRINT_BAR); printf "\n\n"

clean:
	rm -rf work transcript $(ALL_LOG)
	rm -rf velocework puresimwork standardwork 
	rm -rf veloce.log veloce.med veloce.map veloce.wave
	rm -rf tbxbindings.h velrunopts.ini modelsim.ini edsenv vish_stacktrace.vstf
	rm -rf modelsim.ini_lock modelsim.ini_new
	rm -f  criticalpath.txt

