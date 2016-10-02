//
// Testbench for Expand Key module
//

import AESTestDefinitions::*;

module KeyExpansionTestBench;

    KeyExp_keysize #(.KEY_SIZE(128)) key_exp_128();   
    KeyExp_keysize #(.KEY_SIZE(192)) key_exp_192();   
    KeyExp_keysize #(.KEY_SIZE(256)) key_exp_256();   

endmodule
    
  
// 
// TB for 1 keysize at a time
//
module KeyExp_keysize #(parameter KEY_SIZE = 128,
                        parameter KEY_BYTES = KEY_SIZE / 8,
                        parameter NUM_ROUNDS = (KEY_SIZE == 256) ? 14 : (KEY_SIZE == 192) ? 12 : 10,
                        parameter type key_t = byte_t [0:KEY_BYTES-1]);

parameter CLOCK_CYCLE = 20ns;
parameter CLOCK_WIDTH = CLOCK_CYCLE/2;
parameter IDLE_CLOCKS = 2;

typedef struct packed {
  roundKey_t prevKey;
  roundKey_t roundKey;
  key_t key;
} keyRoundTest_t;

keyRoundTest_t curTest;

key_t key;
roundKey_t [0:NUM_ROUNDS] roundKeys;

logic clock, reset;
int idx = 0;

KeyExpansion #(KEY_SIZE) key_exp(clock, reset, key, roundKeys);

// Create a free running clock
initial
begin
    clock = `FALSE;
    forever #CLOCK_WIDTH clock = ~clock;
end

// Generate a reset signal for two cycles
initial
begin
    reset = `TRUE;
    repeat (IDLE_CLOCKS) @(negedge clock);
    reset = `FALSE;
end

// test entry
initial
begin
  KeyRoundTester #(KEY_SIZE) tester;
  tester = new();

  repeat(IDLE_CLOCKS) @(negedge clock);

  tester.ParseFileForTestCases("test/vectors/fips_example_vectors.txt", "k_sch", KEY_SIZE);

  curTest = tester.GetNextTest();
  key = curTest.key; // stabalize key at input, let it trickle down to the rounds
  repeat(NUM_ROUNDS+1) @(negedge clock);
  idx += 1;
  tester.Compare(roundKeys[idx], curTest);
  
  while(tester.NumTests() != 0)
  begin
    curTest = tester.GetNextTest();
    key = curTest.key; // stabalize key at input, let it trickle down to the rounds
    repeat(1) @(negedge clock);
    idx += 1;
    tester.Compare(roundKeys[idx], curTest);
  end

  if (KEY_SIZE == 256)
    $finish();
end

endmodule

