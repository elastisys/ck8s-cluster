#!/bin/bash

# Set variables and array adapted for the workload cluster and call functions in prometheus-common

INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source $INNER_SCRIPTS_PATH/../prometheus-common.sh

# Get amount of nodes in cluster
totalNodes=$(kubectl get nodes -o json | jq '.items[] | .metadata.name' | wc -l)
workerNodes=$(kubectl get nodes -l node-role.kubernetes.io/worker -o json | jq '.items[] | .metadata.name' | wc -l)

echo
echo
echo "Testing workload cluster prometheus"
echo "==================================="

{
# Run port-forward instance as a background process
kubectl port-forward -n monitoring svc/prometheus-operator-prometheus 9090 &
PF_PID=$!
sleep 3
# Call simplifyData function in prometheus-common, reduces the dataset
simplifyData
} &> /dev/null

# Reset variables for second prometheus
HEALTHY=0
UNHEALTHY=0
FOUND=0
MISSING=0

# Not using these targets atm
# TODO: add elements to the list when they start being used.
# "monitoring/prometheus-operator-kube-etcd/0 1"
# "monitoring/prometheus-operator-kube-proxy/0 1"
wcTargets=(
    "monitoring/prometheus-operator-apiserver/0 1"
    "monitoring/prometheus-operator-coredns/0 1"
    "monitoring/prometheus-operator-kube-state-metrics/0 1"
    "monitoring/prometheus-operator-kubelet/0 ${totalNodes}"
    "monitoring/prometheus-operator-kubelet/1 ${totalNodes}"
    "monitoring/prometheus-operator-node-exporter/0 ${workerNodes}"
    "monitoring/prometheus-operator-operator/0 1"
    "monitoring/prometheus-operator-prometheus/0 1"
)

# Call functions from prometheus-common
for wcTarget in "${wcTargets[@]}"
do
    check_instances $wcTarget
done
count_healthy

kill "${PF_PID}"
wait "${PF_PID}" 2>/dev/null