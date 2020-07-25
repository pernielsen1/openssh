#!/bin/bash
Country="SE"
State="Stockholm"
Location="Stockholm"
Organisation="My Company"
OrganisationUnit="My Company Root"
CommonName="My Company www.mycompany.com"
subject="/C=$Country/ST=$State/L=$Location/O=$Organisation/OU=$OrganisationUnit/CN=$CommonName"
echo $subject
openssl req -nodes -newkey rsa:2048 -keyout rootkey.pem -out rootcert.pem -subj "$subject"
# Root certificate created 
# extract the public key
openssl rsa -in rootkey.pem -pubout > rootkey.pub
# now create a server certificate
# https://gist.github.com/fntlnz/cf14feb5a46b2eda428e000157447309
	
