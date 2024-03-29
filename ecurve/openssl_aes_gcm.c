#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <malloc.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/aes.h>
#include <openssl/rand.h>

#define ERR_EVP_CIPHER_INIT -1
#define ERR_EVP_CIPHER_UPDATE -2
#define ERR_EVP_CIPHER_FINAL -3
#define ERR_EVP_CTX_NEW -4

#define AES_256_KEY_SIZE 32
#define AES_BLOCK_SIZE 16
#define BUFSIZE 1024
#define TAGSIZE 16

// unsigned char *tag;
unsigned char *iv;
unsigned char *key;
const EVP_CIPHER *cipher_type;
unsigned int encrypt;
// https://wiki.openssl.org/index.php/EVP_Authenticated_Encryption_and_Decryption
 
void file_encrypt_decrypt(FILE *ifp, FILE *ofp){
    /* Allow enough space in output buffer for additional block */
    int cipher_block_size = EVP_CIPHER_block_size(cipher_type);
    unsigned char in_buf[BUFSIZE], out_buf[BUFSIZE + cipher_block_size];
    unsigned char tmp_buf[BUFSIZE];
    unsigned char tmp_tag[TAGSIZE];	
    int num_bytes_read, out_len;
    int offset, num_bytes;
    int i;
    EVP_CIPHER_CTX *ctx;
    ctx = EVP_CIPHER_CTX_new();
    if(ctx == NULL){
        fprintf(stderr, "ERROR: EVP_CIPHER_CTX_new failed. OpenSSL error: %s\n", 
                ERR_error_string(ERR_get_error(), NULL));
    }

    /* Don't set key or IV right away; we want to check lengths */
    if(!EVP_CipherInit_ex(ctx, cipher_type, NULL, NULL, NULL, encrypt)){
        fprintf(stderr, "ERROR: EVP_CipherInit_ex failed. OpenSSL error: %s\n", 
                ERR_error_string(ERR_get_error(), NULL));
    }
    if(!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, 12, NULL)) {
        printf("Error setting IV - len"); 
     }


    /* Now we can set key and IV */
    if(!EVP_CipherInit_ex(ctx, NULL, NULL, key, iv, encrypt)){
        fprintf(stderr, "ERROR: EVP_CipherInit_ex failed. OpenSSL error: %s\n", 
                ERR_error_string(ERR_get_error(), NULL));
        EVP_CIPHER_CTX_cleanup(ctx);
    }

    offset=0;    
    while(1){
        // Read in data in blocks until EOF. Update the ciphering with each read.
        num_bytes_read = fread(in_buf, sizeof(unsigned char), BUFSIZE, ifp);
        if (ferror(ifp)){
            fprintf(stderr, "ERROR: fread error: %s\n", strerror(errno));
            EVP_CIPHER_CTX_cleanup(ctx);
        }
	if (encrypt) {
	   memcpy(tmp_buf, in_buf, num_bytes_read);
	   num_bytes=num_bytes_read;
        }
	else {
	   if (offset) {
	      memcpy(tmp_buf, tmp_tag, offset);
		for (int i=0; i < offset; i++)
			printf("%#x ", tmp_tag[i]);	
		
           }
	   memcpy(tmp_buf + offset, in_buf, num_bytes_read - TAGSIZE);
	   memcpy(tmp_tag, in_buf + num_bytes_read - TAGSIZE, TAGSIZE);
	   num_bytes=num_bytes_read - TAGSIZE;
	   offset=TAGSIZE;
        }

        if(!EVP_CipherUpdate(ctx, out_buf, &out_len, in_buf, num_bytes)){
            fprintf(stderr, "ERROR: EVP_CipherUpdate failed. OpenSSL error: %s\n", 
                    ERR_error_string(ERR_get_error(), NULL));
            EVP_CIPHER_CTX_cleanup(ctx);
        }
	printf("Writing %d bytes\n", out_len);
        fwrite(out_buf, sizeof(unsigned char), out_len, ofp);
        if (ferror(ofp)) {
            fprintf(stderr, "ERROR: fwrite error: %s\n", strerror(errno));
            EVP_CIPHER_CTX_cleanup(ctx);
        }
        if (num_bytes_read < BUFSIZE) {
            /* Reached End of file */
            break;
        }
    }

    if (encrypt==0) { // decrypt
	  if(!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, TAGSIZE, tmp_tag)) {
              fprintf(stderr, "ERROR: EVP_CIPHER_CTX_ctrl, GCM_SET_TAG failed. OpenSSL error: %s\n", 
                	ERR_error_string(ERR_get_error(), NULL));

	      EVP_CIPHER_CTX_cleanup(ctx);
          }
     }

    /* Now cipher the final block and write it out to file */
    if(!EVP_CipherFinal_ex(ctx, out_buf, &out_len)){
        fprintf(stderr, "ERROR: EVP_CipherFinal_ex failed. OpenSSL error: %s\n", 
                ERR_error_string(ERR_get_error(), NULL));
        EVP_CIPHER_CTX_cleanup(ctx);
    }
    fwrite(out_buf, sizeof(unsigned char), out_len, ofp);
    if (ferror(ofp)) {
        fprintf(stderr, "ERROR: fwrite error: %s\n", strerror(errno));
        EVP_CIPHER_CTX_cleanup(ctx);
    }
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_GET_TAG, 16, out_buf);
    /* Output tag */
    if (encrypt==1) {
 	   fwrite(out_buf, sizeof(unsigned char), 16, ofp);
    }
    EVP_CIPHER_CTX_cleanup(ctx);
}


int main(int argc, char *argv[]) {
    FILE *f_input, *f_enc, *f_dec;
	
    /* Make sure user provides all input  */
    if (argc < 6) {
        printf("Usage: %s /path/to/inputfile /path/to/outputfile key iv enc\n", argv[0]);
	printf("enc=e means encrypt d=decrypt");
        return -1;
    }
    long l;    
    key= OPENSSL_hexstr2buf(argv[3], &l);
    iv= OPENSSL_hexstr2buf(argv[4], &l);
    encrypt = 0;

    if (strcmp(argv[5], "e") == 0) {
	encrypt=1;
	printf("mode encrypt\n");
    }
    cipher_type = EVP_aes_256_gcm();

    /* Open the input file for reading in binary ("rb" mode) */
    f_input = fopen(argv[1], "rb");
    if (!f_input) {
        /* Unable to open file for reading */
        fprintf(stderr, "ERROR: fopen error: %s\n", strerror(errno));
        return errno;
    }

    /* Open and truncate file to zero length or create ciphertext file for writing */
    f_enc = fopen(argv[2], "wb");
    if (!f_enc) {
        /* Unable to open file for writing */
        fprintf(stderr, "ERROR: fopen error: %s\n", strerror(errno));
        return errno;
    }
    printf("Doing %s infile:%s outfile:%s key:%s iv:%s\n", argv[5], argv[1], argv[2], argv[3], argv[4]);
    /* Encrypt the given file */
    file_encrypt_decrypt(f_input, f_enc);

    /* Encryption done, close the file descriptors */
    fclose(f_input);
    fclose(f_enc);
   

    return 0;
}
