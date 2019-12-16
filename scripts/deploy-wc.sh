#!/bin/bash

set -e

: "${ECK_SC_KUBECONFIG:?Missing ECK_SC_KUBECONFIG}"

: "${S3_ACCESS_KEY:?Missing S3_ACCESS_KEY}"
: "${S3_SECRET_KEY:?Missing S3_SECRET_KEY}"
: "${S3_REGION:?Missing S3_REGION}"
: "${S3_REGION_ENDPOINT:?Missing S3_REGION_ENDPOINT}"
: "${S3_VELERO_BUCKET_NAME:?Missing S3_VELERO_BUCKET_NAME}"
: "${KUBELOGIN_CLIENT_SECRET:?Missing KUBELOGIN_CLIENT_SECRET}"
: "${ENABLE_OPA:?Missing ENABLE_OPA}"
: "${ENABLE_PSP:?Missing ENABLE_PSP}"
: "${CUSTOMER_NAMESPACES:?Missing CUSTOMER_NAMESPACES}"
: "${CUSTOMER_ADMIN_USERS:?Missing CUSTOMER_ADMIN_USERS}"
: "${PROMETHEUS_CLIENT_SECRET:?Missing PROMETHEUS_CLIENT_SECRET}"
: "${ENABLE_CUSTOMER_PROMETHEUS:?Missing ENABLE_CUSTOMER_PROMETHEUS}"
if [ $ENABLE_CUSTOMER_PROMETHEUS == "true" ]
then
    : "${CUSTOMER_PROMETHEUS_CLIENT_SECRET:?Missing CUSTOMER_PROMETHEUS_CLIENT_SECRET}"
fi

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

source "${SCRIPTS_PATH}/common.sh"

if [[ "$#" -lt 1 ]]
then
  >&2 echo "Usage: deploy-wc.sh path-to-infra-file <--interactive>"
  exit 1
fi

infra="$1"

if [ $CLOUD_PROVIDER == "exoscale" ]
then
export NFS_WC_SERVER_IP=$(cat $infra | jq -r '.workload_cluster.nfs_ip_address')
elif [ $CLOUD_PROVIDER == "safespring" ]
then
export NFS_WC_SERVER_IP=$(cat $infra | jq -r '.workload_cluster.nfs_private_ip_address')
fi

# Arg for Helmfile to be interactive so that one can decide on which releases
# to update if changes are found.
# USE: --interactive, default is not interactive.
INTERACTIVE=${2:-""}

# NAMESPACES
NAMESPACES="cert-manager falco monitoring fluentd ck8sdash"
for namespace in ${NAMESPACES}
do
    kubectl create namespace ${namespace} --dry-run -o yaml | kubectl apply -f -
    kubectl label --overwrite namespace ${namespace} owner=operator
done

if [[ $ENABLE_OPA == "true" ]]
then
    kubectl create namespace opa --dry-run -o yaml | kubectl apply -f -
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

    # Deploy cluster spcific roles and rolebindings
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/workload_cluster/falco-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/workload_cluster/fluentd-psp.yaml

    if [[ $ENABLE_OPA == "true" ]]
    then
        kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/workload_cluster/
    fi
fi

