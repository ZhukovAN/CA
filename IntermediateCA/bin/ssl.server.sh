#!/bin/bash

CA_BIN_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CA_CONF_DIR=$CA_BIN_DIR
CA_HOME=$(cd $CA_BIN_DIR/..; pwd)
CA_NAME=IntermediateCA

ROOT_CA_NAME=RootCA
ROOT_CA_HOME=$(cd $CA_BIN_DIR/../../$ROOT_CA_NAME; pwd)

echo "Using CA_HOME=$CA_HOME"

rm -rf $CA_HOME/temp
mkdir -p $CA_HOME/temp

openssl req -new -config $CA_CONF_DIR/ssl.server.conf -out $CA_HOME/temp/ssl.server.pem.csr -keyout $CA_HOME/temp/ssl.server.pem.key
openssl ca -config $CA_CONF_DIR/ca.conf -in $CA_HOME/temp/ssl.server.pem.csr -out $CA_HOME/temp/ssl.server.pem.crt -policy extern_pol -extensions server_ext -notext
OUT_FOLDER=$CA_HOME/out/`openssl x509 -in $CA_HOME/temp/ssl.server.pem.crt -serial -noout | sed -r 's/serial=//g'`
mkdir -p $OUT_FOLDER
mv $CA_HOME/temp/* $OUT_FOLDER
openssl x509 -outform DER -in $OUT_FOLDER/ssl.server.pem.crt -out $OUT_FOLDER/ssl.server.der.crt

cat $CA_HOME/certs/$CA_NAME.pem.crt $ROOT_CA_HOME/certs/$ROOT_CA_NAME.pem.crt > $OUT_FOLDER/ca.chain.pem.crt
openssl pkcs12 -export -name "SSL server certificate" -inkey $OUT_FOLDER/ssl.server.pem.key -in $OUT_FOLDER/ssl.server.pem.crt -certfile $OUT_FOLDER/ca.chain.pem.crt -out $OUT_FOLDER/ssl.server.full.pfx -password pass:P@ssw0rd
openssl pkcs12 -export -name "SSL server certificate" -inkey $OUT_FOLDER/ssl.server.pem.key -in $OUT_FOLDER/ssl.server.pem.crt -out $OUT_FOLDER/ssl.server.brief.pfx -password pass:P@ssw0rd
openssl pkcs12 -in $OUT_FOLDER/ssl.server.full.pfx -out $OUT_FOLDER/ssl.server.full.pem -passin pass:P@ssw0rd -passout pass:P@ssw0rd
openssl pkcs12 -in $OUT_FOLDER/ssl.server.brief.pfx -out $OUT_FOLDER/ssl.server.brief.pem -passin pass:P@ssw0rd -passout pass:P@ssw0rd

# Generate Java keystore
cd $OUT_FOLDER
keytool -importcert -keystore trust.jks -storepass P@ssw0rd -alias RootCA -file ../../../$ROOT_CA_NAME/certs/$ROOT_CA_NAME.pem.crt -noprompt
keytool -importcert -keystore trust.jks -storepass P@ssw0rd -alias IntermediateCA -file ../../certs/$CA_NAME.pem.crt -noprompt
keytool -importcert -keystore private.jks -storepass P@ssw0rd -alias RootCA -file ../../../$ROOT_CA_NAME/certs/$ROOT_CA_NAME.pem.crt -noprompt
keytool -importcert -keystore private.jks -storepass P@ssw0rd -alias IntermediateCA -file ../../certs/$CA_NAME.pem.crt -noprompt
keytool -importkeystore -srckeystore ssl.server.brief.pfx -srcstoretype pkcs12 -destkeystore private.jks -deststoretype JKS -deststorepass P@ssw0rd -srcstorepass P@ssw0rd
keytool -importkeystore -srckeystore private.jks -destkeystore private.p12 -deststoretype pkcs12 -deststorepass P@ssw0rd -srcstorepass P@ssw0rd
cd ..