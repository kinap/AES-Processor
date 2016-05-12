//
// Key Expansion Module
//

// TODO: this module only supports 128-bit key - update to support larger keys
`include "AESDefinitions.svpkg"

module KeyExpansion(input byte_t round, expandedKey_t prevExpandedKey,
                    output roundKey_t roundKey, expandedKey_t nextExpandedKey);

localparam byte_t RCON[16] = '{
    8'h8d, 8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 
    8'h80, 8'h1b, 8'h36, 8'h6c, 8'hd8, 8'hab, 8'h4d, 8'h9a
};


always_comb
begin

    nextExpandedKey.columns[0] = genFirstColumn(
        round, prevExpandedKey.columns[0], prevExpandedKey.columns[KEY_NUM_COLS-1]);

    for (int i=1; i<=3; ++i)
        nextExpandedKey.columns[i] = nextExpandedKey.columns[i-1] ^ prevExpandedKey.columns[i];

    // this won't be so simple for AES192 and AES256
    roundKey = nextExpandedKey;

end

function automatic keyColumn_t genFirstColumn(input integer round, keyColumn_t prevFirst, prevLast);

    keyColumn_t out;

    out = prevFirst ^ ApplyRcon(round, SubBytes_4(Rot(prevLast)));

    return out;

endfunction


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
