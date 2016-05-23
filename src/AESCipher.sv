//
// Top level AES encoder
//

import AESDefinitions::*;

module AESEncoder(input logic clock, reset,
                  input state_t in, key_t key,
                 output state_t out);

state_t roundOutput[`NUM_ROUNDS];
roundKeys_t roundKeyOutput[`NUM_ROUNDS];
roundKeys_t roundKeys;
state_t tmp;

// Key expansion block - outside the rounds
ExpandKey keyExpBlock (key, roundKeys);

// First round - add key only
AddRoundKey firstRound(in, roundKeys[0], tmp);
Buffer #(state_t) firstRoundBuffer(clock, reset, tmp, roundOutput[0]);
Buffer #(roundKeys_t) firstRoundKeyBuffer(clock, reset, roundKeys, roundKeyOutput[0]);

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i < `NUM_ROUNDS; i++)
    begin
      BufferedRound intermediateRound(clock, reset, roundOutput[i-1], roundKeyOutput[i-1][i-1], roundOutput[i]);
      Buffer #(roundKeys_t) intermediateRoundKeys(clock, reset, roundKeyOutput[i-1], roundKeyOutput[i]);
    end
endgenerate

assign out = roundOutput[`NUM_ROUNDS-1];

endmodule : AESEncoder


module AESDecoder(input logic clock, reset,
                  input state_t in, key_t key,
                 output state_t out);

state_t roundOutput[`NUM_ROUNDS];
roundKeys_t roundKeyOutput[`NUM_ROUNDS];
roundKeys_t roundKeys;
state_t tmp;

// Key expansion block - outside the rounds
ExpandKey keyExpBlock (key, roundKeys);

// First round - add key only
AddRoundKey firstRound(in, roundKeys[0], tmp);
Buffer #(state_t) firstRoundBuffer(clock, reset, tmp, roundOutput[0]);
Buffer #(roundKeys_t) firstRoundKeyBuffer(clock, reset, roundKeys, roundKeyOutput[0]);

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i < `NUM_ROUNDS; i++)
    begin
      BufferedRoundInverse intermediatRound(clock, reset, roundOutput[i-1], roundKeyOutput[i-1][i-1], roundOutput[i]);
      Buffer #(roundKeys_t) intermediateRoundKeys(clock, reset, roundKeyOutput[i-1], roundKeyOutput[i]);
    end
endgenerate

// Final round - sub, shift, add key
assign out = roundOutput[`NUM_ROUNDS-1];

endmodule : AESDecoder
