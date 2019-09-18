#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
source "${SCRIPTS_PATH}/common.sh"


: "${S3_ACCESS_KEY:?Missing S3_ACCESS_KEY}"
: "${S3_SECRET_KEY:?Missing S3_SECRET_KEY}"
: "${S3_REGION:?Missing S3_REGION}"
: "${S3_REGION_ENDPOINT:?Missing S3_REGION_ENDPOINT}"
: "${S3_BUCKET_NAME:?Missing S3_BUCKET_NAME}"

if [[ "$#" -lt 1 ]]
then 
  echo "Usage: deploy-sc.sh path-to-infra-file <--interactive>"
  exit 1
fi

infra="$1"

# Domains that should be allowed to log in using OAuth
export OAUTH_ALLOWED_DOMAINS="${OAUTH_ALLOWED_DOMAINS:-elastisys.com}"

pushd "${SCRIPTS_PATH}/../" > /dev/null
export NFS_SC_SERVER_IP=$(cat $infra | jq -r '.service_cluster.nfs_ip_address')
popd > /dev/null

# Arg for Helmfile to be interactive so that one can decide on which releases
# to update if changes are found.
# USE: --interactive, default is not interactive.
INTERACTIVE=${2:-""}


# NAMESPACES
kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
kubectl create namespace elastic-system --dry-run -o yaml | kubectl apply -f -
kubectl create namespace harbor --dry-run -o yaml | kubectl apply -f -
kubectl create namespace dex --dry-run -o yaml | kubectl apply -f -
kubectl create namespace nfs-provisioner --dry-run -o yaml | kubectl apply -f -
kubectl create namespace influxdb-prometheus --dry-run -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run -o yaml | kubectl apply -f -


# PSP
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access-sc.yaml


# HELM and TILLER
mkdir -p ${SCRIPTS_PATH}/../certs/service_cluster/kube-system/certs
${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/service_cluster "helm"
source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/service_cluster/kube-system/certs "helm"


# DASHBOARD
kubectl apply -f ${SCRIPTS_PATH}/../manifests/dashboard.yaml


# CERT-MANAGER
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers/selfsigning-issuer.yaml
envsubst < ${SCRIPTS_PATH}/../manifests/issuers/harbor-core-cert.yaml | kubectl apply -f -
envsubst < ${SCRIPTS_PATH}/../manifests/issuers/harbor-notary-cert.yaml | kubectl apply -f -


# Elasticsearch and kibana.
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/operator.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/elasticsearch.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/kibana.yaml
cat ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/ingress.yaml | envsubst | kubectl apply -f -


# HARBOR
kubectl -n harbor create rolebinding harbor-privileged-psp \
    --clusterrole=psp:privileged --serviceaccount=harbor:default \
    --dry-run -o yaml | kubectl apply -f -


# Prometheus - install CRDS.
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/podmonitor.crd.yaml


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

echo -e "\nContinuing with Helmfile\n"

cd ${SCRIPTS_PATH}/../helmfile

# Install cert-manager and nfs-client-provisioner first.
helmfile -f helmfile.yaml -e service_cluster -l app=cert-manager -l app=nfs-client-provisioner $INTERACTIVE apply

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

# Install the rest of the charts.
helmfile -f helmfile.yaml -e service_cluster -l app!=cert-manager,app!=nfs-client-provisioner,app!=dex $INTERACTIVE apply

# Check harbor rollout status.
# Should not be needed due to 'wait' when installing/upgrading harbor!
# Just keeping it for now but should be removed.
kubectl -n harbor rollout status deployment harbor-harbor-clair

# Set up initial state for harbor.
EXISTS=$(curl -s -k -X GET -u admin:Harbor12345 https://harbor.${ECK_SC_DOMAIN}/api/projects/1 | jq '.code')

if [ $EXISTS != "404" ]
then
    NAME=$(curl -s -k -X GET -u admin:Harbor12345 https://harbor.${ECK_SC_DOMAIN}/api/projects/1 | jq '.name')
    if [ $NAME == "\"library\"" ]
    then
        # Deletes the default project "library"
        echo Removing project library from harbor
        # Curl will retrun status 500 even though it successfully removed the project.
        curl -s -k -X DELETE -u admin:Harbor12345 https://harbor.${ECK_SC_DOMAIN}/api/projects/1 > /dev/null

        # Creates new private project "default"
        echo Creating new private project default
        curl -s -k -X POST -u admin:Harbor12345 --header 'Content-Type: application/json' --header 'Accept: application/json' https://harbor.${ECK_SC_DOMAIN}/api/projects --data '{
            "project_name": "default",
            "metadata": {
                "public": "0",
                "enable_content_trust": "false",
                "prevent_vul": "false",
                "severity": "low",
                "auto_scan": "true"
            }
        }'
    fi
fi


# Adding dashboards to kibana
echo "Waiting until kibana is ready"
if ! kubectl rollout status -n elastic-system deployment kibana-kb --timeout=5m
then
    exit 1
fi
ES_PW=$(kubectl get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)
curl -kL -X POST "kibana.${ECK_SC_DOMAIN}/api/saved_objects/_import" -H "kbn-xsrf: true" \
    --form file=@${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/kibana-dashboards.ndjson -u elastic:${ES_PW}
