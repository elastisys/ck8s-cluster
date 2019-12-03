#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
source "${SCRIPTS_PATH}/common.sh"


if [[ "$#" -lt 1 ]]
then
  >&2 echo "Usage: deploy-sc.sh path-to-infra-file <--interactive>"
  exit 1
fi

infra="$1"

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
: "${SLACK_API_URL:?Missing SLACK_API_URL}"
: "${OAUTH_ALLOWED_DOMAINS:?Missing OAUTH_ALLOWED_DOMAINS}"

# Check that passwords are set
: "${INFLUXDB_PWD:?Missing INFLUXDB_PWD}"
: "${HARBOR_PWD:?Missing HARBOR_PWD}"
: "${GRAFANA_PWD:?Missing GRAFANA_PWD}"
: "${DASHBOARD_CLIENT_SECRET:?Missing DASHBOARD_CLIENT_SECRET}"
: "${GRAFANA_CLIENT_SECRET:?Missing GRAFANA_CLIENT_SECRET}"
: "${KUBELOGIN_CLIENT_SECRET:?Missing KUBELOGIN_CLIENT_SECRET}"

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

if [ $CLOUD_PROVIDER == "exoscale" ]
then
export NFS_SC_SERVER_IP=$(cat $infra | jq -r '.service_cluster.nfs_ip_address')
elif [ $CLOUD_PROVIDER == "safespring" ]
then
export NFS_SC_SERVER_IP=$(cat $infra | jq -r '.service_cluster.nfs_private_ip_address')
fi

# Arg for Helmfile to be interactive so that one can decide on which releases
# to update if changes are found.
# USE: --interactive, default is not interactive.
INTERACTIVE=${2:-""}


# NAMESPACES
NAMESPACES="cert-manager elastic-system dex nfs-provisioner influxdb-prometheus monitoring"
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
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/dashboard-psp.yaml
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
mkdir -p ${SCRIPTS_PATH}/../clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/certs/service_cluster/kube-system/certs
${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/certs/service_cluster "helm"
source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/certs/service_cluster/kube-system/certs "helm"


# DASHBOARD
kubectl apply -f ${SCRIPTS_PATH}/../manifests/dashboard.yaml


# CERT-MANAGER
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite


issuer_namespaces='dex elastic-system kube-system monitoring'
for ns in $issuer_namespaces
do
    export CERT_NAMESPACE=$ns
    envsubst < ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml | kubectl apply -f -
    envsubst < ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml | kubectl apply -f -
done


if [[ $ENABLE_HARBOR == "true" ]]
then
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers/selfsigning-issuer-harbor.yaml
    envsubst < ${SCRIPTS_PATH}/../manifests/issuers/harbor-core-cert.yaml | kubectl apply -f -
    envsubst < ${SCRIPTS_PATH}/../manifests/issuers/harbor-notary-cert.yaml | kubectl apply -f -

    export CERT_NAMESPACE=harbor
    envsubst < ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml | kubectl apply -f -
    envsubst < ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml | kubectl apply -f -
fi

# Elasticsearch and kibana.
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


# Prometheus workload_cluster reader
# Generate workload_cluster scrape configs
envsubst < "$SCRIPTS_PATH"/../manifests/prometheus-wc-reader/prometheus-federate-additional.yaml | \
    kubectl create secret generic prometheus-wc-scrape-configs -n monitoring --dry-run \
    -o yaml --from-file=prometheus-federate-additional.yaml=/dev/stdin | \
    kubectl apply -f -
# Create prometheus workload_cluster reader
envsubst < "$SCRIPTS_PATH"/../manifests/prometheus-wc-reader/prometheus-wc-reader.yaml | kubectl apply -f -
# Expose prometheus workload_cluster reader
kubectl apply -f "$SCRIPTS_PATH"/../manifests/prometheus-wc-reader/prometheus-wc-service.yaml


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
    helmfile -f helmfile.yaml -e service_cluster -l app!=cert-manager,app!=nfs-client-provisioner,app!=dex,app!=prometheus-operator $INTERACTIVE apply
else
    # Install the rest of the charts, excluding prometheus-operator.
    helmfile -f helmfile.yaml -e service_cluster -l app!=cert-manager,app!=nfs-client-provisioner,app!=dex,app!=prometheus-operator,app!=harbor $INTERACTIVE apply
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

if [[ $ENABLE_HARBOR == "true" ]]
then
    echo "Setting up initial harbor state"
    HARBOR_URL="https://harbor.${ECK_BASE_DOMAIN}/api/projects/1"
    # Check harbor rollout status.
    # Should not be needed due to 'wait' when installing/upgrading harbor!
    # Just keeping it for now but should be removed.
    kubectl -n harbor rollout status deployment harbor-harbor-clair

    # Set up initial state for harbor.
    EXISTS=$(curl -k -X GET -u admin:Harbor12345 $HARBOR_URL | jq '.code') || {
      echo "ERROR L.${LINENO} - Harbor url $HARBOR_URL cannot be reached."
      exit 1
    }
    if [ "$EXISTS" != "404" ]
    then
        NAME=$(curl -k -X GET -u admin:Harbor12345 $HARBOR_URL | jq '.name')

        if [ "$NAME" == "\"library\"" ]
        then
            # Deletes the default project "library"
            echo Removing project library from harbor
            # Curl will retrun status 500 even though it successfully removed the project.
            curl -k -X DELETE -u admin:${HARBOR_PWD} $HARBOR_URL > /dev/null

            # Creates new private project "default"
            echo Creating new private project default
            curl -k -X POST -u admin:${HARBOR_PWD} --header 'Content-Type: application/json' --header 'Accept: application/json' https://harbor.${ECK_BASE_DOMAIN}/api/projects --data '{
                "project_name": "default",
                "metadata": {
                    "public": "0",
                    "enable_content_trust": "false",
                    "prevent_vul": "false",
                    "severity": "low",
                    "auto_scan": "true"
                }
            }'
            echo "Harbor initialized"
        fi
    else
        echo "Harbor was already initilized"
    fi
