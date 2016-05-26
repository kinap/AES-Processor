#include <argp.h>

/* Defines */
#define PT_FILENAME "plain.txt"
#define CT_FILENAME "encrypted.txt"
#define KEY_FILENAME "key.txt"

#define BLOCKSIZE 16
#define KEYSIZE_256 32
#define KEYSIZE_192 24
#define KEYSIZE_128 16

enum aes_t {AES_128 = 0, AES_192 = 1, AES_256 = 2};

/* File handles */
struct file_h {
    FILE *pt_file;
    FILE *ct_file;
    FILE *key_file;
} handle;

/* Cmd line ocumentation */
const char *arpg_program_version = "0.1.0";

static char doc[] =
    "AESGen - Generates test vectors for AES [128|192|256].";

/* Arguments and their descriptions */
static struct argp_option options[] = {
    {"variant", 'v', "KEYSIZE", 0, "AES variant. Valid options are 128, 192, 256", 0},
    {"known_answer_test", 'k', 0, 0, "Check TomCrypt with a known answer test", 0},
    {"num_vectors", 'n', "COUNT", 0, "Number of test vectors to generate", 0},
    {0, 0, 0, 0, 0, 0}
};

struct arguments {
    int variant;
    int kat;
    int num_vectors;
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
        default:
            return ARGP_ERR_UNKNOWN;
    }

    return 0;
}

static struct argp argp = {options, parse_opt, NULL, doc, 0, 0, 0};

