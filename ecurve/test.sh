#!/bin/bash
function binFileToHexString() {
   xxd  -p $1| tr -d '\n'
}

function hexStringToBin() {
   echo "$1" | xxd -r -p|cat
}

odir="output"
plainFile="plain.txt"
key="1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF"
iv="00000000000000000000000000000000"
./openssl_aes_gcm e "$plainFile" "$odir"/cipher.bin "$key" "$iv"
cipher=`binFileToHexString "$odir"/cipher.bin`
tag=${cipher:(-32)}

cipherLen=${#cipher}
echo "cipherLen:" "$cipherLen"

let cipherLen-=32
cipherExclTag=${cipher:0:${cipherLen}}
echo "cipher" "$cipher"
echo "cipherLen:" "$cipherLen"
echo "cipherExclTag:" "$cipherExclTag"
echo "tag:" "$tag"
hexStringToBin "$cipherExclTag">"$odir"/cipherExclTag.bin
./openssl_aes_gcm d "$odir"/cipherExclTag.bin "$odir"/plain.txt "$key" "$iv" "$tag"
cat "$odir/plain.txt"