fi

# Adding backup job and repository to elasticsearch
while [[ $(kubectl get elasticsearches.elasticsearch.k8s.elastic.co -n elastic-system elasticsearch -o 'jsonpath={.status.health}') != "green" ]]
do
    echo "Waiting until elasticsearch is ready"
    sleep 2
done



export ES_PW=$(kubectl get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)
envsubst < ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/elasticsearch-curator.yaml | kubectl -n elastic-system apply -f -

curl -X PUT "https://elastic.${ECK_OPS_DOMAIN}/_snapshot/s3_backup_repository?pretty" \
    -H 'Content-Type: application/json' \
    -d' {"type": "s3", "settings":{ "bucket": "'"${S3_ES_BACKUP_BUCKET_NAME}"'", "client": "default"}}' \
    -k -u elastic:${ES_PW}
curl -X PUT "https://elastic.${ECK_OPS_DOMAIN}/_cluster/settings?pretty" \
    -H 'Content-Type: application/json' \
    -k -u elastic:${ES_PW} \
    -d' {"transient": {"indices.lifecycle.poll_interval": "10s" }}'\

kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/backup-job.yaml

# Adding dashboards to kibana
echo "Waiting until kibana is ready"

if ! kubectl rollout status -n elastic-system deployment kibana-kb --timeout=5m
then
    exit 1
fi

curl -kL -X POST "kibana.${ECK_OPS_DOMAIN}/api/saved_objects/_import" -H "kbn-xsrf: true" \
    --form file=@${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/kibana-dashboards.ndjson -u elastic:${ES_PW}

# Restore InfluxDB from backup
if [[ $ECK_RESTORE_CLUSTER != "false" ]]
then
    echo "Restoring InfluxDB"
    envsubst < ${SCRIPTS_PATH}/../manifests/restore/restore-influx.yaml | kubectl -n influxdb-prometheus apply -f -
fi

## Maybe this can become problematic if cluster is being restored?
# Install InfluxDB backup cron-job.
envsubst < ${SCRIPTS_PATH}/../manifests/backup/backup-influx-cronjob.yaml | kubectl -n influxdb-prometheus apply -f -
