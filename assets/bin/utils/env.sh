#!/bin/bash

export KEYLEN=4096

export CA_CONF=${CA}/conf
export CA_DATA=${CA}/data

export ROOT_CA_DATA=${CA_DATA}/root-ca
export INTERMEDIATE_CA_DATA=${CA_DATA}/intermediate-ca

export ROOT_CA_CONF=${CA}/conf/root-ca
export INTERMEDIATE_CA_CONF=${CA}/conf/intermediate-ca
