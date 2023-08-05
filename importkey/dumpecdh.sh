#/bin/bash
function hexStringToBin() {
   echo "$1" | xxd -r -p|cat
}

function buildJsonLine() {
	echo -n '"'$1'":"'$2'"'$3
}

if [[ -z "$1" ]]; then
   key="keys/ECDHPrivate.pem"
else
   key="$1"
fi
if [[ -z "$2" ]]; then
   outFile="importkey.json.txt"
else
   outFile="$2"
fi
echo "key is....:" "$key" 
echo "outFile is:" "$outFile" 

#-------------------------------------------------------------- 
# parse majority by reading text output 
# openssl ec -inform pem -in "$key" -text
#--------------------------------------------------------------
temp=`openssl ec -inform pem -in "$key" -text`

temp=${temp//$'\n'/''}
temp=${temp//' '/''}
temp=${temp//'('/''}
temp=${temp//')'/''}
temp=${temp//$'Private-Key:'/$'\nPrivate_Key='}
temp=${temp//$'priv:'/$'\npriv='}
temp=${temp//$'pub:'/$'\npub='}
temp=${temp//$'ASN1OID:'/$'\nASN1OID='}
temp=${temp//$'NISTCURVE:'/$'\nNISTCURVE='}
temp=${temp//$'writing:'/$'\nwriting'}
temp=${temp//$'-----BEGIN'/$'\n:-----BEGIN'}
temp=${temp//$':'/}
temp=${temp//$'\n'/' '}
# remove the section starting with ----- BEGIN by cutting from the end %% longest match on -
temp=${temp%%-*}

#use below if var is in CSV (instead of space as delim)
#change=`echo $change | tr ',' ' '`
changes=$temp
for change in $changes; do
    set -- `echo $change | tr '=' ' '`
    #can assign value to a variable like below
    eval $1="$2";
done
#---------------------------------------------------------------------------------------
# Extract the curve Object Id by lookin in a der encoding - located after private key
#-----------------------------------------------------------------------------------------
derHex=`openssl ec -in "$key" -outform DER|xxd -p|tr -d '\n'`
# check if long structure > 128 bytes
is81=${derHex:2:2}
echo "is81" "$is81"
if [[ "$is81" -eq "81" ]]; then
   offset1=14
else
   offset1=12
fi

privLen=$((0x"${derHex:offset1:2}"))
priv2=${derHex:offset1+2:privLen}
oidPos="$((2*$privLen+offset1+6))"
oidLen=$((0x"${derHex:oidPos+2:2}"))
oid="${derHex:oidPos:4}""${derHex:oidPos+4:oidLen*2}"
pubLen=$((1+ ${#pub}/2))
pubLenHex=`printf "%02x" $((pubLen))`


# echo "derHex:" "$derHex"
# echo "pubLenHex" "$pubLenHex" "pubLen" "$pubLen"
# echo "privLen" "$privLen" 
# echo "oidPos" "$oidPos" 
# echo "oidLen" "$oidLen" 

echo "{">"$outFile"
echo `buildJsonLine "type" "ECDH" ","`>>"$outFile"
echo `buildJsonLine "priv" "$priv" ","`>>"$outFile"
echo `buildJsonLine "pub" "$pub" ","`>>"$outFile"
echo `buildJsonLine "curveOID" "$oid" ","`>>"$outFile"
echo `buildJsonLine "curve" "$ASN1OID" ""`>>"$outFile"
echo "}">>"$outFile"

# echo "type=ECDH">"$outFile"
# echo "priv=""$priv">>"$outFile"
# echo "pub=""$pub">>"$outFile"
# echo "curve=""ASN1OID">>"$outFile"
# echo "curveOID=""$oid">>"$outFile"
# cat "$outFile"





