//
// Saturating down counter, timeUp is asserted NUM_ROUNDS after reset.
//

import AESDefinitions::*;

// Reset value is equal to the number of rounds
module Counter #(RESET_VAL = 10)
                (input clock, reset,
                output logic timeUp);

localparam WIDTH = 8;

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
