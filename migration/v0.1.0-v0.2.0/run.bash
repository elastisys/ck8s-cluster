#!/bin/bash

set -eu -o pipefail

: "${CK8S_CONFIG_PATH_OLD:?Missing CK8S_CONFIG_PATH_OLD}"
: "${CK8S_CONFIG_PATH_NEW:?Missing CK8S_CONFIG_PATH_NEW}"
: "${SOPS_PGP_FP:?Missing SOPS_PGP_FP}"
: "${TF_TOKEN:?Missing TF_TOKEN}"
: "${VAULT_TOKEN:?Missing VAULT_TOKEN}"

here="$(dirname "$(readlink -f "$0")")"
resources_path="${here}/resources"
bin_path="${here}/../../bin"
scripts_path="${here}/../../scripts"
config_defaults_path="${here}/../../config"

log_migration() {
    echo -e "\e[33mMIGRATION[\e[35mv0.1.0-v0.2.0\e[33m]\e[0m ${@}" >&2
}

check_old() {
    file="${CK8S_CONFIG_PATH_OLD}/${1}"
    log_migration "Checking existence of old config file: ${file}"
    if [ ! -f "${file}" ]; then
        echo "File in old config path not found: ${file}" >&2
        exit 1
    fi
}

migrate_file() {
    from="${CK8S_CONFIG_PATH_OLD}/${1}"
    to="${CK8S_CONFIG_PATH_NEW}/${2}"
    log_migration "Migrating ${from} -> ${to}"
    cp ${from} ${to}
}

encrypt() {
    file="${CK8S_CONFIG_PATH_NEW}/${1}"
    log_migration "Encrypting ${file}"
    sops -e -i "${file}"
}

check_old "config.sh"

check_old "variables.tfvars"

check_old "secrets/env/env.sh"

check_old "secrets/infra/infra.json"

check_old "secrets/customer/kubeconfig.yaml"

check_old "secrets/rke/eck-sc.rkestate"
check_old "secrets/rke/eck-sc.yaml"
check_old "secrets/rke/eck-wc.rkestate"
check_old "secrets/rke/eck-wc.yaml"
check_old "secrets/rke/kube_config_eck-sc.yaml"
check_old "secrets/rke/kube_config_eck-wc.yaml"

check_old "secrets/ssh-keys/id_rsa_sc"
check_old "secrets/ssh-keys/id_rsa_sc.pub"
check_old "secrets/ssh-keys/id_rsa_wc"
check_old "secrets/ssh-keys/id_rsa_wc.pub"

check_old "secrets/certs/service_cluster/kube-system/certs/ca-key.pem"
check_old "secrets/certs/service_cluster/kube-system/certs/ca.pem"
check_old "secrets/certs/service_cluster/kube-system/certs/helm-key.pem"
check_old "secrets/certs/service_cluster/kube-system/certs/helm.pem"
check_old "secrets/certs/service_cluster/kube-system/certs/tiller-key.pem"
check_old "secrets/certs/service_cluster/kube-system/certs/tiller.pem"

check_old "secrets/certs/workload_cluster/kube-system/certs/ca-key.pem"
check_old "secrets/certs/workload_cluster/kube-system/certs/ca.pem"
check_old "secrets/certs/workload_cluster/kube-system/certs/helm-key.pem"
check_old "secrets/certs/workload_cluster/kube-system/certs/helm.pem"
check_old "secrets/certs/workload_cluster/kube-system/certs/tiller-key.pem"
check_old "secrets/certs/workload_cluster/kube-system/certs/tiller.pem"

# Initialize new config

log_migration "Initializing new config path: ${CK8S_CONFIG_PATH_NEW}"

(
    source "${CK8S_CONFIG_PATH_OLD}/config.sh"

    CK8S_CONFIG_PATH="${CK8S_CONFIG_PATH_NEW}" \
    CK8S_CLOUD_PROVIDER="${CLOUD_PROVIDER}" \
    CK8S_ENVIRONMENT_NAME="${ENVIRONMENT_NAME}" \
        "${bin_path}/ck8s" init
)

# Migrate config.sh

log_migration "Migrating config"

