#!/bin/bash

set -eu -o pipefail

: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"
config="${CK8S_CONFIG_PATH}/config.yaml"

dns_subdomain=$(yq r -e "${config}" dns_prefix) || (echo "key 'dns_prefix' was not found, maybe this config was already migrated"; exit 1)
cloud_provider=$(yq r -e "${config}" cloud_provider) || (echo "key 'cloud_provider' was not found"; exit 1)
case "${cloud_provider}" in
    exoscale)
        dns_domain="a1ck.io"
        ;;
    *)
        dns_domain="elastisys.se"
        ;;
esac

yq d -i "${config}" dns_prefix
yq w -i "${config}" oidc_issuer_url "https://dex.${dns_subdomain}.${dns_domain}"
yq w -i "${config}" oidc_client_id kubelogin
yq w -i "${config}" oidc_username_claim email
yq w -i "${config}" oidc_groups_claim groups

echo "OIDC config migration successful"
