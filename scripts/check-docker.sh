#!/bin/bash

set -e
SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

# Get terraform output
cd ${SCRIPTS_PATH}/../terraform
tf_out=$(terraform output -json)

# TODO - Update when we can have variable amount of masters.
master_ip_address=$(echo ${tf_out} | jq -r '.c_master_ip_address.value')
worker_ip_addresses=($(echo ${tf_out} | jq -r '.c_worker_ip_addresses.value[]'))

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
      sleep
    done

    echo "Docker is up and running"
EOF
  
  if [[ $? -ne 0 ]]
  then 
    exit 1
  fi
done