(
    CK8S_VERSION="0.1.0"

    # Load old config

    source "${CK8S_CONFIG_PATH_OLD}/config.sh"
    source "${resources_path}/common-env.sh"
    source "${resources_path}/${CLOUD_PROVIDER}-common-env.sh"
    # Not sure if this is necessary, but this is done in old init.sh
    source "${CK8S_CONFIG_PATH_OLD}/config.sh"

    # Determine configuration options to migrate

    req_opts=$(cat "${config_defaults_path}/config/head.sh" \
                   "${config_defaults_path}/config/${CLOUD_PROVIDER}.sh" \
                   "${config_defaults_path}/config/tail.sh" | \
               egrep '^export [A-Za-z0-9_]+=' | sed 's/export \(.*\)=.*/\1/' | uniq)
    optin_opts=$(cat "${config_defaults_path}/config/head.sh" \
                    "${config_defaults_path}/config/${CLOUD_PROVIDER}.sh" \
                    "${config_defaults_path}/config/tail.sh" | \
                egrep '^# export [A-Za-z0-9_]+=' | sed 's/# export \(.*\)=.*/\1/' | uniq)

    # Truncate config.sh

    > "${CK8S_CONFIG_PATH_NEW}/config.sh"

    # Migrate required config options

    for opt in ${req_opts}; do
        set +u
        if [ -z "${!opt}" ]; then
            log_migration "ERROR: Missing ${opt} in old config"
            exit 1
        fi
        set -u
        echo "export ${opt}=\"${!opt}\"" >> "${CK8S_CONFIG_PATH_NEW}/config.sh"
    done

    # Migrate opt-in config options

    for opt in ${optin_opts}; do
        set +u
        if [ -z "${!opt}" ]; then
            log_migration "Old config does not specify '${opt}', skipping"
            continue
        fi
        set -u
        echo "export ${opt}=\"${!opt}\"" >> "${CK8S_CONFIG_PATH_NEW}/config.sh"
    done
)

# Migrate secrets.env

log_migration "Migrating secrets"

(
    source "${CK8S_CONFIG_PATH_OLD}/config.sh"

    # Load default secrets

    source "${config_defaults_path}/secrets/secrets.env"
    source "${config_defaults_path}/secrets/${CLOUD_PROVIDER}.env"

    # Load old secrets

    source "${CK8S_CONFIG_PATH_OLD}/secrets/env/env.sh"
    source "${resources_path}/get-gen-secrets.sh"

    # Make sure SLACK_API_URL was explicitly set in old config.
    set +u
    if [ "${ALERT_TO}" = "slack" ] && [ -z "${SLACK_API_URL}" ]; then
        log_migration \
            "ERROR: ALERT_TO=slack but SLACK_API_URL not set in old config"
        exit 1
    fi
    set -u

    # Determine configuration options to migrate

    req_opts=$(cat "${config_defaults_path}/secrets/${CLOUD_PROVIDER}.env" \
                   "${config_defaults_path}/secrets/secrets.env" | \
               egrep '^[A-Za-z0-9_]+=' | sed 's/\(.*\)=.*/\1/' | uniq)
    optin_opts=$(cat "${config_defaults_path}/secrets/${CLOUD_PROVIDER}.env" \
                    "${config_defaults_path}/secrets/secrets.env" | \
                egrep '^# [A-Za-z0-9_]+=' | sed 's/# \(.*\)=.*/\1/' | uniq)

    # Truncate secrets.env

    > "${CK8S_CONFIG_PATH_NEW}/secrets.env"

    # Migrate required secrets

    for opt in ${req_opts}; do
        set +u
        if [ -z "${!opt}" ]; then
            log_migration "ERROR: Missing ${opt} in old secrets env"
            exit 1
        fi
        set -u
        echo "${opt}=${!opt}" >> "${CK8S_CONFIG_PATH_NEW}/secrets.env"
    done

    # Migrate opt-in secrets

    for opt in ${optin_opts}; do
        set +u
        if [ -z "${!opt}" ]; then
            log_migration "Old secrets env does not specify '${opt}', skipping"
            continue
        fi
        set -u
        echo "${opt}=${!opt}" >> "${CK8S_CONFIG_PATH_NEW}/secrets.env"
    done

    # Encrypt secrets.env

    encrypt secrets.env
)

