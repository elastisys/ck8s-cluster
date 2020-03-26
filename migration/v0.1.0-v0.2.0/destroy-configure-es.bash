#!/bin/bash

set -eu

: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"
: "${SOPS_PGP_FP:?Missing SOPS_PGP_FP}"

here="$(dirname "$(readlink -f "$0")")"
helmfile="${here}/../../helmfile/helmfile.yaml"

helmcert="${CK8S_CONFIG_PATH}/certs/service_cluster/kube-system/certs/helm-key.pem"
kubeconfig="${CK8S_CONFIG_PATH}/.state/kube_config_rke_sc.yaml"

log_migration() {
    echo -e "\e[33mMIGRATION[\e[35mv0.1.0-v0.2.0\e[33m]\e[0m ${@}" >&2
}

log_migration Decrypting service cluster Helm certificate key
sops -d -i "${helmcert}"
log_migration Decrypting service cluster kubeconfig
sops -d -i "${kubeconfig}"

encrypt() {
    log_migration Encrypting service cluster Helm certificate key
    sops -e -i "${kubeconfig}"
    log_migration Encrypting service cluster kubeconfig
    sops -e -i "${helmcert}"
}

trap 'encrypt' EXIT

export KUBECONFIG="${kubeconfig}"
export CONFIG_PATH="${CK8S_CONFIG_PATH}"
source "${CK8S_CONFIG_PATH}/config.sh"

log_migration Destroying configure-es release

sops exec-env "${CK8S_CONFIG_PATH}/secrets.env" \
    'helmfile -f '"${helmfile}"' -e service_cluster -l app=config -i destroy'
