#!/bin/bash

initializeCaFolder() {
    folders=( "private" "certs" "crl" "out" "db" )
    for folder in "${folders[@]}"; do
        rm -rf $1/${folder}
        mkdir -p $1/${folder}
    done
}

initializeCaDatabase() {
    uuidgen | sed 's/-//g' | cut -c-16 > $1/db/crt.srl
    uuidgen | sed 's/-//g' | cut -c-10 > $1/db/crl.srl
    touch $1/db/database
    touch $1/db/database.attr
}

initializeCaConfiguration() {
    sed -i "s|___ORGANIZATION_PLACEHOLDER___|${ORGANIZATION}\3|g" $1/ca.conf
}

initializeRootCa() {
    initializeCaFolder ${ROOT_CA_DATA}
    initializeCaDatabase ${ROOT_CA_DATA}
    initializeCaConfiguration ${ROOT_CA_CONF}

    echo "Generate root CA ${KEYLEN}-bit key"
    openssl genrsa -out ${ROOT_CA_DATA}/private/key.pem ${KEYLEN}
    chmod 660 ${ROOT_CA_DATA}/private/key.pem

    echo "Generate and self-sign certificate signing request"
    openssl req -new -config ${ROOT_CA_CONF}/ca.conf -out ${ROOT_CA_DATA}/csr.pem -key ${ROOT_CA_DATA}/private/key.pem
    openssl ca -batch -selfsign -config ${ROOT_CA_CONF}/ca.conf -in ${ROOT_CA_DATA}/csr.pem -out ${ROOT_CA_DATA}/certs/ca.pem -extensions root_ca_ext -notext
    openssl x509 -outform DER -in ${ROOT_CA_DATA}/certs/ca.pem -out ${ROOT_CA_DATA}/certs/ca.crt

    echo "Generate CRL"
    openssl ca -gencrl -config ${ROOT_CA_CONF}/ca.conf -out ${ROOT_CA_DATA}/crl/ca.pem.crl
    openssl crl -in ${ROOT_CA_DATA}/crl/ca.pem.crl -outform DER -out ${ROOT_CA_DATA}/crl/ca.der.crl

    SERIAL=`openssl x509 -in ${ROOT_CA_DATA}/certs/ca.pem -serial -noout | sed -r 's/serial=//g'`
    OUT=${ROOT_CA_DATA}/out/${SERIAL}
    echo "Copy root CA certificate generation artifacts to ${OUT} folder"
    mkdir -p ${OUT}
    mv ${ROOT_CA_DATA}/csr.pem ${OUT}
    mv ${ROOT_CA_DATA}/out/${SERIAL}.pem ${OUT}/ca.pem
    cp ${ROOT_CA_DATA}/certs/ca.crt ${OUT}
}

initializeIntermediateCa() {
    initializeCaFolder ${INTERMEDIATE_CA_DATA}
    initializeCaDatabase ${INTERMEDIATE_CA_DATA}
    initializeCaConfiguration ${INTERMEDIATE_CA_CONF}

    echo "Generate intermediate CA ${KEYLEN}-bit key"
    openssl genrsa -out ${INTERMEDIATE_CA_DATA}/private/key.pem ${KEYLEN}
    chmod 660 ${INTERMEDIATE_CA_DATA}/private/key.pem
    echo "Generate and self-sign certificate signing request"
    openssl req -new -config ${INTERMEDIATE_CA_CONF}/ca.conf -out ${INTERMEDIATE_CA_DATA}/csr.pem -key ${INTERMEDIATE_CA_DATA}/private/key.pem

    openssl ca -batch -config ${ROOT_CA_CONF}/ca.conf -in ${INTERMEDIATE_CA_DATA}/csr.pem -out ${INTERMEDIATE_CA_DATA}/certs/ca.pem -extensions signing_ca_ext -policy extern_pol -notext

    openssl x509 -outform DER -in ${INTERMEDIATE_CA_DATA}/certs/ca.pem -out ${INTERMEDIATE_CA_DATA}/certs/ca.crt
    echo "Generate CRL"
    openssl ca -gencrl -config ${INTERMEDIATE_CA_CONF}/ca.conf -out ${INTERMEDIATE_CA_DATA}/crl/ca.pem.crl
    openssl crl -in ${INTERMEDIATE_CA_DATA}/crl/ca.pem.crl -outform DER -out ${INTERMEDIATE_CA_DATA}/crl/ca.der.crl

    SERIAL=`openssl x509 -in ${INTERMEDIATE_CA_DATA}/certs/ca.pem -serial -noout | sed -r 's/serial=//g'`
    OUT=${ROOT_CA_DATA}/out/${SERIAL}
    echo "Copy intermediate CA certificate generation artifacts to ${OUT} folder"
    mkdir -p ${OUT}
    mv ${INTERMEDIATE_CA_DATA}/csr.pem ${OUT}
    mv ${ROOT_CA_DATA}/out/${SERIAL}.pem ${OUT}/ca.pem
    cp ${INTERMEDIATE_CA_DATA}/certs/ca.crt ${OUT}
}

