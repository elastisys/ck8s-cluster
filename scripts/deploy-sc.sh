#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

# General aws S3 cli variables.
: "${S3_ACCESS_KEY:?Missing S3_ACCESS_KEY}"
: "${S3_SECRET_KEY:?Missing S3_SECRET_KEY}"
: "${S3_REGION:?Missing S3_REGION}"
: "${S3_REGION_ENDPOINT:?Missing S3_REGION_ENDPOINT}"

# Inlfux backup variables.
: "${INFLUX_ADDR:?Missing INFLUX_ADDR}"
: "${S3_INFLUX_BUCKET_URL:?Missing S3_INFLUX_BUCKET_URL}"
: "${INFLUX_BACKUP_SCHEDULE:?Missing INFLUX_BACKUP_SCHEDULE}"

: "${ENABLE_PSP:?Missing ENABLE_PSP}"
: "${ENABLE_HARBOR:?Missing ENABLE_HARBOR}"
: "${ENABLE_CUSTOMER_PROMETHEUS:?Missing ENABLE_CUSTOMER_PROMETHEUS}"
: "${ENABLE_CUSTOMER_GRAFANA:?Missing ENABLE_CUSTOMER_GRAFANA}"
: "${SLACK_API_URL:?Missing SLACK_API_URL}"
: "${OAUTH_ALLOWED_DOMAINS:?Missing OAUTH_ALLOWED_DOMAINS}"

# Alerting
: "${ENABLE_HEARTBEAT:?Missing ENABLE_HEARTBEAT}"
: "${OPSGENIE_API_KEY:?Missing OPSGENIE_API_KEY}"
if [ $ENABLE_HEARTBEAT == "true" ]
then
    : "${OPSGENIE_HEARTBEAT_NAME:?Missing OPSGENIE_HEARTBEAT_NAME}"
fi

# Check that passwords are set
: "${INFLUXDB_PWD:?Missing INFLUXDB_PWD}"
: "${HARBOR_PWD:?Missing HARBOR_PWD}"
: "${GRAFANA_PWD:?Missing GRAFANA_PWD}"
: "${GRAFANA_CLIENT_SECRET:?Missing GRAFANA_CLIENT_SECRET}"
: "${KUBELOGIN_CLIENT_SECRET:?Missing KUBELOGIN_CLIENT_SECRET}"
: "${ELASTIC_USER_SECRET:?Missing ELASTIC_USER_SECRET}"

: "${PROMETHEUS_PWD:?Missing PROMETHEUS_PWD}"
: "${CUSTOMER_GRAFANA_PWD:?Missing CUSTOMER_GRAFANA_PWD}"
if [ $ENABLE_CUSTOMER_PROMETHEUS == "true" ]
then
    : "${CUSTOMER_PROMETHEUS_PWD:?Missing CUSTOMER_PROMETHEUS_PWD}"
fi

# For health checking
: "${MASTER_WC_SERVER_IP:?Missing MASTER_WC_SERVER_IP}"

# If unset -> false
ECK_RESTORE_CLUSTER=${ECK_RESTORE_CLUSTER:-false}

if [[ $ECK_RESTORE_CLUSTER != "false" ]]
then
    : "${INFLUX_BACKUP_NAME:?Missing INFLUX_BACKUP_NAME}"
fi

if [ $CLOUD_PROVIDER == "citycloud" ]
then
    export STORAGE_CLASS=cinder-storage
else
    export STORAGE_CLASS=nfs-client
fi

if [[ $ENABLE_HARBOR == "true" ]]
then
    : "${S3_HARBOR_BUCKET_NAME:?Missing S3_HARBOR_BUCKET_NAME}"
    : "${S3_ES_BACKUP_BUCKET_NAME:?Missing S3_ES_BACKUP_BUCKET_NAME}"
fi

# Arg for Helmfile to be interactive so that one can decide on which releases
# to update if changes are found.
# USE: --interactive, default is not interactive.
INTERACTIVE=${1:-""}

