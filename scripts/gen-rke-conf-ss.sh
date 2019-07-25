#!/bin/sh

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
cd ${SCRIPTS_PATH}/../terraform/system-services/

w1_ip=$(terraform output ss-worker1-ip)
w2_ip=$(terraform output ss-worker2-ip)
m_ip=$(terraform output ss-master-ip)

cat <<EOF
cluster_name: eck-system-services

# Change this path later
<<<<<<< HEAD
<<<<<<< HEAD
ssh_key_path: ~/.ssh/id_rsa
=======
ssh_key_path: ~/.ssh/exoscale
>>>>>>> 44c6463... psp and dashboard test
=======
ssh_key_path: ~/.ssh/id_rsa
>>>>>>> 0e22144... Added dashboard to customer

nodes:
  - address: $m_ip
    user: rancher
    role: [controlplane,etcd]
  - address: $w1_ip
    user: rancher
    role: [worker]
  - address: $w2_ip
    user: rancher
    role: [worker]

services:
  kube-api:
    pod_security_policy: true
    # Add additional arguments to the kubernetes API server
    # This WILL OVERRIDE any existing defaults
    extra_args:
      oidc-issuer-url: https://dex.compliantk8s.com
      oidc-client-id: test-app
      oidc-ca-file: /etc/kubernetes/ssl/dex-ca.pem
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
