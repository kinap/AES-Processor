//
// Testbench for Expand Key module
//

import AESTestDefinitions::*;

module ExpandKeyTestBench;

localparam KEY_CYCLE_COUNT = `NUM_ROUNDS / 2;

logic clock, reset;
int testCount = 0;
int validRounds = 0;

key_t key;
roundKeys_t roundKeysAct;
expandedKeyTest_t curTest;
expandedKeyTest_t [0:`NUM_ROUNDS] testFIFO;

ExpandKey mut(
  .clock(clock),
  .reset(reset),
  .key(key), 
  .roundKeys(roundKeysAct)
);

// free-running clock
always #1 clock = ~clock;

// The key schedule array is treated like a FIFO so that each round key is
// checked against the correct expected result. When a key is changed, the
// correct round key results will be propogated on each clock cycle, so it is
// possible, for example, for the first and last round keys to correspond to
// different input keys. The expected result FIFO keeps the expected key
// schedules synchronized with the input keys.
always @(negedge clock) testFIFO = {curTest, testFIFO[0:`NUM_ROUNDS-1]};
assign key = testFIFO[0].key;

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

  curTest = tester.GetNextTest();

  for (int i=0; i<=`NUM_ROUNDS; ++i)
  begin

    #0;
    if (testFIFO[0].roundKeys[i] !== roundKeysAct[i])
      tester.ReportError(testFIFO[0].roundKeys[i], roundKeysAct[i], key, i, 0);

    @(negedge clock);

  end

  ++testCount;
  $display("current round keys: %h", roundKeysAct);

  while(tester.NumTests() != 0)
  begin

    // Now that the whole key schedule is populated, we can change out the keys more quickly, and
    // every round key should correspond to the correct input key as it's propogated through the
    // round pipeline. Start a new key every KEY_CYCLE_COUNT cycles. 
    curTest = tester.GetNextTest();
    @(negedge clock);

    // confirm that key changes propogate correctly
    for (int j=0; j<=KEY_CYCLE_COUNT; ++j)
    begin

      #0;
      for (int i=0; i<=`NUM_ROUNDS; ++i)
      begin

        if (testFIFO[i].roundKeys[i] !== roundKeysAct[i])
          tester.ReportError(testFIFO[i].roundKeys[i], roundKeysAct[i], testFIFO[i].key, i, testCount);

      end

      @(negedge clock);

    end
    $display("current round keys: %h", roundKeysAct);

    ++testCount;

  end

  // confirm that the last key's round keys are propogated to the last round key
  for (int j=0; j<=`NUM_ROUNDS-KEY_CYCLE_COUNT; ++j)
  begin

    #0;
    for (int i=0; i<=`NUM_ROUNDS; ++i)
    begin

      if (testFIFO[i].roundKeys[i] !== roundKeysAct[i])
        tester.ReportError(testFIFO[i].roundKeys[i], roundKeysAct[i], testFIFO[i].key, i, testCount);

    end

    @(negedge clock);

  end
  
  $display("current round keys: %h", roundKeysAct);

  $display("ExpandKeyTestBench executed %0d test cases", testCount);
  $finish();
end

endmodule

