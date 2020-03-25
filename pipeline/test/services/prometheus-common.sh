#!/bin/bash

# Script that test if prometheus targets exist and are healthy

# Functions/variables that both clusters need
MISSING=0
FOUND=0
UNHEALTHY=0
HEALTHY=0
declare -a failedTargets

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

    # Compares the amount of current instances to the amount of desired instances to see if they match
    if [[ ${currentInstanceAmount} == ${desiredInstanceAmount} ]];
    then
        echo
        echo -n -e "${1}"
        echo -n -e "\texists ✔"
        echo -e "\thealthy ✔"
        HEALTHY=$((HEALTHY+1))
        FOUND=$((FOUND+1))
    else
        echo
        echo -n -e "${1}"
        echo -n -e "\texists ❌"
        echo -e "\thealthy ❌"
        UNHEALTHY=$((UNHEALTHY+1))
        MISSING=$((MISSING+1))
        failedTargets+=("${1}")
    fi
    echo "Instances: ${activeInstance}"
    echo "Healthy instances: (${currentInstanceAmount}/${desiredInstanceAmount})"
}

function count_healthy() {
    if [ "${MISSING}" -eq 0 ]
    then
        echo
        echo "Found all targets!"
    else
        echo
        echo "Could not find all targets"
        echo "Targets found: ${FOUND}"
        echo "Targets missing: ${MISSING}"
        echo
        echo "Failed targets: ${failedTargets[@]}"
        echo
    fi

    if [ "${UNHEALTHY}" -eq 0 ]
    then
        echo "All targets are healthy!"
        echo
    else
        echo
        echo "All targets are not healthy!"
        echo "Healthy targets: ${HEALTHY}"
        echo "Unhealthy targets: ${UNHEALTHY}"
        echo
    fi
}