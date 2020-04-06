#!/bin/bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"

source "${here}/common.bash"

sops_pgp_setup

sops exec-file --no-fifo "${CK8S_CONFIG_PATH}/.state/kube_config_wc.yaml" \
    'KUBECONFIG={} ${GITHUB_WORKSPACE}/release/get-versions.sh'

sops exec-file --no-fifo "${CK8S_CONFIG_PATH}/.state/kube_config_sc.yaml" \
    'KUBECONFIG={} ${GITHUB_WORKSPACE}/release/get-versions.sh'

cat release/version.json > "${GITHUB_WORKSPACE}/version.json"
