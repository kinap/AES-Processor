//
// Testbench for AddRoundKey stage of AES round
//

`include "./AESTestDefinitions.svpkg"

module AddRoundKeyTestBench();

// Input and Output connections
logic [127:0] in, inInv, out, outInv, key, outKey;

// Module declaration
AddRoundKey Dut(in, out, outKey);

// Test exectuion and verfication task
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
  end

  $finish();
end

endmodule
