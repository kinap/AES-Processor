//
// Top level testbench on the HDL side. Contains XRTL Transactor
//

import AESDefinitions::*;

typedef enum byte { DIRECTED, SEEDED } TEST_TYPE;

module Transactor #(parameter KEY_SIZE = 128, 
                    parameter KEY_BYTES = KEY_SIZE / 8, 
                    parameter type key_t = byte_t [0:KEY_BYTES-1]);

parameter NUM_ROUNDS =
  (KEY_SIZE == 256)
    ? 14
    : (KEY_SIZE == 192)
      ? 12
      : 10;
parameter KEY_BYTES_256 = 256 / 8;

// Clock generation
parameter CLOCK_WIDTH = 20;
parameter CLOCK_CYCLE = CLOCK_WIDTH/2;
parameter END_DELAY = (NUM_ROUNDS+10)*CLOCK_WIDTH;

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
logic phaseReset = 0;
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
key_t inputKey, inputEncryptKey, encryptKey, bufferEncryptKey;
state_t plainData, encryptData, outputEncrypt, outputPlain, inputEncryptData;
logic encodeValid, decodeValid, bufReset;

assign inputEncryptData = (TestPhase == 0) ? encryptData : outputEncrypt;
assign inputEncryptKey = (TestPhase == 0) ? inputKey : bufferEncryptKey;
assign decodeReset = (TestPhase == 0) ? reset : bufReset;
key_t bufferedEncryptKeys[NUM_ROUNDS+1];
logic bufferedReset[NUM_ROUNDS+1];
assign bufferedEncryptKeys[0] = inputKey;
assign bufferedReset[0] = reset;
assign bufferEncryptKey = bufferedEncryptKeys[NUM_ROUNDS];
assign bufReset = bufferedReset[NUM_ROUNDS] | phaseReset;
genvar j;
generate
  for(j = 1; j <= NUM_ROUNDS; j++)
  begin
    Buffer #(key_t) KeyBuffer(clock, reset, bufferedEncryptKeys[j-1], bufferedEncryptKeys[j]);
    Buffer #(logic) ResetBuffer(clock, 1'b0, bufferedReset[j-1], bufferedReset[j]);
  end
endgenerate
AESEncoder encoder(clock, reset, plainData, inputKey, outputEncrypt, encodeValid);
AESDecoder decoder(clock, decodeReset, inputEncryptData, inputEncryptKey, outputPlain, decodeValid);

// Assertions to check output
property encodeCheck;
  @(posedge clock)
  disable iff(reset || (TestPhase != 0))
  (encodeValid & (outputEncrypt == $past(encryptData,NUM_ROUNDS))) | !encodeValid;
endproperty

p1: assert property(encodeCheck) else $display("%d\n%d\n%d",encodeValid,reset,TestPhase);

property decodeCheck;
  @(posedge clock)
  disable iff(reset || (TestPhase != 0))
  (decodeValid & (outputPlain == $past(plainData,NUM_ROUNDS))) | !decodeValid;
endproperty

p2: assert property(decodeCheck);

property encodeDecodeCheck;
  @(posedge clock)
  disable iff(reset || TestPhase != 1 || phaseReset)
  (decodeValid & (outputPlain == $past(plainData, 2*NUM_ROUNDS))) | !decodeValid;
endproperty

p3: assert property(encodeDecodeCheck);

// Input Pipe Instantiation
/* REMOVE
scemi_input_pipe #(.BYTES_PER_ELEMENT(2*AES_STATE_SIZE+KEY_BYTES+1),
*/
scemi_input_pipe #(.BYTES_PER_ELEMENT(4*AES_STATE_SIZE+KEY_BYTES_256+1),
                   .PAYLOAD_MAX_ELEMENTS(1),
                   .BUFFER_MAX_ELEMENTS(100)
                  ) inputpipe(clock);

//XRTL FSM to obtain operands from the HVL side
inputTest_t testIn;
state_t tempData;
key_t tempKey;
bit eom = 0;
int i = 0;
logic [7:0] ne_valid = 0;
//TEST_TYPE lastPhase = DIRECTED;
logic switchedPhase = 0;

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
      if(!eom)
      begin
        testIn = {<<byte{testIn}};
        if((testIn.testType == SEEDED) && (switchedPhase == 0))
        begin
          TestPhase = 1;
          switchedPhase = 1;
          phaseReset = 1;
          repeat(2) @(posedge clock);
          phaseReset = 0;
        end
        if(testIn.testType == DIRECTED)
        begin
          TestPhase = 0;
          plainData <= testIn.plain;
          encryptData <= testIn.encrypt128;
          inputKey <= testIn.key;
        end
        else if(testIn.testType == SEEDED)
        begin
          tempData = testIn.plain;
          tempKey = testIn.key;
          for(i=0; i<128; i=i+1)
          begin
            plainData <= tempData ^ (1<<i);
            inputKey <= tempKey;
            encryptKey <= tempKey;
            repeat(1) @(posedge clock);
          end
          for(i=0; i<128; i=i+1)
          begin
            plainData <= tempData ^ (1<<i);
            inputKey <= ~tempKey;
            encryptKey <= ~tempKey;
            repeat(1) @(posedge clock);
          end
          plainData <= tempData;
          inputKey <= tempKey;
          encryptKey <= tempKey;
        end
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
