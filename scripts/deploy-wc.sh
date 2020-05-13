#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"
: "${S3_ACCESS_KEY:?Missing S3_ACCESS_KEY}"
: "${S3_SECRET_KEY:?Missing S3_SECRET_KEY}"
: "${S3_REGION:?Missing S3_REGION}"
: "${S3_REGION_ENDPOINT:?Missing S3_REGION_ENDPOINT}"
: "${S3_VELERO_BUCKET_NAME:?Missing S3_VELERO_BUCKET_NAME}"
: "${KUBELOGIN_CLIENT_SECRET:?Missing KUBELOGIN_CLIENT_SECRET}"
: "${ENABLE_OPA:?Missing ENABLE_OPA}"
: "${ENABLE_PSP:?Missing ENABLE_PSP}"
: "${ENABLE_CK8SDASH_WC:?Missing ENABLE_CK8SDASH_WC}"
: "${CUSTOMER_NAMESPACES:?Missing CUSTOMER_NAMESPACES}"
: "${CUSTOMER_ADMIN_USERS:?Missing CUSTOMER_ADMIN_USERS}"
: "${HARBOR_PWD:?Missing HARBOR_PWD}"
: "${CUSTOMER_GRAFANA_PWD:?Missing CUSTOMER_GRAFANA_PWD}"
: "${ELASTIC_USER_SECRET:?Missing ELASTIC_USER_SECRET}"
: "${CUSTOMER_PROMETHEUS_PWD:?Missing CUSTOMER_PROMETHEUS_PWD}"
: "${ENABLE_CUSTOMER_ALERTMANAGER:?Missing ENABLE_CUSTOMER_ALERTMANAGER}"
if [ $ENABLE_CUSTOMER_ALERTMANAGER == "true" ]
then
    : "${ENABLE_CUSTOMER_ALERTMANAGER_INGRESS:?Missing ENABLE_CUSTOMER_ALERTMANAGER_INGRESS}"
    if [ $ENABLE_CUSTOMER_ALERTMANAGER_INGRESS == "true" ]
    then
        : "${CUSTOMER_ALERTMANAGER_PWD:?Missing CUSTOMER_ALERTMANAGER_PWD}"
    fi
fi

source ${SCRIPTS_PATH}/set-storage-class.sh

export CLUSTER_NAME="${ENVIRONMENT_NAME}_${CLOUD_PROVIDER}"
export CUSTOMER_NAMESPACES_COMMASEPARATED=$(echo "$CUSTOMER_NAMESPACES" | tr ' ' ,)
export CUSTOMER_ADMIN_USERS_COMMASEPARATED=$(echo "$CUSTOMER_ADMIN_USERS" | tr ' ' ,)

# Arg for Helmfile to be interactive so that one can decide on which releases
# to update if changes are found.
# USE: --interactive, default is not interactive.
INTERACTIVE=${1:-""}

echo "Creating namespaces" >&2
NAMESPACES="cert-manager fluentd kube-node-lease kube-public kube-system monitoring nginx-ingress velero"
[ "$ENABLE_CK8SDASH_WC" == "true" ] && NAMESPACES+=" ck8sdash"
[ "$ENABLE_FALCO" == "true" ] && NAMESPACES+=" falco"
[ "$ENABLE_OPA" == "true" ] && NAMESPACES+=" opa"

for namespace in ${NAMESPACES}
do
    kubectl create namespace ${namespace} --dry-run -o yaml | kubectl apply -f -
    kubectl label --overwrite namespace ${namespace} owner=operator
done

echo "Creating pod security policies" >&2
if [[ $ENABLE_PSP == "true" ]]
then
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml

    # Deploy common roles and rolebindings.
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/common/kube-system-role-psp.yaml
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

echo "Preparing cert-manager and issuers" >&2
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite


issuer_namespaces='kube-system monitoring'
[ "$ENABLE_CK8SDASH_WC" == "true" ] && issuer_namespaces+=" ck8sdash"
for ns in $issuer_namespaces
do
    kubectl -n ${ns} apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml
    kubectl -n ${ns} apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml
done

echo -e "Continuing with Helmfile" >&2
cd ${SCRIPTS_PATH}/../helmfile

echo "Installing cert-manager" >&2
helmfile -f helmfile.yaml -e workload_cluster -l app=cert-manager $INTERACTIVE apply --suppress-diff

source ${SCRIPTS_PATH}/install-storage-class-provider.sh
install_storage_class_provider "${STORAGE_CLASS}" workload_cluster

charts_ignore_list="app!=cert-manager,app!=nfs-client-provisioner,app!=fluentd-system,app!=fluentd,app!=prometheus-operator"
[[ $ENABLE_OPA != "true" ]] && charts_ignore_list+=",app!=opa"
[[ $ENABLE_FALCO != "true" ]] && charts_ignore_list+=",app!=falco"
[[ $ENABLE_CK8SDASH_WC != "true" ]] && charts_ignore_list+=",app!=ck8sdash"

