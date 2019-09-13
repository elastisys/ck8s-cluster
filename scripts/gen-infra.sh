#!/bin/bash

# Generates infra.json from terraform output.

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"

cd "${SCRIPTS_PATH}/../terraform/"
tf_out=$(terraform output -json)
cd "${SCRIPTS_PATH}/../"

# Makes into cleaner infra format than terraform output

## count(s), should really not be nessecary to have.
## Length of ip addresses list should be enough.
## Keep here for now -> don't have to rewrite infra tests.

service=$(echo $tf_out | jq '{
    "worker_ip_addresses": .sc_worker_ip_addresses.value,
    "master_ip_address": .sc_master_ip_address.value,
    "nfs_ip_address": .sc_nfs_ip_address.value,
    "dns_name": .sc_dns_name.value,
    "worker_count": .sc_worker_count.value}
    | {"service_cluster": values}')

workload=$(echo $tf_out | jq '{
    "worker_ip_addresses": .wc_worker_ip_addresses.value,
    "master_ip_address": .wc_master_ip_address.value,
    "nfs_ip_address": .wc_nfs_ip_address.value,
    "dns_name": .wc_dns_name.value,
    "worker_count": .wc_worker_count.value}
    | {"workload_cluster": values}')

echo $workload $service | jq -s add > infra.json
