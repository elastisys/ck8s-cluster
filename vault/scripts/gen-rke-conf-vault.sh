#!/bin/bash

set -e

if [[ "$#" -ne 1 ]]
then 
  >&2 echo "Usage: gen-rke-conf-vault.sh <path-to-infra-file>"
  exit 1
fi

infra="$1"

master_ip_addresses=($(cat $infra | jq -r '.vault_cluster.master_ip_addresses[]'))

cat <<EOF
cluster_name: eck-vault_cluster

ssh_agent_auth: true

nodes:
EOF

for i in $(seq 0 $((${#master_ip_addresses[@]} - 1)))
do
cat <<EOF
  - address: ${master_ip_addresses[${i}]}
    role: [controlplane,etcd,worker]
    user: rancher
EOF
done

cat <<EOF

services:
  kube-api:
    pod_security_policy: false
    # Add additional arguments to the kubernetes API server
    # This WILL OVERRIDE any existing defaults
    extra_binds:
    # Adds file from node into docker container running api-server
      - "/etc/kubernetes/conf:/etc/kubernetes/conf"
    extra_args:
      # Increase number of delete workers
      delete-collection-workers: 3
      # Set the level of log output to debug-level
      v: 4
      enable-admission-plugins: "NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,NodeRestriction"

  etcd:
    snapshot: true
    creation: 6h
    retention: 24h

ingress:
  provider: "nginx"
  extra_args:
    enable-ssl-passthrough: ""
EOF
