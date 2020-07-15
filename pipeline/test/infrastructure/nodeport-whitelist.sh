#!/bin/bash

set -e
if [ "$#" -ne 1 -o "$1" != "positive" -a "$1" != "negative" ]
then
    >&2 echo "Usage: nodeport-whitelist.sh <positive | negative>"
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
echo "Testing nodeport whitelisting"
echo "==============================="

startup(){
    $ck8s ops kubectl sc apply -f "${here}/../pipeline/test/infrastructure/nginx-whitelisttest.yaml"
    $ck8s ops kubectl wc apply -f "${here}/../pipeline/test/infrastructure/nginx-whitelisttest.yaml"
    $ck8s ops kubectl sc -n ck8s-nodeport-test wait --for=condition=Available deploy/nginx-deployment \
        --timeout=5m
    $ck8s ops kubectl wc -n ck8s-nodeport-test wait --for=condition=Available deploy/nginx-deployment \
        --timeout=5m
}

cleanup() {
    $ck8s ops kubectl sc delete -f "${here}/../pipeline/test/infrastructure/nginx-whitelisttest.yaml"
    $ck8s ops kubectl wc delete -f "${here}/../pipeline/test/infrastructure/nginx-whitelisttest.yaml"
}

check_nodeport_whitelist() {
  prefix=$1
  type=$2
  host_addresses=($(cat $infra | jq -r ".${prefix}.worker_ip_addresses[].public_ip" ))
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
#This means that startup is only done by positive to ensure that it works. Meaning that the negative tests have something to test against aswell.
if [[ "$test_type" == "positive" ]]; then
    startup 
fi
check_nodeport_whitelist service_cluster "$test_type"
check_nodeport_whitelist workload_cluster "$test_type"
if [[ "$test_type" == "negative" ]]; then
    cleanup 
fi

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