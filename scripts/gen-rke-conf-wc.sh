#!/bin/bash

set -e

: "${ECK_SC_DOMAIN:?Missing ECK_SC_DOMAIN}"

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
cd ${SCRIPTS_PATH}/../
hosts=$(cat infra.json)

master_ip_address=$(echo ${hosts} | jq -r '.workload_cluster.master_ip_address')
worker_ip_address=($(echo ${hosts} | jq -r '.workload_cluster.worker_ip_addresses[]'))

cat <<EOF
cluster_name: eck-customer

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
    extra_binds:
    # Adds file from node into docker container running api-server
      - "/etc/kubernetes/conf:/etc/kubernetes/conf"
      - "/var/log/kube-audit:/var/log/kube-audit"
    extra_args:
      oidc-issuer-url: https://dex.${ECK_SC_DOMAIN}
      oidc-client-id: kubernetes
      oidc-username-claim: email
      oidc-groups-claim: groups
      audit-policy-file: "/etc/kubernetes/conf/audit-policy.yaml"
      audit-log-path: "/var/log/kube-audit/kube-apiserver.log"
      # Increase number of delete workers
      delete-collection-workers: 3
      # Set the level of log output to debug-level
      v: 4
      # Enables PodTolerationRestriction and PodNodeSelector admission plugin in apiserver
      enable-admission-plugins: "PodTolerationRestriction,PodNodeSelector,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,NodeRestriction,PodSecurityPolicy,PodSecurityPolicy"
      admission-control-config-file: "/etc/kubernetes/conf/admission-control-config.yaml"

  etcd:
    snapshot: true
    creation: 6h
    retention: 24h

ingress:
  provider: "nginx"
  extra_args:
    enable-ssl-passthrough: ""

private_registries:
    - url: harbor.${ECK_SC_DOMAIN}
      user: admin
      password: Harbor12345
EOF
