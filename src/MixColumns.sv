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

`ifdef INFER_RAM

byte_t GfMultLut2[0:255];
byte_t GfMultLut3[0:255];

initial
begin
  $readmemh("./src/mem/GfMult2Lut.mem", GfMultLut2);
  $readmemh("./src/mem/GfMult3Lut.mem", GfMultLut3);
end
`endif

// Multiplication functions used in Rijndael
function automatic byte_t GfMult2Lut(input byte_t a);
  return GfMultLut2[a];
endfunction

function automatic byte_t GfMult3Lut(input byte_t a);
  return GfMultLut3[a];
endfunction

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

`ifdef INFER_RAM

byte_t GfMultLut9[0:255];
byte_t GfMultLut11[0:255];
byte_t GfMultLut13[0:255];
byte_t GfMultLut14[0:255];

initial
begin
 $readmemh("./src/mem/GfMult9Lut.mem", GfMultLut9);
 $readmemh("./src/mem/GfMult11Lut.mem", GfMultLut11);
 $readmemh("./src/mem/GfMult13Lut.mem", GfMultLut13);
 $readmemh("./src/mem/GfMult14Lut.mem", GfMultLut14);
end
`endif

function automatic byte_t GfMult9Lut(input byte_t a);
  return GfMultLut9[a];
endfunction

function automatic byte_t GfMult11Lut(input byte_t a);
  return GfMultLut11[a];
endfunction

function automatic byte_t GfMult13Lut(input byte_t a);
  return GfMultLut13[a];
endfunction

function automatic byte_t GfMult14Lut(input byte_t a);
  return GfMultLut14[a];
endfunction

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
