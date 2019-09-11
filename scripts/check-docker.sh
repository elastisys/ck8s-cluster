#!/bin/bash

set -e
SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

if [ "$1" != "system-services" -a "$1" != "customer" ]
then 
    echo "Usage: ss.sh <system-services | customer>"
    exit 1
fi

if [ $1 == "system-services" ]
then 
    prefix="system_services"
elif [ $1 == "customer" ]
then
    prefix="customer"
fi

# Get infra info
cd ${SCRIPTS_PATH}/../

# TODO - Update when we can have variable amount of masters.
master_ip_address=$(cat hosts.json | jq -r ".${prefix}_master_ip_address.value")
worker_ip_addresses=($(cat hosts.json | jq -r ".${prefix}_worker_ip_addresses.value[]"))

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
