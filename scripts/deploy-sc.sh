#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"

# General aws S3 cli variables.
: "${S3_ACCESS_KEY:?Missing S3_ACCESS_KEY}"
: "${S3_SECRET_KEY:?Missing S3_SECRET_KEY}"
: "${S3_REGION:?Missing S3_REGION}"
: "${S3_REGION_ENDPOINT:?Missing S3_REGION_ENDPOINT}"

# Inlfux backup variables.
: "${INFLUX_ADDR:?Missing INFLUX_ADDR}"
: "${S3_INFLUX_BUCKET_NAME:?Missing S3_INFLUX_BUCKET_NAME}"

# Fluentd aggregator S3 output variables.
: "${S3_SC_FLUENTD_BUCKET_NAME:?Missing S3_SC_FLUENTD_BUCKET_NAME}"

: "${ENABLE_PSP:?Missing ENABLE_PSP}"
: "${ENABLE_HARBOR:?Missing ENABLE_HARBOR}"
: "${ENABLE_CUSTOMER_GRAFANA:?Missing ENABLE_CUSTOMER_GRAFANA}"
: "${OAUTH_ALLOWED_DOMAINS:?Missing OAUTH_ALLOWED_DOMAINS}"
: "${ENABLE_CK8SDASH_SC:?Missing ENABLE_CK8SDASH_SC}"

# Elasticsearch Config
: "${ES_MASTER_COUNT:?Missing ES_MASTER_COUNT}"
: "${ES_MASTER_STORAGE_SIZE:?Missing ES_MASTER_STORAGE_SIZE}"
: "${ES_MASTER_CPU_REQUEST:?Missing ES_MASTER_CPU_REQUEST}"
: "${ES_MASTER_MEM_REQUEST:?Missing ES_MASTER_MEM_REQUEST}"
: "${ES_MASTER_CPU_LIMIT:?Missing ES_MASTER_CPU_LIMIT}"
: "${ES_MASTER_MEM_LIMIT:?Missing ES_MASTER_MEM_LIMIT}"
: "${ES_MASTER_JAVA_OPTS:?Missing ES_MASTER_JAVA_OPTS}"
: "${ES_DATA_COUNT:?Missing ES_DATA_COUNT}"
: "${ES_DATA_STORAGE_SIZE:?Missing ES_DATA_STORAGE_SIZE}"
: "${ES_DATA_CPU_REQUEST:?Missing ES_DATA_CPU_REQUEST}"
: "${ES_DATA_MEM_REQUEST:?Missing ES_DATA_MEM_REQUEST}"
: "${ES_DATA_CPU_LIMIT:?Missing ES_DATA_CPU_LIMIT}"
: "${ES_DATA_MEM_LIMIT:?Missing ES_DATA_MEM_LIMIT}"
: "${ES_DATA_JAVA_OPTS:?Missing ES_DATA_JAVA_OPTS}"
: "${ES_CLIENT_COUNT:?Missing ES_CLIENT_COUNT}"
: "${ES_CLIENT_CPU_REQUEST:?Missing ES_CLIENT_CPU_REQUEST}"
: "${ES_CLIENT_MEM_REQUEST:?Missing ES_CLIENT_MEM_REQUEST}"
: "${ES_CLIENT_CPU_LIMIT:?Missing ES_CLIENT_CPU_LIMIT}"
: "${ES_CLIENT_MEM_LIMIT:?Missing ES_CLIENT_MEM_LIMIT}"
: "${ES_CLIENT_JAVA_OPTS:?Missing ES_CLIENT_JAVA_OPTS}"
: "${ES_KUBEAUDIT_RETENTION_SIZE:?Missing ES_KUBEAUDIT_RETENTION_SIZE}"
: "${ES_KUBEAUDIT_RETENTION_AGE:?Missing ES_KUBEAUDIT_RETENTION_AGE}"
: "${ES_KUBERNETES_RETENTION_SIZE:?Missing ES_KUBERNETES_RETENTION_SIZE}"
: "${ES_KUBERNETES_RETENTION_AGE:?Missing ES_KUBERNETES_RETENTION_AGE}"
: "${ES_OTHER_RETENTION_SIZE:?Missing ES_OTHER_RETENTION_SIZE}"
: "${ES_OTHER_RETENTION_AGE:?Missing ES_OTHER_RETENTION_AGE}"
: "${ES_POSTGRESQL_RETENTION_SIZE:?Missing ES_POSTGRESQL_RETENTION_SIZE}"
: "${ES_POSTGRESQL_RETENTION_AGE:?Missing ES_POSTGRESQL_RETENTION_AGE}"
: "${ES_ROLLOVER_SIZE:?Missing ES_ROLLOVER_SIZE}"
: "${ES_ROLLOVER_AGE:?Missing ES_ROLLOVER_AGE}"
: "${ES_SNAPSHOT_MIN:?Missing ES_SNAPSHOT_MIN}"
: "${ES_SNAPSHOT_MAX:?Missing ES_SNAPSHOT_MAX}"
: "${ES_SNAPSHOT_AGE_SECONDS:?Missing ES_SNAPSHOT_AGE_SECONDS}"
: "${ES_SNAPSHOT_RETENTION_SCHEDULE:?Missing ES_SNAPSHOT_RETENTION_SCHEDULE}"
: "${ES_SNAPSHOT_SCHEDULE:?Missing ES_SNAPSHOT_SCHEDULE}"

