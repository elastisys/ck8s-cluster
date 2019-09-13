#!/bin/bash

set -e

: "${ECK_SC_DOMAIN:?Missing ECK_SC_DOMAIN}"

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
cd ${SCRIPTS_PATH}/../
hosts=$(cat infra.json)

master_ip_address=$(echo ${hosts} | jq -r '.service_cluster.master_ip_address')
worker_ip_address=($(echo ${hosts} | jq -r '.service_cluster.worker_ip_addresses[]'))

cat <<EOF
cluster_name: eck-system-services

ssh_agent_auth: true

nodes:
  - address: ${master_ip_address}
    user: rancher
    role: [controlplane,etcd]
EOF
for i in $(seq 0 $((${#worker_ip_address[@]} - 1))); do
cat <<EOF
  - address: ${worker_ip_address[${i}]}
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
      oidc-issuer-url: https://dex.${ECK_SC_DOMAIN}
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
