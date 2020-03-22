#!/bin/bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
ck8s="${here}/../bin/ck8s"

source "${here}/common.bash"

sops_pgp_setup

terraform_setup

export CK8S_ENVIRONMENT_NAME="pipeline-${GITHUB_RUN_ID}"

# Initialize ck8s repository

"${ck8s}" init

# Update ck8s configuration

config_update() {
    sed -i 's/'"${1}"'=".*"/'"${1}"'="'"${2}"'"/g' \
        "${CK8S_CONFIG_PATH}/config.sh"
}

secrets_update() {
    secrets_env="${CK8S_CONFIG_PATH}/secrets.env"
    sops -d -i "${secrets_env}"
    sed -i 's/'"${1}"'=.*/'"${1}"'='"${2}"'/g' "${secrets_env}"
    sops -e -i "${secrets_env}"

}

case "${CK8S_CLOUD_PROVIDER}" in
    "exoscale")
    config_update ECK_BASE_DOMAIN "${CK8S_ENVIRONMENT_NAME}.a1ck.io"
    config_update ECK_OPS_DOMAIN "ops.${CK8S_ENVIRONMENT_NAME}.a1ck.io"

    secrets_update TF_VAR_exoscale_api_key "${CI_EXOSCALE_KEY}"
    secrets_update TF_VAR_exoscale_secret_key "${CI_EXOSCALE_SECRET}"
    secrets_update S3_ACCESS_KEY "${CI_EXOSCALE_KEY}"
    secrets_update S3_SECRET_KEY "${CI_EXOSCALE_SECRET}"

    # No whitelisting
    sed -i ':a;N;$!ba;s/public_ingress_cidr_whitelist = \[[^]]*\]/public_ingress_cidr_whitelist = \["0.0.0.0\/0"\]/g' \
        "${CK8S_CONFIG_PATH}/config.tfvars"
    ;;
    "safespring")
    config_update ECK_BASE_DOMAIN "${CK8S_ENVIRONMENT_NAME}.elastisys.se"
    config_update ECK_OPS_DOMAIN "ops.${CK8S_ENVIRONMENT_NAME}.elastisys.se"

    secrets_update OS_USERNAME "${CI_OS_USERNAME}"
    secrets_update OS_PASSWORD "${CI_OS_PASSWORD}"
    secrets_update S3_ACCESS_KEY "${CI_S3_ACCESS_KEY}"
    secrets_update S3_SECRET_KEY "${CI_S3_SECRET_KEY}"
    secrets_update AWS_ACCESS_KEY_ID "${CI_AWS_ACCESS_KEY_ID}"
    secrets_update AWS_SECRET_ACCESS_KEY "${CI_AWS_SECRET_ACCESS_KEY}"

    # No whitelisting
    sed -i 's/public_ingress_cidr_whitelist = .*/public_ingress_cidr_whitelist = "0.0.0.0\/0"/' \
        "${CK8S_CONFIG_PATH}/config.tfvars"
    ;;
esac

# TODO: The GitHub Actions runner does not run as root. Chmodding for now.
#       Would be nice to find a cleaner solution.

chmod 644 "${CK8S_CONFIG_PATH}/ssh/id_rsa_sc"
chmod 644 "${CK8S_CONFIG_PATH}/ssh/id_rsa_wc"
chmod 644 "${CK8S_CONFIG_PATH}"/certs/service_cluster/kube-system/certs/*-key.pem
chmod 644 "${CK8S_CONFIG_PATH}"/certs/workload_cluster/kube-system/certs/*-key.pem