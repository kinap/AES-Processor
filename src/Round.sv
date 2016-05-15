//
// AES Round & Inverse Round
//

`include "AESDefinitions.svpkg"

module Round(input state_t in, roundKey_t key,
             output state_t out);
parameter RoundNum = 1;
localparam finalRound = ((RoundNum == `NUM_ROUNDS) ? 1 : 0);

// State wire array
state_t wires[3];

SubBytes sb(in, wires[0]);
ShiftRows sr(wires[0], wires[1]);

// Final round doesn't perform the mix columns step
if(finalRound)
  assign wires[2] = wires[1];
else
  MixColumns mc(wires[1], wires[2]);

AddRoundKey ark(wires[2], key, out);

endmodule : Round

module RoundInverse(input state_t in, roundKey_t key,
                    output state_t out);
parameter RoundNum = 1;
localparam finalRound = (RoundNum == `NUM_ROUNDS) ? 1 : 0;

// State wire array
state_t wires[3];

ShiftRowsInverse isr(in, wires[0]);
SubBytesInverse isb(wires[0], wires[1]);
AddRoundKey ark(wires[1], key, wires[2]);

// Final round doesn't perform the mix columns step
if(finalRound)
  assign out = wires[2];
else
  MixColumnsInverse mc(wires[2], out);

endmodule : RoundInverse
