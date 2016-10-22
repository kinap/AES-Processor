//
// Standalone testbench for top level 
//

// WARNING: super manual. used for a _quick_ visual spot check of the top
// level. Do not rely upon for serious analysis.

import AESTestDefinitions::*;

module AESCipherTestBench;

    AESTop_keysize #(.KEY_SIZE(128)) key_exp_128();   
    //AESTop_keysize #(.KEY_SIZE(192)) key_exp_192();   
    //AESTop_keysize #(.KEY_SIZE(256)) key_exp_256();   

endmodule
    
  
// 
// TB for 1 keysize at a time
//
module AESTop_keysize #(parameter KEY_SIZE = 128,
                        parameter KEY_BYTES = KEY_SIZE / 8,
                        parameter type key_t = byte_t [0:KEY_BYTES-1]);

parameter CLOCK_CYCLE = 20ns;
parameter CLOCK_WIDTH = CLOCK_CYCLE/2;
parameter IDLE_CLOCKS = 2;

// AES dut signals 
logic clock, reset;
state_t in, out;
key_t key;
logic valid;

// DUT
AESEncoder #(KEY_SIZE) dut(clock, reset, in, key, out, valid);

// Create a free running clock
initial
begin
    clock = `FALSE;
    forever #CLOCK_WIDTH clock = ~clock;
end

// Generate a reset signal for two cycles
initial
begin
    reset = `TRUE;
    repeat (IDLE_CLOCKS) @(negedge clock);
    reset = `FALSE;
end

initial
begin
$monitor("%t 
Keys --v 
| 0: %h | 1: %h | 2: %h | 3: %h \
| 4: %h | 5: %h | 6: %h | 7: %h \
| 8: %h | 9: %h | 10: %h | 11: %h \
| 12: %h | 13: %h | 14: %h
Rounds --v 
| 0: %h | 1: %h | 2: %h | 3: %h \
| 4: %h | 5: %h | 6: %h | 7: %h \
| 8: %h | 9: %h | 10: %h | 11: %h \
| 12: %h | 13: %h | 14: %h \
%d
", $time,
dut.keyExpBlock.roundKeys[0],dut.keyExpBlock.roundKeys[1],dut.keyExpBlock.roundKeys[2],dut.keyExpBlock.roundKeys[3],
dut.keyExpBlock.roundKeys[4],dut.keyExpBlock.roundKeys[5],dut.keyExpBlock.roundKeys[6],dut.keyExpBlock.roundKeys[7],
dut.keyExpBlock.roundKeys[8],dut.keyExpBlock.roundKeys[9],dut.keyExpBlock.roundKeys[10],dut.keyExpBlock.roundKeys[11],
dut.keyExpBlock.roundKeys[12],dut.keyExpBlock.roundKeys[13],dut.keyExpBlock.roundKeys[14],
dut.roundOutput[0],
dut.roundOutput[1],
dut.roundOutput[2],
dut.roundOutput[3],
dut.roundOutput[4],
dut.roundOutput[5],
dut.roundOutput[6],
dut.roundOutput[7],
dut.roundOutput[8],
dut.roundOutput[9],
dut.roundOutput[10],
dut.roundOutput[11],
dut.roundOutput[12],
dut.roundOutput[13],
dut.roundOutput[14],
valid
);
end

// test entry
initial
begin

  repeat(IDLE_CLOCKS) @(negedge clock);

  while(!valid)
  begin
    in =  128'h00112233445566778899aabbccddeeff;
    key = 128'h000102030405060708090a0b0c0d0e0f;
    repeat(1) @(negedge clock);
    in =  128'h39d6e9ae76a9b2f3fc462680f766720e;
    key = 128'h75d11b0e3a68c4223d88dbf017977dd7;
    repeat(1) @(negedge clock);
    in = 'x;
    key = 'x;
  end

  repeat(10) @(negedge clock);
  $finish();
end

endmodule

