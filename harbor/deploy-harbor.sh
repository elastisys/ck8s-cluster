#!/bin/bash

# Dir where this script is located
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
WORKSPACE="${SCRIPT_DIR}/../"

kubectl create ns harbor --dry-run -o yaml | kubectl apply -f -
kubectl -n harbor create rolebinding harbor-privileged-psp \
    --clusterrole=psp:privileged --serviceaccount=harbor:default \
    --dry-run -o yaml | kubectl apply -f -
helm upgrade harbor ${WORKSPACE}/charts/harbor \
  --install --version 1.1.0 \
  --namespace harbor \
  --values ${SCRIPT_DIR}/harbor-values.yaml

# The harbor chart modifies the ingress annotations, so we do it with this hack instead
kubectl -n harbor annotate ingress harbor-harbor-ingress certmanager.k8s.io/cluster-issuer=letsencrypt-prod
