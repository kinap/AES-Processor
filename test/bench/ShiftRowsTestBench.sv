//
// Testbench for ShiftRows & Inverse ShiftRows stage of AES round
//

include ../../src/AESDefinitions.svpkg;

module ShiftRowsTestBench();

// Input and Output connections
logic [127:0] in, inInv, out, outInv;

// Test storage structures
typedef struct {
  state_t plain;
  state_t encrypted;
} test_t;

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
ShiftRows Dut(in, out);
ShiftRowsInverse Dut2(inInv, outInv);

// Test execution and verification task
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
      $display("*** Error: Current output doesn't match expected");
      $display("***        Input:    %h", curTest.encrypted);
      $display("***        Ouptut:   %h", curOutInv);
      $display("***        Expected: %h", curTest.plain);
      $finish();
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
    if(tempString.icompare("s_box") == 0)
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
