//
// HVL Testbench for AES Encoder and Decoder
// Works alongside Transactor.sv on the Emulator
//

import scemi_pipes_pkg::*;
import AESTestDefinitions::*;
import AESDefinitions::*;

// File Handles
int plain_file;
int encrypted_file;
int key_file;

// Store sent data and expected encrypted output in a queue;
inputTest_t sentTests [$];
int errorCount = 0;

// Scoreboard class
// Monitors output pipe, compare to golden result
class ScoreBoard;
  state_t data;
  key_t key;
  state_t outEncrypted, outDecrypted,
          expectEncrypted, expectDecrypted;
  inputTest_t curTest;

  scemi_dynamic_output_pipe monitor;

  function new();
  begin
    monitor = new("Transactor.outputpipe");
  end
  endfunction : new

  task run();
    bit eom_flag;
    bit [1:0] ne_valid;
    while(1)
    begin
      automatic byte unsigned result[] = new[2*AES_STATE_SIZE];

      //Note - this function call is blocking, waits until result is available
      monitor.receive_bytes(1, ne_valid, result, eom_flag);
      foreach(result[i])
      begin
        outEncrypted = {result[i],outEncrypted[0:AES_STATE_SIZE-9]};
      end

      monitor.receive_bytes(1, ne_valid, result, eom_flag);
      foreach(result[i])
      begin
        outDecrypted = {result[i],outDecrypted[0:AES_STATE_SIZE-9]};
      end

      curTest = sentTests.pop_front();
      expectEncrypted = curTest.encrypt;
      expectDecrypted = curTest.plain;

      $display("outEncrypted: %h", outEncrypted);
      $display("outDecrypted: %h", outDecrypted);

      if(outEncrypted !== expectEncrypted)
      begin
        $display("***Error: Encrypted output doesn't match expected");
        $display("***       Encrypted output: %h", outEncrypted);
        $display("***       Expected:         %h", expectEncrypted);
        errorCount++;
      end

      if(outDecrypted !== expectDecrypted)
      begin
        $display("***Error: Decrypted output doesn't match expected");
        $display("***       Decrypted output: %h", outDecrypted);
        $display("***       Expected:         %h", expectDecrypted);
        errorCount++;
      end
 
      if(eom_flag && (sentTests.size() == 0))
          $finish;
    end
  endtask : run

endclass : ScoreBoard;

// Stimulus generation class
// Read in plain text, key, and encrypted output from files
class StimulusGeneration;
  scemi_dynamic_input_pipe driver;

  // Variables to hold input data
  state_t inData, expected;
  key_t keyData;
  inputTest_t test;
  int i;

  function new();
  begin
    driver = new("Transactor.inputpipe");
    plain_file = $fopen("test/vectors/plain.txt", "rb");
    encrypted_file = $fopen("test/vectors/encrypted.txt", "rb");
    key_file = $fopen("test/vectors/key.txt", "rb");
    
    // Push enough "dummy" tests to allow the encoder/decoder to output real data
    for(int j = 0; j <= `NUM_ROUNDS; j++)
    begin
      test = '0;
      sentTests.push_back(test);
    end
  end
  endfunction : new

  task run;
    automatic byte unsigned dataSend[] = new[2*AES_STATE_SIZE+KEY_BYTES];
    while(!$feof(plain_file) && !$feof(encrypted_file) && !$feof(key_file))
    begin
      // Read in plain and encrypted data and key
      i = $fscanf(plain_file, "%h", inData);
      $display("%m, inData: %h", inData);
      i = $fscanf(encrypted_file, "%h", expected);
      $display("%m, expected: %h", expected);
      i = $fscanf(key_file, "%h", keyData);
      $display("%m, key: %h", keyData);
      
      // Create a test and push it to the queue
      test.plain = inData;
      test.encrypt = expected;
      test.key = keyData;
      sentTests.push_back(test);
      
      $display("%m, %h", test);
      // Convert the data to an array to send
      foreach(dataSend[i])
      begin
        dataSend[i] = test[$bits(test)-1:$bits(test)-8];
        test = {test, 8'b0};
      end
      $display("%m, %h", dataSend);

      driver.send_bytes(1, dataSend, 0);
    end

    //Sent eom and flush the pipe
    dataSend[0] = 0;
    driver.send_bytes(1,dataSend,1);
    driver.flush();
  endtask : run

endclass : StimulusGeneration

module EncoderDecoderTestBench;
  ScoreBoard scb;
  StimulusGeneration stim;

  task run();
  begin
    fork
    begin
      scb.run();
    end
    join_none

    fork
    begin
      stim.run();
    end
    join_none
  end
  endtask : run

  initial
  begin
    fork
      scb = new();
      stim = new();
      $display("\nStarted at:"); $system("date");
      run();
    join_none
  end

  final
  begin
    $display("\nEnded at:"); $system("date");
    if(!errorCount)
      $display("All tests pass sucessfully");
    else
      $display("%0d tests failed", errorCount);
  end

endmodule : EncoderDecoderTestBench 
