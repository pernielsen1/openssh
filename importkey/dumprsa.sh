#/bin/bash

function hexStringToBin() {
   echo "$1" | xxd -r -p|cat
}

function getFingerprintFromCert() {
temp=`openssl x509 -in "$1" -fingerprint -sha256 -noout|grep -Po "(?<=^SHA256 Fingerprint).*"`
# return a string =08:0F:5B:... next three lines remove : and = and then convert to lowercase .íntuitive NOT :-)...
temp=${temp//:/}
temp=${temp//=/}
temp="${temp,,}"
echo $temp
}

publicCertificate="Labbtav.crt"
publicKeyFingerprint=`getFingerprintFromCert "$publicCertificate"`
echo "Fingerprint is  =" "$publicKeyFingerprint"


temp=`openssl rsa -in keys/encryptPrivate.pem -text -noout`
temp=${temp//$'\n'/''}
temp=${temp//' '/''}
temp=${temp//'('/''}
temp=${temp//')'/''}
temp=${temp//$'Private-Key:'/$'\nPrivateKey='}
temp=${temp//$'modulus:'/$'\nmodulus='}
temp=${temp//$'publicExponent:'/$'\npublicExponent='}
temp=${temp//$'privateExponent:'/$'\nprivateExponent='}
temp=${temp//$'privateExponent:'/$'\nprivateExponent='}
temp=${temp//$'prime1:'/$'\nprime1='}
temp=${temp//$'prime2:'/$'\nprime2='}
temp=${temp//$'exponent1:'/$'\nexponent1='}
temp=${temp//$'exponent2:'/$'\nexponent2='}
temp=${temp//$'coefficient:'/$'\ncoefficient='}
temp=${temp//$':'/}
temp=${temp//$'\n'/' '}

#use below if var is in CSV (instead of space as delim)
#change=`echo $change | tr ',' ' '`
changes=$temp
for change in $changes; do
    set -- `echo $change | tr '=' ' '`
    #can assign value to a variable like below
    eval $1="$2";
done

# from https://blog.didierstevens.com/2012/01/01/calculating-a-ssh-fingerprint-from-a-cisco-public-key/


hexStringToBin "$digestString">modulus2.bin
aesSHA="-sha256"
openssl base64 -d -in $publicCertificate>cert.bin
openssl dgst  $aesSHA cert.bin

function lengthAndHexString() {
    echo `printf "%08x$1" $((${#1}/2))`
}
function lengthLineFeedAndHexString() {
    echo `printf "%08x\n$1" $((${#1}/2))`
}

# build an  ssh_rsa key structure
# ssh_rsa_hex=`echo  -n "ssh_rsa"|xxd -p`
# ssh_rsa_str=`lengthAndHexString $ssh_rsa_hex`
# ssh_pub_str=`lengthAndHexString $pubExp`
# ssh_mod_str=`lengthAndHexString $modulus`
# digestString=$ssh_rsa_str$ssh_pub_str$ssh_mod_str
# echo $digestString

#create input file to RSA-CRT format
pubExp="$publicExponent"
bitlen=$(((${#modulus}*4)-2))
printf "%04x\n"  $bitlen>RSA_CRT.txt
echo `printf "%04x\n" $((${#modulus}/2))`>>RSA_CRT.txt
echo `printf "%04x\n" $((${#pubExp}/2))`>>RSA_CRT.txt
echo "0000">>RSA_CRT.txt
echo `printf "%04x\n" $((${#prime1}/2))`>>RSA_CRT.txt
echo `printf "%04x\n" $((${#prime2}/2))`>>RSA_CRT.txt
echo `printf "%04x\n" $((${#exponent1}/2))`>>RSA_CRT.txt
echo `printf "%04x\n" $((${#exponent2}/2))`>>RSA_CRT.txt
echo `printf "%04x\n" $((${#coefficient}/2))`>>RSA_CRT.txt
echo "$modulus">>RSA_CRT.txt
echo "$pubExp">>RSA_CRT.txt
echo "$prime1">>RSA_CRT.txt
echo "$prime2">>RSA_CRT.txt
echo "$exponent1">>RSA_CRT.txt
echo "$exponent2">>RSA_CRT.txt
echo "$coefficient">>RSA_CRT.txt
cat RSA_CRT.txt
#create input file to asn1parse format 
echo "asn1=SEQUENCE:rsa_key">RSA_asn1parse.txt
echo ""

echo "[rsa_key]">>RSA_asn1parse.txt
echo "version=INTEGER:0">>RSA_asn1parse.txt
echo "modulus=INTEGER:0x""$modulus">>RSA_asn1parse.txt
echo "pubExp=INTEGER:0x010001">>RSA_asn1parse.txt
echo "privExp=INTEGER:0x""$privateExponent">>RSA_asn1parse.txt
echo "p=INTEGER:0x""$prime1">>RSA_asn1parse.txt
echo "q=INTEGER:0x""$prime2">>RSA_asn1parse.txt
echo "e1=INTEGER:0x""$exponent1">>RSA_asn1parse.txt
echo "e2=INTEGER:0x""$exponent2">>RSA_asn1parse.txt
echo "coeff=INTEGER:0x""$coefficient">>RSA_asn1parse.txt
cat RSA_asn1parse.txt

