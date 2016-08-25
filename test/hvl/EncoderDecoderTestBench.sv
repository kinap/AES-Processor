//
// HVL Testbench for AES Encoder and Decoder
// Works alongside Transactor.sv on the Emulator
//

import scemi_pipes_pkg::*;
import AESTestDefinitions::*;
import AESDefinitions::*;

// File Handles
/* REMOVE
int plain_file, plain_file2;
int encrypted_file, encrypted_file2;
int key_file, key_file2;
*/
int directed_file, seeded_file;

// Stimulus generation class
// Read in plain text, key, and encrypted output from files
/* REMOVE
class StimulusGeneration #(parameter KEY_SIZE = 128, 
                           parameter KEY_BYTES = KEY_SIZE / 8, 
                           parameter type key_t = byte_t [0:KEY_BYTES-1]);
*/
class StimulusGeneration;

  scemi_dynamic_input_pipe driver;

  parameter KEY_SIZE = 256;
  parameter KEY_BYTES = KEY_SIZE / 8;
  typedef byte_t [0:KEY_BYTES-1] key_t;

/* REMOVE
  typedef struct packed {
    TEST_TYPE testType;
    state_t plain;
    state_t encrypt;
    key_t key;
  } inputTest_t;
*/
  typedef struct packed {
    TEST_TYPE testType;
    state_t plain;
    key_t key;
    state_t encrypt128;
    state_t encrypt192;
    state_t encrypt256;
  } inputTest_t;

/* REMOVE
  // Store sent data and expected encrypted output in a queue;
  inputTest_t sentTests [$];
  int errorCount = 0, passCount = 0;
*/

  // Variables to hold input data
  state_t inData, expected128, expected192, expected256;
  key_t keyData;
  inputTest_t test;
/* REMOVE
  int i, j, k;
*/
  int i;
  string directedFN, seededFN;

/* REMOVE
  string plainFN, encryptFN, keyFN;
*/

  function new();
  begin
    driver = new("Transactor.inputpipe");
    /* REMOVE
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
    plain_file2 = $fopen(plainFN, "rb");
    encrypted_file2 = $fopen(encryptFN, "rb");
    key_file2 = $fopen(keyFN, "rb");
    */
    directedFN = "test/vectors/directed.txt";
    seededFN = "test/vectors/seeded.txt";
    directed_file = $fopen(directedFN, "rb");
    seeded_file = $fopen(seededFN, "rb");
  end
  endfunction : new

  task run;
    /* REMOVE
    automatic byte unsigned dataSend[] = new[2*AES_STATE_SIZE+KEY_BYTES+1];
    */
    automatic byte unsigned dataSend[] = new[4*AES_STATE_SIZE+KEY_BYTES+1];
    /*
    while(!$feof(plain_file) && !$feof(encrypted_file) && !$feof(key_file))
    */
    while(!$feof(directed_file))
    begin
      // Read in plain and encrypted data and key
/* REMOVE
      i = $fscanf(plain_file, "%h", inData);
      j = $fscanf(encrypted_file, "%h", expected);
      k = $fscanf(key_file, "%h", keyData);
*/
      i = $fscanf(directed_file, "%h %h %h %h %h", inData, keyData, expected128, 
                    expected192, expected256);      

      //Check if data is read in
    /* REMOVE
      if(i <= 0 && j <= 0 && k <= 0)
    */
      if(i <= 0)
        continue;
      
      // Create a test and push it to the queue
      test.testType = DIRECTED;
      test.plain = inData;
    /* REMOVE
      test.encrypt = expected;
    */
      test.encrypt128 = expected128;
      test.encrypt192 = expected192;
      test.encrypt256 = expected256;
      test.key = keyData;
     /* REMOVE
      sentTests.push_back(test);
     */      

      // Convert the data to an array to send
      dataSend = {>>byte{test}};

      driver.send_bytes(1, dataSend, 0);
    end

/* REMOVE
    while(!$feof(plain_file2) && !$feof(encrypted_file2) && !$feof(key_file2))
*/
    while(!$feof(seeded_file))
    begin
      // Read in plain and encrypted data and key
/* REMOVE
      i = $fscanf(plain_file2, "%h", inData);
      j = $fscanf(encrypted_file2, "%h", expected);
      k = $fscanf(key_file2, "%h", keyData);
*/
      i = $fscanf(seeded_file, "%h %h %h %h %h", inData, keyData, expected128,
                    expected192, expected256);     

      //Check if data is read in
     /* REMOVE
      if(i <= 0 && j <= 0 && k <= 0)
     */
      if(i <= 0)
        continue;
      
      // Create a test and push it to the queue
      test.testType = SEEDED;
      test.plain = inData;
    /* REMOVE
      test.encrypt = expected;
    */
      test.encrypt128 = expected128;
      test.encrypt192 = expected192;
      test.encrypt256 = expected256;
      test.key = keyData;
    /* REMOVE
      sentTests.push_back(test);
    */      

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
