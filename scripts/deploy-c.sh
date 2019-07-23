#!/bin/bash

set -e

: "${ECK_SS_KUBECONFIG:?Missing ECK_SS_KUBECONFIG}"

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

source "${SCRIPTS_PATH}/deploy-common.sh"

pushd "${SCRIPTS_PATH}/../terraform/customer/" > /dev/null

# Elastic ip for the customer cluster.
E_IP=$(terraform output c-elastic-ip)

popd > /dev/null

pushd "${SCRIPTS_PATH}/../terraform/system-services/" > /dev/null

# Elastic ip for the system services cluster.
SS_E_IP=$(terraform output ss-elastic-ip)

popd > /dev/null

ES_PW=$(kubectl --kubeconfig="${ECK_SS_KUBECONFIG}" get secret quickstart-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)

# NAMESPACES

kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
kubectl create namespace restricted-namespace --dry-run -o yaml | kubectl apply -f -

# Node restriction
sh ${SCRIPTS_PATH}/node-restriction.sh

# PSP

kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access-c.yaml

# HELM, TILLER

mkdir -p ${SCRIPTS_PATH}/../certs/customer/kube-system/certs

${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/customer "admin1"

source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/customer/kube-system/certs admin1



# CERT-MANAGER

# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# https://docs.cert-manager.io/en/latest/getting-started/install.html#installing-with-helm
# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update

helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.0



# FLUENTD

kubectl apply -f ${SCRIPTS_PATH}/../manifests/fluentd/sa-rbac.yaml

kubectl -n kube-system create secret generic elasticsearch \
    --from-literal=password="${ES_PW}" --dry-run -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
    version: v1
    kubernetes.io/cluster-service: "true"
spec:
  template:
    metadata:
      labels:
        k8s-app: fluentd-logging
        version: v1
        kubernetes.io/cluster-service: "true"
    spec:
      serviceAccount: fluentd
      serviceAccountName: fluentd
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.4.2-debian-elasticsearch-1.0
        env:
          - name: FLUENT_UID
            value: "0"
          - name:  FLUENT_ELASTICSEARCH_HOST
            value: "elastic.${ECK_DOMAIN}"
          - name:  FLUENT_ELASTICSEARCH_PORT
            value: "443"
          - name: FLUENT_ELASTICSEARCH_SCHEME
            value: "https"
          # X-Pack Authentication
          # =====================
          - name: FLUENT_ELASTICSEARCH_USER
            value: "elastic"
          - name: FLUENT_ELASTICSEARCH_PASSWORD
            valueFrom:
              secretKeyRef:
                name: elasticsearch
                key: password
          # Option to configure elasticsearch plugin with self signed certs
          # ================================================================
          - name: FLUENT_ELASTICSEARCH_SSL_VERIFY
            value: "false"
          - name: FLUENT_ELASTICSEARCH_SSL_VERSION
            value: "TLSv1_2"
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlogjournal
          mountPath: /var/log/journal
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlogjournal
        hostPath:
          path: /var/log/journal
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
EOF
