//
// Top level testbench on the HDL side. Contains XRTL Transactor
//

import AESDefinitions::*;

typedef struct packed {
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
logic clock = 0;
//tbx clkgen
initial
begin
clock=0;
forever #10 clock=~clock;
end

// Reset generation
logic reset = 1;
//tbx clkgen
initial
begin
  reset = 1;
  #20 reset = 0;
end

// DUT Instantiation
key_t inputKey;
state_t plainData, encryptData, outputEncrypt, outputPlain;
logic encodeValid, decodeValid;

AESEncoder encoder(clock, reset, plainData, inputKey, outputEncrypt, encodeValid);
AESDecoder decoder(clock, reset, encryptData, inputKey, outputPlain, decodeValid);

// Input Pipe Instantiation
scemi_input_pipe #(.BYTES_PER_ELEMENT(2*AES_STATE_SIZE+KEY_BYTES),
                   .PAYLOAD_MAX_ELEMENTS(1)
                  ) inputpipe(clock);

// Output Pipe Instantiation
scemi_output_pipe #(.BYTES_PER_ELEMENT(2*AES_STATE_SIZE+1),
                    .PAYLOAD_MAX_ELEMENTS(1)
                  ) outputpipe(clock);

//XRTL FSM to obtain operands from the HVL side
inputTest_t testIn;
outputResult_t testOut;
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
    testOut = {outputEncrypt, outputPlain, {3'b0, encodeValid}, {3'b0, decodeValid}};
    outputpipe.send(1,testOut,eom);

    if(!eom)
    begin
      inputpipe.receive(1,ne_valid,testIn,eom);
      testIn = {<<byte{testIn}};
      plainData <= testIn.plain;
      encryptData <= testIn.encrypt;
      inputKey <= testIn.key;
    end
  end
end

endmodule : Transactor