# HELM, TILLER
mkdir -p ${SCRIPTS_PATH}/../clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/certs/workload_cluster/kube-system/certs
${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/certs/workload_cluster "helm"
source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/certs/workload_cluster/kube-system/certs "helm"


# DASHBOARD
kubectl apply -f ${SCRIPTS_PATH}/../manifests/dashboard.yaml


# CERT-MANAGER
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite


issuer_namespaces='kube-system monitoring ck8sdash'
for ns in $issuer_namespaces
do
    export CERT_NAMESPACE=$ns
    envsubst < ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml | kubectl apply -f -
    envsubst < ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml | kubectl apply -f -
done


# OPA
if [[ $ENABLE_OPA == "true" ]]
then
    # Copy original 'allowed_registries'
    cp ${SCRIPTS_PATH}/../policies/allowed_registries.rego ${SCRIPTS_PATH}/../policies/allowed_registries.rego.orig
    # Add our Harbor domain as allowed registry.
    envsubst < ${SCRIPTS_PATH}/../policies/allowed_registries.rego > ${SCRIPTS_PATH}/../policies/allowed_registries.rego.tmp
    mv ${SCRIPTS_PATH}/../policies/allowed_registries.rego.tmp ${SCRIPTS_PATH}/../policies/allowed_registries.rego

    kubectl -n opa create cm policies -o yaml --dry-run \
        --from-file="${SCRIPTS_PATH}/../policies/ingress-whitelist.rego" \
        --from-file="${SCRIPTS_PATH}/../policies/main.rego" \
        --from-file="${SCRIPTS_PATH}/../policies/netpol-demo.rego" \
        --from-file="${SCRIPTS_PATH}/../policies/allowed_registries.rego" | kubectl apply -f -
    kubectl -n opa label cm policies openpolicyagent.org/policy=rego --overwrite
    # Restore original file.
    mv ${SCRIPTS_PATH}/../policies/allowed_registries.rego.orig ${SCRIPTS_PATH}/../policies/allowed_registries.rego
fi

# Prometheus CRDS
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
    helmfile -f helmfile.yaml -e workload_cluster -l app=cert-manager -l app=nginx-ingress $INTERACTIVE apply
else
    # Install cert-manager and nfs-client-provisioner.
    helmfile -f helmfile.yaml -e workload_cluster -l app=cert-manager -l app=nfs-client-provisioner -l app=nginx-ingress $INTERACTIVE apply
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

if [[ $ENABLE_OPA == "true" ]]
then
    # Install rest of the charts excluding fluentd and prometheus.
    helmfile -f helmfile.yaml -e workload_cluster -l app!=cert-manager,app!=nfs-client-provisioner,app!=fluentd-system,app!=fluentd,app!=prometheus-operator,app!=nginx-ingress $INTERACTIVE apply
else
    # Install rest of the charts excluding fluentd, prometheus, and opa.
    helmfile -f helmfile.yaml -e workload_cluster -l app!=cert-manager,app!=nfs-client-provisioner,app!=fluentd-system,app!=fluentd,app!=prometheus-operator,app!=opa,app!=nginx-ingress $INTERACTIVE apply
fi

# Create basic auth credentials for accessing workload cluster prometheus
htpasswd -c -b auth prometheus ${PROMETHEUS_CLIENT_SECRET}
kubectl -n monitoring create secret generic prometheus-auth --from-file=auth --dry-run -o yaml | kubectl apply -f -
rm auth

# Install prometheus-operator. Retry three times.
tries=3
success=false

for i in $(seq 1 $tries)
do
    if helmfile -f helmfile.yaml -e workload_cluster -l app=prometheus-operator $INTERACTIVE apply
    then
        success=true
        break
    else
        echo failed to deploy prometheus operator on try $i
        helmfile -f helmfile.yaml -e workload_cluster -l app=prometheus-operator $INTERACTIVE destroy
    fi
done

# Then prometheus operator failed too many times
if [ $success != "true" ]
then
    exit 1
fi


# FLUENTD
kubectl -n kube-system create secret generic template-secret --from-file=../manifests/logstash_template  --from-file=../manifests/kubecomponents_template --dry-run -o yaml | kubectl apply -f -
kubectl -n fluentd create secret generic template-secret --from-file=../manifests/logstash_template  --from-file=../manifests/kubecomponents_template --dry-run -o yaml | kubectl apply -f -

while [[ $(kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" get elasticsearches.elasticsearch.k8s.elastic.co -n elastic-system elasticsearch -o 'jsonpath={.status.health}') != "green" ]]
do
    echo "Waiting until elasticsearch is ready"
    sleep 2
done

# Get elastisearch password from service_cluster cluster
ES_PW=$(kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)

while [ -z "$ES_PW" ]
do
    echo "Waiting for elasticsearch password"
    sleep 5
    ES_PW=$(kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)
done
echo "Got elsticsearch password"

kubectl -n kube-system create secret generic elasticsearch \
    --from-literal=password="${ES_PW}" --dry-run -o yaml | kubectl apply -f -
kubectl -n fluentd create secret generic elasticsearch \
    --from-literal=password="${ES_PW}" --dry-run -o yaml | kubectl apply -f -

# Install fluentd
helmfile -f helmfile.yaml -e workload_cluster -l app=fluentd $INTERACTIVE apply

# ck8sdash
envsubst < ${SCRIPTS_PATH}/../manifests/ck8sdash/env-secret.yaml | kubectl apply -f -
envsubst < ${SCRIPTS_PATH}/../manifests/ck8sdash/ingress-wc.yaml | kubectl apply -f -
kubectl apply -f ${SCRIPTS_PATH}/../manifests/ck8sdash/service.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/ck8sdash/deployment.yaml

#
# Customer RBAC
#

# Create namespace(s) and RBAC
for namespace in ${CUSTOMER_NAMESPACES}
do
    kubectl create namespace "${namespace}" \
        --dry-run -o yaml | kubectl apply -f -
    for user in ${CUSTOMER_ADMIN_USERS}
    do
        # By using "auth reconcile" instead of "apply" we can add one
        # user at a time.
        kubectl -n "${namespace}" create rolebinding workload-admins \
            --clusterrole=admin --user="${user}" \
            --dry-run -o yaml | kubectl auth reconcile -f -
    done
done


# Create kubeconfig for the customer

# Get server and certificate from the admin kubeconfig generated by RKE
CUSTOMER_SERVER=$(kubectl config view \
    -o jsonpath="{.clusters[0].cluster.server}")
CUSTOMER_CERTIFICATE_AUTHORITY=/tmp/customer-authority.pem
kubectl config view --raw \
    -o jsonpath="{.clusters[0].cluster.certificate-authority-data}" \
    | base64 --decode > ${CUSTOMER_CERTIFICATE_AUTHORITY}

CUSTOMER_KUBECONFIG=${SCRIPTS_PATH}/../clusters/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/customer/kubeconfig.yaml
kubectl --kubeconfig=${CUSTOMER_KUBECONFIG} config set-cluster compliantk8s \
    --server=${CUSTOMER_SERVER} \
    --certificate-authority=${CUSTOMER_CERTIFICATE_AUTHORITY} --embed-certs=true
kubectl --kubeconfig=${CUSTOMER_KUBECONFIG} config set-credentials user \
    --exec-command=kubectl \
    --exec-api-version=client.authentication.k8s.io/v1beta1 \
    --exec-arg=oidc-login \
    --exec-arg=get-token \
    --exec-arg=--oidc-issuer-url=https://dex.${ECK_BASE_DOMAIN} \
    --exec-arg=--oidc-client-id=kubelogin \
    --exec-arg=--oidc-client-secret=${KUBELOGIN_CLIENT_SECRET} \
    --exec-arg=--oidc-extra-scope=email

# Create context with relavant namespace
# This assigns the namespace(s) to $1, $2, etc in order
# so CUSTOMER_NAMESPACES="demo1 demo2 demo3" -> $1=demo1, $2=demo2, $3=demo3
set -- ${CUSTOMER_NAMESPACES}
# Pick the first namespace
CONTEXT_NAMESPACE=$1
kubectl --kubeconfig=${CUSTOMER_KUBECONFIG} config set-context \
    user@compliantk8s \
    --user user --cluster=compliantk8s --namespace=${CONTEXT_NAMESPACE}
kubectl --kubeconfig=${CUSTOMER_KUBECONFIG} config use-context \
    user@compliantk8s

rm ${CUSTOMER_CERTIFICATE_AUTHORITY}

# Allow customer admins to configure fluentd
kubectl apply -f ${SCRIPTS_PATH}/../manifests/customer-rbac/fluentd.yaml

for user in ${CUSTOMER_ADMIN_USERS}
do
    kubectl -n fluentd create rolebinding fluentd-configurer \
        --role=fluentd-configurer --user="${user}" \
        --dry-run -o yaml | kubectl auth reconcile -f -
done

# Add example resources.
# We use `create` here instead of `apply` to avoid overwriting any changes the
# customer may have done.
kubectl create -f ${SCRIPTS_PATH}/../manifests/examples/fluentd/fluentd-extra-config.yaml \
    2> /dev/null || echo "fluentd-extra-config configmap already in place. Ignoring."

if [ $ENABLE_CUSTOMER_PROMETHEUS == "true" ]
then
    # This Prometheus instance could be added just as we do with other prometheus
    # instances in the service cluster using helm, but then we risk overwriting
    # customer changes.
    envsubst < ${SCRIPTS_PATH}/../manifests/examples/monitoring/rbac.yaml | \
        kubectl -n ${CONTEXT_NAMESPACE} create -f - 2> /dev/null || \
        echo "Example prometheus RBAC alredy in place. Ignoring."
    envsubst < ${SCRIPTS_PATH}/../manifests/examples/monitoring/ingress.yaml | \
        kubectl -n ${CONTEXT_NAMESPACE} create -f - 2> /dev/null || \
        echo "Example ingress alredy in place. Ignoring."
    kubectl -n ${CONTEXT_NAMESPACE} create -f ${SCRIPTS_PATH}/../manifests/examples/monitoring/issuer.yaml \
        2> /dev/null || echo "Example issuer alredy in place. Ignoring."
    kubectl -n ${CONTEXT_NAMESPACE} create -f ${SCRIPTS_PATH}/../manifests/examples/monitoring/prometheus.yaml \
        2> /dev/null || echo "Example prometheus alredy in place. Ignoring."
    # Create basic auth credentials for the customers prometheus instance
    htpasswd -c -b auth prometheus ${CUSTOMER_PROMETHEUS_CLIENT_SECRET}
    kubectl -n ${CONTEXT_NAMESPACE} create secret generic prometheus-auth --from-file=auth \
        2> /dev/null || echo "Example prometheus auth secret alredy in place. Ignoring."
    rm auth
fi
