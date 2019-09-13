SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"

SUCCESSES=0
FAILURES=0

source ${SCRIPTS_PATH}/service-cluster/testPodsReady.sh
source ${SCRIPTS_PATH}/service-cluster/testEndpoints.sh

echo -e "\nSuccesses: $SUCCESSES"
echo "Failures: $FAILURES"

if [ $FAILURES -gt 0 ]
then 
    echo "Something failed"
    exit 1
fi

echo "All tests succeded"