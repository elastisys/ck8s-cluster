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
desired_masters=$(cat $infra | jq -r ".${prefix}.master_count")
desired_workers=$(cat $infra | jq -r ".${prefix}.worker_count")

# Get how many nodes of each type there currently are in the cluster.
masters=$(kubectl get nodes --no-headers -l "node-role.kubernetes.io/master=" | wc -l)
workers=$(kubectl get nodes --no-headers -l "node-role.kubernetes.io/master!=" | wc -l)

success="true"

function check_nodes () {
    type=$1
    desired=$2
    nodes=$3

    if [[ "$type" != "masters" && "$type" != "workers" ]]
    then
        echo "Invalid node type, must be one of 'masters' or 'workers'"
        exit 1
    fi

    echo "Checking $type"

    if [[ "$nodes" -ne  "$desired" ]]
    then
        echo -e "\tInvalid number of $type nodes are running\n\tDesired: $desired\n\tRunning: $nodes"
        success="false"
    else
        echo -e "\t$nodes/$desired $type are running."
    fi
}

check_nodes "masters"  "$desired_masters" "$masters"
check_nodes "workers"  "$desired_workers" "$workers"

if [[ "$success" != "true" ]]
then
    exit 1
fi
