#!/bin/bash

export CA=/opt/ca
source utils/env.sh
source utils/utils.sh

if [ ! -f ${ROOT_CA_DATA}/private/key.pem ]; then
    initializeRootCa
    initializeIntermediateCa
elif [ ! -f ${INTERMEDIATE_CA_DATA}/private/key.pem ]; then
    initializeIntermediateCa
fi

${@}