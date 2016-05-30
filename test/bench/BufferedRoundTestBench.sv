//
// Testbench for Round & Inverse Round stage of AES round
//

import AESTestDefinitions::*;

module BufferedRoundTestBench();
parameter CLOCK_CYCLE = 20ns;
parameter CLOCK_WIDTH = CLOCK_CYCLE/2;
parameter IDLE_CLOCKS = 2;

// Input and Output connections
state_t in, inInv, in2, inInv2, out, outInv, out2, outInv2;
roundKey_t key, key2, keyInv2;
logic clock, reset;
logic rndValid = '0, rndLastValid = '0, invValid = '0, invLastValid = '0;

// Module declaration
BufferedRound Dut(clock, reset, rndValid, in, key, out);
BufferedRoundInverse Dut2(clock, reset, invValid, inInv, key, outInv);

// Test last round as a special case
BufferedRound #(`NUM_ROUNDS) Dut3(clock, reset, rndLastValid, in2, key2, out2);
BufferedRoundInverse #(`NUM_ROUNDS) Dut4(clock, reset, invLastValid, inInv2, keyInv2, outInv2);

// Test execution and verification task
keyTest_t curTest;
bit [127:0] curOut, curOutInv;

// Create a free running clock
initial
begin
clock = `FALSE;
forever #CLOCK_WIDTH clock = ~clock;
end

// Generate a reset signal for two cycles
initial
begin
reset = `TRUE;
repeat (IDLE_CLOCKS) @(negedge clock);
reset = `FALSE;
end

initial
begin
  RoundTester tester, invTester;
  tester = new();
  tester.ParseFileForTestCases("test/vectors/fips_example_vectors.txt");
  repeat (IDLE_CLOCKS) @(negedge clock);

  while(tester.NumTests() != 0)
  begin
    curTest = tester.GetNextTest();
    in = curTest.plain;
    key = curTest.roundKey;
    rndValid <= 1'b1;
    repeat(1) @(negedge clock);
    curOut = out;
    tester.Compare(in, curOut, curTest, 0);
  end

  invTester = new();
  tester.ParseFileForTestCases("test/vectors/fips_example_inverse_vectors.txt");

  while(tester.NumTests() != 0)
  begin
    curTest = tester.GetNextTest();
    inInv = curTest.plain;
    key = curTest.roundKey;
    invValid <= 1'b1;
    repeat(1) @(negedge clock);
    curOutInv = outInv;
    tester.Compare(inInv, curOutInv, curTest, 0);
  end

  $finish();
end

// Special case testing for the last round
bit [127:0] expected1 = 128'h69C4E0D86A7B0430D8CDB78070B4C55A, 
            expected2 = 128'h00112233445566778899AABBCCDDEEFF;
initial
begin
  RoundTester testerFinal;
  testerFinal = new();
  repeat(IDLE_CLOCKS) @(negedge clock);

  in2 = 128'hBD6E7C3DF2B5779E0B61216E8B10B689;
  inInv2 = 128'h6353E08C0960E104CD70B751BACAD0E7;
  key2 = 128'h13111D7FE3944A17F307A78B4D2B30C5;
  keyInv2 = 128'h000102030405060708090A0B0C0D0E0F;
  rndLastValid <= 1'b1;
  invLastValid <= 1'b1;
  repeat(1) @(negedge clock);
  if(out2 !== expected1)
    testerFinal.PrintError(in2, key2, out2, expected1, 0);

  if(outInv2 !== expected2)
    testerFinal.PrintError(inInv2, keyInv2, outInv2, expected2, 1);

end

endmodule : BufferedRoundTestBench
