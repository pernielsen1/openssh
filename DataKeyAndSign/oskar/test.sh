#!/bin/bash
# clssic example a public key is received a one time AES key generated and encrypted using public key wiht OAEP t
# he payload data was encrypted with the AEs key CBC mode with standard padding pkcs1
#
# Input fles:
# key.base64 = The encrypted AES key OAEP formatted in base64 encoding
# iv-base64 = The IV in base64 encoding
¤ 
¤ Cleanup 
rm *.bin
# decrypt the AES key using OAEP first convert base64 to binary
cat key.base64|openssl enc -base64 -d>key.bin
openssl pkeyutl -decrypt -in key.bin -out key.clear  -inkey seb_test_key.pem -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -pkeyopt rsa_mgf1_md:sha256
# convert the decrypted key to hex string and the base64 passed IV to hex string
aesKey=$(xxd -p key.clear | tr -d '\n')
cat iv.base64|openssl enc -base64 -d>iv.bin
iv=$(xxd -p iv.bin | tr -d '\n')

echo  "key is:" $aesKey " iv:" $iv
cat cipher.base64|openssl enc -base64 -d>cipher.bin
# Decrypt with aes 
openssl enc -d -aes-256-cbc  -in cipher.bin -K $aesKey 	-iv $iv -out  plain.txt
cat plain.txt


