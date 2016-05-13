//
// Key Expansion Module
//

`include "AESDefinitions.svpkg"

module ExpandKey(input key_t key, output expandedKey_t expandedKey);

localparam byte_t [KEY_COL_SIZE-1:0] RCON[11] = '{
    'h8d, 'h01, 'h02, 'h04, 'h08, 'h10, 
    'h20, 'h40, 'h80, 'h1b, 'h36
};

always_comb
begin

    expandedKey.expBlocks[0] = key;

    for (int i=1; i<=`NUM_KEY_EXP_ROUNDS; ++i)
        expandedKey.expBlocks[i] = expandBlock(i, expandedKey.expBlocks[i-1]);

end

`ifndef AES_256 // expanding a 128- or 192-bit key

    function automatic expandBlock(input integer round, expKeyBlock_t prevBlock);

        expKeyBlock_t nextBlock;

        nextBlock[0] = prevBlock[0] ^ ApplyRcon(round, SubBytes_4(Rot(prevBlock[KEY_NUM_COLS-1])));

        for (int i=1; i<=(KEY_NUM_COLS-1); ++i)
            nextBlock[i] = nextBlock[i-1] ^ prevBlock[i];

        return nextBlock;

    endfunction

`else // Expanding a 256-bit key

    function automatic expandBlock(input integer round, expKeyBlock_t prevBlock);

        expKeyBlock_t nextBlock;

        nextBlock[0] = prevBlock[0] ^ ApplyRcon(round, SubBytes_4(Rot(prevBlock[KEY_NUM_COLS-1])));

        for (int i=1; i<=3; ++i)
            nextExpandedKey.columns[i] = nextExpandedKey.columns[i-1] ^ prevExpandedKey.columns[i];

        nextExpandedKey.columns[4] = SubBytes_4(nextExpandedKey.columns[3]) ^ prevExpandedKey.columns[4];

        for (int i=5; i<=7; ++i)
            nextExpandedKey.columns[i] = nextExpandedKey.columns[i-1] ^ prevExpandedKey.columns[i];

        return nextBlock;

    endfunction

`endif // `ifndef AES_256

function automatic expKeyColumn_t ApplyRcon(input integer round, expKeyColumn_t in);

    return in ^ (RCON[round] << (KEY_COL_SIZE-1));

endfunction

function automatic expKeyColumn_t SubBytes_4(input expKeyColumn_t in);

    expKeyColumn_t out;

    for(int i=0; i<=3; ++i)
    begin
      out[i] = sbox[in[i][7:4]][in[i][3:0]];
    end

    return out;

endfunction

function automatic expKeyColumn_t Rot(input expKeyColumn_t in);

    return {in[1:KEY_COL_SIZE-1], in[0]};

endfunction

endmodule
