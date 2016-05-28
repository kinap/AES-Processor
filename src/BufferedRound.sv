//
// Round module with buffering of the output
//

import AESDefinitions::*;

module BufferedRound(input logic clock, reset, validInput,
                     input state_t in, roundKey_t key,
                     output state_t out);
parameter RoundNum = 1;

// State wire for intermediate value
state_t temp;

Round #(RoundNum) round(validInput, in, key, temp);
Buffer #(state_t) buffer(clock, reset, temp, out);

endmodule : BufferedRound

module BufferedRoundInverse(input logic clock, reset, validInput,
                            input state_t in, roundKey_t key,
                            output state_t out);
parameter RoundNum = 1;

// State wire for intermediate value
state_t temp;

RoundInverse #(RoundNum) invRound(validInput, in, key, temp);
Buffer #(state_t) buffer(clock, reset, temp, out);

endmodule : BufferedRoundInverse
