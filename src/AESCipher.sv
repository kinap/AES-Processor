//
// Top level AES encoder
//

import AESDefinitions::*;

module AESEncoder(input logic clock, reset,
                  input state_t in, key_t key,
                 output state_t out);

state_t roundOutput[`NUM_ROUNDS+1];
roundKeys_t roundKeyOutput[`NUM_ROUNDS+1];

// Key expansion block - outside the rounds
ExpandKey keyExpBlock (key, roundKeyOutput[0]);

// First round - add key only
AddRoundKey firstRound(in, roundKeyOutput[0][0], roundOutput[0]);

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i <= `NUM_ROUNDS; i++)
    begin
      BufferedRound #(i) Round(clock, reset, roundOutput[i-1], roundKeyOutput[i][i], roundOutput[i]);
      Buffer #(roundKeys_t) KeyBuffer(clock, reset, roundKeyOutput[i-1], roundKeyOutput[i]);
    end
endgenerate

assign out = roundOutput[`NUM_ROUNDS];

endmodule : AESEncoder


module AESDecoder(input logic clock, reset,
                  input state_t in, key_t key,
                 output state_t out);

state_t roundOutput[`NUM_ROUNDS+1];
roundKeys_t roundKeyOutput[`NUM_ROUNDS+1];

// Key expansion block - outside the rounds
ExpandKey keyExpBlock (key, roundKeyOutput[0]);

// First round - add key only
AddRoundKey firstRound(in, roundKeyOutput[0][`NUM_ROUNDS], roundOutput[0]);

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i <= `NUM_ROUNDS; i++)
    begin
      BufferedRoundInverse #(i) Round(clock, reset, roundOutput[i-1], roundKeyOutput[i][`NUM_ROUNDS-i], roundOutput[i]);
      Buffer #(roundKeys_t) KeyBuffer(clock, reset, roundKeyOutput[i-1], roundKeyOutput[i]);
    end
endgenerate

assign out = roundOutput[`NUM_ROUNDS];

endmodule : AESDecoder
