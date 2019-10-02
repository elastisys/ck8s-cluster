#!/bin/bash

# Generates json infra from terraform output.

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"

pushd "${SCRIPTS_PATH}/../terraform/" > /dev/null
tf_out=$(terraform output -json)
popd > /dev/null

# Makes into cleaner infra format than terraform output

vault=$(echo $tf_out | jq '{
    "master_ip_addresses": .vault_master_ip_addresses.value,
    "nfs_ip_address": .vault_nfs_ip_address.value,
    "dns_name": .vault_dns_name.value}
    | {"vault_cluster": values}')

echo $vault | jq '.'
