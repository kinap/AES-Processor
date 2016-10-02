//
// Testbench for Expand Key module
//

import AESTestDefinitions::*;

// TODO how do we want to test all key sizes?
module KeyExpansionTestBench #(parameter KEY_SIZE = 192, 
                               parameter KEY_BYTES = KEY_SIZE / 8,
                               parameter type key_t = byte_t [0:KEY_BYTES-1]);
parameter NUM_ROUNDS =
  (KEY_SIZE == 256)
    ? 14
    : (KEY_SIZE == 192)
      ? 12
      : 10;

parameter CLOCK_CYCLE = 20ns;
parameter CLOCK_WIDTH = CLOCK_CYCLE/2;
parameter IDLE_CLOCKS = 2;

typedef struct packed {
  roundKey_t prevKey;
  roundKey_t roundKey;
  key_t key;
} keyRoundTest_t;

key_t roundIn[NUM_ROUNDS];
key_t roundOut[NUM_ROUNDS];
roundKey_t tmp;
//roundKey_t roundKey [NUM_ROUNDS];
logic clock, reset;

keyRoundTest_t curTest;
int idx = 0;

// each key round has a unique rcon value, so we must instantiate them separately
genvar i;
for (i = 1; i <= NUM_ROUNDS; i++)
begin
  KeyRound #(.KEY_SIZE(KEY_SIZE), .RCON_ITER(i)) mut(clock, reset, roundIn[i-1], roundOut[i-1]);
end

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
  KeyRoundTester #(KEY_SIZE) tester;
  tester = new();

  repeat(IDLE_CLOCKS) @(negedge clock);

  tester.ParseFileForTestCases("test/vectors/fips_example_vectors.txt", "k_sch", KEY_SIZE);
  
  while(tester.NumTests() != 0)
  begin
    curTest = tester.GetNextTest();
    roundIn[0] = curTest.key;
    $display("****** IN : %0d, %h", idx, roundIn[idx]);

    repeat(1) @(negedge clock);
    //#1 repeat(1);

    $display("****** OUT: %0d, %h", idx, roundOut[idx]);
    tmp = {roundIn[idx][KEY_BYTES-8 +: 8], roundOut[idx][0 +: 8]};
    $display("****** RK : %0d, %h", idx, tmp);

    tester.Compare(tmp, curTest);
    idx += 1;
    roundIn[idx] = roundOut[idx-1];
  end

  $finish();
end

endmodule

