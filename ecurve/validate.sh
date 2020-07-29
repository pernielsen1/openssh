#!/bin/bash
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
mykey="keys/encryptPrivate.pem"
partnerkey="keys/signingPublic.pem"
# ----------------------------------------$odi/--------
# put infile in a variable and extract the properties
# ------------------------------------------------
json=`cat $infile`
cipher=`jsonval2 "$json"  cipher`
tag=${cipher:(-32)}
otherinfo=`jsonval2 "$json"  otherinfo`
echo "cipher is:" "$cipher"
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
iv="000000000000000000000000"
# openssl cli does not support gcm functions so use a c program that interfaces directly instead
# openssl enc -aes-256-gcm  -in "$odir"/plain.txt -out "$odir"/cipher.bin -K "$key" -iv $iv
hexStringToBin "$cipher">"$odir"/cipher.bin
./openssl_aes_gcm "$odir/cipher.bin" "$odir"/plain.txt "$key" "$iv" d
cat "$odir/plain.txt"



