//
// Key Expansion Module
//

import AESDefinitions::*;
import SBox::*;

module ExpandKey(input logic validInput, key_t key, output roundKeys_t roundKeys);

localparam KEY_COL_SIZE = 4;

localparam byte_t [KEY_COL_SIZE-1:0] RCON[12] = '{
    'h8d, 'h01, 'h02, 'h04, 'h08, 'h10, 
    'h20, 'h40, 'h80, 'h1b, 'h36, 'h6c
};

`ifdef AES_256
    localparam NUM_KEY_EXP_ROUNDS = 8;
`elsif AES_192
    localparam NUM_KEY_EXP_ROUNDS = 9;
`else
    localparam NUM_KEY_EXP_ROUNDS = 11;
`endif

localparam KEY_NUM_COLS = KEY_BYTES / KEY_COL_SIZE;
localparam ROUND_KEY_BITS = AES_STATE_SIZE * 8;

// The algorithm that produces the key schedule operates on blocks that are equal to the key size,
// but the round keys are always 128 bits. For 192- and 256-bit keys, the algorithm produces a key
// schedule that is 64 and 128 bits wider than the round keys necessary, respectively. This
// parameter is calculates the number of bits that the calculated key schedule needs to be shifted
// right to produce correctly-aligned keys.
// bit shift = (key width * # of expansion rounds + 1) - (round key width * # of cipher rounds +1)
localparam KEY_SCH_SHIFT = (`KEY_SIZE * (NUM_KEY_EXP_ROUNDS+1)) - 
                                (ROUND_KEY_BITS * (`NUM_ROUNDS+1));

typedef byte_t [0:KEY_COL_SIZE-1] expKeyColumn_t;
typedef expKeyColumn_t [0:KEY_NUM_COLS-1] expKeyBlock_t;

expKeyBlock_t [0:NUM_KEY_EXP_ROUNDS] keyBlocks;
assign roundKeys = (keyBlocks >> KEY_SCH_SHIFT);

always_comb
begin

    ExpKeyKnownKey_a: assert ((~validInput) || (~$isunknown(key)));

    keyBlocks[0] = key;

    for (int j=1; j<=NUM_KEY_EXP_ROUNDS; ++j)
        keyBlocks[j] = expandBlock(j, keyBlocks[j-1]);

end

`ifndef AES_256 // expanding a 128- or 192-bit key

    function automatic expKeyBlock_t expandBlock(input integer round, expKeyBlock_t prevBlock);

        expKeyBlock_t nextBlock;

        nextBlock[0] = prevBlock[0] ^ ApplyRcon(round, SubBytes_4(Rot(prevBlock[KEY_NUM_COLS-1])));

        for (int i=1; i<=(KEY_NUM_COLS-1); ++i)
            nextBlock[i] = nextBlock[i-1] ^ prevBlock[i];

        return nextBlock;

    endfunction

`else // Expanding a 256-bit key

    function automatic expKeyBlock_t expandBlock(input integer round, expKeyBlock_t prevBlock);

        expKeyBlock_t nextBlock;

        nextBlock[0] = prevBlock[0] ^ ApplyRcon(round, SubBytes_4(Rot(prevBlock[KEY_NUM_COLS-1])));

        for (int i=1; i<=3; ++i)
            nextBlock[i] = nextBlock[i-1] ^ prevBlock[i];

        nextBlock[4] = SubBytes_4(nextBlock[3]) ^ prevBlock[4];

        for (int i=5; i<=7; ++i)
            nextBlock[i] = nextBlock[i-1] ^ prevBlock[i];

        return nextBlock;

    endfunction

`endif // `ifndef AES_256

function automatic expKeyColumn_t ApplyRcon(input integer round, expKeyColumn_t in);

    return in ^ (RCON[round] << ((KEY_COL_SIZE-1)*8));

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

