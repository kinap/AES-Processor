#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <tomcrypt.h>
#include "AESGen.h"

//
// Utilities
//
void open_files(int combined_file, struct file_h *handle)
{
    if (combined_file) {
        handle->combined_file = fopen(COMBINED_FILENAME, "wb");
        handle->pt_file = NULL;
        handle->ct_file = NULL;
        handle->key_file = NULL;
    } else {
        handle->combined_file = NULL; 
        handle->pt_file = fopen(PT_FILENAME, "wb");
        handle->ct_file = fopen(CT_FILENAME, "wb");
        handle->key_file = fopen(KEY_FILENAME, "wb");
    }
}

void close_files(struct file_h *handle)
{
    CLOSE_FILE(handle->pt_file);
    CLOSE_FILE(handle->ct_file);
    CLOSE_FILE(handle->key_file);
    CLOSE_FILE(handle->combined_file);
}

void print_block(unsigned char *arr, int len)
{
    int i;
    for (i = 0; i < len; i++) 
        printf("%x ", arr[i]);
    printf("\n");
}

//
// Known Answer Test. Verifies that the libtomcrypt sequence produces correct results.
// 
int kat(int key_size, int num_rounds)
{
    /* INCON AES ECB test vector(s) 1 */
    unsigned char pt[BLOCKSIZE] = {0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96, 0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a};
    //unsigned char et128[BLOCKSIZE] = {0xf3, 0xee, 0xd1, 0xbd, 0xb5, 0xd2, 0xa0, 0x3c, 0x06, 0x4b, 0x5a, 0x7e, 0x3d, 0xb1, 0x81, 0xf8};
    //unsigned char et192[BLOCKSIZE] = {0xbd, 0x33, 0x4f, 0x1d, 0x6e, 0x45, 0xf2, 0x5f, 0xf7, 0x12, 0xa2, 0x14, 0x57, 0x1f, 0xa5, 0xcc};
    //unsigned char et256[BLOCKSIZE] = {0x3a, 0xd7, 0x7b, 0xb4, 0x0d, 0x7a, 0x36, 0x60, 0xa8, 0x9e, 0xca, 0xf3, 0x24, 0x66, 0xef, 0x97};
    unsigned char key256[32] = {0x60, 0x3d, 0xeb, 0x10, 0x15, 0xca, 0x71, 0xbe, 0x2b, 0x73, 0xae, 0xf0, 0x85, 0x7d, 0x77, 0x81, 
                                0x1f, 0x35, 0x2c, 0x07, 0x3b, 0x61, 0x08, 0xd7, 0x2d, 0x98, 0x10, 0xa3, 0x09, 0x14, 0xdf, 0xf4};
    unsigned char key192[24] = {0x8e, 0x73, 0xb0, 0xf7, 0xda, 0x0e, 0x64, 0x52, 0xc8, 0x10, 0xf3, 0x2b, 0x80, 0x90, 0x79, 0xe5, 
                                0x62, 0xf8, 0xea, 0xd2, 0x52, 0x2c, 0x6b, 0x7b};
    unsigned char key128[16] = {0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c};

    unsigned char ct[BLOCKSIZE];
    unsigned char ptm[BLOCKSIZE];
    symmetric_key skey; // scheduled key

    unsigned char *key;
    if (key_size == KEYSIZE_128)
        key = key128;
    else if (key_size == KEYSIZE_192)
        key = key192;
    else
        key = key256;

    printf("Running known answer test for keysize %dB\n", key_size);

    /* setup variant */
    aes_setup(key, key_size, num_rounds, &skey);

    /* encrypt plaintext */
    aes_ecb_encrypt(pt, ct, &skey);

    // FIXME getting seg faults whenever mem* are used (memcmp, memset, etc).
    // gdb shows the automatic arrays above are overlapping? wtf?
    /* compare with expected */
    //if (memcmp(et, ct, sizeof et)) {
    //    printf("Expected does not match actual.\n");
    //    return EXIT_FAILURE;
    //} else {
    //    printf("Expected matches actual.\n");
    //}

    /* decypt ciphertext */
    aes_ecb_decrypt(ct, ptm, &skey);

    /* make sure decryption worked */
    //if (memcmp(pt, ptm, sizeof(pt))) {
    //    printf("Expected does not match actual.\n");
    //    return EXIT_FAILURE;
    //} else {
    //    printf("Expected matches actual.\n");
    //}

    /* done, clear key schedule */
    aes_done(&skey);

    return EXIT_SUCCESS;
}

