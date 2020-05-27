#!/bin/bash

set -e

# Check that cluster type argument is set and valid.
if [ "$#" -ne 2 ] || [ "$1" != "service_cluster" ] && [ "$1" != "workload_cluster" ]
then
    echo "Usage: $0 <service_cluster | workload_cluster> path-to-infra-file" >&2
    exit 1
fi

echo "Running test on the $1 cluster"

prefix="$1"
infra="$2"

function check_hosts () {
    type=$1
    echo "Running checks hosts of type $type"

    user="ubuntu"

    nr_hosts=$(jq -r ".${prefix}.${type}_count" < $infra)

    if [ "$type" == "nfs" ] && [ "$nr_hosts" == "0" ]
    then
        echo "No nfs server used"
        return 0
    fi
    
    host_addresses=( $(jq -r ".${prefix}.${type}_ip_addresses[].public_ip" < $infra) )

    # Check that the list of host ip addresses is equal to the number of desired workers.
    if [ "$nr_hosts" -ne "${#host_addresses[@]}" ]
    then
        echo -e "Invalid number of hosts are running\nDesired: $nr_hosts\nRunning: ${#host_addresses[@]}"
        exit 1
    fi

    # Check that all hosts are reachable via ssh. Retrying for 1 minute.
    for host in "${host_addresses[@]}"
    do
        MESSAGE="Checking host: $host"
        success="false"
        SECONDS=0

        while [[ "$success" != "true" ]] && [[ $SECONDS -lt 240 ]]
        do
            echo $MESSAGE
            ssh "$host" -l "$user" -T -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" 'ls' &>/dev/null && success="true"
            sleep 5
            MESSAGE="Retrying host: $host"
        done

        if [[ "$success" == "false" ]]
        then
            echo "Host: $host is not reachable by ssh!"
            exit 1
        fi

    done
}

check_hosts master
check_hosts worker
check_hosts nfs