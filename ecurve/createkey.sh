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
echo  "creating key and cert for " "$1"
openssl ecparam -name prime256v1 -genkey -noout  -out "$key"Private.pem
# create a certificate from the private key
openssl req -key "$key"Private.pem -new -x509 -days 365 -subj "$subject" -out "$key"Public.crt
# create a standard PEM file for the public key as well
openssl ec -in "$key"Private.pem -pubout -out "$key"Public.pem

