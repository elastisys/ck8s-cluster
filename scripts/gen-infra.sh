#!/bin/bash

# Generates json infra from terraform output.

set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"

SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"

pushd "${SCRIPTS_PATH}/../terraform/${CLOUD_PROVIDER}/" > /dev/null
tf_out=$(terraform output -json)
popd > /dev/null

# Makes into cleaner infra format than terraform output

if [ $CLOUD_PROVIDER != "safespring" ]; then
    service=$(echo $tf_out | jq '{
        "worker_ip_addresses": .sc_worker_ip_addresses.value,
        "worker_private_ip_addresses": .sc_worker_private_ip_addresses.value,
        "master_ip_addresses": .sc_master_ip_addresses.value,
        "master_private_ip_addresses": .sc_master_private_ip_addresses.value,
        "nfs_ip_address": .sc_nfs_ip_address.value,
        "nfs_private_ip_address": .sc_nfs_private_ip_address.value,
        "nfs_device_path": .sc_nfs_device_path.value,
        "dns_name": .sc_dns_name.value,
        "domain_name": .domain_name.value,
        "worker_count": .sc_worker_ip_addresses.value | length,
        "master_count": .sc_master_ip_addresses.value | length}
        | {"service_cluster": values}')

    workload=$(echo $tf_out | jq '{
        "worker_ip_addresses": .wc_worker_ip_addresses.value,
        "worker_private_ip_addresses": .wc_worker_private_ip_addresses.value,
        "master_ip_addresses": .wc_master_ip_addresses.value,
        "master_private_ip_addresses": .wc_master_private_ip_addresses.value,
        "nfs_ip_address": .wc_nfs_ip_address.value,
        "nfs_private_ip_address": .wc_nfs_private_ip_address.value,
        "nfs_device_path": .wc_nfs_device_path.value,
        "dns_name": .wc_dns_name.value,
        "domain_name": .domain_name.value,
        "worker_count": .wc_worker_ip_addresses.value | length,
        "master_count": .wc_master_ip_addresses.value | length}
        | {"workload_cluster": values}')
else
    service=$(echo $tf_out | jq '{
        "worker_ip_addresses": .sc_worker_ips.value,
        "master_ip_addresses": .sc_master_ips.value,
        "nfs_ip_addresses": .sc_nfs_ips.value,
        "nfs_device_path": .sc_nfs_device_paths.value,
        "worker_device_path": .sc_worker_device_paths.value,
        "dns_name": .sc_dns_name.value,
        "domain_name": .domain_name.value,
        "worker_count": .sc_worker_ips.value | length,
        "master_count": .sc_master_ips.value | length}
        | {"service_cluster": values}')

    workload=$(echo $tf_out | jq '{
        "worker_ip_addresses": .wc_worker_ips.value,
        "master_ip_addresses": .wc_master_ips.value,
        "nfs_ip_addresses": .wc_nfs_ips.value,
        "nfs_device_path": .wc_nfs_device_paths.value,
        "worker_device_path": .wc_worker_device_paths.value,
        "dns_name": .wc_dns_name.value,
        "domain_name": .domain_name.value,
        "worker_count": .wc_worker_ips.value | length,
        "master_count": .wc_master_ips.value | length}
        | {"workload_cluster": values}')
fi


echo $workload $service | jq -s add