# NAMESPACES
NAMESPACES="cert-manager elastic-system dex nfs-provisioner influxdb-prometheus monitoring ck8sdash"
for namespace in ${NAMESPACES}
do
    kubectl create namespace ${namespace} --dry-run -o yaml | kubectl apply -f -
    kubectl label --overwrite namespace ${namespace} owner=operator
done

if [[ $ENABLE_HARBOR == "true" ]]
then
    kubectl create namespace harbor --dry-run -o yaml | kubectl apply -f -
fi

# PSP
if [[ $ENABLE_PSP == "true" ]]
then
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml

    # Deploy common roles and rolebindings.
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/kube-system-role-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/rke-job-deployer-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/tiller-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/nfs-client-provisioner-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/cert-manager-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/default-restricted-psp.yaml

    # Deploy cluster spcific roles and rolebindings.
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/dex-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/elastic-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/influxdb-psp.yaml

    if [[ $ENABLE_HARBOR == "true" ]]
    then
        kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/service_cluster/
    fi

fi

# HELM and TILLER
mkdir -p ${CONFIG_PATH}/certs/service_cluster/kube-system/certs
${SCRIPTS_PATH}/initialize-cluster.sh ${CONFIG_PATH}/certs/service_cluster "helm"
source ${SCRIPTS_PATH}/helm-env.sh kube-system ${CONFIG_PATH}/certs/service_cluster/kube-system/certs "helm"


# CERT-MANAGER
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite


issuer_namespaces='dex elastic-system kube-system monitoring ck8sdash'
for ns in $issuer_namespaces
do
    kubectl -n ${ns} apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml
    kubectl -n ${ns} apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml
done


if [[ $ENABLE_HARBOR == "true" ]]
then
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers/selfsigning-issuer-harbor.yaml
    envsubst < ${SCRIPTS_PATH}/../manifests/issuers/harbor-core-cert.yaml | kubectl apply -f -
    envsubst < ${SCRIPTS_PATH}/../manifests/issuers/harbor-notary-cert.yaml | kubectl apply -f -

    kubectl -n harbor apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml
    kubectl -n harbor apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml
fi

# Elasticsearch and kibana.
kubectl  -n  elastic-system create secret generic elasticsearch-es-elastic-user \
    --from-literal=elastic=$ELASTIC_USER_SECRET \
    --dry-run -o yaml | kubectl apply -f -

kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/operator.yaml
kubectl create secret generic s3-credentials -n elastic-system \
    --from-literal=s3.client.default.access_key=${S3_ACCESS_KEY} \
    --from-literal=s3.client.default.secret_key=${S3_SECRET_KEY} \
    --dry-run -o yaml | kubectl apply -f -
cat ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/elasticsearch.yaml | envsubst | kubectl apply -f -
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/kibana.yaml
cat ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/ingress.yaml | envsubst | kubectl apply -f -


# HARBOR
if [[ $ENABLE_PSP == "true" && $ENABLE_HARBOR == "true" ]]
then
    kubectl -n harbor create rolebinding harbor-privileged-psp \
        --clusterrole=psp:privileged --serviceaccount=harbor:default \
        --dry-run -o yaml | kubectl apply -f -
fi

# Prometheus - install CRDS.
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.33.0/example/prometheus-operator-crd/alertmanager.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.33.0/example/prometheus-operator-crd/prometheus.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.33.0/example/prometheus-operator-crd/prometheusrule.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.33.0/example/prometheus-operator-crd/servicemonitor.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.33.0/example/prometheus-operator-crd/podmonitor.crd.yaml


if [ $CLOUD_PROVIDER == "citycloud" ]
then
    storage=$(kubectl get storageclasses.storage.k8s.io cinder-storage)
    if [ $storage != "cinder-storage" ]
    then
        # Install cinder StorageClass.
        kubectl apply -f ${SCRIPTS_PATH}/../manifests/cinder-storage.yaml
    fi
