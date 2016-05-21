//
// Testbench for Expand Key module
//

import AESTestDefinitions::*;

module ExpandKeyTestBench();

key_t key;
roundKeys_t roundKeys;
expandedKeyTest_t curTest;
int testCount = 0;

ExpandKey mut(
    .key(key), 
    .roundKeys(roundKeys)
);

initial
begin
  KeyScheduleTester tester;
  tester = new();
  tester.ParseFileForTestCases("test/vectors/key_schedule_vectors.txt");
  
  $display("ROUND_KEY_COLS: %0d", mut.ROUND_KEY_COLS);
  $display("KEY_SCH_COLS: %0d", mut.KEY_SCH_COLS);
  $display("KEY_SCH_SHIFT: %0d", mut.KEY_SCH_SHIFT);
  $display("Num tests: %d", tester.NumTests());
  $monitor("Round Key Cols: %h\n mut.roundKeys: %h", mut.keyBlocks, mut.roundKeys);

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