generateSslServerCertificate() {
    TMP=`mktemp -d`
    # Create temp configuration file and replace Organization, Subject and SAN placeholders with actual values
    cp ${INTERMEDIATE_CA_CONF}/ssl.server.conf ${TMP}/ca.conf
    sed -i "s|___ORGANIZATION_PLACEHOLDER___|${ORGANIZATION}\3|g" ${TMP}/ca.conf
    sed -i "s|___SAM_PLACEHOLDER___|${1}\3|g" ${TMP}/ca.conf
    openssl req -new -config ${TMP}/ca.conf -out ${TMP}/csr.pem -keyout ${TMP}/key.pem && rm -rf ${TMP}/ca.conf
    
    # Sign request
    openssl ca -batch -config ${INTERMEDIATE_CA_CONF}/ca.conf -in ${TMP}/csr.pem -out ${TMP}/server.pem -policy extern_pol -extensions server_ext -notext
    SERIAL=`openssl x509 -in ${TMP}/server.pem -serial -noout | sed -r 's/serial=//g'`
    OUT=${INTERMEDIATE_CA_DATA}/out/${SERIAL}
    # Don't know how to avoid OpenSSL putting signed certificate copy named ${OUT}.pem, so just remove it
    rm -rf ${OUT}.pem

    echo "Copy certificate generation artifacts to ${OUT} folder"
    mkdir -p ${OUT} && mv ${TMP}/* ${OUT}/
    openssl x509 -outform DER -in ${OUT}/server.pem -out ${OUT}/server.crt
    cat ${INTERMEDIATE_CA_DATA}/certs/ca.pem ${ROOT_CA_DATA}/certs/ca.pem > ${OUT}/ca.pem
    openssl pkcs12 -export -name "SSL server" -inkey ${OUT}/key.pem -in ${OUT}/server.pem -certfile ${OUT}/ca.pem -out ${OUT}/server.full.pfx -password pass:P@ssw0rd
    openssl pkcs12 -export -name "SSL server" -inkey ${OUT}/key.pem -in ${OUT}/server.pem -out ${OUT}/server.brief.pfx -password pass:P@ssw0rd
    openssl pkcs12 -in ${OUT}/server.full.pfx -out ${OUT}/server.full.pem -passin pass:P@ssw0rd -passout pass:P@ssw0rd
    openssl pkcs12 -in ${OUT}/server.brief.pfx -out ${OUT}/server.brief.pem -passin pass:P@ssw0rd -passout pass:P@ssw0rd

    # Generate Java keystore
    keytool -importcert -keystore ${OUT}/trust.jks -storepass P@ssw0rd -alias 'Root CA' -file ${ROOT_CA_DATA}/certs/ca.pem -noprompt
    keytool -importcert -keystore ${OUT}/trust.jks -storepass P@ssw0rd -alias 'Intermediate CA' -file ${INTERMEDIATE_CA_DATA}/certs/ca.pem -noprompt
    keytool -importcert -keystore ${OUT}/private.jks -storepass P@ssw0rd -alias 'Root CA' -file ${ROOT_CA_DATA}/certs/ca.pem -noprompt
    keytool -importcert -keystore ${OUT}/private.jks -storepass P@ssw0rd -alias 'Intermediate CA' -file ${INTERMEDIATE_CA_DATA}/certs/ca.pem -noprompt
    keytool -importkeystore -srckeystore ${OUT}/server.brief.pfx -srcstoretype pkcs12 -destkeystore ${OUT}/private.jks -deststoretype JKS -deststorepass P@ssw0rd -srcstorepass P@ssw0rd
    keytool -importkeystore -srckeystore ${OUT}/private.jks -destkeystore ${OUT}/private.p12 -deststoretype pkcs12 -deststorepass P@ssw0rd -srcstorepass P@ssw0rd

    rm -rf ${TMP}
}
