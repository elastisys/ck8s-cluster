#!/bin/bash

# This script takes care of initializing a CK8S configuration path. It first
# initializes and configures the Terraform remote workspace and then generates
# SSH keys, Helm certificates and writes the default configuration files to the
# config path.
# It's not to be executed on its own but rather via `ck8s init`.

set -eu -o pipefail

: "${CK8S_CLOUD_PROVIDER:?Missing CK8S_CLOUD_PROVIDER}"
: "${CK8S_ENVIRONMENT_NAME:?Missing CK8S_ENVIRONMENT_NAME}"
# TODO: Remove when Terraform remote execution mode can be set without curling
: "${TF_TOKEN:?Missing TF_TOKEN}"

here="$(dirname "$(readlink -f "$0")")"
source "${here}/common.bash"

validate_cloud "${CK8S_CLOUD_PROVIDER}"

#
# Terraform
#

log_info "Initializing Terraform remote workspace"

pushd "${terraform_path}/${CK8S_CLOUD_PROVIDER}" > /dev/null
echo '1' | TF_WORKSPACE="${CK8S_ENVIRONMENT_NAME}" terraform init
terraform workspace select "${CK8S_ENVIRONMENT_NAME}" || \
    terraform workspace new "${CK8S_ENVIRONMENT_NAME}"
CLOUD_PROVIDER="${CK8S_CLOUD_PROVIDER}" ./set-execution-mode.sh
popd > /dev/null

#
# Config
#

log_info "Initializing CK8S configuration"

mkdir -p "${CK8S_CONFIG_PATH}"
mkdir -p "${state_path}"
mkdir -p "${ssh_path}"

ssh_gen() {
    if [ -f "${1}" ]; then
        log_info "${1} already exists, not overwriting"
        return
    fi

    # TODO: Avoid writing to disk.
    ssh-keygen -q -N "" -f "${1}"
    sops_encrypt "${1}"
}

log_info "Generating SSH keys"

ssh_gen "${ssh_priv_key_sc}"
ssh_gen "${ssh_priv_key_wc}"

# TODO: Not a fan of this directory, we should probably have a separate script
#       for generating customer configurations and not store it as a part of
#       the ck8s configuration.
mkdir -p "${CK8S_CONFIG_PATH}/customer"

# TODO: Remove when we have migrated to Helm 3.
mkdir -p "${certs_path}"
gen_helm_certs() {
    certs="${certs_path}/${1}/kube-system/certs"

    log_info "Initializing Helm certificates for ${1}"

    ${scripts_path}/generate-certs.sh "${certs}" helm
    sops_encrypt "${certs}/ca-key.pem"
    sops_encrypt "${certs}/helm-key.pem"
    sops_encrypt "${certs}/tiller-key.pem"
}
gen_helm_certs service_cluster
gen_helm_certs workload_cluster

if [ -f "${config_file}" ]; then
    log_info "${config_file} already exists, not overwriting config"
else
    export CK8S_VERSION=$(version_get)
    cat "${config_defaults_path}/config/head.sh" \
        "${config_defaults_path}/config/${CK8S_CLOUD_PROVIDER}.sh" \
        "${config_defaults_path}/config/tail.sh" | \
        envsubst > "${config_file}"
fi

if [ -f "${secrets_file}" ]; then
    log_info "${secrets_file} already exists, not overwriting secrets"
else
    # TODO: Generate random passwords

    cat "${config_defaults_path}/secrets/${CK8S_CLOUD_PROVIDER}.env" \
        "${config_defaults_path}/secrets/secrets.env" | \
        sops_encrypt_stdin dotenv "${secrets_file}"
fi

if [ -f "${tfvars_file}" ]; then
    log_info "${tfvars_file} already exists, not overwriting Terraform config"
else
    cp "${config_defaults_path}/terraform/${CK8S_CLOUD_PROVIDER}.tfvars" \
        "${tfvars_file}"
fi

log_info "Config initialized"

log_info "Time to edit the following files:"
log_info "${config_file}"
log_info "${secrets_file}"
log_info "${tfvars_file}"
