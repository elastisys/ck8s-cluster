#!/bin/sh

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
cd ${SCRIPTS_PATH}/../terraform/customer/

m_ip=$(terraform output c-master-ip)

kubectl taint node $m_ip key=value:NoSchedule


kubectl apply -f ${SCRIPTS_PATH}/../local-storage/restricted-namespace.yaml
kubectl apply -f ${SCRIPTS_PATH}/../local-storage/local-test.yaml