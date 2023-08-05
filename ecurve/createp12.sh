#!/bin/bash
# validate input
usage="createkey keyname" 
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
echo  "p12 for " "$1"
openssl req -new -key "$key".pem -subj "$subject" -out  temp.csr
openssl x509 -req -days 1000 -in temp.csr -signkey "$key".pem -out "$key".cer
openssl pkcs12 -export -inkey "$key".pem -in "$key".cer -out "$key".p12
 
