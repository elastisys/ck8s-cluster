#!/bin/bash

set -e

: "${ECK_SC_DOMAIN:?Missing ECK_SC_DOMAIN}"
: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"

if [ $CLOUD_PROVIDER == "safespring" ] || [ $CLOUD_PROVIDER == "citycloud" ]
then
: "${OS_USERNAME:?Missing OS_USERNAME}"
: "${OS_PASSWORD:?Missing OS_PASSWORD}"
: "${OS_AUTH_URL:?Missing OS_AUTH_URL}"
: "${OS_PROJECT_ID:?Missing OS_PROJECT_ID}"
: "${OS_USER_DOMAIN_NAME:?Missing OS_USER_DOMAIN_NAME}"
fi

if [[ "$#" -ne 1 ]]
then 
  >&2 echo "Usage: gen-rke-conf-wc.sh <path-to-infra-file>"
  exit 1
fi

infra="$1"

# If unset -> true
ENABLE_PSP=${ENABLE_PSP:-true}

# Use default harbor password if not set.
HARBOR_PWD=${HARBOR_PWD:-"Harbor12345"}

master_ip_addresses=($(cat $infra | jq -r '.workload_cluster.master_ip_addresses[]'))
worker_ip_addresses=($(cat $infra | jq -r '.workload_cluster.worker_ip_addresses[]'))

if [ $CLOUD_PROVIDER == "safespring" ] || [ $CLOUD_PROVIDER == "citycloud" ]
then
  master_private_ip_addresses=($(cat $infra | jq -r '.workload_cluster.master_private_ip_addresses[]'))
  worker_private_ip_addresses=($(cat $infra | jq -r '.workload_cluster.worker_private_ip_addresses[]'))
fi

cat <<EOF
cluster_name: eck-workload_cluster

ssh_agent_auth: true

nodes:
EOF

for i in $(seq 0 $((${#master_ip_addresses[@]} - 1)))
do
cat <<EOF
  - address: ${master_ip_addresses[${i}]}
    role: [controlplane,etcd]
EOF
if [ $CLOUD_PROVIDER == "exoscale" ]
then
cat <<EOF
    user: rancher
EOF
elif [ $CLOUD_PROVIDER == "safespring" ] || [ $CLOUD_PROVIDER == "citycloud" ]
then
cat <<EOF
    user: ubuntu
    internal_address: ${master_private_ip_addresses[${i}]}
EOF
fi
done

for i in $(seq 0 $((${#worker_ip_addresses[@]} - 1)))
do
cat <<EOF
  - address: ${worker_ip_addresses[${i}]}
    role: [worker]
EOF
if [ $CLOUD_PROVIDER == "exoscale" ]
then
cat <<EOF
    user: rancher
EOF
elif [ $CLOUD_PROVIDER == "safespring" ] || [ $CLOUD_PROVIDER == "citycloud" ]
then
cat <<EOF
    user: ubuntu
    internal_address: ${worker_private_ip_addresses[${i}]}
EOF
fi
done

cat <<EOF

services:
  kube-api:
EOF

if [[ $ENABLE_PSP == "true" ]]
then
cat <<EOF
    pod_security_policy: true
EOF
else
cat <<EOF
    pod_security_policy: false
EOF
fi

cat <<EOF
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
      admission-control-config-file: "/etc/kubernetes/conf/admission-control-config.yaml"
EOF

if [[ $ENABLE_PSP == "true" ]]
then
cat <<EOF 
      # Enables PodTolerationRestriction, PodNodeSelector, and PSP admission plugin in apiserver
      enable-admission-plugins: "PodTolerationRestriction,PodNodeSelector,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,NodeRestriction,PodSecurityPolicy"
EOF
else
cat <<EOF
      # Enables PodTolerationRestriction and PodNodeSelector admission plugin in apiserver
      enable-admission-plugins: "PodTolerationRestriction,PodNodeSelector,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,NodeRestriction"
EOF
fi


cat <<EOF

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
      password: ${HARBOR_PWD}
EOF

if [ $CLOUD_PROVIDER == "safespring" ] || [ $CLOUD_PROVIDER == "citycloud" ]
then
cat <<EOF
cloud_provider:
  name: openstack
  openstackCloudProvider:
    global:
      username: ${OS_USERNAME}
      password: ${OS_PASSWORD}
      auth-url: ${OS_AUTH_URL}
      tenant-id: ${OS_PROJECT_ID}
      domain-name: ${OS_USER_DOMAIN_NAME}
EOF
fi
