//
// Top level AES encoder
//

import AESDefinitions::*;

module AESEncoder(input logic clock, reset,
                  input state_t in, key_t key,
                 output state_t out,
                 output encodeValid);

state_t roundOutput[`NUM_ROUNDS+1];
roundKeys_t roundKeyOutput[`NUM_ROUNDS+1];
logic roundValid[`NUM_ROUNDS+1];
logic counterValid;

assign roundValid[0] = ~reset;

// counter for valid signal
Counter validCounter(clock, reset, counterValid);

// Key expansion block - outside the rounds
ExpandKey keyExpBlock (roundValid[0], key, roundKeyOutput[0]);

// First round - add key only
AddRoundKey firstRound(roundValid[0], in, roundKeyOutput[0][0], roundOutput[0]);

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i <= `NUM_ROUNDS; i++)
    begin
      BufferedRound #(i) Round(clock, reset, roundValid[i-1], roundOutput[i-1], roundKeyOutput[i-1][i], roundOutput[i]);
      Buffer #(roundKeys_t) KeyBuffer(clock, reset, roundKeyOutput[i-1], roundKeyOutput[i]);
      Buffer ValidBuffer(clock, reset, roundValid[i-1], roundValid[i]);
    end
endgenerate

assign out = roundOutput[`NUM_ROUNDS];
assign encodeValid = counterValid & roundValid[`NUM_ROUNDS];

endmodule : AESEncoder


module AESDecoder(input logic clock, reset,
                  input state_t in, key_t key,
                 output state_t out,
                 output decodeValid);

state_t roundOutput[`NUM_ROUNDS+1];
roundKeys_t roundKeyOutput[`NUM_ROUNDS+1];
logic roundValid[`NUM_ROUNDS+1];
logic counterValid;

assign roundValid[0] = ~reset;

// counter for valid signal
Counter validCounter(clock, reset, counterValid);

// Key expansion block - outside the rounds
ExpandKey keyExpBlock (roundValid[0], key, roundKeyOutput[0]);

// First round - add key only
AddRoundKey firstRound(roundValid[0], in, roundKeyOutput[0][`NUM_ROUNDS], roundOutput[0]);

// Intermediate rounds - sub, shift, mix, add key
genvar i;
generate
  for(i = 1; i <= `NUM_ROUNDS; i++)
    begin
      BufferedRoundInverse #(i) Round(clock, reset, roundValid[i-1], roundOutput[i-1], roundKeyOutput[i-1][`NUM_ROUNDS-i], roundOutput[i]);
      Buffer #(roundKeys_t) KeyBuffer(clock, reset, roundKeyOutput[i-1], roundKeyOutput[i]);
      Buffer roundValidBuffer(clock, reset, roundValid[i-1], roundValid[i]);
    end
endgenerate

assign out = roundOutput[`NUM_ROUNDS];
assign decodeValid = counterValid & roundValid[`NUM_ROUNDS];

endmodule : AESDecoder
