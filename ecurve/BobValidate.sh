#!/bin/bash
#-------------------------------------------------------------------------------------------------
# Alice has sent $1 defaults to json.txt to Bob
# Bob will derive a shared secret by using BobPrivate and AlicePublic elliptic curve keys
# The elliptic keys are created in the init.sh by using createkey.sh - keys are prime256v1
# After having derived the shared secret Bob will derive an AES 256 bits key according to NIST 
# Bob reads the other info from the json tag "otherinfo" it defaults to "Here is some other info"
# Bob reads the IV from the json.
# The cipher text is extracted from the json and then decrypted using GCM (see openssl_aes_gcm.c)
# The GCM tag is stored in the last 16 bytes of the encrypted file.  
# A resulting file $odir/plain.txt is generated containing where Bob can read message from Alice
# The signature extracted from json of the plain text file is also validated (ECDSA) hash = sha256
#-------------------------------------------------------------------------------------------------

# first some helper functions
# jsonval2 adapted from https://gist.github.com/cjus/1047794
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

function base64StringToHexString() {
    echo "$1" | openssl base64 -d -A|xxd  -p -c 2000   
}


# OK here we go - have we been passed an input file name or just assuming default json.txt
odir="output"
infile=json.txt
if [ "$#" -ge 1 ]
then
infile="$1"
fi

# The input variables names of keys for decrypting (privateKey) and verify the signature (publicCertificate)
# ----------------------------------------$odi/--------
# put infile in a variable and extract the properties
# ------------------------------------------------
json=`cat $infile`
receiverPrivate=`jsonval2 "$json"  receiverPrivate`
senderPublic=`jsonval2 "$json"  senderPublic`
cipher=`jsonval2 "$json"  cipher`
otherInfo=`jsonval2 "$json"  otherInfo`
iv=`jsonval2 "$json"  iv`
echo "cipher is:" "$cipher" " in hex:"`base64StringToHexString $cipher`
echo "iv is:" "$iv"
base64StringToBin "$iv">output/ivR.bin
ivHex=`binFileToHexString output/ivR.bin`

base64StringToBin "$otherInfo">output/otherInfoR.bin
otherInfoHex=`binFileToHexString output/otherInfoR.bin`
echo "otherInfo:" "$otherInfo"
echo "otherInfoHex:" "$otherInfoHex"

#------------------------------------------------------------
# derive the shared secret
#------------------------------------------------------------
openssl pkeyutl -derive -inkey  "$receiverPrivate" -peerkey "$senderPublic" -out output/shared_secret.bin
shared_secret=`binFileToHexString output/shared_secret.bin`
echo "shared_secret:""$shared_secret"
#--------------------------------------------------------------------------
# generate the key according to NIST
# The integer 00000001 + shared secret + other info and calculate a sha256
#-------------------------------------------------------------------------
message="00000001""$shared_secret""$otherInfoHex"
echo "message:""$message"
hexStringToBin "$message">output/message.bin
openssl dgst -sha256 -binary output/message.bin>output/key.bin
key=`binFileToHexString output/key.bin`
echo "key:" "$key"
#--------------------------------------------------------------------------
# do a aes-256  encryption GCM mode
#-------------------------------------------------------------------------
# iv="000000000000000000000000"
# openssl cli does not support gcm functions so use a c program that interfaces directly instead
# openssl enc -aes-256-gcm  -in "$odir"/plain.txt -out "$odir"/cipher.bin -K "$key" -iv $iv
hexStringToBin "$cipher">output/cipher.bin
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "SCRIPT_DIR:""$SCRIPT_DIR"
"$SCRIPT_DIR"/openssl_aes_gcm output/cipher.bin output/plain.txt "$key" "$ivHex" d
# ./openssl_aes_gcm output/cipher.bin output/plain.txt "$key" "$ivHex" d
echo "decrypt completed"
#--------------------------------------------------------------------------
# verify signature
#-------------------------------------------------------------------------
signature=`jsonval2 "$json"  signature`
if [[ -z "$signtature" ]]; then
   echo "no signature to validate"
   pubTag=""
else
echo "signature:" "$signature"
base64StringToBin "$signature">output/r_signature.der
openssl dgst -sha256 -verify "$senderPublic" -signature output/r_signature.der output/plain.txt
fi

xxd output/plain.txt



