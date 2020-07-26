#!/bin/bash
# first some helper functions
# jsonval2 adapted from https://gist.github.com/cjus/1047794
encoding="base64"
function jsonval2() {
   temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
   echo ${temp##*|}
}

function binFileToHexString() {
   xxd  -p -c 200 $1
}

function hexStringToBin() {
   echo "$1" | xxd -r -p|cat
}

function base64StringToBin() {
   echo "$1"|openssl base64 -d -A|cat
}

function stringToBin() {

   if [ $encoding == "hex" ]; then
	hexStringToBin $1
   else
        base64StringToBin $1
   fi

}


# OK here we go - have we been passed an input file name or just assuming default json.txt
odir="output"
infile=json.txt
if [ "$#" -ge 1 ]
then
infile="$1"
fi

# The input variables names of keys for decrypting (privateKey) and verify the signature (publicCertificate)
privateKey="keys/encryptPrivate.pem"
publicCertificate="keys/signingPublic.crt"
# ------------------------------------------------
# put infile in a variable and extract the properties
# ------------------------------------------------
json=`cat $infile`
data=`jsonval2 "$json"  data`
fingerprint=`jsonval2 "$json"  fingerprint`
key=`jsonval2 "$json"  key`
iv=`jsonval2 "$json"  iv`
pkeyopt="-pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -pkeyopt rsa_mgf1_md:sha256"
# -------------------------------------------------------------------------------------
# unwrap the key first convert from base64 - binary and store in aesKey variable
# based on length define the aes-cipher (128 or 256) bits
#-------------------------------------------------------------------------------------
stringToBin "$key">"$odir"/encryptedKey.bin
openssl pkeyutl -decrypt -in "$odir"/encryptedKey.bin -out "$odir"/encryptedKey.clear  -inkey "$privateKey"  $pkeyopt
aesKey=`binFileToHexString "$odir"/encryptedKey.clear`
aesCipher="-aes-""$((4*${#aesKey}))""-cbc"
echo "decryptedKey is:" $aesKey " aesCipher is:" $aesCipher "iv is:" $iv
# -----------------------------------------------------------------------------------
# PKCS7 padding is default for openssl
# decrypt the json element data and store it in plain.txt
# -----------------------------------------------------------------------------------
stringToBin "$data">"$odir"/data.bin
dataPlain=`openssl enc -d $aesCipher -in "$odir"/data.bin -K $aesKey -iv $iv`
echo "$dataPlain">"$odir"/plain.txt
# ----------------------------------------------------------------------------------
# extract signature and verify it against the plain text (signatureData)
# ---------------------------------------------------------------------------------
echo "Validating signature"
signatureData=$dataPlain
signature=`jsonval2 "$json"  signature`
stringToBin "$signature">"$odir"/signature.bin
echo -n $signatureData>"$odir"/signatureData.temp
# extract public key from certificate
openssl x509 -pubkey -noout -in "$publicCertificate" > "$odir"/publicKey.temp
openssl dgst -sha256 -verify "$odir"/publicKey.temp -signature "$odir"/signature.bin "$odir"/signatureData.temp
echo "plain text was:"
cat "$odir"/plain.txt


