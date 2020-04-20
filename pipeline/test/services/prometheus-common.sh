#!/bin/bash

# Script that test if prometheus targets exist and are healthy

# Makes dataset smaller before testing it for each target
function simplifyData() {
    {
    jsonData=$(curl 'http://localhost:9090/api/v1/targets')
    lessInstance=$(echo ${jsonData} |
        jq '.data.activeTargets[] |
            {job: .discoveredLabels.job , health: .health, instance: .labels.instance}')
    } &> /dev/null
}

# Compares current amount of found instances to amount of desired instances
#Args:
#   1. target name
#   2. expected target instances
function check_instances() {
    targetName="${1}"
    desiredInstanceAmount="${2}"

    # Not sending lessInstance through as an argument to optimize runtime
    # Stores the value value of the "instance" key where the
    # "job" key matches the value of the current target being tested
    activeInstance=$(echo ${lessInstance} |
        jq -r --arg target "${targetName}" '. |
            select(.job==$target and .health=="up") |
            .instance')

    # Counts how many instances were found for that target
    currentInstanceAmount=$(echo ${activeInstance} | wc -w)

    echo -n -e "${targetName} \t(${currentInstanceAmount}/${desiredInstanceAmount})"
    # Compares the amount of current instances to the amount of desired instances to see if they match
    if [[ ${currentInstanceAmount} == ${desiredInstanceAmount} ]];
    then
        echo -e "\t✔"; SUCCESSES=$((SUCCESSES+1))
    else
        echo -e "\t❌"; FAILURES=$((FAILURES+1))
        DEBUG_PROMETHEUS_TARGETS+=("${targetName}")
    fi
}
