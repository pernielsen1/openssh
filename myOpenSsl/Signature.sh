#!/bin/bash
refresult="c3ab8ff13720e8ad9047dd39466b3c8974e592c2fa383d4a3960714caef0c4f2"
Text="foobar"
echo  -n $Text > plain.txt
openssl dgst -sha256 -binary -out plain.hash plain.txt 
echo  "refresult is:" 
echo $refresult
echo  "plain.hash:"
xxd -p  plain.hash
#  calculate hash and sign in one go
openssl dgst -sha256 -sign rootkey.pem -out signature.bin plain.txt 
echo "signature.bin"
xxd -p signature.bin
#  recover the signature 
openssl rsautl -verify -pubin -inkey rootkey.pub -keyform PEM -in signature.bin  -raw -out signature.recover.bin
echo "signature.recover.bin"  
xxd -p signature.recover.bin
echo "verifying the signature"
openssl dgst -sha256 -sigopt rsa_padding_mode:pkcs1 -verify rootkey.pub -signature signature.bin plain.txt
 




