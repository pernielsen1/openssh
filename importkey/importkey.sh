#!/bin/bash
function jsonval2() {
   temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
   echo ${temp##*|}
}

function hexStringToBin() {
   echo "$1" | xxd -r -p|cat
}

function getAsn1Tag() {
   temp="$((${#1}/2))"
   if [[ "$temp" -gt 127 ]]; then
	echo "81"`printf "%02x" "$temp"`"$1"
   else
	echo `printf "%02x" "$temp"`"$1"
   fi
}

if [[ -z "$1" ]]; then
   infile="importkey.json.txt"
else   
   infile="$1"
fi
if [[ -z "$2" ]]; then
   outfile="keys/importkey.result.pem"
else   
   outfile="$2"
fi



#-----------------------------------------------------------------------------
# Read the json to variables
#-----------------------------------------------------------------------------
json=`cat $infile`
type=`jsonval2 "$json" type`
priv=`jsonval2 "$json" priv`
pub=`jsonval2 "$json" pub`
curve=`jsonval2 "$json" curve`
curveOID=`jsonval2 "$json" curveOID`
# https://stackoverflow.com/questions/48101258/how-to-convert-an-ecdsa-key-to-pem-format
# build object ID string to identify the curve 
echo "curveOID" "$curveOID"
objectIDstr="a0"`printf "%02x" $((${#curveOID}/2))`"$curveOID"
privLen=`printf "%02x" $((${#priv}/2))`


pubStr="03"`getAsn1Tag "00""$pub"`
pubLen=`printf "%02x" $((${#pubStr}/2))`
pubTag="a1"`getAsn1Tag "$pubStr"`

privTag="02010104"`getAsn1Tag "$priv"`
full="$privTag""$objectIDstr""$pubTag"
der="30"`getAsn1Tag "$full"`
echo "$der"
hexStringToBin "$der">derdump.der
hexStringToBin "$der"|openssl ec -inform d>"$outfile"

