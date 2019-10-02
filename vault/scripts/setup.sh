#!/bin/bash

set -e

: "${ECK_VAULT_DOMAIN:?Missing ECK_VAULT_DOMAIN}"

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

# Generate infra.json.
${SCRIPTS_PATH}/gen-infra.sh > ${SCRIPTS_PATH}/../infra.json

# Genereate rke-config.
${SCRIPTS_PATH}/gen-rke-conf-vault.sh ${SCRIPTS_PATH}/../infra.json > ${SCRIPTS_PATH}/../rke-vault.yaml

# Install kubernetes.
rke up --config ${SCRIPTS_PATH}/../rke-vault.yaml

# Export kubeconfig.
export KUBECONFIG=${SCRIPTS_PATH}/../kube_config_rke-vault.yaml

# Install nfs and vault.
${SCRIPTS_PATH}/deploy-svc.sh ${SCRIPTS_PATH}/../infra.json

# Just this for now.
sleep 10

# Initialize and unseal vault.
keys_token=$(${SCRIPTS_PATH}/init-vault.sh)

echo "Keys and token: $keys_token"

# Change this later. Store keys and master token temporarily.
echo $keys_token > keys-token

root_token=$(echo $keys_token | jq '.root_token')

# Get rid of starting end ending double quotes.
temp="${root_token%\"}"
temp="${temp#\"}"

export VAULT_TOKEN="$temp"

${SCRIPTS_PATH}/config-vault.sh