fi


echo -e "\nContinuing with Helmfile\n"
cd ${SCRIPTS_PATH}/../helmfile


if [ $CLOUD_PROVIDER == "citycloud" ]
then
    # Install cert-manager.
    helmfile -f helmfile.yaml -e service_cluster -l app=cert-manager $INTERACTIVE apply
else
    # Install cert-manager and nfs-client-provisioner.
    helmfile -f helmfile.yaml -e service_cluster -l app=cert-manager -l app=nfs-client-provisioner $INTERACTIVE apply
fi

# Get status of the cert-manager webhook api.
STATUS=$(kubectl get apiservice v1beta1.webhook.certmanager.k8s.io -o yaml -o=jsonpath='{.status.conditions[0].type}')

# Just want to see if this ever happens.
if [ $STATUS != "Available" ]
then
   echo -e  "##\n##\nWaiting for cert-manager webhook to become ready\n##\n##"
   kubectl wait --for=condition=Available --timeout=300s \
       apiservice v1beta1.webhook.certmanager.k8s.io
fi

# Install dex.
helmfile -f helmfile.yaml -e service_cluster -l app=dex $INTERACTIVE apply

if [[ $ENABLE_HARBOR == "true" ]]
then
    # Install the rest of the charts, excluding prometheus-operator.
    helmfile -f helmfile.yaml -e service_cluster -l app!=cert-manager,app!=nfs-client-provisioner,app!=dex,app!=prometheus-operator,app!=elasticsearch-prometheus-exporter $INTERACTIVE apply
else
    # Install the rest of the charts, excluding prometheus-operator.
    helmfile -f helmfile.yaml -e service_cluster -l app!=cert-manager,app!=nfs-client-provisioner,app!=dex,app!=prometheus-operator,app!=elasticsearch-prometheus-exporter,app!=harbor $INTERACTIVE apply
fi

# Install prometheus-operator. Retry three times.
tries=3
success=false

for i in $(seq 1 $tries)
do
    if helmfile -f helmfile.yaml -e service_cluster -l app=prometheus-operator $INTERACTIVE apply
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
    exit 1
fi

# ck8sdash
envsubst < ${SCRIPTS_PATH}/../manifests/ck8sdash/env-secret.yaml | kubectl apply -f -
envsubst < ${SCRIPTS_PATH}/../manifests/ck8sdash/ingress-sc.yaml | kubectl apply -f -
kubectl apply -f ${SCRIPTS_PATH}/../manifests/ck8sdash/service.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/ck8sdash/deployment.yaml

# Adding backup job and repository to elasticsearch
while [[ $(kubectl get elasticsearches.elasticsearch.k8s.elastic.co -n elastic-system elasticsearch -o 'jsonpath={.status.health}') != "green" ]]
do
    echo "Waiting until elasticsearch is ready"
    sleep 2
done



export ES_PW=$(kubectl get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)

# Create curator configmap
${SCRIPTS_PATH}/gen-curator-conf.sh | kubectl apply -f -

# Create curator cronjob
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/curator.yaml

kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/backup-job.yaml

#install elasticsearch-prometheus-exporter
helmfile -f helmfile.yaml -e service_cluster -l app=elasticsearch-prometheus-exporter $INTERACTIVE apply

# Restore InfluxDB from backup
if [[ $ECK_RESTORE_CLUSTER != "false" ]]
then
    echo "Restoring InfluxDB"
    envsubst < ${SCRIPTS_PATH}/../manifests/restore/restore-influx.yaml | kubectl -n influxdb-prometheus apply -f -
fi

## Maybe this can become problematic if cluster is being restored?
# Install InfluxDB backup cron-job.
envsubst < ${SCRIPTS_PATH}/../manifests/backup/backup-influx-cronjob.yaml | kubectl -n influxdb-prometheus apply -f -
