
import AESDefinitions::*;

//
// Buffered key round. 
//
module KeyRound #(parameter KEY_SIZE = 128,
                  parameter RCON_ITER = 1,
                  parameter KEY_BYTES = KEY_SIZE / 8,
                  parameter type key_t = byte_t [0:KEY_BYTES-1])

(input logic clock, reset, input key_t in, output key_t roundKey);

    key_t out; // intermeditate value to register

    SubKeyGen #(.KEY_SIZE(KEY_SIZE)) subkey (in, out);
    Buffer #(key_t) buffer (clock, reset, out, roundKey);

endmodule

//
//   Produces one sub key of expanded key.
//   Each sub key is KEY_SIZE, which is > blocksize for 192/256.
//   We get the round key by only using blocksize of the lines for the round key.
//
module SubKeyGen #(parameter KEY_SIZE = 128,
                   parameter RCON_ITER = 1,
                   parameter KEY_BYTES = KEY_SIZE / 8,
                   parameter type key_t = byte_t [0:KEY_BYTES-1])

(input key_t prevSubKey, output key_t nextSubKey);

    int keyIdx;

    `ifdef INFER_RAM
    byte_t sbox[0:255];
    initial
    begin
      $readmemh("./src/mem/Sbox.mem", sbox);
    end
    `endif

    localparam DWORD_SIZE = 4; /* chunk schedule_core operates on in bytes */

    always_comb
    begin
        /* copy last 4B of previous block */
        nextSubKey[0:DWORD_SIZE-1] = prevSubKey[KEY_BYTES-4:KEY_BYTES-1];
        /* perform core on the 4B block */
        nextSubKey[0:DWORD_SIZE-1] = schedule_core (nextSubKey[0:DWORD_SIZE-1], RCON_ITER);
        /* XOR with first 4B */
        nextSubKey[0:DWORD_SIZE-1] ^= prevSubKey[0:DWORD_SIZE-1];

        /* generate the rest of the round key from those first 4B and the last round key */
        for (keyIdx = 4; keyIdx < KEY_BYTES; keyIdx += DWORD_SIZE)
        begin
            /* copy last generated 4B chunk to new key */
            nextSubKey[keyIdx +: DWORD_SIZE] = nextSubKey[keyIdx-DWORD_SIZE +: DWORD_SIZE];

            /* if AES_256, there is an extra sbox application */
            if ((KEY_SIZE == 256) && (keyIdx == 16))
                nextSubKey[keyIdx +: DWORD_SIZE] = sub4(nextSubKey[keyIdx +: DWORD_SIZE]);

            /* XOR with next 4B from prev key */
            nextSubKey[keyIdx +: DWORD_SIZE] ^= prevSubKey[keyIdx +: DWORD_SIZE];
        end
    end

endmodule

//***************************************************************************************
// Core functionality
//***************************************************************************************

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

