#!/bin/bash

# This script:
# 1: Removes the password for each service.
# 2: Revokes the vault token.

set -e
echo "manual=$MANUAL"
if [[ "$#" -lt 1 ]]
then 
  >&2 echo "Usage: vault-cleanup.sh <services>"
  exit 1
fi

services=("$@")

for svc in ${services[@]}
do
    # Delete Metadata and All Versions.
    curl --header "X-Vault-Token: $VAULT_TOKEN" --request DELETE "${VAULT_ADDR}/v1/${BASE_PATH_META}/${svc}"

done
if [[ "$MANUAL" != true ]]; then
    # Revoke vault token.
    curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST "${VAULT_ADDR}/v1/auth/token/revoke-self"
fi