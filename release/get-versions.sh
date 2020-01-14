#!/bin/bash

APPS="prometheus,grafana,harbor,falco,fluentd,velero,nginx-ingress"
kubectl get pods --all-namespaces --selector="app in (${APPS}) " -o json | jq -r '.items[].spec.containers[].image' | sed 's|.*/||'
kubectl get pods --all-namespaces --selector="app.kubernetes.io/name in (${APPS}) " -o json | jq -r '.items[].spec.containers[].image' | sed 's|.*/||'
echo -e "elasticsearch:`kubectl get elasticsearch -n elastic-system -o json | jq -r '.items[].spec.version'`"
