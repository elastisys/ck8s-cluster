#!/bin/bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
ck8s="${here}/../bin/ck8s"

source "${here}/common.bash"

# To determine CLOUD_PROVIDER
source "${CK8S_CONFIG_PATH}/config.sh"

my_ip=$(get_my_ip)

case "${CLOUD_PROVIDER}" in
    "exoscale")
    secrets_update TF_VAR_exoscale_api_key "${CI_EXOSCALE_KEY}"
    secrets_update TF_VAR_exoscale_secret_key "${CI_EXOSCALE_SECRET}"
    secrets_update S3_ACCESS_KEY "${CI_EXOSCALE_KEY}"
    secrets_update S3_SECRET_KEY "${CI_EXOSCALE_SECRET}"

    whitelist_update "public_ingress_cidr_whitelist" $my_ip
    whitelist_update "api_server_whitelist" $my_ip
    whitelist_update "nodeport_whitelist" $my_ip
    ;;
    "safespring")
    secrets_update OS_USERNAME "${SAFESPRING_OS_USERNAME}"
    secrets_update OS_PASSWORD "${SAFESPRING_OS_PASSWORD}"
    secrets_update S3_ACCESS_KEY "${SAFESPRING_S3_ACCESS_KEY}"
    secrets_update S3_SECRET_KEY "${SAFESPRING_S3_SECRET_KEY}"
    secrets_update AWS_ACCESS_KEY_ID "${CI_AWS_ACCESS_KEY_ID}"
    secrets_update AWS_SECRET_ACCESS_KEY "${CI_AWS_SECRET_ACCESS_KEY}"

    whitelist_update "public_ingress_cidr_whitelist" $my_ip
    whitelist_update "api_server_whitelist" $my_ip
    whitelist_update "nodeport_whitelist" $my_ip
    ;;
    "citycloud")
    secrets_update OS_USERNAME "${CITYCLOUD_OS_USERNAME}"
    secrets_update OS_PASSWORD "${CITYCLOUD_OS_PASSWORD}"
    secrets_update S3_ACCESS_KEY "${CITYCLOUD_S3_ACCESS_KEY}"
    secrets_update S3_SECRET_KEY "${CITYCLOUD_S3_SECRET_KEY}"
    secrets_update AWS_ACCESS_KEY_ID "${CI_AWS_ACCESS_KEY_ID}"
    secrets_update AWS_SECRET_ACCESS_KEY "${CI_AWS_SECRET_ACCESS_KEY}"

    whitelist_update "public_ingress_cidr_whitelist" $my_ip
    whitelist_update "api_server_whitelist" $my_ip
    whitelist_update "nodeport_whitelist" $my_ip
    ;;
esac
