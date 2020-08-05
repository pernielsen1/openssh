#/bin/bash
./dumpecdh.sh keys/AlicePrivate.pem AlicePrivate.json
./importkey.sh AlicePrivate.json keys/AlicePrivate2.pem
openssl ec -in keys/AlicePrivate.pem -text -noout
openssl ec -in keys/AlicePrivate2.pem -text -noout

