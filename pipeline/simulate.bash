#!/bin/bash

# This script simulates an e2e pipeline run.
#
# Usage:
# ./simulate.bash <tfe organization> <environment name> [docker extra args... ]
#
# Pass extra arguments to docker run by passing them to this command. For
# example if you are using a Terraform credentials helper you could run:
# ./simulate.bash orgname pipeline-test -v ~/.terraform.d:/root/.terraform.d:ro

set -eu

: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"
: "${CK8S_PGP_FP:?Missing CK8S_PGP_FP}"
: "${EXOSCALE_KEY:?Missing EXOSCALE_KEY}"
: "${EXOSCALE_SECRET:?Missing EXOSCALE_SECRET}"

log_info() {
    echo -e "[\e[34mck8\e[0m]" "${@}" >&2
}

log_error() {
    echo -e "[\e[31mck8\e[0m]" "${@}" >&2
}

usage() {
  log_error "Usage: ${0} <tfe organization> <environment name> [<extra docker args>...]"
}

if [ $# -lt 2 ]; then
  usage
  exit 1
fi

TFE_ORGANIZATION=${1}
ENVIRONMENT_NAME=${2}
shift 2

GNUPGHOME="${GNUPGHOME:-${HOME}/.gnupg}"

if [ ! -d "${GNUPGHOME}" ]; then
    log_error "GnuPG home directory not found: ${GNUPGHOME}"
    log_error "Set \$GNUPGHOME to override."
    exit 1
fi

root="$(dirname "$(readlink -f "$0")")/.."

docker_name="ck8s-cluster-pipeline-simulation"
docker_image="ckctl:local"

docker build -t "${docker_image}" "${root}"

args=(
    -e CI_EXOSCALE_KEY="${EXOSCALE_KEY}"
    -e CI_EXOSCALE_SECRET="${EXOSCALE_SECRET}"
    -w /ck8s
    -v "${root}":/ck8s:ro
    -v "${CK8S_CONFIG_PATH}":/ck8s-config
    -v "${HOME}/.terraformrc":/root/.terraformrc:ro
    -v "${GNUPGHOME}":/root/.gnupg
    -e GNUPGHOME=/root/.gnupg
    -e GPG_TTY=/dev/pts/0
    -e CK8S_CONFIG_PATH=/ck8s-config
    -e CK8S_PGP_FP="${CK8S_PGP_FP}"
    -e CK8S_LOG_LEVEL="debug"
    "${@}"
)

docker run -d --name "${docker_name}" "${args[@]}" "${docker_image}" sleep 3600

trap 'docker stop "${docker_name}" && docker rm "${docker_name}"' EXIT

docker_exec() {
    docker exec -it "${docker_name}" "${@}"
}

docker_exec ./pipeline/init.bash "${ENVIRONMENT_NAME}" exoscale

config_update() {
    docker_exec \
        sed -i 's/'"${1}"'\(\s*\)=\(\s*\)'"${2}"'/'"${1}"'\1=\2"'"${3}"'"/' \
            "/ck8s-config/${4}"
}
config_update "organization" '""' "${TFE_ORGANIZATION}" "backend_config.hcl"

secrets_update() {
    docker_exec sops --set '["'"${1}"'"] "'"${2}"'"' /ck8s-config/secrets.yaml
}
secrets_update exoscale_api_key "${EXOSCALE_KEY}"
secrets_update exoscale_secret_key "${EXOSCALE_SECRET}"
secrets_update s3_access_key "${EXOSCALE_KEY}"
secrets_update s3_secret_key "${EXOSCALE_SECRET}"

whitelist_update() {
    if ! [[ $2 =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]; then
        echo "Invalid IP: $2"
        exit 1
    fi
    docker_exec \
        sed -i ':a;N;$!ba;s/\s*"'"${1}"'": \[[^]]*\]/"'"${1}"'": \["'"${2}"'\/32"\]/g' \
            /ck8s-config/tfvars.json
}
my_ip=$(curl ifconfig.me 2>/dev/null)
whitelist_update "public_ingress_cidr_whitelist" "$my_ip"
whitelist_update "api_server_whitelist" "$my_ip"
whitelist_update "nodeport_whitelist" "$my_ip"

docker_exec ./pipeline/apply.bash
docker_exec ./pipeline/e2e-tests.bash
docker_exec ./pipeline/destroy.bash
