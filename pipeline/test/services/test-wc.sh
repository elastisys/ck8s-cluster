SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"

SUCCESSES=0
FAILURES=0
DEBUG_OUTPUT=("")
DEBUG_LOGS=("")

source ${SCRIPTS_PATH}/workload-cluster/testPodsReady.sh
source ${SCRIPTS_PATH}/workload-cluster/testEndpoints.sh
source ${SCRIPTS_PATH}/workload-cluster/testCustomerRbac.sh

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
    exit 1
fi

echo "All tests succeded"
