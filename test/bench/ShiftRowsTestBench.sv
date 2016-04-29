//
// Testbench for ShiftRows stage of AES round
//

include ../../src/AESDefinitions.svpkg;

module ShiftRowsTestBench();

// Input and Output connections
logic [127:0] in, out;

// Test storage structures
typedef struct {
  state_t in;
  state_t out;
} test_t;

test_t qTests[$];

// Test creation task
task automatic MakeTest(bit [127:0] in, bit [127:0] out);
begin
  test_t newTest;
  $cast(newTest.in, in);
  $cast(newTest.out, out);
  qTests.push_back(newTest);
end
endtask

// Module declaration
ShiftRows Dut(in, out);

// Test execution and verification task
task ApplyTests();
  test_t curTest;
  bit [127:0] curOut;

  while(qTests.size() != 0)
  begin
    curTest = qTests.pop_front();
    in = curTest.in;
    #1 repeat(1);
    curOut = out;
    if(curOut !== curTest.out)
    begin
      $display("*** Error: Current output doesn't match expected");
      $display("***        Input:    %h", curTest.in);
      $display("***        Output:   %h", curOut);
      $display("***        Expected: %h", curTest.out);
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
