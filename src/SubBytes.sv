//
// SubBytes Layer of the AES round
//

import AESDefinitions::*;

module SubBytes(input logic validInput, state_t in,
                output state_t out);

always_comb
  begin
    // Each byte of the output is the element in the sbox LUT where the high
    // and low parts of the input byte are used as the indices of the 2D LUT
    for(int i = 0; i < 16; i++)
    begin
      out[i] = sbox[in[i][7:4]][in[i][3:0]];
    end
    `ifdef DEBUG
      $display("%m");
      $display("In: %h",in);
      $display("Out: %h", out);
    `endif
  end
endmodule

module SubBytesInverse(input logic validInput, state_t in,
                       output state_t out);

always_comb
  begin
    // Each byte of the output is the element in the inverse sbox LUT where the
    // high and low parts of the input byte are used as the indices of the 2D 
    // LUT
    for(int i = 0; i < 16; i++)
    begin
      out[i] = invSbox[in[i][7:4]][in[i][3:0]];
    end
    `ifdef DEBUG
      $display("%m");
      $display("In: %h",in);
      $display("Out: %h", out);
    `endif
  end
endmodule
