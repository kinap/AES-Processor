//
// AddRoundKey stage of the AES round
//

`include "AESDefinitions.svpkg"

module AddRoundKey(input state_t in, roundKey_t roundKey,
                  output state_t out);
always_comb
  begin
    out = in ^ roundKey;
  end
endmodule

