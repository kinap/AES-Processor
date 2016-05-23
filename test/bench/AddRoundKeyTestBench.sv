//
// Testbench for AddRoundKey stage of AES round
//

import AESTestDefinitions::*;

module AddRoundKeyTestBench();

// Input and Output connections
state_t in, out;
roundKey_t key;

// Module declaration
AddRoundKey Dut(in, key, out);

// Test exectuion and verfication task
keyTest_t curTest;
state_t curOut;

initial
begin
  UnitKeyTester tester;
  tester = new();
  tester.ParseFileForTestCases("test/vectors/fips_example_vectors.txt", "k_sch");

  while(tester.NumTests() != 0)
  begin
    curTest = tester.GetNextTest();
    in = curTest.plain;
    key = curTest.roundKey;
    #1 repeat(1);
    curOut = out;
    tester.Compare(in, curOut, curTest, 0);
  end

  $finish();
end

endmodule
