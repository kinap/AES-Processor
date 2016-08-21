//
// Top level testbench on the HDL side. Contains XRTL Transactor
//

import AESDefinitions::*;

typedef enum byte { DIRECTED, SEEDED } TEST_TYPE;

typedef struct packed {
  TEST_TYPE testType;
  state_t plain;
  state_t encrypt;
  key_t key;
} inputTest_t;

typedef struct packed {
  state_t encrypt;
  state_t plain;
  logic [3:0] encryptValid;
  logic [3:0] plainVlaid;
} outputResult_t;

module Transactor;

// Clock generation
parameter CLOCK_WIDTH = 20;
parameter CLOCK_CYCLE = CLOCK_WIDTH/2;
parameter END_DELAY = (`NUM_ROUNDS+10)*CLOCK_WIDTH;
logic clock = 0;
//tbx clkgen inactive_negedge
initial
begin
clock=0;
forever #CLOCK_CYCLE clock=~clock;
end

// Reset generation
logic globalReset = 1;
logic localReset = 0;
logic reset;
//tbx clkgen
initial
begin
  globalReset = 1;
  #CLOCK_WIDTH globalReset = 0;
end

assign reset = globalReset | localReset;

// DUT Instantiation
logic TestPhase = 0;
key_t inputKey;
state_t plainData, encryptData, outputEncrypt, outputPlain, inputEncryptData;
logic encodeValid, decodeValid;

assign inputEncryptData = (TestPhase == 0) ? encryptData : outputEncrypt;
AESEncoder encoder(clock, reset, plainData, inputKey, outputEncrypt, encodeValid);
AESDecoder decoder(clock, reset, inputEncryptData, inputKey, outputPlain, decodeValid);

// Assertions to check output
property encodeCheck;
  @(posedge clock)
  disable iff(reset || TestPhase != 0)
  (encodeValid & (outputEncrypt == $past(encryptData,`NUM_ROUNDS))) | !encodeValid;
endproperty

p1: assert property(encodeCheck);

property decodeCheck;
  @(posedge clock)
  disable iff(reset || TestPhase != 0)
  (decodeValid & (outputPlain == $past(plainData,`NUM_ROUNDS))) | !decodeValid;
endproperty

p2: assert property(decodeCheck);

// Input Pipe Instantiation
scemi_input_pipe #(.BYTES_PER_ELEMENT(2*AES_STATE_SIZE+KEY_BYTES+1),
                   .PAYLOAD_MAX_ELEMENTS(1),
                   .BUFFER_MAX_ELEMENTS(100)
                  ) inputpipe(clock);

//XRTL FSM to obtain operands from the HVL side
inputTest_t testIn;
bit eom = 0;
logic [7:0] ne_valid = 0;

always @(posedge clock)
begin
  if(reset)
  begin
    plainData <= '0;
    encryptData <= '0;
    inputKey <= '0;
  end
  else
  begin
    if(!eom)
    begin
      inputpipe.receive(1,ne_valid,testIn,eom);
      testIn = {<<byte{testIn}};
      if(testIn.testType == DIRECTED)
      begin
        plainData <= testIn.plain;
        encryptData <= testIn.encrypt;
        inputKey <= testIn.key;
      end
    end
    else
    begin
      localReset = 1;
      #END_DELAY $finish();
    end
  end
end

endmodule : Transactor
