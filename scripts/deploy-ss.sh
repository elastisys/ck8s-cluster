#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

source "${SCRIPTS_PATH}/common.sh"

: "${TF_VAR_exoscale_api_key:?Missing TF_VAR_exoscale_api_key}"
: "${TF_VAR_exoscale_secret_key:?Missing TF_VAR_exoscale_secret_key}"
: "${GOOGLE_CLIENT_ID:?Missing GOOGLE_CLIENT_ID}"
: "${GOOGLE_CLIENT_SECRET:?Missing GOOGLE_CLIENT_SECRET}"

pushd "${SCRIPTS_PATH}/../terraform/system-services/" > /dev/null

E_IP=$(terraform output ss-elastic-ip)
NFS_SERVER_IP=$(terraform output ss-nfs-ip)

popd > /dev/null

# NAMESPACES

kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
kubectl create namespace elastic-system --dry-run -o yaml | kubectl apply -f -
kubectl create namespace harbor --dry-run -o yaml | kubectl apply -f -
kubectl create namespace dex --dry-run -o yaml | kubectl apply -f -
kubectl create namespace nfs-provisioner --dry-run -o yaml | kubectl apply -f -
kubectl create namespace influxdb-prometheus --dry-run -o yaml | kubectl apply -f -

# PSP

kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access-ss.yaml

# HELM, TILLER

mkdir -p ${SCRIPTS_PATH}/../certs/system-services/kube-system/certs

${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/system-services "admin1"

source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/system-services/kube-system/certs admin1

# Add Helm repositories and update repository cache

helm repo add harbor https://helm.goharbor.io
helm repo add jetstack https://charts.jetstack.io
helm repo update

# DEX, OAUTH2, DASHBOARD

helm upgrade dex ${SCRIPTS_PATH}/../charts/dex --install --namespace dex \
    --set "ingress.hosts={dex.${ECK_DOMAIN}}" \
    --set "ingress.tls[0].hosts={dex.${ECK_DOMAIN}}" \
    --set "config.issuer=https://dex.${ECK_DOMAIN}" \
    --set "config.connectors[0].config.redirectURI=https://dex.${ECK_DOMAIN}/callback" \
    --set "config.connectors[0].config.clientID=${GOOGLE_CLIENT_ID}" \
    --set "config.connectors[0].config.clientSecret=${GOOGLE_CLIENT_SECRET}" \
    --set "config.staticClients[0].redirectURIs={http://localhost:8000,https://dashboard.${ECK_DOMAIN}/oauth2/callback,https://dashboard.${ECK_C_DOMAIN}/oauth2/callback}" \
    -f ${SCRIPTS_PATH}/../helm-values/dex-values.yaml

helm upgrade oauth2 stable/oauth2-proxy --install --namespace kube-system \
    --set "extraArgs.redirect-url=https://dashboard.${ECK_DOMAIN}/oauth2/callback" \
    --set "extraArgs.oidc-issuer-url=https://dex.${ECK_DOMAIN}" \
    --set "ingress.hosts={dashboard.${ECK_DOMAIN}}" \
    --set "ingress.tls[0].hosts={dashboard.${ECK_DOMAIN}}" \
    -f ${SCRIPTS_PATH}/../helm-values/oauth2-proxy-values-ss.yaml --version 0.12.3 --debug

kubectl apply -f ${SCRIPTS_PATH}/../manifests/dashboard.yaml

# CERT-MANAGER

# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# https://docs.cert-manager.io/en/latest/getting-started/install.html#installing-with-helm
# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers

helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.0

# Elasticsearch and kibana.

kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/operator.yaml
sleep 5
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/elasticsearch.yaml
sleep 5
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/kibana.yaml

cat ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/ingress.yaml | envsubst | kubectl apply -f -

# NFS client provisioner

helm upgrade nfs-client-provisioner stable/nfs-client-provisioner \
  --install --namespace kube-system --version 1.2.6 \
  --values ${SCRIPTS_PATH}/../helm-values/nfs-client-provisioner-values.yaml \
  --set nfs.server=${NFS_SERVER_IP}

# HARBOR

# Create rolebindings for harbor
kubectl -n harbor create rolebinding harbor-privileged-psp \
    --clusterrole=psp:privileged --serviceaccount=harbor:default \
    --dry-run -o yaml | kubectl apply -f -

# Deploying harbor
helm upgrade harbor harbor/harbor --version 1.1.1 \
  --install \
  --namespace harbor \
  --values ${SCRIPTS_PATH}/../helm-values/harbor-values.yaml \
  --set persistence.imageChartStorage.s3.secretkey=$TF_VAR_exoscale_secret_key \
  --set persistence.imageChartStorage.s3.accesskey=$TF_VAR_exoscale_api_key  \
  --set "expose.ingress.hosts.core=harbor.${ECK_DOMAIN}" \
  --set "expose.ingress.hosts.notary=notary.harbor.${ECK_DOMAIN}" \
  --set "externalURL=https://harbor.${ECK_DOMAIN}"

#INFLUXDB
helm upgrade influxdb-prometheus stable/influxdb \
  --install --namespace influxdb-prometheus \
  -f ${SCRIPTS_PATH}/../helm-values/influxdb-values.yaml \
  --set ingress.hostname=influxdb-prometheus.$ECK_DOMAIN

# Deploy prometheus operator and grafana
helm upgrade prometheus-operator stable/prometheus-operator \
  --install --namespace monitoring \
  -f ${SCRIPTS_PATH}/../helm-values/prometheus-ss.yaml \
  --version 6.2.1 \
  --set grafana.ingress.hosts={grafana.${ECK_DOMAIN}} \
  --set grafana.ingress.tls[0].hosts={grafana.${ECK_DOMAIN}}

echo Waiting for harbor to become ready


# TODO: This doesn't handle a second run. The Clair pod gets re-created so the
#       wait thinks it's fine because the old Clair pod is still there but the
#       new Clair pod is not ready yet causing an internal server error
#       response when executing the DELETE request.

# Waiting for "Clair" to be ready.
# We cannot use `--wait` due to this: https://github.com/helm/helm/issues/5170
ready_pods=$(kubectl get deployment -n harbor harbor-harbor-clair -o jsonpath='{.status.readyReplicas}')
# Set default 0 (output is empty if no pod is ready)
until [ ${ready_pods:=0} -eq 1 ]
do
    echo "Waiting for harbor to become ready..."
    sleep 5s
    ready_pods=$(kubectl get deployment -n harbor harbor-harbor-clair -o jsonpath='{.status.readyReplicas}')
done

#
#REMEBER TO REMOVE "-k" from curl! Just here for now because of the let's encrypt certificate limitation!
#

# Deletes the default project "library"
echo Removing old project from harbor
curl -k -X DELETE -u admin:Harbor12345 https://harbor.${ECK_DOMAIN}/api/projects/1

# Creates new private project "default"
echo Creating new private project
curl -k -X POST -u admin:Harbor12345 --header 'Content-Type: application/json' --header 'Accept: application/json' https://harbor.${ECK_DOMAIN}/api/projects --data '{
    "project_name": "default",
    "metadata": {
      "public": "0",
      "enable_content_trust": "false",
      "prevent_vul": "false",
      "severity": "low",
      "auto_scan": "true"
    }
}'
