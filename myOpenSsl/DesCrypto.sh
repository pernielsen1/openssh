#!/bin/bash
# https://sandilands.info/sgordon/simple-introduction-to-using-openssl-on-command-line
# penssl list-cipher-commands
Key="0123456789abcdeffedcba9876543210"
IV="0000000000000000"
Plain="Hello World"
echo -n $Plain>plain.txt
xxd plain.txt
# Encrypts it obs it will be PKCS7 - padded hello world is 11 so padding char will be hex 05
openssl enc -des-ede-cbc -in plain.txt -out ciphertext.bin -K $Key -iv $IV
xxd  ciphertext.bin
openssl enc -des-ede-cbc -d -in ciphertext.bin -out plain2.txt -K $Key -iv $IV
xxd  plain2.txt
# See the padding char
openssl enc -des-ede-cbc -d -in ciphertext.bin -out plain3.txt -K $Key -iv $IV -nopad
xxd plain3.txt
# ECB example vs CBC  no padding
Plain="1234567812345678"
echo -n $Plain>plain.txt
echo Repeated pattern Encrypted with CBC and no padding
openssl enc -des-ede-cbc  -in plain.txt -out ciphertext_cbc.bin -K $Key -iv $IV -nopad
xxd ciphertext_cbc.bin
echo Repeated pattern Encrypted with ECB and no padding note patterns is repeated in cipher text
openssl enc -des-ede  -in plain.txt -out ciphertext_ecb.bin -K $Key  -nopad
xxd ciphertext_ecb.bin
echo Repeated pattern decrypted again from CBC and ECB 
openssl enc -des-ede-cbc -d -in ciphertext_cbc.bin -out plain2.txt -K $Key -iv $IV -nopad
xxd  plain2.txt
openssl enc -des-ede  -d -in ciphertext_ecb.bin -out plain3.txt -K $Key  -nopad
xxd  plain3.txt
