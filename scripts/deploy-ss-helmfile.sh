#!/bin/bash

# Maybe some of the following could be installed using charts by helmfile.

set -e
SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
source "${SCRIPTS_PATH}/common.sh"

: "${TF_VAR_exoscale_api_key:?Missing TF_VAR_exoscale_api_key}"
: "${TF_VAR_exoscale_secret_key:?Missing TF_VAR_exoscale_secret_key}"
: "${GOOGLE_CLIENT_ID:?Missing GOOGLE_CLIENT_ID}"
: "${GOOGLE_CLIENT_SECRET:?Missing GOOGLE_CLIENT_SECRET}"


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


# HELM and TILLER
mkdir -p ${SCRIPTS_PATH}/../certs/system-services/kube-system/certs
${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/system-services "admin1"
source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/system-services/kube-system/certs admin1


# DASHBOARD
kubectl apply -f ${SCRIPTS_PATH}/../manifests/dashboard.yaml


# CERT-MANAGER
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers


# Elasticsearch and kibana.
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/operator.yaml
sleep 5
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/elasticsearch.yaml
sleep 5
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


#
# The following needs to be handled after the the harbor release in the helmfile as been applied.
# Thus, this should be moved and exectued somewhere else. 
#
    # # TODO: This doesn't handle a second run. The Clair pod gets re-created so the
    # #       wait thinks it's fine because the old Clair pod is still there but the
    # #       new Clair pod is not ready yet causing an internal server error
    # #       response when executing the DELETE request.
    #echo Waiting for harbor to become ready
    # # Waiting for "Clair" to be ready.
    # # We cannot use `--wait` due to this: https://github.com/helm/helm/issues/5170
    # ready_pods=$(kubectl get deployment -n harbor harbor-harbor-clair -o jsonpath='{.status.readyReplicas}')
    # # Set default 0 (output is empty if no pod is ready)
    # until [ ${ready_pods:=0} -eq 1 ]
    # do
    #     echo "Waiting for harbor to become ready..."
    #     sleep 5s
    #     ready_pods=$(kubectl get deployment -n harbor harbor-harbor-clair -o jsonpath='{.status.readyReplicas}')
    # done


    # # Deletes the default project "library"
    # echo Removing old project from harbor
    # curl -k -X DELETE -u admin:Harbor12345 https://harbor.${ECK_SS_DOMAIN}/api/projects/1

    # # Creates new private project "default"
    # echo Creating new private project
    # curl -k -X POST -u admin:Harbor12345 --header 'Content-Type: application/json' --header 'Accept: application/json' https://harbor.${ECK_SS_DOMAIN}/api/projects --data '{
    #     "project_name": "default",
    #     "metadata": {
    #       "public": "0",
    #       "enable_content_trust": "false",
    #       "prevent_vul": "false",
    #       "severity": "low",
    #       "auto_scan": "true"
    #     }
    # }'