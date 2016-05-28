//
// AES Round & Inverse Round
//

import AESDefinitions::*;

module Round(input logic validInput, state_t in, roundKey_t key,
             output state_t out);
parameter RoundNum = 1;
localparam finalRound = ((RoundNum == `NUM_ROUNDS) ? 1 : 0);

// State wire array
state_t wires[3];

SubBytes sb(validInput, in, wires[0]);
ShiftRows sr(validInput, wires[0], wires[1]);

// Final round doesn't perform the mix columns step
if(finalRound)
  assign wires[2] = wires[1];
else
  MixColumns mc(validInput, wires[1], wires[2]);

AddRoundKey ark(validInput, wires[2], key, out);

endmodule : Round

module RoundInverse(input logic validInput, state_t in, roundKey_t key,
                    output state_t out);
parameter RoundNum = 1;
localparam finalRound = (RoundNum == `NUM_ROUNDS) ? 1 : 0;

// State wire array
state_t wires[3];

ShiftRowsInverse isr(validInput, in, wires[0]);
SubBytesInverse isb(validInput, wires[0], wires[1]);
AddRoundKey ark(validInput, wires[1], key, wires[2]);

// Final round doesn't perform the mix columns step
if(finalRound)
  assign out = wires[2];
else
  MixColumnsInverse mc(validInput, wires[2], out);

endmodule : RoundInverse
