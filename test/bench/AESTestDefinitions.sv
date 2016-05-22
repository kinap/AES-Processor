`ifndef AES_TEST_DEFINITIONS
  `define AES_TEST_DEFINITIONS

  // TODO: Remove AES_SIM_ERROR, replace $finish in error detection to $error

  // TODO: Identify methods that are shared between all test classes (like
  // GetNextTest and NumTests) and move them into a test superclass

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

  typedef struct packed {
    key_t key;
    expandedKey_t expandedKey;
  } expandedKeyTest_t;

/*  typedef struct packed {
    state_t plain;
    state_t encrypt;
    key_t key;
  } inputTest_t; */

  //***************************************************************************************//
  class UnitTester;
    test_t qTests[$];

    function void AddTestCase(bit [127:0] plain, bit [127:0] encrypted);
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

    function void Compare(bit [127:0] in, bit [127:0] out, test_t curTest, bit encryptedIn);
      if(out !== (encryptedIn ? curTest.plain : curTest.encrypted))
      begin
        $display("AES_SIM_ERROR");
        $display("*** Error: Current output doesn't match expected");
        if(encryptedIn)
          $display("***        Inverse Phase");
        else
          $display("***        Normal Phase");
        $display("***        Input:    %h", (encryptedIn ? curTest.encrypted : curTest.plain));
        $display("***        Output:   %h", out);
        $display("***        Expected: %h", (encryptedIn ? curTest.plain : curTest.encrypted));
        $finish();
      end
    endfunction : Compare

    function void ParseFileForTestCases(string testFile, string phaseString);
      bit [127:0] parse1, parse2;
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

    function void AddTestCase(bit [127:0] plain, bit [127:0] encrypted, [127:0] roundKey);
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

    function void Compare(bit [127:0] in, bit [127:0] out, keyTest_t curTest, bit encryptedIn);
      if(out !== (encryptedIn ? curTest.plain : curTest.encrypted))
      begin
        $display("AES_SIM_ERROR");
        $display("*** Error: Current output doesn't match expected");
        if(encryptedIn)
          $display("***        Inverse Phase");
        else
          $display("***        Normal Phase");
        $display("***        Input:    %h", (encryptedIn ? curTest.encrypted : curTest.plain));
        $display("***        Key:      %h", curTest.roundKey);
        $display("***        Output:   %h", out);
        $display("***        Expected: %h", (encryptedIn ? curTest.plain : curTest.encrypted));
        $finish();
      end
    endfunction : Compare

    function void ParseFileForTestCases(string testFile, string phaseString);
      bit [127:0] parse1, parse2, parse3;
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

    function void AddTestCase(bit [127:0] plain, bit [127:0] encrypted, [127:0] roundKey);
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

    function void Compare(bit [127:0] in, bit [127:0] out, keyTest_t curTest, bit encryptedIn);
      if(out !== (encryptedIn ? curTest.plain : curTest.encrypted))
      begin
        PrintError((encryptedIn ? curTest.encrypted : curTest.plain), curTest.roundKey, out, (encryptedIn ? curTest.plain : curTest.encrypted), encryptedIn);
        $finish();
      end
    endfunction : Compare

    function void PrintError(bit [127:0] in, key, out, expected, bit inverse);
      $display("AES_SIM_ERROR");
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
      bit [127:0] parse1, plain, encrypt, key;
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
  class KeyScheduleTester;
    expandedKeyTest_t qTests[$];

    `ifdef AES_128
    string vectorHeader = "AES 128\n";
    `elsif AES_192
    string vectorHeader = "AES 192\n";
    `else
    string vectorHeader = "AES 256\n";
    `endif 

    function void AddTestCase(key_t cipherKey, expandedKey_t expandedKey);
      expandedKeyTest_t newTest;
      newTest.key = cipherKey;
      newTest.expandedKey = expandedKey;
      qTests.push_back(newTest);
    endfunction : AddTestCase

    function expandedKeyTest_t GetNextTest();
      return qTests.pop_front();
    endfunction : GetNextTest

    function int NumTests();
      return qTests.size();
    endfunction : NumTests

    function void Compare(expandedKeyTest_t curTest, expandedKey_t expandedKey);
    if(curTest.expandedKey !== expandedKey)
      begin
        $display("AES_SIM_ERROR");
        $display("*** Error: Current output doesn't match expected");
        $display("***        Cipher Key:\t%h", curTest.key);
        $display("***        Expected & Actual:");
        $display("***   EXP: %0h", curTest.expandedKey);
        $display("***   ACT: %0h", expandedKey);
        $finish();
      end
    endfunction : Compare

    function void ParseFileForTestCases(string vectorFile);
      key_t key;
      expandedKey_t expandedKey;
      string header;
      int i, file;

      file = $fopen(vectorFile, "r");

      // advance file pointer to appropriate section header for key width
      i = $fscanf(file, "%s\n", header);
      while (!$feof(file) && vectorHeader.icompare(header) != 0)
        i = $fscanf(file, "%s\n", header);

      while(!$feof(file))
      begin
        i = $fscanf(file, "%h %h\n", key, expandedKey.roundKeys.keys);
        if (i < 1)
          break;

        AddTestCase(key, expandedKey);
        expandedKey = '0;
      end 

      $fclose(file);

    endfunction : ParseFileForTestCases

  endclass : KeyScheduleTester

  endpackage : AESTestDefinitions

`endif
