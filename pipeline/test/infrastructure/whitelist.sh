#!/bin/bash

set -e
if [ "$#" -ne 1 -o "$1" != "positive" -a "$1" != "negative" ]
then
    >&2 echo "Usage: whitelist.sh <positive | negative>"
    exit 1
fi

test_type=$1
here="$(dirname "$(readlink -f "$0")")"
ck8s="${here}/../../../bin/ck8s"
source "${here}/../../common.bash"
source "${here}/../../../bin/common.bash"
failures=0
success=0
infra="${config[infrastructure_file]}"
echo "==============================="
echo "Testing whitelisting"
echo "==============================="

function check_ssh () {
    prefix=$1
    type=$2

    if [[ "$1" == "service_cluster" ]]; then
        agent="${secrets[ssh_priv_key_sc]}"
    elif [[ "$1" == "workload_cluster" ]]; then
        agent="${secrets[ssh_priv_key_wc]}"
    else
        echo "Invalid arg 1 $1"
        exit 1
    fi

    user="ubuntu"
    host_addresses=($(cat $infra | jq -r ".${prefix}.master_ip_addresses[].public_ip" ))


    # Check that all hosts are reachable via ssh. Retrying for 1 minute.
    for host in "${host_addresses[@]}"
    do
        pass="negative"
        SECONDS=0

        while [[ "$pass" != "positive" ]] && [[ $SECONDS -lt 20 ]]
        do
            pass="positive"
            with_ssh_agent "$agent" ssh "$host" -l "$user" -T -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" 'ls' >/dev/null 2>&1 || pass="negative"
            sleep 2
        done

        if [[ "$pass" == "$type" ]]; then
            echo -n -e "$prefix $type ssh whitelisting succeeded ✔\n" ;success=$((success+1))

        else
            echo -n -e "$prefix $type ssh whitelisting failed ❌\n" ; failures=$((failures+1))
        fi
    done
}

check_api_server() {
  prefix=$1
  type=$2
  if [[ "$CK8S_CLOUD_PROVIDER" == "exoscale" ]]; then
    host_addresses=()
    host_addresses+=("$(cat $infra | jq -r ".${prefix}.loadbalancer_ip_addresses")")
  elif [[ "$CK8S_CLOUD_PROVIDER" == "aws" ]]; then
    host_addresses=()
    if [[ "$prefix" == "service_cluster" ]]; then
        host_addresses+=("$(cat $infra | jq -r ".${prefix}.sc_master_external_loadbalancer_fqdn")")
    else
        host_addresses+=("$(cat $infra | jq -r ".${prefix}.wc_master_external_loadbalancer_fqdn")")
    fi
  else
    host_addresses=($(cat $infra | jq -r ".${prefix}.loadbalancer_ip_addresses[].public_ip" ))
  fi
  for host in "${host_addresses[@]}"
  do
      code=$(curl https://${host}:6443 -ks --max-time 5 | jq .code)
      if [[ -n "$code" ]]; then
          if [[ "$type" == "positive" ]]; then
              echo -n -e "$prefix $type api whitelisting succeeded ✔\n" ;success=$((success+1))
          else 
              echo -n -e "$prefix $type api whitelisting failed ❌\n" ; failures=$((failures+1))
          fi    
      else 
          if [[ "$type" == "negative" ]]; then
              echo -n -e "$prefix $type api whitelisting succeeded ✔\n" ;success=$((success+1))
          else 
              echo -n -e "$prefix $type api whitelisting failed ❌\n" ; failures=$((failures+1))
          fi  
      fi
  done
}

check_ssh service_cluster "$test_type"
check_ssh workload_cluster "$test_type"
check_api_server service_cluster "$test_type"
check_api_server workload_cluster "$test_type"

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