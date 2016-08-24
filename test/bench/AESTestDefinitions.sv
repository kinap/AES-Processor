`ifndef AES_TEST_DEFINITIONS
  `define AES_TEST_DEFINITIONS

  package AESTestDefinitions;

  import AESDefinitions::*;

  // Test storage structure
  typedef struct packed {
    state_t plain;
    state_t encrypted;
  } test_t;  

  typedef struct packed {
    state_t plain;
    state_t encrypted;
    roundKey_t roundKey;
  } keyTest_t;

  //***************************************************************************************//
  class UnitTester;
    test_t qTests[$];

    function void AddTestCase(state_t plain, state_t encrypted);
      test_t newTest;
      $cast(newTest.plain, plain);
      $cast(newTest.encrypted, encrypted);
      qTests.push_back(newTest);
    endfunction : AddTestCase

    function test_t GetNextTest();
      return qTests.pop_front();
    endfunction : GetNextTest

    function int NumTests();
      return qTests.size();
    endfunction : NumTests

    function void Compare(state_t in, state_t out, test_t curTest, bit encryptedIn);
      CompareOutput_a: assert (out == (encryptedIn ? curTest.plain : curTest.encrypted))
      else
      begin
        $display("*** Error: Current output doesn't match expected");
        if(encryptedIn)
          $display("***        Inverse Phase");
        else
          $display("***        Normal Phase");
        $display("***        Input:    %h", (encryptedIn ? curTest.encrypted : curTest.plain));
        $display("***        Output:   %h", out);
        $display("***        Expected: %h", (encryptedIn ? curTest.plain : curTest.encrypted));
        $error;
      end
    endfunction : Compare

    function void ParseFileForTestCases(string testFile, string phaseString);
      state_t parse1, parse2;
      string parseString, tempString;
      int i, file;
      file = $fopen(testFile, "r");
      while(!$feof(file))
      begin
        i = $fscanf(file, "%s %h\n", parseString, parse2);
        tempString = parseString.substr(parseString.len()-5, parseString.len()-1);
        if(tempString.icompare(phaseString) == 0)
          AddTestCase(.plain(parse1), .encrypted(parse2));
        else
          parse1 = parse2;
      end 
    endfunction : ParseFileForTestCases

  endclass : UnitTester

  //***************************************************************************************//
  class UnitKeyTester;
    keyTest_t qTests[$];

    function void AddTestCase(state_t plain, state_t encrypted, roundKey_t roundKey);
      keyTest_t newTest;
      $cast(newTest.plain, plain);
      $cast(newTest.encrypted, encrypted);
      $cast(newTest.roundKey, roundKey);
      qTests.push_back(newTest);
      `ifdef DEBUG_TEST
        $display("UnitKeyTester.AddTestCase");
        $display("Plain: %h", plain);
        $display("Encrypted: %h", encrypted);
        $display("Round Key: %h", roundKey);
      `endif
    endfunction : AddTestCase

    function keyTest_t GetNextTest();
      return qTests.pop_front();
    endfunction : GetNextTest

    function int NumTests();
      return qTests.size();
    endfunction : NumTests

    function void Compare(state_t in, state_t out, keyTest_t curTest, bit encryptedIn);
      AddRoundKey_a: assert (out == (encryptedIn ? curTest.plain : curTest.encrypted))
      else
      begin
        $display("*** Error: Current output doesn't match expected");
        if(encryptedIn)
          $display("***        Inverse Phase");
        else
          $display("***        Normal Phase");
        $display("***        Input:    %h", (encryptedIn ? curTest.encrypted : curTest.plain));
        $display("***        Key:      %h", curTest.roundKey);
        $display("***        Output:   %h", out);
        $display("***        Expected: %h", (encryptedIn ? curTest.plain : curTest.encrypted));
        $error;
      end
    endfunction : Compare

    function void ParseFileForTestCases(string testFile, string phaseString);
      state_t parse1, parse2, parse3;
      string parseString, tempString;
      int i, file;
      file = $fopen(testFile, "r");
      while(!$feof(file))
      begin
        i = $fscanf(file, "%s %h\n", parseString, parse2);
        tempString = parseString.substr(parseString.len()-5, parseString.len()-1);
        if(tempString.icompare(phaseString) == 0)
        begin
          i = $fscanf(file, "%s %h\n", parseString, parse3);
          AddTestCase(.plain(parse1), .roundKey(parse2), .encrypted(parse3));
        end
        else
          parse1 = parse2;
      end 
    endfunction : ParseFileForTestCases

  endclass : UnitKeyTester

  //***************************************************************************************//
  class RoundTester;
    keyTest_t qTests[$];

    function void AddTestCase(state_t plain, state_t encrypted, roundKey_t roundKey);
      keyTest_t newTest;
      $cast(newTest.plain, plain);
      $cast(newTest.encrypted, encrypted);
      $cast(newTest.roundKey, roundKey);
      qTests.push_back(newTest);
    endfunction : AddTestCase

    function keyTest_t GetNextTest();
      return qTests.pop_front();
    endfunction : GetNextTest

    function int NumTests();
      return qTests.size();
    endfunction : NumTests

    function void Compare(state_t in, state_t out, keyTest_t curTest, bit encryptedIn);
      Round_a: assert (out == (encryptedIn ? curTest.plain : curTest.encrypted))
      else
      begin
        PrintError((encryptedIn ? curTest.encrypted : curTest.plain), 
                curTest.roundKey, out, 
                (encryptedIn ? curTest.plain : curTest.encrypted), 
                encryptedIn);
        $error;
      end
    endfunction : Compare

    function void PrintError(state_t in, key, out, expected, bit inverse);
      $display("*** Error: Current output doesn't match expected");
      if(inverse)
        $display("***        Inverse Phase");
      else
        $display("***        Normal Phase");

      $display("***        Input:    %h", in);
      $display("***        Key:      %h", key);
      $display("***        Output:   %h", out);
      $display("***        Expected: %h", expected);
    endfunction : PrintError

    function void ParseFileForTestCases(string testFile);
      state_t parse1, plain, encrypt;
      roundKey_t key;
      string parseString, tempString;
      int i, file;
      bit [127:0] inputs[$];
      file = $fopen(testFile, "r");
      while(!$feof(file))
      begin
        i = $fscanf(file, "%s %h\n", parseString, parse1);
        tempString = parseString.substr(parseString.len()-5, parseString.len()-1);
        if(tempString.icompare("start") == 0 || tempString.icompare("k_sch") == 0 || tempString.icompare("utput") == 0)
        begin
          inputs.push_back(parse1);
          if(tempString.icompare("utput") == 0)
          begin
            // Drop the last round
            void'(inputs.pop_back());
            void'(inputs.pop_back());
            while(inputs.size() > 2)
            begin
              encrypt = inputs.pop_back();
              key = inputs.pop_back();
              plain = inputs.pop_back();
              AddTestCase(.plain(plain), .roundKey(key), .encrypted(encrypt));
              inputs.push_back(plain);
            end
            inputs = {};
          end
        end
      end
    endfunction : ParseFileForTestCases

  endclass : RoundTester

  //***************************************************************************************//
  class KeyScheduleTester #(parameter KEY_SIZE = 128, 
                            parameter KEY_BYTES = KEY_SIZE / 8, 
                            parameter type key_t = byte_t [0:KEY_BYTES-1]);

    parameter NUM_ROUNDS =
      (KEY_SIZE == 256)
        ? 14
        : (KEY_SIZE == 192)
          ? 12
          : 10;

    parameter type roundKeys_t = roundKey_t [0:NUM_ROUNDS]; 

    typedef struct packed {
      key_t key;
      roundKeys_t roundKeys;
    } expandedKeyTest_t;

    expandedKeyTest_t qTests[$];

    function void AddTestCase(key_t cipherKey, roundKeys_t roundKeys);
      expandedKeyTest_t newTest;
      newTest.key = cipherKey;
      newTest.roundKeys = roundKeys;
      qTests.push_back(newTest);
    endfunction : AddTestCase

    function expandedKeyTest_t GetNextTest();
      return qTests.pop_front();
    endfunction : GetNextTest

    function int NumTests();
      return qTests.size();
    endfunction : NumTests

    function void Compare(expandedKeyTest_t curTest, roundKeys_t roundKeys);

      for (int i=0; i<=NUM_ROUNDS; ++i)
      begin
          
        KeySchedule_a: assert (curTest.roundKeys[i] == roundKeys[i])
        else
        begin
          $display("***      Error: Round key doesn't match expected");
          $display("***      Round:\t%0d", i);
          $display("*** Cipher Key:\t%h", curTest.key);
          $display("***   Expected:\t%h", curTest.roundKeys[i]);
          $display("***     Actual:\t%h", roundKeys[i]);
          $error;
        end

      end
    endfunction : Compare

    function void ParseFileForTestCases(string vectorFile);
      key_t key;
      roundKeys_t roundKeys;
      string header;
      string vectorHeader;
      int i, file;

      file = $fopen(vectorFile, "r");

      if (KEY_SIZE == 128)
          vectorHeader = "AES_128";
      else if (KEY_SIZE == 192)
          vectorHeader = "AES_192";
      else // KEY_SIZE == 256
          vectorHeader = "AES_256";

      // advance file pointer to appropriate section header for key width
      i = $fscanf(file, "%s\n", header);
      while (!$feof(file) && vectorHeader.icompare(header) != 0)
        i = $fscanf(file, "%s\n", header);
        
      while(!$feof(file))
      begin
        i = $fscanf(file, "%h %h\n", key, roundKeys);
        if (i < 2)
          break;

        AddTestCase(key, roundKeys);
      end 

      $fclose(file);

    endfunction : ParseFileForTestCases

  endclass : KeyScheduleTester

  endpackage : AESTestDefinitions

`endif
