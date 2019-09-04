#!/bin/bash

# This checks the types of each node by looking at the labels that RKE uses: worker, controlplane, and etcd.
# It determines whether or not the desired number of masters/etcd and workers in the cluster is met.

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

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

# Get desired numbers from terraform.
cd ${SCRIPTS_PATH}/../../../terraform
tf_out=$(terraform output -json)

# For whatever reason it was not always able to get the output..
if [[ "$?" -ne 0 ]]
then 
    exit 1
fi

cd ${SCRIPTS_PATH}/

desired_workers=($(echo ${tf_out} | jq -r ".${prefix}_worker_count.value" ))
desired_controlplanes=1
desired_etcds=1

# Get the lables of each node
labels=$(kubectl get nodes -o json | jq ".items[].metadata.labels")

# Check number workers
echo "Checking workers"
workers=$(echo "$labels" | jq 'values | select(."node-role.kubernetes.io/worker" == "true") | [."node-role.kubernetes.io/worker"]')

# We need to check this because list=[""] is evaluated to be empty while ${#list[@]}=1...
if [[ -z ${workers} ]]
then 
    echo -e "\tInvalid number of workers are running\n\tDesired: $desired_workers\n\tRunning: 0"
else
    if [[ "${#workers[@]}" -ne  "$desired_workers" ]]
    then 
        echo -e "\tInvalid number of worker nodes are running\n\tDesired: $desired_workers\n\tRunning: ${#workers[@]}"
    else
        echo -e "\t${#workers[@]}/$desired_workers workers are running."
    fi
fi

# Check number of controlplanes.
echo "Checking controlplanes"
controlplanes=$(echo "$labels" | jq 'values | select(."node-role.kubernetes.io/controlplane" == "true") | [."node-role.kubernetes.io/controlplane"]')

if [[ -z ${controlplanes} ]]
then
    echo -e "\tInvalid number of controlplanes are running\n\tDesired: $desired_controlplanes\n\tRunning: 0"
else
    if [[ ${#controlplanes[@]} -ne "$desired_controlplanes" ]]
    then 
        echo -e "\tInvalid number of controlplanes are running\n\tDesired: $desired_controlplanes\n\tRunning: ${#controlplanes[@]}"
    else
        echo -e "\t${#controlplanes[@]}/$desired_controlplanes controlplanes are running."
    fi
fi

# Check number of etcds.
echo "Checking etcds"
etcds=$(echo "$labels" | jq 'values | select(."node-role.kubernetes.io/etcd" == "true") | [."node-role.kubernetes.io/etcd"]')

if  [[ -z "${etcds}" ]]
then
    echo -e "\tInvalid number of etcds are running\n\tDesired: $desired_etcds\n\tRunning: 0"
else 
    if [ ${#etcds[@]} -ne "$desired_etcds" ]
    then 
        echo -e "\tInvalid number of etcds are running\n\tDesired: $desired_etcds\n\tRunning: ${#etcds[@]}"
    else 
        echo -e "\t${#etcds[@]}/$desired_etcds etcds are running."
    fi
fi
