//
// MixColumns stage of the AES round
// See AESDefinitions package for more details on the arithmetic.
// Reference: https://en.wikipedia.org/wiki/Rijndael_mix_columns
//
// FIXME - Dan - I feel like part of this isn't synthesizable?

include AESDefinitions.svpkg;
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
    for (int i = 0; i < 4; i++)
      begin
        out[i + 0]  = GfMultBy2(in[i+0]) ^ GfMultBy3(in[i+1]) ^ in[i+2] ^ in[i+3];
        out[i + 4]  = in[i+0] ^ GfMultBy2(in[i+1]) ^ GfMultBy3(in[i+2]) ^ in[i+3];
        out[i + 8]  = in[i+0] ^ in[i+1] ^ GfMultBy2(in[i+2]) ^ GfMultBy3(in[i+3]);
        out[i + 12] = GfMultBy3(in[i+0]) ^ in[i+1] ^ in[i+2] ^ GfMultBy2(in[i+3]);
      end
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
    for (int i = 0; i < 4; i++)
      begin
        out[i + 0]  = GfMultBy14(in[i+0]) ^ GfMultBy11(in[i+1]) ^ GfMultBy13(in[i+2]) ^ GfMultBy9(in[i+3]);
        out[i + 0]  = GfMultBy9(in[i+0]) ^ GfMultBy14(in[i+1]) ^ GfMultBy11(in[i+2]) ^ GfMultBy13(in[i+3]);
        out[i + 0]  = GfMultBy13(in[i+0]) ^ GfMultBy9(in[i+1]) ^ GfMultBy14(in[i+2]) ^ GfMultBy11(in[i+3]);
        out[i + 0]  = GfMultBy11(in[i+0]) ^ GfMultBy13(in[i+1]) ^ GfMultBy9(in[i+2]) ^ GfMultBy14(in[i+3]);
      end
  end
endmodule
