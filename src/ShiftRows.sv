//
// ShiftRows Layer of the AES round
//

include AESDefinitions.svpkg;

module ShiftRows(input state_t in, 
                 output state_t out);
always_comb
  begin
    out = { in[0], in[5], in[10], in[15], in[4], in[9], in[14], in[3],
            in[8], in[13], in[2], in[7], in[12], in[1], in[6], in[11] };
  end
endmodule

module ShiftRowsInverse(input state_t in,
                        output state_t out);
always_comb
  begin
    out = { in[0], in[13], in[10], in[7], in[4], in[1], in[14], in[11],
            in[8], in[5], in[2], in[15], in[12], in[9], in[6], in[3] };
  end
endmodule
