//
// MixColumns stage of the AES round
// Reference: https://en.wikipedia.org/wiki/Rijndael_mix_columns
//

import AESDefinitions::*;

import GaloisFieldFunctions::*;

//
// Matrix used to perform matrix multiplication in GF(2^8):
// (2  3  1  1)
// (1  2  3  1)
// (1  1  2  3)
// (3  1  1  2)
//
module MixColumns(input state_t in, 
                 output state_t out);

always_comb
  begin

    for (int i = 0; i < AES_STATE_SIZE; i = i+4)
      begin

        out[i+0] = GfMult2Lut(in[i+0]) ^ GfMult3Lut(in[i+1]) ^ in[i+2]             ^ in[i+3];
        out[i+1] = in[i+0]             ^ GfMult2Lut(in[i+1]) ^ GfMult3Lut(in[i+2]) ^ in[i+3];
        out[i+2] = in[i+0]             ^ in[i+1]             ^ GfMult2Lut(in[i+2]) ^ GfMult3Lut(in[i+3]);
        out[i+3] = GfMult3Lut(in[i+0]) ^ in[i+1]             ^ in[i+2]             ^ GfMult2Lut(in[i+3]);
      end
  `ifdef DEBUG
    $display("%m");
    $display("In: %h", in);
    $display("Out: %h", out);
  `endif
  end
endmodule

//
// Inverse matrix used to perform matrix multiplication in GF(2^8):
// (14  11  13   9)
// (9   14  11  13)
// (13  9   14  11)
// (11  13  9   14)
//
module MixColumnsInverse(input state_t in,
                        output state_t out);

always_comb
  begin

    for (int i = 0; i < AES_STATE_SIZE; i = i+4)
      begin
        out[i+0] = GfMult14Lut(in[i+0]) ^ GfMult11Lut(in[i+1]) ^ GfMult13Lut(in[i+2]) ^  GfMult9Lut(in[i+3]);
        out[i+1] =  GfMult9Lut(in[i+0]) ^ GfMult14Lut(in[i+1]) ^ GfMult11Lut(in[i+2]) ^ GfMult13Lut(in[i+3]);
        out[i+2] = GfMult13Lut(in[i+0]) ^  GfMult9Lut(in[i+1]) ^ GfMult14Lut(in[i+2]) ^ GfMult11Lut(in[i+3]);
        out[i+3] = GfMult11Lut(in[i+0]) ^ GfMult13Lut(in[i+1]) ^  GfMult9Lut(in[i+2]) ^ GfMult14Lut(in[i+3]);
      end
  `ifdef DEBUG
    $display("%m");
    $display("In: %h", in);
    $display("Out: %h", out);
  `endif
  end
endmodule
