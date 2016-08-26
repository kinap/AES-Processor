//
// HVL Testbench for AES Encoder and Decoder
// Works alongside Transactor.sv on the Emulator
//

import scemi_pipes_pkg::*;
import AESTestDefinitions::*;
import AESDefinitions::*;

// File Handles
int directed_file, seeded_file;

// Stimulus generation class
class StimulusGeneration;

  scemi_dynamic_input_pipe driver;

  parameter KEY_SIZE = 256;
  parameter KEY_BYTES = KEY_SIZE / 8;
  typedef byte_t [0:KEY_BYTES-1] key_t;

  typedef struct packed {
    TEST_TYPE testType;
    state_t plain;
    key_t key;
    state_t encrypt128;
    state_t encrypt192;
    state_t encrypt256;
  } inputTest_t;

  // Variables to hold input data
  state_t inData, expected128, expected192, expected256;
  key_t keyData;
  inputTest_t test;
  int i;
  string directedFN, seededFN;

  function new();
  begin
    driver = new("Transactor.inputpipe");
    directedFN = "test/vectors/directed.txt";
    seededFN = "test/vectors/seeded.txt";
    directed_file = $fopen(directedFN, "rb");
    seeded_file = $fopen(seededFN, "rb");
  end
  endfunction : new

  task run;
    automatic byte unsigned dataSend[] = new[4*AES_STATE_SIZE+KEY_BYTES+1];
    while(!$feof(directed_file))
    begin
      // Read in plain and encrypted data and key
      i = $fscanf(directed_file, "%h %h %h %h %h", inData, keyData, expected128, 
                    expected192, expected256);      

      //Check if data is read in
      if(i <= 0)
        continue;
      
      // Create a test and push it to the queue
      test.testType = DIRECTED;
      test.plain = inData;
      test.encrypt128 = expected128;
      test.encrypt192 = expected192;
      test.encrypt256 = expected256;
      test.key = keyData;

      // Convert the data to an array to send
      dataSend = {>>byte{test}};

      driver.send_bytes(1, dataSend, 0);
    end

    while(!$feof(seeded_file))
    begin
      // Read in plain and encrypted data and key
      i = $fscanf(seeded_file, "%h %h %h %h %h", inData, keyData, expected128,
                    expected192, expected256);     

      //Check if data is read in
      if(i <= 0)
        continue;
      
      // Create a test and push it to the queue
      test.testType = SEEDED;
      test.plain = inData;
      test.encrypt128 = expected128;
      test.encrypt192 = expected192;
      test.encrypt256 = expected256;
      test.key = keyData;

      // Convert the data to an array to send
      dataSend = {>>byte{test}};

      driver.send_bytes(1, dataSend, 0);
    end

    //Sent eom and flush the pipe
    dataSend[0] = 0;
    driver.send_bytes(1,dataSend,1);
    driver.flush();
  endtask : run

endclass : StimulusGeneration

module EncoderDecoderTestBench;
  StimulusGeneration stim;

  task run();
  begin
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
      stim = new();
      $display("\nStarted at:"); $system("date");
      run();
    join_none
  end

  final
  begin
    $display("\nEnded at:"); $system("date");
  end

endmodule : EncoderDecoderTestBench 
