#!/bin/bash
function jsonval2() {
   temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
   echo ${temp##*|}
}

function hexStringToBin() {
   echo "$1" | xxd -r -p|cat
}


function getAsn1Tag() {
   temp="$((${#2}/2))"
   if [[ "$temp" -gt 255 ]]; then
     echo "$1""82"`printf "%04x" "$temp"`"$2"
     elif [[ "$temp" -gt 127 ]]; then
        echo "$1""81"`printf "%02x" "$temp"`"$2"
     else
        echo "$1"`printf "%02x" "$temp"`"$2"
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
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
mapfile="$SCRIPT_DIR""/map/curvemap.csv"
echo "$mapfile"

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
if [[ -z "$curveOID" ]]; then
   declare -A curvemap 
   while IFS=, read -r key val
   do
      curvemap["$key"]="$val" 
   done < $mapfile
   curveOID="${curvemap["$curve"]}"
   echo "no curveOID passed finding in map with curvename:" "$curve" " found:" "$curveOID"

fi

objectIDstr=`getAsn1Tag "a0" "$curveOID"`

if [[ -z "$pub" ]]; then
   echo "no pub"
   pubTag=""
else
   pubStr=`getAsn1Tag "03" "00""$pub"`
   pubTag=`getAsn1Tag "a1" "$pubStr"`
   begin=""
fi

if [[ -z "$priv" ]]; then
   echo "no priv"
   privTag=""
   objectIDstr=`getAsn1Tag "30" "06072a8648ce3d0201""$curveOID"`

   full="$objectIDstr""$pubStr"

else
   privTag=`getAsn1Tag "04" "$priv"`
   begin="020101"
   full="$begin""$privTag""$objectIDstr""$pubTag"


fi

## privTag=`getAsn1Tag "04" "$priv"`
der=`getAsn1Tag "30" "$full"`

# hexStringToBin "$der">derdump.der

if [[ -z "$priv" ]]; then
echo "no priv import" 
hexStringToBin "$der"|openssl ec -pubin -inform d>"$outfile"

else
echo "prim import"
hexStringToBin "$der"|openssl ec -inform d>"$outfile"
fi
