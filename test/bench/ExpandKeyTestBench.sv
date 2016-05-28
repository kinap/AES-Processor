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
    .validInput(1'b1),
    .key(key), 
    .roundKeys(roundKeys)
);

initial
begin
  KeyScheduleTester tester;
  tester = new();
  tester.ParseFileForTestCases("test/vectors/key_schedule_vectors.txt");
  
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
