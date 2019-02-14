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

openssl genrsa -out "$CA_HOME/temp/vpn.server.pem.key" 4096 -aes256
openssl req -nodes -new -config $CA_CONF_DIR/vpn.server.conf -out $CA_HOME/temp/vpn.server.pem.csr -key $CA_HOME/temp/vpn.server.pem.key
openssl ca -config $CA_CONF_DIR/ca.conf -in $CA_HOME/temp/vpn.server.pem.csr -out $CA_HOME/temp/vpn.server.pem.crt -policy extern_pol -extensions vpn_server_ext -notext
openssl x509 -outform DER -in $CA_HOME/temp/vpn.server.pem.crt -out $CA_HOME/temp/vpn.server.der.crt

cat $CA_HOME/certs/$CA_NAME.pem.crt $ROOT_CA_HOME/certs/$ROOT_CA_NAME.pem.crt > $CA_HOME/temp/ca.chain.pem.crt
openssl pkcs12 -export -name "VPN server certificate" -inkey $CA_HOME/temp/vpn.server.pem.key -in $CA_HOME/temp/vpn.server.pem.crt -certfile $CA_HOME/temp/ca.chain.pem.crt -out $CA_HOME/temp/vpn.server.p12 -password pass:P@ssw0rd
openssl genpkey -genparam -algorithm DH -out "$CA_HOME/temp/vpn.server.pem.dh" -pkeyopt dh_paramgen_prime_len:4096
