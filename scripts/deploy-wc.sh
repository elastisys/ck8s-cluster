#!/bin/bash

set -e

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
: "${PROMETHEUS_PWD:?Missing PROMETHEUS_PWD}"
: "${HARBOR_PWD:?Missing HARBOR_PWD}"
: "${CUSTOMER_GRAFANA_PWD:?Missing CUSTOMER_GRAFANA_PWD}"
: "${ELASTIC_USER_SECRET:?Missing ELASTIC_USER_SECRET}"
: "${ENABLE_CUSTOMER_PROMETHEUS:?Missing ENABLE_CUSTOMER_PROMETHEUS}"
if [ $ENABLE_CUSTOMER_PROMETHEUS == "true" ]
then
    : "${CUSTOMER_PROMETHEUS_PWD:?Missing CUSTOMER_PROMETHEUS_PWD}"
fi
: "${ENABLE_CUSTOMER_ALERTMANAGER:?Missing ENABLE_CUSTOMER_ALERTMANAGER}"
if [ $ENABLE_CUSTOMER_ALERTMANAGER == "true" ]
then
    : "${ENABLE_CUSTOMER_ALERTMANAGER_INGRESS:?Missing ENABLE_CUSTOMER_ALERTMANAGER_INGRESS}"
    if [ $ENABLE_CUSTOMER_ALERTMANAGER_INGRESS == "true" ]
    then
        : "${CUSTOMER_ALERTMANAGER_PWD:?Missing CUSTOMER_ALERTMANAGER_PWD}"
    fi
fi

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
# Arg for Helmfile to be interactive so that one can decide on which releases
# to update if changes are found.
# USE: --interactive, default is not interactive.
INTERACTIVE=${1:-""}

# NAMESPACES
NAMESPACES="cert-manager monitoring fluentd ck8sdash"

[ "$ENABLE_FALCO" == "true" ] && NAMESPACES+=" falco"
[ "$ENABLE_OPA" == "true" ] && NAMESPACES+=" opa"

for namespace in ${NAMESPACES}
do
    kubectl create namespace ${namespace} --dry-run -o yaml | kubectl apply -f -
    kubectl label --overwrite namespace ${namespace} owner=operator
done

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

    # Deploy cluster spcific roles and rolebindings
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/workload_cluster/fluentd-psp.yaml

    if [[ $ENABLE_FALCO == "true" ]]
    then
        kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/workload_cluster/falco-psp.yaml
    fi

    if [[ $ENABLE_OPA == "true" ]]
    then
        kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/workload_cluster/opa-psp.yaml
    fi
fi

# HELM, TILLER
mkdir -p ${CONFIG_PATH}/certs/workload_cluster/kube-system/certs
${SCRIPTS_PATH}/initialize-cluster.sh ${CONFIG_PATH}/certs/workload_cluster "helm"
source ${SCRIPTS_PATH}/helm-env.sh kube-system ${CONFIG_PATH}/certs/workload_cluster/kube-system/certs "helm"


# CERT-MANAGER
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite


issuer_namespaces='kube-system monitoring ck8sdash'
for ns in $issuer_namespaces
do
    kubectl -n ${ns} apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml
    kubectl -n ${ns} apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml
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

charts_ignore_list="app!=cert-manager,app!=nfs-client-provisioner,app!=fluentd-system,app!=fluentd,app!=prometheus-operator,app!=nginx-ingress"

[[ $ENABLE_OPA != "true" ]] && charts_ignore_list+=",app!=opa"
[[ $ENABLE_FALCO != "true" ]] && charts_ignore_list+=",app!=falco"

# Install rest of the charts excluding charts in charts_ignore_list.
helmfile -f helmfile.yaml -e workload_cluster -l "$charts_ignore_list" $INTERACTIVE apply

# Create basic auth credentials for accessing workload cluster prometheus
htpasswd -c -b auth prometheus ${PROMETHEUS_PWD}
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
kubectl -n kube-system create secret generic template-secret --from-file=../manifests/other_template \
    --from-file=../manifests/kubecomponents_template --from-file=../manifests/kubeaudit_template \
    --from-file=../manifests/kubernetes_template --dry-run -o yaml | kubectl apply -f -
kubectl -n fluentd create secret generic template-secret --from-file=../manifests/other_template \
    --from-file=../manifests/kubecomponents_template --from-file=../manifests/kubeaudit_template \
    --from-file=../manifests/kubernetes_template --dry-run -o yaml | kubectl apply -f -

# Password for accessing elasticsearch
kubectl -n kube-system create secret generic elasticsearch \
    --from-literal=password="${ELASTIC_USER_SECRET}" --dry-run -o yaml | kubectl apply -f -
