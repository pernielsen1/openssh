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

# OK here we go - have we been passed an input file name or just assuming default json.txt
odir="output"
infile=json.txt
if [ "$#" -ge 1 ]
then
infile="$1"
fi

# The input variables names of keys for decrypting (privateKey) and verify the signature (publicCertificate)
mykey="keys/BobPrivate.pem"
partnerkey="keys/AlicePublic.pem"
# ----------------------------------------$odi/--------
# put infile in a variable and extract the properties
# ------------------------------------------------
json=`cat $infile`
cipher=`jsonval2 "$json"  cipher`
tag=${cipher:(-32)}
otherinfo=`jsonval2 "$json"  otherinfo`
iv=`jsonval2 "$json"  iv`
echo "cipher is:" "$cipher"
echo "iv is:" "$iv"
#------------------------------------------------------------
# derive the shared secret
#------------------------------------------------------------
openssl pkeyutl -derive -inkey  "$mykey" -peerkey "$partnerkey" -out "$odir"/shared_secret.bin
shared_secret=`binFileToHexString "$odir"/shared_secret.bin`
#--------------------------------------------------------------------------
# generate the key according to NIST
# The integer 00000001 + shared secret + other info and calculate a sha256
#-------------------------------------------------------------------------
message="00000001""$shared_secret""$otherinfo"
hexStringToBin "$message">"$odir"/message.bin
openssl dgst -sha256 -binary "$odir"/message.bin>"$odir"/key.bin
key=`binFileToHexString "$odir"/key.bin`
#--------------------------------------------------------------------------
# do a aes-256  encryption GCM mode
#-------------------------------------------------------------------------
# iv="000000000000000000000000"
# openssl cli does not support gcm functions so use a c program that interfaces directly instead
# openssl enc -aes-256-gcm  -in "$odir"/plain.txt -out "$odir"/cipher.bin -K "$key" -iv $iv
hexStringToBin "$cipher">"$odir"/cipher.bin
./openssl_aes_gcm "$odir/cipher.bin" "$odir"/plain.txt "$key" "$iv" d
#--------------------------------------------------------------------------
# verify signature
#-------------------------------------------------------------------------
signature=`jsonval2 "$json"  signature`
echo "signature:" "$signature"
hexStringToBin "$signature">"$odir"/r_signature.der
openssl dgst -sha256 -verify "$partnerkey" -signature "$odir"/r_signature.der "$odir"/plain.txt
cat "$odir/plain.txt"



