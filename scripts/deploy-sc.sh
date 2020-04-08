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

# Elasticsearch
: "${ES_NODE_COUNT:?Missing ES_NODE_COUNT}"

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
: "${ELASTIC_USER_SECRET:?Missing ELASTIC_USER_SECRET}"
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
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/elastic-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/influxdb-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/fluentd-psp.yaml

    if [[ $ENABLE_HARBOR == "true" ]]
    then
        kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/
    fi
fi

echo "Preparing cert manager and creating Issuers" >&2
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
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

echo "Creating Prometheus CRD" >&2
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.33.0/example/prometheus-operator-crd/alertmanager.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.33.0/example/prometheus-operator-crd/prometheus.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.33.0/example/prometheus-operator-crd/prometheusrule.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.33.0/example/prometheus-operator-crd/servicemonitor.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.33.0/example/prometheus-operator-crd/podmonitor.crd.yaml

echo "Creating elasticsearch-operator CRD" >&2
kubectl apply -f "${SCRIPTS_PATH}/../manifests/elasticsearch-operator/crds.yaml"

echo "Creating Velero CRD" >&2
kubectl apply -f https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/backupstoragelocations.yaml
kubectl apply -f https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/volumesnapshotlocations.yaml
kubectl apply -f https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/schedules.yaml

echo -e "Continuing with Helmfile" >&2
cd ${SCRIPTS_PATH}/../helmfile

echo "Install cert-manager" >&2
helmfile -f helmfile.yaml -e service_cluster -l app=cert-manager $INTERACTIVE apply --suppress-diff

source ${SCRIPTS_PATH}/install-storage-class-provider.sh
install_storage_class_provider "${STORAGE_CLASS}" service_cluster
install_storage_class_provider "${ES_STORAGE_CLASS}" service_cluster

# Get status of the cert-manager webhook api.
STATUS=$(kubectl get apiservice v1beta1.webhook.certmanager.k8s.io -o yaml -o=jsonpath='{.status.conditions[0].type}')

# Just want to see if this ever happens.
if [ $STATUS != "Available" ]
then
   echo -e  "Waiting for cert-manager webhook to become ready" >&2
   kubectl wait --for=condition=Available --timeout=300s \
       apiservice v1beta1.webhook.certmanager.k8s.io
fi

echo "Installing Dex" >&2
helmfile -f helmfile.yaml -e service_cluster -l app=dex $INTERACTIVE apply --suppress-diff

charts_ignore_list="app!=cert-manager,app!=nfs-client-provisioner,app!=local-volume-provisioner,app!=dex,app!=prometheus-operator,app!=elasticsearch-prometheus-exporter"

[[ $ENABLE_HARBOR != "true" ]] && charts_ignore_list+=",app!=harbor"
[[ $ENABLE_CK8SDASH_SC != "true" ]] && charts_ignore_list+=",app!=ck8sdash"

echo "Installing the rest of the charts" >&2
helmfile -f helmfile.yaml -e service_cluster -l "$charts_ignore_list" $INTERACTIVE apply --suppress-diff

echo "Installing prometheus operator" >&2
tries=3
success=false

for i in $(seq 1 $tries)
do
    if helmfile -f helmfile.yaml -e service_cluster -l app=prometheus-operator $INTERACTIVE apply --suppress-diff
    then
        success=true
        break
    else
        echo failed to deploy prometheus operator on try $i
        helmfile -f helmfile.yaml -e service_cluster -l app=prometheus-operator $INTERACTIVE destroy
    fi
done

# Then prometheus operator failed too many times
if [ $success != "true" ]
then
    echo "Error: Prometheus failed to install three times" >&2
    exit 1
fi

echo "Install elasticsearch prometheus exporter" >&2
helmfile -f helmfile.yaml -e service_cluster -l app=elasticsearch-prometheus-exporter $INTERACTIVE apply --suppress-diff

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
