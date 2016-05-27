//
// Generic buffer
// Use a type parameter when the Buffer is instantated to set how wide the
// input and output data paths are
//

module Buffer #(parameter type bType = logic) (input logic clock, reset, bType in, output bType out);

  always_ff @(posedge clock)
    begin
    // Transfer the input to the output unless is asserted
    if(reset)
      out <= 0;
    else
      out <= in;
    end

endmodule
