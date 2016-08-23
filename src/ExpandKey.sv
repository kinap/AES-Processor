//
// Key Expansion Module
//

import AESDefinitions::*;

// We are relying on AESEncoder/Decoder to never provide incorrect values for the params
module ExpandKey #(parameter KEY_SIZE = 128,
                   parameter NUM_ROUNDS = 10, 
                   parameter KEY_BYTES = KEY_SIZE / 8,
                   parameter type roundKeys_t = roundKey_t [0:NUM_ROUNDS], 
                   parameter type key_t = logic [0:KEY_BYTES-1])

(input key_t key, 
output roundKeys_t roundKeys);

localparam KEY_COL_SIZE = 4;
localparam byte_t [KEY_COL_SIZE-1:0] RCON[12] = '{
    'h8d, 'h01, 'h02, 'h04, 'h08, 'h10, 
    'h20, 'h40, 'h80, 'h1b, 'h36, 'h6c
};

localparam NUM_KEY_EXP_ROUNDS =
    (KEY_SIZE == 256)
        ? 8
        : (KEY_SIZE == 192)
            ? 9
            : 11;

localparam KEY_NUM_COLS = KEY_BYTES / KEY_COL_SIZE;
localparam ROUND_KEY_BITS = AES_STATE_SIZE * 8;

// The algorithm that produces the key schedule operates on blocks that are equal to the key size,
// but the round keys are always 128 bits. For 192- and 256-bit keys, the algorithm produces a key
// schedule that is 64 and 128 bits wider than the round keys necessary, respectively. This
// parameter is calculates the number of bits that the calculated key schedule needs to be shifted
// right to produce correctly-aligned keys.
// bit shift = (key width * # of expansion rounds + 1) - (round key width * # of cipher rounds +1)
localparam KEY_SCH_SHIFT = (KEY_SIZE * (NUM_KEY_EXP_ROUNDS+1)) - 
                                (ROUND_KEY_BITS * (NUM_ROUNDS+1));

typedef byte_t [0:KEY_COL_SIZE-1] expKeyColumn_t;
typedef expKeyColumn_t [0:KEY_NUM_COLS-1] expKeyBlock_t;

expKeyBlock_t [0:NUM_KEY_EXP_ROUNDS] keyBlocks;
assign roundKeys = (keyBlocks >> KEY_SCH_SHIFT);

byte_t sbox[0:255];
initial
begin
  $readmemh("./src/mem/Sbox.mem", sbox);
end

always_comb
begin

    keyBlocks[0] = key;

    for (int j=1; j<=NUM_KEY_EXP_ROUNDS; ++j)
        keyBlocks[j] = expandBlock(j, keyBlocks[j-1]);

end

// TODO
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

function automatic expKeyColumn_t Rot(input expKeyColumn_t in);

    return {in[1:KEY_COL_SIZE-1], in[0]};

endfunction

function automatic expKeyColumn_t SubBytes_4(input expKeyColumn_t in);

    expKeyColumn_t out;
    for(int i=0; i<=3; ++i)
    begin
      out[i] = sbox[(in[i][7:4]*16) + in[i][3:0]];
    end
    return out;

endfunction

endmodule