kubectl -n fluentd create secret generic elasticsearch \
    --from-literal=password="${ELASTIC_USER_SECRET}" --dry-run -o yaml | kubectl apply -f -

# Install fluentd
helmfile -f helmfile.yaml -e workload_cluster -l app=fluentd $INTERACTIVE apply

# Install ck8sdash
kubectl apply -f ${SCRIPTS_PATH}/../manifests/ck8sdash/service-account.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/ck8sdash/init-script-cm.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/ck8sdash/info-text-cm.yaml
envsubst < ${SCRIPTS_PATH}/../manifests/ck8sdash/env-secret-wc.yaml | kubectl apply -f -
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

CUSTOMER_KUBECONFIG=${CONFIG_PATH}/customer/kubeconfig.yaml
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
kubectl create -f ${SCRIPTS_PATH}/../manifests/examples/fluentd/fluentd-extra-plugins.yaml \
    2> /dev/null || echo "fluentd-extra-plugins configmap already in place. Ignoring."

if [ $ENABLE_CUSTOMER_PROMETHEUS == "true" ]
then
    # This Prometheus instance could be added just as we do with other prometheus
    # instances in the service cluster using helm, but then we risk overwriting
    # customer changes.
    envsubst < ${SCRIPTS_PATH}/../manifests/examples/monitoring/prometheus-rbac.yaml | \
        kubectl -n ${CONTEXT_NAMESPACE} create -f - 2> /dev/null || \
        echo "Example prometheus RBAC alredy in place. Ignoring."
    envsubst < ${SCRIPTS_PATH}/../manifests/examples/monitoring/prometheus-ingress.yaml | \
        kubectl -n ${CONTEXT_NAMESPACE} create -f - 2> /dev/null || \
        echo "Example ingress alredy in place. Ignoring."
    kubectl -n ${CONTEXT_NAMESPACE} create -f ${SCRIPTS_PATH}/../manifests/examples/monitoring/issuer.yaml \
        2> /dev/null || echo "Example issuer alredy in place. Ignoring."
    envsubst < ${SCRIPTS_PATH}/../manifests/examples/monitoring/prometheus.yaml | \
        kubectl -n ${CONTEXT_NAMESPACE} create -f - 2> /dev/null || \
        echo "Example prometheus alredy in place. Ignoring."
    # Create basic auth credentials for the customers prometheus instance
    htpasswd -c -b auth prometheus ${CUSTOMER_PROMETHEUS_PWD}
    kubectl -n ${CONTEXT_NAMESPACE} create secret generic prometheus-auth --from-file=auth \
        2> /dev/null || echo "Example prometheus auth secret alredy in place. Ignoring."
    rm auth
fi

if [ $ENABLE_CUSTOMER_ALERTMANAGER == "true" ]
then
    # Use `kubectl create` to avoid overwriting customer changes
    kubectl -n ${CONTEXT_NAMESPACE} create -f ${SCRIPTS_PATH}/../manifests/examples/monitoring/issuer.yaml \
        2> /dev/null || echo "Example issuer alredy in place. Ignoring."
    kubectl -n ${CONTEXT_NAMESPACE} create -f ${SCRIPTS_PATH}/../manifests/examples/monitoring/alertmanager-instance.yaml \
        2> /dev/null || echo "Example alertmanager alredy in place. Ignoring."

    if [ $ENABLE_CUSTOMER_ALERTMANAGER_INGRESS == "true" ]
    then
        envsubst < ${SCRIPTS_PATH}/../manifests/examples/monitoring/alertmanager-ingress.yaml | \
            kubectl -n ${CONTEXT_NAMESPACE} create -f - 2> /dev/null || \
            echo "Example ingress alredy in place. Ignoring."
        # Create alertmanager config secret
        # Note that the name must match alertmanager-{ALERTMANAGER_NAME}
        # See https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/alerting.md
        kubectl -n ${CONTEXT_NAMESPACE} create secret generic alertmanager-alertmanager \
            --from-file=alertmanager.yaml=${SCRIPTS_PATH}/../manifests/examples/monitoring/alertmanager-config.yaml \
            2> /dev/null || echo "Example alertmanager config secret alredy in place. Ignoring."
        # Create basic auth credentials for the customers alertmanager instance
        htpasswd -c -b auth alertmanager ${CUSTOMER_ALERTMANAGER_PWD}
        kubectl -n ${CONTEXT_NAMESPACE} create secret generic alertmanager-auth --from-file=auth \
            2> /dev/null || echo "Example alertmanager auth secret alredy in place. Ignoring."
        rm auth
    fi
fi
