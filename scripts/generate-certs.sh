#!/bin/bash

# Script for generating certificates needed for securing helm/tiller.
#
# Usage: ./generate-certs.sh <out-dir> [client-list]
#
# Example: ./generate-certs.sh certs "client1 client2 client3"
#
# Based on https://github.com/helm/helm/blob/master/docs/tiller_ssl.md

CERT_DIR=$1
CLIENT_LIST=${2:-helm}

mkdir -p ${CERT_DIR}

echo "Generating certificates in ${CERT_DIR}"

# Key and certificate for the CA
if [ -e ${CERT_DIR}/ca-key.pem ]
then
    echo "Using existing ${CERT_DIR}/ca-key.pem"
else
    openssl genrsa -out ${CERT_DIR}/ca-key.pem 4096
fi
if [ -e ${CERT_DIR}/ca.pem ]
then
    echo "Using existing ${CERT_DIR}/ca.pem"
else
    openssl req -nodes -key ${CERT_DIR}/ca-key.pem -new -x509 -days 7300 -sha256 -out ${CERT_DIR}/ca.pem -extensions v3_ca -subj '/CN=tillerselfsigned'
fi


# Key and CSR for tiller
if [ -e ${CERT_DIR}/tiller-key.pem ]
then
    echo "Using existing ${CERT_DIR}/tiller-key.pem"
else
    openssl genrsa -out ${CERT_DIR}/tiller-key.pem 4096
fi
if [ -e ${CERT_DIR}/tiller-csr.pem ]
then
    echo "Using existing ${CERT_DIR}/tiller-csr.pem"
else
    openssl req -nodes -key ${CERT_DIR}/tiller-key.pem -new -sha256 -out ${CERT_DIR}/tiller-csr.pem -subj '/CN=tiller'
fi

# Key and CSR for Helm client (one per actual client)
for client in ${CLIENT_LIST}
do
    if [ -e ${CERT_DIR}/${client}-key.pem ]
    then
        echo "Using existing ${CERT_DIR}/${client}-key.pem"
    else
        openssl genrsa -out ${CERT_DIR}/${client}-key.pem 4096
    fi
    if [ -e ${CERT_DIR}/${client}-csr.pem ]
    then
        echo "Using existing ${CERT_DIR}/${client}-csr.pem"
    else
        openssl req -nodes -key ${CERT_DIR}/${client}-key.pem -new -sha256 -out ${CERT_DIR}/${client}-csr.pem -subj "/CN=${client}"
    fi

    # Sign the CSRs
    if [ -e ${CERT_DIR}/${client}.pem ]
    then
        echo "Using existing ${CERT_DIR}/${client}.pem"
    else
        openssl x509 -req -CA ${CERT_DIR}/ca.pem -CAkey ${CERT_DIR}/ca-key.pem -CAcreateserial -in ${CERT_DIR}/${client}-csr.pem -out ${CERT_DIR}/${client}.pem -days 365
    fi
done

# Sign the tiller CSR
if [ -e ${CERT_DIR}/tiller.pem ]
then
    echo "Using existing ${CERT_DIR}/tiller.pem"
else
    openssl x509 -req -CA ${CERT_DIR}/ca.pem -CAkey ${CERT_DIR}/ca-key.pem -CAcreateserial -in ${CERT_DIR}/tiller-csr.pem -out ${CERT_DIR}/tiller.pem -days 365
fi
