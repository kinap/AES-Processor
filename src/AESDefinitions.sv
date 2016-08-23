`ifndef AES_DEFINITIONS
  `define AES_DEFINITIONS

package AESDefinitions;

  // Basic definitions
  `define TRUE 1'b1
  `define FALSE 1'b0

  parameter AES_STATE_SIZE = 16;

  // Byte-oriented AES "State"
  // Byte indices 0-3 are the first column, 4-7 are the second column, etc.
  typedef logic [7:0] byte_t;
  typedef byte_t [0:AES_STATE_SIZE-1] state_t;
  typedef byte_t [0:AES_STATE_SIZE-1] roundKey_t;

endpackage : AESDefinitions

`endif // AES_DEFINITIONS

