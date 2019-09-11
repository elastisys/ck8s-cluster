#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

# Generate rke cluster config.
echo "Generating rke cluster configuration."
"${SCRIPTS_PATH}/gen-rke-conf-system.sh" > "${SCRIPTS_PATH}/../eck-system.yaml"

cd "${SCRIPTS_PATH}/../"

echo -e "\nInstalling kubernetes."
rke up --config eck-system.yaml

export KUBECONFIG=$(pwd)/kube_config_eck-system.yaml

echo -e "\nInstalling services."
"${SCRIPTS_PATH}/deploy-system.sh"