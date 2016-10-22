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
roundKey_t [NUM_ROUNDS+1] roundKeys;

logic clock, reset;
int idx = 0;

KeyExpansionPipelined #(KEY_SIZE) key_exp(clock, reset, key, roundKeys);

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

initial
begin
$monitor("%t - \
| 0: %h | 1: %h | 2: %h | 3: %h \
| 4: %h | 5: %h | 6: %h | 7: %h \
| 8: %h | 9: %h | 10: %h | 11: %h \
| 12: %h | 13: %h | 14: %h ", 
$time, roundKeys[0],roundKeys[1],roundKeys[2],roundKeys[3],roundKeys[4],roundKeys[5],roundKeys[6],roundKeys[7],roundKeys[8],roundKeys[9],roundKeys[10],roundKeys[11],roundKeys[12],roundKeys[13],roundKeys[14]);
  //$monitor("%t - 0: %h | 1: %h | %h | %h | %h | %h | %h | %h | %h | %h | %h | %h | %h | %h | %h ", $time, key_exp.subKey[0],key_exp.subKey[1],key_exp.subKey[2],key_exp.subKey[3],key_exp.subKey[4],key_exp.subKey[5],key_exp.subKey[6],key_exp.subKey[7],key_exp.subKey[8],key_exp.subKey[9],key_exp.subKey[10],key_exp.subKey[11],key_exp.subKey[12],key_exp.subKey[13],key_exp.subKey[14]);
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
  $display("Done priming...");
  
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

