//
// Testbench for Expand Key module
//

import AESTestDefinitions::*;

// TODO how do we want to test all key sizes?
module KeyExpansionTestBench #(parameter KEY_SIZE = 128, 
                               parameter KEY_BYTES = KEY_SIZE / 8);
parameter NUM_ROUNDS =
  (KEY_SIZE == 256)
    ? 14
    : (KEY_SIZE == 192)
      ? 12
      : 10;

roundKey_t prevKey [NUM_ROUNDS];
roundKey_t roundKey [NUM_ROUNDS];
keyRoundTest_t curTest;
int idx = 0;

// each key round has a unique rcon value, so we must test them separately
genvar i;
for (i = 1; i <= NUM_ROUNDS; i++)
begin
  KeyRound #(.RCON_ITER(i)) mut(prevKey[i-1], roundKey[i-1]);
end

initial
begin
  KeyRoundTester tester;
  tester = new();

  tester.ParseFileForTestCases("test/vectors/fips_example_vectors.txt", "k_sch", KEY_SIZE);
  
  while(tester.NumTests() != 0)
  begin
    curTest = tester.GetNextTest();
    // only stimulate the corresponding round
    prevKey[idx] = curTest.prevKey;
    #1 repeat(1);
    tester.Compare(roundKey[idx], curTest);
    idx += 1;
  end

  $finish();
end

endmodule

