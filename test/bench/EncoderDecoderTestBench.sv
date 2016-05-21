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
state_t encryptedTests [$];
int errorCount = 0;

// Scoreboard class
// Monitors output pipe, compare to golden result
class ScoreBoard;
  state_t data;
  key_t key;
  state_t outEncrypted, outDecrypted,
          expectEncrypted, expectDecrypted;

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

      expectEncrypted = encryptedTest.pop_front;
      expectDecrypted = sentTest.pop_front;

      if(outEncrypted !== expectEncrypted)
      begin
        $display("***Error: Encrypted output doesn't match expected");
        $display("***       Encrypted output: %h", outEncrypted);
        $display("***       Expected:         %h", expectedEncrypted);
        errorCount++;
      end

      if(outDecrypted !== expectDecrypted)
      begin
        $display("***Error: Decrypted output doesn't match expected");
        $display("***       Decrypted output: %h", outDecrypted);
        $display("***       Expected:         %h", expectedDecrypted);
        errorCount++;
      end
 
      if(eom_flag)
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
    plain_file = $fopen("test/vector/plain.txt", "rb");
    encrypted_file = $fopen("test/vector/encrypted.txt", "rb");
    key_file = $fopen("test/vector/key.txt", "rb");
  end
  endfunction : new

  task run;
    automatic int counter = 0;
    automatic byte unsigned plainByte, encryptedByte, keyByte;
    automatic byte unsigned dataSend[] = new[AES_STATE_SIZE+KEY_BYTES];
    while(!$feof(plain_file) && !$feof(encrypted_file) && $feof(key_file))
    begin
      counter++;
      plainByte = $fgetc(plain_file);
      encryptedByte = $fgetc(encrypted_file);
      keyByte = $fgetc(key_file);
      inData[AES_STATE_SIZE-counter] = plainByte;
      expected[AES_STATE_SIZE-counter] = encryptedByte;
      keyData[AES_STATE_SIZE-counter] = keyByte;
      if(counter == AES_STATE_SIZE)
      begin
        test.data = inData;
        test.key = keyData;
        sentTests.push_back(test);
        encryptedTests.push_back(expected);
        foreach(dataSend[i])
        begin
          dataSend[i] = test[7:0];
          dataSend = {8'b0,test[AES_STATE_SIZE+KEY_BYTES-1:8]};
        end

        driver.send_bytes(1, dataSend, 0);
      end
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
      $display("\nStarted at:"); $system("data");
      run();
    join_none
  end

  final
  begin
    $display("\nEnded at:"); $system("data");
    if(!errorCount)
      $display("All tests pass sucessfully");
    else
      $display("%0d tests failed", errorCount);
  end

endmodule : EncoderDecoderTestBench 
