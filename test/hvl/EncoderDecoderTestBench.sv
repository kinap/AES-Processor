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
int errorCount = 0, passCount = 0;

// Stimulus generation class
// Read in plain text, key, and encrypted output from files
class StimulusGeneration;
  scemi_dynamic_input_pipe driver;

  // Variables to hold input data
  state_t inData, expected;
  key_t keyData;
  inputTest_t test;
  int i, j, k;

  string plainFN, encryptFN, keyFN;

  function new();
  begin
    driver = new("Transactor.inputpipe");
    `ifdef AES_192
      plainFN = "test/vectors/plain_192.txt";
      encryptFN = "test/vectors/encrypted_192.txt";
      keyFN = "test/vectors/key_192.txt";
    `elsif AES_256
      plainFN = "test/vectors/plain_256.txt";
      encryptFN = "test/vectors/encrypted_256.txt";
      keyFN = "test/vectors/key_256.txt";
    `else
      plainFN = "test/vectors/plain.txt";
      encryptFN = "test/vectors/encrypted.txt";
      keyFN = "test/vectors/key.txt";
    `endif
    plain_file = $fopen(plainFN, "rb");
    encrypted_file = $fopen(encryptFN, "rb");
    key_file = $fopen(keyFN, "rb");
  end
  endfunction : new

  task run;
    automatic byte unsigned dataSend[] = new[2*AES_STATE_SIZE+KEY_BYTES+1];
    while(!$feof(plain_file) && !$feof(encrypted_file) && !$feof(key_file))
    begin
      // Read in plain and encrypted data and key
      i = $fscanf(plain_file, "%h", inData);
      j = $fscanf(encrypted_file, "%h", expected);
      k = $fscanf(key_file, "%h", keyData);

      //Check if data is read in
      if(i <= 0 && j <= 0 && k <= 0)
        continue;
      
      // Create a test and push it to the queue
      //test.testType = DIRECTED;
      test.testType = SEEDED;
      test.plain = inData;
      test.encrypt = expected;
      test.key = keyData;
      sentTests.push_back(test);
      
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
