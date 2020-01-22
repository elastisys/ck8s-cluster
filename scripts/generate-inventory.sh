#!/bin/bash

set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"

if [[ "$#" -ne 1 ]]
then 
  >&2 echo "Usage: generate-inventory.sh <path-to-infra-file>"
  exit 1
fi

infra=$(cat "$1")

sc_workers_extra_volume=$(echo $infra | jq -r '.service_cluster.worker_device_path | keys[]')
sc_masters=$(echo $infra | jq -r '.service_cluster.master_ip_addresses | keys[]')
sc_workers=$(echo $infra | jq -r '.service_cluster.worker_ip_addresses | keys[]')

wc_workers_extra_volume=$(echo $infra | jq -r '.workload_cluster.worker_device_path | keys[]')
wc_masters=$(echo $infra | jq -r '.workload_cluster.master_ip_addresses | keys[]')
wc_workers=$(echo $infra | jq -r '.workload_cluster.worker_ip_addresses | keys[]')

function print_ansible_hosts {
  type="$1"
  cluster="$2"
  shift;shift
  instances="$@"

  for instance in ${instances[@]}; do

cat <<EOF
$instance ansible_host=$(echo $infra | jq -r '.'"${cluster}"'.'"${type}"'_ip_addresses."'"${instance}"'".public_ip')
EOF

  done
}

cat <<EOF
[all]
EOF

print_ansible_hosts master service_cluster ${sc_masters[@]}
print_ansible_hosts worker service_cluster ${sc_workers[@]}

cat <<EOF
[all]
EOF

print_ansible_hosts master workload_cluster ${wc_masters[@]}
print_ansible_hosts worker workload_cluster ${wc_workers[@]}

cat <<EOF
[extra_volume]
EOF

print_ansible_hosts worker service_cluster ${sc_workers_extra_volume[@]}
print_ansible_hosts worker workload_cluster ${wc_workers_extra_volume[@]}

cat <<EOF
[all:vars]
ansible_user=ubuntu
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF