#!/bin/bash
function buildJsonLine() {
	echo -n '"'$1'":"'$2'"'$3
}

function binFileToHexString() {
   xxd  -p -c 2000 $1
}

function hexStringToBin() {
   echo "$1" | xxd -r -p|cat
}

function stringToHexString() {
 echo  "$1" -n|tr -d '\n'|xxd -p -c 2000
}

function binFileToHexString() {
   xxd  -p $1| tr -d '\n'
}

odir=output
plainFile="plain.txt"
mykey="keys/signingPrivate.pem"
partnerkey="keys/encryptPublic.pem"
#------------------------------------------------------------
# derive the shared secret
#------------------------------------------------------------
openssl pkeyutl -derive -inkey  "$mykey" -peerkey "$partnerkey" -out "$odir"/shared_secret.bin
shared_secret=`binFileToHexString "$odir"/shared_secret.bin`
otherinfo=`stringToHexString "Here is some other info"`
#--------------------------------------------------------------------------
# generate the key according to NIST
# The integer 00000001 + shared secret + other info and calculate a sha256
#-------------------------------------------------------------------------
message="00000001""$shared_secret""$otherinfo"
hexStringToBin "$message">"$odir"/message.bin
openssl dgst -sha256 -binary "$odir"/message.bin>"$odir"/key.bin
key=`binFileToHexString "$odir"/key.bin`

#--------------------------------------------------------------------------
# do a aes-256  encryption gcm mode.
#-------------------------------------------------------------------------
iv="000000000000000000000000"
# openssl cli does not support gcm functions so use a c program that interfaces directly instead
# openssl enc -aes-256-gcm  -in "$odir"/plain.txt -out "$odir"/cipher.bin -K "$key" -iv $iv
./openssl_aes_gcm "$plainFile" "$odir"/cipher.bin "$key" "$iv" e
cipher=`binFileToHexString "$odir"/cipher.bin`

#--------------------------------------------------------
# build the json structure
#--------------------------------------------------------
echo "{">json.txt
echo `buildJsonLine "cipher" "$cipher" ","`>>json.txt
echo `buildJsonLine "otherinfo" "$otherinfo" ","`>>json.txt
echo "}">>json.txt
cat json.txt


