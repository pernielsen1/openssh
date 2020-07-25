#!/bin/bash
function jsonval2() {
   temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
   echo ${temp##*|}
}

function hexStringToBin() {
   echo "$1" | xxd -r -p|cat
}

# infile="importkey.json.txt"
infile="$1"
outfile="$2"

json=`cat $infile`
type=`jsonval2 "$json" type`
priv=`jsonval2 "$json" priv`
pub=`jsonval2 "$json" pub`
curve=`jsonval2 "$json" curve`
# https://stackoverflow.com/questions/48101258/how-to-convert-an-ecdsa-key-to-pem-format
# secp256k1  1.3.132.0.10 object ID is:  06 05 2B 81 04 00 0A

objectID=""


if [ "$curve" = "secp256v1" ]; then 
    objectID="06052B8104000A"
fi  

if [ "$curve" = "prime256v1" ]; then
# Prime 256 v1 object ID is 06 08 2A 86 48 CE 3D 03 01 07
    objectID="06082A8648CE3D030107"
fi  
objectIDstr="a0"`printf "%02x" $((${#objectID}/2))`"$objectID"
privLen=`printf "%02x" $((${#priv}/2))`
full="02010104""$privLen""$priv""$objectIDstr"
fullLen=`printf "%02x" $((${#full}/2))`
der="30""$fullLen""$full"
echo "$der"
hexStringToBin "$der"|openssl ec -inform d>"$outfile"
