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

source "${here}/common.bash"

sops_pgp_setup

terraform_setup

# Remove Docker image GITHUB_SHA tag created by pipeline from Docker Hub

if [ -z ${GITHUB_SHA+x} ]; then
    echo "GITHUB_SHA not set, skipping Docker tag deletion." >&2
else
    : "${DOCKERHUB_USER:?Missing DOCKERHUB_USER}"
    : "${DOCKERHUB_PASSWORD:?Missing DOCKERHUB_PASSWORD}"

    echo "Deleting Docker Hub tag: ${GITHUB_SHA}" >&2

    TOKEN=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"username": "'${DOCKERHUB_USER}'",
                 "password": "'${DOCKERHUB_PASSWORD}'"}' \
                "https://hub.docker.com/v2/users/login/" | \
            jq -r .token)

    curl -i -X DELETE \
        -H "Accept: application/json" \
        -H "Authorization: JWT ${TOKEN}" \
        "https://hub.docker.com/v2/repositories/elastisys/ck8s-ops/tags/${GITHUB_SHA}/"
fi

# Delete infrastructure

TF_CLI_ARGS_destroy="-auto-approve" \
    sops exec-env "${CK8S_CONFIG_PATH}/secrets.env" "${bin_path}/destroy.bash"

# Delete Terraform workspace

# TODO: Perhaps make this part of `ck8s destroy` later?

echo "Deleting Terraform workspace" >&2

source "${CK8S_CONFIG_PATH}/config.sh"

pushd "${terraform_path}/${CLOUD_PROVIDER}" > /dev/null
echo '1' | TF_WORKSPACE=pipeline terraform init
terraform workspace select "${ENVIRONMENT_NAME}"
terraform workspace select pipeline
terraform workspace delete "${ENVIRONMENT_NAME}"
popd > /dev/null

echo "Cleanup completed!" >&2
