#!/bin/bash
# validate input
usage="createkey keyname [pkcs12_input_key_file] [password] [base64]"
if [ "$1" == 'encrypt' ] || [ "$1" == 'signing' ] || [ "$1" = "ECDH" ]
then
   echo "creating key for:" "$1"
else
   echo "error usage is:" "$usage"
exit 1
fi
keyDir="keys"
key="$keyDir"/"$1"
# parameters for the subject parm
Country="SE"
State="Stockholm"
Location="Stockholm"
Organisation="test"
OrganisationUnit="My test unit"
CommonName="My Company www.test.xyz.com"
subject="/C=$Country/ST=$State/L=$Location/O=$Organisation/OU=$OrganisationUnit/CN=$CommonName"
# either create a key or import a key (pkcs12) format
if [ "$#" -lt 2 ]
then
   echo  "creating key and cert request"
   if [ "$1" = "ECDH" ] 
   then
      openssl ecparam -name secp256k1 -genkey -noout -out "$key"Private.pem
   else
      openssl req -nodes -newkey rsa:2048 -keyout "$key"Private.pem -out "$key".csr -subj "$subject" 
   fi
else
   echo "importing key" "$2"
   if [ "$#" -eq 4 ]
   then
      echo "converting from base64"
      openssl base64 -in "$2" -d -out temp.bin
      openssl pkcs12  -in temp.bin -out "$key"Private.pem -nodes -password pass:"$3"
      rm temp.bin
   else
      openssl pkcs12  -in "$2" -out "$key"Private.pem -nodes -password pass:"$3"
   fi
fi
# create a certificate from the private key
openssl req -key "$key"Private.pem -new -x509 -days 365 -subj "$subject" -out "$key"Public.crt
