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

  $monitor("Time: %t\troundKeysAct:\t%h", $time, roundKeysAct);
//  $monitor("testFIFO[0]:\t%p\ntestFIFO[1]:\t%p\ntestFIFO[2]:\t%p", testFIFO[0], testFIFO[1],
//    testFIFO[2]);

  for (int i=0; i<=`NUM_ROUNDS; ++i)
  begin

    @(negedge clock)
    if (testFIFO[0].roundKeys[i] !== roundKeysAct[i])
      tester.ReportError(testFIFO[0].roundKeys[i], roundKeysAct[i], key, i, 0);
//    $display("Expected:\t%h", testFIFO[0].roundKeys[i]);
//    $display("Actual:\t%h", roundKeysAct[i]);
  end

  ++testCount;

  while(tester.NumTests() != 0)
  begin

    // Now that the whole key schedule is populated, we can change out the keys more quickly, and
    // every round key should correspond to the correct input key as it's propogated through the
    // round pipeline. Start a new key every KEY_CYCLE_COUNT cycles. 
    curTest = tester.GetNextTest();
    @(posedge clock);

    for (int j=0; j<=KEY_CYCLE_COUNT; ++j)
    begin

      @(negedge clock)
      for (int i=0; i<=`NUM_ROUNDS; ++i)
      begin

        if (testFIFO[i].roundKeys[i] !== roundKeysAct[i])
        begin
          tester.ReportError(testFIFO[i].roundKeys[i], roundKeysAct[i], testFIFO[i].key, i, testCount);
//          $display("curTest.roundKeys:\t%h", testFIFO[i].roundKeys);

        end
        $display("Time: %t\tExpected:\t%h", $time, testFIFO[i].roundKeys[i]);
        $display("Time: %t\tActual:\t%h", $time, roundKeysAct[i]);
        
      end
    end

    break;
    ++testCount;

  end

  $display("ExpandKeyTestBench executed %0d test cases", testCount);
  $finish();
end

endmodule

