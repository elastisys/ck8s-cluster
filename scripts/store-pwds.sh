#!/bin/bash

# This scripts generates and stores passwords in vault.
# It accepts multiple services as input.
# This script utilizes 'gen-pwd.sh' and 'vault-post.sh'.
# Will store the password in 'base_path/service'
# 'base_path' must include 'data' after the path to the secrets engine.

set -e

if [[ "$#" -lt 5 ]]
then 
  >&2 echo "Usage: store-pwds.sh vault_addr vault_token pwd_length base_path service_1 <service_2..>"
  exit 1
fi

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

vault_addr="$1"
vault_token="$2"
pwd_length="$3"
base_path="$4"
shift;shift;shift;shift;
services=("$@")

for svc in ${services[@]}
do
    # Generate random password.
    passwd=$(${SCRIPTS_PATH}/gen-pwd.sh "$pwd_length")

    # Build path for password secret.
    path="$base_path/"$svc""
    
    # Build payload - for kv version 2.
  tee payload.json <<EOF
{
  "data": {
    "password": "$passwd"
  }
}
EOF

    # Store password in vault.
    cat payload.json | "${SCRIPTS_PATH}/vault-post.sh" "$vault_addr" "$vault_token" "$path"
done

# Remove payload.json
rm payload.json
