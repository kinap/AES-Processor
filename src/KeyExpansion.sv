
import AESDefinitions::*;

//
// Pipelined key expansion module. Provides a new key when a round needs it.
//
module KeyExpansion #(parameter KEY_SIZE = 128,
                      parameter KEY_BYTES = KEY_SIZE / 8,
                      parameter NUM_ROUNDS = (KEY_SIZE == 256) ? 14 : (KEY_SIZE == 192) ? 12 : 10,
                      parameter type key_t = byte_t [0:KEY_BYTES-1])

(input logic clock, reset, key_t key, output roundKey_t [NUM_ROUNDS+1] roundKeys);

    key_t subKey[NUM_ROUNDS+1];

    // truncate input key and use for first round
    assign subKey[0] = key;
    assign roundKeys[0] = key[0:AES_STATE_SIZE-1];
    // No buffering first round
    //Buffer #(roundKey_t) firstRound (clock, reset, key[0:AES_STATE_SIZE-1], roundKeys[0]);

    // all other rounds require processing
    genvar i;
    for (i = 1; i <= NUM_ROUNDS; i++)
    begin
      KeyRound #(.KEY_SIZE(KEY_SIZE), .ROUND(i)) KeyRound(clock, reset, subKey[i-1], subKey[i], roundKeys[i]);
    end


endmodule

//
// Buffered key round 
//
module KeyRound #(parameter KEY_SIZE = 128,
                  parameter ROUND = 1,
                  parameter KEY_BYTES = KEY_SIZE / 8,
                  parameter type key_t = byte_t [0:KEY_BYTES-1])

(input logic clock, reset, input key_t in, output key_t subKeyRound, roundKey_t roundKey);

    int keySelect, rcon, rconAdjust;

    key_t out, tmpSubKey; 
    roundKey_t tmp; // intermeditate value to register

    SubKeyGen #(.KEY_SIZE(KEY_SIZE)) subkey(in, rcon, out);
    Buffer #(key_t) bufferSubKey(clock, reset, tmpSubKey, subKeyRound); // for internal key exp module
    Buffer #(roundKey_t) bufferRoundKey(clock, reset, tmp, roundKey); // for round clients

    // shift subkey if 192 or 256
    // We get the round key by only using blocksize of the lines for the round key.
    always_comb
    begin
        rcon = ROUND;
        tmpSubKey = out;

        if (KEY_SIZE == 128)
            tmp = out;
        else if (KEY_SIZE == 192)
        begin
            keySelect = ROUND % 3;
            rconAdjust = ROUND / 3;
            rcon = rcon - rconAdjust;

            if (keySelect == 1)
                tmp = {in[KEY_BYTES-8 +: 8], out[0 +: 8]};
            else if (keySelect == 2) 
                tmp = in[KEY_BYTES-16 +: 16];
            else
            begin
                tmp = in[0 +: 16];
                tmpSubKey = in; // every 3 rounds, insert bubble since we're about to exceed our history buffer of 1*KEY_SIZE
            end
        end
        else if (KEY_SIZE == 256)
        begin
            keySelect = ROUND % 2;
            rconAdjust = ROUND / 2;
            rcon = rcon - rconAdjust;

            if (keySelect)
            begin
                tmp = in[KEY_BYTES-16 +: 16];
                tmpSubKey = in; // every 2 rounds, insert bubble since we're about to exceed our history buffer of 1*KEY_SIZE
            end
            else
                tmp = out[0 +: 16];
        end
    end

endmodule


//***************************************************************************************
// Core functionality
//***************************************************************************************

//
//   Produces one sub key of expanded key. Each sub key is KEY_SIZE, which is > blocksize for 192/256.
//
module SubKeyGen #(parameter KEY_SIZE = 128,
                   parameter KEY_BYTES = KEY_SIZE / 8,
                   parameter type key_t = byte_t [0:KEY_BYTES-1])

(input key_t prevSubKey, int rcon_iter, output key_t nextSubKey);

    int keyIdx;
    dword_t tmp;

    `ifdef INFER_RAM
    byte_t sbox[0:255];
    initial
    begin
      $readmemh("./src/mem/Sbox.mem", sbox);
    end
    `endif

    always_comb
    begin
        /* copy last 4B of previous block */
        nextSubKey[0:3] = prevSubKey[KEY_BYTES-4:KEY_BYTES-1];
        /* perform core on the 4B block */
        // WA for veloce compiler... doesn't like nextSubKey[0:3] being passed to the function and being updated by it
        tmp = nextSubKey[0:3]; 
        nextSubKey[0:3] = schedule_core (tmp, rcon_iter);
        /* XOR with first 4B */
        nextSubKey[0:3] ^= prevSubKey[0:3];

        /* generate the rest of the round key from those first 4B and the last round key */
        for (keyIdx = 4; keyIdx < KEY_BYTES; keyIdx += 4)
        begin
            /* copy last generated 4B chunk to new key */
            nextSubKey[keyIdx +: 4] = nextSubKey[keyIdx-4 +: 4];

            /* if AES_256, there is an extra sbox application */
            if ((KEY_SIZE == 256) && (keyIdx == 16))
                nextSubKey[keyIdx +: 4] = sub4(nextSubKey[keyIdx +: 4]);

            /* XOR with next 4B from prev key */
            nextSubKey[keyIdx +: 4] ^= prevSubKey[keyIdx +: 4];
        end
    end

endmodule

//
//   Inner loop of key expansion. Peformed once during each key expansion round
//
function automatic dword_t schedule_core(input dword_t in, integer round);

    dword_t out;

    out = rot4(in);
    out = sub4(out);
    out[0] ^= rcon(round);

    return out;
        
endfunction

//
//   Rotates a 4 byte word 8 bits to the left
//
function automatic dword_t rot4 (input dword_t in);

    return {in[1], in[2], in[3], in[0]};

endfunction

//
//   Applies the sbox to a 4 byte word 
//
function automatic dword_t sub4(input dword_t in);

    dword_t out;
    for(int i=0; i<=3; ++i)
    begin
      `ifdef INFER_RAM
      out[i] = sbox[(in[i][7:4]*16) + in[i][3:0]];
      `else
      out[i] = sbox[in[i][7:4]][in[i][3:0]];
      `endif
    end
    return out;

endfunction

//
//   Applies the rcon function to a byte 
//
function automatic byte_t rcon(input integer round);

    byte_t RCON[12] = '{'h8d, 'h01, 'h02, 'h04, 'h08, 'h10, 
                        'h20, 'h40, 'h80, 'h1b, 'h36, 'h6c};
    return (RCON[round]);

endfunction

