//
// Testbench for Expand Key module
//

import AESTestDefinitions::*;

module ExpandKeyTestBench #(parameter KEY_SIZE = 128, 
                            parameter KEY_BYTES = KEY_SIZE / 8, 
                            parameter NUM_ROUNDS = 10, 
                            parameter type roundKeys_t = roundKey_t [0:NUM_ROUNDS], 
                            parameter type key_t = byte_t [0:KEY_BYTES-1]);

typedef struct packed {
  key_t key;
  roundKeys_t roundKeys;
} expandedKeyTest_t;

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
  // TODO how do we want to test all key sizes?
  KeyScheduleTester #(128) tester;
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