# Migrate SSH keys

log_migration "Migrating SSH keys"

migrate_file secrets/ssh-keys/id_rsa_sc ssh
migrate_file secrets/ssh-keys/id_rsa_sc.pub ssh
migrate_file secrets/ssh-keys/id_rsa_wc ssh
migrate_file secrets/ssh-keys/id_rsa_wc.pub ssh
encrypt ssh/id_rsa_sc
encrypt ssh/id_rsa_wc

# Migrate Helm certificates

log_migration "Migrating Helm secrets"

migrate_file secrets/certs/service_cluster/kube-system/certs/ca-key.pem \
    certs/service_cluster/kube-system/certs
migrate_file secrets/certs/service_cluster/kube-system/certs/ca.pem \
    certs/service_cluster/kube-system/certs
migrate_file secrets/certs/service_cluster/kube-system/certs/helm-key.pem \
    certs/service_cluster/kube-system/certs
migrate_file secrets/certs/service_cluster/kube-system/certs/helm.pem \
    certs/service_cluster/kube-system/certs
migrate_file secrets/certs/service_cluster/kube-system/certs/tiller-key.pem \
    certs/service_cluster/kube-system/certs
migrate_file secrets/certs/service_cluster/kube-system/certs/tiller.pem \
    certs/service_cluster/kube-system/certs

encrypt certs/service_cluster/kube-system/certs/ca-key.pem
encrypt certs/service_cluster/kube-system/certs/helm-key.pem
encrypt certs/service_cluster/kube-system/certs/tiller-key.pem

migrate_file secrets/certs/workload_cluster/kube-system/certs/ca-key.pem \
    certs/workload_cluster/kube-system/certs
migrate_file secrets/certs/workload_cluster/kube-system/certs/ca.pem \
    certs/workload_cluster/kube-system/certs
migrate_file secrets/certs/workload_cluster/kube-system/certs/helm-key.pem \
    certs/workload_cluster/kube-system/certs
migrate_file secrets/certs/workload_cluster/kube-system/certs/helm.pem \
    certs/workload_cluster/kube-system/certs
migrate_file secrets/certs/workload_cluster/kube-system/certs/tiller-key.pem \
    certs/workload_cluster/kube-system/certs
migrate_file secrets/certs/workload_cluster/kube-system/certs/tiller.pem \
    certs/workload_cluster/kube-system/certs

encrypt certs/workload_cluster/kube-system/certs/ca-key.pem
encrypt certs/workload_cluster/kube-system/certs/helm-key.pem
encrypt certs/workload_cluster/kube-system/certs/tiller-key.pem

# Migrate RKE state

log_migration "Migrating rke state"

migrate_file secrets/rke/eck-sc.rkestate .state/rke_sc.rkestate
migrate_file secrets/rke/eck-wc.rkestate .state/rke_wc.rkestate
migrate_file secrets/rke/eck-sc.yaml .state/rke_sc.yaml
migrate_file secrets/rke/eck-wc.yaml .state/rke_wc.yaml
migrate_file secrets/rke/kube_config_eck-sc.yaml .state/kube_config_rke_sc.yaml
migrate_file secrets/rke/kube_config_eck-wc.yaml .state/kube_config_rke_wc.yaml

encrypt .state/rke_sc.rkestate
encrypt .state/rke_wc.rkestate
encrypt .state/rke_sc.yaml
encrypt .state/rke_wc.yaml
encrypt .state/kube_config_rke_sc.yaml
encrypt .state/kube_config_rke_wc.yaml

# Migrate customer kubeconfig

log_migration "Migrating customer kubeconfig"

migrate_file secrets/customer/kubeconfig.yaml customer
encrypt customer/kubeconfig.yaml

# Migrate infra.json

log_migration "Migrating infra.json"

migrate_file secrets/infra/infra.json .state

# Migrate Terraform config

log_migration "Migrating Terraform config"

migrate_file variables.tfvars config.tfvars

log_migration "SUCCESS!"
