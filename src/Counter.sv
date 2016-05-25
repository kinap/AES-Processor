//
// Saturating down counter, timeUp is asserted NUM_ROUNDS after reset.
//

import AESDefinitions::*;

module Counter #(parameter WIDTH = 8, RESET_VAL = `NUM_ROUNDS)
                (input clock, reset,
                output logic timeUp);

logic [WIDTH-1:0] count;

always_ff @(posedge clock) 
  begin
    timeUp <= 0;
    if (reset)
      count <= RESET_VAL;
    else 
      begin
        if (count == 0)
          begin
            count <= '0;
            timeUp <= 1;
          end
        else
          count <= count - 1;
      end
  end
endmodule
