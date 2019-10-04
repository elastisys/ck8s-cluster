#!/bin/bash

# Installs the nfs storage provisioner and installs vault.
# This script will leave vault in an uninitialized state.
# Initializing and unsealing vault will need to be done manually.

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

if [[ "$#" -lt 1 ]]
then 
  >&2 echo "Usage: deploy-svc.sh path-to-infra-file"
  exit 1
fi

infra="$1"

export NFS_VAULT_SERVER_IP=$(cat $infra | jq -r '.vault_cluster.nfs_ip_address')

kubectl create namespace vault --dry-run -o yaml | kubectl apply -f -

# HELM and TILLER
mkdir -p ${SCRIPTS_PATH}/../certs/vault_cluster/kube-system/certs
${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/vault_cluster "helm"
source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/vault_cluster/kube-system/certs "helm"

# CERT-MANAGER
kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml
envsubst < ${SCRIPTS_PATH}/../manifests/certificates/vault-cert.yaml | kubectl apply -f -


# HELMFILE
helmfile -f helmfile/helmfile.yaml -e vault_cluster -l app=nfs-client-provisioner apply
helmfile -f helmfile/helmfile.yaml -e vault_cluster -l app=cert-manager apply
helmfile -f helmfile/helmfile.yaml -e vault_cluster -l app=vault apply

while [[ $(kubectl -n vault get certificates vault-cert -o 'jsonpath={.status.conditions[0].status}') != "True" ]]; 
do 
  echo "Waiting for certificate." && sleep 2; 
done

echo "Waiting for certificate done!"

envsubst < ${SCRIPTS_PATH}/../vault-config/ingress.yaml | kubectl apply -f -

while [[ $(kubectl -n vault get pods vault-0 -o 'jsonpath={.status.phase}') != "Running" ]]; 
do 
  echo "waiting for pod." && sleep 2; 
done

echo "Waiting for pod done!"
