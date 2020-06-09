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

log_info "Running helmfile diff on the service cluster"

charts_ignore_list=""
[[ $CLOUD_PROVIDER != "exoscale" ]] && charts_ignore_list+=",app!=nfs-client-provisioner,app!=local-volume-provisioner"
[[ $ENABLE_HARBOR != "true" ]] && charts_ignore_list+=",app!=harbor"
[[ $ENABLE_CK8SDASH_SC != "true" ]] && charts_ignore_list+=",app!=ck8sdash"

"${here}/ops.bash" helmfile sc -l "${charts_ignore_list:1}" diff

log_info "Running helmfile diff on the workload cluster"

charts_ignore_list=""
[[ $CLOUD_PROVIDER != "exoscale" ]] && charts_ignore_list+=",app!=nfs-client-provisioner"
[[ $ENABLE_OPA != "true" ]] && charts_ignore_list+=",app!=gatekeeper-operator,app!=gatekeeper-templates,app!=gatekeeper-constraints"
[[ $ENABLE_FALCO != "true" ]] && charts_ignore_list+=",app!=falco"
[[ $ENABLE_CK8SDASH_WC != "true" ]] && charts_ignore_list+=",app!=ck8sdash"

"${here}/ops.bash" helmfile wc -l "${charts_ignore_list:1}" diff