# Elasticsearch secrets
: "${ES_ADMIN_PWD:?Missing ES_ADMIN_PWD}"
: "${ES_CONFIGURER_PWD:?Missing ES_CONFIGURER_PWD}"
: "${ES_KIBANASERVER_PWD:?Missing ES_KIBANASERVER_PWD}"
: "${ES_ADMIN_PWD_HASH:?Missing ES_ADMIN_PWD_HASH}"
: "${ES_CONFIGURER_PWD_HASH:?Missing ES_CONFIGURER_PWD_HASH}"
: "${ES_KIBANASERVER_PWD_HASH:?Missing ES_KIBANASERVER_PWD_HASH}"
: "${ES_FLUENTD_PWD:?Missing ES_FLUENTD_PWD}"
: "${ES_CURATOR_PWD:?Missing ES_CURATOR_PWD}"
: "${ES_SNAPSHOTTER_PWD:?Missing ES_SNAPSHOTTER_PWD}"
: "${ES_METRICS_EXPORTER_PWD:?Missing ES_METRICS_EXPORTER_PWD}"
: "${ES_KIBANA_COOKIE_ENC_KEY:?Missing ES_KIBANA_COOKIE_ENC_KEY}"

# Alerting
: "${ALERT_TO:?Missing ALERT_TO}"
: "${ENABLE_HEARTBEAT:?Missing ENABLE_HEARTBEAT}"
if [ $ENABLE_HEARTBEAT == "true" ]
then
    : "${OPSGENIE_HEARTBEAT_NAME:?Missing OPSGENIE_HEARTBEAT_NAME}"
    : "${OPSGENIE_API_KEY:?Missing OPSGENIE_API_KEY}"
fi
if [ $ALERT_TO == "opsgenie" ]
then
    : "${OPSGENIE_API_KEY:?Missing OPSGENIE_API_KEY}"
elif [ $ALERT_TO == "slack" ]
then
    : "${SLACK_API_URL:?Missing SLACK_API_URL}"
elif [ $ALERT_TO == "null" ]
then
    :; # This is OK, do nothing
else
    echo "ERROR: ALERT_TO must be set to one of slack, opsgenie or null."
    exit 1
fi

# Check that passwords are set
: "${INFLUXDB_PWD:?Missing INFLUXDB_PWD}"
: "${HARBOR_PWD:?Missing HARBOR_PWD}"
: "${GRAFANA_PWD:?Missing GRAFANA_PWD}"
: "${GRAFANA_CLIENT_SECRET:?Missing GRAFANA_CLIENT_SECRET}"
: "${KUBELOGIN_CLIENT_SECRET:?Missing KUBELOGIN_CLIENT_SECRET}"
: "${CUSTOMER_GRAFANA_PWD:?Missing CUSTOMER_GRAFANA_PWD}"
: "${CUSTOMER_PROMETHEUS_PWD:?Missing CUSTOMER_PROMETHEUS_PWD}"

# For health checking
: "${MASTER_WC_SERVER_IP:?Missing MASTER_WC_SERVER_IP}"

# If unset -> false
ECK_RESTORE_CLUSTER=${ECK_RESTORE_CLUSTER:-false}

if [[ $ECK_RESTORE_CLUSTER != "false" ]]
then
    : "${INFLUX_BACKUP_NAME:?Missing INFLUX_BACKUP_NAME}"
fi

source ${SCRIPTS_PATH}/set-storage-class.sh

if [[ $ENABLE_HARBOR == "true" ]]
then
    : "${S3_HARBOR_BUCKET_NAME:?Missing S3_HARBOR_BUCKET_NAME}"
    : "${S3_ES_BACKUP_BUCKET_NAME:?Missing S3_ES_BACKUP_BUCKET_NAME}"
