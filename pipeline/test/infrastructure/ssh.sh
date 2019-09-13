#!/bin/bash

set -e

# Check that cluster type argument is set and valid.
if [ "$#" -ne 2 -o "$1" != "service_cluster" -a "$1" != "workload_cluster" ]
then 
    echo "Usage: ss.sh <service_cluster | workload_cluster> path-to-infra-file"
    exit 1
fi

echo "Running test on the $1 cluster"

prefix="$1"
infra="$2"

function check_hosts () {
    type=$1
    echo "Running checks hosts of type $type"

    if [ "$type" == "worker" ]
    then
        # Number of desired hosts of type.
        nr_hosts=$(cat $infra | jq -r ".${prefix}.${type}_count" )

        # IP addresses of the worker nodes.
        host_addresses=($(cat $infra | jq -r ".${prefix}.${type}_ip_addresses[]" ))
        user="rancher"
    elif [ "$type" == "nfs" ]
    then 
        nr_hosts=1
        host_addresses=($(cat $infra | jq -r ".${prefix}.${type}_ip_address" ))
        user="ubuntu"
    elif [ "$type" == "master" ]
    then
        nr_hosts=1
        host_addresses=($(cat $infra | jq -r ".${prefix}.${type}_ip_address" ))
        user="rancher"
    fi

    # Check that the list of host ip addresses is equal to the number of desired workers.
    if [ "$nr_hosts" -ne "${#host_addresses[@]}" ]
    then 
        echo -e "Invalid number of hosts are running\nDesired: $nr_hosts\nRunning: ${#host_addresses[@]}"
        exit 1
    fi

    # Check that all hosts are reachable via ssh. Retrying for 1 minute.
    for host in "${host_addresses[@]}"
    do 
        echo "Checking host: $host"
        success="false"
        wait_time=0

        while [[ "$success" != "true" ]] && [[ "$wait_time" < 60 ]]
        do
            echo "Retrying host: $host"
            success="true"
            ssh "$host" -l "$user" -T -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" 'ls' >/dev/null 2>&1 || success="false"
            wait_time=$((wait_time + 5))
            sleep 5
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
