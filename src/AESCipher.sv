//
// Top level AES encoder
//

import AESDefinitions::*;

module AESEncoder #(parameter KEY_SIZE = 128, 
                    parameter KEY_BYTES = KEY_SIZE / 8, 
                    parameter type key_t = byte_t [0:KEY_BYTES-1])

(input logic clock, reset,
input state_t in, key_t key,
output state_t out,
output encodeValid);

parameter NUM_ROUNDS =
  (KEY_SIZE == 256)
    ? 14
    : (KEY_SIZE == 192)
      ? 12
      : 10;

typedef roundKey_t [0:NUM_ROUNDS] roundKeys_t;

state_t roundOutput[0:NUM_ROUNDS];
roundKeys_t roundKeys;

//
// Module instantiations
// 

// counter for valid signal
Counter #(NUM_ROUNDS) validCounter(clock, reset, encodeValid);

// Key expansion block - internally pipelined
KeyExpansion #(KEY_SIZE) keyExpBlock (clock, reset, key, roundKeys);

// First round - add original key only
AddRoundKey firstRound(in, roundKeys[0], roundOutput[0]);

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i <= NUM_ROUNDS; i++)
    begin
      BufferedRound #(i, NUM_ROUNDS) Round(clock, reset, roundOutput[i-1], roundKeys[i], roundOutput[i]);
    end
endgenerate

assign out = roundOutput[NUM_ROUNDS];

endmodule : AESEncoder


module AESDecoder #(parameter KEY_SIZE = 128, 
                    parameter KEY_BYTES = KEY_SIZE / 8, 
                    parameter type key_t = byte_t [0:KEY_BYTES-1])

(input logic clock, reset,
input state_t in, key_t key,
output state_t out,
output decodeValid);

parameter NUM_ROUNDS =
  (KEY_SIZE == 256)
    ? 14
    : (KEY_SIZE == 192)
      ? 12
      : 10;

typedef roundKey_t [0:NUM_ROUNDS] roundKeys_t;

state_t roundOutput[0:NUM_ROUNDS];
roundKeys_t roundKeys;

//
// Module instantiations
// 

// counter for valid signal
Counter #(NUM_ROUNDS) validCounter(clock, reset, decodeValid);

// Key expansion block - internally pipelined
KeyExpansion #(KEY_SIZE) keyExpBlock (clock, reset, key, roundKeys);

// First round - add key only
AddRoundKey firstRound(in, roundKeys[0], roundOutput[0]);

//
// Round generation loop
//

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i <= NUM_ROUNDS; i++)
    begin
      BufferedRoundInverse #(i, NUM_ROUNDS) Round(clock, reset, roundOutput[i-1], roundKeys[i], roundOutput[i]);
    end
endgenerate

assign out = roundOutput[NUM_ROUNDS];

endmodule : AESDecoder