fi

# Arg for Helmfile to be interactive so that one can decide on which releases
# to update if changes are found.
# USE: --interactive, default is not interactive.
INTERACTIVE=${1:-""}

echo "Creating namespaces" >&2
NAMESPACES="cert-manager dex elastic-system fluentd harbor influxdb-prometheus kube-node-lease kube-public kube-system monitoring nginx-ingress velero"
[ $ENABLE_CK8SDASH_SC == "true" ] && NAMESPACES+=" ck8sdash"
for namespace in ${NAMESPACES}
do
    kubectl create namespace ${namespace} --dry-run -o yaml | kubectl apply -f -
    kubectl label --overwrite namespace ${namespace} owner=operator
done


if [[ $ENABLE_HARBOR == "true" ]]
then
    kubectl create namespace harbor --dry-run -o yaml | kubectl apply -f -
fi

echo "Creating pod security policies" >&2
if [[ $ENABLE_PSP == "true" ]]
then
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml

    # Deploy common roles and rolebindings.
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/kube-system-role-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/nfs-client-provisioner-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/cert-manager-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/default-restricted-psp.yaml

    # Deploy cluster spcific roles and rolebindings.
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/dex-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/influxdb-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/fluentd-psp.yaml

    if [[ $ENABLE_HARBOR == "true" ]]
    then
        kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/
    fi
fi

echo "Preparing cert manager and creating Issuers" >&2
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite


issuer_namespaces='dex elastic-system kube-system monitoring'
[ $ENABLE_CK8SDASH_SC == "true" ] && issuer_namespaces+=" ck8sdash"
for ns in $issuer_namespaces
do
    kubectl -n ${ns} apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml
    kubectl -n ${ns} apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml
done
if [[ $ENABLE_HARBOR == "true" ]]
then
    kubectl -n harbor apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml
    kubectl -n harbor apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml
fi

echo "Installing fluentd" >&2
kubectl create secret generic s3-credentials -n fluentd \
    --from-literal=s3_access_key=${S3_ACCESS_KEY} \
    --from-literal=s3_secret_key=${S3_SECRET_KEY} \
    --dry-run -o yaml | kubectl apply -f -

echo "Installing Harbor" >&2
if [[ $ENABLE_PSP == "true" && $ENABLE_HARBOR == "true" ]]
then
    kubectl -n harbor create rolebinding harbor-privileged-psp \
        --clusterrole=psp:privileged --serviceaccount=harbor:default \
        --dry-run -o yaml | kubectl apply -f -
fi

echo -e "Continuing with Helmfile" >&2
cd ${SCRIPTS_PATH}/../helmfile

source ${SCRIPTS_PATH}/install-storage-class-provider.sh
install_storage_class_provider "${STORAGE_CLASS}" service_cluster
install_storage_class_provider "${ES_STORAGE_CLASS}" service_cluster

charts_ignore_list="app!=nfs-client-provisioner,app!=local-volume-provisioner"
[[ $ENABLE_HARBOR != "true" ]] && charts_ignore_list+=",app!=harbor"
[[ $ENABLE_CK8SDASH_SC != "true" ]] && charts_ignore_list+=",app!=ck8sdash"

echo "Installing the rest of the charts" >&2
helmfile -f helmfile.yaml -e service_cluster -l "$charts_ignore_list" $INTERACTIVE apply --suppress-diff

# Restore InfluxDB from backup
# Requires dropping existing databases first
if [[ $ECK_RESTORE_CLUSTER != "false" ]]
then
    echo "Restoring InfluxDB" >&2
    envsubst < ${SCRIPTS_PATH}/../manifests/restore/restore-influx.yaml | kubectl -n influxdb-prometheus apply -f -
fi

if [ "${RESTORE_VELERO}" = "true" ]
then
    if [ "${ENABLE_CUSTOMER_GRAFANA}" = "true" ]
    then
        # Need to delete the customer-grafana deployment and pvc created by
        # Helm before restoring it from backup.
        kubectl delete deployment -n monitoring customer-grafana
        kubectl delete pvc -n monitoring customer-grafana
    fi

    if [ ! -z "${VELERO_BACKUP_NAME}" ]
    then
        velero restore create --from-backup "${VELERO_BACKUP_NAME}" -w
    else
        velero restore create --from-schedule velero-daily-backup -w
    fi
fi
echo "Deploc sc completed!" >&2
