#!/bin/bash
infile=$1
echo "Infile is:" "$infile"
openssl base64 -d -a -in  "$infile" -out "$infile.bin"
openssl pkcs12 -in "$infile.bin" -out "$infile.key.pem" -nocerts -nodes


