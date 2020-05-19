#!/bin/bash

set -eu

here="$(dirname "$(readlink -f "$0")")"

source "${here}/common.bash"

usage() {
    echo "Usage: <sc|wc> <<master|worker> MACHINE_NAME|nfs> [cmd]" >&2
    exit 1
}

[ ${#} -lt 2 ] && usage

config_load

prefix=$(cat ${config[tfvars_file]} | grep prefix_${1} | awk '{print $3}')
if [ "${prefix}" = '""' ]; then
    hostname="${ENVIRONMENT_NAME}"
    case "${1}" in
        sc) hostname+="-service-cluster" ;;
        wc) hostname+="-workload-cluster" ;;
    esac
else
    hostname=${prefix//\"/}
fi

case "${1}" in
    sc)
        cluster=service_cluster
        ssh_key="${secrets[ssh_priv_key_sc]}"
        user=ubuntu
    ;;
    wc)
        cluster=workload_cluster
        ssh_key="${secrets[ssh_priv_key_wc]}"
        user=ubuntu
    ;;
    *) usage ;;
esac

shopt -s extglob
case "${2}" in
    master)
        [ ${#} -lt 3 ] && usage
        hostname+="-${3}"
        json_path=".${cluster}.master_ip_addresses[\"${hostname}\"].public_ip"
        shift 3
    ;;
    worker)
        [ ${#} -lt 3 ] && usage
        hostname+="-${3}"
        json_path=".${cluster}.worker_ip_addresses[\"${hostname}\"].public_ip"
        shift 3
    ;;
    nfs)
        json_path=".${cluster}.nfs_ip_addresses[\"nfs\"].public_ip"
        shift 2
    ;;
    *) usage ;;
esac

shopt -u extglob


ip=$(cat ${config[infrastructure_file]} | jq -r "${json_path}")

if [ "${ip}" = "null" ]; then
    log_error "Machine not found in infrastructure file"
    log_error "JSONPath: ${json_path}"
    exit 1
fi

with_ssh_agent "${ssh_key}" ssh "${user}@${ip}" ${@}
