#!/bin/bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
ck8s="${here}/../bin/ck8s"
bin_path="${here}/../bin"
test_path="${here}/test"

source "${here}/common.bash"
source "${bin_path}/common.bash"

sops_pgp_setup

terraform_setup

TF_CLI_ARGS_apply="-auto-approve" "${ck8s}" apply all

# Run smoke tests (simple deployment and LoadBalancer on supported cloud providers)
# We only run this on WC as SC is thoroughly tested from all apps deployed there.
with_kubeconfig "${secrets[kube_config_wc]}" \
    "${pipeline_path}/test/k8s/test-deploy.sh" workload_cluster \
        "${config[infrastructure_file]}"

# Test API server whitelist
${test_path}/infrastructure/whitelist.sh "positive"

whitelist_update "public_ingress_cidr_whitelist" "127.0.0.1"
whitelist_update "api_server_whitelist" "127.0.0.1"

TF_CLI_ARGS_apply="-auto-approve" \
    sops exec-env "${CK8S_CONFIG_PATH}/secrets.env" "${bin_path}/apply.bash infra tf"
${test_path}/infrastructure/whitelist.sh "negative"

# TODO: The GitHub Actions runner does not run as root. Chmodding for now.
#       Would be nice to find a cleaner solution.

chmod 644 "${CK8S_CONFIG_PATH}/.state/kube_config_sc.yaml"
chmod 644 "${CK8S_CONFIG_PATH}/.state/kube_config_wc.yaml"
chmod 644 "${CK8S_CONFIG_PATH}/customer/kubeconfig.yaml"
