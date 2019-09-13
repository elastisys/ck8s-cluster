#!/bin/bash

set -e
SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

# Check that cluster type argument is set and valid.
if [ "$1" != "service_cluster" -a "$1" != "workload_cluster" ]
then 
    echo "Usage: ss.sh <service_cluster | workload_cluster>"
    exit 1
fi

echo "Running test on the $1 cluster"

prefix="$1"

# Get infra info
cd ${SCRIPTS_PATH}/../

# TODO - Update when we can have variable amount of masters.
master_ip_address=$(cat infra.json | jq -r ".${prefix}.master_ip_address")
worker_ip_addresses=($(cat infra.json | jq -r ".${prefix}.worker_ip_addresses[]"))

hosts=$worker_ip_addresses
hosts+=($master_ip_address)

for host in "${hosts[@]}"
do
  echo "Checking if docker is running on host: $host"
  ssh "$host" -l "rancher" -T -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" <<EOF
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
