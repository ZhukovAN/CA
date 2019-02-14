#!/bin/bash
CA_BIN_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CA_CONF_DIR=$CA_BIN_DIR
CA_HOME=$(cd $CA_BIN_DIR/..; pwd)
CA_NAME=IntermediateCA
CA_KEYLEN=2048

ROOT_CA_NAME=RootCA
ROOT_CA_HOME=$(cd $CA_BIN_DIR/../../$ROOT_CA_NAME; pwd)

echo "Using CA_HOME=$CA_HOME"

rm -rf $CA_HOME/private
rm -rf $CA_HOME/certs
rm -rf $CA_HOME/newcerts
rm -rf $CA_HOME/db
rm -rf $CA_HOME/*.crl
mkdir -p $CA_HOME/private
mkdir -p $CA_HOME/certs
mkdir -p $CA_HOME/newcerts
mkdir -p $CA_HOME/db

sed -i "s|^\(dir\s*=\s*\)\([^#]\+\)\(\s\+# Top dir\)|\1${CA_HOME}\3|g" $CA_BIN_DIR/ca.conf

UUID=`uuidgen | sed 's/-//g'`
UUID=`cut -c-16 <<< ${UUID^^}`
echo $UUID > $CA_HOME/db/$CA_NAME.crt.srl
UUID=`uuidgen | sed 's/-//g'`
UUID=`cut -c-10 <<< ${UUID^^}`
echo $UUID > $CA_HOME/db/$CA_NAME.crl.srl
touch $CA_HOME/db/$CA_NAME.db
touch $CA_HOME/db/$CA_NAME.db.attr
openssl genrsa -out $CA_HOME/private/$CA_NAME.pem.key $CA_KEYLEN
chmod 660 $CA_HOME/private/$CA_NAME.pem.key
openssl req -new -config $CA_CONF_DIR/ca.conf -out $CA_HOME/$CA_NAME.pem.csr -key $CA_HOME/private/$CA_NAME.pem.key
openssl ca -config $ROOT_CA_HOME/bin/ca.conf -in $CA_HOME/$CA_NAME.pem.csr -out $CA_HOME/certs/$CA_NAME.pem.crt -extensions signing_ca_ext -policy extern_pol -notext
openssl x509 -outform DER -in $CA_HOME/certs/$CA_NAME.pem.crt -out $CA_HOME/certs/$CA_NAME.der.crt
# ssh-keygen -y -f $CA_HOME/private/$CA_NAME.pem.key > $CA_HOME/$CA_NAME-ssh.pub
openssl ca -gencrl -config $CA_CONF_DIR/ca.conf -out $CA_HOME/$CA_NAME.pem.crl
openssl crl -in $CA_HOME/$CA_NAME.pem.crl -outform DER -out $CA_HOME/$CA_NAME.der.crl

rm -rf $CA_HOME/$CA_NAME.pem.csr
