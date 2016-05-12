//
// Key Expansion Module
//

// TODO: The original plan for this module isn't going to work for 192- and 256-bit keys. 
// 
// There is not a 1:1 correspondence between the iteration used to generate the key schedule and the
// rounds for Nk != 16. For example, in AES 192, each iteration of the key expansion algorithm
// generates 192 bits, and it is repeated 8 times, creating a vectore that is 216 bytes wide (the
// last 8 of which are truncated). The round keys are every 128-bit (16-byte) block within this
// vector (leaving the last 8 bytes unused). 
// 
// Thus, each round key may actually require the results from two separate iterations of the key
// expansion algorithm. We need to move this module outside of the round modules, let it generate
// the whole key, and use exensive buffering to get the right round keys in the right places.

`include "AESDefinitions.svpkg"

module KeyExpansion(input byte_t round, expandedKey_t prevExpandedKey,
                    output roundKey_t roundKey, expandedKey_t nextExpandedKey);

localparam byte_t RCON[11] = '{
    8'h8d, 8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 
    8'h20, 8'h40, 8'h80, 8'h1b, 8'h36, 
};


always_comb
begin

    nextExpandedKey.columns[0] = prevExpandedKey.columns[0] ^ ApplyRcon(
                                    round, SubBytes_4(Rot(prevExpandedKey.columns[KEY_NUM_COLS-1])));

    `ifndef AES_256 // Expanding a 128- or 192-bit key
        for (int i=1; i<=(KEY_NUM_COLS-1); ++i)
            nextExpandedKey.columns[i] = nextExpandedKey.columns[i-1] ^ prevExpandedKey.columns[i];

    `ifdef AES_192 // 192-bit key
    
        // see note at the top of this file

    `else // 128-bit key

        roundKey = nextExpandedKey;

    `endif // `ifdef AES_192

    `else // Expanding a 256-bit key

        for (int i=1; i<=3; ++i)
            nextExpandedKey.columns[i] = nextExpandedKey.columns[i-1] ^ prevExpandedKey.columns[i];

        nextExpandedKey.columns[4] = SubBytes_4(nextExpandedKey.columns[3]) ^ prevExpandedKey.columns[4];

        for (int i=5; i<=7; ++i)
            nextExpandedKey.columns[i] = nextExpandedKey.columns[i-1] ^ prevExpandedKey.columns[i];

        // see note at the top of this file

    `endif // `ifndef AES_256

end

function automatic keyColumn_t ApplyRcon(input integer round, keyColumn_t in);

    return in ^ (RCON[round] << (KEY_COL_SIZE-1));

endfunction

function automatic keyColumn_t SubBytes_4(input keyColumn_t in);

    keyColumn_t out;

    for(int i=0; i<=3; ++i)
    begin
      out[i] = sbox[in[i][7:4]][in[i][3:0]];
    end

    return out;

endfunction

function automatic keyColumn_t Rot(input keyColumn_t in);

    return {in[KEY_COL_SIZE-2:0], in[KEY_COL_SIZE-1]};

endfunction

endmodule
