#!/bin/bash

# Usage:
# ./initialize.sh staging-certs "Jenkins admin1 admin2" staging

# Dir where this script is located
SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

CERT_FOLDER=${1}
CLIENT_LIST=${2:-"admin1 admin2"}
STAGE=${3:-staging}

set -e

WORKSPACE="${SCRIPTS_PATH}/../clusters/${STAGE}"

#
# Secure tiller setup
#

# Generate certificates for each application and client
${SCRIPTS_PATH}/generate-certs.sh ${CERT_FOLDER}/cluster/certs "${CLIENT_LIST}"

# Initialize tiller with correct certs
${SCRIPTS_PATH}/initialize-tiller.sh kube-system ${CERT_FOLDER}/cluster/certs ${WORKSPACE}/helm-setup
