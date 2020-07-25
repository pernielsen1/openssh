#/bin/bash
function hexStringToBin() {
   echo "$1" | xxd -r -p|cat
}

function buildJsonLine() {
	echo -n '"'$1'":"'$2'"'$3
}


key="keys/ECDHPrivate.pem"
# key=$1

echo "asn1parse"
openssl asn1parse -inform PEM -in "$key" -i 
# openssl ec -inform pem -in "$key" -text
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

echo "asn1=SEQUENCE:ec_key">ec_asn1parse.txt
echo "[ec_key]">>ec_asn1parse.txt
echo "version=INTEGER:1">>ec_asn1parse.txt
echo "priv=INTEGER:0x""$priv">>ec_asn1parse.txt
echo "pub=""$pub">>ec_asn1parse.txt

cat ec_asn1parse.txt

# https://stackoverflow.com/questions/48101258/how-to-convert-an-ecdsa-key-to-pem-format
prestring="30740201010420"
# midstring = identifies secp256k1
midstring="a00706052b8104000aa144034200" 
derstring="$prestring""$priv""$midstring""$pub"
echo "$derstring"
hexStringToBin "$derstring">der.bin
openssl ec -inform d<der.bin

echo "{">importkey.json.txt

echo `buildJsonLine "type" "ECDH" ","`>>importkey.json.txt
echo `buildJsonLine "priv" "$priv" ","`>>importkey.json.txt
echo `buildJsonLine "pub" "$pub" ","`>>importkey.json.txt
echo `buildJsonLine "curve" "$ASN1OID" ""`>>importkey.json.txt
echo "}">>importkey.json.txt

cat importkey.json.txt


