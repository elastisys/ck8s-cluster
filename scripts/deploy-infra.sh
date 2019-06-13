#!/bin/bash

# Dir where this script is located
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
WORKSPACE="${SCRIPT_DIR}/../"

#
# Falco
#

# https://github.com/helm/charts/tree/master/stable/falco
helm upgrade falco stable/falco --install --namespace falco --version 0.7.6

# Faclo requires privileged PSP and does not include its own policy in the chart
kubectl -n falco create rolebinding falco-privileged-psp \
    --clusterrole=psp:privileged --serviceaccount=falco:falco \
    --dry-run -o yaml | kubectl apply -f -

#
# Nginx-ingress
#

# https://github.com/helm/charts/tree/master/stable/nginx-ingress
helm upgrade nginx-ingress stable/nginx-ingress --install \
    --namespace nginx-ingress --version 1.6.16 \
    -f ${WORKSPACE}/helm-values/nginx-ingress.yaml

#
# Cert-manager
#

# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# https://docs.cert-manager.io/en/latest/getting-started/install.html#installing-with-helm
# Create the namespace for cert-manager
kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite
# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update

helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.0
# Create letsencrypt-staging and prod ClusterIssuers
kubectl apply -f ${WORKSPACE}/manifests/issuers/letsencrypt-staging.yaml
kubectl apply -f ${WORKSPACE}/manifests/issuers/letsencrypt-prod.yaml

#
# Dex
#

# https://github.com/helm/charts/tree/master/stable/dex
helm upgrade dex ${WORKSPACE}/charts/dex --install --namespace dex \
    -f ${WORKSPACE}/helm-values/dex-values.yaml

#
# Dashboard and Oauth2 proxy
#

# https://github.com/helm/charts/tree/master/stable/oauth2-proxy
helm upgrade oauth2 stable/oauth2-proxy --install --namespace kube-system \
    -f ${WORKSPACE}/helm-values/oauth2-proxy-values.yaml

kubectl apply -f ${WORKSPACE}/manifests/dashboard.yaml

#
# Harbor
#

kubectl create ns harbor --dry-run -o yaml | kubectl apply -f -
kubectl -n harbor create rolebinding harbor-privileged-psp \
    --clusterrole=psp:privileged --serviceaccount=harbor:default \
    --dry-run -o yaml | kubectl apply -f -
helm upgrade harbor ${WORKSPACE}/charts/harbor \
  --install \
  --namespace harbor \
  --values ${WORKSPACE}/helm-values/harbor-values.yaml

# The harbor chart modifies the ingress annotations, so we do it with this hack instead
kubectl -n harbor annotate ingress harbor-harbor-ingress certmanager.k8s.io/cluster-issuer=letsencrypt-prod

#
# OPA
#

kubectl create namespace opa
kubectl create namespace opa-test
kubectl label ns kube-system openpolicyagent.org/webhook=ignore --overwrite
kubectl label ns opa openpolicyagent.org/webhook=ignore --overwrite

openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -days 100000 -out ca.crt -subj "/CN=admission_ca"


openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=opa.opa.svc" -config ${WORKSPACE}/manifests/opa/server.conf
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 100000 -extensions v3_req -extfile ${WORKSPACE}/manifests/opa/server.conf

kubectl create secret tls opa-server --cert=server.crt --key=server.key -n opa
kubectl apply -f ${WORKSPACE}/manifests/opa/opa-psp-rolebinding.yaml
kubectl apply -f ${WORKSPACE}/manifests/opa/opa-test-psp-rolebinding.yaml
kubectl apply -f ${WORKSPACE}/manifests/opa/admission-controller.yaml

kubectl apply -f - <<EOF
kind: ValidatingWebhookConfiguration
apiVersion: admissionregistration.k8s.io/v1beta1
metadata:
  name: opa-validating-webhook
  namespace: opa
webhooks:
  - name: validating-webhook.openpolicyagent.org
    namespaceSelector:
      matchExpressions:
      - key: openpolicyagent.org/webhook
        operator: NotIn
        values:
        - ignore
    rules:
      - operations: ["CREATE", "UPDATE"]
        apiGroups: ["*"]
        apiVersions: ["*"]
        resources: ["*"]
    clientConfig:
      caBundle: $(cat ca.crt | base64 | tr -d '\n')
      service:
        namespace: opa
        name: opa
EOF

kubectl create configmap network-policy --from-file=${WORKSPACE}/manifests/opa/policy.rego -n opa
