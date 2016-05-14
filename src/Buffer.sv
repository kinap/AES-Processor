//
// Generic buffer
//

module Buffer #(parameter type bType = logic) (input logic clock, reset, bType in, output bType out);

  always_ff @(posedge clock)
    begin
    if(reset)
      out <= 0;
    else
      out <= in;
    end

endmodule
