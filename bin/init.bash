#!/bin/bash

# This script takes care of initializing a CK8S configuration path. It first
# initializes and configures the Terraform remote workspace and then generates
# SSH keys and writes the default configuration files to the config path.
# It's not to be executed on its own but rather via `ck8s init`.

set -eu -o pipefail

: "${CK8S_CLOUD_PROVIDER:?Missing CK8S_CLOUD_PROVIDER}"
: "${CK8S_ENVIRONMENT_NAME:?Missing CK8S_ENVIRONMENT_NAME}"
# TODO: Remove when Terraform remote execution mode can be set without curling
: "${TF_TOKEN:?Missing TF_TOKEN}"
# Make sure flavor is set
CK8S_FLAVOR="${CK8S_FLAVOR:-default}"

here="$(dirname "$(readlink -f "$0")")"
source "${here}/common.bash"

validate_cloud "${CK8S_CLOUD_PROVIDER}"

# Validate the flavor
if [ "${CK8S_FLAVOR}" != "default" ] &&
   [ "${CK8S_FLAVOR}" != "ha" ]; then
    log_error "ERROR: Unsupported flavor: ${CK8S_FLAVOR}"
    exit 1
fi
if [ "${CK8S_FLAVOR}" == "ha" ] &&
    ([ "${CK8S_CLOUD_PROVIDER}" != "exoscale" ] &&
    [ "${CK8S_CLOUD_PROVIDER}" != "safespring" ]); then
    log_error "ERROR: Unsupported flavor: ${CK8S_FLAVOR}"
    log_error "for cloud provider: ${CK8S_CLOUD_PROVIDER}"
    exit 1
fi

tfvars_flavor() {
    if [ "${CK8S_FLAVOR}" == "default" ]; then
        echo "${CK8S_CLOUD_PROVIDER}.tfvars"
    else
        echo "${CK8S_CLOUD_PROVIDER}-${CK8S_FLAVOR}.tfvars"
    fi
}

#
# SOPS config
#

if [ -f "${sops_config}" ]; then
    log_info "SOPS config already exists: ${sops_config}"
    validate_sops_config
else
    if [ "${CK8S_PGP_FP+x}" != "" ]; then
        fingerprint="${CK8S_PGP_FP}"
    elif [ "${CK8S_PGP_UID+x}" != "" ]; then
        fingerprint=$(gpg --list-keys --with-colons "${CK8S_PGP_UID}" | \
                      awk -F: '$1 == "fpr" {print $10;}' | head -n 1)
        if [ -z "${fingerprint}" ]; then
            log_error "ERROR: Unable to get fingerprint from gpg keyring."
            log_error "CK8S_PGP_UID=${CK8S_PGP_UID}"
            exit 1
        fi
    else
        log_error "ERROR: CK8S_PGP_FP and CK8S_PGP_UID can't both be unset"
        exit 1
    fi

    log_info "Initializing SOPS config with PGP fingerprint: ${fingerprint}"

    sops_config_write_fingerprints "${fingerprint}"
fi

#
# Config
#

log_info "Initializing CK8S configuration"

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

ssh_gen "${secrets[ssh_priv_key_sc]}"
ssh_gen "${secrets[ssh_priv_key_wc]}"

# TODO: Not a fan of this directory, we should probably have a separate script
#       for generating customer configurations and not store it as a part of
#       the ck8s configuration.
mkdir -p "${CK8S_CONFIG_PATH}/customer"

if [ -f "${config[config_file]}" ]; then
    log_info "${config[config_file]} already exists, not overwriting config"
else
    export CK8S_VERSION=$(version_get)
    cat "${config_defaults_path}/config/head.sh" \
        "${config_defaults_path}/config/${CK8S_CLOUD_PROVIDER}.sh" \
        "${config_defaults_path}/config/tail.sh" | \
        envsubst > "${config[config_file]}"
fi

if [ -f "${secrets[secrets_file]}" ]; then
    log_info "${secrets[secrets_file]} already exists, not overwriting secrets"
else
    # TODO: Generate random passwords

    cat "${config_defaults_path}/secrets/${CK8S_CLOUD_PROVIDER}.env" \
        "${config_defaults_path}/secrets/secrets.env" | \
        sops_encrypt_stdin dotenv "${secrets[secrets_file]}"
fi

if [ -f "${config[tfvars_file]}" ]; then
    log_info "${config[tfvars_file]} already exists, not overwriting" \
             "Terraform config"
else
    cp "${config_defaults_path}/terraform/$(tfvars_flavor)" \
        "${config[tfvars_file]}"
fi

if [ -f "${config[backend_config]}" ]; then
    log_info "${config[backend_config]} already exists, not overwriting" \
             "Terraform config"
else
    if [ "${CK8S_CLOUD_PROVIDER}" == "exoscale" ]; then
        export TERRAFORM_PREFIX="a1-demo-"
    elif [ "${CK8S_CLOUD_PROVIDER}" == "safespring" ]; then
        export TERRAFORM_PREFIX="safespring-demo-"
    elif [ "${CK8S_CLOUD_PROVIDER}" == "citycloud" ]; then
        export TERRAFORM_PREFIX="citycloud-"
    elif [ "${CK8S_CLOUD_PROVIDER}" == "aws" ]; then
        export TERRAFORM_PREFIX="aws-"
    else
        echo "ERROR: invalid name of CK8S_CLOUD_PROVIDER=${CK8S_CLOUD_PROVIDER}"
        exit 1
    fi
    cat "${config_defaults_path}/terraform/backend_config.hcl" \
        | envsubst > "${config[backend_config]}"
fi

#
# Terraform
#

log_info "Initializing Terraform remote workspace"

pushd "${terraform_path}/${CK8S_CLOUD_PROVIDER}" > /dev/null
echo '1' | TF_WORKSPACE="${CK8S_ENVIRONMENT_NAME}" terraform init -backend-config="${config[backend_config]}"
terraform workspace select "${CK8S_ENVIRONMENT_NAME}" || \
    terraform workspace new "${CK8S_ENVIRONMENT_NAME}"
popd > /dev/null
CLOUD_PROVIDER="${CK8S_CLOUD_PROVIDER}" ${scripts_path}/set-execution-mode.sh

log_info "Config initialized"

log_info "Time to edit the following files:"
log_info "${config[config_file]}"
log_info "${secrets[secrets_file]}"
log_info "${config[tfvars_file]}"
log_info "${config[backend_config]}"
