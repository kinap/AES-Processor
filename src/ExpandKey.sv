//
// Key Expansion Module
//

// TODO: this module only supports 128-bit key - update to support larger keys
`include "AESDefinitions.svpkg"

module KeyExpansion(input key_t key, 
                    output roundKey_t [0:`NUM_ROUNDS+1] keySchedule);

localparam byte_t RCON[16] = '{
    8'h8d, 8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 
    8'h80, 8'h1b, 8'h36, 8'h6c, 8'hd8, 8'hab, 8'h4d, 8'h9a
};

localparam KEYROUNDS = `NUM_ROUNDS + 1;

always_comb
begin

    keySchedule[0] = key;
    for (int i=1; i<=KEYROUNDS; ++i)
        keySchedule[i] = CalcRoundKey(i, keySchedule[i-1]);

end

function automatic byte_t [3:0][3:0] CalcRoundKey(input integer round, byte_t [3:0][3:0] prevRound);

    byte_t [3:0][3:0] nextRound;

    nextRound[0] = prevRound[0] ^ ApplyRcon(round, SubBytes_4(Rot(prevRound[3])));

    for (int i=1; i<=3; ++i)
        nextRound[i] = nextRound[i-1] ^ prevRound[i];

    return nextRound;

endfunction

function automatic byte_t [3:0] ApplyRcon(input integer round, byte_t [3:0] in);

    return in ^ {RCON[round], 8'h0, 8'h0, 8'h0};

endfunction

// TODO: parameterize the SubBytes module and use that instead of this function
function automatic byte_t [3:0] SubBytes_4(input byte_t [3:0] in);

    byte_t [3:0] out;

    for(int i=0; i<=3; ++i)
    begin
      out[i] = sbox[in[i][7:4]][in[i][3:0]];
    end

    return out;

endfunction

function automatic byte_t [3:0] Rot(input byte_t [3:0] in);

    return {in[2:0], in[3]};

endfunction

endmodule
