#!/bin/bash

# Set variables and array adapted for the service cluster and call functions in prometheus-common

INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source $INNER_SCRIPTS_PATH/../prometheus-common.sh

# Get amount of nodes in cluster
totalNodes=$(kubectl get nodes --no-headers | wc -l)
masterNodes=$(kubectl get nodes -l node-role.kubernetes.io/master --no-headers | wc -l)
# Note: workers are simply non-masters, so we select all that do NOT have the master label
workerNodes=$(kubectl get nodes -l node-role.kubernetes.io/master!= --no-headers | wc -l)

echo
echo
echo "Testing service cluster prometheus"
echo "=================================="
{
# Run port-forward instance as a background process
kubectl port-forward -n monitoring svc/prometheus-operator-prometheus 9090 &
PF_PID=$!
sleep 3
# Call simplifyData function in prometheus-common, reduces the dataset
simplifyData
} &> /dev/null

# Not using these targets atm
# TODO: add elements to the list when they start being used.
# "monitoring/prometheus-operator-kube-etcd/0 1"
# "monitoring/prometheus-operator-kube-proxy/0 1"
scTargets=(
    "elastic-system/elasticsearch-prometheus-exporter-elasticsearch-exporter/0 1"
    "monitoring/blackbox-exporter-customer-api-server/0 1"
    "monitoring/blackbox-exporter-dex/0 1"
    "monitoring/blackbox-exporter-grafana/0 1"
    "monitoring/blackbox-exporter-kibana/0 1"
    "monitoring/influxdb-du-monitoring-service-monitor/0 1"
    "monitoring/prometheus-operator-alertmanager/0 1"
    "monitoring/prometheus-operator-apiserver/0 ${masterNodes}"
    "monitoring/prometheus-operator-coredns/0 2"
    "monitoring/prometheus-operator-grafana/0 1"
    "monitoring/prometheus-operator-kube-state-metrics/0 1"
    "monitoring/prometheus-operator-kubelet/0 ${totalNodes}"
    "monitoring/prometheus-operator-kubelet/1 ${totalNodes}"
    "monitoring/prometheus-operator-node-exporter/0 ${totalNodes}"
    "monitoring/prometheus-operator-operator/0 1"
    "monitoring/prometheus-operator-prometheus/0 1"
)

# Call functions from prometheus-common
for scTarget in "${scTargets[@]}"
do
    check_instances $scTarget
done

kill "${PF_PID}"
wait "${PF_PID}" 2>/dev/null


# wc-scraper-prometheus
# Set variables and array adapted for the service cluster (wc-scraper-prometheus service) and call functions in prometheus-common
echo
echo
echo "Testing wc scraper prometheus"
echo "============================="

{
# Run port-forward instance as a background process
kubectl port-forward -n monitoring svc/wc-scraper-prometheus-instance 9090 &
PF_PID=$!
sleep 3
# Call simplifyData function in prometheus-common, reduces the dataset
simplifyData
} &> /dev/null

scraperTargets=(
    "federate-kubelet 1"
    "federate-others 1"
)

# Call functions from prometheus-common
for scraperTarget in "${scraperTargets[@]}"
do
    check_instances $scraperTarget
done

kill "${PF_PID}"
wait "${PF_PID}" 2>/dev/null
