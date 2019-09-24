#!/bin/bash

set -e

# This checks the types of each node by looking at the labels: worker, controlplane, and etcd.
# It determines whether or not the desired number of masters/etcd and workers in the cluster is met.

# Check that cluster type argument is set and valid.
if [ "$#" -ne 2 -o "$1" != "service_cluster" -a "$1" != "workload_cluster" ]
then 
    >&2 echo "Usage: check-nodes.sh <service_cluster | workload_cluster> path-to-infra-file"
    exit 1
fi

echo "Running test on the $1 cluster"

prefix="$1"
infra="$2"

# Get the desired number of each node type.
desired_workers=($(cat $infra | jq -r ".${prefix}.worker_count" ))
desired_controlplanes=($(cat $infra | jq -r ".${prefix}.master_count" ))
desired_etcds=($(cat $infra | jq -r ".${prefix}.master_count" ))


# Get the lables of each node
labels=$(kubectl get nodes -o json | jq ".items[].metadata.labels")

# Get how many nodes of each type there currently are in the cluster.
workers=($(echo "$labels" | jq ' values | select(."node-role.kubernetes.io/worker" == "true") | [."node-role.kubernetes.io/worker"] | add | values'));
controlplanes=($(echo "$labels" | jq 'values | select(."node-role.kubernetes.io/controlplane" == "true") | [."node-role.kubernetes.io/controlplane"] | add | values'))
etcds=($(echo "$labels" | jq 'values | select(."node-role.kubernetes.io/etcd" == "true") | [."node-role.kubernetes.io/etcd"] | add | values'))

success="true"

function check_nodes () {
    type=$1
    desired=$2
    shift; shift
    nodes=("$@")

    if [[ "$type" != "workers" && "$type" != "controlplanes" && "$type" != "etcds" ]]
    then 
        echo "Invalid node type, must be one of: 'workers', 'controlplanes', 'etcds'"
        exit 1
    fi

    echo "Checking $type"

    if [[ "${#nodes[@]}" -ne  "$desired" ]]
    then 
        echo -e "\tInvalid number of $type nodes are running\n\tDesired: $desired\n\tRunning: ${#nodes[@]}"
        success="false"
    else
        echo -e "\t${#nodes[@]}/$desired $type are running."
    fi
}

check_nodes "workers" "$desired_workers" "${workers[@]}" 
check_nodes "controlplanes" "$desired_controlplanes" "${controlplanes[@]}"
check_nodes "etcds"  "$desired_etcds" "${etcds[@]}"

if [[ "$success" != "true" ]]
then 
    exit 1
fi
