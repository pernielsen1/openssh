#!/bin/bash
#----------------------------------------
# helper functions
#--------------------------------------
encoding="base64"
function buildJsonLine() {
	echo -n '"'$1'":"'$2'"'$3
}
function binFileToHexString() {
   xxd  -p $1| tr -d '\n'
}
function hexStringToBin() {
   echo "$1" | xxd -r -p|cat
}
function base64StringToBin() {
   echo "$1"|openssl base64 -d -A|cat
}
function binFileToBase64String() {
   openssl base64 -A -in $1|cat
}

function binFileToString() {
   if [ $encoding ==  "hex" ];  then
	binFileToHexString $1
   else
	binFileToBase64String $1
   fi
}


function getFingerprintFromCert() {
temp=`openssl x509 -in "$1" -fingerprint -sha256 -noout|grep -Po "(?<=^SHA256 Fingerprint).*"`
# return a string =08:0F:5B:... next three lines remove : and = and then convert to lowercase .íntuitive NOT :-)... 
temp=${temp//:/}
temp=${temp//=/}
temp="${temp,,}"
echo $temp
}

odir=output
#------------------------------------------------------------------------------------
# Here we go the aeskey is hardcoded in example - normally you would create temporary random key
# IV set to hex 00 - normally also use a random number here 
#------------------------------------------------------------------------------------
aesCipher="-aes-256-cbc"
aesKey="C1C2C3C4C5C6C7C81C2C3C4C5C6C7C8CA1A2A3A4A5A6A7A81A2A3A4A5A6A7A8A"
iv="00000000000000000000000000000000"
# the digest function for TAV

privateKey="keys/signingPrivate.pem"
publicCertificate="keys/encryptPublic.crt"

#--------------------------------------------------------------------------
# encrypt the data => encryptedDataHex
#--------------------------------------------------------------------------
plainText="Hello World here we come"
echo $plainText>"$odir"/plain.temp
openssl enc -e $aesCipher -in "$odir"/plain.temp -out "$odir"/cipher.bin -K $aesKey -iv $iv
data=`binFileToString "$odir"/cipher.bin`

#--------------------------------------------------------------------------------------------------
# encrypt the aesKey with public key padding sha256 - if you want standard PKCS 1.2 use pkeyopt=""
#--------------------------------------------------------------------------------------------------
pkeyopt="-pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -pkeyopt rsa_mgf1_md:sha256"
hexStringToBin "$aesKey">"$odir"/aesKey.bin
openssl pkeyutl -encrypt -in "$odir"/aesKey.bin -out "$odir"/aesKey.enc -certin -inkey "$publicCertificate"  $pkeyopt
key=`binFileToString "$odir"/aesKey.enc`

#-------------------------------------------------------------------
# create the signature - based on whole plain text in this example
#-------------------------------------------------------------------
signatureData=$plainText
echo -n $signatureData>"$odir"/signatureData.temp
openssl dgst -sha256 -sign $privateKey -out "$odir"/signature.bin "$odir"/signatureData.temp
# signature=`binFileToBase64String "$odir"/signature.bin`
signature=`binFileToString "$odir"/signature.bin`

#--------------------------------------------------------------------------
# extract the finger print for public key from certificate
#--------------------------------------------------------------------------
fingerprint=`getFingerprintFromCert "$publicCertificate"`

#--------------------------------------------------------
# build the json structure
#--------------------------------------------------------
echo "{">json.txt
echo `buildJsonLine "data" "$data" ","`>>json.txt
echo `buildJsonLine "key" "$key" ","`>>json.txt
echo `buildJsonLine "iv" "$iv" ","`>>json.txt
echo `buildJsonLine "fingerprint" "$fingerprint" ","`>>json.txt
echo `buildJsonLine "signature" "$signature" ""`>>json.txt
echo "}">>json.txt


