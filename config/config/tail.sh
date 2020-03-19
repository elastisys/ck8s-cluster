
# One of staging and prod
export CERT_TYPE="staging"

export S3_HARBOR_BUCKET_NAME="${CK8S_ENVIRONMENT_NAME}-harbor"
export S3_VELERO_BUCKET_NAME="${CK8S_ENVIRONMENT_NAME}-velero"
export S3_ES_BACKUP_BUCKET_NAME="${CK8S_ENVIRONMENT_NAME}-es-backup"
export S3_INFLUX_BUCKET_NAME="${CK8S_ENVIRONMENT_NAME}-influxdb"
export S3_SC_FLUENTD_BUCKET_NAME="${CK8S_ENVIRONMENT_NAME}-sc-logs"

export ENABLE_HARBOR="true"
export ENABLE_FALCO="true"
export ENABLE_PSP="true"
export ENABLE_OPA="true"
export ENABLE_CUSTOMER_GRAFANA="true"
export ENABLE_CUSTOMER_ALERTMANAGER="false"
export ENABLE_CUSTOMER_ALERTMANAGER_INGRESS="false"
export ENABLE_POSTGRESQL="false"
export ENABLE_CK8SDASH_SC="true"
export ENABLE_CK8SDASH_WC="true"

export CUSTOMER_NAMESPACES="demo1 demo2 demo3"
export CUSTOMER_ADMIN_USERS="admin1@elastisys.com admin2@elastisys.com"

# IP of the cluster DNS in kubernetes (needed for node-local-dns)
export CLUSTER_DNS="10.96.0.10"

# One of opsgenie, slack or null
export ALERT_TO="null"
# Use opsgenie heartbeat feature
# TODO: Rename to OPSGENIE_HEARTBEAT_ENABLED
export ENABLE_HEARTBEAT="false"
# required if heartbeat enabled, no default
# export OPSGENIE_HEARTBEAT_NAME=name-of-heartbeat

# Only emails with these domains are allowed to login through Dex.
export OAUTH_ALLOWED_DOMAINS="elastisys.com"
# Create a static dex user "admin@example.com"
export ENABLE_STATIC_DEX_LOGIN="false"

# If set to "true", set nginx-ingress external traffic policy to "Local".
# Must be "true" for IP whitelisting to work.
export EXTERNAL_TRAFFIC_POLICY_LOCAL="false"

# Global NGINX IP whitelist
# If you enable this, make sure to set EXTERNAL_TRAFFIC_POLICY_LOCAL to "true".
# Comma-separated list of CIDRs.
# https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#whitelist-source-range
# Note that elasticsearch must allow traffic from all nodes in the workload
# cluster in order to get logs from fluentd. Prometheus in the workload cluster
# must allow traffic from the service cluster so that metrics can be federated.
#export GLOBAL_WHITELIST_SOURCE_RANGE="0.0.0.0/0"
# Service-specific IP whitelists.
# Overrides the global whitelist.
#export CK8SDASH_SC_WHITELIST_SOURCE_RANGE="$GLOBAL_WHITELIST_SOURCE_RANGE,0.0.0.0/0"
#export CK8SDASH_wC_WHITELIST_SOURCE_RANGE="$GLOBAL_WHITELIST_SOURCE_RANGE,0.0.0.0/0"
#export DEX_WHITELIST_SOURCE_RANGE="$GLOBAL_WHITELIST_SOURCE_RANGE,0.0.0.0/0"
#export KIBANA_WHITELIST_SOURCE_RANGE="$GLOBAL_WHITELIST_SOURCE_RANGE,0.0.0.0/0"
#export ELASTICSEARCH_WHITELIST_SOURCE_RANGE="$GLOBAL_WHITELIST_SOURCE_RANGE,0.0.0.0/0"
#export HARBOR_WHITELIST_SOURCE_RANGE="$GLOBAL_WHITELIST_SOURCE_RANGE,0.0.0.0/0"
#export CUSTOMER_GRAFANA_WHITELIST_SOURCE_RANGE="$GLOBAL_WHITELIST_SOURCE_RANGE,0.0.0.0/0"
#export GRAFANA_OPS_WHITELIST_SOURCE_RANGE="$GLOBAL_WHITELIST_SOURCE_RANGE,0.0.0.0/0"
#export PROMETHEUS_WC_WHITELIST_SOURCE_RANGE="$GLOBAL_WHITELIST_SOURCE_RANGE,0.0.0.0/0"

export INFLUXDB_USER="admin"
# Influx cronjob backup variables.
# TODO: Does this really need to be configurable?
export INFLUX_ADDR="influxdb.influxdb-prometheus.svc:8088"
# Retention policy for influxdb workload cluster database
export INFLUXDB_RETENTION_WC="7d"
# Retention policy for influxdb service cluster database
export INFLUXDB_RETENTION_SC="3d"

# TODO: Prefix these variables with ES/ELASTICSEARCH
export ES_NODE_COUNT="2"

# SIZE in GB when auditlogs should be removed for index 'kubeaudit'
export KUBEAUDIT_RETENTION_SIZE="100"
# AGE in days when auditlogs should be removed for index 'kubeaudit'
export KUBEAUDIT_RETENTION_AGE="30"
# SIZE in GB when api-server logs should be removed for index 'kubecomponents'
export KUBECOMPONENTS_RETENTION_SIZE="10"
# AGE in days when api-server logs should be removed for index 'kubecomponents'
export KUBECOMPONENTS_RETENTION_AGE="10"
# SIZE in GB when kubernetes container logs should be removed for index 'kubernetes'
export KUBERNETES_RETENTION_SIZE="50"
# AGE in days when kubernetes container  logs should be removed for index 'kubernetes'
export KUBERNETES_RETENTION_AGE="30"
# SIZE in GB when other logs should be removed for index 'other'
export OTHER_RETENTION_SIZE="10"
# AGE in days when other logs should be removed for index 'other'
export OTHER_RETENTION_AGE="30"
# SIZE in GB when other logs should be removed for index 'postgresql'
export POSTGRESQL_RETENTION_SIZE="30"
# AGE in days when other logs should be removed for index 'postgresql'
export POSTGRESQL_RETENTION_AGE="30"
# SIZE in GB when indices should perform rollover
export ROLLOVER_SIZE="1"
# AGE in days when indices should perform rollover
export ROLLOVER_AGE="1"

export PROMETHEUS_STORAGE_SIZE_WC="5Gi"
# Size-based retention policy for Prometheus workload cluster database
export PROMETHEUS_RETENTION_SIZE_WC="4GiB"
# Time-based retention policy for Prometheus workload cluster database
export PROMETHEUS_RETENTION_WC="3d"

export PROMETHEUS_STORAGE_SIZE_SC="5Gi"
# Size-based retention policy for Prometheus service cluster database
export PROMETHEUS_RETENTION_SIZE_SC="4GiB"
# Time-based retention policy for Prometheus service cluster database
export PROMETHEUS_RETENTION_SC="3d"

# Time-based retention policy for Alertmanager
export ALERTMANAGER_RETENTION="72h"
