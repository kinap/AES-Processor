//
// Testbench for Expand Key module
//

import AESTestDefinitions::*;

module ExpandKeyTestBench();

// Input and Output connections
key_t key;
expandedKey_t expandedKey;
expandedKeyTest_t curTest;
int testCount = 0;

// Module under test instantiation
ExpandKey mut(
    .key(key), 
    .expandedKey(expandedKey)
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
    tester.Compare(curTest, expandedKey);
  end

  $display("ExpandKeyTestBench executed %0d test cases", testCount);
  $finish();
end

endmodule
