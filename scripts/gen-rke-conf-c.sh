#!/bin/sh

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
cd ${SCRIPTS_PATH}/../terraform/customer/

w1_ip=$(terraform output c-worker1-ip)
w2_ip=$(terraform output c-worker2-ip)
m_ip=$(terraform output c-master-ip)

cat <<EOF
cluster_name: eck-customer

# Change this path later
ssh_key_path: ~/.ssh/id_rsa

nodes:
  - address: $m_ip
    user: rancher
    role: [controlplane,etcd]
    labels:
      env: master
  - address: $w1_ip
    user: rancher
    role: [worker]
    labels:
      env: worker
  - address: $w2_ip
    user: rancher
    role: [worker]
    labels:
      env: worker

services:
  kube-api:
    pod_security_policy: true
    # Add additional arguments to the kubernetes API server
    # This WILL OVERRIDE any existing defaults
    extra_binds:
    # Adds file from node into docker container running api-server
      - "/home/rancher/admission-control-config.yaml:/etc/kubernetes/conf/admission-control-config.yaml"
      - "/home/rancher/podnodeselector.yaml:/etc/kubernetes/conf/podnodeselector.yaml"
    extra_args:
      # Enable audit log to stdout
      audit-log-path: "-"
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
EOF
