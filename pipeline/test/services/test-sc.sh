#!/bin/bash

SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"

SUCCESSES=0
FAILURES=0
DEBUG_OUTPUT=("")
DEBUG_LOGS=("")
DEBUG_PROMETHEUS_TARGETS=("")

source ${SCRIPTS_PATH}/service-cluster/testPodsReady.sh
source ${SCRIPTS_PATH}/service-cluster/testEndpoints.sh
source ${SCRIPTS_PATH}/service-cluster/testPrometheusTargets.sh

echo -e "\nSuccesses: $SUCCESSES"
echo "Failures: $FAILURES"

if [ $FAILURES -gt 0 ]
then
    echo "Something failed"
    echo
    echo "Logs from failed test resources"
    echo "==============================="
    echo
    echo "${DEBUG_LOGS[@]}"
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
