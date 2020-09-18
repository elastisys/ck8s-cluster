#!/bin/bash

set -e
if [ "$#" -ne 1 ] || ( [ "$1" != "positive" ] && [ "$1" != "negative" ] && [ "$1" != "startup" ] && [ "$1" != "cleanup" ] )
then
    >&2 echo "Usage: nodeport-whitelist.sh <positive | negative | startup | cleanup>"
    exit 1
fi

test_type=$1
here="$(dirname "$(readlink -f "$0")")"
ck8s="${here}/../../../bin/ck8s"
source "${here}/../../common.bash"

failures=0
success=0

startup(){
    ckctl internal kubectl --cluster sc -- apply -f "${here}/nginx-whitelisttest.yaml"
    ckctl internal kubectl --cluster wc -- apply -f "${here}/nginx-whitelisttest.yaml"
    ckctl internal kubectl --cluster sc -- -n ck8s-nodeport-test wait --for=condition=Available deploy/nginx-deployment \
        --timeout=5m
    ckctl internal kubectl --cluster wc -- -n ck8s-nodeport-test wait --for=condition=Available deploy/nginx-deployment \
        --timeout=5m
}

cleanup() {
    ckctl internal kubectl --cluster sc -- delete -f "${here}/nginx-whitelisttest.yaml"
    ckctl internal kubectl --cluster wc -- delete -f "${here}/nginx-whitelisttest.yaml"
}

check_nodeport_whitelist() {
  prefix=$1
  type=$2
  host_addresses=($(cat ${CK8S_CONFIG_PATH}/.state/infra.json | jq -r ".${prefix}.worker_ip_addresses[].public_ip" ))
  for host in "${host_addresses[@]}"
  do
      if [[ -n $(curl -I http://${host}:32116 -ks --max-time 5) ]]; then
          if [[ "$type" == "positive" ]]; then
              echo -n -e "$prefix $type nodeport whitelisting succeeded ✔\n" ;success=$((success+1))
          else 
              echo -n -e "$prefix $type nodeport whitelisting failed ❌\n" ; failures=$((failures+1))
          fi    
      else 
          if [[ "$type" == "negative" ]]; then
              echo -n -e "$prefix $type nodeport whitelisting succeeded ✔\n" ;success=$((success+1))
          else 
              echo -n -e "$prefix $type nodeport whitelisting failed ❌\n" ; failures=$((failures+1))
          fi  
      fi
  done
}

#As there is a bug in kubernetes where resourses is not resleased straight away. https://github.com/kubernetes/kubernetes/issues/32987
#This means that startup is only done by negative to ensure that it works. Meaning that the positive tests have something to test against aswell.
if [[ "$test_type" == "startup" ]]; then
    startup 
elif [[ "$test_type" == "cleanup" ]]; then
    cleanup 
elif [[ "$test_type" == "negative" ]] || [[ "$test_type" == "positive" ]]; then
    echo "==============================="
    echo "Testing nodeport whitelisting"
    echo "==============================="

    check_nodeport_whitelist service_cluster "$test_type"
    check_nodeport_whitelist workload_cluster "$test_type"

    echo "==============================="
    echo "Nodeport whitelist test result"
    echo "===============================" 
    echo "Successes: $success"
    echo "Failures: $failures"

    if [ $failures -gt 0 ]
    then
        echo "Nodeport whitelist testing failed"
        exit 1
    fi

fi