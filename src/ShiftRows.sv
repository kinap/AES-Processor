//
// ShiftRows Layer of the AES round
//

module ShiftRows(input logic [127:0] inBytes, 
                 output logic [127:0] outBytes);
logic [0:3][0:3][7:0] state, outState;

always_comb
  begin
    state = inBytes;

    outState[0] = state[0];
    outState[1] = { state[1][1:3], state[1][0] };
    outState[2] = { state[2][2:3], state[2][0:1] };
    outState[3] = { state[3][3], state[3][0:2] };

    outBytes = outState;
  end
endmodule
