#!/bin/bash

set -eu

here="$(dirname "$(readlink -f "$0")")"

source "${here}/common.bash"

usage() {
    echo "Usage: <sc|wc> <master-#|worker-#|nfs> [cmd]" >&2
    exit 1
}

[ ${#} -lt 2 ] && usage

config_load

hostname="${ENVIRONMENT_NAME}"

case "${1}" in
    sc)
        cluster=service_cluster
        hostname+="-service-cluster"
        ssh_key="${secrets[ssh_priv_key_sc]}"
    ;;
    wc)
        cluster=workload_cluster
        hostname+="-workload-cluster"
        ssh_key="${secrets[ssh_priv_key_wc]}"
    ;;
    *) usage ;;
esac

shopt -s extglob
case "${2}" in
    master-+([0-9]))
        hostname+="-${2}"
        json_path=".${cluster}.master_ip_addresses[\"${hostname}\"].public_ip"
    ;;
    worker-+([0-9]))
        hostname+="-${2}"
        json_path=".${cluster}.worker_ip_addresses[\"${hostname}\"].public_ip"
    ;;
    nfs)
        json_path=".${cluster}.nfs_ip_addresses"
    ;;
    *) usage ;;
esac

case "${2}" in
    master-+([0-9])) ;&
    worker-+([0-9]))
        case "${CLOUD_PROVIDER}" in
            exoscale) user=rancher ;;
            safespring) user=ubuntu ;;
            citycloud) user=ubuntu ;;
        esac
    ;;
    nfs) user=ubuntu ;;
esac
shopt -u extglob

shift 2

ip=$(cat ${config[infrastructure_file]} | jq -r "${json_path}")

if [ "${ip}" = "null" ]; then
    log_error "Machine not found in infrastructure file"
    log_error "JSONPath: ${json_path}"
    exit 1
fi

with_ssh_agent "${ssh_key}" ssh "${user}@${ip}" ${@}
