#!/bin/bash

SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"

SUCCESSES=0
FAILURES=0
DEBUG_OUTPUT=("")
DEBUG_PROMETHEUS_TARGETS=("")
CLUSTER="WorkloadCluster"

source ${SCRIPTS_PATH}/workload-cluster/testPodsReady.sh
source ${SCRIPTS_PATH}/workload-cluster/testEndpoints.sh
source ${SCRIPTS_PATH}/workload-cluster/testCustomerRbac.sh
source ${SCRIPTS_PATH}/workload-cluster/testPrometheusTargets.sh

echo -e "\nSuccesses: $SUCCESSES"
echo "Failures: $FAILURES"

if [ $FAILURES -gt 0 ]
then
    echo "Something failed"
    echo
    echo "Logs from failed test resources"
    echo "==============================="
    echo
    echo "Exists in logs/WorkloadCluster/<kind>/<namespace>"
    echo
    echo "Events from failed test resources"
    echo "==============================="
    echo
    echo "Exists in events/WorkloadCluster/<kind>/<namespace>"
    echo
    echo "Json output of failed test resources"
    echo "===================================="
    echo
    echo "${DEBUG_OUTPUT[@]}" | jq .
    echo
    echo "Unhealthy/missing prometheus targets"
    echo "===================================="
    echo
    echo "${DEBUG_PROMETHEUS_TARGETS[@]}"
    echo
    exit 1
fi

echo "All tests succeded"
