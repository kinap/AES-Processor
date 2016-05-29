//
// Testbench for ShiftRows & Inverse ShiftRows stage of AES round
//

import AESTestDefinitions::*;

module ShiftRowsTestBench();

// Input and Output connections
state_t in, inInv, out, outInv;
logic valid = 1'b0;

// Module declaration
ShiftRows Dut(valid, in, out);
ShiftRowsInverse Dut2(valid, inInv, outInv);

// Test execution and verification task
test_t curTest;
state_t curOut, curOutInv;

initial
begin
  UnitTester tester;
  tester = new();
  tester.ParseFileForTestCases("test/vectors/fips_example_vectors.txt", "s_row");

  while(tester.NumTests() != 0)
  begin
    curTest = tester.GetNextTest();
    in = curTest.plain;
    inInv = curTest.encrypted;
    valid <= 1'b1;
    #1 repeat(1);
    curOut = out;
    curOutInv = outInv;
    tester.Compare(in, curOut, curTest, 0);
    tester.Compare(inInv, curOutInv, curTest, 1);
  end

  $finish();
end

endmodule
