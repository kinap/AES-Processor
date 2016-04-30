//
// Testbench for SubBytes & Inverse SubBytes stage of AES round
//

include ../../src/AESDefinitions.svpkg;
include ./AESTestDefinitions.svpkg;

module SubBytesTestBench();

// Input and Output connections
logic [127:0] in, inInv, out, outInv;

test_t qTests[$];

// Test creation task
task automatic MakeTest(bit [127:0] plain, bit [127:0] encrypted);
begin
  test_t newTest;
  $cast(newTest.plain, plain);
  $cast(newTest.encrypted, encrypted);
  qTests.push_back(newTest);
end
endtask

// Module declaration
SubBytes Dut(in, out);
//SubBytesInverse Dut2(inInv, outInv);

// Test exectuion and verfication task
task ApplyTests();
  test_t curTest;
  bit [127:0] curOut, curOutInv;

  while(qTests.size() != 0)
  begin
    curTest = qTests.pop_front();
    in = curTest.plain;
    inInv = curTest.encrypted;
    #1 repeat(1);
    curOut = out;
    curOutInv = outInv;
    if(curOut !== curTest.encrypted)
    begin
      $display("*** Error: Current output doesn't match expected");
      $display("***        Input:    %h", curTest.plain);
      $display("***        Output:   %h", curOut);
      $display("***        Expected: %h", curTest.encrypted);
      $finish();
    end
    if(curOutInv !== curTest.plain)
    begin

    end
  end
endtask

int testFile, i;
bit [127:0] parse1, parse2;
string phaseString, tempString;

initial
begin
  testFile = $fopen("test/vectors/fips_example_vectors.txt", "r");
  while(!$feof(testFile))
  begin
    i = $fscanf(testFile, "%s %h\n", phaseString, parse1);
    tempString = phaseString.substr(phaseString.len()-5, phaseString.len()-1);
    if(tempString.icompare("start") == 0)
    begin
      i = $fscanf(testFile, "%s %h\n", phaseString, parse2);
      MakeTest(parse1, parse2);
    end
  end
  $fclose(testFile);

  ApplyTests();
  $finish();
end

endmodule
