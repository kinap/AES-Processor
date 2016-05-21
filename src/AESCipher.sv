//
// Top level AES encoder
//

import AESDefinitions::*;

module AESEncoder(input logic clock, reset,
                  input state_t in, key_t key,
                 output state_t out);

state_t roundOutput[`NUM_ROUNDS];
roundKey_t roundKey[`NUM_ROUNDS];
state_t tmp;

// Key expansion block - outside the rounds
ExpandKey keyExpBlock (key, roundKey[0]);

// First round - add key only
AddRoundKey firstRound(in, roundKey[0], tmp);
Buffer #(state_t) firstRoundBuffer(clock, reset, tmp, roundOutput[0]);

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i < `NUM_ROUNDS-2; i++)
    begin
      BufferedRound intermediatRound(clock, reset, roundOutput[i-1], roundKey[i-1], roundOutput[i]);
    end
endgenerate

// Final round - sub, shift, add key
BufferedRound finalRound(clock, reset, roundOutput[`NUM_ROUNDS-1], roundKey[`NUM_ROUNDS-1], out);

endmodule : AESEncoder


module AESDecoder(input logic clock, reset,
                  input state_t in, key_t key,
                 output state_t out);

state_t roundOutput[`NUM_ROUNDS];
roundKey_t roundKey[`NUM_ROUNDS];
state_t tmp;

// Key expansion block - outside the rounds
ExpandKey keyExpBlock (key, roundKey[0]);

// First round - add key only
AddRoundKey firstRound(in, roundKey[0], tmp);
Buffer #(state_t) firstRoundBuffer(clock, reset, tmp, roundOutput[0]);

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i < `NUM_ROUNDS-2; i++)
    begin
      BufferedRoundInverse intermediatRound(clock, reset, roundOutput[i-1], roundKey[i-1], roundOutput[i]);
    end
endgenerate

// Final round - sub, shift, add key
BufferedRoundInverse finalRound(clock, reset, roundOutput[`NUM_ROUNDS-1], roundKey[`NUM_ROUNDS-1], out);

endmodule : AESDecoder
