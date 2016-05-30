`ifndef AES_DEFINITIONS
  `define AES_DEFINITIONS

package AESDefinitions;
  // Set key size based on define
  `ifdef AES_256
    `define KEY_SIZE 256
    `define NUM_ROUNDS 14
  `elsif AES_192
    `define KEY_SIZE 192
    `define NUM_ROUNDS 12
  `else
    `define KEY_SIZE 128
    `define NUM_ROUNDS 10
  `endif

  // Basic definitions
  `define TRUE 1'b1
  `define FALSE 1'b0

  //
  // Types and sizes for AES
  //
  parameter AES_STATE_SIZE = 16;
  parameter KEY_BYTES = `KEY_SIZE / 8;

  // Byte-oriented AES "State"
  // Byte indices 0-3 are the first column, 4-7 are the second column, etc.
  typedef logic [7:0] byte_t;
  typedef byte_t [0:AES_STATE_SIZE-1] state_t;

  typedef byte_t [0:KEY_BYTES-1] key_t;
  typedef byte_t [0:AES_STATE_SIZE-1] roundKey_t;
  typedef roundKey_t [0:`NUM_ROUNDS] roundKeys_t;

endpackage : AESDefinitions

`endif // AES_DEFINITIONS

