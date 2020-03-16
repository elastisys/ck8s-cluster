#!/bin/bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
ck8s="${here}/../bin/ck8s"

source "${here}/common.bash"

sops_pgp_setup

terraform_setup

TF_CLI_ARGS_apply="-auto-approve" "${ck8s}" apply all

# TODO: The GitHub Actions runner does not run as root. Chmodding for now.
#       Would be nice to find a cleaner solution.

chmod 644 "${CK8S_CONFIG_PATH}/.state/kube_config_rke_sc.yaml"
chmod 644 "${CK8S_CONFIG_PATH}/.state/kube_config_rke_wc.yaml"
chmod 644 "${CK8S_CONFIG_PATH}/customer/kubeconfig.yaml"
