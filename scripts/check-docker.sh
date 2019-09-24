#!/bin/bash

set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"

# Check that cluster type argument is set and valid.
if [ "$#" -ne 2 -o "$1" != "service_cluster" -a "$1" != "workload_cluster" ]
then 
    >&2 echo "Usage: check-docker.sh <service_cluster | workload_cluster> path-to-infra-file"
    exit 1
fi

echo "Running test on the $1 cluster"

prefix="$1"
infra="$2"

master_ip_addresses=($(cat $infra | jq -r ".${prefix}.master_ip_addresses[]"))
worker_ip_addresses=($(cat $infra | jq -r ".${prefix}.worker_ip_addresses[]"))

# Join the two lists.
hosts=(${worker_ip_addresses[@]})
hosts+=(${master_ip_addresses[@]})

if [ $CLOUD_PROVIDER == "exoscale" ]
then username=rancher
elif [ $CLOUD_PROVIDER == "safespring" ]
then username=ubuntu
fi

# Check that each host in hosts is reachable via ssh.
for host in "${hosts[@]}"
do
  echo "Checking if docker is running on host: $host"
  ssh "$host" -l "$username" -T -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" <<EOF
    #!/bin/bash

    while ( ! docker info >/dev/null 2>&1 )
    do
      echo "Waiting for Docker to launch..."
      sleep 2
    done

    echo "Docker is up and running"
EOF
  
  if [[ $? -ne 0 ]]
  then 
    exit 1
  fi
done
