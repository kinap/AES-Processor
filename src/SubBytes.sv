//
// SubBytes Layer of the AES round
//

import AESDefinitions::*;

// TODO: Parameterize the substitution width for this module
module SubBytes(input state_t in,
                output state_t out);

always_comb
  begin
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

module SubBytesInverse(input state_t in,
                       output state_t out);

always_comb
  begin
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
