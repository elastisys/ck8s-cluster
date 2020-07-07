#!/bin/bash
# Script used by pipeline to cleanup run.
# CK8S_CONFIG_PATH
# GITHUB_SHA
# DOCKERHUB_USER
# DOCKERHUB_PASSWORD

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
bin_path="${here}/../bin"
terraform_path="${here}/../terraform"
ck8s="${here}/../bin/ck8s"

source "${here}/common.bash"
source "${bin_path}/common.bash"

sops_pgp_setup

terraform_setup

# Delete infrastructure
my_ip=$(curl ifconfig.me 2>/dev/null)
whitelist_update "public_ingress_cidr_whitelist" $my_ip 
whitelist_update "api_server_whitelist" $my_ip
whitelist_update "nodeport_whitelist" $my_ip

echo "Ensure that whitelist allows the pipeline to access the cluster."
TF_CLI_ARGS_apply="-auto-approve" \
    sops exec-env "${CK8S_CONFIG_PATH}/secrets.env" "${bin_path}/apply.bash infra tf" \
    || echo "Applying whitelist failed, will try to destroy anyway."

TF_CLI_ARGS_destroy="-auto-approve" \
    sops exec-env "${CK8S_CONFIG_PATH}/secrets.env" "${bin_path}/destroy.bash"

# Delete Terraform workspace

# TODO: Perhaps make this part of `ck8s destroy` later?

echo "Deleting Terraform workspace" >&2

source "${CK8S_CONFIG_PATH}/config.sh"

pushd "${terraform_path}/${CLOUD_PROVIDER}" > /dev/null
echo '1' | TF_WORKSPACE=pipeline terraform init -backend-config="${config[backend_config]}"
terraform workspace select "${ENVIRONMENT_NAME}"
terraform workspace select pipeline
terraform workspace delete "${ENVIRONMENT_NAME}"
popd > /dev/null

echo "Cleanup completed!" >&2
