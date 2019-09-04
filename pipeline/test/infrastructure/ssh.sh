#!/bin/bash

# Check that cluster type argument is set and valid.
if [ "$1" != "system-services" -a "$1" != "customer" ]
then 
    echo "Usage: ss.sh <system-services | customer>"
    exit 1
fi

echo "Running test on the $1 cluster"

if [ $1 == "system-services" ]
then 
    prefix="ss"
elif [ $1 == "customer" ]
then
    prefix="c"
fi

tf_out=$(terraform output -json)

# TODO - Update this function when we can have variable amount of masters.
function check_hosts () {
    type=$1
    echo "Running checks hosts of type $type"

    if [ "$type" == "worker" ]
    then
        # Number of desired hosts of type.
        nr_hosts=$(echo ${tf_out} | jq -r ".${prefix}_${type}_count.value" )

        # IP addresses of the worker nodes.
        host_addresses=($(echo ${tf_out} | jq -r ".${prefix}_${type}_ip_addresses.value[]" ))
        user="rancher"
    elif [ "$type" == "nfs" ]
    then 
        nr_hosts=1
        host_addresses=($(echo ${tf_out} | jq -r ".${prefix}_${type}_ip_address.value" ))
        user="ubuntu"
    elif [ "$type" == "master" ]
    then
        nr_hosts=1
        host_addresses=($(echo ${tf_out} | jq -r ".${prefix}_${type}_ip_address.value" ))
        user="rancher"
    fi

    # Check that the list of host ip addresses is equal to the number of desired workers.
    if [ "$nr_hosts" -ne "${#host_addresses[@]}" ]
    then 
        echo -e "Invalid number of hosts are running\nDesired: $nr_hosts\nRunning: ${#host_addresses[@]}"
    fi

    # Check that all hosts are reachable via ssh. Retrying for 1 minute.
    for host in "${host_addresses[@]}"
    do 
        echo "Checking host: $host"
        ssh "$host" -l "$user" -T -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" 'ls' >/dev/null 2>&1
       
        if [[ "$?" -ne 0 ]]
        then 
            wait_time=0
            success=false

            while [[ ! success ]] && [[ $wait_time < 60 ]]
            do
                echo "Retrying host: $host"
                ssh "$host" -l "$user" -T -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" 'ls' >/dev/null 2>&1 
                
                if [[ "$?" -eq 0 ]]
                then
                    success=true
                else 
                    success=false
                fi

                wait_time=$((wait_time + 2))
            done 

            if [[ ! success ]]
            then 
                echo "Host: $host is not reachable by ssh!"
                exit 1
            fi
        fi
    done
}

check_hosts master
check_hosts worker
check_hosts nfs
