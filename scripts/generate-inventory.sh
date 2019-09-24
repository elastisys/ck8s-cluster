#!/bin/bash

set -e

if [[ "$#" -ne 1 ]]
then 
  >&2 echo "Usage: generate-inventory.sh <path-to-infra-file>"
  exit 1
fi

infra="$1"

sc_master_ip_addresses=($(cat $infra | jq -r '.service_cluster.master_ip_addresses[]'))
sc_worker_ip_addresses=($(cat $infra | jq -r '.service_cluster.worker_ip_addresses[]'))
sc_nfs_ip_address=$(cat $infra | jq -r '.service_cluster.nfs_ip_address')
wc_master_ip_addresses=($(cat $infra | jq -r '.workload_cluster.master_ip_addresses[]'))
wc_worker_ip_addresses=($(cat $infra | jq -r '.workload_cluster.worker_ip_addresses[]'))
wc_nfs_ip_address=$(cat $infra | jq -r '.workload_cluster.nfs_ip_address')

# TODO: Cheating by assuming same device path on both clusters for now
nfs_device_path=$(cat $infra | jq -r '.service_cluster.nfs_device_path')

for i in $(seq 0 $((${#sc_master_ip_addresses[@]} - 1))); do
cat <<EOF
[all]
sc_master${i} ansible_host=${sc_master_ip_addresses[${i}]}
EOF
done

for i in $(seq 0 $((${#sc_worker_ip_addresses[@]} - 1))); do
cat <<EOF
sc_worker${i} ansible_host=${sc_worker_ip_addresses[${i}]}
EOF
done

for i in $(seq 0 $((${#wc_master_ip_addresses[@]} - 1))); do
cat <<EOF
[all]
wc_master${i} ansible_host=${wc_master_ip_addresses[${i}]}
EOF
done

for i in $(seq 0 $((${#wc_worker_ip_addresses[@]} - 1))); do
cat <<EOF
wc_worker${i} ansible_host=${wc_worker_ip_addresses[${i}]}
EOF
done

cat <<EOF
[nfs]
sc_nfs ansible_host=${sc_nfs_ip_address}
wc_nfs ansible_host=${wc_nfs_ip_address}
[all:vars]
ansible_user=ubuntu
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
[nfs:vars]
internal_cidr_prefix=172.16.0.0/24
nfs_device_path=${nfs_device_path}
EOF
