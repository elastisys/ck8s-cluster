#!/bin/bash

set -e

: "${ECK_OPS_DOMAIN:?Missing ECK_OPS_DOMAIN}"
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

infra=$(cat "$1")

# If unset -> true
ENABLE_PSP=${ENABLE_PSP:-true}

# Get list of master and worker instance names.
masters=$(echo $infra | jq -r '.workload_cluster.master_ip_addresses | keys[]')
workers=$(echo $infra | jq -r '.workload_cluster.worker_ip_addresses | keys[]')

cat <<EOF
cluster_name: ${ENVIRONMENT_NAME}_${CLOUD_PROVIDER}_wc

ssh_agent_auth: true

kubernetes_version: $KUBERNETES_VERSION

nodes:
EOF

# Add master nodes.
for instance in ${masters[@]}; do
cat <<EOF
  - address: $(echo $infra | jq -r '.workload_cluster.master_ip_addresses."'"${instance}"'".public_ip')
    role: [controlplane,etcd]
    hostname_override: $instance
EOF

if [ $CLOUD_PROVIDER == "exoscale" ]
then
cat <<EOF
    user: rancher
EOF
else
cat <<EOF
    user: ubuntu
    internal_address: $(echo $infra | jq -r '.workload_cluster.master_ip_addresses."'"${instance}"'".private_ip')
EOF
fi
done

# Add worker nodes.
for instance in ${workers[@]}; do
cat <<EOF
  - address: $(echo $infra | jq -r '.workload_cluster.worker_ip_addresses."'"${instance}"'".public_ip')
    role: [worker]
    hostname_override: $instance
EOF

if [ $CLOUD_PROVIDER == "exoscale" ]
then
cat <<EOF
    user: rancher
EOF
else
cat <<EOF
    user: ubuntu
    internal_address: $(echo $infra | jq -r '.workload_cluster.worker_ip_addresses."'"${instance}"'".private_ip')
EOF
fi
done

cat <<EOF

services:
EOF

if (( $(echo $infra | jq -r '.workload_cluster.worker_device_path | length') > 0 ))
then
cat <<EOF
  kubelet:
    extra_binds:
      - /mnt/disks:/mnt/disks
EOF
fi

cat <<EOF
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
      oidc-issuer-url: https://dex.${ECK_BASE_DOMAIN}
      oidc-client-id: kubelogin
      oidc-username-claim: email
      oidc-groups-claim: groups
      audit-policy-file: "/etc/kubernetes/conf/audit-policy.yaml"
      audit-log-path: "/var/log/kube-audit/kube-apiserver.log"
      # Increase number of delete workers
      delete-collection-workers: 3
      # Set the level of log output to debug-level
      v: 4
      # Set max age for audit logs
      audit-log-maxage: 7
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
    provider: none
EOF

if [ "$ENABLE_HARBOR" == "true" ];
then
cat <<EOF

private_registries:
    - url: harbor.${ECK_BASE_DOMAIN}
      user: admin
      password: ${HARBOR_PWD}
EOF
fi

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
