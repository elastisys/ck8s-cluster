#!/bin/bash

# This script simulates the e2e step in a pipeline run.

# This requires you to have a valid terraform token in ~/.terraformrc
# It also requires a pinentry program that is console based (e.g.
# pinentry-dmenue will not work).
#
# Usage is following:
# ./simulate.bash <environment name> [docker extra args... ]
#
# Pass extra arguments to docker run by passing them to this command. For
# example if you are using a Terraform credentials helper you could run:
# ./simulate.bash pipeline-simulation -v ~/.terraform.d:/root/.terraform.d:ro

set -eu

: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"
: "${CK8S_PGP_FP:?Missing CK8S_PGP_FP}"
: "${EXOSCALE_KEY:?Missing EXOSCALE_KEY}"
: "${EXOSCALE_SECRET:?Missing EXOSCALE_SECRET}"

log_info() {
    echo -e "[\e[34mck8\e[0m] ${@}" >&2
}

log_error() {
    echo -e "[\e[31mck8\e[0m] ${@}" >&2
}

usage() {
  log_error "Usage: ${0} <environment name> [<extra docker args>...]"
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

ENVIRONMENT_NAME=${1}
shift

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
    -e GPG_TTY=/dev/pts/0 # TODO Does this work every time? Maybe try programatically figure this out
    -e CK8S_CONFIG_PATH=/ck8s-config
    -e CK8S_PGP_FP="${CK8S_PGP_FP}"
    -e CK8S_LOG_LEVEL="debug"
    ${@}
)

docker run -d --name "${docker_name}" ${args[@]} "${docker_image}" sleep 3600

trap 'docker stop "${docker_name}" && docker rm "${docker_name}"' EXIT

docker_exec() {
    docker exec -it "${docker_name}" ${@}
}

docker_exec ckctl init ${ENVIRONMENT_NAME} exoscale
docker_exec ./pipeline/configure.bash
docker_exec ckctl apply --cluster sc
docker_exec ckctl apply --cluster wc
docker_exec ckctl status --cluster sc
docker_exec ckctl status --cluster wc
docker_exec ./pipeline/e2e-tests.bash
docker_exec ckctl destroy --cluster wc
docker_exec ckctl destroy --cluster sc --destroy-remote-workspace
