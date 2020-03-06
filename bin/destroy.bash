#!/bin/bash

# OBS: DONT USE THIS IN PRODUCTION

# TODO: This is currently a very crude teardown flow. It needs to be expanded
#       upon with things like cleaning up loadbalancer, volumes etc.

# To run it, execute the following:
# sops exec-env [config-path/secrets.env] ./destroy.bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
source "${here}/common.bash"

config_load

log_info "Destroying Terraform infrastructure"

pushd "${terraform_path}/${CLOUD_PROVIDER}" > /dev/null
terraform init
terraform workspace select "${ENVIRONMENT_NAME}"
terraform destroy \
    -var-file="${tfvars_file}" \
    -var ssh_pub_key_file_sc="${ssh_path}/id_rsa_sc.pub" \
    -var ssh_pub_key_file_wc="${ssh_path}/id_rsa_wc.pub"
popd > /dev/null

rm -f "${rkestate_sc}"
rm -f "${rkestate_wc}"
rm -f "${kube_config_sc}"
rm -f "${kube_config_wc}"
