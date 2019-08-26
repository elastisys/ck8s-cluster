#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

: "${ECK_SS_DOMAIN:?Missing ECK_SS_DOMAIN}"

cd ${SCRIPTS_PATH}/../terraform

tf_out=$(terraform output -json)

master_ip_address=$(echo ${tf_out} | jq -r '.ss_master_ip_address.value')
#master_internal_ip_addresses=$(echo ${tf_out} | jq -r \
#                               '.ss_master_internal_ip_address.value')

worker_ip_address=($(echo ${tf_out} | jq -r '.ss_worker_ip_addresses.value[]'))
#worker_internal_ip_addresses=($(echo ${tf_out} | jq -r \
#                               '.ss_worker_internal_ip_addresses.value[]'))

cat <<EOF
cluster_name: eck-system-services

ssh_agent_auth: true

nodes:
  - address: ${master_ip_address}
#    internal_address: ${master_internal_ip_addresses}
    user: rancher
    role: [controlplane,etcd]
EOF
for i in $(seq 0 $((${#worker_ip_address[@]} - 1))); do
cat <<EOF
  - address: ${worker_ip_address[${i}]}
#    internal_address: ${worker_internal_ip_addresses[${i}]}
    user: rancher
    role: [worker]
EOF
done
cat <<EOF

services:
  kube-api:
    pod_security_policy: true
    # Add additional arguments to the kubernetes API server
    # This WILL OVERRIDE any existing defaults
    extra_args:
      oidc-issuer-url: https://dex.${ECK_SS_DOMAIN}
      oidc-client-id: kubernetes
      oidc-username-claim: email
      oidc-groups-claim: groups
      # Enable audit log to stdout
      audit-log-path: "-"
      # Increase number of delete workers
      delete-collection-workers: 3
      # Set the level of log output to debug-level
      v: 4
      enable-admission-plugins: "NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,NodeRestriction,PodSecurityPolicy"

  etcd:
    snapshot: true
    creation: 6h
    retention: 24h

ingress:
  provider: "nginx"
  extra_args:
    enable-ssl-passthrough: ""
EOF
