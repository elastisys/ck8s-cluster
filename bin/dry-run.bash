#!/bin/bash

set -eu -o pipefail

# This is a very simplistic dry-run command. It runs terraform plan and
# helmfile diff. This at least gives the user some indication if something has
# changed.
# It's not to be executed on it's own but rather via `ck8s dry-run`.

# TODO: Implement a proper dry-run command which actually gives the user some
#       reassurance that the cluster will not change when deploying.
#       Currently, rke does not support it:
#       https://github.com/rancher/rke/issues/1063

here="$(dirname "$(readlink -f "$0")")"
source "${here}/common.bash"

config_load

#
# Terraform plan
#

pushd "${terraform_path}/${CLOUD_PROVIDER}" > /dev/null
terraform init
terraform workspace select "${ENVIRONMENT_NAME}"
terraform plan \
    -var-file="${tfvars_file}" \
    -var ssh_pub_key_file_sc="${ssh_pub_key_sc}" \
    -var ssh_pub_key_file_wc="${ssh_pub_key_wc}"
popd > /dev/null

#
# Helmfile diff
#

with_kubeconfig "${kube_config_sc}" "${here}/dry-run-helmfile-diff.bash" \
    service_cluster

with_kubeconfig "${kube_config_wc}" "${here}/dry-run-helmfile-diff.bash" \
    workload_cluster
