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
  class KeyRoundTester #(parameter KEY_SIZE = 128,
                         parameter KEY_BYTES = KEY_SIZE / 8,
                         parameter type key_t = byte_t [0:KEY_BYTES-1]);

    typedef struct packed {
      roundKey_t prevKey;
      roundKey_t roundKey;
      key_t key;
    } keyRoundTest_t;

    keyRoundTest_t qTests[$];

    function void AddTestCase(roundKey_t prevKey, roundKey_t roundKey, key_t key);
      keyRoundTest_t newTest;
      $cast(newTest.prevKey, prevKey);
      $cast(newTest.roundKey, roundKey);
      $cast(newTest.key, key);
      qTests.push_back(newTest);
      `ifdef DEBUG_TEST
        $display("KeyRoundTester.AddTestCase");
        $display("Prev Key: %h", prevKey);
        $display("Round Key: %h", roundKey);
        $display("initial: %h", key);
      `endif
    endfunction : AddTestCase

    function keyRoundTest_t GetNextTest();
      return qTests.pop_front();
    endfunction : GetNextTest

    function int NumTests();
      return qTests.size();
    endfunction : NumTests

    function void Compare(roundKey_t actual, keyRoundTest_t curTest);
      AddRoundKey_a: assert (actual == curTest.roundKey)
      else
      begin
        $display("*** Error: Current output doesn't match expected");
        $display("***        Prev Key: %h", curTest.prevKey);
        $display("***        Actual  : %h", actual);
        $display("***        Expected: %h", curTest.roundKey);
        $error;
      end
    endfunction : Compare

    function void ParseFileForTestCases(string testFile, string phaseString, integer KEY_SIZE);
      roundKey_t firstFound, secondFound, tmp;
      string parseString, tempString, initialKey;
      string vectorHeader;
      int i, file;
      bit first_parse = 1;

      file = $fopen(testFile, "r");

      if (KEY_SIZE == 128)
          vectorHeader = "AES-128";
      else if (KEY_SIZE == 192)
          vectorHeader = "AES-192";
      else // KEY_SIZE == 256
          vectorHeader = "AES-256";

      // advance file pointer to appropriate section header for key width
      while($fscanf(file, "%s", parseString) && parseString != vectorHeader);
        // get initial key
        i = $fscanf(file, "%s %h\n", "KEY", initialKey);

      // i'm not proud of what follows
      while(!$feof(file))
      begin
        // search for occurance of k_sch
        i = $fscanf(file, "%s %h\n", parseString, firstFound);
        // key size delimeter
        if (parseString == "****")
            break;

        tempString = parseString.substr(parseString.len()-5, parseString.len()-1);

        // if found, it is saved as firstFound already
        if(tempString.icompare(phaseString) == 0)
        begin

          // first time through file, read two keys
          if (first_parse)
          begin
              while(first_parse)
              begin
                  // search again to find expected answer
                  i = $fscanf(file, "%s %h\n", parseString, secondFound);
                  tempString = parseString.substr(parseString.len()-5, parseString.len()-1);

                  // if found, it is saved as secondFound already
                  if(tempString.icompare(phaseString) == 0)
                  begin
                    AddTestCase(.prevKey(firstFound), .roundKey(secondFound), .key(initialKey));
                    first_parse = 0;
                  end
              end
          end
          // subsequent times through file, read 1 key, use last read key as the starting point
          else
          begin
            tmp = firstFound;
            firstFound = secondFound;
            secondFound = tmp;
            AddTestCase(.prevKey(firstFound), .roundKey(secondFound), .key(initialKey));
          end
        end
      end 
    endfunction : ParseFileForTestCases

  endclass : KeyRoundTester

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

  endpackage : AESTestDefinitions

`endif
