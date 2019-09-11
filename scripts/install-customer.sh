#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

# Generate rke cluster config.
echo "Generating rke cluster configuration."
"${SCRIPTS_PATH}/gen-rke-conf-customer.sh" > "${SCRIPTS_PATH}/../eck-customer.yaml"

cd "${SCRIPTS_PATH}/../"

echo -e "\nInstalling kubernetes."
rke up --config eck-customer.yaml

export KUBECONFIG=$(pwd)/kube_config_eck-customer.yaml
export ECK_SYTEM_KUBECONFIG=$(pwd)/kube_config_eck-system.yaml

echo -e "\nInstalling services."
"${SCRIPTS_PATH}/deploy-customer.sh"
