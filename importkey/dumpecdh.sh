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
echo "outFile is:" "$key" 

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
#---------------------------------------------------------------------------------------
derHex=`openssl ec -in "$key" -outform DER|xxd -p|tr -d '\n'`
privLen=$((0x"${derHex:12:2}"))
priv2=${derHex:14:privLen}
oidPos="$((2*$privLen+18))"
oidLen=$((0x"${derHex:oidPos+2:2}"))
oid="${derHex:oidPos:4}""${derHex:oidPos+4:oidLen*2}"
echo "{">"$outFile"
echo `buildJsonLine "type" "ECDH" ","`>>"$outFile"
echo `buildJsonLine "priv" "$priv" ","`>>"$outFile"
echo `buildJsonLine "pub" "$pub" ","`>>"$outFile"
echo `buildJsonLine "curveOID" "$oid" ","`>>"$outFile"
echo `buildJsonLine "curve" "$ASN1OID" ""`>>"$outFile"
echo "}">>"$outFile"
cat "$outFile"





