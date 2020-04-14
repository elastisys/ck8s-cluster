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
echo '1' | TF_WORKSPACE="${ENVIRONMENT_NAME}" terraform init -backend-config="${config[backend_config]}"
terraform workspace select "${ENVIRONMENT_NAME}"
terraform plan \
    -var-file="${config[tfvars_file]}" \
    -var ssh_pub_key_sc="${config[ssh_pub_key_sc]}" \
    -var ssh_pub_key_wc="${config[ssh_pub_key_wc]}"
popd > /dev/null

#
# Helmfile diff
#

"${here}/ops.bash" helmfile sc diff
"${here}/ops.bash" helmfile wc diff