//
// Generates a random plaintext of BLOCKSIZE, a random key of key_size, and an associated ciphertext.
// Outputs to correct files
//
int generate_vector(struct file_h *handle, prng_state *prng, int key_size, int num_rounds, int combined)
{
    int i;
    symmetric_key skey; // scheduled key

    if (!combined) {
        unsigned char pt[BLOCKSIZE];
        unsigned char ct[BLOCKSIZE];
        unsigned char key[key_size];

        /* Generate random data */
        yarrow_read(pt, sizeof(pt), prng);
        yarrow_read(key, sizeof(key), prng);

        /* setup variant */
        aes_setup(key, key_size, num_rounds, &skey);

        /* encrypt plaintext */
        aes_ecb_encrypt(pt, ct, &skey);

        /* done, clear key schedule */
        aes_done(&skey);

        /* write our data to file */
        for (i = 0; i < BLOCKSIZE; i ++) 
            fprintf(handle->pt_file, "%02x", pt[i]);
        fputc(0xa, handle->pt_file);

        for (i = 0; i < BLOCKSIZE; i ++) 
            fprintf(handle->ct_file, "%02x", ct[i]);
        fputc(0xa, handle->ct_file);

        for (i = 0; i < key_size; i ++) 
            fprintf(handle->key_file, "%02x", key[i]);
        fputc(0xa, handle->key_file);

    } else {

        unsigned char pt128[BLOCKSIZE];

        unsigned char ct128[BLOCKSIZE];
        unsigned char ct192[BLOCKSIZE];
        unsigned char ct256[BLOCKSIZE];

        /* smaller keys are substrings of the 256 key */
        unsigned char key256[KEYSIZE_256];

        /* Generate random data */
        yarrow_read(pt128, sizeof(pt128), prng);
        yarrow_read(key256, sizeof(key256), prng);

        /************************************/

        // 256
        aes_setup(key256, KEYSIZE_256, ROUNDS_256, &skey);
        aes_ecb_encrypt(pt128, ct256, &skey);
        aes_done(&skey);

        // 192 
        aes_setup(key256, KEYSIZE_192, ROUNDS_192, &skey);
        aes_ecb_encrypt(pt128, ct192, &skey);
        aes_done(&skey);

        // 128
        aes_setup(key256, KEYSIZE_128, ROUNDS_128, &skey);
        aes_ecb_encrypt(pt128, ct128, &skey);
        aes_done(&skey);

        /************************************/
        /* write our data to file           */

        /* plaintext */
        for (i = 0; i < BLOCKSIZE; i++) 
            fprintf(handle->combined_file, "%02x", pt128[i]);
        fputc(0x20, handle->combined_file); // space character

        /* 256-bit key */
        for (i = 0; i < KEYSIZE_256; i++) 
            fprintf(handle->combined_file, "%02x", key256[i]);
        fputc(0x20, handle->combined_file); // space character

        /* separate ciphertexts */
        for (i = 0; i < BLOCKSIZE; i++) 
            fprintf(handle->combined_file, "%02x", ct128[i]);
        fputc(0x20, handle->combined_file); // space character

        for (i = 0; i < BLOCKSIZE; i++) 
            fprintf(handle->combined_file, "%02x", ct192[i]);
        fputc(0x20, handle->combined_file); // space character

        for (i = 0; i < BLOCKSIZE; i++) 
            fprintf(handle->combined_file, "%02x", ct256[i]);
        fputc(0x20, handle->combined_file); // space character
        fputc(0xa, handle->combined_file); // newline


    }

    return EXIT_SUCCESS;
}

//
// Generator entry
// 
int main(int argc, char **argv)
{
    int i;
    int key_size, num_rounds;
    struct file_h handle;
    prng_state prng;

    struct arguments args;

    /* Default arg values */
    args.kat = 0;
    args.num_vectors = 1;
    args.variant = AES_128;
    args.combined = 1;

    argp_parse(&argp, argc, argv, 0, 0, &args);

    /* register AES */
    if (register_cipher(&aes_desc)) {
        printf("Error registering AES.\n");
        return EXIT_FAILURE;
    }

    /* start psuedo random number generator */
    if (yarrow_start(&prng) != CRYPT_OK) {
        printf("Error starting PRNG.\n");
        return EXIT_FAILURE;
    }

    if (yarrow_ready(&prng) != CRYPT_OK) {
        printf("Error readying.\n");
        return EXIT_FAILURE;
    }

    /* select keysize */
    if (args.combined) {
        // nop
    } else if (args.variant == AES_256) {
        key_size = KEYSIZE_256;
        num_rounds = ROUNDS_256;
    } else if (args.variant == AES_192) {
        key_size = KEYSIZE_192;
        num_rounds = ROUNDS_192;
    } else { // if (args.variant == AES_128) { 
        key_size = KEYSIZE_128;
        num_rounds = ROUNDS_128;
    }

    /* generate test vectors */
    if (args.kat) {
        kat(key_size, num_rounds);
    } else {
        open_files(args.combined, &handle);
        for (i = 0; i < args.num_vectors; i++) 
            // TODO segault - compile with tomfastmath?
            //if (yarrow_add_entropy(seed, sizeof(seed), &prng) != CRYPT_OK) {
            //    printf("Error adding entropy.\n");
            //    return EXIT_FAILURE;
            //}
            generate_vector(&handle, &prng, key_size, num_rounds, args.combined);
        close_files(&handle);
    }

    /* unregister AES */
    if (unregister_cipher(&aes_desc)) {
        printf("Error removing AES.\n");
        return EXIT_FAILURE;
    }

    yarrow_done(&prng);

    return EXIT_SUCCESS;
}

