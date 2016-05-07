//
// AES Round & InverseRound
//

include AESDefinitions.svpkg;

module Round(input state_t in, roundKey_t key
             output state_t out);
parameter Round = 1;
loclparam finalRound = (Round == NUM_ROUNDS) ? 1 : 0;

// State wire array
state_t wires[3];

SubBytes sb(in, wires[0]);
ShiftRows sr(wires[0], wires[1]);

// Final round doesn't perform the mix columns step
if(finalRound)
  assign wires[2] = wires[1];
else
  MixColumns(wires[1], wires[2]);

AddRoundKey ark(wires[2], key, out);

endmodule : Round

module InverseRound(input state_t in, roundKey_t key
                    output state_t out);
parameter Round = 1;
localparam finalRound = (ROUND == NUM_ROUNDS) ? 1 : 0;

// State wire array
state_t wires[3];

InverseShiftRows isr(in, wires[0]);
InverseSubBytes isb(wires[0], wires[1]);
AddRoundKey ark(wires[1], wires[2]);

// Final round doesn't perform the mix columns step
if(finalRound)
  assign out = wires[2];
else
  MixColumns(wires[2], out);

endmodule : InverseRound
