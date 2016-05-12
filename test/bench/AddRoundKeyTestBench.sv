//
// Testbench for AddRoundKey stage of AES round
//

`include "./AESTestDefinitions.svpkg"

module AddRoundKeyTestBench();

// Input and Output connections
logic [127:0] in, out, key;

// Module declaration
AddRoundKey Dut(in, key, out);

// Test exectuion and verfication task
keyTest_t curTest;
bit [127:0] curOut;

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
