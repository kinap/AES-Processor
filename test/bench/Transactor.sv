//
// Top level testbench on the HDL side. Contains XRTL Transactor
//

import AESTestDefinitions::*;

module Transactor();

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
initial
begin
  reset = 1;
  #20 reset = 0;
end

// DUT Instantiation
key_t inputKey, decoderKey;
state_t inputData, encryptData, outputData;

AESEncoder encoder(clock, reset, inputData, inputKey, encryptData);
AESDecoder decoder(clock, reset, encryptdata, decoderKey, outputData);

// Input Pipe Instantiation
scemi_input_pipe #(.BYTES_PER_ELEMENT(AES_STATE_SIZE+KEY_BYTES),
                   .PAYLOAD_MAX_ELEMENTS(1),
                   .BUFFER_MAX_ELEMENTS(100)
                  ) inputpipe(clock);

// Output Pipe Instantiation
scemi_output_pipe #(.BYTES_PER_ELEMENT(AES_STATE_SIZE),
                    .PAYLOAD_MAX_ELEMENTS(2),
                    .BUFFER_MAX_ELEMENTS(100)
                  ) outputpipe(clock);

//XRTL FSM to obtain operands from the HVL side
inputTest_t testIn;
state_t [1:0] testOut;
bit eom = 0;
logic [7:0] ne_valid = 0;
int eom;

always @(posedge clock)
begin
  if(reset)
  begin
    inputData <= '0;
    inputKey <= '0;
  end
  else
  begin
    testOut = {encryptData, outputData};
    outputpipe.send(2,testOut,eom);

    if(!eom)
    begin
      inputpipe.recieve(1,ne_valid,testIn,eom);
      inputData <= testIn.data;
      inputKey <= testIn.key;
    end
  end
end

endmodule : Transactor
