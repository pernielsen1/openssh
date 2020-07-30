#!/bin/bash
#------------------------------------------------------------------------------------
# Alice want to send $1 defaults to plain.txt to Bob
# Alice will derive a shared secret by using AlicePrivate and BobPublic elliptic curve keys
# The elliptic keys are created in the init.sh by using createkey.sh - keys are prime256v1
# After having derived the shared secret Alice will derive an AES 256 bits key according to NIST 
# Alice and Bob have agreed that other info is "Here is some other info"
# Alice will generate a temporary IV
# The plain text file is then encrypted using GCM (see openssl_aes_gcm.c)
# The GCM tag is stored in the last 16 bytes of the encrypted file.  
# Alice also creates a digital signature (ECDSA) on the plain text using sha256 as hashing function
# A resulting file json.txt is generated containing:
#   cipher message in hex notation
#   iv 
#   Other info
#-----------------------------------------------------------------------------------
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

# Here we go
odir=output
plainFile="plain.txt"
mykey="keys/AlicePrivate.pem"
partnerkey="keys/BobPublic.pem"
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
#iv="000000000000000000000000"
openssl rand -out "$odir"/randomiv.bin 12
iv=`binFileToHexString "$odir"/randomiv.bin`
# openssl cli does not support gcm functions so use a c program that interfaces directly instead
# openssl enc -aes-256-gcm  -in "$odir"/plain.txt -out "$odir"/cipher.bin -K "$key" -iv $iv
./openssl_aes_gcm "$plainFile" "$odir"/cipher.bin "$key" "$iv" e
cipher=`binFileToHexString "$odir"/cipher.bin`
#--------------------------------------------------------------------------
# create signature 
#-------------------------------------------------------------------------
openssl dgst -sha256 -sign "$mykey" "$plainFile" >"$odir"/signature.der
signature=`binFileToHexString "$odir"/signature.der`

#--------------------------------------------------------
# build the json structure
#--------------------------------------------------------
echo "{">json.txt
echo `buildJsonLine "cipher" "$cipher" ","`>>json.txt
echo `buildJsonLine "otherinfo" "$otherinfo" ","`>>json.txt
echo `buildJsonLine "iv" "$iv" ","`>>json.txt
echo `buildJsonLine "signature" "$signature" ","`>>json.txt
echo "}">>json.txt
cat json.txt


