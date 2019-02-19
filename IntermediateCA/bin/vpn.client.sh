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

openssl req -new -config $CA_CONF_DIR/vpn.client.conf -out $CA_HOME/temp/vpn.client.pem.csr -keyout $CA_HOME/temp/vpn.client.pem.key
openssl ca -config $CA_CONF_DIR/ca.conf -in $CA_HOME/temp/vpn.client.pem.csr -out $CA_HOME/temp/vpn.client.pem.crt -policy extern_pol -extensions client_ext -notext
OUT_FOLDER=$CA_HOME/out/`openssl x509 -in $CA_HOME/temp/vpn.client.pem.crt -serial -noout | sed -r 's/serial=//g'`
mkdir -p $OUT_FOLDER
mv $CA_HOME/temp/* $OUT_FOLDER
openssl x509 -outform DER -in $OUT_FOLDER/vpn.client.pem.crt -out $OUT_FOLDER/vpn.client.der.crt

cat $CA_HOME/certs/$CA_NAME.pem.crt $ROOT_CA_HOME/certs/$ROOT_CA_NAME.pem.crt > $OUT_FOLDER/ca.chain.pem.crt
openssl pkcs12 -export -name "VPN client certificate" -inkey $OUT_FOLDER/vpn.client.pem.key -in $OUT_FOLDER/vpn.client.pem.crt -certfile $OUT_FOLDER/ca.chain.pem.crt -out $OUT_FOLDER/vpn.client.full.pfx -password pass:P@ssw0rd
openssl pkcs12 -export -name "VPN client certificate" -inkey $OUT_FOLDER/vpn.client.pem.key -in $OUT_FOLDER/vpn.client.pem.crt -out $OUT_FOLDER/vpn.client.brief.pfx -password pass:P@ssw0rd