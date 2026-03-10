#!/bin/bash

KEYLEN=4096

CA_CONF=/etc/ca
CA_DATA=/var/lib/ca

ROOT_CA_DATA=${CA_DATA}/root
INTERMEDIATE_CA_DATA=${CA_DATA}/intermediate

ROOT_CA_CONF=${CA_CONF}/root
INTERMEDIATE_CA_CONF=${CA_CONF}/intermediate
