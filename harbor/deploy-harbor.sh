#!/bin/bash

# Dir where this script is located
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
WORKSPACE="${SCRIPT_DIR}/../"

kubectl create ns harbor --dry-run -o yaml | kubectl apply -f -
kubectl -n harbor create rolebinding harbor-privileged-psp \
    --clusterrole=psp:privileged --serviceaccount=harbor:default \
    --dry-run -o yaml | kubectl apply -f -
helm upgrade harbor harbor/harbor \
  --install \
  --namespace harbor \
  --values ${SCRIPT_DIR}/harbor-values.yaml
