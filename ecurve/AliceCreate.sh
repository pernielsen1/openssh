#!/bin/bash
#------------------------------------------------------------------------------------
# Example of exchanging a message encrypted and signed between two parties Alice & Bob
# What keys to use, message to encrypt, padding etc are read from AliceCreate.json of from $1 if passed
# Default values will be:
# SenderPrivate   = keys/AlicePrivate.pem
# SenderPublic    = keys/AlicePublic.pem
# otherInfo       = The text string "Here is some other info" as base64
# plainFile       = plain.txt
# iv              = not passed i.e. random iv is used - otherwise pass as hex string
# padding         = GCM  -  the tag will be stored in encrypted message file last 16 bytes
# The result will be stored in BobValidate.json (i.e. the file sent to Bob).
# It will contain the following (assuming default values) 
# SenderPublic    = keys/AlicePublic.pem
# ReceiverPrivate = keys/BobPrivate.pem
# cipher          = base64 encoded encrypted message
# signature       = base64 encoded EC DSA signature
# iv              = the IV used 
# padding         = the padding scheme
# 
# input on EC DSA found at 
# https://davidederosa.com/basic-blockchain-programming/elliptic-curve-digital-signatures/
#-----------------------------------------------------------------------------------
function buildJsonLine() {
	echo -n '"'$1'":"'$2'"'$3
}

# jsonval2 adapted from https://gist.github.com/cjus/1047794
function jsonval2() {
   temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
   echo ${temp##*|}
}


function binFileToHexString() {
   xxd  -p -c 2000 $1
}

function hexStringToBin() {
   echo "$1" | xxd -r -p|cat
}

function stringToBase64String() {
 echo  "$1" -n|tr -d '\n'|openssl base64 -A
}

function binFileToHexString() {
   xxd  -p $1| tr -d '\n'
}

function base64StringToBin() {
   echo "$1"|openssl base64 -d -A|cat
}
function binFileToBase64String() {
   openssl base64 -A -in $1|cat
}



# Here we go
jsonFile="AliceCreate.json"
json=`cat $jsonFile`
senderPrivate=`jsonval2 "$json"  senderPrivate`
receiverPublic=`jsonval2 "$json"  receiverPublic`
plainFile=`jsonval2 "$json"  plainFile`
otherInfo=`jsonval2 "$json"  otherInfo`
iv=`jsonval2 "$json"  iv`
echo "senderPrivate:" "$senderPrivate"
echo "receiverPublic:" "$receiverPublic"
echo "plainFile:" "$plainFile"
echo "otherInfo:" "$otherInfo"
echo "iv:" "$iv"
if [ -z "$iv" ]; then
   openssl rand -out output/randomiv.bin 16
   iv=`binFileToBase64String output/randomiv.bin`
fi
base64StringToBin "$iv">output/iv.bin
ivHex=`binFileToHexString output/iv.bin`
echo "iv:" "$iv"
echo "ivHex:" "$ivHex"



#------------------------------------------------------------
# derive the shared secret
#------------------------------------------------------------
openssl pkeyutl -derive -inkey  "$senderPrivate" -peerkey "$receiverPublic" -out output/shared_secret.bin
shared_secret=`binFileToHexString output/shared_secret.bin`
#--------------------------------------------------------------------------
# generate the key according to NIST
# The integer 00000001 + shared secret + other info and calculate a sha256
#-------------------------------------------------------------------------
message="00000001""$shared_secret""$otherinfo"
hexStringToBin "$message">output/message.bin
openssl dgst -sha256 -binary output/message.bin>output/key.bin
key=`binFileToHexString output/key.bin`

#--------------------------------------------------------------------------
# do a aes-256  encryption gcm mode.
#-------------------------------------------------------------------------
# openssl cli does not support gcm functions so use a c program that interfaces directly instead
# openssl enc -aes-256-gcm  -in "$odir"/plain.txt -out "$odir"/cipher.bin -K "$key" -iv $iv
./openssl_aes_gcm "$plainFile" output/cipher.bin "$key" "$ivHex" e
cipher=`binFileToBase64String output/cipher.bin`
#--------------------------------------------------------------------------
# create signature 
#-------------------------------------------------------------------------
openssl dgst -sha256 -sign "$senderPrivate" "$plainFile" >output/signature.der
signature=`binFileToBase64String output/signature.der`

#--------------------------------------------------------
# build the json structure
#--------------------------------------------------------
echo "{">json.txt
echo `buildJsonLine "cipher" "$cipher" ","`>>json.txt
echo `buildJsonLine "otherInfo" "$otherInfo" ","`>>json.txt
echo `buildJsonLine "iv" "$iv" ","`>>json.txt
echo `buildJsonLine "signature" "$signature" ","`>>json.txt
echo `buildJsonLine "receiverPrivate" "keys/BobPrivate.pem" ","`>>json.txt
echo `buildJsonLine "senderPublic" "keys/AlicePublic.pem" ","`>>json.txt

echo "}">>json.txt
cat json.txt


