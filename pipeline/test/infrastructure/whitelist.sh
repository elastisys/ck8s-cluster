#!/bin/bash

set -e -o pipefail

if [ ${#} -ne 1 ] || [ "${1}" != "positive" ] && [ "${1}" != "negative" ]
then
    >&2 echo "Usage: whitelist.sh <positive | negative>"
    exit 1
fi

set -u

test_type=$1
here="$(dirname "$(readlink -f "$0")")"
source "${here}/../../common.bash"
failures=0
success=0
echo "==============================="
echo "Testing whitelisting"
echo "==============================="

print_log_output() {
    echo "==============================="
    echo "Log output"
    echo "==============================="
    echo "${@}"
}

check_ssh() {
    export CK8S_CLUSTER=$1

    pass="positive"
    out=$(ckctl status ssh --ssh-timeout 10s 2>&1) || pass="negative"

    if [ "${pass}" = "${test_type}" ]; then
        echo "${CK8S_CLUSTER} ${test_type} ssh whitelisting succeeded ✔"
        success=$((success+1))
    else
        echo "${CK8S_CLUSTER} ${test_type} ssh whitelisting failed ❌"
        failures=$((failures+1))

        print_log_output "${out}"
    fi
}

check_api_server() {
    export CK8S_CLUSTER=$1

    pass="positive"
    out=$(ckctl internal kubectl cluster-info -- --request-timeout 10s 2>&1) \
        || pass="negative"

    if [ "${pass}" = "${test_type}" ]; then
        echo "${CK8S_CLUSTER} ${test_type} api whitelisting succeeded ✔"
        success=$((success+1))
    else
        echo "${CK8S_CLUSTER} ${test_type} api whitelisting failed ❌"
        failures=$((failures+1))

        print_log_output "${out}"
    fi
}

check_ssh sc
check_ssh wc
check_api_server sc
check_api_server wc

echo "==============================="
echo "Whitelist test result $test_type"
echo "==============================="
echo "Successes: $success"
echo "Failures: $failures"

if [ $failures -gt 0 ]
then
    echo "Whitelist testing failed"
    exit 1
fi
