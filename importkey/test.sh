#/bin/bash
./dumprsa.sh
./importkey.sh
openssl x509 -pubkey -noout -in keys/encryptPublic.crt > keys/encryptPublic.pem
echo "encrypting with the existing public key encryptPublic.pem"
openssl rsautl -encrypt -inkey keys/encryptPublic.pem -pubin -in plain.txt -out plain.txt.enc
echo "decrypting with the newly created key" 
openssl rsautl -decrypt -inkey newkey.pem  -in plain.txt.enc -out plain.after.txt
cat plain.after.txt

