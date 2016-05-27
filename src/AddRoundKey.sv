//
// AddRoundKey stage of the AES round
//

import AESDefinitions::*;

module AddRoundKey(input state_t in, roundKey_t roundKey,
                  output state_t out);
always_comb
  begin
    // The output is simply the input bitwise-xor'd with the round key
    out = in ^ roundKey;
    `ifdef DEBUG
      $display("%m");
      $display("In: %h", in);
      $display("Round Key: %h", roundKey);
      $display("Out: %h", out);
    `endif 
  end
endmodule