echo "Installing the remaining helm charts" >&2
helmfile -f helmfile.yaml -e workload_cluster -l "$charts_ignore_list" $INTERACTIVE apply --suppress-diff

echo "Create basic auth credentials for accessing workload cluster prometheus" >&2
htpasswd -c -b auth prometheus ${CUSTOMER_PROMETHEUS_PWD}
kubectl -n monitoring create secret generic prometheus-auth --from-file=auth --dry-run -o yaml | kubectl apply -f -
rm auth

echo "Installing prometheus operator" >&2
tries=3
success=false

for i in $(seq 1 $tries)
do
    if helmfile -f helmfile.yaml -e workload_cluster -l app=prometheus-operator $INTERACTIVE apply --suppress-diff
    then
        success=true
        break
    else
        echo failed to deploy prometheus operator on try $i
        helmfile -f helmfile.yaml -e workload_cluster -l app=prometheus-operator $INTERACTIVE destroy
    fi
done


if [ $success != "true" ]
then
    echo "Error: Prometheus failed to install three times" >&2
    exit 1
fi


echo "Creating Elasticsearch and fluentd secrets" >&2

kubectl -n kube-system create secret generic elasticsearch \
    --from-literal=password="${ELASTIC_USER_SECRET}" --dry-run -o yaml | kubectl apply -f -
kubectl -n fluentd create secret generic elasticsearch \
    --from-literal=password="${ELASTIC_USER_SECRET}" --dry-run -o yaml | kubectl apply -f -

echo "Installing fluentd" >&2
helmfile -f helmfile.yaml -e workload_cluster -l app=fluentd $INTERACTIVE apply --suppress-diff

# TODO: Move this to separate command
echo "Creating kubeconfig for the customer" >&2

# Get server and certificate from the admin kubeconfig
CUSTOMER_SERVER=$(kubectl config view \
    -o jsonpath="{.clusters[0].cluster.server}")
CUSTOMER_CERTIFICATE_AUTHORITY=/tmp/customer-authority.pem
kubectl config view --raw \
    -o jsonpath="{.clusters[0].cluster.certificate-authority-data}" \
    | base64 --decode > ${CUSTOMER_CERTIFICATE_AUTHORITY}

CUSTOMER_KUBECONFIG=${CONFIG_PATH}/customer/kubeconfig.yaml

if [ -f "${CUSTOMER_KUBECONFIG}" ]; then
    sops --config "${CONFIG_PATH}/.sops.yaml" -d -i "${CUSTOMER_KUBECONFIG}"
fi

kubectl --kubeconfig=${CUSTOMER_KUBECONFIG} config set-cluster ${CLUSTER_NAME} \
    --server=${CUSTOMER_SERVER} \
    --certificate-authority=${CUSTOMER_CERTIFICATE_AUTHORITY} --embed-certs=true
kubectl --kubeconfig=${CUSTOMER_KUBECONFIG} config set-credentials user@${CLUSTER_NAME} \
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
    ${CLUSTER_NAME} \
    --user user@${CLUSTER_NAME} --cluster=${CLUSTER_NAME} --namespace=${CONTEXT_NAMESPACE}
kubectl --kubeconfig=${CUSTOMER_KUBECONFIG} config use-context \
    ${CLUSTER_NAME}

sops --config "${CONFIG_PATH}/.sops.yaml" -e -i "${CUSTOMER_KUBECONFIG}"

rm ${CUSTOMER_CERTIFICATE_AUTHORITY}

# Add example resources.
# We use `create` here instead of `apply` to avoid overwriting any changes the
# customer may have done.
kubectl create -f ${SCRIPTS_PATH}/../manifests/examples/fluentd/fluentd-extra-config.yaml \
    2> /dev/null || echo "fluentd-extra-config configmap already in place. Ignoring."
kubectl create -f ${SCRIPTS_PATH}/../manifests/examples/fluentd/fluentd-extra-plugins.yaml \
    2> /dev/null || echo "fluentd-extra-plugins configmap already in place. Ignoring."

if [ "$ENABLE_CUSTOMER_ALERTMANAGER" == "true" ]
then
    echo "Adding customer alertmanager" >&2
    # Use `kubectl create` to avoid overwriting customer changes
    if [ "$ENABLE_CUSTOMER_ALERTMANAGER_INGRESS" == "true" ]
    then
        htpasswd -c -b auth alertmanager "${CUSTOMER_ALERTMANAGER_PWD}"
        kubectl -n "monitoring" create secret generic alertmanager-auth \
            --from-file=auth 2> /dev/null || \
            echo "Example alertmanager auth secret already in place. Ignoring."
        rm auth
    fi
    helm template ./charts/examples/customer-alertmanager \
            --namespace "monitoring" \
            --set baseDomain="${ECK_BASE_DOMAIN}" \
            --set ingress.enabled="$ENABLE_CUSTOMER_ALERTMANAGER_INGRESS" \
            | kubectl -n "monitoring" create -f - 2> /dev/null || \
            echo "Example alertmanager already in place. Ignoring."
fi
echo "Deploy-wc completed!" >&2
