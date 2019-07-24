#!/bin/sh

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
cd ${SCRIPTS_PATH}/../terraform/customer/

m_ip=$(terraform output c-master-ip)

# Taint master node with NoSchedule
kubectl taint node $m_ip restrictednode=true:NoSchedule

# Create namespace with whitelisting only default tolerations and worker node selectors
kubectl apply -f ${SCRIPTS_PATH}/../local-storage/restricted-namespace.yaml
