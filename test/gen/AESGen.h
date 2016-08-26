#include <argp.h>

/* Defines */
#define PT_FILENAME "plain.txt"
#define CT_FILENAME "encrypted.txt"
#define KEY_FILENAME "key.txt"
#define COMBINED_FILENAME "vectors.txt"

#define BLOCKSIZE 16

/* macros */
#define CLOSE_FILE(fh) ( (fh != NULL) ? fclose(fh) : 0 )

enum aes_t {AES_128 = 0, AES_192 = 1, AES_256 = 2, AES_ALL = 3};

enum keysize_t {KEYSIZE_128 = 16, KEYSIZE_192 = 24, KEYSIZE_256 = 32, KEYSIZE_ALL = 16};

enum num_rounds_t {ROUNDS_128 = 10, ROUNDS_192 = 12, ROUNDS_256 = 14};

/* File handles */
struct file_h {
    FILE *pt_file;
    FILE *ct_file;
    FILE *key_file;
    FILE *combined_file;
} handle;

/* Cmd line ocumentation */
const char *arpg_program_version = "0.1.0";

static char doc[] =
"AESGen - Generates test vectors for AES [128|192|256]. \
If the combined flag is used, a vectors.txt will be generated containing \
<128 bit input data><256-bit key><128 cipher text><192 cipher text><256 cipher text> \
The key will be subdivided into smaller key sizes using the appropriate number of least significant bytes.";

/* Arguments and their descriptions */
static struct argp_option options[] = {
    {"variant", 'v', "KEYSIZE", 0, "AES variant. Valid options are 128, 192, 256. Default all.", 0},
    {"known_answer_test", 'k', 0, 0, "Check TomCrypt with a known answer test. Default off.", 0},
    {"num_vectors", 'n', "COUNT", 0, "Number of test vectors to generate. Default 1.", 0},
    {"combined_file_disable", 'c', 0, 0, "Plaintext, key, ciphertext printed to separate files. Default off.", 0},
    {0, 0, 0, 0, 0, 0}
};

struct arguments {
    int variant;
    int kat;
    int num_vectors;
    int combined;
};

/* Parser */
static error_t parse_opt (int key, char *arg, struct argp_state *state)
{
    struct arguments *args = state->input;

    switch(key) 
    {
        case 'v':
            args->variant = atoi(arg);
            break;
        case 'k':
            args->kat = 1;
            break;
        case 'n':
            args->num_vectors = atoi(arg);
            break;
        case 'c':
            args->combined = 0;
            break;
        default:
            return ARGP_ERR_UNKNOWN;
    }

    return 0;
}

static struct argp argp = {options, parse_opt, NULL, doc, 0, 0, 0};

