#!/bin/bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
ck8s="${here}/../bin/ck8s"

source "${here}/common.bash"

sops_pgp_setup

terraform_setup

TF_CLI_ARGS_apply="-auto-approve" "${ck8s}" apply all
${here}/test/infrastructure/whitelist.sh "positive"

whitelist_update "public_ingress_cidr_whitelist" "127.0.0.1"
whitelist_update "api_server_whitelist" "127.0.0.1"

TF_CLI_ARGS_apply="-auto-approve" "${ck8s}" apply all
${here}/test/infrastructure/whitelist.sh "positive"

whitelist_update "public_ingress_cidr_whitelist" "0.0.0.0"
whitelist_update "api_server_whitelist" "0.0.0.0"

TF_CLI_ARGS_apply="-auto-approve" "${ck8s}" apply infra
${here}/test/infrastructure/whitelist.sh "negative"

# TODO: The GitHub Actions runner does not run as root. Chmodding for now.
#       Would be nice to find a cleaner solution.

chmod 644 "${CK8S_CONFIG_PATH}/.state/kube_config_sc.yaml"
chmod 644 "${CK8S_CONFIG_PATH}/.state/kube_config_wc.yaml"
chmod 644 "${CK8S_CONFIG_PATH}/customer/kubeconfig.yaml"
