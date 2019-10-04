#!/bin/bash

# This script is a simple wrapper for retrieving secrets from vault.

if [[ "$#" -lt 3 ]]
then 
  >&2 echo "Usage: vault-get.sh vault_addr vault_token path"
  exit 1
fi

vault_addr="$1"
vault_token="$2"
path="$3"

curl -s -k \
    --header "X-Vault-Token: $vault_token" \
    --request GET \
    "$vault_addr"/v1/"$path"
