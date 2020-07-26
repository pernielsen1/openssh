# DataKeyAndSign
An example of exchaning data between two parties with data in a json structure.
Data is encrypted with an AES key.
The AES key is sent a part of the json structure encrypted under receipients public RSA key.
The json has a signature of the data - the data is signed with the senders private RSA key.
The json has a reference to the fingerprint of the receipients public key.

## Installation
./init.sh
the init.sh script creates two key pairs 
encryption (i.e. public and private key for the receiver - normally you only have the public key sent to you from the receiver).
signing (i.e. the public and private key for the sender - normally you would send the public key to the receiver)

## Usage
./create.sh
Will create a test json.txt where data has been encrypted with an aes key, the key has been encrypted with receivers public key and a signature created signed with senders private key.

./validate.sh
Will validate json.txt extract key - decrypt and verify signature.



