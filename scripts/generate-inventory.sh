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

if [ "${CLOUD_PROVIDER}" = "safespring" ]
then
  sc_loadbalancers=$(echo $infra | jq -r '.service_cluster.loadbalancer_ip_addresses | keys[]')
  wc_loadbalancers=$(echo $infra | jq -r '.workload_cluster.loadbalancer_ip_addresses | keys[]')
fi

function print_ansible_hosts {
  type="$1"
  cluster="$2"
  shift;shift
  instances="$@"

  for instance in ${instances[@]}; do

cat <<EOF
$instance ansible_host=$(echo $infra | jq -r '.'"${cluster}"'.'"${type}"'_ip_addresses."'"${instance}"'".public_ip') \
private_ip=$(echo $infra | jq -r '.'"${cluster}"'.'"${type}"'_ip_addresses."'"${instance}"'".private_ip')
EOF

  done
}

echo "[sc_masters]"
print_ansible_hosts master service_cluster ${sc_masters[@]}
echo "[sc_workers]"
print_ansible_hosts worker service_cluster ${sc_workers[@]}

echo "[wc_masters]"
print_ansible_hosts master workload_cluster ${wc_masters[@]}
echo "[wc_workers]"
print_ansible_hosts worker workload_cluster ${wc_workers[@]}

cat <<EOF
[extra_volume]
EOF

print_ansible_hosts worker service_cluster ${sc_workers_extra_volume[@]}
print_ansible_hosts worker workload_cluster ${wc_workers_extra_volume[@]}

if [ "${CLOUD_PROVIDER}" = "safespring" ]
then
  echo "[wc_loadbalancers]"
  echo "$(print_ansible_hosts loadbalancer workload_cluster ${wc_loadbalancers[@]})"

  echo "[sc_loadbalancers]"
  echo "$(print_ansible_hosts loadbalancer service_cluster ${sc_loadbalancers[@]})"
fi

cat <<EOF
[all:vars]
ansible_user=ubuntu
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
