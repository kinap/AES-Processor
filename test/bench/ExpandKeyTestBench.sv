//
// Testbench for Expand Key module
//

import AESTestDefinitions::*;

module ExpandKeyTestBench;

logic clock, reset;
int testCount = 0;
int validRounds = 0;

key_t key;
roundKeys_t [0:`NUM_ROUNDS] roundKeys;
roundKeys_t stagedRoundKey;
expandedKeyTest_t curTest;

ExpandKey mut(
    .key(key), 
    .roundKeys(roundKeys)
);

// free-running clock
always #1 clock = ~clock;

// The key schedule array is treated like a FIFO so that each round key is
// checked against the correct expected result. When a key is changed, the
// correct round key results will be propogated on each clock cycle, so it is
// possible, for example, for the first and last round keys to correspond to
// different input keys. The expected result FIFO keeps the expected key
// schedules synchronized with the input keys.
always @(negedge clock) roundKeys = {stagedRoundKey, roundKeys[0:`NUM_ROUNDS-1]};

// A concurrent assertion is used to check the round keys against the expected key. This count
// prevents the assertion from checking round keys that have not yet been calculated when the module
// is first started up.
always @(posedge clock) validRounds = (validRound < `NUM_ROUNDS) ? validRounds + 1 : validRounds;

initial
begin
  clock = 1'b0;
  reset = 1'b0;
end

initial
begin
  KeyScheduleTester tester;
  tester = new();
  tester.ParseFileForTestCases("test/vectors/key_schedule_vectors.txt");

  // test first key and key schedule
  // each clock cycle should result in one more round key being ready, so load
  // the first key, then advance for NUM_ROUNDS cycles, checking 0 - n round
  // keys, where n is the number of rounds that should be populated

  curTest = tester.GetNextTest();
  key = curTest.key;
  stagedRoundKey = curTest.roundKeys;

  for (int i=0; i<=`NUM_ROUNDS; ++i)
  begin
    @(negedge clock)
    tester.Compare(curTest, roundKeys);
    ++testCount;
  
  while(tester.NumTests() != 0)
  begin
    curTest = tester.GetNextTest();
    key = curTest.key;
    #1
    tester.Compare(curTest, roundKeys);
    ++testCount;
  end


  $display("ExpandKeyTestBench executed %0d test cases", testCount);
  $finish();
end

endmodule

