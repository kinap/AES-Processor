//
// Top level testbench on the HDL side. Contains XRTL Transactor
//

import AESDefinitions::*;

typedef struct packed {
  state_t plain;
  state_t encrypt;
  key_t key;
} inputTest_t;

module Transactor;

// Clock generation
logic clock;
//tbx clkgen
initial
begin
clock=0;
forever #10 clock=~clock;
end

// Reset generation
logic reset;
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
AESDecoder decoder(clock, reset, encryptData, inputKey, outputPlain, decodeVaiid);

// Input Pipe Instantiation
scemi_input_pipe #(.BYTES_PER_ELEMENT(2*AES_STATE_SIZE+KEY_BYTES),
                   .PAYLOAD_MAX_ELEMENTS(1),
                   .BUFFER_MAX_ELEMENTS(100)
                  ) inputpipe(clock);

// Output Pipe Instantiation
scemi_output_pipe #(.BYTES_PER_ELEMENT(2*AES_STATE_SIZE+1),
                    .PAYLOAD_MAX_ELEMENTS(1),
                    .BUFFER_MAX_ELEMENTS(100)
                  ) outputpipe(clock);

//XRTL FSM to obtain operands from the HVL side
inputTest_t testIn;
state_t [1:0] testOut;
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
    //$display("outputEncrypt: %h", outputEncrypt);
    //$display("outputPlain: %h", outputPlain);
    testOut = {outputEncrypt, outputPlain, {3'b0, encodeValid}, {3'b0, decodeValid}};
    outputpipe.send(1,testOut,eom);

    if(!eom)
    begin
      inputpipe.receive(1,ne_valid,testIn,eom);
      testIn = {<<byte{testIn}};
      //$display("testIn: %h", testIn);
      plainData <= testIn.plain;
      //$display("plain: %h", testIn.plain);
      encryptData <= testIn.encrypt;
      //$display("encrypt: %h", testIn.encrypt);
      inputKey <= testIn.key;
      //$display("key: %h", testIn.key);
    end
  end
end

endmodule : Transactor
