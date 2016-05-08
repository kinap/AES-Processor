//
// Testbench for Round & Inverse Round stage of AES round
//

`include "./AESTestDefinitions.svpkg"

module RoundTestBench();

// Input and Output connections
logic [127:0] in, inInv, out, outInv;
logic [`KEY_SIZE-1:0] key;

// Module declaration
Round Dut(in, key, out);
RoundInverse Dut2(inInv, key, outInv);

// Test execution and verification task
keyTest_t curTest;
bit [127:0] curOut, curOutInv;

initial
begin
  UnitKeyTester tester;
  tester = new();
  tester.ParseFileForTestCases("test/vectors/fips_example_vectors.txt", "k_sch");

  while(tester.NumTests() != 0)
  begin
    curTest = tester.GetNextTest();
    in = curTest.plain;
    inInv = curTest.encrypted;
    key = curTest.roundKey;
    #1 repeat(1);
    curOut = out;
    curOutInv = outInv;
    tester.Compare(in, curOut, curTest, 0);
    tester.Compare(inInv, curOutInv, curTest, 1);
  end

  $finish();
end

endmodule : RoundTestBench
